# PlayWorld Studio 1.0 Readiness and Phased Implementation Plan

## Document purpose

This document defines the staged implementation and release program that takes PlayWorld Studio from the first stable Windows product and its update infrastructure to a credible `1.0.0` General Availability release.

It is a strategic roadmap, not blanket authorization to begin every listed phase. Execution remains controlled by the current approved handoff. Each new phase begins only after the previous milestone is complete, merged into protected `master`, and followed by an explicit user-approved handoff.

The plan deliberately prioritizes product completeness, real-world use, data safety, reliability, security, usability, and release confidence over adding an unlimited number of new systems.

## Repository and product baseline

- Repository: `https://github.com/DocDamage/polyfork-project`
- Authoritative branch: protected `master`
- Current Phase 19 branch baseline: `master@ddfe6081e620a101f3d7e55c576f166c6683d7ed`
- Completed and accepted product milestone: Phase 18
- Accepted stable product: PlayWorld Studio `0.1.0`
- Active planned milestone: Phase 19 / PlayWorld Studio `0.2.0`
- Initial 1.0 platform: Windows x86_64
- Engine line: Godot 4.7.x
- Canonical visual direction: dark, playful, Nintendo/Apple-inspired, smart defaults first, advanced controls on demand
- Core product posture: offline-first, local user data, no mandatory account, no mandatory cloud connection

Phase 18 proved a deterministic portable package, Windows installer lifecycle, user-data separation, project/preference preservation, creator-to-game export, controller/accessibility acceptance, recovery support, and final packaged visual QA.

Phase 19 is intended to establish the maintenance infrastructure needed for future releases: application updates, release channels, signed manifests, migrations, rollback, diagnostics, release publishing, and real `0.1.0 -> 0.2.0` upgrade testing.

## What `1.0.0` means

`1.0.0` is not a percentage-complete label. It is a product contract.

PlayWorld Studio reaches `1.0.0` only when a normal user can install it, create and manage projects, import and organize assets, author a playable experience, save and reopen safely, test in Instant Play, export a standalone Windows game, update the application, recover from failures, and obtain useful diagnostics without editing repository files, opening the Godot editor, or manually modifying project JSON.

A `1.0.0` declaration means the project is prepared to make the following commitments:

1. **Core workflow stability**  
   The create -> author -> play -> save -> reopen -> export workflow is complete, understandable, and supported.

2. **Project compatibility**  
   Existing supported projects are opened through explicit migrations, with backups and recoverable failure behavior.

3. **User-data safety**  
   Updates, rollback, repair, reinstall, and uninstall do not destroy worlds, Asset Library configuration, preferences, recovery data, or user-created content.

4. **Release integrity**  
   Portable packages, installers, update manifests, release artifacts, checksums, signatures, and publishing authorization are verified.

5. **Reliable packaged behavior**  
   The shipped application—not only source scripts—passes Windows lifecycle, controller, accessibility, security, privacy, export, migration, and visual QA.

6. **Known performance envelope**  
   Small, Medium, Large/streamed, large Asset Library, and representative authored-world workloads have documented budgets and predictable degradation.

7. **No critical hidden workarounds**  
   Required user workflows do not depend on undocumented source edits, developer-only tools, manual file surgery, or fake test fixtures.

8. **Supportability**  
   Diagnostics, recovery, logs, support bundles, user documentation, release notes, and troubleshooting procedures are sufficient to investigate real failures.

9. **Feature discipline**  
   The 1.0 scope is frozen early enough to stabilize it. Major new systems are deferred rather than repeatedly destabilizing the release.

10. **Explicit release confidence**  
    `1.0.0` is promoted only from an approved release candidate after complete evidence review and explicit user authorization.

## Product invariants through 1.0

Every phase must preserve these rules unless a later approved decision explicitly changes them:

- Runtime creation remains the primary user experience.
- Existing `PlaySession` remains the authoritative Build/Play boundary.
- Authored changes remain command/transaction owned and support Undo/Redo.
- Stable authored IDs remain authoritative across save, export, migration, update, and multiplayer.
- External Asset Library source folders remain read-only.
- Offline single-player remains first-class.
- Multiplayer remains opt-in and does not replace authored identity.
- Gameplay networking is not presented as collaborative editing.
- User projects and preferences remain outside application installation directories.
- Update checks never block startup or basic editing.
- No mandatory account or cloud dependency is introduced.
- The canonical UI reference remains the visual authority.
- Keyboard/mouse and controller paths remain supported.
- Gamepad acceptance continues to use semantic `ui_accept` and `ui_cancel`.
- No release gate is weakened merely to obtain a green workflow.
- No stub, placeholder, existence-only assertion, or synthetic screenshot may be represented as completed behavior.
- Security scanners must be corrected when they produce false positives; they must not be broadly disabled.
- Every destructive-format migration creates a recoverable backup first.
- Every milestone uses one substantive branch and one milestone PR rather than forcing a PR for each small task.
- The milestone PR remains unmerged until explicit user authorization.

## Versioning strategy

The planned public version mapping is:

| Phase | Product version | Primary purpose |
|---|---:|---|
| Phase 19 | `0.2.0` | Update, migration, rollback, recovery, release-channel, and publishing infrastructure |
| Phase 20 | `0.3.0` | End-to-end creator workflow completion and onboarding |
| Phase 21 | `0.4.0` | Authoring depth and cross-system coherence |
| Phase 22 | `0.5.0` | Real-project dogfooding and reference-game closure |
| Phase 23 | `0.6.0` | Reliability, performance, scale, and long-session hardening |
| Phase 24 | `0.7.0` | Distribution trust, code signing, supply-chain security, and release operations |
| Phase 25 | `0.8.0` | Feature freeze, UX consistency, accessibility, and documentation closure |
| Phase 26 | `0.9.0` | Public beta, compatibility freeze, and bug-burn program |
| Phase 27 | `1.0.0-rc.N` -> `1.0.0` | Release-candidate validation and General Availability |

A phase number is an implementation milestone. A product version is a release identity. They normally move together in this plan, but a version must not be published merely because a phase branch exists or a PR merges.

Patch releases such as `0.4.1` or `0.8.2` may be used for narrowly scoped fixes without inventing a new major phase. Beta and release-candidate tags may be used within each milestone when needed:

- `v0.4.0-beta.1`
- `v0.4.0`
- `v1.0.0-beta.1`
- `v1.0.0-rc.1`
- `v1.0.0`

Publishing always requires the explicit release authorization gate established by Phase 19.

## Branch, PR, and evidence policy

Each phase follows the same execution structure:

1. Verify current protected `master`.
2. Create one dedicated milestone branch from that exact commit.
3. Implement the complete phase on that branch.
4. Keep task IDs as internal checkpoints, not forced PR boundaries.
5. Run focused tests continuously.
6. Run the complete inherited regression set before closeout.
7. Open one milestone PR against `master`.
8. Keep the PR open and unmerged while final evidence is reviewed.
9. Record exact branch head, merge candidate, workflow runs, artifact IDs, hashes, screenshots, limitations, and manual findings.
10. Merge only after explicit user authorization.

Every milestone PR must contain:

- exact authoritative base SHA;
- exact final branch-head SHA;
- source and Windows workflow run IDs;
- artifact IDs and SHA-256 values;
- migration/upgrade sources and destinations;
- security/privacy scan results;
- controller/accessibility evidence;
- visual evidence list and manual review notes;
- known limitations;
- explicit scope exclusions;
- explicit merge boundary.

---

# Phase 19 — `0.2.0` — Update and Release Infrastructure

## Objective

Create the infrastructure needed to maintain PlayWorld Studio safely after installation.

Phase 19 remains the prerequisite for the rest of this roadmap. Later phases must use its release channels, signed manifests, updater, migrations, rollback, diagnostics, artifact naming, release publishing, and upgrade testing rather than creating parallel mechanisms.

## Required workstreams

