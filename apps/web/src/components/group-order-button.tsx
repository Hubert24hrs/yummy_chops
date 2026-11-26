"use client";

import { ApiError, type DeliveryAddress, type Fulfillment, type SplitMode } from "@gudmeal/api-client";
import { Button, Dialog, Field, Input, Select, cn } from "@gudmeal/ui";
import { useMutation, useQuery } from "@tanstack/react-query";
import { Users } from "lucide-react";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { useApi } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { AREAS, CITY_NAMES, useLocation } from "@/lib/location";

/** "Order with friends": start a group order at this store, then share the code. */
export function GroupOrderButton({ restaurantId, canOrder }: { restaurantId: string; canOrder: boolean }) {
  const api = useApi();
  const { user } = useAuth();
  const router = useRouter();
  const { area } = useLocation();
  const [open, setOpen] = useState(false);
  const [fulfillment, setFulfillment] = useState<Fulfillment>("delivery");
  const [split, setSplit] = useState<SplitMode>("each");
  const [addressId, setAddressId] = useState("new");
  const [line1, setLine1] = useState("");
  const [areaName, setAreaName] = useState(area.name);
  const addresses = useQuery({ queryKey: ["addresses"], queryFn: () => api.me.addresses(), enabled: open && Boolean(user) });
  useEffect(() => {
    if (addresses.data?.length && addressId === "new") setAddressId(addresses.data[0]!.id);
  }, [addresses.data, addressId]);

  const address: DeliveryAddress | null = useMemo(() => {
    if (fulfillment === "pickup") return null;
    const saved = addresses.data?.find((a) => a.id === addressId);
    if (saved) return saved;
    if (line1.trim().length < 3) return null;
    const a = AREAS.find((x) => x.name === areaName) ?? area;
    return { line1: line1.trim(), area: a.name, city: CITY_NAMES[a.city], state: CITY_NAMES[a.city], location: a.location };
  }, [fulfillment, addresses.data, addressId, line1, areaName, area]);

  const create = useMutation({
    mutationFn: () => api.groups.create({ restaurant_id: restaurantId, fulfillment, delivery_address: address, split_mode: split }),
    onSuccess: (g) => router.push(`/group/${g.id}`),
  });

  if (!canOrder) return null;
  return (
    <>
      <Button variant="outline" onClick={() => setOpen(true)}>
        <Users className="size-4" aria-hidden="true" /> Order with friends
      </Button>
      {open && (
        <Dialog open onClose={() => setOpen(false)} title="Start a group order" footer={
          <Button block size="lg" loading={create.isPending} disabled={fulfillment === "delivery" && !address} onClick={() => create.mutate()}>
            Start and get a code
          </Button>
        }>
          <div className="space-y-4">
            <p className="text-sm text-muted">Friends join with a code and add their own items. You place one order when everyone is ready.</p>
            <div role="radiogroup" aria-label="Delivery or pickup" className="grid grid-cols-2 gap-2">
              {(["delivery", "pickup"] as const).map((f) => (
                <button key={f} type="button" role="radio" aria-checked={fulfillment === f} onClick={() => setFulfillment(f)}
                  className={cn("rounded-md border p-2.5 text-sm font-semibold", fulfillment === f ? "border-primary bg-primary-soft" : "border-border")}>
                  {f === "delivery" ? "Delivery" : "Pickup"}
                </button>
              ))}
            </div>
            {fulfillment === "delivery" && (
              <div className="space-y-3">
                <Field label="Deliver to" htmlFor="group-address">
                  <Select id="group-address" value={addressId} onChange={(e) => setAddressId(e.target.value)}>
                    {addresses.data?.map((a) => <option key={a.id} value={a.id}>{a.label ? `${a.label} — ` : ""}{a.line1}, {a.area}</option>)}
                    <option value="new">+ New address</option>
                  </Select>
                </Field>
                {addressId === "new" && (
                  <div className="grid gap-3 sm:grid-cols-2">
                    <Field label="Street address" htmlFor="group-line1">
                      <Input id="group-line1" value={line1} onChange={(e) => setLine1(e.target.value)} placeholder="12 Admiralty Way" />
                    </Field>
                    <Field label="Area" htmlFor="group-area">
                      <Select id="group-area" value={areaName} onChange={(e) => setAreaName(e.target.value)}>
                        {(["lagos", "enugu"] as const).map((city) => (
                          <optgroup key={city} label={CITY_NAMES[city]}>
                            {AREAS.filter((a) => a.city === city).map((a) => <option key={a.name}>{a.name}</option>)}
                          </optgroup>
                        ))}
                      </Select>
                    </Field>
                  </div>
                )}
              </div>
            )}
            <div role="radiogroup" aria-label="Who pays" className="grid gap-2">
              {([["each", "Everyone pays their own share"], ["host", "I'll pay for everyone"]] as const).map(([mode, label]) => (
                <button key={mode} type="button" role="radio" aria-checked={split === mode} onClick={() => setSplit(mode)}
                  className={cn("rounded-md border p-2.5 text-left text-sm font-semibold", split === mode ? "border-primary bg-primary-soft" : "border-border")}>
                  {label}
                </button>
              ))}
            </div>
            {create.error && <p className="text-sm text-danger" role="alert">{create.error instanceof ApiError ? create.error.message : "Something went wrong."}</p>}
          </div>
        </Dialog>
      )}
    </>
  );
}
