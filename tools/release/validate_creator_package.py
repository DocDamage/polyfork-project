#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
PRODUCT = json.loads((ROOT / "config/release/product.json").read_text(encoding="utf-8"))
PRIVATE_KEY_BLOCK = re.compile(
    rb"-----BEGIN (?:(?:RSA|OPENSSH|EC) )?PRIVATE KEY-----[\r\n]+"
    rb"(?:[A-Za-z0-9+/=]{16,}[\r\n]+){2,}"
    rb"-----END (?:(?:RSA|OPENSSH|EC) )?PRIVATE KEY-----"
)
SECRET = re.compile(rb"(?i)(?:sk-(?:proj-)?[a-z0-9_-]{24,}|(?:api|secret|access)[_-]?key\s*[:=]\s*['\"]?[a-z0-9_./+-]{20,})")

PROTECTED_TOP_LEVEL = {"projects", "asset_library", "user_data", "updates", "release", "recovery", "checkpoints", "preferences", "support"}

def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def safe_relative(value: str) -> Path:
    normalized = value.replace("\\", "/")
    if not normalized or normalized.startswith("/") or ":" in normalized:
        raise SystemExit(f"Unsafe release inventory path: {value}")
    parts = normalized.split("/")
    if any(part in {"", ".", ".."} for part in parts):
        raise SystemExit(f"Unsafe release inventory path: {value}")
    if parts[0].lower() in PROTECTED_TOP_LEVEL:
        raise SystemExit(f"Protected user-data path entered release inventory: {value}")
    return Path(*parts)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("package_dir")
    args = parser.parse_args()
    root = Path(args.package_dir).resolve()
    manifest_path = root / "release_manifest.json"
    sums_path = root / "SHA256SUMS.txt"
    required = [
        root / "PlayWorld Studio.exe",
        root / "install_mode.txt",
        root / "tools/godot/godot.exe",
        root / "tools/updater/PlayWorldUpdater.exe",
        root / "tools/export_templates/4.7.1.stable/windows_release_x86_64.exe",
        root / "tools/runtime_source/src/export/runtime/StandaloneRuntime.tscn",
        root / "tools/runtime_source/src/network/network_runtime_service.gd",
        manifest_path,
        sums_path,
    ]
    missing = [str(path.relative_to(root)) for path in required if not path.is_file()]
    if missing:
        raise SystemExit("Missing required release files: " + ", ".join(missing))
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("schema_version") != 3 or manifest.get("product_name") != "PlayWorld Studio":
        raise SystemExit("Release manifest schema/product identity is invalid.")
    if manifest.get("version") != PRODUCT["version"] or manifest.get("channel") != "stable" or manifest.get("architecture") != "x86_64":
        raise SystemExit("Phase 19 release manifest product identity is invalid.")
    if manifest.get("user_data_policy") != "outside_install_directory" or "0.1.0" not in manifest.get("supported_upgrade_from", []):
        raise SystemExit("Phase 19 release manifest is missing upgrade/user-data policy.")
    updater = manifest.get("updater", {})
    if updater.get("helper") != "tools/updater/PlayWorldUpdater.exe" or not updater.get("portable_and_installed"):
        raise SystemExit("Phase 19 release manifest does not declare the updater helper.")
    inventory = manifest.get("included_files", [])
    if not isinstance(inventory, list) or not inventory:
        raise SystemExit("Release manifest inventory is missing.")
    expected: set[str] = set()
    for item in inventory:
        relative = safe_relative(str(item.get("path", ""))).as_posix()
        if relative.lower() in {value.lower() for value in expected}:
            raise SystemExit("Release manifest contains duplicate paths.")
        expected.add(relative)
        path = root / relative
        if not path.is_file() or sha256(path) != item.get("sha256") or path.stat().st_size != item.get("size"):
            raise SystemExit(f"Release manifest included-file validation failed: {relative}")
    actual = {path.relative_to(root).as_posix() for path in root.rglob("*") if path.is_file() and path.name not in {"release_manifest.json", "SHA256SUMS.txt"}}
    if actual != expected:
        raise SystemExit(f"Release package inventory differs from the signed manifest: missing={sorted(expected - actual)} unexpected={sorted(actual - expected)}")
    sums: dict[str, str] = {}
    for line in sums_path.read_text(encoding="utf-8").splitlines():
        digest, relative = line.split("  ", 1)
        if relative in sums:
            raise SystemExit("Duplicate SHA256SUMS entry.")
        sums[relative] = digest
    for relative, digest in sums.items():
        path = root / safe_relative(relative)
        if not path.is_file() or sha256(path) != digest:
            raise SystemExit(f"Release SHA-256 validation failed: {relative}")
    forbidden = ("/tests/", "/.github/", "/downloads/", "/.git/", "/artifacts/")
    scan_suffixes = {".pck", ".json", ".txt", ".md", ".cfg", ".ini", ".gd", ".tscn", ".tres", ".gdshader", ".godot", ".log"}
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        relative = "/" + path.relative_to(root).as_posix().lower()
        if any(value in relative for value in forbidden) or path.name.lower() in {".env", ".env.local", "id_rsa", "id_ed25519"}:
            raise SystemExit(f"Forbidden development file in release package: {relative}")
        if path.suffix.lower() in scan_suffixes:
            data = path.read_bytes()
            if PRIVATE_KEY_BLOCK.search(data) or SECRET.search(data):
                raise SystemExit(f"Credential/private-key material detected in release package: {relative}")
    if (root / "install_mode.txt").read_text(encoding="utf-8").strip() != "portable":
        raise SystemExit("Portable package install-mode marker is invalid.")
    print("PASS: Phase 19 creator package inventory, updater, integrity, path, and credential scans completed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
