#!/usr/bin/env bash
# One-time bootstrap of a Yummy Chops environment in an EXISTING Google Cloud project that already has
# Firebase added and billing enabled. Run it yourself, per environment (dev → staging → prod):
#
#   infra/scripts/bootstrap-gcp.sh yummy-chops-dev europe-west1
#   infra/scripts/bootstrap-gcp.sh yummy-chops-dev europe-west1 --with-cloud-sql   # creates a billable Cloud SQL instance
#
# The script is idempotent where gcloud allows (existing resources are skipped) and NEVER creates
# Cloud SQL unless --with-cloud-sql is passed and you confirm the cost prompt.
set -euo pipefail

PROJECT="${1:?project id required, e.g. yummy-chops-dev}"
REGION="${2:-europe-west1}"
WITH_SQL="${3:-}"
ENV_NAME="${PROJECT##*-}"   # dev | staging | prod

say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
exists() { "$@" >/dev/null 2>&1; }

say "Checking billing for $PROJECT"
BILLING=$(gcloud beta billing projects describe "$PROJECT" --format='value(billingEnabled)' 2>/dev/null || echo "unknown")
echo "billingEnabled=$BILLING"
if [[ "$BILLING" != "True" ]]; then
  echo "Billing is not enabled (or not visible to you). Enable billing and create a budget alert first." >&2
  exit 1
fi
cat <<EOF

This will enable APIs and create (mostly free-tier / pay-per-use) resources in $PROJECT ($REGION):
  Artifact Registry, service accounts, Pub/Sub topic, Cloud Tasks queue, Cloud Scheduler jobs,
  Secret Manager secret placeholders and a Firestore database.
Cloud Run, Pub/Sub, Tasks, Scheduler and Firestore bill per use. See docs/COST_ESTIMATE.md.
EOF
read -r -p "Type the project id to continue: " CONFIRM
[[ "$CONFIRM" == "$PROJECT" ]] || { echo "Aborted."; exit 1; }

gcloud config set project "$PROJECT" >/dev/null

say "Enabling APIs"
gcloud services enable run.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com \
  secretmanager.googleapis.com pubsub.googleapis.com cloudtasks.googleapis.com cloudscheduler.googleapis.com \
  firestore.googleapis.com iam.googleapis.com iamcredentials.googleapis.com sqladmin.googleapis.com \
  monitoring.googleapis.com logging.googleapis.com firebase.googleapis.com identitytoolkit.googleapis.com \
  fcm.googleapis.com firebaseappcheck.googleapis.com

say "Artifact Registry"
exists gcloud artifacts repositories describe gudmeal --location "$REGION" ||
  gcloud artifacts repositories create gudmeal --repository-format docker --location "$REGION" \
    --description "Yummy Chops service images"

say "Service accounts (least privilege)"
# gudmeal-web runs the three websites and gets no roles: they only call the public API.
for sa in gudmeal-api gudmeal-agents gudmeal-tasks gudmeal-deployer gudmeal-web; do
  exists gcloud iam service-accounts describe "$sa@$PROJECT.iam.gserviceaccount.com" ||
    gcloud iam service-accounts create "$sa" --display-name "$sa"
done
bind() { gcloud projects add-iam-policy-binding "$PROJECT" --member "serviceAccount:$1@$PROJECT.iam.gserviceaccount.com" --role "$2" --condition None >/dev/null; }
for role in roles/datastore.user roles/cloudsql.client roles/pubsub.publisher \
            roles/cloudtasks.enqueuer roles/firebaseauth.admin roles/firebasecloudmessaging.admin roles/logging.logWriter \
            roles/monitoring.metricWriter; do
  bind gudmeal-api "$role"
done
# Yummy checks whether a sign-in was revoked (CHECK_TOKEN_REVOCATION), which reads Firebase Auth.
for role in roles/cloudsql.client roles/firebaseauth.viewer roles/logging.logWriter roles/monitoring.metricWriter; do
  bind gudmeal-agents "$role"
done
# secretmanager.viewer: deploy.sh checks which secrets have values (never their contents).
for role in roles/run.admin roles/cloudbuild.builds.editor roles/artifactregistry.writer roles/iam.serviceAccountUser \
            roles/secretmanager.viewer; do
  bind gudmeal-deployer "$role"
done
# The API enqueues Cloud Tasks that authenticate as gudmeal-tasks.
gcloud iam service-accounts add-iam-policy-binding "gudmeal-tasks@$PROJECT.iam.gserviceaccount.com" \
  --member "serviceAccount:gudmeal-api@$PROJECT.iam.gserviceaccount.com" --role roles/iam.serviceAccountUser >/dev/null

say "Firestore (Native mode)"
exists gcloud firestore databases describe --database="(default)" ||
  gcloud firestore databases create --location="$REGION" --type=firestore-native
echo "Deploy rules & indexes with: (cd firebase && firebase deploy --only firestore,storage --project $PROJECT)"
# WhatsApp de-duplication records and link codes delete themselves once `expire_at` has passed (ADR-0017).
for group in whatsapp_messages whatsapp_link_codes; do
  gcloud firestore fields ttls update expire_at --collection-group="$group" --enable-ttl --async >/dev/null
done

say "Pub/Sub, Cloud Tasks"
exists gcloud pubsub topics describe gudmeal-domain-events || gcloud pubsub topics create gudmeal-domain-events
exists gcloud pubsub topics describe gudmeal-domain-events-dlq || gcloud pubsub topics create gudmeal-domain-events-dlq
exists gcloud tasks queues describe gudmeal-default --location "$REGION" ||
  gcloud tasks queues create gudmeal-default --location "$REGION" --max-attempts 8 --min-backoff 5s --max-backoff 300s

