"""Payment webhooks, internal (Cloud Tasks / Pub/Sub / Scheduler) endpoints and the local payment sandbox."""

from __future__ import annotations

import html
import json
import uuid
from datetime import timedelta
from typing import Annotated, Any
from urllib.parse import urlparse

from fastapi import APIRouter, Query, Request
from fastapi.responses import HTMLResponse, JSONResponse, PlainTextResponse, RedirectResponse
from pydantic import BaseModel, Field

from ...domain.money import format_naira
from ...domain.whatsapp import signature
from ...errors import NotFound
from ...services.infra import decode_pubsub_push
from ...services.whatsapp import SandboxSender
from ..deps import Ctr, InternalCaller, client_ip

webhooks = APIRouter(prefix="/v1/webhooks", tags=["webhooks"])
internal = APIRouter(prefix="/internal", tags=["internal"], include_in_schema=False)
dev = APIRouter(prefix="/v1/dev", tags=["dev"], include_in_schema=False)


# Yummy on WhatsApp (ADR-0017). Registered before the payment route below, which matches any /{provider}.
@webhooks.get("/whatsapp", response_class=PlainTextResponse)
async def whatsapp_verify(
    c: Ctr,
    mode: Annotated[str | None, Query(alias="hub.mode")] = None,
    token: Annotated[str | None, Query(alias="hub.verify_token")] = None,
    challenge: Annotated[str | None, Query(alias="hub.challenge")] = None,
) -> PlainTextResponse:
    return PlainTextResponse(c.whatsapp.verify_subscription(mode, token, challenge))


@webhooks.post("/whatsapp")
async def whatsapp_webhook(request: Request, c: Ctr) -> dict[str, int]:
    raw = await request.body()
    return {"queued": await c.whatsapp.receive(raw, request.headers.get("x-hub-signature-256"))}


@webhooks.post("/{provider}")
async def payment_webhook(provider: str, request: Request, c: Ctr) -> dict[str, str]:
    raw = await request.body()
    headers = {k.lower(): v for k, v in request.headers.items()}
    return await c.payments.handle_webhook(provider, raw, headers, client_ip(request))


# ------------------------------------------------------------------------------------------------
# Internal
# ------------------------------------------------------------------------------------------------


@internal.post("/tasks/{name}")
async def run_task(name: str, payload: dict[str, Any], c: Ctr, _caller: InternalCaller) -> dict[str, str]:
    await c.task_router.run(f"/internal/tasks/{name}", payload)
    return {"status": "ok"}


@internal.post("/events")
async def pubsub_push(body: dict[str, Any], c: Ctr, _caller: InternalCaller) -> dict[str, str]:
    topic, payload = decode_pubsub_push(body)
    await c.handlers.dispatch(topic, payload)  # errors → 500 → Pub/Sub retries with backoff
    return {"status": "ok"}


@internal.post("/jobs/relay-outbox")
async def relay_outbox(c: Ctr, _caller: InternalCaller) -> dict[str, int]:
    return {"published": await c.relay.relay_pending(limit=200)}


@internal.post("/jobs/reconcile-payments")
async def reconcile_payments(c: Ctr, _caller: InternalCaller) -> dict[str, int]:
    return await c.payments.reconcile_stale()


@internal.post("/jobs/renew-plus")
async def renew_plus(c: Ctr, _caller: InternalCaller) -> dict[str, int]:
    """Daily (Cloud Scheduler): renew Yummy Chops Plus from wallets; remind members who can't be charged."""
    return await c.membership.renew_due()


@internal.post("/jobs/seed-demo")
async def seed_demo(c: Ctr, _caller: InternalCaller) -> dict[str, int]:
    """Online test server only (ENVIRONMENT=development with SEED_DEMO_DATA, never staging or production; ADR-0026): fill the
    database once with the invented demo shops, menus, riders and vouchers, open the shops around the clock
    (DEMO_SHOPS_ALWAYS_OPEN) and keep only rider@ for jobs. Saving the same ids again overwrites them."""
    s = c.settings
    if not s.seed_demo_data or s.environment in ("staging", "production"):
        raise NotFound("Not available here")
    from ...seed import seed
    from ...seed.lagos import open_demo_shops_all_day, park_extra_demo_riders

    counts = await seed(c.repos)
    if s.demo_shops_always_open:
        counts["open_all_day"] = await open_demo_shops_all_day(c.repos)
    await park_extra_demo_riders(c.repos)
    return counts


