# PlayWorld Studio

PlayWorld Studio is a Godot 4.7.x runtime game-creation application for building worlds, placing and converting assets into gameplay-ready prefabs, sculpting terrain, visually scripting interactions, testing instantly, exporting standalone Godot games, and running bounded direct-connect multiplayer Play sessions.

The user-facing direction is **smart defaults first, advanced controls on demand**. The canonical UI reference is `assets/reference/CANONICAL_UI_REFERENCE.png`; unexplained visual drift is treated as a defect.

## Repository authority

- Repository default and authoritative integrated branch: `master`.
- Current `master`: `9ed7abd28144f9757244f33aa33176e7074aca86`.
- That commit is the verified signed merge of **PR #23 — Phase 18 — Stable Release and Windows Productization**.
- PR #23 was merged prematurely before the required manual visual closeout was valid. Preserve repository history and repair forward from current `master`.
- Phases **0 through 17 are complete and accepted**.
- Phase 18 implementation is integrated, but final Phase 18 acceptance remains open.
- Corrective branch: `fix/phase18-post-merge-closeout`.
- Historical `main` is obsolete starter code and must not be used for development.
- No Phase 19 work is authorized.

## Phase 18 correction

The original Phase 18 artifact contained an invalid `09-about-version-1280x720.png`: it showed Home rather than the required About/version surface. The old automation proved that a PNG existed, but did not prove that the real About action rendered the expected interface.

The corrective branch:

- promotes the Home overlay to the topmost Home surface;
- uses a correctly typed About item collection;
- renders a visible PlayWorld Studio `0.1.0` identity card;
- activates the real About button during packaged QA;
- requires exact title, version, channel, platform, Godot version, source identity, overlay coverage, and label renderability before capture;
- retains all existing release, lifecycle, controller, accessibility, export, upgrade, uninstall, and support checks.

Phase 18 is finally accepted only after the exact corrective head is green, new release artifacts and checksums are verified, all eleven screenshots are manually inspected, and the corrective PR remains unmerged until explicit user authorization.

## PlayWorld Studio 0.1.0 target

- `PlayWorld-Studio-0.1.0-Windows-x64.zip`
- `PlayWorld-Studio-0.1.0-Windows-x64-Setup.exe`
- Windows x86_64
- Godot 4.7.1 exporter and Windows export templates
- deterministic portable ZIP and SHA-256 integrity data
- normal Windows install/uninstall path
- per-user projects, preferences, Asset Library state, recovery data, and support data outside the application directory
- real `0.1.0-rc.1 → 0.1.0` migration verification using the exact Phase 17 RC artifact
- packaged creator → standalone Windows game export and launch
- packaged controller/accessibility and visual acceptance

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