say "Secret Manager placeholders (add values yourself: gcloud secrets versions add NAME --data-file=-)"
for s in api-database-url agents-database-url agents-checkpoint-url paystack-secret-key flutterwave-secret-key \
         flutterwave-secret-hash api-code-pepper gemini-api-key gemini-model google-maps-server-key \
         channel-token-secret whatsapp-access-token whatsapp-app-secret whatsapp-verify-token; do
  exists gcloud secrets describe "$s" || gcloud secrets create "$s" --replication-policy automatic
done
# Each service reads only its own secrets: Yummy, which talks to an AI model, never sees the payment keys or the
# API's database.
grant_secret() {
  gcloud secrets add-iam-policy-binding "$2" --member "serviceAccount:$1@$PROJECT.iam.gserviceaccount.com" \
    --role roles/secretmanager.secretAccessor >/dev/null
}
for s in api-database-url paystack-secret-key flutterwave-secret-key flutterwave-secret-hash api-code-pepper \
         google-maps-server-key channel-token-secret whatsapp-access-token whatsapp-app-secret whatsapp-verify-token; do
  grant_secret gudmeal-api "$s"
done
for s in agents-database-url agents-checkpoint-url gemini-api-key gemini-model channel-token-secret; do
  grant_secret gudmeal-agents "$s"
done

say "Cloud Storage for riders' KYC documents"
BUCKET="${STORAGE_BUCKET:-$PROJECT.firebasestorage.app}"
if exists gcloud storage buckets describe "gs://$BUCKET"; then
  gcloud storage buckets add-iam-policy-binding "gs://$BUCKET" \
    --member "serviceAccount:gudmeal-api@$PROJECT.iam.gserviceaccount.com" --role roles/storage.objectAdmin >/dev/null
else
  echo "Turn on Storage in the Firebase console (it creates gs://$BUCKET), then run this script again."
fi

if [[ "$WITH_SQL" == "--with-cloud-sql" ]]; then
  TIER=$([[ "$ENV_NAME" == "prod" ]] && echo db-custom-2-7680 || echo db-custom-1-3840)
  AVAIL=$([[ "$ENV_NAME" == "prod" ]] && echo REGIONAL || echo ZONAL)
  cat <<EOF

Cloud SQL for PostgreSQL 16 — tier $TIER, availability $AVAIL, backups + point-in-time recovery.
This is BILLED HOURLY even when idle (see docs/COST_ESTIMATE.md).
EOF
  read -r -p "Create the Cloud SQL instance now? (yes/no) " OK
  if [[ "$OK" == "yes" ]]; then
    exists gcloud sql instances describe gudmeal-sql ||
      gcloud sql instances create gudmeal-sql --database-version POSTGRES_16 --region "$REGION" --tier "$TIER" \
        --availability-type "$AVAIL" --backup-start-time 02:00 --enable-point-in-time-recovery \
        --storage-auto-increase --deletion-protection
    for db in gudmeal gudmeal_agents; do
      exists gcloud sql databases describe "$db" --instance gudmeal-sql || gcloud sql databases create "$db" --instance gudmeal-sql
    done
    echo "Create DB users with generated passwords and store the connection URLs in Secret Manager:"
    echo "  gcloud sql users create gudmeal_api --instance gudmeal-sql --password=<generated>"
  fi
fi

# The services' public URLs (deterministic run.app URLs, the same ones deploy.sh uses).
source "$(dirname "$0")/urls.sh"

cat <<EOF

In the Firebase console for $PROJECT (needs you, before the first deploy):
  - Project settings → Your apps: register one Web app for the three websites. Put its apiKey and appId in the
    GitHub Environment variables FIREBASE_API_KEY and FIREBASE_APP_ID (see docs/DEPLOYMENT.md).
  - Authentication → Settings → Authorized domains: add ${WEB_URL#https://}, ${PARTNER_URL#https://} and
    ${ADMIN_URL#https://}.
  - App Check: create a reCAPTCHA Enterprise key for those three domains, register it for the web app and set the
    GitHub Environment variable APP_CHECK_SITE_KEY (required for production, where the API enforces App Check).

Next steps (after the first deploy):
  API_URL=$API_URL
  gcloud run services add-iam-policy-binding gudmeal-api --region $REGION \\
    --member serviceAccount:gudmeal-tasks@$PROJECT.iam.gserviceaccount.com --role roles/run.invoker
  gcloud pubsub subscriptions create gudmeal-events-push --topic gudmeal-domain-events \\
    --push-endpoint "\$API_URL/internal/events" --push-auth-service-account gudmeal-tasks@$PROJECT.iam.gserviceaccount.com \\
    --push-auth-token-audience "\$API_URL" --dead-letter-topic gudmeal-domain-events-dlq --max-delivery-attempts 10
  for job in "relay-outbox|* * * * *" "reconcile-payments|*/10 * * * *" "sweep|*/5 * * * *" "renew-plus|0 7 * * *"; do
    gcloud scheduler jobs create http "gudmeal-\${job%%|*}" --location $REGION --schedule "\${job##*|}" \\
      --uri "\$API_URL/internal/jobs/\${job%%|*}" --http-method POST \\
      --oidc-service-account-email gudmeal-tasks@$PROJECT.iam.gserviceaccount.com --oidc-token-audience "\$API_URL"
  done
  Budget alert: gcloud billing budgets create --billing-account <ACCOUNT_ID> --display-name "gudmeal-$ENV_NAME" \\
    --budget-amount 100USD --threshold-rule percent=0.5 --threshold-rule percent=0.9 --threshold-rule percent=1.0
EOF