- [ ] P19-T01 Implement nonblocking in-application update checks.
- [ ] P19-T02 Implement stable, beta, and optional internal development channels.
- [ ] P19-T03 Implement signed update-manifest validation and future-strengthening hooks.
- [ ] P19-T04 Implement verified download, staging, installation handoff, restart, and progress UX.
- [ ] P19-T05 Implement portable and installed update lifecycles.
- [ ] P19-T06 Implement repair, failed-update recovery, interrupted-update recovery, and binary rollback.
- [ ] P19-T07 Replace one-off migration logic with a sequential migration registry and journal.
- [ ] P19-T08 Implement abnormal-shutdown detection, recovery screen, safe mode, and non-destructive preference reset.
- [ ] P19-T09 Expand release-health diagnostics and bounded support bundles.
- [ ] P19-T10 Add production updater, recovery, diagnostics, and channel-switching UX.
- [ ] P19-T11 Preserve complete controller/focus/accessibility behavior across all new surfaces.
- [ ] P19-T12 Add explicit-authority GitHub Release publishing with local/uploaded hash verification.
- [ ] P19-T13 Add update-manifest, path, inventory, downgrade, channel, corruption, and staging security gates.
- [ ] P19-T14 Prove offline startup and editing remain fully functional.
- [ ] P19-T15 Complete real `0.1.0 -> 0.2.0` portable and installer upgrade QA.
- [ ] P19-T16 Complete final visual QA and evidence reconciliation.

## Phase 19 completion gate

Phase 19 completes only when all requirements in its approved scope pass on the exact PR head, including real portable and installed `0.1.0 -> 0.2.0` upgrades, rollback/recovery, stable/beta isolation, deterministic portable packaging, verified installer output, privacy/security scans, controller/accessibility paths, manual visual review, and recorded final evidence.

## Explicit boundary

Phase 19 must not absorb the Phase 20 creator-workflow overhaul. It supplies the maintenance foundation; it does not become an unlimited product redesign.

---

# Phase 20 — `0.3.0` — End-to-End Creator Workflow Completion

## Objective

Make the full beginner-to-export workflow coherent enough that a user who did not build PlayWorld Studio can create a small playable game entirely through the packaged application.

The milestone is about workflow closure, discoverability, and removing dead ends—not adding broad new gameplay architecture.

## User outcome

A new user can:

1. install or extract PlayWorld Studio;
2. understand where to begin;
3. create a project from a template;
4. add an Asset Library source;
5. place and configure assets;
6. enter Instant Play;
7. save, close, and reopen;
8. export a Windows game;
9. locate the exported result;
10. understand and recover from common failures.

## Workstreams

### P20-T01 — Workflow inventory and blocker map

- [ ] Audit every user-visible route from Home through export.
- [ ] Record unreachable, incomplete, duplicated, hidden, confusing, or developer-oriented actions.
- [ ] Distinguish missing functionality from poor presentation.
- [ ] Create scenario-based acceptance cases rather than file-existence checks.
- [ ] Establish a zero-unexplained-dead-end rule for the primary workflow.

### P20-T02 — Project lifecycle and My Worlds

- [ ] Complete project create, open, rename, duplicate, archive, and delete behavior.
- [ ] Require confirmation for destructive project actions.
- [ ] Preserve recoverable project metadata before destructive changes.
- [ ] Show project version/schema, last opened, template, world size, and health.
- [ ] Surface missing external Asset Library sources without corrupting the project.
- [ ] Handle missing, malformed, locked, read-only, and partially migrated projects explicitly.
- [ ] Ensure controller focus remains deterministic across project cards and dialogs.

### P20-T03 — Save, autosave, dirty state, and reopen clarity

- [ ] Make unsaved state visible and consistent.
- [ ] Define and document manual save, autosave, checkpoint, and recovery behavior.
- [ ] Prevent accidental loss when returning Home, switching projects, updating, or closing.
- [ ] Add actionable save failures for low disk space, permission failure, path loss, and malformed data.
- [ ] Verify repeated save/reopen cycles do not reorder or mutate authored data unexpectedly.
- [ ] Provide a clear recovery path after a prior abnormal shutdown.

### P20-T04 — Asset onboarding

- [ ] Add a clear first-source Asset Library onboarding path.
- [ ] Show scan progress, cancellation, completion, warnings, and failures.
- [ ] Explain that original external files remain untouched.
- [ ] Surface unsupported files and partial metadata without pretending they imported successfully.
- [ ] Provide repair/relink behavior when a source folder moves or becomes unavailable.
- [ ] Make asset placement and conversion actions discoverable from cards and search results.

### P20-T05 — Authoring tool discoverability

- [ ] Add contextual labels, hints, status, and tool descriptions where controls are currently opaque.
- [ ] Keep minimal hidden menus while exposing advanced controls on demand.
- [ ] Make current selection, active tool, snapping mode, and placement state unambiguous.
- [ ] Prevent mode changes while transient operations would be lost.
- [ ] Add consistent cancel/back behavior for mouse, keyboard, and controller.
- [ ] Remove developer terminology from normal creator-facing messages.

### P20-T06 — Guided first project

- [ ] Add an optional first-run guided project using a real built-in template.
- [ ] Teach create, camera, selection, placement, transform, component configuration, Play, save, and export.
- [ ] Allow the tutorial to be skipped, resumed, or restarted.
- [ ] Store tutorial state as user preference, not authored project data.
- [ ] Support controller-only completion.
- [ ] Ensure reduced-motion and compact layouts remain usable.

### P20-T07 — Build/Play continuity

- [ ] Make Build -> Play -> Build transitions visually and behaviorally clear.
- [ ] Preserve authoritative Build state after disposable Play.
- [ ] Surface Play-start blockers before entering Play.
- [ ] Explain runtime-only state versus authored state.
- [ ] Verify repeated Play cycles do not leak nodes, connections, runtime IDs, or temporary state.
- [ ] Preserve template-specific controllers and gameplay behaviors.

### P20-T08 — Export completion UX

- [ ] Present export prerequisites and blockers before build.
- [ ] Show exporter/template availability and remediation.
- [ ] Show output location, progress, success, warnings, and failure details.
- [ ] Add open-folder and launch-exported-game actions.
- [ ] Prevent stale files from being represented as a successful new export.
- [ ] Verify offline and multiplayer-enabled dependency closure.
- [ ] Preserve deterministic export reports and attribution/license output.

### P20-T09 — Error and empty states

- [ ] Replace generic or silent failures across the primary workflow.
- [ ] Add clear empty states for no projects, no assets, no templates, no recent project, and no export.
- [ ] Ensure every blocking error states what happened, what was preserved, and what the user can do next.
- [ ] Prevent raw stack traces or source paths from becoming the main user message.
- [ ] Retain bounded diagnostic detail for support.

### P20-T10 — Controller and accessibility closure

- [ ] Exercise every primary workflow using a physical or simulated controller path.
- [ ] Verify visible focus, focus restoration, tab order, `ui_accept`, and `ui_cancel`.
- [ ] Verify keyboard-only operation.
- [ ] Verify text scaling, compact density, and reduced motion.
- [ ] Add automated assertions that the focused control is visible and enabled.
- [ ] Prevent hidden overlays from retaining focus.

### P20-T11 — First-game acceptance fixture

- [ ] Build a complete small third-person adventure using only the packaged UI.
- [ ] Use external assets through the Asset Library.
- [ ] Add placed scenery and at least one gameplay-configured object.
- [ ] Add at least one Visual Scripting interaction.
- [ ] Enter Instant Play and complete a basic objective.
- [ ] Save, reopen, duplicate, and export the project.
- [ ] Launch and verify the exported game.
- [ ] Upgrade the application and reopen the same project.
- [ ] Record every workaround; unresolved developer-only workaround is a phase blocker.

### P20-T12 — Documentation and evidence

