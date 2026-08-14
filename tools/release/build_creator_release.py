#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
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
RUNTIME_SOURCE_ROOTS = ("src/export/runtime/StandaloneRuntime.tscn", "src/network/network_runtime_service.gd")
RUNTIME_TEXT_EXTENSIONS = {"gd", "tscn", "tres", "gdshader", "cfg", "godot"}
RUNTIME_REFERENCE = re.compile(r"res://[A-Za-z0-9_./\\-]+\.[A-Za-z0-9_]+")
PRIVATE_KEY_BLOCK = re.compile(
    rb"-----BEGIN (?:(?:RSA|OPENSSH|EC) )?PRIVATE KEY-----[\r\n]+"
    rb"(?:[A-Za-z0-9+/=]{16,}[\r\n]+){2,}"
    rb"-----END (?:(?:RSA|OPENSSH|EC) )?PRIVATE KEY-----"
)
SECRET_PATTERN = re.compile(rb"(?i)(?:sk-(?:proj-)?[a-z0-9_-]{24,}|(?:api|secret|access)[_-]?key\s*[:=]\s*['\"]?[a-z0-9_./+-]{20,})")

PROTECTED_TOP_LEVEL = {"projects", "asset_library", "user_data", "updates", "release", "recovery", "checkpoints", "preferences", "support"}

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


def mark_generated_outputs_ignored() -> None:
    artifact_root = ROOT / "artifacts"
    artifact_root.mkdir(parents=True, exist_ok=True)
    (artifact_root / ".gdignore").write_text("# Generated release/test outputs are not project source.\n", encoding="utf-8")


def copy_docs(package_dir: Path) -> None:
    target = package_dir / "docs"
    target.mkdir(parents=True, exist_ok=True)
    notices = ROOT / "THIRD_PARTY_NOTICES.md"
    if notices.exists():
        shutil.copy2(notices, target / notices.name)
    release_docs = ROOT / "docs" / "release"
    if release_docs.is_dir():
        for source in sorted(release_docs.glob("*.md")):
            shutil.copy2(source, target / source.name)


def normalize_runtime_reference(value: str) -> str:
    normalized = value.strip().replace("\\", "/")
    if normalized.startswith("res://"):
        normalized = normalized[6:]
    while normalized.startswith("./"):
        normalized = normalized[2:]
    return normalized


def runtime_source_closure() -> list[str]:
    queued = sorted(set(RUNTIME_SOURCE_ROOTS))
    seen: set[str] = set()
    while queued:
        relative = queued.pop(0)
        if relative in seen:
            continue
        source = (ROOT / relative).resolve()
        try:
            source.relative_to(ROOT)
        except ValueError as exc:
            raise SystemExit(f"Unsafe runtime source dependency: {relative}") from exc
        if not source.is_file():
            raise SystemExit(f"Runtime source dependency is missing: {relative}")
        seen.add(relative)
        if source.suffix.lower().lstrip(".") not in RUNTIME_TEXT_EXTENSIONS:
            continue
        text = source.read_text(encoding="utf-8")
        for match in RUNTIME_REFERENCE.finditer(text):
            dependency = normalize_runtime_reference(match.group(0))
            if dependency == "export_manifest.json" or dependency.startswith("runtime_data/"):
                continue
            if not dependency or dependency.startswith("../") or "/../" in dependency:
                raise SystemExit(f"Unsafe runtime source reference: {dependency}")
            if dependency not in seen and dependency not in queued:
                queued.append(dependency)
        queued.sort()
    return sorted(seen)


def copy_runtime_source(package_dir: Path) -> None:
    target_root = package_dir / "tools" / "runtime_source"
    for relative in runtime_source_closure():
        source = ROOT / relative
        target = target_root / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)


def iter_files(root: Path):
    yield from sorted((path for path in root.rglob("*") if path.is_file()), key=lambda path: path.relative_to(root).as_posix())


