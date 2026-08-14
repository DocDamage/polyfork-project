# Migration, Update Recovery, Repair, and Rollback

## Persistent-data boundary

Projects, preferences, Asset Library configuration, checkpoints, recovery data, update state, and support data remain under the user-data location, not the application directory. Updater operations target application-owned inventory only.

## Migration registry

The migration registry separates application version from persisted schema version. Registered steps run in order, record a journal, create a backup before mutation, and are designed to be idempotent. Unsupported future schemas are refused instead of guessed or rewritten.

A failed step restores its backup when possible and leaves the migration journal available for diagnosis. Project migration logic does not live in unrelated UI code.

## Update journal

The update journal records operation ID, operation, stage, artifact, application root, backup root, previous and replacement inventories, completed paths, errors, and outcome. An interrupted journal cannot be silently overwritten by another check or download.

Choosing repair archives the interrupted journal before starting the repair operation. This preserves incident evidence while allowing a verified repair package to proceed.

## Repair

Repair uses the last locally verified update package. The artifact is revalidated and handed to the same bounded external helper used for normal updates. Repair does not use or delete project content.

## Rollback

Rollback uses a verified application-binary backup and its inventory. The helper verifies every backup file before restoring it. It removes only application-owned replacement files; unrelated files in a portable folder remain untouched. Rollback does not downgrade or delete authored project data.

## Abnormal shutdown and safe mode

A startup marker and clean-shutdown marker distinguish normal exit from an abnormal prior session. The recovery screen can launch safe mode or reset preferences non-destructively. Safe mode disables optional update networking, cloud AI, and multiplayer for the session; it does not modify projects.