- [ ] Create a concise Quick Start.
- [ ] Document project lifecycle, Asset Library onboarding, save/recovery, Play, and export.
- [ ] Capture normal and compact screenshots for all primary routes.
- [ ] Manually inspect every screenshot for clipping, overlap, hidden actions, focus, and canonical visual consistency.
- [ ] Record the exact first-game acceptance evidence in the milestone PR.

## Phase 20 completion gate

Phase 20 completes only when the small reference adventure can be created, saved, reopened, played, exported, launched, updated, and recovered entirely through the packaged application with keyboard/mouse and controller paths.

There must be no required manual JSON edit, repository edit, Godot-editor step, hidden test-only hook, or undocumented developer workaround.

## Not in Phase 20

- New major gameplay frameworks
- Marketplace or store
- Production collaboration
- Matchmaking or relay services
- Linux, macOS, or mobile distribution
- Major renderer replacement
- Full Asset Library format expansion unrelated to the first-game workflow

---

# Phase 21 — `0.4.0` — Authoring Depth and Cross-System Coherence

## Objective

Turn the existing broad feature set into a coherent production authoring environment. The milestone strengthens the connections between assets, components, prefabs, terrain, procedural systems, gameplay, Visual Scripting, templates, and export.

## User outcome

A user can build a medium-sized, multi-system game without repeatedly encountering shallow editors, disconnected data, missing configuration surfaces, or operations that bypass Undo/Redo.

## Workstreams

### P21-T01 — Asset Library production depth

- [ ] Complete reliable metadata and preview behavior for prioritized supported formats.
- [ ] Strengthen GLB/GLTF and Godot scene inspection.
- [ ] Add production-ready texture, audio, animation, and OBJ indexing where supported.
- [ ] Define explicit FBX behavior: supported import path, external conversion requirement, or actionable unsupported state.
- [ ] Complete duplicate detection, tags, favorites, collections, custom categories, and filters.
- [ ] Add dependency and usage views showing which projects/prefabs reference an asset.
- [ ] Add deterministic thumbnail generation and fallback semantics.
- [ ] Preserve source/license/attribution metadata through prefab use and export.

### P21-T02 — Components and archetypes editor

- [ ] Ensure all supported gameplay components have real creator-facing configuration surfaces.
- [ ] Add validation, defaults, help text, and dependency warnings.
- [ ] Prevent impossible component combinations or explain required dependencies.
- [ ] Keep all authored mutations command-backed.
- [ ] Make archetype application, customization, and removal reversible.
- [ ] Show inherited versus locally overridden values.

### P21-T03 — Prefab system completion

- [ ] Complete prefab create, save, instantiate, update, duplicate, and delete workflows.
- [ ] Complete base/derived prefab inheritance.
- [ ] Support explicit overrides and reset-to-base behavior.
- [ ] Define behavior when a base prefab changes.
- [ ] Detect missing/cyclic/invalid prefab references.
- [ ] Preserve stable IDs and instance identity.
- [ ] Verify prefab behavior through save, migration, Play, export, and project duplication.

### P21-T04 — Sockets and attachments

- [ ] Add complete socket authoring, naming, orientation, validation, and visualization.
- [ ] Support attachments for seats, weapons, handles, lights, mounts, loot, wheels, and custom extension points.
- [ ] Preserve socket references through prefab inheritance and export.
- [ ] Add snapping and attachment workflows that remain controller-usable.
- [ ] Reject missing or incompatible sockets explicitly.

### P21-T05 — Visual Scripting production workflow

- [ ] Expand validation for missing nodes, invalid links, incompatible value types, unreachable branches, and missing references.
- [ ] Add debugging visibility for active nodes, events, variables, timers, and errors.
- [ ] Complete reusable functions/macros and versioned serialization.
- [ ] Preserve Preview-before-Execute boundaries where AI proposes graph changes.
- [ ] Keep multiplayer actions on the existing gameplay-event boundary.
- [ ] Add migration fixtures for older graph schemas.
- [ ] Ensure graph editing is fully Undo/Redo owned.

### P21-T06 — Terrain, foliage, splines, and environment coherence

- [ ] Ensure biome selection consistently initializes terrain, foliage, environment, and procedural defaults.
- [ ] Strengthen sculpt, paint, streaming-cell, and terrain-aware placement behavior.
- [ ] Complete nondestructive procedural preview and explicit bake behavior.
- [ ] Ensure foliage remains an instanced system rather than object spam.
- [ ] Complete spline workflows for roads and reusable path-based systems.
- [ ] Validate water-provider behavior and project-owned/imported sources.
- [ ] Preserve authored data through world-size profiles, save, Play, export, and migration.

### P21-T07 — Gameplay framework authoring depth

- [ ] Complete creator-facing configuration for supported inventory, health, interaction, narrative, vehicle, objective, score, and template capabilities.
- [ ] Ensure runtime systems use stable authored references.
- [ ] Add validation for missing gameplay dependencies.
- [ ] Preserve host-authoritative rules for multiplayer-enabled projects.
- [ ] Avoid adding template-specific editor forks.

### P21-T08 — Reusable world chunks

- [ ] Complete save, preview, place, update, duplicate, and remove behavior for reusable authored chunks.
- [ ] Define stable identity and reference behavior.
- [ ] Preserve terrain, entities, components, prefabs, Visual Scripting, and environment dependencies.
- [ ] Detect missing assets or incompatible schema versions before placement.
- [ ] Keep source chunks nondestructive until explicitly updated.

### P21-T09 — Project organization and search

- [ ] Add project-wide search for entities, prefabs, components, graphs, assets, and identifiers.
- [ ] Add filters and collections suitable for medium projects.
- [ ] Add reference inspection and “used by” information.
- [ ] Make missing references repairable rather than silently dropped.
- [ ] Support controller navigation and compact layout.

### P21-T10 — Universal Undo/Redo audit

- [ ] Enumerate every authored mutation across all systems.
- [ ] Prove every supported mutation is command/transaction owned or explicitly non-authored.
- [ ] Add cross-system transaction tests.
- [ ] Verify failed commands roll back atomically.
- [ ] Verify save/reopen and migrations do not corrupt command-relevant state.
- [ ] Prevent Play-only state from entering authored history.

### P21-T11 — Template parity

- [ ] Audit Blank Sandbox, Third-Person Adventure, FPS, Survival, RPG, Driving, and Walking Simulator.
- [ ] Ensure each template exposes its intended capabilities through the same editor architecture.
- [ ] Remove template-only hidden setup.
- [ ] Verify Small, Medium, and Large-appropriate behavior.
- [ ] Verify offline export for every template.
- [ ] Verify multiplayer export only where capability is explicitly enabled.

### P21-T12 — Medium reference game

- [ ] Build a medium survival/RPG hybrid entirely through the packaged UI.
- [ ] Use prefabs, components, sockets, inventory, health, environment, terrain, foliage, Visual Scripting, and reusable chunks.
- [ ] Save and reopen across multiple sessions.
- [ ] Upgrade from `0.3.0` to `0.4.0`.
- [ ] Export and launch the standalone game.
- [ ] Record all performance and usability failures.
- [ ] Treat every required source-level workaround as a blocker.

## Phase 21 completion gate

Phase 21 completes only when the medium reference game proves real cross-system authoring depth, universal Undo/Redo ownership, correct save/migration/export behavior, and no required developer-only configuration.

## Not in Phase 21

- Unlimited new component categories
- Full collaborative editing
- Production hosted multiplayer services
- Marketplace/plugin ecosystem
- Additional operating systems
- Large-scale performance tuning that belongs to Phase 23

---

# Phase 22 — `0.5.0` — Real-Project Dogfooding and Reference-Game Closure

## Objective

Stop evaluating PlayWorld Studio primarily through isolated feature tests. Build representative games entirely inside the packaged product and use every obstacle as evidence about the real distance to 1.0.

