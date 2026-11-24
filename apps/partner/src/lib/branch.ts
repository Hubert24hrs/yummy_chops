import type { Restaurant } from "@gudmeal/api-client";

/** Where a shop is and, for a business's branch, which one (ADR-0028): "Ikeja GRA branch · Ikeja", "Lekki Phase 1
 * branch", or just the area for a shop that is not in a business. Branches share their business's name. */
export function branchLine(r: Pick<Restaurant, "area" | "business_id" | "branch_name">): string {
  if (!r.business_id) return r.area;
  const name = r.branch_name?.trim() || r.area;
  return name === r.area ? `${r.area} branch` : `${name} branch · ${r.area}`;
}
