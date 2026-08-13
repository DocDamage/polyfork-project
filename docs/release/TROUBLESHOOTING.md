# Troubleshooting

## PlayWorld Studio will not start

Re-extract the complete ZIP and confirm `PlayWorld Studio.exe` and its `.pck` remain together. Do not move only the EXE out of the package directory.

## Existing projects do not appear

Confirm you are using the same Windows user profile. Projects are stored in per-user application data, not beside the executable.

## Asset Library source is unavailable

Restore access to the registered external folder or register its new location. PlayWorld does not silently copy or replace the original source folder.

## Windows game export says tooling is missing

Confirm `tools/godot/godot.exe` exists inside the extracted creator package. If using a custom exporter, verify the configured path or `PLAYWORLD_GODOT_EXPORTER` value points to a readable Godot 4.7.1 executable.

## Windows game export says templates are missing

Confirm `tools/export_templates/4.7.1.stable/windows_release_x86_64.exe` exists. Re-extract or reinstall the full creator package if it is missing.

## Export fails for an asset dependency

Open Asset Library and verify the referenced source is available and scans successfully. Missing required dependencies are hard failures by design.

## AI Creation is unavailable

Check provider endpoint/model configuration, privacy scope, cloud consent, and the environment variable named by `credential_env`. Credentials are not stored in provider descriptors.

## Preferences are malformed

PlayWorld falls back to safe preference defaults and reports the preference load failure. Correct or remove the malformed per-user preference file; project data is separate.
