# Windows Game Export from the Distributed Creator

PlayWorld Studio's creator package contains the tooling required to invoke the existing authored-game export pipeline without a development checkout.

The package includes:

- a Godot 4.7.1 exporter executable under `tools/godot`;
- the Windows x86_64 release template under `tools/export_templates/4.7.1.stable`.

When a game export begins, PlayWorld first uses an explicitly configured exporter if present, then an exporter named by `PLAYWORLD_GODOT_EXPORTER`, then the bundled exporter. The required Windows template is installed into the current user's Godot export-template directory when it is not already present.

Export still uses the existing runtime-only dependency closure. Authored runtime data, required Asset Library dependencies, license/attribution data, performance profile data, and standalone bootstrap are staged. Editor-only creator material is not copied into the authored-game package.

A missing configured exporter, missing bundled exporter, missing template, invalid output destination, unavailable dependency, or Godot export failure is an explicit failure. No successful package is reported if the executable was not produced.
