#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

START = "<!-- PHASE19_CORRECTION_STATUS_START -->"
END = "<!-- PHASE19_CORRECTION_STATUS_END -->"

SECTIONS = {
    "docs/implementation/MASTER_IMPLEMENTATION_PLAN.md": """
## Phase 19 corrective completion status

PR #27 was integrated before the full Phase 19 milestone existed. Corrective work proceeds from signed `master@ebeb35e28f53738c63d35429eba1ea40b5c8cdb1` on `dev/phase19-completion-correction`. Phase 19 remains incomplete until the exact final corrective PR head passes the full source, Windows update, real `0.1.0 → 0.2.0`, security, controller/accessibility, publication-dry-run, and manually reviewed visual gates. Phase 20 remains unauthorized.
""",
    "docs/implementation/TASK_BACKLOG.md": """
## Active milestone override — Phase 19 corrective completion

The only active milestone is Phase 19 completion and evidence closeout. Required work covers P19-T01 through P19-T16 in `PHASE19_UPDATE_RELEASE_INFRASTRUCTURE_PLAN.md`. Do not schedule Phase 20 work, create a Phase 20 branch, tag `v0.2.0`, or publish a release from this backlog state.
""",
    "docs/qa/QUALITY_GATES.md": """
## Phase 19 release-maintenance gates

Phase 19 adds strict signed-manifest, channel, staging, migration, session-recovery, updater-helper, deterministic package, installer, real portable/installed `0.1.0 → 0.2.0`, interruption, repair, rollback, offline/export, controller/accessibility, visual, privacy, security, and publication-dry-run gates. Inherited checks do not replace these focused gates. Screenshot existence alone is not visual acceptance.
""",
    "docs/qa/TEST_MATRIX.md": """
## Phase 19 matrix extension

Use `docs/qa/PHASE19_QA.md` as the exact-head evidence ledger. Test Stable/Beta isolation, accepted and rejected real signatures, portable and installed lifecycles, interruption at every replacement boundary, sequential migration, abnormal shutdown, safe mode, bounded diagnostics, support privacy, offline authoring/export, physical or simulated controller paths, normal/compact layouts, and publication dry run without creating a tag or release.
""",
    "docs/release/INSTALL_WINDOWS.md": """
## 0.2.0 update candidate

Phase 19 distinguishes portable replacement from installed-mode installer handoff. Both preserve persistent per-user data outside the application directory. The accepted `0.1.0` application does not contain this updater; the real `0.1.0 → 0.2.0` bootstrap uses the verified replacement ZIP or installer path and is proven in the Phase 19 Windows workflow.
""",
    "docs/release/USER_DATA_AND_UPGRADE.md": """
## Phase 19 data-safety extension

Update, repair, reinstall, rollback, and uninstall operate on application binaries and preserve projects, preferences, Asset Library state, checkpoints, recovery data, and support data. Sequential migrations create backups and journals. Unsupported future schemas are refused. See `MIGRATION_ROLLBACK_RECOVERY.md`.
""",
    "docs/release/TROUBLESHOOTING.md": """
## Update and recovery troubleshooting

When an update is interrupted, do not delete the user-data directory. Open Settings → Updates and use Repair or Rollback when available. Safe mode disables optional networking/cloud/multiplayer for the session. Generate a local support bundle only after reviewing its bounded contents. Hash, signature, path, or privacy failures are hard stops and should be preserved for incident review.
""",
    "docs/release/KNOWN_LIMITATIONS.md": """
## Phase 19 candidate limitations

The initial update lifecycle remains Windows x86_64 only. Authenticode signing is not claimed by this milestone. Production update signing requires externally provisioned protected private keys; placeholder Stable/Beta trust records are intentionally disabled until provisioned. Phase 19 source is not an accepted public release until exact-head evidence and explicit publication authorization exist.
""",
}


def upsert(path: Path, body: str) -> None:
    if not path.exists():
        return
    text = path.read_text(encoding="utf-8")
    block = f"\n{START}\n{body.strip()}\n{END}\n"
    if START in text and END in text:
        before, remainder = text.split(START, 1)
        _, after = remainder.split(END, 1)
        text = before.rstrip() + block + after.lstrip("\n")
    else:
        text = text.rstrip() + "\n" + block
    path.write_text(text, encoding="utf-8")


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    for relative, body in SECTIONS.items():
        upsert(root / relative, body)
    print("PASS: Phase 19 documentation reconciliation blocks applied.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
