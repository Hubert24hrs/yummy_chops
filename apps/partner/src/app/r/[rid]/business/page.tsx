"use client";

import type { Business, BusinessBranch, MyBusinesses, PlaceLookup } from "@gudmeal/api-client";
import { AddressSearch, Badge, Button, Card, Dialog, EmptyState, ErrorState, Field, Input, Select, Skeleton } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient, type QueryClient } from "@tanstack/react-query";
import { Building2, Check, Copy, Landmark, MapPin, Phone, Plus } from "lucide-react";
import Link from "next/link";
import { use, useState } from "react";
import { useApi } from "@/lib/api";
import { useAuth } from "@/lib/auth";

/**
 * The business: its unique ID, its branches (each with its own address, orders and manager's number, all selling one
 * menu) and the bank account Paystack pays its share of card payments into
 * (docs/adr/0028-business-branches-and-split-payments.md). Only the owner manages it.
 */
export default function BusinessPage({ params }: { params: Promise<{ rid: string }> }) {
  const { rid } = use(params);
  const api = useApi();
  const mine = useQuery({ queryKey: ["business"], queryFn: () => api.partner.business() });
  if (mine.isLoading) return <Skeleton className="h-96" />;
  if (mine.error || !mine.data) return <ErrorState message={(mine.error as Error)?.message ?? "Business unavailable"} onRetry={() => mine.refetch()} />;
  const business = mine.data.businesses.find((b) => b.branches.some((branch) => branch.restaurant_id === rid));
  if (business) return <BusinessView business={business} rid={rid} />;
  const shop = mine.data.without_business.find((r) => r.restaurant_id === rid);
  if (shop) return <GetBusinessId rid={rid} name={shop.name} />;
  return <EmptyState title="Only the owner manages the business" body="Ask the owner of this shop to add branches or change the bank account." />;
}

/** Puts a business the API just returned into the cached list, so the page shows it without another request. */
function remember(qc: QueryClient, saved: Business) {
  qc.setQueryData<MyBusinesses>(["business"], (old) => old && {
    businesses: old.businesses.some((b) => b.id === saved.id)
      ? old.businesses.map((b) => (b.id === saved.id ? saved : b))
      : [...old.businesses, saved],
    without_business: old.without_business.filter((r) => !saved.branches.some((b) => b.restaurant_id === r.restaurant_id)),
  });
}

const branchLabel = (b: BusinessBranch) => b.branch_name || b.area || "Branch";
/** The street address, with the area added when the address does not name it already. */
const fullAddress = (b: BusinessBranch) =>
  !b.area || b.address.toLowerCase().includes(b.area.toLowerCase()) ? b.address : `${b.address}, ${b.area}`;

function GetBusinessId({ rid, name }: { rid: string; name: string }) {
  const api = useApi();
  const qc = useQueryClient();
  const claim = useMutation({ mutationFn: () => api.partner.claimBusiness(rid), onSuccess: (saved) => remember(qc, saved) });
  return (
    <Card className="max-w-xl space-y-3 p-6">
      <Building2 className="size-8 text-primary" aria-hidden="true" />
      <h2 className="font-display text-2xl">Get your business ID</h2>
      <p className="text-sm text-muted">
        {name} gets its own business ID. With it you can add branches (customers order from the one nearest to them,
        with one menu for all) and connect your bank account, so Paystack sends your share of every card payment
        straight to you.
      </p>
      {claim.error && <p role="alert" className="text-sm text-danger">{(claim.error as Error).message}</p>}
      <Button onClick={() => claim.mutate()} loading={claim.isPending}>Get my business ID</Button>
    </Card>
  );
}

