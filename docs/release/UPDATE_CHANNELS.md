# Update Channels and Signed Metadata

## Channels

- **Stable** is the default and accepts only stable-version metadata signed by a Stable-authorized key.
- **Beta** is an explicit user preference and accepts only Beta metadata signed by a Beta-authorized key.
- **Development** is disabled for normal production use and appears only when an internal opt-in setting is enabled.

Changing channels is reversible, stored as a user preference, and never written into authored project data. A channel change does not itself migrate or downgrade a project.

## Update check behavior

Update checks are optional and do not block startup. Background checks use timeout, cache/backoff, and one-operation-at-a-time rules. Offline, timeout, malformed, or unavailable endpoints leave normal creator use functional. Safe mode disables update networking for that session.

## Trust model

A manifest envelope carries a key ID, canonical base64 JSON payload, and RSA/SHA-256 signature. Acceptance requires:

- strict envelope and payload shape;
- exact PlayWorld Studio product identity;
- exact selected channel;
- valid semantic-version transition;
- authorized active non-revoked key;
- exact Windows x86_64 artifact inventory;
- HTTPS URL on the selected channel allowlist;
- safe filename;
- exact byte size and SHA-256;
- no duplicate artifact kind;
- stable-channel prerelease rejection;
- no unauthorized downgrade.

The repository stores public trust records only. Private signing material belongs in the protected production release environment and must never be committed.

## Download and staging

Artifacts download to `user://updates/staging`, first as a partial file. A partial or stale file is never “ready.” Exact size and SHA-256 are checked before promotion. The external helper revalidates the artifact and bounded request before changing application binaries.
