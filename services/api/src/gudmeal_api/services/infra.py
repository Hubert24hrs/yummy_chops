"""Infrastructure ports and adapters: event bus, task queue, notifications, identity administration."""

from __future__ import annotations

import asyncio
import base64
import json
import logging
import uuid
from collections import defaultdict
from collections.abc import Awaitable, Callable
from datetime import UTC, datetime, timedelta
from typing import Any, Protocol

from ..domain.models import Notification
from ..logging_setup import log_event
from ..repositories import Repositories

logger = logging.getLogger(__name__)

EventHandler = Callable[[dict[str, Any]], Awaitable[None]]
TaskHandler = Callable[[dict[str, Any]], Awaitable[None]]


# ------------------------------------------------------------------------------------------------
# Events
# ------------------------------------------------------------------------------------------------


class EventHandlers:
    def __init__(self) -> None:
        self._handlers: dict[str, list[EventHandler]] = defaultdict(list)

    def on(self, topic: str, handler: EventHandler) -> None:
        self._handlers[topic].append(handler)

    async def dispatch(self, topic: str, payload: dict[str, Any]) -> None:
        for handler in self._handlers.get(topic, []):
            await handler(payload)


class EventBus(Protocol):
    async def publish(self, topic: str, payload: dict[str, Any]) -> None: ...


class InProcessEventBus:
    """Delivers events synchronously to local handlers (local dev and tests)."""

    def __init__(self, handlers: EventHandlers) -> None:
        self.handlers = handlers
        self.published: list[tuple[str, dict[str, Any]]] = []

    async def publish(self, topic: str, payload: dict[str, Any]) -> None:
        self.published.append((topic, payload))
        await self.handlers.dispatch(topic, payload)


class PubSubEventBus:
    """Publishes to one Pub/Sub topic; the event name travels in the `topic` attribute."""

    def __init__(self, project_id: str, topic_id: str) -> None:
        from google.cloud import pubsub_v1

        self._publisher = pubsub_v1.PublisherClient()
        self._topic_path = self._publisher.topic_path(project_id, topic_id)

    async def publish(self, topic: str, payload: dict[str, Any]) -> None:
        data = json.dumps(payload, default=str).encode()
        future = self._publisher.publish(self._topic_path, data, topic=topic)
        await asyncio.to_thread(future.result, 30)


def decode_pubsub_push(body: dict[str, Any]) -> tuple[str, dict[str, Any]]:
    message = body.get("message") or {}
    topic = (message.get("attributes") or {}).get("topic", "")
    payload = json.loads(base64.b64decode(message.get("data") or b"e30=") or b"{}")
    return topic, payload


class Emitter:
    """Publishes events whose source of truth is Firestore. Failures are logged; sweeper jobs reconcile."""

    def __init__(self, bus: EventBus) -> None:
        self.bus = bus

    async def emit(self, topic: str, payload: dict[str, Any]) -> None:
        try:
            await self.bus.publish(topic, {**payload, "emitted_at": datetime.now(UTC).isoformat()})
        except Exception:
            logger.exception("event handler failed", extra={"extra_fields": {"topic": topic}})


# ------------------------------------------------------------------------------------------------
# Tasks (timers)
# ------------------------------------------------------------------------------------------------


class TaskQueue(Protocol):
    async def enqueue(self, path: str, payload: dict[str, Any], *, delay_seconds: int = 0) -> None: ...


class TaskRouter:
    def __init__(self) -> None:
        self.routes: dict[str, TaskHandler] = {}

    def route(self, path: str, handler: TaskHandler) -> None:
        self.routes[path] = handler

    async def run(self, path: str, payload: dict[str, Any]) -> None:
        handler = self.routes.get(path)
        if handler is None:
            raise KeyError(f"No task handler for {path}")
        await handler(payload)


