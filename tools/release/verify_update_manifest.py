#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import binascii
import json
from pathlib import Path
import re
import sys
import time
from urllib.parse import urlparse

from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa

ROOT = Path(__file__).resolve().parents[2]
CHANNELS = {"stable", "beta", "development"}
KINDS = {"portable", "installer"}
SEMVER = re.compile(
    r"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)"
    r"(?:-((?:0|[1-9][0-9]*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*)(?:\.(?:0|[1-9][0-9]*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*))*))?"
    r"(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$"
)
MAX_MANIFEST_BYTES = 1024 * 1024
MAX_NOTES_BYTES = 64 * 1024
MAX_ARTIFACT_BYTES = 8 * 1024**3
MAX_FUTURE_SKEW = 86400


def require_shape(value: dict, required: set[str], optional: set[str] | None = None) -> None:
    optional = optional or set()
    missing = required - value.keys()
    unexpected = value.keys() - required - optional
    if missing or unexpected:
        raise ValueError(f"Schema mismatch: missing={sorted(missing)} unexpected={sorted(unexpected)}")


def load_object(path: Path, maximum: int) -> dict:
    if not path.is_file() or path.stat().st_size <= 0 or path.stat().st_size > maximum:
        raise ValueError("JSON file size is outside accepted bounds.")
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError("JSON document is not an object.")
    return value


def parse_semver(value: object) -> tuple[int, int, int, tuple[str, ...]]:
    if not isinstance(value, str):
        raise ValueError("Semantic version is not a string.")
    match = SEMVER.fullmatch(value)
    if not match:
        raise ValueError(f"Invalid semantic version: {value}")
    prerelease = tuple(match.group(4).split(".")) if match.group(4) else ()
    return int(match.group(1)), int(match.group(2)), int(match.group(3)), prerelease


def compare_semver(left: str, right: str) -> int:
    a = parse_semver(left)
    b = parse_semver(right)
    if a[:3] != b[:3]:
        return (a[:3] > b[:3]) - (a[:3] < b[:3])
    if not a[3] and not b[3]:
        return 0
    if not a[3]:
        return 1
    if not b[3]:
        return -1
    for x, y in zip(a[3], b[3]):
        if x == y:
            continue
        x_num, y_num = x.isdigit(), y.isdigit()
        if x_num and y_num:
            return (int(x) > int(y)) - (int(x) < int(y))
        if x_num != y_num:
            return -1 if x_num else 1
        return (x > y) - (x < y)
    return (len(a[3]) > len(b[3])) - (len(a[3]) < len(b[3]))


