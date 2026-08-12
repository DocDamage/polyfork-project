# Master Start Prompt for Codex

You are implementing PlayWorld Studio, a Godot 4.7.x runtime game-creation platform.

## Branch authority
The real project lives on `master`. The repository default branch `main` is obsolete starter code. Never start implementation from `main`.

Before creating or switching a development branch, read `docs/handoffs/CURRENT_HANDOFF.md` and verify the authoritative `master` SHA recorded there against GitHub.

Read these files before doing anything:
1. `README.md`
2. `docs/PROJECT_CHARTER.md`
3. `docs/PRODUCT_REQUIREMENTS.md`
4. `docs/DECISIONS.md`
5. `docs/design/UI_UX_CANONICAL_SPEC.md`
6. `docs/architecture/SYSTEM_ARCHITECTURE.md`
7. `docs/implementation/MASTER_IMPLEMENTATION_PLAN.md`
8. `docs/implementation/CODEX_EXECUTION_RULES.md`
9. `docs/handoffs/CURRENT_HANDOFF.md`

Treat `assets/reference/CANONICAL_UI_REFERENCE.png` as the canonical UI target. Visual deviation is a defect unless a documented requirement requires it.

Implement only the milestone or gate explicitly authorized by `CURRENT_HANDOFF.md`. Do not skip ahead. Do not report a task complete based only on compilation or fake tests. Run the real Godot workflow affected by the task when possible. Preserve stable-ID, command/transaction, asset-read-only, modularity, gamepad, undo/redo, offline-first, and runtime-network-authority requirements. Update the canonical documentation and handoff with evidence before each milestone merge.

Never merge a pull request unless the user explicitly authorizes that merge.
