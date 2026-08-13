# Install PlayWorld Studio on Windows

## Release candidate package

Phase 17 distributes PlayWorld Studio as a portable Windows x64 package:

`PlayWorld-Studio-0.1.0-rc.1-Windows-x64.zip`

1. Verify the ZIP against its adjacent `.sha256` file.
2. Extract the entire package to a normal application folder.
3. Keep the `tools` directory beside `PlayWorld Studio.exe`; it contains the bundled Godot exporter and Windows runtime template required for creator-to-game export.
4. Launch `PlayWorld Studio.exe`.

The creator does not store projects, shared Asset Library state, or preferences inside the installation directory. Those use Godot per-user storage under the current Windows user profile.

## Upgrade or reinstall

Close PlayWorld Studio, replace or relocate the application package, then relaunch it under the same Windows user account. Existing projects, preferences, and shared Asset Library state remain in per-user storage and are discovered independently of the install directory.

The RC is distributed as a ZIP package. A traditional installer is not part of the minimum Phase 17 release boundary.
