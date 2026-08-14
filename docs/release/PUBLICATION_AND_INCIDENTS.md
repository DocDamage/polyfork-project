# Release Publication and Update Incident Procedure

## Production publication

The production workflow is manual only. It requires:

1. exact approved 40-character source commit;
2. exact successful Phase 19 Windows workflow run;
3. selected Stable or Beta channel;
4. exact `v0.2.0` tag input;
5. explicit authorization phrase;
6. protected production environment approval;
7. protected signing key matching an enabled public trust record;
8. local artifact validation and security scan;
9. signed manifest construction and local verification;
10. draft release creation and exact inventory upload;
11. re-download of every uploaded asset;
12. SHA-256 and signature verification of downloaded assets;
13. separate explicit publish boolean.

A normal PR run, branch push, merge, or successful dry run cannot create a public release.

## Update incident response

For a suspected bad update:

- stop publication or leave the release in draft;
- disable or revoke the affected key record as appropriate;
- remove the affected channel endpoint from active distribution;
- preserve manifests, hashes, workflow run IDs, artifact IDs, helper logs, and update journals;
- do not delete user projects or ask users to overwrite their user-data directory;
- provide repair or rollback instructions using verified application artifacts;
- issue a corrected signed manifest only after root cause and artifact identity are verified;
- document impact, affected versions/channels, remediation, and key-rotation decision.

## Rollback of publication

Do not silently replace an already published asset under the same identity. Publish a corrected version with new immutable artifact hashes and signed metadata. A revoked manifest or key does not authorize destructive changes to installed user data.
