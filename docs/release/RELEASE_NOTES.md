# PlayWorld Studio 0.1.0-rc.1 Release Notes

## Release candidate objective

This is the first distribution-focused PlayWorld Studio milestone. It packages the creator application itself rather than changing the existing user-game export architecture.

## Added in Phase 17

- semantic product/version identity and About surface;
- production application icon and Windows executable metadata;
- dedicated Windows x64 creator export preset;
- deterministic `PlayWorld-Studio-0.1.0-rc.1-Windows-x64.zip` packaging;
- bundled Godot 4.7.1 exporter plus Windows release template for creator-to-game export;
- SHA-256 checksums and release manifest with source/build identity and included-file hashes;
- final-package development-material and credential-like-material scanning;
- packaged creator clean-first-run, authoring, save/reopen, Instant Play, shared Asset Library, creator-to-game export, exported-game launch, relocation/upgrade-style, read-only-style install, and visual-evidence gates;
- strict malformed-preference handling that returns safe defaults without noisy engine parser failures;
- release documentation and QA matrix updates.

Inherited product behavior from Phases 0–16 remains in place and is covered by the Phase 17 regression workflow.
