#!/usr/bin/env bash
# Deploy Yummy Chops to Cloud Run: gudmeal-api, gudmeal-agents and the three websites (gudmeal-web, gudmeal-partner,
# gudmeal-admin), from the images built with infra/cloudbuild/cloudbuild.yaml.
# Usage: infra/scripts/deploy.sh <environment> <project> <region> <artifact-repo> <tag>
# Secrets are referenced from Secret Manager (never passed on the command line).
set -euo pipefail

ENVIRONMENT="$1"; PROJECT="$2"; REGION="$3"; REPO="$4"; TAG="$5"
IMG="$REGION-docker.pkg.dev/$PROJECT/$REPO"
SQL="$PROJECT:$REGION:gudmeal-sql"

case "$ENVIRONMENT" in
  production) MIN=1; MAX=20 ;;
  staging)    MIN=0; MAX=4 ;;
  *)          MIN=0; MAX=2 ;;
esac

# API_URL, AGENTS_URL, WEB_URL, PARTNER_URL and ADMIN_URL: Cloud Run's deterministic URLs unless overridden.
source "$(dirname "$0")/urls.sh"
SITES="[\"$WEB_URL\",\"$PARTNER_URL\",\"$ADMIN_URL\"]"  # browser origins allowed by the API and Yummy (CORS)

# Yummy on WhatsApp (ADR-0017) uses Meta's paid WhatsApp Business messaging, so it stays off until the owner has
# approved the cost and finished the Meta setup. To switch it on, fill the whatsapp-* secrets and run this script
# with WHATSAPP_ENABLED=true, WHATSAPP_PHONE_NUMBER_ID and WHATSAPP_BUSINESS_NUMBER set.
WHATSAPP_ENV="WHATSAPP_ENABLED=false"
WHATSAPP_SECRETS=""
if [[ "${WHATSAPP_ENABLED:-false}" == "true" ]]; then
  : "${WHATSAPP_PHONE_NUMBER_ID:?set WHATSAPP_PHONE_NUMBER_ID}" "${WHATSAPP_BUSINESS_NUMBER:?set WHATSAPP_BUSINESS_NUMBER}"
  WHATSAPP_ENV="WHATSAPP_ENABLED=true,WHATSAPP_PROVIDER=cloud,WHATSAPP_PHONE_NUMBER_ID=$WHATSAPP_PHONE_NUMBER_ID,WHATSAPP_BUSINESS_NUMBER=$WHATSAPP_BUSINESS_NUMBER"
  WHATSAPP_SECRETS=",WHATSAPP_ACCESS_TOKEN=whatsapp-access-token:latest,WHATSAPP_APP_SECRET=whatsapp-app-secret:latest,WHATSAPP_VERIFY_TOKEN=whatsapp-verify-token:latest"
fi

# True when a secret has a value. A failed check stops the deploy: going on would deploy without that secret, since
# --set-secrets replaces every binding (gudmeal-deployer needs roles/secretmanager.viewer, bootstrap-gcp.sh).
has_secret() {
  local found
  found=$(gcloud secrets versions list "$1" --project "$PROJECT" --filter 'state=ENABLED' --limit 1 --format 'value(name)') ||
    { echo "Could not check the secret $1; stopping so it is not dropped from the services." >&2; exit 1; }
  [[ -n "$found" ]]
}

# Riders' KYC documents live in the project's Firebase Storage bucket (the API refuses to start in the cloud
# without it; bootstrap-gcp.sh gives gudmeal-api access).
STORAGE_BUCKET="${STORAGE_BUCKET:-$PROJECT.firebasestorage.app}"

# Google Maps server key (docs/GOOGLE_MAPS.md), bound once the secret has a value; without it the API gives labelled
# estimates. It is listed here because --set-secrets replaces every secret binding on each deploy.
MAPS_SECRET=""
if has_secret google-maps-server-key; then
  MAPS_SECRET=",GOOGLE_MAPS_API_KEY=google-maps-server-key:latest"
fi

# Gemini (Yummy's AI): bound once gemini-api-key has a value; without it Yummy answers in its offline mode.
GEMINI_SECRETS=""
if has_secret gemini-api-key; then
  GEMINI_SECRETS="GOOGLE_API_KEY=gemini-api-key:latest,GEMINI_MODEL=gemini-model:latest,"
fi

# The online test server (ENVIRONMENT=development, ADR-0026) runs the invented demo shops: Cloud Scheduler fills the
# database once (/internal/jobs/seed-demo) and lets the shops accept orders (/internal/jobs/demo-shops). Staging and
# production refuse these switches at start-up.
DEMO_ENV="SEED_DEMO_DATA=false"
if [[ "$ENVIRONMENT" == "development" ]]; then
  DEMO_ENV="SEED_DEMO_DATA=true,DEMO_SHOPS_ALWAYS_OPEN=true,DEMO_SHOP_AUTOPILOT=true"
fi