This phase is intentionally allowed to fix defects across existing systems. It is not an excuse to add unrelated architecture.

## Dogfooding rule

The reference projects may use only:

- the packaged PlayWorld Studio application;
- supported external Asset Library folders;
- built-in creator UI and documented workflows;
- exported standalone builds.

The reference projects may not rely on:

- manual project JSON editing;
- direct Godot-editor scene editing;
- repository-only scripts;
- test-only command-line hooks;
- unshipped conversion tools;
- hidden developer menus;
- hand-patching exported packages.

When a blocker is discovered, fix PlayWorld Studio, rerun the affected workflow, and keep the reference project on the supported path.

## Required reference projects

### Reference A — Small third-person adventure

Must demonstrate:

- project creation and guided onboarding;
- external assets;
- placement and transforms;
- gameplay object conversion;
- one or more interactions;
- Visual Scripting;
- save/reopen;
- export and launch.

### Reference B — Medium survival/RPG experience

Must demonstrate:

- terrain and biome;
- foliage and environment;
- inventory/health/objectives;
- prefabs and inheritance;
- reusable chunks;
- multiple gameplay interactions;
- persistence and migration;
- export.

### Reference C — Driving/environment experience

Must demonstrate:

- vehicle archetype and sockets;
- road/spline workflow;
- environment and time/weather;
- controller gameplay;
- camera behavior;
- standalone export.

### Reference D — Large streamed exploration world

Must demonstrate:

- Large world creation;
- streamed cells/chunks;
- terrain-aware placement;
- procedural and foliage systems;
- long-distance traversal;
- save/reopen;
- performance profiling;
- standalone export.

### Reference E — Direct-connect multiplayer arena

Must demonstrate:

- explicit multiplayer capability;
- Offline, Host, and Client paths;
- local versus remote input ownership;
- host-authoritative gameplay state;
- score/objective state;
- disconnect/reconnect cleanup;
- exported concurrent host/client builds;
- offline use remaining functional.

## Workstreams

### P22-T01 — Reference-project repository and provenance

- [ ] Define where source projects, test assets, exported builds, screenshots, and evidence live.
- [ ] Preserve asset licenses and source metadata.
- [ ] Keep large generated artifacts out of source unless intentionally retained.
- [ ] Record exact application version and schema used for each project state.

### P22-T02 — Blocker and workaround ledger

- [ ] Record every stopped workflow, hidden dependency, manual workaround, data-loss risk, and confusing interaction.
- [ ] Classify blockers by severity and owning subsystem.
- [ ] Link each resolved blocker to tests and reference-project evidence.
- [ ] Do not close a blocker based only on a unit test if the real project path still fails.

### P22-T03 — Repeated authoring sessions

- [ ] Perform multi-session creation rather than single-run fixtures.
- [ ] Exercise save, close, reopen, update, repair, rollback, and recovery.
- [ ] Verify project history and checkpoints remain useful.
- [ ] Verify external Asset Library sources can be disconnected and repaired.

### P22-T04 — Exported-game parity

- [ ] Compare in-Studio Play behavior against exported behavior.
- [ ] Verify controls, components, graphs, environment, assets, and multiplayer dependencies.
- [ ] Detect editor-only leakage.
- [ ] Detect missing runtime source closure.
- [ ] Prevent “works in Play but not exported” from becoming accepted behavior.

### P22-T05 — Usability observation

- [ ] Run structured creator sessions without source-code context.
- [ ] Record hesitation, navigation failure, terminology confusion, and repeated mistakes.
- [ ] Prioritize high-frequency workflow friction over cosmetic novelty.
- [ ] Validate controller-only sessions separately.

### P22-T06 — Project migration matrix

- [ ] Preserve project copies from `0.2.0`, `0.3.0`, and `0.4.0`.
- [ ] Upgrade them through `0.5.0`.
- [ ] Verify backups, migration journal, project content, preferences, and export.
- [ ] Test migration failure and restoration using real reference projects.

### P22-T07 — Documentation from real use

- [ ] Convert repeated user questions into documentation.
- [ ] Create worked examples from reference projects.
- [ ] Document known limits honestly.
- [ ] Ensure screenshots and instructions match the packaged application.

### P22-T08 — Defect-burn acceptance

- [ ] Resolve all Priority 0 data-loss/security blockers.
- [ ] Resolve all Priority 1 core-workflow blockers.
- [ ] Resolve or explicitly defer Priority 2 issues with documented impact.
- [ ] Prohibit open undocumented workarounds in required scenarios.

## Phase 22 completion gate

Phase 22 completes only when all five reference projects can be authored, reopened, upgraded, played, exported, launched, and supported through documented packaged workflows.

The milestone PR must contain the blocker ledger, exact reference-project versions, exports, screenshots, upgrade evidence, controller findings, and remaining accepted limitations.

## Not in Phase 22

- New major product categories unrelated to reference-project blockers
- Production matchmaking/relay
- Collaborative editor mutation
- New platform ports
- Marketplace/store
- Feature work justified only by novelty rather than reference-project need

---

# Phase 23 — `0.6.0` — Reliability, Performance, Scale, and Long-Session Hardening

## Objective

Establish a measured operating envelope and make failure behavior predictable under large data, long sessions, interruption, corruption, resource pressure, and repeated operations.

## Workstreams

### P23-T01 — Benchmark architecture

- [ ] Create deterministic Small, Medium, Large, and Stress project fixtures.
- [ ] Create Asset Library fixtures at representative catalog sizes.
- [ ] Measure startup, project open, save, autosave, search, scan, Play transition, export, and shutdown.
- [ ] Record CPU, memory, render, streaming, and disk metrics where available.
- [ ] Distinguish CI regression proxies from real RTX 3060-class hardware claims.
- [ ] Store machine-readable benchmark reports.

### P23-T02 — Performance budgets

- [ ] Define supported budgets from measured evidence rather than guesses.
- [ ] Preserve the Balanced 60 FPS at 1080p reference target for representative medium-world workloads.
- [ ] Define Low/Balanced/High degradation policy.
- [ ] Define startup, save, project-open, Asset Library, Play-transition, and export thresholds.
- [ ] Establish warning and hard-failure thresholds.
- [ ] Lock the budgets before Phase 25 feature freeze.

### P23-T03 — Large Asset Library behavior

- [ ] Exercise catalogs containing thousands to tens of thousands of files.
- [ ] Add incremental scan and no-op scan behavior.
- [ ] Avoid rescanning unchanged sources unnecessarily.
- [ ] Support cancellation and restart.
- [ ] Keep search/filter/favorite/collection behavior responsive.
- [ ] Detect moved, deleted, duplicate, malformed, and inaccessible assets.
- [ ] Bound thumbnail and metadata memory use.

### P23-T04 — Large world and streaming reliability

- [ ] Exercise representative Large world traversal and editing.
- [ ] Measure streaming-cell load/unload behavior.
- [ ] Detect leaked entities, nodes, resources, and signals.
- [ ] Validate authoring across cell boundaries.
- [ ] Verify save/reopen and export.
- [ ] Decide from evidence whether floating-origin implementation is required before 1.0.
- [ ] Implement floating origin only if benchmark and precision evidence justify it.

### P23-T05 — Long-session and repeated-operation soak

- [ ] Run repeated Build/Play cycles.
- [ ] Run repeated project open/close and project switching.
- [ ] Run repeated save/checkpoint/recovery cycles.
- [ ] Run repeated Asset Library scans.
- [ ] Run repeated export and update checks.
- [ ] Monitor memory and node/resource counts.
- [ ] Fail on unbounded growth, stale state, or cumulative corruption.

### P23-T06 — Crash resistance and atomic persistence

- [ ] Audit all persisted authored files for atomic replacement.
- [ ] Add interruption fixtures for save, migration, update, and export metadata writes.
- [ ] Verify original data remains recoverable.
- [ ] Validate migration journal restart behavior.
- [ ] Validate abnormal-shutdown detection without false-positive recovery loops.
- [ ] Add fuzzed malformed-input tests for persisted schemas.

