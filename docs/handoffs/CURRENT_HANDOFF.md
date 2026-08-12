# POLYFORK PROJECT — PHASE 7 COMPLETION HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## Authoritative branch
The real project lives on:

`master`

Authoritative `master` after the Phase 6 merge:

`14d87bb12a3423dc54fc186f47f491a393537420`

That commit is the verified GitHub merge commit for PR #11 — Phase 6 — Components, Archetypes, Prefabs.

The repository default branch `main` remains obsolete starter code.

**Never develop from `main`.**

## Current milestone status
Phases 0 through 6 are merged on authoritative `master`.

Phase 7 — Instant Play + Templates — is implementation-complete and verified on:

`dev/phase7-instant-play-templates-milestone`

All internal Phase 7 checkpoints P07-T01 through P07-T08 are complete.

Verified implementation head before this documentation-only closeout:

`cfa60cf0bab8637325dc76d8de74a46cabce45f0`

The Phase 7 completion PR must target `master` and must not be merged without explicit user authorization.

## Branch integrity
Before documentation closeout:
- authoritative `master`: `14d87bb12a3423dc54fc186f47f491a393537420`
- merge base: `14d87bb12a3423dc54fc186f47f491a393537420`
- Phase 7 branch: ahead only
- ahead of `master`: 70 commits
- behind `master`: 0 commits

The milestone therefore starts from the exact merged Phase 6 source of truth and contains no `main` ancestry drift.

## Green verification on the implementation head
- Godot Smoke: `31564392784` — SUCCESS
  - runtime smoke harness
  - Phase 1 visual regression capture
  - Phase 4 Asset Library visual regression capture
  - Phase 5 Terrain visual regression capture
- Phase 7 Contracts: `31564392859` — SUCCESS
  - `phase7-templates`
  - `phase7-play`
  - `phase7-playable-controllers`
- Phase 7 Visual Evidence: `31564392817` — SUCCESS
- Phase 7 visual evidence artifact: `9128908334`

All Phase 7 workflows use Godot `4.7.1.stable.official.a13da4feb`. Strict CI rejects `SCRIPT ERROR:` and engine `ERROR:` output.

Representative lifecycle verification completed 100 Build/Play transitions in 27 ms against a broad 12,000 ms CI regression budget. This is a regression proxy, not a hardware FPS claim.

## Phase 7 delivered

### Real Build ↔ Play lifecycle
- Build remains the authoritative authored project state.
- Play deep-loads authored data into disposable runtime state rather than converting the editor into the game.
- Play-time runtime mutations do not alter authored project data or authoring Undo/Redo history.
- Build selection is cleared for gameplay and restored on return.
- Autosave is suspended while disposable Play state owns the session and resumes in Build.
- Startup failures roll back input, selection, camera, runtime state, and exclusions safely.
- Repeated Build → Play → Build transitions do not accumulate runtime player nodes.

### Semantic gameplay input
- gameplay uses a dedicated `play_*` semantic layer separate from editor `ui_*` navigation
- keyboard/mouse and gamepad mappings drive the same controller actions
- the Play session removes only gameplay actions it created
- pre-existing editor/user mappings are preserved
- Escape/Back/B reliably returns from Play
- mouse capture is released on exit/failure

### Reusable player/controller foundations
- one stable reusable Phase 7 `player` archetype extends the nine Phase 6 presets
- third-person `CharacterBody3D` movement, jump, mouse/right-stick look, camera distance/height
- first-person `CharacterBody3D` movement, jump option, mouse/right-stick look, eye height
- both run in the existing editor SubViewport world and drive Phase 5 streaming focus
- both use real Phase 5 terrain collision/gravity
- terrain trimesh collision is explicitly two-sided to support robust character contact
- authored player-start proxy/collision is excluded from Play and restored in Build by stable entity ID

### Template system
Seven schema-v1 built-in manifests are data-driven:
- Blank Sandbox
- Third-Person Adventure
- FPS
- Survival
- RPG
- Driving
- Walking Simulator

Manifests declare required runtime modules, deterministic starter entities, semantic input profile, player archetype, camera configuration, graph/HUD references, export settings, tutorials, and planned later-phase modules.

Required unavailable modules, corrupt/incomplete manifests, duplicate IDs, unsupported schema versions, and unsupported input profiles fail closed. Failed application does not partially mutate the project.

Starter world entities receive deterministic stable IDs derived from project/template/starter identity. Materialization is idempotent and leaves a clean authoring history baseline.

Projects may enable/disable available runtime modules and change controller style after creation without rewriting template identity; templates are starters, not permanent genre forks.

Driving uses a real Phase 6 Vehicle archetype prototype but does not fabricate later vehicle-driving behavior.

### Persistence and identity
Verified across save/reopen:
- template ID and runtime module configuration
- semantic input profile
- reusable player archetype reference
- controller/spawn configuration
- deterministic starter entity IDs
- world-cell ownership
- transforms
- component-instance references

External Phase 4 Asset Library source folders remain read-only.

## Rendered evidence inspected
The Phase 7 artifact contains:
- `01-third-person-play.png`
- `02-build-restored.png`
- `03-fps-play.png`

Manual inspection confirms:
- Third-Person Play shows the transient player on terrain without the authored player-start proxy or Build-only empty-state UI.
- Returning to Build restores the editor transform controls, bottom tool dock, and authored editor presentation.
- FPS Play shows a clean first-person world with Play-only status and no duplicate player-start proxy.

## Documentation closeout
Updated for actual Phase 7 implementation:
- `docs/implementation/TASK_BACKLOG.md`
- `docs/implementation/MASTER_IMPLEMENTATION_PLAN.md`
- `docs/systems/TEMPLATE_SYSTEM.md`
- `docs/systems/INPUT_GAMEPAD_TOUCH.md`
- this handoff

## Next action
1. verify the documentation-only closeout commit remains green on inherited/Phase 7 gates;
2. open one Phase 7 completion PR from `dev/phase7-instant-play-templates-milestone` to authoritative `master`;
3. review the PR and checks;
4. merge only after explicit user authorization.

After the Phase 7 completion PR is explicitly merged, verify the resulting authoritative `master` SHA before creating a Phase 8 milestone branch.

**Do not begin Phase 8 before the Phase 7 completion PR is explicitly merged.**