def channel_hosts(path: Path, channel: str) -> set[str]:
    value = load_object(path, MAX_MANIFEST_BYTES)
    require_shape(value, {"schema_version", "channels"})
    if value["schema_version"] != 1 or not isinstance(value["channels"], dict):
        raise ValueError("Channel configuration is invalid.")
    record = value["channels"].get(channel)
    if not isinstance(record, dict):
        raise ValueError("Selected channel has no configuration.")
    require_shape(record, {"enabled", "manifest_url", "allowed_hosts"})
    if not record["enabled"] or not isinstance(record["allowed_hosts"], list):
        raise ValueError("Selected channel is disabled or has no host policy.")
    hosts = {str(item).lower() for item in record["allowed_hosts"] if isinstance(item, str) and item}
    if not hosts:
        raise ValueError("Selected channel host allowlist is empty.")
    return hosts


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("manifest")
    parser.add_argument("--registry", required=True)
    parser.add_argument("--channel", required=True, choices=sorted(CHANNELS))
    parser.add_argument("--channel-config", default=str(ROOT / "config/release/update_channels.json"))
    parser.add_argument("--current-version", default="")
    parser.add_argument("--now-unix", type=int, default=0)
    args = parser.parse_args()
    try:
        envelope = load_object(Path(args.manifest), MAX_MANIFEST_BYTES)
        registry = load_object(Path(args.registry), MAX_MANIFEST_BYTES)
        allowed_hosts = channel_hosts(Path(args.channel_config), args.channel)
        require_shape(envelope, {"schema_version", "algorithm", "key_id", "payload_encoding", "payload", "signature"})
        require_shape(registry, {"schema_version", "keys"}, {"policy"})
        if envelope["schema_version"] != 1 or envelope["algorithm"] != "rsa-sha256" or envelope["payload_encoding"] != "base64-json":
            raise ValueError("Manifest envelope identity is unsupported.")
        if registry["schema_version"] != 1 or not isinstance(registry["keys"], list):
            raise ValueError("Trusted key registry is invalid.")
        now = args.now_unix or int(time.time())
        matches = [item for item in registry["keys"] if isinstance(item, dict) and item.get("key_id") == envelope["key_id"]]
        if len(matches) != 1:
            raise ValueError("Manifest key is not uniquely trusted.")
        record = matches[0]
        require_shape(record, {"key_id", "algorithm", "enabled", "revoked", "channels", "not_before_unix", "not_after_unix", "public_key_pem"}, {"comment"})
        if record["algorithm"] != "rsa-sha256" or not isinstance(record["channels"], list):
            raise ValueError("Trusted manifest key policy is invalid.")
        if not record["enabled"] or record["revoked"] or args.channel not in record["channels"]:
            raise ValueError("Manifest key is disabled, revoked, or unauthorized for this channel.")
        if record["not_before_unix"] and now < record["not_before_unix"]:
            raise ValueError("Manifest key is not active yet.")
        if record["not_after_unix"] and now > record["not_after_unix"]:
            raise ValueError("Manifest key has expired.")
        payload_bytes = base64.b64decode(envelope["payload"], validate=True)
        signature = base64.b64decode(envelope["signature"], validate=True)
        if base64.b64encode(payload_bytes).decode("ascii") != envelope["payload"] or base64.b64encode(signature).decode("ascii") != envelope["signature"]:
            raise ValueError("Manifest base64 is not canonical.")
        public_key = serialization.load_pem_public_key(record["public_key_pem"].encode("ascii"))
        if not isinstance(public_key, rsa.RSAPublicKey) or public_key.key_size < 2048:
            raise ValueError("Trusted manifest key is not a supported RSA public key.")
        public_key.verify(signature, payload_bytes, padding.PKCS1v15(), hashes.SHA256())
        if payload_bytes.decode("utf-8").encode("utf-8") != payload_bytes:
            raise ValueError("Signed payload is not canonical UTF-8.")
        payload = json.loads(payload_bytes.decode("utf-8"))
        if not isinstance(payload, dict):
            raise ValueError("Signed payload is not an object.")
        require_shape(payload, {"schema_version", "product_name", "version", "channel", "published_at_unix", "minimum_updater_version", "release_notes", "source_commit", "data_schema_version", "artifacts"}, {"extensions"})
        if payload["schema_version"] != 1 or payload["product_name"] != "PlayWorld Studio" or payload["channel"] != args.channel:
            raise ValueError("Signed payload schema/product/channel identity is invalid.")
        version = str(payload["version"])
        _, _, _, prerelease = parse_semver(version)
        minimum = str(payload["minimum_updater_version"])
        parse_semver(minimum)
        if args.channel == "stable" and prerelease:
            raise ValueError("Stable signed payload is a prerelease.")
        if args.current_version:
            parse_semver(args.current_version)
            if compare_semver(version, args.current_version) < 0:
                raise ValueError("Signed payload attempts a downgrade.")
            if compare_semver(args.current_version, minimum) < 0:
                raise ValueError("Signed payload requires a newer updater.")
        if not isinstance(payload["published_at_unix"], int) or payload["published_at_unix"] <= 0 or payload["published_at_unix"] > now + MAX_FUTURE_SKEW:
            raise ValueError("Signed publication time is invalid.")
        if not isinstance(payload["data_schema_version"], int) or payload["data_schema_version"] < 1:
            raise ValueError("Signed data schema version is invalid.")
        if not isinstance(payload["release_notes"], str) or not payload["release_notes"].strip() or len(payload["release_notes"].encode("utf-8")) > MAX_NOTES_BYTES:
            raise ValueError("Signed release notes are missing or too large.")
        if not re.fullmatch(r"[0-9a-f]{40}", str(payload["source_commit"])):
            raise ValueError("Signed source commit is invalid.")
        if not isinstance(payload["artifacts"], list) or not payload["artifacts"]:
            raise ValueError("Signed artifact inventory is invalid.")
        kinds: set[str] = set()
        for artifact in payload["artifacts"]:
            if not isinstance(artifact, dict):
                raise ValueError("Signed artifact entry is not an object.")
            require_shape(artifact, {"kind", "platform", "architecture", "filename", "url", "size", "sha256"}, {"release_manifest_sha256", "extensions"})
            kind = artifact["kind"]
            if kind in kinds or kind not in KINDS:
                raise ValueError("Signed artifact kinds are invalid or duplicated.")
            kinds.add(kind)
            if artifact["platform"] != "Windows" or artifact["architecture"] != "x86_64":
                raise ValueError("Signed artifact platform or architecture is invalid.")
            parsed = urlparse(artifact["url"])
            if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password or parsed.hostname.lower() not in allowed_hosts:
                raise ValueError("Signed artifact URL is unsafe or outside the selected channel allowlist.")
            filename = str(artifact["filename"])
            if not re.fullmatch(r"[A-Za-z0-9_.-]{1,200}", filename) or ".." in filename or filename.endswith((".", " ")):
                raise ValueError("Signed artifact filename is unsafe.")
            if (kind == "portable" and not filename.lower().endswith(".zip")) or (kind == "installer" and not filename.lower().endswith(".exe")):
                raise ValueError("Signed artifact filename does not match its kind.")
            if not isinstance(artifact["size"], int) or not 0 < artifact["size"] <= MAX_ARTIFACT_BYTES or not re.fullmatch(r"[0-9a-f]{64}", str(artifact["sha256"])):
                raise ValueError("Signed artifact size or hash is invalid.")
            if "release_manifest_sha256" in artifact and not re.fullmatch(r"[0-9a-f]{64}", str(artifact["release_manifest_sha256"])):
                raise ValueError("Signed release-manifest hash is invalid.")
        if kinds != KINDS:
            raise ValueError("Signed publication inventory must contain exactly one portable and one installer artifact.")
        print(f"PASS: Signed update manifest verified for {payload['channel']} {payload['version']} using {envelope['key_id']}")
        return 0
    except (ValueError, KeyError, TypeError, UnicodeDecodeError, json.JSONDecodeError, InvalidSignature, binascii.Error) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