### P23-T07 — Resource-pressure failure behavior

- [ ] Test low disk space.
- [ ] Test unwritable project and user-data locations.
- [ ] Test locked files.
- [ ] Test missing external drives.
- [ ] Test partial download and interrupted staging.
- [ ] Test insufficient memory proxies where practical.
- [ ] Ensure errors remain actionable and do not destroy prior valid state.

### P23-T08 — Background work and cancellation

- [ ] Ensure scans, thumbnails, export preparation, update downloads, and diagnostics do not block basic editing unnecessarily.
- [ ] Define safe cancellation points.
- [ ] Prevent cancellation from leaving authoritative state half-written.
- [ ] Surface progress honestly.
- [ ] Prevent duplicate concurrent jobs from corrupting shared output.

### P23-T09 — Export scale and determinism

- [ ] Export Small, Medium, Large, and multiplayer reference projects.
- [ ] Verify dependency closure and editor-only stripping.
- [ ] Verify repeat export replaces stale output.
- [ ] Measure output size and build duration.
- [ ] Preserve deterministic reports and portable package determinism.
- [ ] Launch every representative exported game.

### P23-T10 — Reliability diagnostics

- [ ] Add bounded local performance and failure data to diagnostics.
- [ ] Exclude project content, credentials, and unrelated private files.
- [ ] Provide last save, migration, update, recovery, and export outcomes.
- [ ] Preserve explicit user control over bundle generation.
- [ ] Never transmit diagnostics silently.

## Phase 23 completion gate

Phase 23 completes only when performance budgets are measured and documented, all reference projects remain within accepted behavior, long-session tests show no unbounded leak or cumulative corruption, failure injection preserves recoverable user data, and representative exports launch successfully.

## Not in Phase 23

- Cosmetic redesign unrelated to measured usability defects
- New gameplay breadth
- Unproven optimization that weakens determinism or correctness
- Floating origin without evidence that it is required

---

# Phase 24 — `0.7.0` — Distribution Trust, Security, and Release Operations

## Objective

Turn the release pipeline from technically functional into a trustworthy production distribution system with signed binaries, hardened update trust, supply-chain evidence, controlled secrets, and rehearsed incident recovery.

## External prerequisite

Production Windows code signing normally requires a trusted code-signing certificate or approved signing service. Obtaining and securing that credential may require an explicit user-side purchase or account action. The private certificate/key must never be committed to the repository.

If this prerequisite is not satisfied, the product must not claim that its 1.0 Windows binaries are Authenticode-signed.

## Workstreams

### P24-T01 — Windows Authenticode signing

- [ ] Select an approved certificate or managed signing service.
- [ ] Sign the portable application executable and installer.
- [ ] Verify signatures after signing and after artifact upload/download.
- [ ] Timestamp signatures using a trusted timestamp service.
- [ ] Fail publishing when required signatures are missing or invalid.
- [ ] Document certificate renewal and revocation procedures.

### P24-T02 — Update-signing key management

- [ ] Separate update-manifest signing from ordinary repository access.
- [ ] Define key storage, access, rotation, revocation, and emergency replacement.
- [ ] Support multiple trusted public-key IDs during rotation.
- [ ] Reject unknown, expired, revoked, malformed, or mismatched signatures.
- [ ] Preserve an offline/manual update path for trust-service outages.
- [ ] Test a full key-rotation fixture.

### P24-T03 — Supply-chain controls

- [ ] Pin critical workflow actions and tool versions.
- [ ] Verify downloaded Godot binaries, export templates, installer tools, and dependencies.
- [ ] Generate an SBOM or equivalent machine-readable dependency inventory.
- [ ] Generate build provenance for release artifacts.
- [ ] Retain source commit, tool versions, hashes, and build identity.
- [ ] Detect unexpected files in all release packages.

### P24-T04 — Threat model

- [ ] Document update, installer, package, manifest, release-account, external-asset, diagnostic, and migration threats.
- [ ] Define trust boundaries and attacker capabilities.
- [ ] Map mitigations to automated tests.
- [ ] Record accepted risks explicitly.
- [ ] Review downgrade, channel-confusion, path traversal, archive extraction, symlink/reparse-point, and staging-race risks.

### P24-T05 — Secure staging and replacement

- [ ] Revalidate manifests and artifacts immediately before installation.
- [ ] Use bounded staging directories outside live binaries.
- [ ] Reject reparse-point, symlink, junction, and path-escape behavior where applicable.
- [ ] Restrict accepted file inventory.
- [ ] Preserve rollback payload integrity.
- [ ] Prevent unverified files from being promoted into the application directory.

### P24-T06 — Installer privilege and lifecycle review

- [ ] Review user-level versus machine-level installation expectations.
- [ ] Avoid unnecessary elevation.
- [ ] Verify alternate-location, repair, reinstall, upgrade, rollback, and uninstall.
- [ ] Verify application files are removed while user-created data remains.
- [ ] Verify signed installer metadata and Windows registration.
- [ ] Document silent-install behavior used by CI.

### P24-T07 — Privacy and diagnostics review

- [ ] Re-audit support bundle fields.
- [ ] Add secret-pattern regression tests.
- [ ] Reject project content unless explicitly selected by the user.
- [ ] Avoid usernames, unrelated absolute paths, environment secrets, and provider credentials where not required.
- [ ] Keep diagnostics generation local and user initiated.
- [ ] Document exactly what a support bundle contains.

### P24-T08 — Release authorization and promotion

- [ ] Require explicit authorization for beta and stable publication.
- [ ] Prevent PR merge from automatically publishing.
- [ ] Define beta-to-stable promotion criteria.
- [ ] Verify stable users never receive beta artifacts without opt-in.
- [ ] Verify release uploads by downloading and hashing every asset.
- [ ] Retain a draft/review step before final public publication.

### P24-T09 — Incident and rollback rehearsal

- [ ] Rehearse a corrupt release withdrawal.
- [ ] Rehearse update-key revocation.
- [ ] Rehearse code-signing certificate revocation or expiration.
- [ ] Rehearse channel rollback and release-note correction.
- [ ] Verify affected users can recover through manual and in-app paths.
- [ ] Document decision authority and evidence required during an incident.

### P24-T10 — Independent release audit

- [ ] Build from a clean environment.
- [ ] Verify the source commit and artifact inventory independently.
- [ ] Verify deterministic portable output.
- [ ] Verify signed binary and installer metadata.
- [ ] Verify manifests, checksums, signatures, SBOM/provenance, and release notes.
- [ ] Run scanners against downloaded final assets, not only local output.

## Phase 24 completion gate

Phase 24 completes only when the complete Windows release and update trust chain is verified from approved source to downloaded signed artifacts, key rotation and incident recovery are rehearsed, privacy/security scans pass, and publishing remains explicitly authorized.

## Not in Phase 24

- Account system
- Cloud-required project storage
- DRM
- Anti-cheat
- Marketplace payments
- Hosted multiplayer services
- Security claims not backed by a documented threat model and evidence

---

# Phase 25 — `0.8.0` — Feature Freeze, UX Consistency, Accessibility, and Documentation Closure

## Objective

Freeze major product architecture and make the existing product coherent, understandable, accessible, visually consistent, and documented.

After the feature-freeze point, new major systems require an explicit decision that they are necessary 1.0 blockers. “Nice to have” work moves to post-1.0 planning.

## Workstreams

### P25-T01 — Feature-freeze declaration

- [ ] Define the exact 1.0 feature inventory.
- [ ] Mark every feature as complete, blocker, limited, experimental, or post-1.0.
- [ ] Disable or clearly label incomplete experimental surfaces.
- [ ] Prevent undocumented scope growth.
- [ ] Require explicit approval for new major work.

### P25-T02 — Navigation and information architecture