@internal.post("/jobs/demo-shops")
async def demo_shops(c: Ctr, _caller: InternalCaller) -> dict[str, int]:
    """Online test server only (DEMO_SHOP_AUTOPILOT, never staging or production; ADR-0026): nobody sits at the demo
    shops' dashboards, so they accept orders left waiting and mark accepted ones ready. Cloud Scheduler calls it every
    minute (the local stack runs the same pass every few seconds in-process)."""
    s = c.settings
    if not s.demo_shop_autopilot or s.environment in ("staging", "production"):
        raise NotFound("Not available here")
    from ...seed.autopilot import run_demo_shops

    return {"moved": await run_demo_shops(c)}


@internal.post("/jobs/sweep")
async def sweep(c: Ctr, _caller: InternalCaller) -> dict[str, int]:
    """Repairs work whose triggering event may have been lost (idempotent)."""
    settled = 0
    for order in await c.orders.unsettled_completed(timedelta(minutes=5)):
        if await c.payments.settle_completed_order(order):
            settled += 1
    purged = await c.idempotency.purge_expired()
    return {"settled": settled, "idempotency_purged": purged}


# ------------------------------------------------------------------------------------------------
# Local payment sandbox (ENVIRONMENT=local|test only — router is not mounted elsewhere)
# ------------------------------------------------------------------------------------------------


@dev.get("/sandbox-checkout/{reference}", response_class=HTMLResponse)
async def sandbox_checkout(reference: str, c: Ctr) -> HTMLResponse:
    if c.sandbox is None or reference not in c.sandbox.charges:
        raise NotFound("Unknown sandbox payment")
    charge = c.sandbox.charges[reference]
    ref = html.escape(reference)
    return HTMLResponse(f"""<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Yummy Chops · Sandbox checkout</title>
<style>body{{font-family:system-ui,sans-serif;background:#FFFBF8;color:#2A0D06;display:grid;place-items:center;
min-height:100vh;margin:0}}.card{{background:#fff;border-radius:16px;padding:32px;max-width:380px;width:90%;
box-shadow:0 8px 30px rgba(0,0,0,.08)}}.amt{{font-size:32px;font-weight:700;margin:8px 0 24px}}
button{{width:100%;padding:14px;border-radius:12px;border:0;font-size:16px;font-weight:600;margin-top:10px;cursor:pointer}}
.pay{{background:#E0040B;color:#fff}}.fail{{background:#f1f1f1;color:#2A0D06}}.note{{font-size:12px;color:#7A625A;margin-top:18px}}</style>
</head><body><div class="card"><div>Local payment sandbox</div><div class="amt">{format_naira(charge.amount_kobo)}</div>
<div>Reference <code>{ref}</code></div>
<form method="post" action="/v1/dev/sandbox-checkout/{ref}/complete?outcome=success"><button class="pay">Approve payment</button></form>
<form method="post" action="/v1/dev/sandbox-checkout/{ref}/complete?outcome=failure"><button class="fail">Decline</button></form>
<p class="note">Development only. No real money moves. Approving sends a signed webhook through the same
verification and ledger pipeline used for Paystack.</p></div></body></html>""")


