# Troubleshooting PlayWorld Studio 0.1.0

## Check the running build

Open **About**. Stable builds should show PlayWorld Studio `0.1.0`, stable channel, Windows x64, Godot runtime information and source/build identity.

## Create a support report

From Home choose **Support**. The Support & Recovery surface can create `PlayWorld-Support.json` in the per-user support directory. The report is intentionally bounded to product/build/runtime/OS/rendering/GPU/install mode, user-data directory locations, exporter/template availability, schema and Asset Library health. It does not intentionally include project contents or provider credentials.

## A project will not open

Open **Support & Recovery**. Damaged project metadata is listed separately from healthy worlds. If a valid checkpoint exists, choose the recovery action. PlayWorld Studio preserves the damaged canonical metadata before promoting the checkpoint. If no valid checkpoint exists, the UI reports that recovery is unavailable rather than deleting data.

## Settings fail to load

Malformed preferences fall back to safe defaults and the malformed file is preserved as a recovery backup. Reconfigure preferences after launch if needed.

## Asset Library source unavailable

The registered external folder may have moved, been disconnected, or become inaccessible. Restore the original path/drive or register the correct source folder again. PlayWorld Studio does not move the originals automatically.

## Windows export fails

Open Support and check exporter/template availability. The release package must retain `tools/godot/` and `tools/export_templates/4.7.1.stable/`. In portable mode, extract/copy the complete package rather than only `PlayWorld Studio.exe`. In installed mode, run the installer again to repair missing application files.

## Application directory is not writable

Do not redirect projects into the application directory. PlayWorld Studio stores user state in the Windows user profile and is verified against a read-only-style application location. If the executable itself is damaged or incomplete, repair/reinstall the application.

## Upgrade from the RC behaves unexpectedly

Do not delete the per-user PlayWorld Studio directory. Use Support & Recovery to inspect migration state and project health. Migration/recovery backups are kept separately from application files. Repair/reinstall the stable application if bundled components are missing.

## Uninstall did not remove my projects

That is intentional. Phase 18 uninstall removes application files/shortcuts while preserving authored per-user data. Delete user data separately only after making any desired backup.

## Known infrastructure warning

GitHub-hosted Windows visual QA may fall back through ANGLE/Microsoft Basic Render Driver. That hosted-runner condition is not used to suppress unrelated PlayWorld Studio errors.

<!-- PHASE19_CORRECTION_STATUS_START -->
## Update and recovery troubleshooting

When an update is interrupted, do not delete the user-data directory. Open Settings → Updates and use Repair or Rollback when available. Safe mode disables optional networking/cloud/multiplayer for the session. Generate a local support bundle only after reviewing its bounded contents. Hash, signature, path, or privacy failures are hard stops and should be preserved for incident review.
<!-- PHASE19_CORRECTION_STATUS_END -->
