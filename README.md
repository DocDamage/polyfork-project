# PlayWorld Studio

PlayWorld Studio is a Godot 4.7.x runtime game-creation application for building worlds, placing and converting assets into gameplay-ready prefabs, sculpting terrain, visually scripting interactions, testing instantly, exporting standalone Godot games, and running bounded direct-connect multiplayer Play sessions.

The user-facing direction is **smart defaults first, advanced controls on demand**. The canonical UI reference is `assets/reference/CANONICAL_UI_REFERENCE.png`; unexplained visual drift is treated as a defect.

## Repository authority

- Repository default and authoritative integrated branch: `master`.
- Authoritative `master`: `49a5b55748244097d952ab9c095dd00ed0ec9f06`.
- That commit is the verified signed merge of **PR #24 — Phase 18 — Post-merge closeout correction**.
- Phases **0 through 18 are complete and accepted**.
- PR #23 integrated the Phase 18 implementation prematurely; PR #24 completed the corrective visual, QA, evidence, and documentation closeout without rewriting repository history.
- Historical `main` is obsolete starter code. Its archived branch is retained only as `archive/obsolete-main-phase14` and must not be used for development.
- `master` is protected by active repository rules. Changes should be made on a branch and integrated through a pull request.
- No Phase 19 work is authorized until a new handoff defines that milestone.

## PlayWorld Studio 0.1.0 stable release

Phase 18 establishes the first stable Windows productization boundary:

- portable package: `PlayWorld-Studio-0.1.0-Windows-x64.zip`;
- installer: `PlayWorld-Studio-0.1.0-Windows-x64-Setup.exe`;
- Windows x86_64;
- bundled Godot 4.7.1 exporter and Windows export templates;
- deterministic portable ZIP and SHA-256 integrity data;
- normal Windows install, repair, reinstall, and uninstall lifecycle;
- per-user projects, preferences, Asset Library state, recovery data, and support data outside the application directory;
- real `0.1.0-rc.1 → 0.1.0` migration verification using the exact Phase 17 RC artifact;
- checkpoint-based project recovery and malformed-preference recovery backups;
- bounded Support & Recovery diagnostics;
- packaged creator → standalone Windows game export and launch;
- packaged controller, accessibility, focus, and visual acceptance.

Final Phase 18 verification ran on the exact corrective source in workflow `31699466148`. Both `source-regressions` and `windows-stable-release` passed. The final artifact is `9180943528`; all eleven packaged screenshots were manually inspected, including a corrected About/version capture that visibly proves PlayWorld Studio `0.1.0`, stable, Windows x64, Godot 4.7.1, and source identity.

Detailed release evidence is recorded in `docs/qa/PHASE18_QA.md` and the merged PR #24 discussion.

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

## Historical secret boundary

Secret material previously committed to repository history must be treated as exposed and must never be restored, tested, reused, or distributed. External revocation remains required unless independently verified outside the repository.