- [ ] Audit Home, My Worlds, New World, Asset Library, Build, Play, Visual Scripting, Export, Settings, Updates, About, Diagnostics, Support, and Recovery.
- [ ] Remove duplicate routes and inconsistent back behavior.
- [ ] Ensure users always know current project, mode, tool, and save state.
- [ ] Preserve minimal hidden menus while keeping advanced controls discoverable.
- [ ] Verify compact and normal layouts.

### P25-T03 — Canonical visual-system audit

- [ ] Compare every major screen against the canonical reference and UI specification.
- [ ] Standardize spacing, hierarchy, cards, drawers, overlays, focus, status, progress, and error presentation.
- [ ] Preserve context-sensitive colors without creating inconsistent semantics.
- [ ] Remove generic developer dialogs from production workflows.
- [ ] Capture and manually inspect a complete visual inventory.

### P25-T04 — Copy and terminology

- [ ] Standardize names for worlds, projects, assets, prefabs, components, archetypes, chunks, Build, Play, export, update, recovery, and diagnostics.
- [ ] Replace raw implementation terms with creator-facing language.
- [ ] Make destructive confirmations precise.
- [ ] Ensure success messages do not overstate what was verified.
- [ ] Externalize user-visible strings for localization readiness.

### P25-T05 — Accessibility closure

- [ ] Complete keyboard-only navigation.
- [ ] Complete controller-only navigation.
- [ ] Verify focus visibility and restoration.
- [ ] Verify text scaling and compact density.
- [ ] Verify reduced motion.
- [ ] Review contrast and minimum target sizes.
- [ ] Document supported assistive-technology behavior honestly.
- [ ] Add accessibility regression assertions to every major screen.

### P25-T06 — Onboarding and learning path

- [ ] Finalize first-run onboarding.
- [ ] Finalize guided first project.
- [ ] Add contextual help and links to relevant documentation.
- [ ] Provide starter paths for the major templates.
- [ ] Allow experienced users to disable guidance.
- [ ] Ensure help remains available offline where practical.

### P25-T07 — User documentation set

- [ ] Installation and portable use
- [ ] Updates and release channels
- [ ] Project creation and lifecycle
- [ ] Asset Library
- [ ] Placement and transform tools
- [ ] Components, archetypes, prefabs, and sockets
- [ ] Terrain, foliage, splines, and environment
- [ ] Visual Scripting
- [ ] Instant Play
- [ ] Multiplayer direct connect
- [ ] Export
- [ ] Backup, migration, recovery, and rollback
- [ ] Diagnostics and support bundles
- [ ] Troubleshooting
- [ ] Known limitations
- [ ] 1.0 compatibility policy

### P25-T08 — Performance budget lock

- [ ] Adopt the measured budgets from Phase 23 as release gates.
- [ ] Add clear warnings where projects exceed supported budgets.
- [ ] Verify Low/Balanced/High behavior.
- [ ] Prevent late feature work from silently regressing the budgets.
- [ ] Document reference hardware and workload limits.

### P25-T09 — Deprecation and compatibility messaging

- [ ] Mark deprecated schemas, settings, templates, nodes, and APIs.
- [ ] Provide migration paths and warnings.
- [ ] Prevent silent deletion of unsupported authored data.
- [ ] Define minimum supported upgrade versions.
- [ ] Ensure diagnostics show compatibility state.

### P25-T10 — Full product QA sweep

- [ ] Run every reference project.
- [ ] Run all source and packaged regressions.
- [ ] Run migration from every retained supported version.
- [ ] Run portable and installer lifecycles.
- [ ] Run update, rollback, recovery, offline, security, privacy, controller, and accessibility tests.
- [ ] Review every screenshot manually.
- [ ] Resolve all Priority 0 and Priority 1 issues.

## Phase 25 completion gate

Phase 25 completes only when the major feature inventory is frozen, every production surface is coherent and documented, all required workflows are accessible by keyboard/mouse and controller, performance budgets are locked, and no unresolved Priority 0 or Priority 1 defects remain.

## Not in Phase 25

- New major gameplay systems
- Major editor architecture replacement
- New platform ports
- Marketplace
- Collaboration
- Hosted multiplayer infrastructure
- Feature additions justified only by competitive comparison

---

# Phase 26 — `0.9.0` — Public Beta, Compatibility Freeze, and Bug Burn

## Objective

Treat the product as a 1.0 candidate and attempt to disprove its readiness through broader real-world use, upgrade testing, failure injection, and defect burn.

No major architecture should change in this phase unless a release-blocking defect proves the current architecture cannot meet the 1.0 contract.

## Workstreams

### P26-T01 — Compatibility freeze

- [ ] Freeze project, prefab, component, Visual Scripting, template, migration, update-manifest, and release-manifest contracts.
- [ ] Require explicit migration plans for any remaining format change.
- [ ] Preserve old fixtures for every supported direct-upgrade source.
- [ ] Prevent silent schema rewrites without journaled migration.

### P26-T02 — Public beta channel

- [ ] Publish `0.9.0` through the beta channel using explicit authorization.
- [ ] Keep stable users isolated.
- [ ] Present beta warnings and backup expectations.
- [ ] Verify update, rollback, and return-to-stable behavior according to policy.
- [ ] Never require an account to participate.

### P26-T03 — Upgrade matrix

- [ ] Test every retained supported stable version to `0.9.0`.
- [ ] Test beta-to-beta and beta-to-stable transitions.
- [ ] Test portable-to-portable.
- [ ] Test installed-to-installed.
- [ ] Test repair, interruption, corrupt update, invalid hash, invalid signature, and rollback.
- [ ] Verify all five reference projects and user preferences survive.

### P26-T04 — Defect intake and triage

- [ ] Define Priority 0, 1, 2, and 3 severity rules.
- [ ] Require reproduction data before closing failures as external.
- [ ] Link fixes to regression tests.
- [ ] Track affected versions and migration implications.
- [ ] Reject “cannot reproduce” as final disposition when diagnostics or evidence remain available.

### P26-T05 — Crash and recovery program

- [ ] Review abnormal-shutdown reports.
- [ ] Verify safe mode and preference reset.
- [ ] Verify project recovery and checkpoint quality.
- [ ] Verify failed migration restoration.
- [ ] Verify update rollback.
- [ ] Ensure diagnostics remain bounded and user controlled.

### P26-T06 — Reference-project beta validation

- [ ] Upgrade every reference project through the public beta path.
- [ ] Continue authoring after upgrade.
- [ ] Export and launch every project.
- [ ] Verify multiplayer host/client.
- [ ] Verify large-world performance.
- [ ] Verify no unsupported workaround has returned.

### P26-T07 — Release-candidate checklist rehearsal

- [ ] Run the complete 1.0 checklist using `0.9.0` artifacts.
- [ ] Produce draft 1.0 release notes.
- [ ] Produce draft 1.0 user documentation.
- [ ] Produce draft support and incident procedures.
- [ ] Record every missing evidence item.

### P26-T08 — Consecutive green-candidate rule

Before leaving Phase 26:

- [ ] At least three successive exact-head full release workflows must pass without weakening gates.
- [ ] At least two successive beta artifacts must complete upgrade/rollback/reference-project testing.
- [ ] No unresolved Priority 0 or Priority 1 issue may remain.
- [ ] Accepted Priority 2 issues must be documented with user impact and workaround.
- [ ] No active data-loss, security, update-trust, migration, or export-parity investigation may remain open.

## Phase 26 completion gate

Phase 26 completes only when `0.9.0` behaves as a credible 1.0 candidate under the full compatibility, reference-project, release, recovery, security, performance, accessibility, and distribution test set.

## Not in Phase 26

- Broad feature development
- Visual redesign
- Schema churn for convenience
- New services
- New operating systems
- Changes that cannot be justified as 1.0 blockers

---

