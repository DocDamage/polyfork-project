#!/usr/bin/env python3
from __future__ import annotations
import argparse
from pathlib import Path
import re
import sys

SECRET = re.compile(rb"(?i)sk-(?:proj-)?[a-z0-9_-]{24,}")
LEGACY = b".polyfork" + b"API"
FORBIDDEN_NAMES = {".env", ".env.local", ".git"}

def scan_file(path: Path) -> None:
    data = path.read_bytes()
    if LEGACY in data or SECRET.search(data): raise SystemExit(f"Credential-like material detected in {path.name}")

def scan_tree(root: Path) -> None:
    for path in root.rglob("*"):
        if not path.is_file(): continue
        if path.name.lower() in FORBIDDEN_NAMES: raise SystemExit(f"Forbidden private/development material: {path}")
        scan_file(path)

def main() -> int:
    parser = argparse.ArgumentParser(); parser.add_argument("paths", nargs="+"); args = parser.parse_args()
    for raw in args.paths:
        path = Path(raw).resolve()
        if not path.exists(): raise SystemExit(f"Scan target missing: {path}")
        scan_tree(path) if path.is_dir() else scan_file(path)
    print("PASS: Phase 18 package, installer, and support-bundle credential scan completed.")
    return 0

if __name__ == "__main__": sys.exit(main())
