# Security, Privacy, and Licensing

## Local assets
External source folders are treated as read-only. Generated cache/index data stays separate.

## AI credentials
API keys must never be committed to the project. Store credentials in OS/user-scoped configuration or environment-backed secure settings. Local-provider support should work without cloud credentials.

## AI privacy
Clearly indicate when project prompts/catalog metadata are sent to a cloud provider. Offer provider-level opt-in controls and a local-only mode.

## Licensing
Every asset can carry source, author, license, attribution requirements, URL, commercial-use status, and notes. Export validation should surface unknown/restricted assets.

## Generated content
AI/procedural history records which source asset IDs were used so attribution and debugging remain possible.