class InProcessTaskQueue:
    def __init__(self, router: TaskRouter) -> None:
        self.router = router
        self._tasks: set[asyncio.Task[None]] = set()

    async def enqueue(self, path: str, payload: dict[str, Any], *, delay_seconds: int = 0) -> None:
        task = asyncio.create_task(self._run(path, payload, delay_seconds))
        self._tasks.add(task)
        task.add_done_callback(self._tasks.discard)

    async def _run(self, path: str, payload: dict[str, Any], delay: int) -> None:
        await asyncio.sleep(delay)
        try:
            await self.router.run(path, payload)
        except Exception:
            logger.exception("in-process task failed", extra={"extra_fields": {"path": path}})


class RecordingTaskQueue:
    """Test double: records tasks; `run_due()` executes them deterministically."""

    def __init__(self, router: TaskRouter) -> None:
        self.router = router
        self.tasks: list[tuple[str, dict[str, Any], int]] = []

    async def enqueue(self, path: str, payload: dict[str, Any], *, delay_seconds: int = 0) -> None:
        self.tasks.append((path, payload, delay_seconds))

    async def run_all(self, path: str | None = None) -> int:
        pending = [t for t in self.tasks if path is None or t[0] == path]
        self.tasks = [t for t in self.tasks if t not in pending]
        for p, payload, _ in pending:
            await self.router.run(p, payload)
        return len(pending)


class CloudTasksQueue:
    def __init__(
        self,
        *,
        project_id: str,
        location: str,
        queue: str,
        base_url: str,
        service_account: str,
        audience: str,
    ) -> None:
        from google.cloud import tasks_v2

        self._tasks_v2 = tasks_v2
        self._client = tasks_v2.CloudTasksAsyncClient()
        self._parent = self._client.queue_path(project_id, location, queue)
        self._base = base_url.rstrip("/")
        self._sa = service_account
        self._audience = audience

    async def enqueue(self, path: str, payload: dict[str, Any], *, delay_seconds: int = 0) -> None:
        from google.protobuf import timestamp_pb2

        schedule = timestamp_pb2.Timestamp()
        schedule.FromDatetime(datetime.now(UTC) + timedelta(seconds=delay_seconds))
        task = {
            "http_request": {
                "http_method": self._tasks_v2.HttpMethod.POST,
                "url": f"{self._base}{path}",
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps(payload, default=str).encode(),
                "oidc_token": {"service_account_email": self._sa, "audience": self._audience},
            },
            "schedule_time": schedule,
        }
        await self._client.create_task(parent=self._parent, task=task)


# ------------------------------------------------------------------------------------------------
# Notifications
# ------------------------------------------------------------------------------------------------


class Notifier:
    """Writes an in-app inbox notification and (optionally) pushes it via FCM."""

    def __init__(self, repos: Repositories, *, use_fcm: bool = False) -> None:
        self.repos = repos
        self.use_fcm = use_fcm
        self.sent: list[Notification] = []

    async def notify_user(self, uid: str, title: str, body: str, data: dict[str, str] | None = None) -> None:
        note = Notification(
            id=uuid.uuid4().hex,
            recipient_uid=uid,
            title=title,
            body=body,
            data=data or {},
            created_at=datetime.now(UTC),
        )
        self.sent.append(note)
        try:
            await self.repos.notifications.create(note)
            if self.use_fcm:
                await self._push(uid, note)
        except Exception:
            logger.exception("notification failed", extra={"extra_fields": {"uid": uid}})
        log_event(logger, "notification", uid=uid, title=title)

    async def notify_restaurant(
        self, restaurant_id: str, title: str, body: str, data: dict[str, str] | None = None
    ) -> None:
        restaurant = await self.repos.restaurants.get(restaurant_id)
        if restaurant and restaurant.owner_uid:
            await self.notify_user(
                restaurant.owner_uid, title, body, {**(data or {}), "restaurant_id": restaurant_id}
            )
        if self.use_fcm:
            await self._push_topic(f"restaurant-{restaurant_id}", title, body, data or {})

    async def _push(self, uid: str, note: Notification) -> None:
        from firebase_admin import messaging

        user = await self.repos.get_user(uid) or {}
        tokens = [t for t in user.get("device_tokens", []) if isinstance(t, str)][:20]
        if not tokens:
            return
        message = messaging.MulticastMessage(
            tokens=tokens,
            notification=messaging.Notification(title=note.title, body=note.body),
            data={k: str(v) for k, v in note.data.items()},
        )
        response = await asyncio.to_thread(messaging.send_each_for_multicast, message)
        invalid = [tokens[i] for i, r in enumerate(response.responses) if not r.success]
        if invalid:
            await self.repos.upsert_user(uid, {"device_tokens": [t for t in tokens if t not in invalid]})

    async def _push_topic(self, topic: str, title: str, body: str, data: dict[str, str]) -> None:
        from firebase_admin import messaging

        message = messaging.Message(
            topic=topic, notification=messaging.Notification(title=title, body=body), data=data
        )
        try:
            await asyncio.to_thread(messaging.send, message)
        except Exception:
            logger.exception("topic push failed", extra={"extra_fields": {"topic": topic}})


