#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
PRODUCT = json.loads((ROOT / "config/release/product.json").read_text(encoding="utf-8"))
SETUP_NAME = f"PlayWorld-Studio-{PRODUCT['version']}-Windows-x64-Setup.exe"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--package-dir", required=True)
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--iscc", default="")
    args = parser.parse_args()
    package = Path(args.package_dir).resolve()
    output = Path(args.output_dir).resolve()
    output.mkdir(parents=True, exist_ok=True)
    if not (package / "PlayWorld Studio.exe").is_file() or not (package / "tools/updater/PlayWorldUpdater.exe").is_file():
        raise SystemExit("Validated creator package is missing the creator or updater executable.")
    iscc = Path(args.iscc).resolve() if args.iscc else Path(shutil.which("ISCC.exe") or "")
    if not iscc.is_file():
        candidates = [Path(r"C:\Program Files (x86)\Inno Setup 6\ISCC.exe"), Path(r"C:\Program Files\Inno Setup 6\ISCC.exe")]
        iscc = next((path for path in candidates if path.is_file()), Path())
    if not iscc.is_file():
        raise SystemExit("Inno Setup compiler is unavailable.")
    script = ROOT / "tools" / "release" / "playworld-studio.iss"
    command = [str(iscc), f"/DPackageDir={package}", f"/DOutputDir={output}", str(script)]
    print("RUN:", " ".join(command))
    completed = subprocess.run(command, cwd=ROOT)
    if completed.returncode != 0:
        return completed.returncode
    setup = output / SETUP_NAME
    if not setup.is_file():
        raise SystemExit(f"Installer was not produced: {setup}")
    print(f"PASS: Phase 19 Windows installer built: {setup.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
