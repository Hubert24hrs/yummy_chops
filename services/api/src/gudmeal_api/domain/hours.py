"""Opening hours evaluated in the restaurant's local time zone (Africa/Lagos by default)."""

from __future__ import annotations

from datetime import UTC, datetime, time, timedelta
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from pydantic import BaseModel, Field, field_validator

LAGOS = ZoneInfo("Africa/Lagos")


def known_zone(name: str) -> ZoneInfo | None:
    """The time zone called `name` (e.g. "Africa/Lagos"), or None when there is no such zone."""
    try:
        return ZoneInfo(name)
    except (ZoneInfoNotFoundError, ValueError, OSError):  # unknown or malformed name, or a folder of zones
        return None


def _parse_hhmm(value: str) -> time:
    hours, minutes = value.split(":")
    h, m = int(hours), int(minutes)
    if h == 24 and m == 0:
        return time(23, 59, 59)
    return time(h, m)


class TimeRange(BaseModel):
    open: str = Field(pattern=r"^([01]\d|2[0-3]):[0-5]\d$")
    close: str = Field(pattern=r"^(([01]\d|2[0-3]):[0-5]\d|24:00)$")

    @property
    def overnight(self) -> bool:
        return _parse_hhmm(self.close) <= _parse_hhmm(self.open)


class OpeningHours(BaseModel):
    """`weekly[0]` is Monday … `weekly[6]` is Sunday. Ranges may cross midnight (e.g. 18:00–02:00)."""

    timezone: str = "Africa/Lagos"
    weekly: dict[int, list[TimeRange]] = Field(default_factory=dict)
    closed_dates: list[str] = Field(default_factory=list)  # ISO dates, local time

    @field_validator("weekly")
    @classmethod
    def _valid_days(cls, v: dict[int, list[TimeRange]]) -> dict[int, list[TimeRange]]:
        if any(day not in range(7) for day in v):
            raise ValueError("weekday keys must be 0..6")
        return v

    @classmethod
    def every_day(cls, open_: str, close: str) -> OpeningHours:
        return cls(weekly={d: [TimeRange(open=open_, close=close)] for d in range(7)})

    def tz(self) -> ZoneInfo | None:
        """The shop's time zone. None when the stored name is not a zone we know: the shop then counts as closed
        (partners' input is checked when it is saved, see `RestaurantSettingsInput`)."""
        return known_zone(self.timezone)


def is_open(hours: OpeningHours, at: datetime) -> bool:
    if at.tzinfo is None:
        raise ValueError("`at` must be timezone-aware")
    tz = hours.tz()
    if tz is None:  # one shop's bad time zone must never take the whole catalogue down
        return False
    local = at.astimezone(tz)
    if local.date().isoformat() in hours.closed_dates:
        return False
    now_t = local.time()
    for rng in hours.weekly.get(local.weekday(), []):
        o, c = _parse_hhmm(rng.open), _parse_hhmm(rng.close)
        if rng.overnight:
            if now_t >= o:
                return True
        elif o <= now_t < c:
            return True
    # An overnight range that started yesterday may still be running.
    yesterday = (local.weekday() - 1) % 7
    for rng in hours.weekly.get(yesterday, []):
        if rng.overnight and now_t < _parse_hhmm(rng.close):
            return True
    return False


def next_opening(hours: OpeningHours, after: datetime, horizon_days: int = 7) -> datetime | None:
    """Earliest opening time strictly after `after` (UTC), or None if closed for the horizon."""
    if is_open(hours, after):
        return after
    tz = hours.tz()
    if tz is None:
        return None
    local = after.astimezone(tz)
    candidates: list[datetime] = []
    for offset in range(horizon_days + 1):
        day = (local + timedelta(days=offset)).date()
        if day.isoformat() in hours.closed_dates:
            continue
        for rng in hours.weekly.get(day.weekday(), []):
            start = datetime.combine(day, _parse_hhmm(rng.open), tzinfo=tz)
            if start > local:
                candidates.append(start)
    return min(candidates).astimezone(UTC) if candidates else None
