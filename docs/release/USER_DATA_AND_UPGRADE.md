# User Data, Upgrade, Backup, and Recovery

## Storage model

PlayWorld Studio keeps authored/user state outside the application installation directory. This includes worlds, checkpoint recovery data, shared Asset Library catalog/source registrations, UI/performance preferences, release migration state and generated support diagnostics.

Moving, replacing, repairing, or uninstalling the application package therefore does not intentionally remove authored projects.

## Upgrade from 0.1.0-rc.1 to 0.1.0

Phase 18 explicitly supports the final Phase 17 RC as its upgrade source. The release workflow verifies artifact ID `9169222546` and RC ZIP SHA-256 `8db8162872077d00582ab20de5361a59cae19a45a9bacb2a3a7f199d18b4d9b9` before creating RC user data and launching stable 0.1.0 against the same profile.

Stable startup migration records source/target version and backup information under the per-user release area. Migration is intended to be non-destructive and idempotent; an already completed migration is detected rather than repeated destructively.

## Project recovery

Project saves continue to use the existing validated/atomic persistence architecture and checkpoint store. If canonical `project.json` metadata is damaged and a valid checkpoint exists, Support & Recovery can:

1. preserve the damaged canonical metadata as a `.bak` recovery file;
2. load the newest valid checkpoint;
3. validate project identity/state;
4. promote the recovered state back to the canonical project;
5. reopen the project.

If no valid checkpoint exists, recovery fails explicitly without claiming success.

## Malformed preferences

Malformed preference files fall back to normalized safe defaults and are copied to a recovery backup before replacement/continued use.

## External Asset Library sources

Original external asset folders remain read-only. If a registered source is unavailable, PlayWorld Studio reports the problem; it does not fabricate or silently move source content.

## Failed migration or damaged installation

Migration state/backups remain in the per-user release area. Application package integrity and bundled exporter/template presence can be checked from Support & Recovery diagnostics. Repair/reinstall replaces application files while leaving per-user authored state separate.

<!-- PHASE19_CORRECTION_STATUS_START -->
## Phase 19 data-safety extension

Update, repair, reinstall, rollback, and uninstall operate on application binaries and preserve projects, preferences, Asset Library state, checkpoints, recovery data, and support data. Sequential migrations create backups and journals. Unsupported future schemas are refused. See `MIGRATION_ROLLBACK_RECOVERY.md`.
<!-- PHASE19_CORRECTION_STATUS_END -->