@dev.post("/sandbox-checkout/{reference}/complete", response_model=None)
async def sandbox_complete(
    reference: str, outcome: str, request: Request, c: Ctr
) -> RedirectResponse | HTMLResponse:
    if c.sandbox is None:
        raise NotFound("Sandbox disabled")
    success = outcome == "success"
    body, signature, callback = c.sandbox.complete(reference, success=success)
    await c.payments.handle_webhook("local_sandbox", body, {"x-sandbox-signature": signature}, "127.0.0.1")
    if _from_another_device(request) and urlparse(callback).hostname in ("localhost", "127.0.0.1"):
        # A phone on the same Wi-Fi as the laptop (testing the app) cannot open the laptop's localhost callback;
        # the app verifies the payment itself, so send the tester back to it.
        title = "Payment approved" if success else "Payment declined"
        return HTMLResponse(f"""<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Yummy Chops · {title}</title>
<style>body{{font-family:system-ui,sans-serif;background:#FFFBF8;color:#2A0D06;display:grid;place-items:center;
min-height:100vh;margin:0}}.card{{background:#fff;border-radius:16px;padding:32px;max-width:380px;width:90%;
box-shadow:0 8px 30px rgba(0,0,0,.08);text-align:center}}h1{{font-size:24px;margin:0 0 12px}}</style>
</head><body><div class="card"><h1>{title}</h1><p>Return to the Yummy Chops app: it confirms the payment and
updates your order. You can close this page.</p></div></body></html>""")
    sep = "&" if "?" in callback else "?"
    return RedirectResponse(f"{callback}{sep}reference={reference}", status_code=303)


def _from_another_device(request: Request) -> bool:
    """True when the browser is not on the machine running the API (e.g. a phone on the same Wi-Fi)."""
    client = request.client.host if request.client else ""
    return client not in ("127.0.0.1", "::1", "localhost", request.url.hostname)


# ------------------------------------------------------------------------------------------------
# WhatsApp simulator (ENVIRONMENT=local|test only): chat with Yummy as if from WhatsApp, through the real
# signed-webhook → task → Yummy → reply pipeline, with the sandbox sender instead of Meta.
# ------------------------------------------------------------------------------------------------


class SimulatedMessage(BaseModel):
    text: str | None = Field(default=None, max_length=4000)
    button_id: str | None = Field(default=None, max_length=256)
    button_title: str | None = Field(default=None, max_length=40)
    name: str | None = Field(default=None, max_length=60)
    latitude: float | None = Field(default=None, ge=-90, le=90)  # a shared location
    longitude: float | None = Field(default=None, ge=-180, le=180)
    place: str | None = Field(default=None, max_length=120)


def _sandbox(c: Any) -> SandboxSender:
    sender = c.whatsapp.sender
    if not isinstance(sender, SandboxSender):
        raise NotFound("The WhatsApp simulator needs WHATSAPP_PROVIDER=sandbox")
    return sender


@dev.post("/whatsapp/{wa_id}/send")
async def whatsapp_simulate(wa_id: str, data: SimulatedMessage, c: Ctr) -> JSONResponse:
    sender = _sandbox(c)
    if not wa_id.isdigit() or not 10 <= len(wa_id) <= 15:
        raise NotFound("Use an international number without +, e.g. 2348012345678")
    message: dict[str, Any] = {"from": wa_id, "id": f"wamid.sim.{uuid.uuid4().hex}", "timestamp": "0"}
    if data.latitude is not None and data.longitude is not None:
        message |= {
            "type": "location",
            "location": {"latitude": data.latitude, "longitude": data.longitude, "name": data.place or ""},
        }
        shown = f"📍 {data.place or 'Shared location'}"
    elif data.button_id:
        message |= {
            "type": "interactive",
            "interactive": {
                "type": "button_reply",
                "button_reply": {"id": data.button_id, "title": data.button_title or ""},
            },
        }
        shown = f"[{data.button_title or data.button_id}]"
    else:
        message |= {"type": "text", "text": {"body": data.text or ""}}
        shown = data.text or ""
    body = {
        "object": "whatsapp_business_account",
        "entry": [
            {
                "id": "sim",
                "changes": [
                    {
                        "field": "messages",
                        "value": {
                            "messaging_product": "whatsapp",
                            "contacts": [{"wa_id": wa_id, "profile": {"name": data.name or "You"}}],
                            "messages": [message],
                        },
                    }
                ],
            }
        ],
    }
    raw = json.dumps(body).encode()
    sender.outbox[wa_id].append({"direction": "in", "type": "text", "text": {"body": shown}})
    queued = await c.whatsapp.receive(raw, signature(c.whatsapp.app_secret, raw))
    return JSONResponse({"queued": queued})


