# Security, Privacy, and Licensing

## Local assets
External source folders are treated as read-only. Generated cache/index data stays separate.

## AI credentials
API keys must never be committed to the project. Store credentials in OS/user-scoped configuration or environment-backed secure settings. Local-provider support should work without cloud credentials.

Historical credential material already present in Git history must be treated as exposed and rotated/revoked separately; deleting the working-tree file does not make a historical secret safe again.

## AI privacy
Clearly indicate when project prompts/catalog metadata are sent to a cloud provider. Offer provider-level opt-in controls and a local-only mode.

## Multiplayer security boundary
Phase 15 networking is a gameplay foundation, not a production internet-security platform.

- Direct ENet host/join does not imply account authentication, matchmaking, relay/NAT traversal, anti-cheat, voice security, or dedicated-server trust infrastructure.
- Runtime peer/session/network IDs are transport/session identity, not user authentication.
- Clients are not authoritative for replicated gameplay mutations or runtime persistence.
- Authored project IDs and files must not be rewritten from untrusted peer identity.
- Do not represent a Phase 15 direct-connect session as secure for arbitrary hostile internet exposure without additional security architecture.
- Future collaborative authoring requires server-side permission/capability validation and durable author identity separate from gameplay peers.

## Licensing
Every asset can carry source, author, license, attribution requirements, URL, commercial-use status, and notes. Export validation should surface unknown/restricted assets.

## Generated content
AI/procedural history records which source asset IDs were used so attribution and debugging remain possible.
