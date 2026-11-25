import type { NextConfig } from "next";

const config: NextConfig = {
  // Cloud Run images (infra/docker/web.Dockerfile) build with BUILD_STANDALONE=true and run the self-contained
  // server. Next.js finds the monorepo root from package-lock.json, so hoisted node_modules are traced in.
  output: process.env.BUILD_STANDALONE === "true" ? "standalone" : undefined,
  reactStrictMode: true,
  poweredByHeader: false,
  transpilePackages: ["@gudmeal/ui", "@gudmeal/api-client", "@gudmeal/tokens"],
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
