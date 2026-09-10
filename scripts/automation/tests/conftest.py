"""Repo-wide pytest fixtures for scripts/automation tests.

The single fixture here is a session-scoped LEAK GUARD that snapshots
`scripts/automation/configs/` at session start and asserts no NEW
top-level entries appeared by session end.

Why: pipeline_orchestrator._persist_profile_markdown and
_append_reconciliation_to_profile_md write under SCRIPT_DIR/configs/<config>/.
Several behavioural tests (around cmd_approve_profile) historically forgot to
patch SCRIPT_DIR and silently polluted the real repo with `configs/test__src/`.
The directory is gitignore-clean but reappeared on every `git status` after
every test run, generating reviewer noise on unrelated PRs.

This guard FAILS the session at teardown if any new entry appears. The error
message tells the maintainer exactly which test path they need to sandbox
(usually via `patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path)`).

The guard is opt-out: if a test legitimately needs to create new config files
(e.g. a future end-to-end fixture), it can register the expected name via the
`_configs_leak_allowlist` fixture before the assertion runs.
"""
from __future__ import annotations

from pathlib import Path

import pytest

# Real on-disk path that production code writes to. Resolved once at import so
# the fixture is independent of any monkeypatching that may happen later.
_CONFIGS_DIR = (Path(__file__).resolve().parent.parent / "configs")


@pytest.fixture(scope="session")
def _configs_leak_allowlist() -> set[str]:
    """Mutable set of entry names test code is permitted to create.

    Tests that legitimately add to configs/ should add the entry name here
    before producing the file, e.g.:
        def test_thing(_configs_leak_allowlist):
            _configs_leak_allowlist.add("my_legit_config")
    """
    return set()


@pytest.fixture(scope="session", autouse=True)
def _guard_configs_dir_no_leaks(_configs_leak_allowlist):
    """Snapshot configs/ at session start; fail at session end on new entries.

    This catches the SCRIPT_DIR-not-patched bug class. Modifications to
    existing entries (committed YAML configs, etc.) are NOT flagged \u2014 we
    only assert that the SET of top-level names is unchanged (minus any
    entries explicitly allow-listed by a test).
    """
    if not _CONFIGS_DIR.exists():
        # Nothing to guard yet; create the dir would itself be a leak signal.
        before: set[str] = set()
    else:
        before = {p.name for p in _CONFIGS_DIR.iterdir()}

    yield

    if not _CONFIGS_DIR.exists():
        return  # Directory was never created; nothing to compare.

    after = {p.name for p in _CONFIGS_DIR.iterdir()}
    new_entries = after - before - _configs_leak_allowlist
    if new_entries:
        # Build an actionable message. Most leaks come from tests calling
        # cmd_approve_profile / cmd_generate_code without patching SCRIPT_DIR.
        leaked = sorted(new_entries)
        msg = (
            "\n\nTEST LEAK DETECTED in scripts/automation/configs/:\n"
            f"  New entries appeared during the test session: {leaked}\n\n"
            "Likely cause: a test invoked cmd_approve_profile (or another\n"
            "orchestrator command that calls _persist_profile_markdown /\n"
            "_append_reconciliation_to_profile_md) without patching\n"
            "pipeline_orchestrator.SCRIPT_DIR to a tmp_path.\n\n"
            "Fix the offending test by adding:\n"
            '    patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path)\n'
            "to its mock context, OR (if the file is intentional) declare it\n"
            "in the test via the _configs_leak_allowlist fixture.\n\n"
            "Delete the leaked entries to clean up:\n"
            + "\n".join(f"    rm -rf scripts/automation/configs/{n}" for n in leaked)
        )
        pytest.fail(msg)
