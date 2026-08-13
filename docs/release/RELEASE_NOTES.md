# PlayWorld Studio 0.1.0 Release Notes

## Stable release objective

Phase 18 turns the verified `0.1.0-rc.1` creator into the first stable Windows productization boundary without rewriting the editor/runtime/export architecture.

## Added for 0.1.0

- stable `0.1.0` product/About/Windows/package identity;
- deterministic `PlayWorld-Studio-0.1.0-Windows-x64.zip` plus SHA-256 and release manifest;
- `PlayWorld-Studio-0.1.0-Windows-x64-Setup.exe` Windows installer/uninstaller;
- Start Menu integration and alternate installation directory support;
- portable/installed mode diagnostics and strict per-user data separation;
- exact `0.1.0-rc.1 → 0.1.0` migration verification using the final Phase 17 artifact;
- non-destructive/idempotent migration state and backups;
- damaged-project checkpoint recovery with corrupt-metadata backup;
- malformed-preference recovery backup and safe defaults;
- Home Support action with Support & Recovery UI;
- bounded diagnostics covering version/build/runtime/OS/rendering/GPU/install mode/user-data/exporter/schema/Asset Library health;
- clean portable and clean installed first-run end-to-end verification;
- repair/reinstall and uninstall user-data preservation verification;
- installed and portable RC-profile upgrade verification;
- packaged creator→standalone Windows game export and exported-game launch;
- retained packaged controller/accessibility/focus verification;
- release payload, installer and support-bundle credential/private-material scans;
- stable packaged visual evidence and manual visual acceptance gate.

## Upgrade from 0.1.0-rc.1

Projects, registered Asset Library sources/catalog, preferences, authored IDs and project configuration remain in the same per-user PlayWorld Studio data root. Stable startup records migration state non-destructively and preserves migration/recovery backups. See `USER_DATA_AND_UPGRADE.md`.

## Installer reproducibility

The portable ZIP is required to rebuild byte-for-byte for identical inputs. The Inno Setup installer is integrity-checked and SHA-256 published, but byte-for-byte installer reproducibility is not claimed because installer compiler metadata may vary across build environments.

## Security

Release automation scans packaged material and bounded support diagnostics for forbidden development/private material and credential-like patterns. Historical credential artifacts retained only in Git history remain an external rotation/revocation concern and are not included in the release package.
