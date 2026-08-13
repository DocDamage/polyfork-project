# System Requirements — PlayWorld Studio 0.1.0

## Supported release target

- Windows 10/11 x64 class desktop environment.
- x86_64 processor.
- Hardware/driver capable of running Godot 4.7.x rendering paths.
- Writable per-user profile storage for projects, preferences, Asset Library metadata, migration/recovery state and exported content.
- Sufficient disk space for the application package, bundled Godot/export templates, source assets, projects and generated game exports.

## Performance baseline

The project architecture treats an RTX 3060 12 GB class GPU as the Balanced quality baseline. Lower-spec systems may require reduced performance profiles, smaller worlds, lower asset density or reduced visual settings.

## Export requirements

The distributed PlayWorld Studio package includes the Godot 4.7.1 exporter, Windows release template and runtime source closure needed for supported Windows game export. A separate Godot installation is not required for the verified Windows export workflow.

## Not covered by Phase 18

Linux/macOS releases, mobile builds, dedicated-server fleets and production cloud services are outside the stable Windows 0.1.0 milestone.