function BusinessView({ business, rid }: { business: Business; rid: string }) {
  const [adding, setAdding] = useState(false);
  const [editing, setEditing] = useState<BusinessBranch | null>(null);
  return (
    <div className="grid gap-4 xl:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]">
      <div className="min-w-0 space-y-4">
        <IdCard business={business} />
        <Card className="space-y-3 p-5">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <h2 className="font-semibold">Branches <span className="font-normal text-muted">({business.branches.length})</span></h2>
            <Button size="sm" onClick={() => setAdding(true)}><Plus className="size-4" aria-hidden="true" /> Add a branch</Button>
          </div>
          <p className="text-xs text-muted">
            Every branch sells the same menu. Customers see the branch nearest to them while it is open, and its orders
            arrive in that branch&apos;s own dashboard.
          </p>
          <ul className="divide-y divide-border" aria-label="Branches">
            {business.branches.map((b) => (
              <BranchRow key={b.restaurant_id} branch={b} current={b.restaurant_id === rid} onEdit={() => setEditing(b)} />
            ))}
          </ul>
        </Card>
      </div>
      <BankCard business={business} />
      {adding && <AddBranchDialog business={business} onClose={() => setAdding(false)} />}
      {editing && <EditBranchDialog business={business} branch={editing} onClose={() => setEditing(null)} />}
    </div>
  );
}

function IdCard({ business }: { business: Business }) {
  const [copied, setCopied] = useState(false);
  const copy = async () => {
    try {
      await navigator.clipboard.writeText(business.id);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 2000);
    } catch { /* the browser blocked the clipboard: the ID is on screen to copy by hand */ }
  };
  return (
    <Card className="flex flex-wrap items-center justify-between gap-4 p-5">
      <div className="min-w-0">
        <p className="text-xs font-semibold uppercase tracking-wide text-muted">Your business ID</p>
        <p className="font-display text-3xl tracking-wider">{business.id}</p>
        <p className="mt-1 max-w-prose text-sm text-muted">
          Every item you add is tagged with this ID, so each split payment reaches {business.name}. Quote it when you
          contact Yummy Chops.
        </p>
      </div>
      <Button variant="outline" onClick={copy}>
        {copied ? <><Check className="size-4" aria-hidden="true" /> Copied</> : <><Copy className="size-4" aria-hidden="true" /> Copy ID</>}
      </Button>
    </Card>
  );
}

function BranchRow({ branch, current, onEdit }: { branch: BusinessBranch; current: boolean; onEdit: () => void }) {
  const live = branch.status === "active" && branch.is_accepting_orders;
  const state = branch.status === "suspended" ? "Suspended" : live ? "Taking orders" : branch.status === "active" ? "Paused" : "Not live yet";
  return (
    <li className="flex flex-wrap items-start justify-between gap-3 py-3">
      <div className="min-w-0 space-y-1">
        <p className="flex flex-wrap items-center gap-2 font-semibold">
          {branchLabel(branch)}
          {branch.main && <Badge tone="info">Main branch</Badge>}
          <Badge tone={branch.status === "suspended" ? "danger" : live ? "success" : "warning"}>{state}</Badge>
          {current && <span className="text-xs font-normal text-muted">(this dashboard)</span>}
        </p>
        <p className="flex items-start gap-1 text-sm text-muted">
          <MapPin className="mt-0.5 size-4 shrink-0" aria-hidden="true" /> {fullAddress(branch)}
        </p>
        <p className="flex items-center gap-1 text-sm">
          <Phone className="size-4 shrink-0 text-muted" aria-hidden="true" />
          {branch.manager_phone
            ? <>Manager: <a href={`tel:${branch.manager_phone}`} className="font-medium text-primary-strong">{branch.manager_phone}</a></>
            : <span className="text-muted">No manager&apos;s number yet</span>}
        </p>
      </div>
      <div className="flex gap-2">
        <Button size="sm" variant="outline" onClick={onEdit} aria-label={`Edit ${branchLabel(branch)}`}>Edit</Button>
        {!current && (
          <Link href={`/r/${branch.restaurant_id}/orders`}
            className="inline-flex h-9 items-center rounded-md px-3 text-sm font-semibold text-primary hover:bg-surface-muted">
            Open
          </Link>
        )}
      </div>
    </li>
  );
}

const phoneError = (phone: string) => (phone.trim() && phone.trim().length < 7 ? "Enter the full phone number" : undefined);

