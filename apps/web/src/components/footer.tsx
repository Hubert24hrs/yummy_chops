import { Logo } from "@gudmeal/ui";
import Link from "next/link";

export function Footer() {
  return (
    <footer className="mt-16 border-t border-border bg-surface pb-20 md:pb-0">
      <div className="container-page grid gap-8 py-10 sm:grid-cols-2 lg:grid-cols-4">
        <div className="space-y-3">
          <Logo />
          <p className="max-w-xs text-sm text-muted">Food, pharmacy, beauty & skin care, groceries, foodstuff and package delivery in Lagos and Enugu, with Yummy, an AI assistant that plans to your budget.</p>
        </div>
        <FooterCol title="Order" links={[["Order Food", "/food"], ["Pharmacy", "/pharmacy"], ["Beauty & Skin Care", "/beauty"], ["Shop & Groceries", "/groceries"], ["Buy Foodstuff", "/foodstuff"], ["Send a package", "/send"], ["Track a package", "/track"], ["Ask Yummy", "/assistant"], ["My orders", "/orders"]]} />
        <FooterCol title="Partner" links={[["Add your business", "/partner-with-us"], ["Ride with Yummy Chops", "/ride"]]} />
        <FooterCol title="Help" links={[["Support", "/support"], ["Help centre", "/help"], ["Privacy", "/help#privacy"], ["Terms", "/help#terms"]]} />
      </div>
      <div className="container-page border-t border-border py-4 text-xs text-muted">
        © {new Date().getFullYear()} Yummy Chops. Prices in Naira (₦) include VAT where applicable.
      </div>
    </footer>
  );
}

function FooterCol({ title, links }: { title: string; links: [string, string][] }) {
  return (
    <div>
      <p className="mb-3 text-sm font-semibold">{title}</p>
      <ul className="space-y-2 text-sm text-muted">
        {links.map(([label, href]) => (
          <li key={href}><Link href={href} className="hover:text-text">{label}</Link></li>
        ))}
      </ul>
    </div>
  );
}
