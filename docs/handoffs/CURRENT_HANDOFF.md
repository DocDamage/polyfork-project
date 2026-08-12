# POLYFORK PROJECT — PHASE 13 COMPLETION HANDOFF

Repository: `https://github.com/DocDamage/polyfork-project`

Use the GitHub connector for repository work.

## Authoritative branch
The real project lives on `master`.

Authoritative pre-Phase-13 `master`:

`b2a97a6cea52c6620f2b826a390a1d2d531ad81e`

This is the verified merge commit for PR #17 — Phase 12 — AI Creation. Phases 0 through 12 are complete and merged.

The repository default branch `main` remains obsolete starter code. **Never develop from `main`.**

## Phase 13 branch and base
Phase 13 — Export Pipeline was developed continuously on:

`dev/phase13-export-pipeline-milestone`

The branch was created from exactly:

`b2a97a6cea52c6620f2b826a390a1d2d531ad81e`

Before Phase 13 writes, GitHub compare verification reported:
- merge base exactly `b2a97a6cea52c6620f2b826a390a1d2d531ad81e`;
- 0 commits ahead;
- 0 commits behind;
- no obsolete `main` ancestry used.

Verified code-complete head before documentation closeout:

`e8c939a4bc86ef011fcb42c0e8f4b197b470b4e2`

## Phase 13 status
**Phase 13 implementation is complete.**

All internal checkpoints P13-T01 through P13-T10 are complete. The only authorized next repository action is opening the single Phase 13 completion PR to authoritative `master` and leaving it unmerged until explicit user authorization.

## Delivered Phase 13 capability
Phase 13 delivered a Windows-first export pipeline without creating a second runtime architecture.

Delivered behavior includes:
- schema-v1 export/build manifest and strict safe-path/target/classification validation;
- exact deterministic runtime source dependency closure;
- deterministic staging/assembly and repeat-stage replacement;
- explicit stripping of editor shell/workspaces, authoring-only AI data, checkpoints/recovery copies, and other non-runtime project data;
- preservation of authored world, terrain, gameplay, Visual Scripting, procedural, Environment, template/runtime, and resolved asset data required by standalone builds;
- standalone bootstrap through thin adapters into the existing Phase 7 `PlaySession`;
- Phase 7 runtime-module validation kept separate from Phase 4 Asset Library UUID resolution;
- deterministic Asset Library dependency discovery/resolution with hard failure for missing or unavailable required assets;
- read-only external asset sources with only required files staged into managed export space;
- source lineage plus machine-readable and human-readable license/attribution reporting;
- explicit unknown/missing-license findings without invented license grants or compatibility claims;
- generated Windows Godot export preset and actionable export failures;
- deterministic output/package/report structure;
- repeat-export idempotency/stale-file replacement;
- clean-package copy and launch verification outside the editor project;
- Small/Medium/Large standalone Windows verification;
- keyboard/mouse and gamepad semantic input verification in exported builds;
- compact canonical Build-mode Export UI with deterministic output/status controls;
- Export blocking for no-project, Play, transient placement, and invalid states;
- strict Phase 13 foundation/runtime/workspace tests;
- inherited Phase 6–12 regression coverage;
- Godot Smoke;
- rendered canonical Build → Export evidence;
- exported standalone runtime/package evidence.

## Verified completion gates
All five required workflows passed on the exact code-complete head `e8c939a4bc86ef011fcb42c0e8f4b197b470b4e2`:

- **Godot Smoke** — run `31617622730`
- **Phase 13 Windows Export** — run `31617622756`
- **Phase 13 Visual Evidence** — run `31617622776`
- **Phase 13 Inherited Regressions** — run `31617622791`
- **Phase 13 Contracts** — run `31617622792`

The Windows gate verifies Build/stage/export for Small/Medium/Large projects, repeat export with stale-file replacement, copy to a separate clean-package location, standalone executable launch, Phase 7 third-person runtime boot, and keyboard/mouse plus gamepad semantic input bindings.

The inherited regression gate verifies Phase 6 through Phase 12 contract coverage plus the Phase 7 playable-controller smoke. The rendered evidence gate captures the actual canonical Build → Export UI state.

## Security closeout reminder
The tracked `.polyforkAPI` file was removed during Phase 12 and is ignored going forward. Its historical credential material remains present in Git history and should still be considered exposed and rotated/revoked separately.

## Completion PR gate
Open exactly one Phase 13 completion PR from:

`dev/phase13-export-pipeline-milestone`

to authoritative:

`master`

The PR must remain **unmerged** until explicit user authorization is given.

Do not enable auto-merge. Do not begin Phase 14 until the Phase 13 completion PR is explicitly merged and the resulting authoritative `master` SHA is verified.
