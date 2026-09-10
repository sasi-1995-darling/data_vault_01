#!/usr/bin/env python3
"""Per-check exception isolation in ``review_file`` (CI resilience).

Regression guard for the 2026-06 incident: a function-local ``import yaml``
in the governance-allowlist check (I5) raised ``ModuleNotFoundError`` on a
bare CI runner and crashed the *entire* reviewer, discarding all 50+ other
checks' results. ``review_file`` now isolates each check so one failure is
surfaced as a FAIL finding instead of aborting the run.
"""

import sys
from pathlib import Path

import pytest

SCRIPT_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = SCRIPT_DIR / "src"
sys.path.insert(0, str(SRC_DIR))

import code_reviewer
from code_reviewer import CheckEntry, Severity, review_file
from code_review_config import FileStatus

_SQL_FILE = "models/int_staging_views/foo/v_psa_stg_bar.sql"


def _boom(**kwargs):
    raise RuntimeError("simulated check failure")


class TestPerCheckIsolation:
    """A crashing check must not abort the run; it becomes a FAIL finding."""

    def test_crashing_check_does_not_raise(self, monkeypatch):
        patched = dict(code_reviewer.CHECK_REGISTRY)
        patched["ZZ9"] = CheckEntry(_boom, [".sql"], "Z")
        monkeypatch.setattr(code_reviewer, "CHECK_REGISTRY", patched)

        # Must not raise even though ZZ9 explodes.
        findings = review_file(
            file_path=_SQL_FILE,
            sql_content="select 1\n",
            file_status=FileStatus.NEW,
            check_filter="ZZ9",
        )

        zz9 = [f for f in findings if f.check_id == "ZZ9"]
        assert len(zz9) == 1
        assert zz9[0].severity == Severity.FAIL
        assert "did not complete" in zz9[0].message
        assert "RuntimeError" in zz9[0].message

    def test_other_checks_still_run_when_one_crashes(self, monkeypatch):
        # Insert the crashing check FIRST so real checks run AFTER it — proves
        # isolation lets the iteration continue past a mid-loop failure.
        patched = {"ZZ9": CheckEntry(_boom, [".sql"], "Z"), **code_reviewer.CHECK_REGISTRY}
        monkeypatch.setattr(code_reviewer, "CHECK_REGISTRY", patched)

        findings = review_file(
            file_path=_SQL_FILE,
            sql_content="select 1\n",
            file_status=FileStatus.NEW,
        )

        # The isolated failure is present...
        assert any(f.check_id == "ZZ9" for f in findings)
        # ...and real checks (which run after ZZ9) still produced findings,
        # proving the run was not aborted by the crash.
        assert any(f.check_id != "ZZ9" for f in findings)

    def test_keyboardinterrupt_propagates(self, monkeypatch):
        # BaseException (KeyboardInterrupt/SystemExit) must NOT be swallowed.
        def _interrupt(**kwargs):
            raise KeyboardInterrupt

        patched = dict(code_reviewer.CHECK_REGISTRY)
        patched["ZZ9"] = CheckEntry(_interrupt, [".sql"], "Z")
        monkeypatch.setattr(code_reviewer, "CHECK_REGISTRY", patched)

        with pytest.raises(KeyboardInterrupt):
            review_file(
                file_path=_SQL_FILE,
                sql_content="select 1\n",
                file_status=FileStatus.NEW,
                check_filter="ZZ9",
            )

    def test_isolated_finding_names_the_failing_check(self, monkeypatch):
        patched = dict(code_reviewer.CHECK_REGISTRY)
        patched["ZZ9"] = CheckEntry(_boom, [".sql"], "Z")
        monkeypatch.setattr(code_reviewer, "CHECK_REGISTRY", patched)

        findings = review_file(
            file_path=_SQL_FILE,
            sql_content="select 1\n",
            file_status=FileStatus.NEW,
            check_filter="ZZ9",
        )

        zz9 = next(f for f in findings if f.check_id == "ZZ9")
        assert "_boom" in zz9.check_name
        assert "internal error" in zz9.check_name
        assert zz9.file_path == _SQL_FILE