# Phase 27 — `1.0.0-rc.N` to `1.0.0` — Release Candidate and General Availability

## Objective

Promote the frozen, proven product to General Availability without introducing material new behavior.

Phase 27 is a release-validation and evidence milestone. It is not a final opportunity to add features.

## Release-candidate sequence

1. Select an approved source commit from protected `master`.
2. Produce `v1.0.0-rc.1`.
3. Run complete source, Windows, update, migration, rollback, reference-project, export, security, privacy, accessibility, controller, performance, and visual QA.
4. Fix release blockers only.
5. Produce additional `rc.N` versions as needed.
6. Promote the exact approved release-candidate source to `v1.0.0`.
7. Rebuild and verify final artifacts through the explicit release authorization gate.
8. Publish only after manual evidence review and explicit user authorization.

## Workstreams

### P27-T01 — Final product identity

- [ ] Set application, About, diagnostics, manifest, installer, exporter, package, update, and release identity to `1.0.0-rc.N`.
- [ ] Verify channel identity.
- [ ] Verify source/build identity.
- [ ] Verify no stale `0.x` identity appears in shipped surfaces except historical compatibility fixtures.

### P27-T02 — Final migration and compatibility validation

- [ ] Test every supported direct-upgrade source.
- [ ] Test older versions through documented intermediate upgrades where required.
- [ ] Test all reference projects.
- [ ] Test migration interruption and restoration.
- [ ] Verify backups and journal entries.
- [ ] Verify downgrade protection and explicit rollback policy.

### P27-T03 — Final Windows lifecycle

- [ ] Fresh portable launch
- [ ] Fresh installed launch
- [ ] Portable update
- [ ] Installer update
- [ ] Repair
- [ ] Reinstall
- [ ] Alternate location
- [ ] Interrupted update
- [ ] Failed update
- [ ] Binary rollback
- [ ] Uninstall
- [ ] User-data preservation
- [ ] Reinstall and reopen
- [ ] Manual update

### P27-T04 — Final creator workflow

- [ ] Create a new project.
- [ ] Add assets.
- [ ] Author gameplay.
- [ ] Use terrain/environment as appropriate.
- [ ] Enter and leave Play repeatedly.
- [ ] Save and reopen.
- [ ] Duplicate the project.
- [ ] Export and launch.
- [ ] Generate diagnostics.
- [ ] Recover from an injected failure.

### P27-T05 — Final reference-project matrix

- [ ] Small third-person adventure
- [ ] Medium survival/RPG
- [ ] Driving/environment experience
- [ ] Large streamed exploration world
- [ ] Direct-connect multiplayer arena

Each project must open, continue authoring, save, Play, export, and launch. Multiplayer must complete real host/client verification. The large project must remain inside the locked performance policy.

### P27-T06 — Final security and trust

- [ ] Valid Authenticode signatures on required Windows artifacts
- [ ] Valid update-manifest signature
- [ ] Valid checksums
- [ ] Valid artifact inventory
- [ ] Valid SBOM/provenance
- [ ] Valid release-note references
- [ ] No path traversal or unexpected files
- [ ] No private credentials or project content in release/support material
- [ ] Verified downloaded release assets
- [ ] Rehearsed rollback/withdrawal path

### P27-T07 — Final controller and accessibility pass

- [ ] Keyboard/mouse
- [ ] Keyboard only
- [ ] Controller only
- [ ] Focus navigation
- [ ] `ui_accept`
- [ ] `ui_cancel`
- [ ] Text scaling
- [ ] Compact density
- [ ] Reduced motion
- [ ] Visible error/recovery focus
- [ ] Normal and compact layouts

### P27-T08 — Final visual QA

Capture and manually inspect the complete production surface inventory, including at minimum:

- Home
- My Worlds
- New World
- Asset Library
- Build workspace
- component/archetype/prefab editing
- terrain/environment/procedural tools
- Visual Scripting
- Instant Play
- multiplayer
- Export
- Settings
- Updates
- What’s New
- About/version
- Diagnostics
- Support & Recovery
- safe mode
- update download
- ready to install
- update failure
- rollback
- normal layout
- compact layout

Screenshot existence is not acceptance. Automation must prove the intended screen/action is active and renderable before capture. Manual review must record clipping, overlap, readability, focus, identity, and visual-consistency findings.

### P27-T09 — Final documentation

- [ ] 1.0 release notes
- [ ] installation guide
- [ ] update/channel guide
- [ ] complete user guide
- [ ] backup/recovery guide
- [ ] compatibility and migration policy
- [ ] troubleshooting guide
- [ ] diagnostics/support guide
- [ ] known limitations
- [ ] security and privacy statement
- [ ] third-party notices
- [ ] reference-project tutorials
- [ ] post-1.0 support policy

### P27-T10 — GA artifact set

The final release must contain and verify:

- `PlayWorld-Studio-1.0.0-Windows-x64.zip`
- `PlayWorld-Studio-1.0.0-Windows-x64-Setup.exe`
- checksum sidecars
- signed update manifest
- release manifest
- release notes
- third-party notices
- SBOM/provenance material
- exact source/build identity
- retained rollback/recovery information

### P27-T11 — Final evidence record

- [ ] Exact authoritative base
- [ ] Exact RC branch head
- [ ] Exact merge candidate
- [ ] Exact signed integrated commit
- [ ] Workflow run IDs
- [ ] Job results
- [ ] Artifact IDs
- [ ] Artifact SHA-256 values
- [ ] Signature verification
- [ ] Migration matrix
- [ ] Reference-project matrix
- [ ] Export matrix
- [ ] Controller/accessibility findings
- [ ] Security/privacy findings
- [ ] Manual screenshot review
- [ ] Known limitations
- [ ] Explicit publication authorization

## `1.0.0` completion gate

PlayWorld Studio `1.0.0` is complete only when:

- [ ] the exact final release source passes every required source and Windows job;
- [ ] no required status check is bypassed or weakened;
- [ ] every supported upgrade path succeeds or has a documented intermediate path;
- [ ] projects and preferences survive update, migration, rollback, repair, reinstall, and uninstall;
- [ ] every reference project opens, saves, plays, exports, and launches;
- [ ] exported-game behavior matches supported in-Studio Play behavior;
- [ ] stable/beta channel isolation is proven;
- [ ] offline startup, authoring, save, Play, and export remain functional;
- [ ] application and installer signatures are valid if signing is part of the approved 1.0 contract;
- [ ] update manifests, release manifests, hashes, signatures, and inventories verify;
- [ ] security and privacy scans pass;
- [ ] controller and accessibility paths pass;
- [ ] locked performance budgets pass;
- [ ] no Priority 0 or Priority 1 defect remains open;
- [ ] accepted Priority 2 limitations are documented;
- [ ] all final screenshots are manually reviewed;
- [ ] final documentation matches the shipped application;
- [ ] `PlayWorld-Studio-1.0.0-Windows-x64.zip` is verified;
- [ ] `PlayWorld-Studio-1.0.0-Windows-x64-Setup.exe` is verified;
- [ ] final evidence is recorded in the milestone PR and release;
- [ ] the milestone PR remains unmerged until explicit merge authorization;
- [ ] the GitHub Release remains unpublished until explicit release authorization.

---

# Cross-phase quality program

## Required automated test layers

Every phase must add focused tests and retain inherited coverage in these layers:

1. **Schema and contract tests**  
   Validate persisted formats, stable IDs, migration, validation, and ownership.

2. **Unit tests**  
   Validate bounded algorithms and pure behavior.

3. **Integration tests**  
   Validate real cross-system workflows, not only API existence.

4. **Runtime tests**  
   Launch the Godot application and exercise real scenes and services.

5. **Packaged Windows tests**  
   Launch the distributed executable from portable and installed layouts.

6. **Upgrade and migration tests**  
   Use retained real artifacts and real user-data fixtures.

7. **Export tests**  
   Build and launch standalone games.