echo "==> Deploying gudmeal-api ($ENVIRONMENT, min=$MIN max=$MAX)"
gcloud run deploy gudmeal-api --project "$PROJECT" --region "$REGION" \
  --image "$IMG/gudmeal-api:$TAG" \
  --service-account "gudmeal-api@$PROJECT.iam.gserviceaccount.com" \
  --cpu 1 --memory 512Mi --concurrency 40 --timeout 60 \
  --min-instances "$MIN" --max-instances "$MAX" \
  --set-cloudsql-instances "$SQL" \
  --allow-unauthenticated \
  --set-env-vars "ENVIRONMENT=$ENVIRONMENT,DATA_BACKEND=firestore,FILE_STORE=gcs,STORAGE_BUCKET=$STORAGE_BUCKET,$DEMO_ENV,GCP_PROJECT_ID=$PROJECT,FIREBASE_PROJECT_ID=$PROJECT,EVENT_BUS=pubsub,TASK_QUEUE=cloudtasks,NOTIFIER=fcm,INTERNAL_AUTH_MODE=oidc,CLOUD_TASKS_LOCATION=$REGION,CLOUD_TASKS_SERVICE_ACCOUNT=gudmeal-tasks@$PROJECT.iam.gserviceaccount.com,INTERNAL_OIDC_AUDIENCE=$API_URL,PUBLIC_BASE_URL=$API_URL,APP_CHECK_ENFORCED=$([ "$ENVIRONMENT" = production ] && echo true || echo false),AGENTS_BASE_URL=$AGENTS_URL,PUBLIC_WEB_URL=$WEB_URL,PAYMENT_CALLBACK_URL=$WEB_URL/checkout/callback,$WHATSAPP_ENV" \
  --set-env-vars "^;^INTERNAL_OIDC_SERVICE_ACCOUNTS=[\"gudmeal-tasks@$PROJECT.iam.gserviceaccount.com\"];TRUSTED_SERVICE_ACCOUNTS=[\"gudmeal-agents@$PROJECT.iam.gserviceaccount.com\"];CORS_ORIGINS=$SITES" \
  --set-secrets "DATABASE_URL=api-database-url:latest,PAYSTACK_SECRET_KEY=paystack-secret-key:latest,CODE_PEPPER=api-code-pepper:latest,CHANNEL_TOKEN_SECRET=channel-token-secret:latest$WHATSAPP_SECRETS$MAPS_SECRET"

echo "==> Deploying gudmeal-agents"
gcloud run deploy gudmeal-agents --project "$PROJECT" --region "$REGION" \
  --image "$IMG/gudmeal-agents:$TAG" \
  --service-account "gudmeal-agents@$PROJECT.iam.gserviceaccount.com" \
  --cpu 1 --memory 1Gi --concurrency 20 --timeout 120 \
  --min-instances 0 --max-instances "$MAX" \
  --set-cloudsql-instances "$SQL" \
  --allow-unauthenticated \
  --set-env-vars "ENVIRONMENT=$ENVIRONMENT,API_BASE_URL=$API_URL,FIREBASE_PROJECT_ID=$PROJECT,CHECKPOINTER=postgres,CHECK_TOKEN_REVOCATION=true,LANGSMITH_TRACING=false,INTERNAL_AUTH_MODE=oidc,APP_CHECK_ENFORCED=$([ "$ENVIRONMENT" = production ] && echo true || echo false)" \
  --set-env-vars "^;^CORS_ORIGINS=$SITES" \
  --set-secrets "${GEMINI_SECRETS}DATABASE_URL=agents-database-url:latest,CHECKPOINT_POSTGRES_URL=agents-checkpoint-url:latest,CHANNEL_TOKEN_SECRET=channel-token-secret:latest"

# The websites hold no secrets and need no Google Cloud permissions: a role-less service account, public access.
# Their browser settings are compiled into the images; API_URL is for the customer site's server-side pages.
# DEPLOY_WEBSITES=false skips them: the live websites are on Vercel (docs/DEPLOYMENT.md §5a); then set WEB_URL,
# PARTNER_URL and ADMIN_URL to their addresses so CORS and the payment return page point there.
SITE_LIST="web partner admin"
[[ "${DEPLOY_WEBSITES:-true}" == "false" ]] && SITE_LIST=""
for SITE in $SITE_LIST; do
  echo "==> Deploying gudmeal-$SITE"
  gcloud run deploy "gudmeal-$SITE" --project "$PROJECT" --region "$REGION" \
    --image "$IMG/gudmeal-$SITE:$TAG" \
    --service-account "gudmeal-web@$PROJECT.iam.gserviceaccount.com" \
    --cpu 1 --memory 512Mi --concurrency 80 --timeout 60 \
    --min-instances "$([ "$SITE" = web ] && echo "$MIN" || echo 0)" --max-instances "$MAX" \
    --allow-unauthenticated \
    --set-env-vars "API_URL=$API_URL"
done

cat <<EOF
==> Done.
  Customer website  $WEB_URL
  Partner dashboard $PARTNER_URL
  Command Centre    $ADMIN_URL
  API               $API_URL
  Yummy (agents)     $AGENTS_URL
Roll back a service with: gcloud run services update-traffic <service> --to-revisions=<previous>=100 --region $REGION --project $PROJECT
EOF
