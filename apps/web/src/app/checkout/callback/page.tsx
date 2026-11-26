"use client";

import { Button, Card, Spinner } from "@gudmeal/ui";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { CheckCircle2, CircleAlert, Smartphone, XCircle } from "lucide-react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import { ordersPaidTogether } from "@/components/payment-method";
import { useApi } from "@/lib/api";
import { useAuth } from "@/lib/auth";

/** While the provider has not settled the payment, it is asked about again every 2 s, up to 30 times (a minute). */
const VERIFY_RETRY_MS = 2_000;
const VERIFY_TRIES = 30;
const UNSETTLED = ["pending", "initialized"];

export default function CallbackPage() {
  return <Suspense><CallbackGate /></Suspense>;
}

function CallbackGate() {
  const { user, guestError } = useAuth();
  if (user) return <Callback />;
  if (!guestError) {
    // Firebase is still answering, or the guest is being signed in (ADR-0032).
    return <div className="container-page grid place-items-center py-20"><Spinner className="size-10 text-primary" /></div>;
  }
  return <ReturnToApp />;
}

/**
 * Payments started in the mobile app finish here, in a browser tab that is not the app. The app verifies the payment
 * itself, so this tells people to go back to it instead of asking them to sign in.
 */
function ReturnToApp() {
  return (
    <div className="container-page grid place-items-center py-20">
      <Card className="w-full max-w-md space-y-4 p-8 text-center">
        <Smartphone className="mx-auto size-12 text-primary" aria-hidden="true" />
        <h1 className="font-display text-2xl">Return to the Yummy Chops app</h1>
        <p className="text-sm text-muted">
          You can close this page. The app checks the payment and updates your order automatically.
        </p>
      </Card>
    </div>
  );
}

