import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { assertFails, initializeTestEnvironment, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { getBytes, ref, uploadBytes } from "firebase/storage";
import { afterAll, beforeAll, describe, it } from "vitest";

let env: RulesTestEnvironment;
const PNG = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-gudmeal-rules",
    storage: { rules: readFileSync(resolve(__dirname, "../storage.rules"), "utf8") },
  });
  await env.withSecurityRulesDisabled(async (ctx) => {
    await uploadBytes(ref(ctx.storage(), "applications/rider-1/kyc/nin.png"), PNG, { contentType: "image/png" });
  });
});
afterAll(async () => env.cleanup());

const people = () => ({
  "signed out": env.unauthenticatedContext().storage(),
  customer: env.authenticatedContext("cust-1", { roles: [] }).storage(),
  "the rider": env.authenticatedContext("rider-1", { roles: ["rider"] }).storage(),
  "a shop owner": env
    .authenticatedContext("owner-1", { roles: ["restaurant_owner"], restaurant_roles: { "r-jj": "owner" } })
    .storage(),
  "super admin": env.authenticatedContext("admin-1", { roles: ["super_admin"] }).storage(),
});

describe("storage: files go through the API only", () => {
  it("nobody reads the bucket directly, not even a rider's own KYC documents", async () => {
    for (const storage of Object.values(people())) {
      await assertFails(getBytes(ref(storage, "applications/rider-1/kyc/nin.png")));
    }
  });
  it("nobody uploads directly", async () => {
    for (const [who, storage] of Object.entries(people())) {
      for (const path of ["applications/rider-1/kyc/selfie.png", "public/restaurants/r-jj/logo.png", `users/${who}/a.png`]) {
        await assertFails(uploadBytes(ref(storage, path), PNG, { contentType: "image/png" }));
      }
    }
  });
});
