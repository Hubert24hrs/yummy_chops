import type { Metadata } from "next";
import { Suspense } from "react";
import { Chat } from "./chat";

export const metadata: Metadata = {
  title: "Ask Yummy, your AI assistant",
  description: "Yummy finds food, groceries, foodstuff, pharmacy items and beauty products, plans meals to your budget, books package deliveries and tracks orders, in English, Pidgin, Igbo, Yoruba or Hausa. You approve before paying.",
};

export default function AssistantPage() {
  return (
    <Suspense>
      <Chat />
    </Suspense>
  );
}