function AddBranchDialog({ business, onClose }: { business: Business; onClose: () => void }) {
  const api = useApi();
  const qc = useQueryClient();
  const { refreshToken } = useAuth();
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [place, setPlace] = useState<PlaceLookup | null>(null);
  const [address, setAddress] = useState("");
  const add = useMutation({
    mutationFn: (found: PlaceLookup) => api.partner.addBranch(business.id, {
      branch_name: name.trim() || null,
      address: address.trim(),
      area: found.place.area ?? "",
      location: found.place.location,
      manager_phone: phone.trim() || null,
    }),
    onSuccess: async (saved) => {
      remember(qc, saved);
      // The owner's sign-in lists the shops they manage: refresh it so the new branch's dashboard opens.
      await refreshToken();
      await qc.invalidateQueries({ queryKey: ["my-restaurants"] });
      onClose();
    },
  });
  const outside = place !== null && !place.serviceable;
  const ready = place !== null && !outside && address.trim().length >= 5 && !phoneError(phone);
  return (
    <Dialog open onClose={onClose} title="Add a branch" footer={
      <div className="flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>Cancel</Button>
        <Button onClick={() => place && add.mutate(place)} loading={add.isPending} disabled={!ready}>Add branch</Button>
      </div>
    }>
      <div className="space-y-3">
        <p className="text-sm text-muted">
          The branch sells your menu. It stays hidden from customers until you switch on Accepting orders in its own
          dashboard.
        </p>
        <Field label="Branch name" htmlFor="branch-name" hint="Optional, for example Ikeja GRA">
          <Input id="branch-name" value={name} maxLength={60} onChange={(e) => setName(e.target.value)} />
        </Field>
        <AddressSearch
          id="branch-search"
          label="Find the branch's address"
          search={(q, session) => api.places.suggestions(q, session).then((r) => r.suggestions)}
          details={(placeId, session) => api.places.details(placeId, session)}
          onPicked={(found) => {
            add.reset();
            setPlace(found);
            setAddress(found.place.formatted_address);
          }}
        />
        {outside && <p role="alert" className="text-sm text-danger">That address is outside the areas we deliver. Try another address.</p>}
        {place && !outside && (
          <>
            <Field label="Address customers and riders see" htmlFor="branch-address" hint="Street, number and a landmark if it helps riders.">
              <Input id="branch-address" value={address} maxLength={200} onChange={(e) => setAddress(e.target.value)} />
            </Field>
            {place.place.precision !== "rooftop" && place.place.precision !== "street" && (
              <p className="text-sm text-muted">
                That match is the middle of {place.place.area ?? "the area"}: after adding the branch, put its exact pin
                in the branch&apos;s Settings, Kitchen location, so riders find it.
              </p>
            )}
          </>
        )}
        <Field label="Branch manager's phone number" htmlFor="branch-phone" hint="Optional: who Yummy Chops calls about this branch's orders"
          error={phoneError(phone)}>
          <Input id="branch-phone" inputMode="tel" autoComplete="off" value={phone} maxLength={20} onChange={(e) => setPhone(e.target.value)} />
        </Field>
        {add.error && <p role="alert" className="text-sm text-danger">{(add.error as Error).message}</p>}
      </div>
    </Dialog>
  );
}

