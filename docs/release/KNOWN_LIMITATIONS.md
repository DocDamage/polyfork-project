# Known Limitations — 0.1.0-rc.1

- Distribution is Windows x64 only for this release candidate.
- The minimum Phase 17 package is a portable ZIP; a traditional Windows installer is not included.
- Game export is Windows-targeted and depends on the bundled Godot 4.7.1 exporter/template remaining beside the creator package.
- Production matchmaking/relay/account/voice/anti-cheat/rollback/dedicated-server infrastructure is not included.
- Production real-time collaborative authoring mutation is not included.
- Cloud marketplace infrastructure and arbitrary FBX repair/conversion are not included.
- AI cloud use requires explicit provider configuration and cloud consent; provider service availability is external to PlayWorld Studio.
- External Asset Library sources that are moved, deleted, or become unreadable can make dependent exports fail until the source is restored or references are repaired.