8. **Multiplayer tests**  
   Launch concurrent real host/client processes and verify ownership and convergence.

9. **Controller/accessibility tests**  
   Verify physical/semantic inputs, focus, layouts, and preferences.

10. **Security/privacy tests**  
    Validate artifacts, manifests, staging, paths, hashes, signatures, diagnostics, and support bundles.

11. **Performance/scale tests**  
    Use deterministic fixtures and machine-readable reports.

12. **Visual tests**  
    Activate real screens, assert intended state, capture, and manually inspect.

## Manual evidence that automation cannot replace

Automation does not replace:

- judging whether the UI matches the canonical visual direction;
- noticing confusing workflow or terminology;
- identifying excessive friction in real project creation;
- inspecting screenshots for subtle clipping, collision, or hierarchy failure;
- evaluating whether an error message is actionable;
- confirming a reference project is genuinely authorable without hidden workarounds;
- deciding whether a remaining limitation is acceptable for 1.0.

## Defect severity

### Priority 0 — release stopping

Examples:

- data loss;
- credential/private-data exposure;
- update trust bypass;
- arbitrary path write or traversal;
- unrecoverable migration corruption;
- malicious or corrupted package accepted;
- installed/portable upgrade destroys projects;
- published artifact does not match approved source.

No Priority 0 issue may remain open at the end of any release milestone.

### Priority 1 — 1.0 blocker

Examples:

- required creator workflow cannot complete;
- save/reopen fails;
- exported game does not launch;
- controller cannot complete a required flow;
- rollback/recovery fails;
- stable users receive beta;
- reference project requires source editing;
- major UI route is unusable or inaccessible;
- repeated use causes unbounded leaks or corruption.

No Priority 1 issue may remain open at Phase 25, 26, or 27 completion.

### Priority 2 — significant but potentially deferrable

Examples:

- serious workflow friction with a documented workaround;
- unsupported edge-case asset;
- performance degradation outside the supported workload;
- noncritical visual inconsistency;
- optional template limitation.

A Priority 2 issue may remain only when impact, workaround, and post-1.0 disposition are documented and explicitly accepted.

### Priority 3 — polish/backlog

Examples:

- minor copy improvement;
- optional shortcut;
- low-impact cosmetic inconsistency;
- enhancement outside the 1.0 contract.

Priority 3 issues do not block 1.0 unless their combined effect undermines usability or visual acceptance.

---

# Compatibility and retention policy to establish before 1.0

## Direct upgrade window

By Phase 26, the project must define and test the direct upgrade window. Recommended policy:

- keep direct upgrade support for at least the current release and the two previous stable minor releases during pre-1.0;
- preserve retained artifacts and user-data fixtures for every supported source;
- require documented intermediate upgrades for older versions;
- never pretend an untested direct jump is supported.

## Project compatibility

- A newer application may migrate an older supported project only through registered sequential migrations.
- Migrations must be idempotent.
- Destructive-format migrations require automatic backups.
- Failed migration must leave the original data recoverable.
- Project schema and last migration must be visible in diagnostics.
- Downgrading a migrated project is unsupported unless an explicit reversible path exists.
- The application must warn before irreversible project-format changes.

## Release retention

Before 1.0:

- retain every stable release artifact needed by the supported upgrade window;
- retain every update manifest and release note used by those releases;
- retain all 1.0 beta and RC artifacts needed for investigation;
- do not silently replace published binaries under an existing tag.

After 1.0:

- retain `1.0.0` permanently;
- retain security-relevant withdrawn-release metadata;
- retain enough prior 1.x releases to support the documented upgrade window;
- publish corrected versions under new tags rather than mutating old artifacts.

## Release-channel promotion

- Development/nightly builds never promote automatically to beta or stable.
- Beta promotion requires complete beta gates and explicit authorization.
- Stable promotion requires complete stable gates, downloaded-artifact verification, and explicit authorization.
- A channel change is an explicit user preference.
- Stable users never receive beta builds by default.
- Returning from beta to stable must not silently downgrade project formats.

---

# 1.0 scope exclusions

PlayWorld Studio can legitimately reach 1.0 without the following:

- Linux application build
- macOS application build
- mobile application build
- browser application build
- marketplace/store
- paid asset commerce
- account system
- mandatory cloud login
- cloud-required project storage
- production collaborative editor mutation
- production matchmaking
- hosted relay/NAT traversal
- voice chat
- anti-cheat platform
- rollback netcode
- dedicated-server fleet infrastructure
- arbitrary third-party plugin marketplace
- guaranteed repair/conversion of every FBX or malformed asset
- every possible gameplay genre or component
- localization into multiple languages
- touch-first production UI

These may be valid `1.x` or `2.x` milestones. Pulling them into 1.0 without direct evidence that they are core blockers would delay stabilization and increase risk.

---

# Major risks and controls

## Risk: endless feature expansion

**Control:** Freeze the 1.0 feature inventory in Phase 25. Require explicit approval for additions. Move optional systems to post-1.0.

## Risk: tests pass while real users fail

**Control:** Maintain five packaged-app reference projects. Reject existence-only tests and synthetic screenshots. Require real user-path evidence.

## Risk: project corruption through migrations

**Control:** Sequential registry, migration journal, backups, failure restoration, retained real-version fixtures, and full upgrade matrix.

## Risk: updater compromises the application

**Control:** Signed manifests, strict schema validation, exact inventory, hash verification, safe staging, path/reparse-point rejection, pre-install revalidation, rollback, and explicit authorization.

## Risk: release-account or key compromise

**Control:** Separate signing secrets, minimum permissions, key IDs, rotation/revocation procedures, draft release review, and downloaded-artifact verification.

## Risk: large projects become unusable

**Control:** Phase 23 benchmark fixtures, locked budgets, predictable quality profiles, reference large world, and evidence-based floating-origin decision.

## Risk: controller support regresses as UI expands

**Control:** Controller acceptance in every phase, explicit focus graphs, semantic input assertions, visible-focus checks, and controller-only reference sessions.

## Risk: Play and exported game diverge

**Control:** Every reference project must pass in-Studio Play and exported launch. Export parity is a standing milestone gate.

## Risk: Windows distribution appears unsafe

**Control:** Authenticode signing, trusted timestamping, installer review, update-signature validation, checksums, provenance, and documented privacy/security behavior.

## Risk: CI becomes too slow or fragile

**Control:** Separate focused checks from full milestone release gates, cache immutable tooling safely, retry only infrastructure downloads, and never mark unexecuted product tests as passing.

## Risk: documentation becomes stale

**Control:** Update the smallest canonical documents with each behavior change. Treat screenshot/instruction mismatch as a defect during Phase 25–27.

---

# Post-1.0 direction

After `1.0.0`, the roadmap should shift from “prove the product can ship” to controlled `1.x` evolution.

Potential post-1.0 milestones include:

- broader import adapters and conversion assistance;
- additional templates and gameplay components;
- production collaboration protocol;
- matchmaking/relay/account services;
- marketplace/store;
- Linux and macOS application builds;
- deeper touch support;
- localization;
- extension/plugin ecosystem;
- advanced multiplayer infrastructure;
- additional performance and world-scale work.

Those decisions should be based on actual 1.0 usage, support data, reference-project outcomes, and user demand rather than being treated as retroactive 1.0 blockers.

---

# Final program success criteria

The 1.0 program succeeds when PlayWorld Studio is no longer merely a broad collection of implemented systems. It must behave as one maintainable product:

- installable;
- updateable;
- recoverable;
- secure;
- understandable;
- controller-usable;
- performant within documented limits;
- capable of producing real exported games;
- compatible with supported existing projects;
- supported by evidence and documentation;
- releasable without hidden developer intervention.

The decisive proof is not the number of phases completed. The decisive proof is that multiple representative games can be created, maintained, upgraded, recovered, and exported through the same packaged PlayWorld Studio experience that end users receive.
