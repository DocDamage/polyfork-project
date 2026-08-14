#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import py_compile
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile

try:
    import yaml
except ImportError as error:  # pragma: no cover - explicit setup failure
    raise SystemExit("PyYAML is required for Phase 19 workflow validation: python -m pip install pyyaml") from error


def run(command: list[str], root: Path, expect_success: bool = True) -> subprocess.CompletedProcess[str]:
    completed = subprocess.run(command, cwd=root, text=True, capture_output=True)
    if (completed.returncode == 0) != expect_success:
        sys.stdout.write(completed.stdout)
        sys.stderr.write(completed.stderr)
        expectation = "succeed" if expect_success else "fail safely"
        raise SystemExit(f"Command did not {expectation}: {' '.join(command)}")
    return completed


def parse_documents(root: Path) -> None:
    json_paths = sorted((root / "config/release").glob("*.json"))
    json_paths += sorted((root / "tests/fixtures/phase19").glob("*.json"))
    for path in json_paths:
        json.loads(path.read_text(encoding="utf-8"))
    workflow_names = [
        "phase18-stable-release.yml",
        "phase19-contracts.yml",
        "phase19-publication-dry-run.yml",
        "phase19-windows-release.yml",
        "publish-playworld-studio.yml",
    ]
    for name in workflow_names:
        path = root / ".github/workflows" / name
        value = yaml.load(path.read_text(encoding="utf-8"), Loader=yaml.BaseLoader)
        if not isinstance(value, dict) or "jobs" not in value:
            raise ValueError(f"Workflow has no jobs mapping: {path}")


def balanced_source(path: Path, line_comment: str) -> None:
    text = path.read_text(encoding="utf-8")
    if "\t" in text:
        raise ValueError(f"Tab indentation is not permitted: {path}")
    pairs = {")": "(", "]": "[", "}": "{"}
    stack: list[tuple[str, int]] = []
    quote = ""
    escaped = False
    for line_number, line in enumerate(text.splitlines(), 1):
        index = 0
        while index < len(line):
            character = line[index]
            if quote:
                if escaped:
                    escaped = False
                elif character == "\\":
                    escaped = True
                elif character == quote:
                    quote = ""
                index += 1
                continue
            if line.startswith(line_comment, index):
                break
            if character in {'"', "'"}:
                quote = character
            elif character in "([{":
                stack.append((character, line_number))
            elif character in ")]}":
                if not stack or stack[-1][0] != pairs[character]:
                    raise ValueError(f"Delimiter mismatch: {path}:{line_number}")
                stack.pop()
            index += 1
    if quote:
        raise ValueError(f"Unclosed string in {path}")
    if stack:
        raise ValueError(f"Unclosed delimiter in {path}:{stack[-1][1]}")


def validate_scene_bindings(root: Path) -> None:
    pairs = [
        (root / "src/app/screens/settings/update_center.gd", root / "src/app/screens/settings/UpdateCenter.tscn"),
        (root / "src/app/screens/settings/settings_screen.gd", root / "src/app/screens/settings/SettingsScreen.tscn"),
    ]
    for script, scene in pairs:
        script_text = script.read_text(encoding="utf-8")
        scene_text = scene.read_text(encoding="utf-8")
        required = set(re.findall(r"=\s*%([A-Za-z_][A-Za-z0-9_]*)", script_text))
        unique = {
            match.group(1)
            for match in re.finditer(
                r'\[node name="([^"]+)"[^\]]*\]\s*(?:(?!\[node ).)*?unique_name_in_owner\s*=\s*true',
                scene_text,
                re.DOTALL,
            )
        }
        missing = sorted(required - unique)
        if missing:
            raise ValueError(f"Scene is missing unique-name bindings for {script.name}: {missing}")


