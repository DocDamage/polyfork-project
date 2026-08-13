# Phase 18 — Stable Release and Windows Productization Plan

## Objective

Convert the merged Phase 17 `0.1.0-rc.1` creator into **PlayWorld Studio 0.1.0** without replacing working editor/runtime/export architecture.

## Authority

- Base: `master@91b8b9c39fddda4b80ad5c6101d563245ef3e2d0`.
- Branch: `dev/phase18-stable-release`.
- Completion PR: #23 to `master`, unmerged until explicitly authorized.

## Deliverables

1. Stable identity and deterministic portable ZIP.
2. Real Windows installer/uninstaller.
3. User-data/install separation.
4. Exact RC→stable migration validation using Phase 17 artifact `9169222546` and RC ZIP SHA `8db8162872077d00582ab20de5361a59cae19a45a9bacb2a3a7f199d18b4d9b9`.
5. Checkpoint-based project recovery and malformed-preference recovery backups.
6. Support & Recovery UI plus bounded diagnostics.
7. Portable and installed lifecycle QA, including clean first run, restart/reopen, repair/reinstall, uninstall preservation, alternate/read-only application location, export, and exported-game launch.
8. Inherited controller/accessibility/scale/export/multiplayer regressions.
9. Stable visual evidence and manual inspection.
10. Package/installer/support security scanning.
11. Stable release documentation and PR evidence.

## Architecture rule

Reuse Phase 17 packaging/export, Phase 2 atomic-save/checkpoint infrastructure, the universal Asset Library, current `PlaySession`, current authored-game export pipeline, and existing UI shell. Phase 18 adds productization around them; it does not create parallel versions.

## Completion

The exact final branch head must pass `.github/workflows/phase18-stable-release.yml`. The final artifact must contain the stable portable ZIP, its checksum/manifest, installer and checksum, release docs/notices, logs, and visual evidence. The screenshots must then be downloaded and inspected. PR #23 must contain exact run/artifact/checksum results and known limitations before it is marked ready; it remains unmerged.
