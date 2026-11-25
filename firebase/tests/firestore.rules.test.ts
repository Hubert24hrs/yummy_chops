/**
 * Firestore security rules tests. Run inside the emulator:
 *   npx firebase emulators:exec --only firestore,storage --project demo-gudmeal-rules "npm run test:rules -w firebase"
 *
 * The apps and websites read everything through the API, which gives each person their own view of an order; the
 * rules close Firestore to clients so nobody can go around those views.
 */
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { assertFails, initializeTestEnvironment, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { collection, deleteDoc, doc, getDoc, getDocs, query, setDoc, updateDoc, where } from "firebase/firestore";
import { afterAll, beforeAll, beforeEach, describe, it } from "vitest";

let env: RulesTestEnvironment;

const DOCUMENTS: Record<string, Record<string, unknown>> = {
  "restaurant_profiles/r-jj": { id: "r-jj", status: "active", name: "Jollof Junction", commission_bps: 1500 },
  "food_items/i1": { id: "i1", restaurant_id: "r-jj", price_kobo: 550000 },
  "orders/o1": { id: "o1", customer_id: "cust-1", restaurant_id: "r-jj", rider_id: "rider-1", status: "in_transit" },
  "orders/o1/customer_private/codes": { delivery_code: "1234", pickup_code: "5678" },
  "order_events/e1": { order_id: "o1", to_status: "paid" },
  "rider_profiles/rider-1": { uid: "rider-1", last_location: { lat: 6.4, lng: 3.4 } },
  "delivery_tracking/o1": { order_id: "o1", customer_id: "cust-1" },
  "notifications/n1": { recipient_uid: "cust-1", title: "Hi", read_at: null },
  "vouchers/WELCOME500": { code: "WELCOME500" },
  "customer_profiles/cust-1": { uid: "cust-1", allergens: ["peanuts"] },
  "carts/cust-1": { uid: "cust-1", lines: [] },
};

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-gudmeal-rules",
    firestore: { rules: readFileSync(resolve(__dirname, "../firestore.rules"), "utf8") },
  });
});

afterAll(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    for (const [path, data] of Object.entries(DOCUMENTS)) await setDoc(doc(ctx.firestore(), path), data);
  });
});

/** Everyone a client could be: signed out, the order's own customer, its shop, its rider and staff. */
const people = () => ({
  "signed out": env.unauthenticatedContext().firestore(),
  "the customer": env.authenticatedContext("cust-1", { roles: [] }).firestore(),
  "the shop's owner": env
    .authenticatedContext("owner-1", { roles: ["restaurant_owner"], restaurant_roles: { "r-jj": "owner" } })
    .firestore(),
  "the rider": env.authenticatedContext("rider-1", { roles: ["rider"] }).firestore(),
  "super admin": env.authenticatedContext("admin-1", { roles: ["super_admin"] }).firestore(),
});

describe("clients go through the API", () => {
  it("nobody reads any document directly", async () => {
    for (const db of Object.values(people())) {
      for (const path of Object.keys(DOCUMENTS)) await assertFails(getDoc(doc(db, path)));
    }
  });

  it("nobody lists a collection directly", async () => {
    for (const db of Object.values(people())) {
      await assertFails(getDocs(query(collection(db, "orders"), where("customer_id", "==", "cust-1"))));
      await assertFails(getDocs(collection(db, "restaurant_profiles")));
    }
  });

  it("nobody writes, changes or deletes anything directly", async () => {
    for (const db of Object.values(people())) {
      await assertFails(setDoc(doc(db, "carts/cust-1"), { uid: "cust-1", lines: [] }));
      await assertFails(updateDoc(doc(db, "orders/o1"), { status: "delivered" }));
      await assertFails(updateDoc(doc(db, "notifications/n1"), { read_at: new Date() }));
      await assertFails(deleteDoc(doc(db, "food_items/i1")));
      await assertFails(setDoc(doc(db, "anything/new"), { a: 1 }));
    }
  });
});
