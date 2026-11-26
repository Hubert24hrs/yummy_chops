import type { Metadata } from "next";
import { RequireAuth } from "@/components/require-auth";
import { GroupView } from "./group-view";

export const metadata: Metadata = { title: "Group order", robots: { index: false } };

export default async function GroupOrderPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return (
    <RequireAuth>
      <GroupView id={id} />
    </RequireAuth>
  );
}
