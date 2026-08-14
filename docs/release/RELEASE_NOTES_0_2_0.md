# PlayWorld Studio 0.2.0 Release Notes

> Candidate notes. PlayWorld Studio 0.2.0 is not published or accepted until the Phase 19 completion gate passes and publication is explicitly authorized.

## Maintenance and update foundation

- Optional nonblocking update checks with Stable, Beta, and internal Development channels.
- Signed release metadata with channel-aware trust, key activation/expiration/revocation, exact artifact size, and SHA-256 verification.
- Download progress, cancellation, staging outside live binaries, and external Windows update handoff.
- Portable and installed update paths with application-only backups.
- Repair, interrupted-update recovery, and rollback of application binaries without deleting user projects or preferences.

## Data safety and recovery

- Sequential migration registry and migration journal.
- Backups before supported project/preference format migration.
- Refusal to open unsupported future schemas.
- Abnormal-shutdown recovery screen, safe mode, and non-destructive preference reset.
- Bounded diagnostics and local privacy-scanned support bundles.

## Creator experience

- Settings Update Center for version, channel, release notes, progress, install, repair, rollback, safe mode, diagnostics, and support actions.
- Keyboard, mouse, keyboard-only, and controller navigation paths.
- Compact density, UI scaling, reduced-motion compatibility, and visible focus requirements.

## Compatibility

- Initial productized platform remains Windows x86_64.
- The accepted `0.1.0` portable and installer artifacts are the required upgrade sources.
- Projects, Asset Library configuration, preferences, checkpoints, recovery state, and support data remain outside application installation directories.

## Publication boundary

No tag or public release is created automatically by a pull request or merge. Production publication requires an explicitly authorized manual workflow, an exact approved source commit, a successful approved artifact run, protected signing material, draft upload, re-download, and independent hash/signature verification.
