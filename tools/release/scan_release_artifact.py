#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys

# A credential token must begin at a token boundary. This keeps standalone
# OpenAI-style keys detectable without treating the "sk-" inside public TLS
# cipher-suite names such as "PSK-WITH-..." as a credential.
SECRET = re.compile(rb"(?i)(?<![a-z0-9])sk-(?:proj-)?[a-z0-9_-]{24,}")
LEGACY = b".polyfork" + b"API"
FORBIDDEN_NAMES = {".env", ".env.local", ".git"}


def validate_scanner_patterns() -> None:
    tls_cipher = b"TLS-PSK-WITH-CHACHA20-POLY1305-SHA256"
    legacy_key = b"credential=" + b"sk-" + (b"a" * 32)
    project_key = b"credential=" + b"sk-proj-" + (b"b" * 32)

    if SECRET.search(tls_cipher):
        raise SystemExit("Credential scanner regression: TLS PSK cipher name matched as a secret.")
    if not SECRET.search(legacy_key):
        raise SystemExit("Credential scanner regression: standalone sk credential was not detected.")
    if not SECRET.search(project_key):
        raise SystemExit("Credential scanner regression: standalone sk-proj credential was not detected.")


def scan_file(path: Path) -> None:
    data = path.read_bytes()
    if LEGACY in data or SECRET.search(data):
        raise SystemExit(f"Credential-like material detected in {path.name}")


def scan_tree(root: Path) -> None:
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if path.name.lower() in FORBIDDEN_NAMES:
            raise SystemExit(f"Forbidden private/development material: {path}")
        scan_file(path)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="+")
    args = parser.parse_args()

    validate_scanner_patterns()
    for raw in args.paths:
        path = Path(raw).resolve()
        if not path.exists():
            raise SystemExit(f"Scan target missing: {path}")
        scan_tree(path) if path.is_dir() else scan_file(path)

    print("PASS: Phase 18 package, installer, and support-bundle credential scan completed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
