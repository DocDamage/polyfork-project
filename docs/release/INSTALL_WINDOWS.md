# Install PlayWorld Studio 0.1.0 on Windows

PlayWorld Studio 0.1.0 supports both a portable ZIP and a normal installer. Neither requires a Godot installation or development checkout.

## Installer

Use:

`PlayWorld-Studio-0.1.0-Windows-x64-Setup.exe`

The installer copies the creator executable, bundled Godot exporter, Windows export templates, runtime source closure, release documentation/notices and support files. It creates normal Start Menu integration and a Windows uninstall entry.

An alternate destination directory is supported. The application payload may be placed in a restricted/read-only-style location because authored data is stored outside the installation directory.

## Portable ZIP

Use:

`PlayWorld-Studio-0.1.0-Windows-x64.zip`

1. Verify the adjacent `.sha256` file.
2. Extract the entire ZIP.
3. Keep `tools/` beside `PlayWorld Studio.exe`; it contains bundled export tooling.
4. Launch `PlayWorld Studio.exe`.

## User data

Projects, shared Asset Library catalog/source registrations, preferences, migration/recovery records and support diagnostics use Godot per-user storage under the current Windows profile. They are not stored in the installer directory.

## Repair/reinstall/uninstall

Running the 0.1.0 installer again repairs/replaces application files while per-user authored state remains separate. Normal uninstall removes the installed application payload and shortcuts but intentionally does **not** delete authored user data.

To remove authored data as well, back up anything wanted first, then remove the PlayWorld Studio per-user data separately. The Phase 18 uninstaller does not silently perform that destructive action.

See `USER_DATA_AND_UPGRADE.md` and `TROUBLESHOOTING.md`.

<!-- PHASE19_CORRECTION_STATUS_START -->
## 0.2.0 update candidate

Phase 19 distinguishes portable replacement from installed-mode installer handoff. Both preserve persistent per-user data outside the application directory. The accepted `0.1.0` application does not contain this updater; the real `0.1.0 → 0.2.0` bootstrap uses the verified replacement ZIP or installer path and is proven in the Phase 19 Windows workflow.
<!-- PHASE19_CORRECTION_STATUS_END -->