@dev.get("/whatsapp/{wa_id}/messages")
async def whatsapp_conversation(wa_id: str, c: Ctr) -> list[dict[str, Any]]:
    return list(_sandbox(c).outbox.get(wa_id, []))


@dev.get("/whatsapp", response_class=HTMLResponse)
async def whatsapp_simulator() -> HTMLResponse:
    return HTMLResponse(SIMULATOR_PAGE)


SIMULATOR_PAGE = """<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Yummy Chops · WhatsApp simulator</title>
<style>body{font-family:system-ui,sans-serif;margin:0;background:#efeae2;color:#111}header{background:#075e54;color:#fff;
padding:12px 16px}header input{width:12em}main{max-width:640px;margin:0 auto;padding:12px 12px 90px}
.m{max-width:80%;margin:6px 0;padding:8px 10px;border-radius:8px;white-space:pre-wrap;box-shadow:0 1px 1px rgba(0,0,0,.1)}
.in{background:#d9fdd3;margin-left:auto}.out{background:#fff}.b{display:inline-block;margin:6px 6px 0 0;padding:6px 10px;
border:1px solid #0a7cff;border-radius:16px;color:#0a7cff;background:#fff;cursor:pointer}form{position:fixed;bottom:0;
left:0;right:0;display:flex;gap:8px;padding:10px;background:#f0f2f5}form input{flex:1;padding:10px;border-radius:20px;
border:1px solid #ccc}form button{padding:10px 16px;border:0;border-radius:20px;background:#075e54;color:#fff}
small{opacity:.8}</style></head><body><header><b>Yummy on WhatsApp</b> · local simulator<br><small>Your number
<input id="wa" value="2348011111111"> name <input id="nm" value="Ada"> — get a code in the app (Profile → Connect
WhatsApp) and send <code>LINK 123456</code>.</small></header><main id="log"></main>
<form id="f"><select id="loc" title="Share a location"><option value="">📍</option><option value="6.4478,3.4723,Lekki Phase 1">Lekki Phase 1</option><option value="6.5095,3.3711,Yaba">Yaba</option><option value="6.4473,7.5214,Independence Layout">Independence Layout, Enugu</option></select><input id="t" placeholder="Type a message" autocomplete="off"><button>Send</button></form>
<script>
const log=document.getElementById('log'),wa=()=>document.getElementById('wa').value.trim();
async function send(body){await fetch('/v1/dev/whatsapp/'+wa()+'/send',{method:'POST',headers:{'Content-Type':'application/json'},
body:JSON.stringify({...body,name:document.getElementById('nm').value})});setTimeout(load,300)}
function esc(s){return s.replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]))}
async function load(){const r=await fetch('/v1/dev/whatsapp/'+wa()+'/messages');if(!r.ok)return;const ms=await r.json();
log.innerHTML=ms.map(m=>{let h='';if(m.type==='text')h=esc(m.text.body);else if(m.interactive){const i=m.interactive;
h=esc(i.body.text);if(i.type==='button')h+='<br>'+i.action.buttons.map(b=>'<span class="b" data-id="'+esc(b.reply.id)+
'" data-t="'+esc(b.reply.title)+'">'+esc(b.reply.title)+'</span>').join('');if(i.type==='cta_url')h+='<br><a class="b" target="_blank" href="'+
esc(i.action.parameters.url)+'">'+esc(i.action.parameters.display_text)+'</a>'}
return '<div class="m '+(m.direction==='in'?'in':'out')+'">'+h+'</div>'}).join('');window.scrollTo(0,document.body.scrollHeight)}
document.getElementById('loc').addEventListener('change',e=>{const v=e.target.value;if(!v)return;const [la,ln,pl]=v.split(',');send({latitude:+la,longitude:+ln,place:pl});e.target.value=''});
log.addEventListener('click',e=>{const b=e.target.closest('span.b');if(b)send({button_id:b.dataset.id,button_title:b.dataset.t})});
document.getElementById('f').addEventListener('submit',e=>{e.preventDefault();const t=document.getElementById('t');
if(t.value.trim())send({text:t.value.trim()});t.value=''});setInterval(load,1500);load();
</script></body></html>"""
