# Phase 19 Security and Privacy Behavior

## Update security

- Signed metadata is verified before artifact identity is trusted.
- Key IDs are channel authorized and have activation, expiration, enabled, and revocation state.
- Artifacts require exact filename, HTTPS host policy, byte size, and SHA-256.
- The Windows helper accepts only a strict short-lived JSON request inside a bounded update-data directory.
- Application root, backup, journal, request, artifact, and restart paths are independently constrained.
- Portable archive entries reject traversal, absolute paths, drive paths, reparse points, excessive count, and excessive expanded size.
- Replacement is based on release-manifest-owned inventory instead of deleting the application directory.
- Unrelated files and all user-data roots are outside the replacement inventory.

## Signing material

Only public keys belong in the repository. The production workflow reads the private signing material from a protected environment secret, writes it to a temporary runner file with restricted permissions, and never uploads it as an artifact.

## Diagnostics and support bundles

Diagnostics are local and bounded. They may include product/build identity, install mode, logical application/user-data locations, runtime/GPU information, last update state, migration/session-recovery state, project schema version, Asset Library health, exporter availability, and bounded recent errors.

Support bundles are user initiated and remain local unless the user shares them. They exclude authored project content, credentials, environment secrets, and unrelated private files by default. Absolute user/home paths are redacted. Source, packages, logs, diagnostics, and support output are scanned for credential-like and private-key material.

## Incident rule

A signature failure, hash mismatch, path-boundary failure, privacy-scan failure, or unexpected package inventory is a hard stop. The application remains usable offline, but the update is not installed or published.
