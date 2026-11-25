import type { NextConfig } from "next";

// Shop pictures (covers, logos, menu photos) are kept in this project's Firebase Storage bucket under
// public/restaurants/ (firebase/storage.rules). Only those go through the image optimizer: a whole host such as
// storage.googleapis.com would let anyone resize pictures from their own bucket at our cost. No project, no pictures.
const project = process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID;
const remotePatterns = (project ? [`${project}.firebasestorage.app`, `${project}.appspot.com`] : []).flatMap((bucket) => [
  { protocol: "https" as const, hostname: "firebasestorage.googleapis.com", pathname: `/v0/b/${bucket}/o/public%2Frestaurants%2F*` },
  { protocol: "https" as const, hostname: "storage.googleapis.com", pathname: `/${bucket}/public/restaurants/**` },
]);

const config: NextConfig = {
  // Cloud Run images (infra/docker/web.Dockerfile) build with BUILD_STANDALONE=true and run the self-contained
  // server. Next.js finds the monorepo root from package-lock.json, so hoisted node_modules are traced in.
  output: process.env.BUILD_STANDALONE === "true" ? "standalone" : undefined,
  reactStrictMode: true,
  poweredByHeader: false,
  transpilePackages: ["@gudmeal/ui", "@gudmeal/api-client", "@gudmeal/tokens"],
  images: { remotePatterns },
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "X-Frame-Options", value: "DENY" },
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
          { key: "Permissions-Policy", value: "camera=(), microphone=(self), geolocation=(self)" },
          // Browsers that have seen the site use HTTPS only for two years (Vercel adds this too; other hosts do not).
          { key: "Strict-Transport-Security", value: "max-age=63072000" },
          // Only the rules that cannot stop sign-in, maps or payments. A script-src rule needs a nonce for every page
          // and a live Firebase project to test against: not done yet.
          { key: "Content-Security-Policy", value: "base-uri 'self'; object-src 'none'; frame-ancestors 'none'; form-action 'self'" },
        ],
      },
    ];
  },
};

export default config;