def security_scan(package_dir: Path) -> None:
    forbidden_parts = ("/tests/", "/.github/", "/downloads/", "/.git/", "/artifacts/")
    scan_suffixes = {".pck", ".json", ".txt", ".md", ".cfg", ".ini", ".gd", ".tscn", ".tres", ".gdshader", ".godot", ".log", ".yml", ".yaml"}
    for path in iter_files(package_dir):
        relative_path = path.relative_to(package_dir).as_posix()
        rel = "/" + relative_path.lower()
        if relative_path.split("/", 1)[0].lower() in PROTECTED_TOP_LEVEL:
            raise SystemExit(f"Protected user-data path entered release package: {rel}")
        if any(part in rel for part in forbidden_parts) or path.name.lower() in {".env", ".env.local", "id_rsa", "id_ed25519"}:
            raise SystemExit(f"Forbidden development material in release package: {rel}")
        if path.suffix.lower() not in scan_suffixes:
            continue
        data = path.read_bytes()
        if PRIVATE_KEY_BLOCK.search(data) or SECRET_PATTERN.search(data):
            raise SystemExit(f"Credential-like material detected in release package file: {rel}")


def manifest_files(package_dir: Path) -> list[dict[str, object]]:
    result = []
    for path in iter_files(package_dir):
        if path.name in {"release_manifest.json", "SHA256SUMS.txt"}:
            continue
        result.append({"path": path.relative_to(package_dir).as_posix(), "size": path.stat().st_size, "sha256": sha256(path)})
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
    parser.add_argument("--updater-helper", required=True)
    parser.add_argument("--output-root", default="artifacts/phase19/release")
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--source-date-epoch", required=True, type=int)
    args = parser.parse_args()
    product = json.loads(PRODUCT_PATH.read_text(encoding="utf-8"))
    version = product["version"]
    package_name = f"{product['package_prefix']}-{version}-Windows-x64"
    if version != "0.2.0" or product.get("channel") != "stable":
        raise SystemExit("Phase 19 release builder requires stable 0.2.0 product identity.")
    if not re.fullmatch(r"[0-9a-f]{40}", args.source_commit):
        raise SystemExit("Source commit must be a full lowercase Git SHA.")
    mark_generated_outputs_ignored()
    output_root = (ROOT / args.output_root).resolve()
    package_dir = output_root / package_name
    if output_root.exists():
        shutil.rmtree(output_root)
    package_dir.mkdir(parents=True)
    godot = Path(args.godot).resolve()
    template_root = Path(args.template_root).resolve()
    updater_helper = Path(args.updater_helper).resolve()
    if not godot.is_file():
        raise SystemExit("Godot release builder executable is missing.")
    if not updater_helper.is_file():
        raise SystemExit("External updater helper executable is missing.")
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
    updater_target = package_dir / "tools" / "updater"
    updater_target.mkdir(parents=True)
    shutil.copy2(updater_helper, updater_target / "PlayWorldUpdater.exe")
    copy_runtime_source(package_dir)
    copy_docs(package_dir)
    (package_dir / "install_mode.txt").write_text("portable\n", encoding="utf-8")
    security_scan(package_dir)
    godot_version = subprocess.check_output([str(godot), "--version"], text=True).strip()
    build_time = dt.datetime.fromtimestamp(args.source_date_epoch, dt.timezone.utc).isoformat().replace("+00:00", "Z")
    manifest = {
        "schema_version": 3,
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
        "user_data_policy": "outside_install_directory",
        "supported_upgrade_from": product.get("upgrade_from", []),
        "updater": {"schema_version": 1, "helper": "tools/updater/PlayWorldUpdater.exe", "portable_and_installed": True},
        "migration": {"application_schema_version": product.get("application_data_schema_version", 1), "project_schema_version": product.get("project_schema_version", 1)},
        "included_files": manifest_files(package_dir),
    }
    manifest_path = package_dir / "release_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    sums = [f"{sha256(path)}  {path.relative_to(package_dir).as_posix()}" for path in iter_files(package_dir) if path.name != "SHA256SUMS.txt"]
    (package_dir / "SHA256SUMS.txt").write_text("\n".join(sums) + "\n", encoding="utf-8")
    security_scan(package_dir)
    for path in iter_files(package_dir):
        print(f"PACKAGE_FILE_SHA256 {path.relative_to(package_dir).as_posix()} {sha256(path)}")
    zip_path = output_root / f"{package_name}.zip"
    deterministic_zip(package_dir, zip_path, args.source_date_epoch)
    checksum_path = output_root / f"{zip_path.name}.sha256"
    checksum_path.write_text(f"{sha256(zip_path)}  {zip_path.name}\n", encoding="ascii")
    print(f"PASS: Phase 19 stable creator release package built: {zip_path.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
