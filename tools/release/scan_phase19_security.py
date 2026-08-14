#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys

PRIVATE_KEY_BLOCK = re.compile(
    rb"-----BEGIN (?:(?:RSA|OPENSSH|EC) )?PRIVATE KEY-----[\r\n]+"
    rb"(?:[A-Za-z0-9+/=]{16,}[\r\n]+){2,}"
    rb"-----END (?:(?:RSA|OPENSSH|EC) )?PRIVATE KEY-----"
)
SECRET_PATTERNS = [
    # Require a token boundary so public strings such as TLS-PSK-WITH-... do
    # not get misclassified as an OpenAI-style credential.
    re.compile(rb"(?i)(?<![a-z0-9])sk-(?:proj-)?[a-z0-9_-]{24,}"),
    re.compile(rb"(?i)(?:api|secret|access)[_-]?key\s*[:=]\s*['\"]?[a-z0-9_./+-]{20,}"),
    re.compile(rb"gh[pousr]_[A-Za-z0-9_]{30,}"),
]
TEXT_SUFFIXES = {".gd", ".cs", ".py", ".json", ".cfg", ".ini", ".md", ".txt", ".yml", ".yaml", ".tscn", ".tres", ".iss", ".log", ".ps1", ".sh"}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("roots", nargs="+", help="Source/package/support roots to scan")
    args = parser.parse_args()
    errors: list[str] = []
    for root_value in args.roots:
        root = Path(root_value).resolve()
        if not root.exists():
            errors.append(f"Scan root does not exist: {root}")
            continue
        paths = [root] if root.is_file() else root.rglob("*")
        for path in paths:
            if not path.is_file():
                continue
            relative = path.name if root.is_file() else path.relative_to(root).as_posix()
            lower = relative.lower()
            if any(part in f"/{lower}/" for part in ("/.git/", "/node_modules/", "/.godot/", "/__pycache__/")):
                continue
            if path.name.lower() in {".env", ".env.local", "id_rsa", "id_ed25519"} or path.suffix.lower() in {".pem", ".p12", ".pfx", ".key"}:
                errors.append(f"Private/credential file is forbidden: {relative}")
                continue
            if path.suffix.lower() not in TEXT_SUFFIXES and path.stat().st_size > 8 * 1024 * 1024:
                continue
            data = path.read_bytes()
            if PRIVATE_KEY_BLOCK.search(data):
                errors.append(f"Private key material detected: {relative}")
            if any(pattern.search(data) for pattern in SECRET_PATTERNS):
                errors.append(f"Credential-like material detected: {relative}")
            if "support" in lower and (b"project.json" in data or b"absolute_user_path" in data or b"OPENAI_API_KEY" in data):
                errors.append(f"Support bundle privacy boundary failed: {relative}")
    if errors:
        for error in errors:
            print(f"FAIL: {error}", file=sys.stderr)
        return 1
    print("PASS: Phase 19 source/package/support private-key, credential, and privacy scans completed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
