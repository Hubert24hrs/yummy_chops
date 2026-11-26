"""Domain error hierarchy. Every error maps to a stable machine-readable `code` and HTTP status."""

from __future__ import annotations

from typing import Any


class DomainError(Exception):
    code = "domain_error"
    status_code = 400

    def __init__(self, message: str, *, details: dict[str, Any] | None = None) -> None:
        super().__init__(message)
        self.message = message
        self.details = details or {}

    def to_dict(self) -> dict[str, Any]:
        return {"code": self.code, "message": self.message, "details": self.details}


class Unauthenticated(DomainError):
    code = "unauthenticated"
    status_code = 401


class PermissionDenied(DomainError):
    code = "permission_denied"
    status_code = 403


class NotFound(DomainError):
    code = "not_found"
    status_code = 404


class Conflict(DomainError):
    code = "conflict"
    status_code = 409


class InvalidTransition(Conflict):
    code = "invalid_transition"


class QuoteExpired(Conflict):
    code = "quote_expired"


class PriceChanged(Conflict):
    code = "price_changed"


class RestaurantUnavailable(Conflict):
    code = "restaurant_unavailable"


class ItemUnavailable(Conflict):
    code = "item_unavailable"


class OutOfDeliveryArea(Conflict):
    code = "out_of_delivery_area"


class IdempotencyConflict(Conflict):
    code = "idempotency_conflict"


class ValidationFailed(DomainError):
    code = "validation_failed"
    status_code = 422


class IncorrectCode(ValidationFailed):
    """A wrong confirmation code (same error code for clients; only wrong codes count against the code limit)."""


class VoucherInvalid(ValidationFailed):
    code = "voucher_invalid"


class RateLimited(DomainError):
    code = "rate_limited"
    status_code = 429


class PaymentProviderError(DomainError):
    code = "payment_provider_error"
    status_code = 502


class ServiceUnavailable(DomainError):
    code = "service_unavailable"
    status_code = 503
