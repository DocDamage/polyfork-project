#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import stat
import sys
import zipfile

MAX_ARCHIVE_BYTES = 8 * 1024**3
MAX_EXPANDED_BYTES = 16 * 1024**3
MAX_ENTRIES = 50_000
PROTECTED_TOP_LEVEL = {"projects", "asset_library", "user_data", "updates", "release", "recovery", "checkpoints", "preferences", "support"}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def safe_path(value: str) -> PurePosixPath:
    normalized = value.replace("\\", "/")
    path = PurePosixPath(normalized)
    if not normalized or normalized.startswith("/") or ":" in normalized or any(part in {"", ".", ".."} for part in path.parts):
        raise ValueError(f"Unsafe archive/inventory path: {value}")
    return path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("artifact")
    parser.add_argument("--expected-sha256", default="")
    parser.add_argument("--expected-size", type=int, default=0)
    args = parser.parse_args()
    artifact = Path(args.artifact).resolve()
    if not artifact.is_file() or artifact.stat().st_size <= 0 or artifact.stat().st_size > MAX_ARCHIVE_BYTES:
        raise SystemExit("Update artifact is missing or outside accepted size bounds.")
    if args.expected_size and artifact.stat().st_size != args.expected_size:
        raise SystemExit("Update artifact byte-count mismatch.")
    digest = sha256(artifact)
    if args.expected_sha256 and digest != args.expected_sha256:
        raise SystemExit("Update artifact SHA-256 mismatch.")
    if artifact.suffix.lower() != ".zip":
        print(f"PASS: Non-archive update artifact size and SHA-256 verified: {artifact.name}")
        return 0
    seen: set[str] = set()
    expanded = 0
    with zipfile.ZipFile(artifact) as archive:
        if not 0 < len(archive.infolist()) <= MAX_ENTRIES:
            raise SystemExit("Update archive inventory is outside accepted bounds.")
        for info in archive.infolist():
            path = safe_path(info.filename.rstrip("/")) if info.filename.rstrip("/") else None
            if path is None:
                continue
            normalized = path.as_posix().lower()
            if normalized in seen:
                raise SystemExit("Update archive contains duplicate normalized paths.")
            seen.add(normalized)
            mode = info.external_attr >> 16
            if stat.S_ISLNK(mode):
                raise SystemExit("Update archive contains a symbolic link.")
            expanded += info.file_size
            if expanded > MAX_EXPANDED_BYTES:
                raise SystemExit("Update archive expands beyond accepted bounds.")
        roots = {PurePosixPath(info.filename).parts[0] for info in archive.infolist() if PurePosixPath(info.filename).parts}
        if len(roots) != 1:
            raise SystemExit("Portable update archive must contain exactly one package root.")
        root = next(iter(roots))
        for info in archive.infolist():
            parts = PurePosixPath(info.filename).parts
            if len(parts) > 1 and parts[0] == root and parts[1].lower() in PROTECTED_TOP_LEVEL:
                raise SystemExit("Protected user-data path entered portable update inventory.")
        names = {PurePosixPath(info.filename).as_posix() for info in archive.infolist()}
        required = {f"{root}/PlayWorld Studio.exe", f"{root}/release_manifest.json", f"{root}/install_mode.txt", f"{root}/tools/updater/PlayWorldUpdater.exe"}
        if not required.issubset(names):
            raise SystemExit("Portable update archive is missing required creator/updater identity files.")
        manifest = json.loads(archive.read(f"{root}/release_manifest.json"))
        if manifest.get("product_name") != "PlayWorld Studio" or manifest.get("platform") != "Windows" or manifest.get("architecture") != "x86_64":
            raise SystemExit("Portable update release manifest identity is invalid.")
    print(f"PASS: Update artifact archive traversal, link, expansion, identity, size, and SHA-256 gates passed: {artifact.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
