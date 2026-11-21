import type { Metadata, Viewport } from "next";
import { Nunito, Plus_Jakarta_Sans } from "next/font/google";
import type { ReactNode } from "react";
import { BottomNav } from "@/components/bottom-nav";
import { Footer } from "@/components/footer";
import { GudyFab } from "@/components/gudy-fab";
import { Header } from "@/components/header";
import { Providers } from "@/components/providers";
import "./globals.css";

// Headings: a heavy rounded face, like the lettering of the Yummy Chops logo.
const display = Nunito({ subsets: ["latin"], variable: "--font-nunito", display: "swap", weight: ["600", "700", "800", "900"] });
const sans = Plus_Jakarta_Sans({ subsets: ["latin"], variable: "--font-jakarta", display: "swap" });

const site = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";

export const metadata: Metadata = {
  metadataBase: new URL(site),
  title: { default: "Yummy Chops: order food, pharmacy, beauty, groceries, foodstuff and package delivery", template: "%s · Yummy Chops" },
  description:
    "Order food from the best restaurants, pharmacy items, beauty and skin care products, groceries from supermarkets and fresh foodstuff bought for you at the market, and send packages across Lagos and Enugu. Ask Yummy, our AI assistant, in English, Pidgin, Igbo, Yoruba or Hausa.",
  openGraph: { type: "website", siteName: "Yummy Chops", locale: "en_NG" },
  alternates: { canonical: "/" },
};

export const viewport: Viewport = {
  themeColor: [{ media: "(prefers-color-scheme: light)", color: "#FFFBF8" }, { media: "(prefers-color-scheme: dark)", color: "#121513" }],
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en-NG" className={`${display.variable} ${sans.variable}`}>
      <body className="min-h-dvh">
        <Providers>
          <a href="#main" className="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-4 focus:z-50 focus:rounded-md focus:bg-surface focus:px-3 focus:py-2">
            Skip to content
          </a>
          <Header />
          <main id="main" className="min-h-[60vh]">{children}</main>
          <Footer />
          <BottomNav />
          <GudyFab />
        </Providers>
      </body>
    </html>
  );
}
