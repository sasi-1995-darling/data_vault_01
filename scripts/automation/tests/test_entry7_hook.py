"""Logic-regression wrapper around test_pre_commit.sh — sprint-1-deferred #21.

Runs the bash test harness as a subprocess so the 6 entry-7 enforcement
hook cases are included in the standard pytest sweep. The bash script's
full stdout/stderr is propagated into the pytest failure message so a
specific case failure (e.g. Case 4 git-rename-detection) is identifiable
without re-running the bash script by hand.
"""
import subprocess
from pathlib import Path

import pytest

HARNESS = (
    Path(__file__).resolve().parents[1]
    / "hooks" / "git" / "test_pre_commit.sh"
)


def test_entry7_hook_cases():
    """All 6 entry-7 enforcement hook cases must pass.

    Shells out to bash + creates a scratch git repo; ~1-2s.
    """
    assert HARNESS.is_file(), f"hook test harness not found at {HARNESS}"
    result = subprocess.run(
        ["bash", str(HARNESS)],
        capture_output=True,
        text=True,
        timeout=60,
    )
    if result.returncode != 0:
        pytest.fail(
            f"entry-7 hook test harness failed (exit {result.returncode}).\n\n"
            f"--- stdout ---\n{result.stdout}\n"
            f"--- stderr ---\n{result.stderr}"
        )