# ------------------------------------------------------------------------------------------------
# Identity administration (custom claims)
# ------------------------------------------------------------------------------------------------


class IdentityAdmin(Protocol):
    async def set_claims(self, uid: str, roles: list[str], restaurant_roles: dict[str, str]) -> None: ...
    async def get_claims(self, uid: str) -> dict[str, Any]: ...
    async def lookup(self, uid: str) -> dict[str, Any]: ...


class FirebaseIdentityAdmin:
    def __init__(self, app: Any) -> None:
        self._app = app

    async def set_claims(self, uid: str, roles: list[str], restaurant_roles: dict[str, str]) -> None:
        from firebase_admin import auth

        before = await self.get_claims(uid)
        await asyncio.to_thread(
            auth.set_custom_user_claims,
            uid,
            {"roles": sorted(set(roles)), "restaurant_roles": restaurant_roles},
            app=self._app,
        )
        # A role taken away must stop working now, so that person signs in again. A role given (a rider
        # applicant, a new branch) only needs the app to refresh its token, which the apps do themselves.
        old_roles = set(before.get("roles") or []) if isinstance(before.get("roles"), list) else set()
        old_shops = before.get("restaurant_roles") if isinstance(before.get("restaurant_roles"), dict) else {}
        removed = bool(old_roles - set(roles)) or any(
            restaurant_roles.get(rid) != role for rid, role in old_shops.items()
        )
        if removed:
            await asyncio.to_thread(auth.revoke_refresh_tokens, uid, app=self._app)

    async def get_claims(self, uid: str) -> dict[str, Any]:
        from firebase_admin import auth

        user = await asyncio.to_thread(auth.get_user, uid, app=self._app)
        return dict(user.custom_claims or {})

    async def lookup(self, uid: str) -> dict[str, Any]:
        from firebase_admin import auth

        user = await asyncio.to_thread(auth.get_user, uid, app=self._app)
        return {
            "uid": user.uid,
            "email": user.email,
            "phone": user.phone_number,
            "name": user.display_name,
            "disabled": user.disabled,
        }


class MemoryIdentityAdmin:
    def __init__(self) -> None:
        self.claims: dict[str, dict[str, Any]] = {}
        self.users: dict[str, dict[str, Any]] = {}

    async def set_claims(self, uid: str, roles: list[str], restaurant_roles: dict[str, str]) -> None:
        self.claims[uid] = {"roles": sorted(set(roles)), "restaurant_roles": dict(restaurant_roles)}

    async def get_claims(self, uid: str) -> dict[str, Any]:
        return dict(self.claims.get(uid, {}))

    async def lookup(self, uid: str) -> dict[str, Any]:
        return self.users.get(uid, {"uid": uid})
