"use client";

import { ApiError, formatTime, type WhatsAppLinkCode, type WhatsAppStatus } from "@gudmeal/api-client";
import { Badge, Button, Card } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { MessageCircle } from "lucide-react";
import { useApi } from "@/lib/api";

/** What the customer sees: not yet available, connected, or a code to send from WhatsApp. */
export function WhatsAppConnectView({ status, code, onConnect, onDisconnect, busy = false, error }: {
  status: WhatsAppStatus;
  code?: WhatsAppLinkCode | null;
  onConnect: () => void;
  onDisconnect: () => void;
  busy?: boolean;
  error?: string | null;
}) {
  return (
    <Card className="space-y-3 p-5" aria-label="WhatsApp">
      <h2 className="flex items-center gap-2 text-lg font-extrabold">
        <MessageCircle className="size-5 text-[#25D366]" aria-hidden="true" /> Order on WhatsApp
        {status.linked && <Badge tone="success">Connected</Badge>}
      </h2>
      {!status.enabled ? (
        <p className="text-sm text-muted">Chatting with Yummy on WhatsApp is coming soon.</p>
      ) : status.linked ? (
        <>
          <p className="text-sm">Yummy knows your WhatsApp number <strong>{status.number}</strong>. Order, track and ask for help in a chat; you still approve every order and pay on the secure page.</p>
          <div className="flex flex-wrap gap-2">
            {status.chat_link && <a href={status.chat_link} target="_blank" rel="noreferrer"><Button>Chat with Yummy</Button></a>}
            <Button variant="outline" loading={busy} onClick={onDisconnect}>Disconnect</Button>
          </div>
        </>
      ) : code ? (
        <div className="space-y-2" role="status">
          <p className="text-sm">Send this code to Yummy Chops on WhatsApp ({code.business_number}) before {formatTime(code.expires_at)}:</p>
          <p className="font-mono text-3xl font-black tracking-[0.3em]" aria-label="Your WhatsApp code">{code.code}</p>
          <a href={code.wa_link} target="_blank" rel="noreferrer"><Button>Open WhatsApp</Button></a>
          <p className="text-xs text-muted">WhatsApp opens with the message ready: just tap send. This page updates once you&apos;re connected.</p>
        </div>
      ) : (
        <>
          <p className="text-sm">Order food, groceries, foodstuff, pharmacy items, beauty products and packages, track orders and get help by chatting with Yummy on WhatsApp.</p>
          <Button loading={busy} onClick={onConnect}>Connect WhatsApp</Button>
        </>
      )}
      {error && <p className="text-sm text-danger" role="alert">{error}</p>}
    </Card>
  );
}

export function WhatsAppConnect() {
  const api = useApi();
  const qc = useQueryClient();
  const link = useMutation({ mutationFn: () => api.whatsapp.linkCode() });
  const status = useQuery({
    queryKey: ["whatsapp"],
    queryFn: () => api.whatsapp.status(),
    refetchInterval: (q) => (link.data && !q.state.data?.linked ? 4000 : false), // waiting for the code to arrive
  });
  const disconnect = useMutation({
    mutationFn: () => api.whatsapp.disconnect(),
    onSuccess: (s) => { link.reset(); qc.setQueryData(["whatsapp"], s); },
  });
  if (!status.data) return null;
  const error = [link.error, disconnect.error].find(Boolean);
  return (
    <WhatsAppConnectView status={status.data} code={status.data.linked ? null : link.data} busy={link.isPending || disconnect.isPending}
      onConnect={() => link.mutate()} onDisconnect={() => disconnect.mutate()}
      error={error ? (error instanceof ApiError ? error.message : "Something went wrong. Please try again.") : null} />
  );
}
