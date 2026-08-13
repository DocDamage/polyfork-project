#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[2]
PRODUCT_PATH = ROOT / "config" / "release" / "product.json"
PRESET = "PlayWorld Studio Windows x64"
REQUIRED_TEMPLATE = "windows_release_x86_64.exe"
OPTIONAL_TEMPLATE = "windows_debug_x86_64.exe"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def run(command: list[str]) -> None:
    print("RUN:", " ".join(command))
    completed = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(completed.stdout)
    if completed.returncode != 0:
        raise SystemExit(completed.returncode)
    if re.search(r"SCRIPT ERROR:|(^|\s)ERROR:", completed.stdout, re.MULTILINE):
        raise SystemExit("Godot emitted strict errors during creator release build.")


def copy_docs(package_dir: Path) -> None:
    target = package_dir / "docs"
    target.mkdir(parents=True, exist_ok=True)
    candidates = [
        ROOT / "THIRD_PARTY_NOTICES.md",
        ROOT / "docs" / "release" / "INSTALL_WINDOWS.md",
        ROOT / "docs" / "release" / "SYSTEM_REQUIREMENTS.md",
        ROOT / "docs" / "release" / "QUICK_START.md",
        ROOT / "docs" / "release" / "WINDOWS_EXPORT.md",
        ROOT / "docs" / "release" / "TROUBLESHOOTING.md",
        ROOT / "docs" / "release" / "KNOWN_LIMITATIONS.md",
        ROOT / "docs" / "release" / "RELEASE_NOTES.md",
    ]
    for source in candidates:
        if source.exists():
            shutil.copy2(source, target / source.name)


def iter_files(root: Path):
    yield from sorted((p for p in root.rglob("*") if p.is_file()), key=lambda p: p.relative_to(root).as_posix())


def security_scan(package_dir: Path) -> None:
    forbidden_parts = ("/tests/", "/.github/", "/downloads/", "/.git/")
    secret_pattern = re.compile(rb"(?i)sk-(?:proj-)?[a-z0-9_-]{24,}")
    legacy_marker = b".polyfork" + b"API"
    for path in iter_files(package_dir):
        rel = "/" + path.relative_to(package_dir).as_posix().lower()
        if any(part in rel for part in forbidden_parts) or path.name.lower() in {".env", ".env.local"}:
            raise SystemExit(f"Forbidden development material in release package: {rel}")
        if path.suffix.lower() not in {".pck", ".json", ".txt", ".md", ".cfg", ".ini"}:
            continue
        data = path.read_bytes()
        if legacy_marker in data or secret_pattern.search(data):
            raise SystemExit(f"Credential-like material detected in release package file: {rel}")


def manifest_files(package_dir: Path) -> list[dict[str, object]]:
    result = []
    for path in iter_files(package_dir):
        if path.name in {"release_manifest.json", "SHA256SUMS.txt"}:
            continue
        result.append({
            "path": path.relative_to(package_dir).as_posix(),
            "size": path.stat().st_size,
            "sha256": sha256(path),
        })
    return result


def deterministic_zip(package_dir: Path, zip_path: Path, epoch: int) -> None:
    stamp = dt.datetime.fromtimestamp(max(epoch, 315532800), dt.timezone.utc)
    date_time = (stamp.year, stamp.month, stamp.day, stamp.hour, stamp.minute, stamp.second)
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in iter_files(package_dir):
            arcname = f"{package_dir.name}/{path.relative_to(package_dir).as_posix()}"
            info = zipfile.ZipInfo(arcname, date_time=date_time)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--template-root", required=True)
    parser.add_argument("--output-root", default="artifacts/phase17/release")
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--source-date-epoch", required=True, type=int)
    args = parser.parse_args()

    product = json.loads(PRODUCT_PATH.read_text(encoding="utf-8"))
    version = product["version"]
    package_name = f"{product['package_prefix']}-{version}-Windows-x64"
    output_root = (ROOT / args.output_root).resolve()
    package_dir = output_root / package_name
    if output_root.exists():
        shutil.rmtree(output_root)
    package_dir.mkdir(parents=True)

    godot = Path(args.godot).resolve()
    template_root = Path(args.template_root).resolve()
    if not godot.is_file():
        raise SystemExit("Godot release builder executable is missing.")
    release_template = template_root / REQUIRED_TEMPLATE
    if not release_template.is_file():
        raise SystemExit("Required Windows x64 release export template is missing.")

    run([str(godot), "--headless", "--path", str(ROOT), "--import"])
    creator_exe = package_dir / "PlayWorld Studio.exe"
    run([str(godot), "--headless", "--path", str(ROOT), "--export-release", PRESET, str(creator_exe)])
    if not creator_exe.is_file():
        raise SystemExit("Creator Windows export did not create PlayWorld Studio.exe.")

    tool_root = package_dir / "tools" / "godot"
    tool_root.mkdir(parents=True)
    shutil.copy2(godot, tool_root / "godot.exe")
    bundled_templates = package_dir / "tools" / "export_templates" / "4.7.1.stable"
    bundled_templates.mkdir(parents=True)
    shutil.copy2(release_template, bundled_templates / REQUIRED_TEMPLATE)
    debug_template = template_root / OPTIONAL_TEMPLATE
    if debug_template.is_file():
        shutil.copy2(debug_template, bundled_templates / OPTIONAL_TEMPLATE)

    copy_docs(package_dir)
    security_scan(package_dir)

    godot_version = subprocess.check_output([str(godot), "--version"], text=True).strip()
    build_time = dt.datetime.fromtimestamp(args.source_date_epoch, dt.timezone.utc).isoformat().replace("+00:00", "Z")
    manifest = {
        "schema_version": 1,
        "product_name": product["product_name"],
        "version": version,
        "channel": product["channel"],
        "source_commit": args.source_commit,
        "authoritative_base_commit": product["base_commit"],
        "godot_version": godot_version,
        "platform": "Windows",
        "architecture": "x86_64",
        "package_name": package_name,
        "build_timestamp": build_time,
        "included_files": manifest_files(package_dir),
    }
    manifest_path = package_dir / "release_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    sums = []
    for path in iter_files(package_dir):
        if path.name == "SHA256SUMS.txt":
            continue
        sums.append(f"{sha256(path)}  {path.relative_to(package_dir).as_posix()}")
    (package_dir / "SHA256SUMS.txt").write_text("\n".join(sums) + "\n", encoding="utf-8")
    security_scan(package_dir)

    zip_path = output_root / f"{package_name}.zip"
    deterministic_zip(package_dir, zip_path, args.source_date_epoch)
    zip_hash = sha256(zip_path)
    checksum_path = output_root / f"{zip_path.name}.sha256"
    checksum_path.write_text(f"{zip_hash}  {zip_path.name}\n", encoding="utf-8")
    print(f"PASS: Phase 17 creator release package built: {zip_path.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
