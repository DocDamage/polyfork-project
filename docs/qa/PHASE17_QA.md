# Phase 17 QA — Release Candidate and Distribution

## Release gates

Phase 17 is not complete from source contracts alone. The dedicated `.github/workflows/phase17-release.yml` workflow must validate the actual Windows creator package.

Required evidence:

- Godot Smoke;
- Phase 17 release identity/failure contracts;
- Phase 16 product/integration/shared Asset Library contracts;
- discoverable inherited Phase 4–15 suites;
- Phase 7 playable controller smoke;
- Phase 14 scale stress and Windows profile export;
- Phase 15 exported multiplayer host/client verification;
- Phase 16 Windows clean-package export regression;
- deterministic creator package build and package integrity scan;
- clean packaged creator first launch;
- real template + biome project creation;
- command-backed entity place/edit;
- save, close, relaunch, reopen, persisted-state check;
- Instant Play and return to Build;
- real GLTF Asset Library source/catalog behavior;
- packaged creator → standalone Windows game export → game launch;
- preferences/shared-library/project persistence across package relocation;
- read-only-style install-path run with writable user data;
- packaged UI evidence at 1600×900, 1280×720, compact, New World, and workspace;
- release ZIP, release manifest, SHA-256 files, third-party notices, and forbidden-material scan.

Any strict `SCRIPT ERROR:` or engine `ERROR:` in a release gate is a failure unless a test explicitly owns and isolates that engine behavior without declaring the release successful.
