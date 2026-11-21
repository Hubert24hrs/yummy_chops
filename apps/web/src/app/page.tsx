import Link from "next/link";
import { BeautyArt, FoodArt, GroceryArt, MarketArt, ParcelArt, PharmacyArt } from "@/components/illustrations";
import { ServiceBubbles } from "@/components/service-bubbles";
import { AddressPill, BrandTile, SectionTitle } from "@/components/storefront";
import { safe, serverApi } from "@/lib/server-api";

export const dynamic = "force-dynamic";

/**
 * Home, kept minimal like the app's and Glovo's (ADR-0021, six services since ADR-0025): the delivery area, the six
 * services as floating bubbles on the red header (two rows of three, in the owner's order), then the places picked
 * for the customer. Nothing else: Yummy floats over every page, deals show as a "Promo" tag on the shop tiles, and
 * the business and rider sign-ups are in the footer.
 */
export default async function HomePage() {
  const [{ data: food }, { data: pharmacy }, { data: beauty }, { data: grocery }, { data: market }] = await Promise.all([
    safe(serverApi.catalog.restaurants({ limit: 8, vertical: "food", city: "lagos" })),
    safe(serverApi.catalog.restaurants({ limit: 1, vertical: "pharmacy", city: "lagos" })),
    safe(serverApi.catalog.restaurants({ limit: 4, vertical: "beauty", city: "lagos" })),
    safe(serverApi.catalog.restaurants({ limit: 1, vertical: "grocery", city: "lagos" })),
    safe(serverApi.catalog.restaurants({ limit: 1, vertical: "market", city: "lagos" })),
  ]);
  // The best restaurants, one shop of each new kind (so people find them from the home page) and beauty shops.
  const picks = [...(food ?? []).slice(0, 6), ...(pharmacy ?? []), ...(grocery ?? []), ...(market ?? []), ...(beauty ?? []).slice(0, 3)]
    .sort((a, b) => Number(b.is_featured) - Number(a.is_featured));

  return (
    <>
      <section className="gm-hero pb-12">
        <div className="container-page pt-4 md:pt-8">
          <div className="mx-auto max-w-2xl">
            <h1 className="sr-only">Yummy Chops: order food, pharmacy, beauty & skin care, groceries, foodstuff and package delivery in Lagos and Enugu</h1>
            <div className="flex justify-center"><AddressPill onDark /></div>
            <ServiceBubbles
              height={372}
              bubbles={[
                { id: "food", label: "Order Food", href: "/food", art: <FoodArt />, size: 1.08 },
                { id: "pharmacy", label: "Pharmacy", href: "/pharmacy", art: <PharmacyArt /> },
                { id: "beauty", label: "Beauty & Skin Care", href: "/beauty", art: <BeautyArt /> },
                { id: "grocery", label: "Shop & Groceries", href: "/groceries", art: <GroceryArt /> },
                { id: "market", label: "Buy Foodstuff", href: "/foodstuff", art: <MarketArt /> },
                { id: "parcel", label: "Package Delivery", href: "/send", art: <ParcelArt /> },
              ]}
            />
          </div>
        </div>
      </section>

      <div className="container-page pb-10">
        <SectionTitle info="Top-rated places near you, picked for you" action={<Link href="/discover" className="text-sm font-semibold text-primary hover:underline">See all</Link>}>
          These are for you
        </SectionTitle>
        {picks.length > 0 ? (
          <div className="-mx-4 flex gap-3 overflow-x-auto px-4 pb-2 [scrollbar-width:none]">
            {picks.map((r) => <BrandTile key={r.id} card={r} />)}
          </div>
        ) : (
          <p className="rounded-lg border border-dashed border-border p-6 text-sm text-muted">
            Stores are loading slowly right now. <Link href="/food" className="text-primary underline">Order Food</Link>.
          </p>
        )}
      </div>
    </>
  );
}
