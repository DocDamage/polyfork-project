#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import hashlib
import json
from pathlib import Path
import re
import sys
import time
from urllib.parse import urlparse

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa

ROOT = Path(__file__).resolve().parents[2]
PRODUCT_PATH = ROOT / "config/release/product.json"
CHANNELS = {"stable", "beta", "development"}
KINDS = {"portable", "installer"}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def canonical_json(value: object) -> bytes:
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"), sort_keys=False).encode("utf-8")


def safe_filename(value: str) -> bool:
    return bool(re.fullmatch(r"[A-Za-z0-9_.-]{1,200}", value)) and ".." not in value and not value.endswith((".", " "))


def validate_url(value: str) -> None:
    parsed = urlparse(value)
    if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password or any(char.isspace() for char in value) or "\\" in value:
        raise SystemExit(f"Artifact URL is unsafe: {value}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--channel", required=True, choices=sorted(CHANNELS))
    parser.add_argument("--key-id", required=True)
    parser.add_argument("--private-key", required=True)
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--release-notes", required=True)
    parser.add_argument("--portable", required=True)
    parser.add_argument("--portable-url", required=True)
    parser.add_argument("--installer", required=True)
    parser.add_argument("--installer-url", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--published-at-unix", type=int, default=0)
    parser.add_argument("--minimum-updater-version", default="0.1.0")
    args = parser.parse_args()
    product = json.loads(PRODUCT_PATH.read_text(encoding="utf-8"))
    if args.channel == "stable" and "-" in product["version"]:
        raise SystemExit("Stable channel cannot publish a prerelease version.")
    if not re.fullmatch(r"[0-9a-f]{40}", args.source_commit):
        raise SystemExit("Source commit must be a full lowercase Git SHA.")
    notes_path = Path(args.release_notes).resolve()
    notes = notes_path.read_text(encoding="utf-8").strip()
    if not notes or len(notes.encode("utf-8")) > 65536:
        raise SystemExit("Release notes are missing or too large.")
    key_path = Path(args.private_key).resolve()
    try:
        key_path.relative_to(ROOT)
    except ValueError:
        pass
    else:
        raise SystemExit("Private signing key must remain outside the repository.")
    key_data = key_path.read_bytes()
    private_key = serialization.load_pem_private_key(key_data, password=None)
    if not isinstance(private_key, rsa.RSAPrivateKey) or private_key.key_size < 2048:
        raise SystemExit("Update manifest requires an RSA private key of at least 2048 bits.")
    artifacts = []
    for kind, path_value, url in (("portable", args.portable, args.portable_url), ("installer", args.installer, args.installer_url)):
        path = Path(path_value).resolve()
        if kind not in KINDS or not path.is_file() or not safe_filename(path.name):
            raise SystemExit(f"{kind.capitalize()} artifact is missing or unsafe.")
        if kind == "portable" and path.suffix.lower() != ".zip":
            raise SystemExit("Portable artifact must be a ZIP.")
        if kind == "installer" and path.suffix.lower() != ".exe":
            raise SystemExit("Installer artifact must be an EXE.")
        validate_url(url)
        artifacts.append({"kind": kind, "platform": "Windows", "architecture": "x86_64", "filename": path.name, "url": url, "size": path.stat().st_size, "sha256": sha256(path)})
    payload = {
        "schema_version": 1,
        "product_name": product["product_name"],
        "version": product["version"],
        "channel": args.channel,
        "published_at_unix": args.published_at_unix or int(time.time()),
        "minimum_updater_version": args.minimum_updater_version,
        "release_notes": notes,
        "source_commit": args.source_commit,
        "data_schema_version": int(product.get("application_data_schema_version", 1)),
        "artifacts": artifacts,
    }
    payload_bytes = canonical_json(payload)
    signature = private_key.sign(payload_bytes, padding.PKCS1v15(), hashes.SHA256())
    envelope = {
        "schema_version": 1,
        "algorithm": "rsa-sha256",
        "key_id": args.key_id,
        "payload_encoding": "base64-json",
        "payload": base64.b64encode(payload_bytes).decode("ascii"),
        "signature": base64.b64encode(signature).decode("ascii"),
    }
    output = Path(args.output).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(envelope, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: Signed {args.channel} update manifest created for {product['version']} at {output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
