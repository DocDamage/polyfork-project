# PlayWorld Studio / Polyfork Project

PlayWorld Studio is a Windows-first Godot 4.7.x creator application for building, playing, and exporting interactive 3D worlds through a runtime-first workflow.

## Current authoritative state

- Repository authority: protected `master`
- Historical `main`: obsolete starter code; do not develop from it
- Accepted milestones: Phases 0 through 18
- Accepted product: PlayWorld Studio `0.1.0` stable for Windows x86_64
- Phase 18 completion merge: PR #24, followed by documentation closeout PR #26
- Final Phase 18 workflow: `31699466148`
- Current development boundary: no active milestone is authorized by this documentation closeout

Phase 18 proved deterministic portable packaging, a real Windows installer lifecycle, user-data separation, project/preference preservation, a real `0.1.0-rc.1 -> 0.1.0` upgrade, creator-to-game Windows export, packaged controller/accessibility acceptance, recovery/support behavior, security scans, and manually inspected final screenshots.

The exact current repository state and next authorization boundary are recorded in `docs/handoffs/CURRENT_HANDOFF.md`.

## Product direction

PlayWorld Studio is designed around:

- runtime creation as the primary authoring experience;
- smart defaults with advanced controls available on demand;
- keyboard/mouse and controller support;
- local project storage and an external read-only Asset Library;
- fast Build/Play iteration;
- Visual Scripting, gameplay templates, procedural tools, Environment authoring, optional AI-assisted creation, and optional multiplayer foundations;
- Windows standalone-game export;
- a dark, playful Nintendo/Apple-inspired interface.

## Implemented milestone summary

- Phase 0 — Repository and contracts
- Phase 1 — Application shell and canonical UI
- Phase 2 — World project/save foundation
- Phase 3 — Runtime placement editor
- Phase 4 — Universal Asset Library
- Phase 5 — Terrain and streaming
- Phase 6 — Components, archetypes, prefabs, and sockets
- Phase 7 — Instant Play and templates
- Phase 8 — Visual Scripting
- Phase 9 — Foliage, procedural systems, and splines
- Phase 10 — Gameplay framework breadth
- Phase 11 — Environment
- Phase 12 — AI Creation
- Phase 13 — Export pipeline
- Phase 14 — Scale and polish
- Phase 15 — Multiplayer foundations and collaboration roadmap
- Phase 16 — Inherited product completeness and integration closure
- Phase 17 — Release candidate and distribution
- Phase 18 — Stable release and Windows productization

## Stable product artifacts proven by Phase 18

- `PlayWorld-Studio-0.1.0-Windows-x64.zip`
- `PlayWorld-Studio-0.1.0-Windows-x64-Setup.exe`
- release manifest and SHA-256 sidecars
- bundled Godot exporter/templates/runtime source closure needed by the packaged creator to export standalone Windows games
- installer repair/reinstall/uninstall lifecycle
- support bundle and recovery UX

Phase 18 intentionally does not claim production auto-update infrastructure, signed distribution, or non-Windows support.

## Repository layout

- `src/` — application, authoring, runtime, export, networking, scale, and release systems
- `tests/` — contract, regression, runtime, scale, visual, release, and export verification
- `.github/workflows/` — repository-owned CI and release evidence workflows
- `tools/release/` — deterministic creator packaging, validation, security scanning, and installer tooling
- `docs/architecture/` — system architecture and integration guidance
- `docs/implementation/` — milestone plans and backlog
- `docs/qa/` — quality gates, test matrix, and phase evidence
- `docs/release/` — install, upgrade, troubleshooting, requirements, release notes, and limitations
- `docs/handoffs/` — authoritative continuation state

## Development rules

- Start from current `master`, never obsolete `main`.
- Develop on a dedicated branch and merge through a pull request.
- Do not weaken contract, security, packaging, controller, accessibility, export, or visual gates to obtain a green workflow.
- Preserve user projects, preferences, Asset Library state, and recovery data outside installation directories.
- Keep the milestone pull request unmerged until explicit authorization.

## Current limitations

- Productized creator release is Windows x86_64 only.
- Portable ZIP determinism is proven; byte-for-byte installer reproducibility is not claimed.
- Installer code signing is not yet claimed.
- Production application auto-update is not implemented in the accepted `master` baseline.
- External Asset Library folders remain external and read-only.
- Recovery requires a valid checkpoint.
- Multiplayer remains bounded direct-connect gameplay rather than production matchmaking/relay or collaborative editor mutation.
- Cloud AI behavior depends on user-configured provider availability and explicit cloud consent.

See `docs/release/KNOWN_LIMITATIONS.md` and `docs/handoffs/CURRENT_HANDOFF.md` for the authoritative details.
