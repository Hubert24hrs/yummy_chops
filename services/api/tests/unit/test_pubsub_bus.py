"""Events published to Pub/Sub come back to the API with their name (services/infra.py)."""

from __future__ import annotations

import base64
import json
from concurrent.futures import Future
from typing import Any

from gudmeal_api.services.infra import PubSubEventBus, decode_pubsub_push


class _Publisher:
    """Stands in for google.cloud.pubsub_v1.PublisherClient, with the same argument names."""

    def __init__(self) -> None:
        self.sent: list[tuple[str, bytes, dict[str, str]]] = []

    def topic_path(self, project: str, topic: str) -> str:
        return f"projects/{project}/topics/{topic}"

    def publish(self, topic: str, data: bytes, **attrs: Any) -> Future:
        self.sent.append((topic, data, attrs))
        done: Future = Future()
        done.set_result("message-1")
        return done


async def test_an_event_is_published_and_read_back_with_its_name() -> None:
    publisher = _Publisher()
    bus = PubSubEventBus("p", "gudmeal-domain-events", publisher=publisher)
    await bus.publish("payment.succeeded", {"order_id": "o1"})
    path, data, attrs = publisher.sent[0]
    assert path == "projects/p/topics/gudmeal-domain-events"
    push = {"message": {"data": base64.b64encode(data).decode(), "attributes": attrs}}
    assert decode_pubsub_push(push) == ("payment.succeeded", {"order_id": "o1"})


def test_messages_named_the_old_way_still_arrive() -> None:
    data = base64.b64encode(json.dumps({"order_id": "o1"}).encode()).decode()
    assert (
        decode_pubsub_push({"message": {"data": data, "attributes": {"topic": "order.paid"}}})[0]
        == "order.paid"
    )
