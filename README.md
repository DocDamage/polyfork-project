# PlayWorld Studio

PlayWorld Studio is a Godot 4.7.x runtime game-creation application for building worlds, placing and converting assets into gameplay-ready prefabs, sculpting terrain, visually scripting interactions, testing instantly, exporting standalone Godot games, and running bounded direct-connect multiplayer Play sessions.

The user-facing direction is **smart defaults first, advanced controls on demand**. The canonical UI reference is `assets/reference/CANONICAL_UI_REFERENCE.png`; unexplained visual drift is treated as a defect.

## Repository authority

- Repository default and authoritative integrated branch: `master`.
- Authoritative `master`: `91b8b9c39fddda4b80ad5c6101d563245ef3e2d0`.
- That commit is the verified signed merge of **PR #22 — Phase 17 — Release Candidate and Distribution**.
- Historical `main` is obsolete starter code and must not be used for development.
- Phases **0 through 17 are complete and merged**.
- Phase 18 development branch: `dev/phase18-stable-release`.
- Phase 18 completion boundary: PR #23, **Phase 18 — Stable Release and Windows Productization**, targeting `master`; it must remain unmerged until explicitly authorized.

## PlayWorld Studio 0.1.0

Phase 18 promotes the creator from `0.1.0-rc.1` to the first stable Windows productization target:

- portable package: `PlayWorld-Studio-0.1.0-Windows-x64.zip`;
- installer: `PlayWorld-Studio-0.1.0-Windows-x64-Setup.exe`;
- Windows x86_64;
- bundled Godot 4.7.1 exporter and Windows export templates;
- deterministic portable ZIP and SHA-256 integrity data;
- normal Windows install/uninstall path;
- per-user projects, preferences, Asset Library state, recovery data, and support data outside the application directory;
- real `0.1.0-rc.1 → 0.1.0` migration verification using the exact Phase 17 RC artifact;
- project/checkpoint recovery and malformed-preference recovery backups;
- bounded Support & Recovery diagnostics with credential/private-material scanning;
- packaged creator → standalone Windows game export and launch;
- packaged controller/accessibility and visual acceptance.

Final release evidence is recorded on PR #23 after the exact completion head passes `.github/workflows/phase18-stable-release.yml` and the resulting screenshots are manually reviewed.

## Core promise

1. Choose a world size before creation: Small, Medium, or Large/streamed.
2. Spawn directly into a runtime editor.
3. Browse a universal Asset Library without moving original source files.
4. Place and edit assets with transform, snapping, scatter, and painting tools.
5. Convert assets into reusable gameplay prefabs through components, archetypes, sockets, and node-based logic.
6. Toggle **Build | Play** instantly without changing projects or losing edits.
7. Save authored worlds, reusable chunks, prefabs, visual graphs, terrain, environment, and gameplay state.
8. Export standalone Windows games from the packaged creator.
9. Opt supported templates into Offline, Host, or Client Play while preserving offline-first behavior.
10. Keep transient gameplay replication separate from durable authored project identity and future collaboration protocols.

## Start here

- `docs/PROJECT_CHARTER.md`
- `docs/PRODUCT_REQUIREMENTS.md`
- `docs/DECISIONS.md`
- `docs/design/UI_UX_CANONICAL_SPEC.md`
- `docs/architecture/SYSTEM_ARCHITECTURE.md`
- `docs/implementation/MASTER_IMPLEMENTATION_PLAN.md`
- `docs/implementation/PHASE18_STABLE_RELEASE_PRODUCTIZATION_PLAN.md`
- `docs/qa/PHASE18_QA.md`
- `docs/release/INSTALL_WINDOWS.md`
- `docs/release/USER_DATA_AND_UPGRADE.md`
- `docs/release/TROUBLESHOOTING.md`
- `docs/handoffs/CURRENT_HANDOFF.md`

## Security note

Historical `.polyforkAPI` credential material in Git history must be treated as exposed. Never print, restore, test, copy, reuse, or package it. External revocation/rotation remains required unless independently confirmed outside this repository; repository evidence does not prove that action occurred.