def manifest_contracts(root: Path) -> None:
    verifier = [sys.executable, "tools/release/verify_update_manifest.py"]
    common = ["--registry", "tests/fixtures/phase19/test_keys.json", "--now-unix", "1786665600"]
    run(verifier + ["tests/fixtures/phase19/accepted-update.json", *common, "--channel", "development", "--current-version", "0.1.0"], root)
    for name in [
        "wrong-product", "wrong-channel", "wrong-platform", "unsafe-filename", "future-publication",
        "minimum-updater", "duplicate-artifacts", "unknown-field",
    ]:
        run(verifier + [f"tests/fixtures/phase19/{name}.json", *common, "--channel", "development", "--current-version", "0.1.0"], root, False)
    run(verifier + ["tests/fixtures/phase19/downgrade.json", *common, "--channel", "development", "--current-version", "0.2.0"], root, False)
    run(verifier + ["tests/fixtures/phase19/stable-prerelease.json", *common, "--channel", "stable", "--current-version", "0.2.0"], root, False)

    accepted_path = root / "tests/fixtures/phase19/accepted-update.json"
    accepted = json.loads(accepted_path.read_text(encoding="utf-8"))
    with tempfile.TemporaryDirectory(prefix="phase19-manifest-") as directory:
        directory_path = Path(directory)
        for key in ("signature", "payload"):
            altered = dict(accepted)
            raw = altered[key]
            altered[key] = ("A" if not raw.startswith("A") else "B") + raw[1:]
            candidate = directory_path / f"altered-{key}.json"
            candidate.write_text(json.dumps(altered), encoding="utf-8")
            run(verifier + [str(candidate), *common, "--channel", "development", "--current-version", "0.1.0"], root, False)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=str(Path(__file__).resolve().parents[2]))
    args = parser.parse_args()
    root = Path(args.root).resolve()
    if not (root / "project.godot").is_file():
        raise SystemExit(f"Not a PlayWorld Studio repository root: {root}")
    python_paths = [
        root / "tools/release/build_creator_release.py",
        root / "tools/release/build_update_manifest.py",
        root / "tools/release/build_windows_installer.py",
        root / "tools/release/reconcile_phase19_docs.py",
        root / "tools/release/scan_phase19_security.py",
        root / "tools/release/validate_creator_package.py",
        root / "tools/release/validate_phase19_candidate.py",
        root / "tools/release/validate_update_artifact.py",
        root / "tools/release/verify_update_manifest.py",
    ]
    for path in python_paths:
        py_compile.compile(str(path), doraise=True)
    parse_documents(root)
    gd_paths = [
        root / "src/app/screens/settings/settings_screen.gd",
        root / "src/app/screens/settings/update_center.gd",
        root / "src/release/data_migration_registry.gd",
        root / "src/release/phase19_release_maintenance.gd",
        root / "src/release/phase19_verification.gd",
        root / "src/release/product_identity.gd",
        root / "src/release/release_paths.gd",
        root / "src/release/session_recovery_service.gd",
        root / "src/release/update_journal.gd",
        root / "src/release/update_manifest.gd",
        root / "src/release/update_preferences.gd",
        root / "src/release/update_service.gd",
        root / "tests/phase19_contracts_runner.gd",
    ]
    for path in gd_paths:
        balanced_source(path, "#")
    balanced_source(root / "tools/updater/PlayWorldUpdater/Program.cs", "//")
    validate_scene_bindings(root)
    scan_roots = [
        "src/app/screens/settings/SettingsScreen.tscn",
        "src/app/screens/settings/UpdateCenter.tscn",
        "src/app/screens/settings/settings_screen.gd",
        "src/app/screens/settings/update_center.gd",
        "src/release",
        "config/release",
        "tools/release",
        "tools/updater/PlayWorldUpdater",
        "tests/fixtures/phase19",
        "tests/phase19_contracts_runner.gd",
        "docs/implementation/PHASE19_UPDATE_RELEASE_INFRASTRUCTURE_PLAN.md",
        "docs/qa/PHASE19_QA.md",
        "docs/release/MIGRATION_ROLLBACK_RECOVERY.md",
        "docs/release/PUBLICATION_AND_INCIDENTS.md",
        "docs/release/RELEASE_NOTES_0_2_0.md",
        "docs/release/SECURITY_PRIVACY.md",
        "docs/release/UPDATE_CHANNELS.md",
    ]
    run([sys.executable, "tools/release/scan_phase19_security.py", *scan_roots], root)
    manifest_contracts(root)
    print("PASS: Phase 19 candidate static, schema, signature, privacy, security, and scene-binding validation completed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
