"""Private files (rider KYC documents and photos): kept by the API, never public.

Clients send files through the API, which checks what they are (by their first bytes, not the name the client gives)
and how big they are, then stores them:

* `memory`: tests;
* `local`: a git-ignored folder on this computer (the local stack and the phone test);
* `gcs`: the project's Cloud Storage bucket, under `applications/{uid}/...` (the path storage.rules keeps private to
  the applicant and staff). The API reaches it with its own service account.

Files are read back only through API endpoints that check who is asking (the rider for their own files, the
reviewing team for anyone's).
"""

from __future__ import annotations

import asyncio
from pathlib import Path
from typing import Any, Protocol

from ..errors import NotFound, ValidationFailed

MAX_BYTES = 5 * 1024 * 1024  # a phone photo after the app has shrunk it is well under this

_SIGNATURES: tuple[tuple[bytes, str], ...] = (
    (b"\xff\xd8\xff", "image/jpeg"),
    (b"\x89PNG\r\n\x1a\n", "image/png"),
    (b"%PDF-", "application/pdf"),
)
EXTENSIONS = {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp", "application/pdf": "pdf"}


def sniff(data: bytes) -> str | None:
    """What the bytes really are: JPEG, PNG, WebP or PDF, else None."""
    for signature, content_type in _SIGNATURES:
        if data.startswith(signature):
            return content_type
    if len(data) >= 12 and data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "image/webp"
    return None


def check_upload(data: bytes, allowed: set[str]) -> str:
    """The upload's content type, after checking its size and that it is one of the allowed kinds."""
    if not data:
        raise ValidationFailed("The file is empty")
    if len(data) > MAX_BYTES:
        raise ValidationFailed(f"The file is too large (at most {MAX_BYTES // (1024 * 1024)} MB)")
    content_type = sniff(data)
    if content_type not in allowed:
        kinds = " or ".join(sorted({EXTENSIONS[t].upper() for t in allowed}))
        raise ValidationFailed(f"Upload a {kinds} file")
    return content_type


class FileStore(Protocol):
    async def put(self, path: str, data: bytes, content_type: str) -> None: ...

    async def get(self, path: str) -> tuple[bytes, str]: ...


class MemoryFileStore:
    def __init__(self) -> None:
        self.files: dict[str, tuple[bytes, str]] = {}

    async def put(self, path: str, data: bytes, content_type: str) -> None:
        self.files[path] = (data, content_type)

    async def get(self, path: str) -> tuple[bytes, str]:
        if path not in self.files:
            raise NotFound("File not found")
        return self.files[path]


class LocalFileStore:
    """A folder on this computer; each file's content type is kept next to it."""

    def __init__(self, root: str | Path) -> None:
        self.root = Path(root).resolve()

    def _file(self, path: str) -> Path:
        target = (self.root / path).resolve()
        if self.root not in target.parents:
            raise ValidationFailed("Invalid file path")
        return target

    async def put(self, path: str, data: bytes, content_type: str) -> None:
        target = self._file(path)

        def write() -> None:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            target.with_name(target.name + ".type").write_text(content_type, encoding="utf-8")

        await asyncio.to_thread(write)

    async def get(self, path: str) -> tuple[bytes, str]:
        target = self._file(path)

        def read() -> tuple[bytes, str]:
            if not target.is_file():
                raise NotFound("File not found")
            kind = target.with_name(target.name + ".type")
            content_type = kind.read_text(encoding="utf-8") if kind.is_file() else "application/octet-stream"
            return target.read_bytes(), content_type

        return await asyncio.to_thread(read)


class GcsFileStore:
    """The project's Cloud Storage bucket (Firebase Storage)."""

    def __init__(self, bucket_name: str, client: Any | None = None) -> None:
        if client is None:
            from google.cloud import storage

            client = storage.Client()
        self.bucket = client.bucket(bucket_name)

    async def put(self, path: str, data: bytes, content_type: str) -> None:
        blob = self.bucket.blob(path)
        await asyncio.to_thread(blob.upload_from_string, data, content_type=content_type)

    async def get(self, path: str) -> tuple[bytes, str]:
        blob = self.bucket.blob(path)

        def read() -> tuple[bytes, str]:
            if not blob.exists():
                raise NotFound("File not found")
            data = blob.download_as_bytes()
            return data, blob.content_type or "application/octet-stream"

        return await asyncio.to_thread(read)


__all__ = [
    "EXTENSIONS",
    "MAX_BYTES",
    "FileStore",
    "GcsFileStore",
    "LocalFileStore",
    "MemoryFileStore",
    "check_upload",
    "sniff",
]
