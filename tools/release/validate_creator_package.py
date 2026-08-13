#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("package_dir")
    args = parser.parse_args()
    root = Path(args.package_dir).resolve()
    manifest_path = root / "release_manifest.json"
    sums_path = root / "SHA256SUMS.txt"
    required = [
        root / "PlayWorld Studio.exe",
        root / "tools" / "godot" / "godot.exe",
        root / "tools" / "export_templates" / "4.7.1.stable" / "windows_release_x86_64.exe",
        manifest_path,
        sums_path,
    ]
    missing = [str(path.relative_to(root)) for path in required if not path.is_file()]
    if missing:
        raise SystemExit("Missing required release files: " + ", ".join(missing))
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("version") != "0.1.0-rc.1" or manifest.get("architecture") != "x86_64":
        raise SystemExit("Release manifest product identity is invalid.")
    for item in manifest.get("included_files", []):
        path = root / str(item.get("path", ""))
        if not path.is_file() or sha256(path) != item.get("sha256") or path.stat().st_size != item.get("size"):
            raise SystemExit("Release manifest included-file validation failed.")
    sums = {}
    for line in sums_path.read_text(encoding="utf-8").splitlines():
        digest, rel = line.split("  ", 1)
        sums[rel] = digest
    for rel, digest in sums.items():
        path = root / rel
        if not path.is_file() or sha256(path) != digest:
            raise SystemExit("Release SHA-256 validation failed.")
    forbidden = ("/tests/", "/.github/", "/downloads/", "/.git/")
    secret = re.compile(rb"(?i)sk-(?:proj-)?[a-z0-9_-]{24,}")
    legacy_marker = b".polyfork" + b"API"
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        rel = "/" + path.relative_to(root).as_posix().lower()
        if any(value in rel for value in forbidden) or path.name.lower() in {".env", ".env.local"}:
            raise SystemExit("Forbidden development file in release package.")
        if path.suffix.lower() in {".pck", ".json", ".txt", ".md", ".cfg", ".ini"}:
            data = path.read_bytes()
            if legacy_marker in data or secret.search(data):
                raise SystemExit("Credential-like material detected in release package.")
    print("PASS: Phase 17 creator package integrity and credential scan completed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
