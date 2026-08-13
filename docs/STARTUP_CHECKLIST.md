# Startup / Continuation Checklist

- [ ] Install the Godot 4.7.x version required by the current handoff/workflow; Phase 17 release CI uses Godot 4.7.1.
- [ ] Confirm the repository is `DocDamage/polyfork-project`.
- [ ] Confirm the repository default and authoritative development branch is `master`; never use the historical obsolete `main` branch as the project source of truth.
- [ ] Read `docs/handoffs/CURRENT_HANDOFF.md` before creating a branch or changing code.
- [ ] Verify the authoritative `master` SHA recorded in the handoff against GitHub before branching.
- [ ] Keep `assets/reference/CANONICAL_UI_REFERENCE.png` committed and use it for UI comparisons.
- [ ] Open `project.godot` only after branch authority is resolved.
- [ ] Use the implemented universal Asset Library to register external source folders; do not copy the entire external library into the project and do not mutate registered source folders.
- [ ] Preserve milestone-sized development: internal tasks may be continuous, with one PR at the milestone boundary unless the handoff explicitly says otherwise.
- [ ] Do not merge a milestone PR without explicit user authorization.