function Callback() {
  const params = useSearchParams();
  const api = useApi();
  const { isGuest } = useAuth();
  // Paystack appends `reference`/`trxref`; Flutterwave appends `tx_ref`.
  const reference = params.get("reference") ?? params.get("trxref") ?? params.get("tx_ref");
  const orderId = params.get("order_id");
  const isTopUp = params.get("purpose") === "wallet_topup";
  const groupId = params.get("group_order_id");
  // One payment for orders from several shops: the gateway comes back with the first order only.
  const [paidTogether] = useState(() => ordersPaidTogether(reference));

  // Never trust the redirect: ask the server to verify with the provider, straight away (never an answer kept from
  // before), then every 2 s for a short while until the provider has settled it.
  const verify = useQuery({
    queryKey: ["verify", reference],
    enabled: Boolean(reference),
    queryFn: () => api.payments.verify(reference!),
    staleTime: 0,
    gcTime: 0,
    refetchInterval: (q) =>
      q.state.data && UNSETTLED.includes(q.state.data.status) && q.state.dataUpdateCount < VERIFY_TRIES ? VERIFY_RETRY_MS : false,
  });

  const status = verify.data?.status;
  const qc = useQueryClient();
  /** Still not settled after a minute of asking: the order updates by itself when the provider settles it. */
  const answers = qc.getQueryState(["verify", reference])?.dataUpdateCount ?? 0;
  const gaveUp = Boolean(status && UNSETTLED.includes(status) && !verify.isFetching && answers >= VERIFY_TRIES);
  useEffect(() => {
    if (status !== "succeeded") return;
    void qc.invalidateQueries({ queryKey: ["orders"] });
    void qc.invalidateQueries({ queryKey: ["order-summary"] });
  }, [status, qc]);
  // An order that has just been paid for: straight to the receipt printer (ADR-0019).
  const router = useRouter();
  // One payment for several shops' orders is a "basket" payment (no order of its own): those orders are paid too.
  const purpose = verify.data?.purpose ?? "order";
  const paidOrder = status === "succeeded" && !isTopUp && (purpose === "order" || purpose === "basket");
  const paidOrderId = paidOrder ? verify.data?.order_id ?? orderId : undefined;
  const severalOrders = paidTogether.length > 1 || purpose === "basket" || (paidOrder && !paidOrderId);
  useEffect(() => {
    // Several orders: each is listed on its own on the Orders page (each has its own receipt there).
    if (paidOrder && severalOrders) router.replace("/orders");
    else if (paidOrderId) router.replace(`/orders/${paidOrderId}/receipt`);
  }, [paidOrder, severalOrders, paidOrderId, router]);
  /** Where to go from a payment that is not confirmed: back to what was being paid for. */
  const back = (
    <>
      {orderId && <Link href={`/orders/${orderId}`}><Button variant="outline" block>View order</Button></Link>}
      {isTopUp && <Link href="/wallet"><Button variant="outline" block>Back to my wallet</Button></Link>}
      {groupId && <Link href={`/group/${groupId}`}><Button variant="outline" block>Back to the group order</Button></Link>}
      {params.get("purpose") === "plus" && <Link href="/plus"><Button variant="outline" block>Back to Yummy Chops Plus</Button></Link>}
    </>
  );
  return (
    <div className="container-page grid place-items-center py-20">
      <Card className="w-full max-w-md space-y-4 p-8 text-center">
        {!reference ? (
          <p>Missing payment reference.</p>
        ) : gaveUp ? (
          <>
            <CircleAlert className="mx-auto size-12 text-warning" />
            <h1 className="font-display text-2xl">Still confirming your payment</h1>
            <p className="text-sm text-muted">
              The payment provider has not confirmed it yet. You do not need to pay again: your order updates by itself.
            </p>
            <Button block loading={verify.isFetching} onClick={() => verify.refetch()}>Check again</Button>
            <Link href="/orders"><Button variant="outline" block>Go to my orders</Button></Link>
          </>
        ) : verify.isLoading || status === "pending" || status === "initialized" ? (
          <>
            <Spinner className="mx-auto size-10 text-primary" />
            <h1 className="font-display text-2xl">Confirming your payment…</h1>
            <p className="text-sm text-muted">We&apos;re checking with the payment provider. This usually takes a few seconds.</p>
          </>
        ) : status === "succeeded" ? (
          <>
            <CheckCircle2 className="mx-auto size-12 text-secondary" />
            {verify.data?.purpose === "plus" ? (
              <>
                <h1 className="font-display text-2xl">Welcome to Yummy Chops Plus</h1>
                <p className="text-sm text-muted">Free delivery and cheaper service fees start on your next order.</p>
                <Link href="/plus"><Button size="lg" block>See my membership</Button></Link>
              </>
            ) : verify.data?.purpose === "group_share" ? (
              <>
                <h1 className="font-display text-2xl">Your share is paid</h1>
                <p className="text-sm text-muted">The order goes to the store as soon as everyone has paid.</p>
                <Link href={groupId ? `/group/${groupId}` : "/group"}><Button size="lg" block>Back to the group order</Button></Link>
              </>
            ) : isTopUp || verify.data?.purpose === "wallet_topup" ? (
              <>
                <h1 className="font-display text-2xl">Wallet topped up</h1>
                <p className="text-sm text-muted">The money is in your Yummy Chops wallet. Pay for orders in one tap.</p>
                <Link href="/wallet"><Button size="lg" block>Go to my wallet</Button></Link>
              </>
            ) : severalOrders ? (
              <>
                <h1 className="font-display text-2xl">Payment confirmed</h1>
                <p className="text-sm text-muted">Your {paidTogether.length > 1 ? `${paidTogether.length} ` : ""}orders have been sent to their shops. Opening your orders…</p>
                <Link href="/orders"><Button size="lg" block>Track my orders</Button></Link>
              </>
            ) : (
              <>
                <h1 className="font-display text-2xl">Payment confirmed</h1>
                <p className="text-sm text-muted">Your order has been sent. Opening your receipt…</p>
                <Link href={`/orders/${paidOrderId}/receipt`}><Button size="lg" block>Print my receipt</Button></Link>
                <Link href={`/orders/${paidOrderId}`}><Button variant="outline" block>Track my order</Button></Link>
              </>
            )}
          </>
        ) : status === "failed" || status === "abandoned" ? (
          // The API said the payment did not go through. Only a failed payment is "not charged" for certain: one
          // left unfinished (a bank transfer, for example) can still arrive.
          <>
            <XCircle className="mx-auto size-12 text-danger" />
            <h1 className="font-display text-2xl">Payment not completed</h1>
            <p className="text-sm text-muted">
              {status === "failed"
                ? verify.data?.failure_reason ?? "The payment was not successful. You have not been charged."
                : "The payment was not finished. If you did send the money, your order updates by itself when it arrives."}
            </p>
            {back}
          </>
        ) : status === "flagged" ? (
          // Money came in but it does not match the order (amount, currency or reference): the team sorts it out.
          <>
            <CircleAlert className="mx-auto size-12 text-warning" />
            <h1 className="font-display text-2xl">We are checking your payment</h1>
            <p className="text-sm text-muted">
              We received a payment that does not match this order, so our team is looking at it. Please do not pay again.
            </p>
            <Link href="/support"><Button block>Contact support</Button></Link>
            {back}
          </>
        ) : (
          // The check itself did not work (no connection, too many tries, another account): nothing is known about
          // the payment, so this never says the customer was not charged.
          <>
            <CircleAlert className="mx-auto size-12 text-warning" />
            <h1 className="font-display text-2xl">We could not check your payment</h1>
            <p className="text-sm text-muted">
              This does not mean the payment failed. If you were charged, your order updates by itself: you do not need to pay again.
            </p>
            {isGuest && (
              <p className="text-sm text-muted">
                <Smartphone className="mr-1 inline size-4 text-primary" aria-hidden="true" />
                Paid in the Yummy Chops app? You can close this page: the app checks the payment by itself.
              </p>
            )}
            <Button block loading={verify.isFetching} onClick={() => verify.refetch()}>Try again</Button>
            {back}
          </>
        )}
      </Card>
    </div>
  );
}
