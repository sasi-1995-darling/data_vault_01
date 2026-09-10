#!/usr/bin/env python3
"""Tests for fix+proof atomicity prompt in code_reviewer.py (M5)."""

import sys
from pathlib import Path

# Path setup
SCRIPT_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = SCRIPT_DIR / "src"
sys.path.insert(0, str(SRC_DIR))

from code_review_config import FileStatus
from code_reviewer import _is_reviewable_changed_file, review_file


class TestFixProofAtomicityPrompt:
    """M5 should warn on triage source edits with confirm-style phrasing."""

    def test_warns_for_triage_source_python_file(self):
        findings = review_file(
            file_path="scripts/automation/src/triage/redactor_pipeline.py",
            sql_content="def x():\n    return 1\n",
            file_status=FileStatus.MODIFIED,
        )

        m5 = [f for f in findings if f.check_id == "M5"]
        assert len(m5) == 1
        assert m5[0].severity.value == "WARN"
        assert "Confirm fix+proof atomicity" in m5[0].message
        assert "violation" not in m5[0].message.lower()

    def test_does_not_warn_for_non_triage_python_file(self):
        findings = review_file(
            file_path="scripts/automation/src/code_reviewer.py",
            sql_content="def y():\n    return 2\n",
            file_status=FileStatus.MODIFIED,
        )

        m5 = [f for f in findings if f.check_id == "M5"]
        assert m5 == []

    def test_triage_python_emits_only_m5(self):
        findings = review_file(
            file_path="scripts/automation/src/triage/redact.py",
            sql_content="def redact():\n    return {}\n",
            file_status=FileStatus.MODIFIED,
        )

        check_ids = {f.check_id for f in findings}
        assert check_ids == {"M5"}


class TestDefaultScopeSelection:
    """Default changed-file selection should include triage source .py files."""

    def test_reviewable_scope_includes_triage_source_py(self):
        assert _is_reviewable_changed_file(
            "scripts/automation/src/triage/redact.py"
        )

    def test_reviewable_scope_includes_model_sql(self):
        assert _is_reviewable_changed_file(
            "models/int_staging_views/supplier/v_psa_stg_supplier__sap.sql"
        )

    def test_reviewable_scope_excludes_non_triage_python(self):
        assert not _is_reviewable_changed_file(
            "scripts/automation/src/pipeline_orchestrator.py"
        )