function EditBranchDialog({ business, branch, onClose }: { business: Business; branch: BusinessBranch; onClose: () => void }) {
  const api = useApi();
  const qc = useQueryClient();
  const [name, setName] = useState(branch.branch_name ?? "");
  const [phone, setPhone] = useState(branch.manager_phone ?? "");
  const save = useMutation({
    mutationFn: () => api.partner.updateBranch(business.id, branch.restaurant_id, {
      branch_name: name.trim() || null, manager_phone: phone.trim() || null,
    }),
    onSuccess: (saved) => {
      remember(qc, saved);
      onClose();
    },
  });
  return (
    <Dialog open onClose={onClose} title={`Edit ${branchLabel(branch)}`} footer={
      <div className="flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>Cancel</Button>
        <Button onClick={() => save.mutate()} loading={save.isPending} disabled={Boolean(phoneError(phone))}>Save</Button>
      </div>
    }>
      <div className="space-y-3">
        <Field label="Branch name" htmlFor="edit-branch-name">
          <Input id="edit-branch-name" value={name} maxLength={60} onChange={(e) => setName(e.target.value)} />
        </Field>
        <Field label="Branch manager's phone number" htmlFor="edit-branch-phone" error={phoneError(phone)}>
          <Input id="edit-branch-phone" inputMode="tel" autoComplete="off" value={phone} maxLength={20} onChange={(e) => setPhone(e.target.value)} />
        </Field>
        <p className="text-sm text-muted">
          Moving this branch to a new address? Open its{" "}
          <Link href={`/r/${branch.restaurant_id}/settings`} className="font-semibold text-primary">Settings, Kitchen location</Link>:
          the pin is checked against the address there, like every shop&apos;s.
        </p>
        {save.error && <p role="alert" className="text-sm text-danger">{(save.error as Error).message}</p>}
      </div>
    </Dialog>
  );
}

function BankCard({ business }: { business: Business }) {
  const api = useApi();
  const qc = useQueryClient();
  const [changing, setChanging] = useState(!business.bank_connected);
  const banks = useQuery({ queryKey: ["banks"], queryFn: () => api.partner.banks(), enabled: changing, staleTime: 3_600_000 });
  const [bank, setBank] = useState(business.settlement_bank_code ?? "");
  const [account, setAccount] = useState("");
  const connect = useMutation({
    mutationFn: () => api.partner.connectBank(business.id, bank, account),
    onSuccess: (saved) => {
      remember(qc, saved);
      setChanging(false);
      setAccount("");
    },
  });
  const valid = bank !== "" && /^\d{10}$/.test(account);
  return (
    <Card className="h-fit min-w-0 space-y-3 p-5">
      <h2 className="flex items-center gap-2 font-semibold"><Landmark className="size-4" aria-hidden="true" /> Bank account</h2>
      <p className="text-sm text-muted">
        Paystack sends your share of every card payment straight to this account when the customer pays. Cash orders
        and adjustments are settled in your weekly payout.
      </p>
      {business.bank_connected && !changing && (
        <div className="space-y-2 rounded-lg border border-border p-3 text-sm">
          <Badge tone="success">Connected for split payments</Badge>
          <p className="font-semibold">{business.settlement_account_name}</p>
          <p className="text-muted">{business.settlement_bank_name} · account ending {business.settlement_account_last4}</p>
          <Button size="sm" variant="outline" onClick={() => setChanging(true)}>Change account</Button>
        </div>
      )}
      {changing && (
        <form className="space-y-3" onSubmit={(e) => { e.preventDefault(); if (valid) connect.mutate(); }}>
          <Field label="Bank" htmlFor="bank">
            <Select id="bank" value={bank} onChange={(e) => setBank(e.target.value)} disabled={banks.isLoading}>
              <option value="">{banks.isLoading ? "Loading banks…" : "Choose your bank"}</option>
              {banks.data?.map((b) => <option key={b.code} value={b.code}>{b.name}</option>)}
            </Select>
          </Field>
          <Field label="Account number" htmlFor="account" hint="The 10-digit account number. We keep only its last 4 digits.">
            <Input id="account" inputMode="numeric" autoComplete="off" maxLength={10} value={account}
              onChange={(e) => setAccount(e.target.value.replace(/\D/g, ""))} />
          </Field>
          {banks.error && <p role="alert" className="text-sm text-danger">{(banks.error as Error).message}</p>}
          {connect.error && <p role="alert" className="text-sm text-danger">{(connect.error as Error).message}</p>}
          <div className="flex flex-wrap gap-2">
            <Button type="submit" loading={connect.isPending} disabled={!valid}>Check and connect</Button>
            {business.bank_connected && <Button type="button" variant="ghost" onClick={() => { setChanging(false); connect.reset(); }}>Cancel</Button>}
          </div>
          <p className="text-xs text-muted">We check the account name with your bank before connecting it. It should be your business&apos;s account.</p>
        </form>
      )}
    </Card>
  );
}
