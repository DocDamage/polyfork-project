# Test Matrix

| Area | Unit/contracts | Integration/runtime | Persistence/recovery | Controller/accessibility | Visual | Export/package/install |
|---|---|---|---|---|---|---|
| App shell/Home | ✓ | packaged creator | stable user settings | A→`ui_accept`, D-pad/focus | Home full + compact, About, Settings, Support | portable + installed |
| World save | ✓ | create/open/save | atomic save, checkpoint recovery, restart/reopen, RC→stable | UI paths retained | recovery UX | user data outside install |
| Placement/editor | ✓ | packaged authoring | authored IDs/transforms persist | inherited acceptance | Build workspace | creator package |
| Asset Library | ✓ | real shared GLTF fixture | shared catalog/source paths persist | Home/library navigation | Asset Library | dependency closure |
| Terrain/streaming | ✓ | inherited Phase 5/14 | ✓ | ✓ | inherited | Small/Medium/Large Windows export |
| Components/prefabs | ✓ | inherited | ✓ | ✓ | inherited | ✓ |
| Instant Play/templates | ✓ | inherited playable smoke | template/biome persist | Build↔Play | Play capture | packaged creator |
| Visual Scripting | ✓ | inherited | ✓ | ✓ | inherited | authored-game runtime |
| Procedural/foliage/splines | ✓ | inherited | ✓ | ✓ | inherited | ✓ |
| Gameplay framework | ✓ | inherited | ✓ | ✓ | inherited | ✓ |
| Environment | ✓ | inherited | ✓ | ✓ | inherited | ✓ |
| AI Creation | ✓ | inherited privacy/transaction contracts | configuration safety | UI-relevant controls | inherited | explicit provider/config failure |
| Authored-game export | ✓ | packaged creator exports and launches game | project remains intact | Export surface | Export capture | bundled Godot/templates/runtime closure |
| Multiplayer Play | ✓ | exported host/client connection | authored state isolation | inherited input ownership | inherited | concurrent Windows host/client |
| Stable distribution | Phase 18 contracts | portable + installed executable | clean first/reopen, repair, uninstall preserve, RC upgrade | Phase 17 packaged acceptance retained | 11-screen stable evidence set | deterministic ZIP, installer, checksums, scans |
| Diagnostics/recovery | ✓ | Support & Recovery surface | corrupt-project backup + checkpoint promotion; malformed-pref backup | focusable Home action | Support capture | bounded support bundle validation |

## Phase 18 mandatory release assertions

- Stable identity is `0.1.0`; RC identity appears only as historical or upgrade-source data.
- Portable ZIP independently rebuilds byte-for-byte from identical inputs.
- Clean portable first launch performs real create/edit/save/Asset Library/Instant Play/export/launch.
- Clean installed first launch performs real create/edit/save/export/launch.
- Exact Phase 17 RC artifact and SHA are verified before upgrade testing.
- Stable portable and installed executable both preserve the RC-created profile.
- Repair/reinstall retains user data; uninstall removes application payload while authored data remains.
- Read-only/alternate application locations do not redirect user data into the install directory.
- Damaged canonical project metadata is backed up and restored from a valid checkpoint.
- Malformed preferences fall back to defaults while preserving a recovery backup.
- Generated support diagnostics exclude unrelated project content and release-rejected material.
- Packaged controller/accessibility marker remains mandatory: `PASS: Phase 17 packaged creator UI, controller, accessibility, and major-screen acceptance completed.`
- Final stable screenshots must be downloaded and visually inspected; existence alone is not approval.
- The About/version capture must prove the actual About surface, stable `0.1.0` identity, Windows x64, Godot version, and source identity.

## Final Phase 18 evidence

Workflow `31699466148` passed `source-regressions` and `windows-stable-release` on the exact corrective source. Artifact and checksum verification, lifecycle evidence, controller/accessibility results, and manual inspection of all eleven screenshots are recorded in `docs/qa/PHASE18_QA.md` and merged PR #24.

Phase 18 is complete and accepted on signed `master@49a5b55748244097d952ab9c095dd00ed0ec9f06`.

<!-- PHASE19_CORRECTION_STATUS_START -->
## Phase 19 matrix extension

Use `docs/qa/PHASE19_QA.md` as the exact-head evidence ledger. Test Stable/Beta isolation, accepted and rejected real signatures, portable and installed lifecycles, interruption at every replacement boundary, sequential migration, abnormal shutdown, safe mode, bounded diagnostics, support privacy, offline authoring/export, physical or simulated controller paths, normal/compact layouts, and publication dry run without creating a tag or release.
<!-- PHASE19_CORRECTION_STATUS_END -->
