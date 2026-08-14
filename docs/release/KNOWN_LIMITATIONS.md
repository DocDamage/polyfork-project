# Known Limitations — PlayWorld Studio 0.1.0

- Phase 18 is a Windows x86_64 productization milestone. Linux, macOS and mobile distributions are not part of this release.
- The portable ZIP is deterministic for identical inputs. Byte-for-byte installer reproducibility is not claimed; Inno Setup/compiler metadata may vary, so the installer is distributed with an explicit SHA-256 instead.
- The installer is not claimed to be code-signed unless a future release adds and verifies a signing pipeline.
- There is no production auto-update service in Phase 18. Upgrade is performed by replacing the portable package or running the newer installer while retaining the same Windows user profile.
- External Asset Library folders remain external/read-only. Disconnected or moved source folders must be restored or re-registered by the user.
- Recovery can only restore a damaged project when a valid checkpoint exists. It does not invent missing authored data.
- Multiplayer remains the bounded direct-connect gameplay foundation from Phase 15; it is not production matchmaking/relay, dedicated-server fleets, rollback networking, voice chat, anti-cheat, or collaborative editor mutation.
- AI provider behavior remains subject to configured local/cloud provider availability and the existing privacy/consent rules.
- Historical legacy API credential material remains present in repository history and must be treated as exposed; the release scanner prevents that material from being packaged but cannot prove external credential rotation/revocation.
- GitHub-hosted visual QA can use Microsoft Basic Render Driver through ANGLE; this is CI infrastructure, not the expected end-user GPU path.

<!-- PHASE19_CORRECTION_STATUS_START -->
## Phase 19 candidate limitations

The initial update lifecycle remains Windows x86_64 only. Authenticode signing is not claimed by this milestone. Production update signing requires externally provisioned protected private keys; placeholder Stable/Beta trust records are intentionally disabled until provisioned. Phase 19 source is not an accepted public release until exact-head evidence and explicit publication authorization exist.
<!-- PHASE19_CORRECTION_STATUS_END -->
