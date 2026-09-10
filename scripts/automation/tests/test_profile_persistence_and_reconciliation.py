"""
test_profile_persistence_and_reconciliation.py — Tests for:
  1. Profile persistence: _persist_profile_markdown writes a profile.md evidence document
  2. Reconciliation check: _reconcile_columns verifies all profiled columns are accounted for

Feature: spec-anchored-enhancements
Inspiration: Nielsen's spec-anchored development article (May 2026)
"""

import json
import re
import sys
import tempfile
from argparse import Namespace
from pathlib import Path
from unittest.mock import patch, MagicMock

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pipeline_orchestrator import (
    _persist_profile_markdown,
    _reconcile_columns,
    _now_iso,
    _save_state,
    SCRIPT_DIR,
    PROJECT_ROOT,
    STATE_DIR,
    TECHNICAL_COLS,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_state(model_name="v_psa_stg_test_entity__winn_sap", **overrides):
    """Build a minimal valid state dict for testing."""
    state = {
        "model_name": model_name,
        "schema": "WINN_SAP",
        "table": "Z_TEST_TABLE",
        "bk": "TEST_ID",
        "bk_name": "TEST_BK",
        "rec_src": "USOHNO.SAP.ECCPRD.Z_TEST_TABLE",
        "objects": ["stg"],
        "created_at": _now_iso(),
        "steps_completed": [],
        "profile_results": {
            "row_count": 125000,
            "volume_tier": "normal",
            "column_count": 8,
            "ingestion_source": "snp_glue",
            "bkcc": "Hiding_Tiger",
            "grain_valid": True,
            "null_bk_count": 0,
            "has_psa_delete_ind": True,
            "has_fivetran_deleted": False,
            "collision_check": {"blocked": False, "layers": {}},
            "columns": [
                {"name": "TEST_ID", "type": "VARCHAR", "nullable": "NO"},
                {"name": "DESCRIPTION", "type": "VARCHAR", "nullable": "YES"},
                {"name": "AMOUNT", "type": "NUMBER", "nullable": "YES"},
                {"name": "STATUS_CODE", "type": "VARCHAR", "nullable": "YES"},
                {"name": "CREATED_DATE", "type": "DATE", "nullable": "YES"},
                {"name": "PSA_LOAD_DTS", "type": "TIMESTAMP_NTZ", "nullable": "NO"},
                {"name": "PSA_DELETE_IND", "type": "VARCHAR", "nullable": "YES"},
                {"name": "GLCHANGETIME", "type": "VARCHAR", "nullable": "NO"},
            ],
        },
    }
    state.update(overrides)
    return state


# ===========================================================================
# SECTION 1: Profile Persistence Tests
# ===========================================================================

class TestProfilePersistence:
    """Tests for _persist_profile_markdown function."""

    def test_creates_profile_md_file(self, tmp_path):
        """Profile markdown file is created in configs/<config_name>/."""
        state = _make_state()

        with patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path), \
             patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _persist_profile_markdown(state)

        assert result is not None
        assert result.exists()
        assert result.name == "profile.md"
        assert result.parent.name == "test_entity__winn_sap"

    def test_contains_model_name_header(self, tmp_path):
        """Profile.md starts with the model name as H1."""
        state = _make_state()

        with patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path), \
             patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _persist_profile_markdown(state)

        content = result.read_text()
        assert content.startswith("# Profile: v_psa_stg_test_entity__winn_sap")

    def test_contains_summary_table(self, tmp_path):
        """Profile.md contains the summary metrics table."""
        state = _make_state()

        with patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path), \
             patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _persist_profile_markdown(state)

        content = result.read_text()
        assert "| Rows | 125,000 |" in content
        assert "| Volume Tier | normal |" in content
        assert "| Columns | 8 |" in content
        assert "| Ingestion | snp_glue |" in content
        assert "| BKCC | Hiding_Tiger |" in content

    def test_contains_column_inventory(self, tmp_path):
        """Profile.md lists all source columns with roles."""
        state = _make_state()

        with patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path), \
             patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _persist_profile_markdown(state)

        content = result.read_text()
        assert "## Column Inventory" in content
        assert "| 1 | TEST_ID | VARCHAR | NO | BK |" in content
        assert "| 2 | DESCRIPTION | VARCHAR | YES | data |" in content
        assert "| 6 | PSA_LOAD_DTS | TIMESTAMP_NTZ | NO | technical |" in content

    def test_contains_business_key_info(self, tmp_path):
        """Profile.md includes BK and REC_SRC info."""
        state = _make_state()

        with patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path), \
             patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _persist_profile_markdown(state)

        content = result.read_text()
        assert "**Business Key:** TEST_ID → TEST_BK" in content
        assert "**REC_SRC:** USOHNO.SAP.ECCPRD.Z_TEST_TABLE" in content

    def test_contains_collision_check(self, tmp_path):
        """Profile.md includes collision check results."""
        state = _make_state()
        state["profile_results"]["collision_check"] = {
            "blocked": False,
            "layers": {
                "hub": {"status": "NEW", "file": "models/raw_vault/hub/hub_test.sql"},
                "sat": {"status": "NEW", "file": None},
            },
        }

        with patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path), \
             patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _persist_profile_markdown(state)

        content = result.read_text()
        assert "## Collision Check" in content
        assert "**Status:** clear" in content
        assert "**hub:** NEW" in content

    def test_records_null_bk_sentinel_decision(self, tmp_path):
        """Profile.md records NULL BK sentinel choice if made."""
        state = _make_state(null_bk_sentinel="-1")

        with patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path), \
             patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _persist_profile_markdown(state)

        content = result.read_text()
        assert "COALESCE(BK, '-1')" in content

    def test_records_composite_grain(self, tmp_path):
        """Profile.md records composite grain columns if set."""
        state = _make_state(grain_columns=["WERKS", "POPER"])

        with patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path), \
             patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _persist_profile_markdown(state)

        content = result.read_text()
        assert "WERKS, POPER" in content

    def test_records_hash_keys(self, tmp_path):
        """Profile.md records multi-HK definitions if present."""
        state = _make_state(hash_keys=[
            {"name": "TEST_HK", "columns": ["TEST_ID"]},
            {"name": "LNK_TEST_HK", "columns": ["TEST_ID", "OTHER_ID"]},
        ])

        with patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path), \
             patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _persist_profile_markdown(state)

        content = result.read_text()
        assert "TEST_HK = MD5(TEST_ID)" in content
        assert "LNK_TEST_HK = MD5(TEST_ID, OTHER_ID)" in content

    def test_stores_path_in_state(self, tmp_path):
        """profile_md_path is stored in state after persistence."""
        state = _make_state()

        with patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path), \
             patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            _persist_profile_markdown(state)

        assert "profile_md_path" in state

    def test_creates_directory_if_not_exists(self, tmp_path):
        """Config directory is created automatically."""
        state = _make_state(model_name="v_psa_stg_new_model__new_src")

        with patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path), \
             patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _persist_profile_markdown(state)

        assert result.parent.exists()
        assert result.parent.name == "new_model__new_src"

    def test_default_design_decisions(self, tmp_path):
        """Profile.md shows 'Standard defaults' when no overrides."""
        state = _make_state()

        with patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path), \
             patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _persist_profile_markdown(state)

        content = result.read_text()
        assert "Standard defaults (no overrides)" in content

    def test_path_traversal_blocked(self, tmp_path):
        """Path traversal in model_name is blocked (defense-in-depth)."""
        state = _make_state(model_name="v_psa_stg_../../etc/evil")

        with patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path), \
             patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _persist_profile_markdown(state)

        # Should return None (blocked)
        assert result is None


# ===========================================================================
# SECTION 2: Reconciliation Check Tests
# ===========================================================================

class TestReconciliationCheck:
    """Tests for _reconcile_columns function."""

    def test_all_columns_mapped_passes(self, tmp_path):
        """Reconciliation passes when all data columns appear in SQL."""
        state = _make_state()
        # Create a mock generated SQL that references all columns
        sql_content = """
        WITH SRC AS (
            SELECT TEST_ID, DESCRIPTION, AMOUNT, STATUS_CODE, CREATED_DATE,
                   PSA_LOAD_DTS, PSA_DELETE_IND, GLCHANGETIME
            FROM {{ source('psa', 'Z_TEST_TABLE') }}
        )
        SELECT * FROM SRC
        """
        sql_file = tmp_path / "v_psa_stg_test_entity__winn_sap.sql"
        sql_file.write_text(sql_content)

        state["generated_files"] = {"sql": str(sql_file.relative_to(tmp_path.parent))}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _reconcile_columns(state)

        assert result["passed"] is True
        assert len(result["unmapped"]) == 0

    def test_unmapped_column_fails(self, tmp_path):
        """Reconciliation fails when a data column is missing from SQL."""
        state = _make_state()
        # SQL deliberately missing STATUS_CODE and CREATED_DATE
        sql_content = """
        WITH SRC AS (
            SELECT TEST_ID, DESCRIPTION, AMOUNT,
                   PSA_LOAD_DTS, PSA_DELETE_IND, GLCHANGETIME
            FROM {{ source('psa', 'Z_TEST_TABLE') }}
        )
        SELECT * FROM SRC
        """
        sql_file = tmp_path / "v_psa_stg_test_entity__winn_sap.sql"
        sql_file.write_text(sql_content)

        state["generated_files"] = {"sql": str(sql_file.relative_to(tmp_path.parent))}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _reconcile_columns(state)

        assert result["passed"] is False
        assert "STATUS_CODE" in result["unmapped"]
        assert "CREATED_DATE" in result["unmapped"]

    def test_technical_cols_excluded_automatically(self, tmp_path):
        """Technical columns (PSA_LOAD_DTS, GLCHANGETIME, etc.) don't need to be in SQL."""
        state = _make_state()
        # SQL only has data columns, not technical ones
        sql_content = """
        WITH SRC AS (
            SELECT TEST_ID, DESCRIPTION, AMOUNT, STATUS_CODE, CREATED_DATE
            FROM {{ source('psa', 'Z_TEST_TABLE') }}
        )
        SELECT * FROM SRC
        """
        sql_file = tmp_path / "v_psa_stg_test_entity__winn_sap.sql"
        sql_file.write_text(sql_content)

        state["generated_files"] = {"sql": str(sql_file.relative_to(tmp_path.parent))}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _reconcile_columns(state)

        assert result["passed"] is True
        assert "PSA_LOAD_DTS" in result["excluded_technical"]
        assert "GLCHANGETIME" in result["excluded_technical"]
        assert "PSA_DELETE_IND" in result["excluded_technical"]

    def test_bk_column_always_mapped(self, tmp_path):
        """BK column is always considered mapped (becomes BK alias)."""
        state = _make_state()
        # SQL doesn't literally contain TEST_ID but that's fine — BK is aliased
        sql_content = """
        WITH SRC AS (
            SELECT DESCRIPTION, AMOUNT, STATUS_CODE, CREATED_DATE
            FROM {{ source('psa', 'Z_TEST_TABLE') }}
        )
        SELECT TEST_BK FROM SRC
        """
        sql_file = tmp_path / "v_psa_stg_test_entity__winn_sap.sql"
        sql_file.write_text(sql_content)

        state["generated_files"] = {"sql": str(sql_file.relative_to(tmp_path.parent))}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _reconcile_columns(state)

        assert "TEST_ID" in result["mapped"]

    def test_grain_columns_in_sql_mapped(self, tmp_path):
        """Grain columns that appear in SQL are counted as mapped."""
        state = _make_state(grain_columns=["STATUS_CODE"])
        sql_content = """
        WITH SRC AS (
            SELECT TEST_ID, DESCRIPTION, AMOUNT, STATUS_CODE, CREATED_DATE
            FROM {{ source('psa', 'Z_TEST_TABLE') }}
        )
        SELECT * FROM SRC
        """
        sql_file = tmp_path / "v_psa_stg_test_entity__winn_sap.sql"
        sql_file.write_text(sql_content)

        state["generated_files"] = {"sql": str(sql_file.relative_to(tmp_path.parent))}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _reconcile_columns(state)

        assert result["passed"] is True
        assert "STATUS_CODE" in result["mapped"]

    def test_grain_columns_not_in_sql_excluded(self, tmp_path):
        """Grain columns NOT in SQL are recorded as HASHDIFF-excluded (not unmapped)."""
        state = _make_state(grain_columns=["STATUS_CODE"])
        # SQL deliberately doesn't contain STATUS_CODE
        sql_content = """
        WITH SRC AS (
            SELECT TEST_ID, DESCRIPTION, AMOUNT, CREATED_DATE
            FROM {{ source('psa', 'Z_TEST_TABLE') }}
        )
        SELECT * FROM SRC
        """
        sql_file = tmp_path / "v_psa_stg_test_entity__winn_sap.sql"
        sql_file.write_text(sql_content)

        state["generated_files"] = {"sql": str(sql_file.relative_to(tmp_path.parent))}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _reconcile_columns(state)

        # STATUS_CODE is grain → excluded from HASHDIFF, not unmapped
        assert "STATUS_CODE" in result["excluded_hashdiff"]
        assert "STATUS_CODE" not in result["unmapped"]

    def test_no_profile_columns_passes(self, tmp_path):
        """Reconciliation passes gracefully when profile has no columns."""
        state = _make_state()
        state["profile_results"]["columns"] = []

        result = _reconcile_columns(state)

        assert result["passed"] is True
        assert result.get("reason") == "no profile columns"

    def test_no_generated_sql_passes(self, tmp_path):
        """Reconciliation passes gracefully when no SQL has been generated."""
        state = _make_state()
        state["generated_files"] = {}

        result = _reconcile_columns(state)

        assert result["passed"] is True
        assert result.get("reason") == "no generated SQL"

    def test_relative_path_traversal_blocked(self, tmp_path):
        """Tampered state with '../' in sql path must NOT read outside PROJECT_ROOT."""
        state = _make_state()
        # Plant a sentinel file OUTSIDE the project root containing one of the
        # profiled column names. If the guard fails, _col_in_sql would find it
        # and silently mark the column as mapped, masking the breach.
        evil_dir = tmp_path.parent / "evil_outside_root"
        evil_dir.mkdir(exist_ok=True)
        evil_file = evil_dir / "secret.sql"
        evil_file.write_text("SELECT TEST_ID, DESCRIPTION, AMOUNT, STATUS_CODE, CREATED_DATE")

        # generated_files.sql escapes PROJECT_ROOT (tmp_path.parent) via '../'
        state["generated_files"] = {"sql": "../evil_outside_root/secret.sql"}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _reconcile_columns(state)

        # Guard should refuse to read the file at all
        assert result["passed"] is True
        assert result.get("reason") == "SQL path outside project root"
        assert result["mapped"] == []

    def test_absolute_path_outside_root_blocked(self, tmp_path):
        """Tampered state with an absolute path outside PROJECT_ROOT must be rejected."""
        state = _make_state()
        # tmp_path.parent.parent is one level ABOVE PROJECT_ROOT (which we patch
        # to tmp_path.parent); using tmp_path.parent itself would be inside root.
        evil_dir = tmp_path.parent.parent / "evil_abs_outside"
        evil_dir.mkdir(exist_ok=True)
        evil_file = evil_dir / "leak.sql"
        evil_file.write_text("SELECT TEST_ID, DESCRIPTION, AMOUNT, STATUS_CODE, CREATED_DATE")

        state["generated_files"] = {"sql": str(evil_file)}

        try:
            with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
                result = _reconcile_columns(state)

            assert result["passed"] is True
            assert result.get("reason") == "SQL path outside project root"
            assert result["mapped"] == []
        finally:
            evil_file.unlink(missing_ok=True)
            try:
                evil_dir.rmdir()
            except OSError:
                pass

    def test_composite_bk_all_parts_mapped(self, tmp_path):
        """Composite BK (multiple columns) — all parts counted as mapped."""
        state = _make_state()
        state["bk"] = "MATNR, WERKS"
        state["profile_results"]["columns"] = [
            {"name": "MATNR", "type": "VARCHAR", "nullable": "NO"},
            {"name": "WERKS", "type": "VARCHAR", "nullable": "NO"},
            {"name": "DESCRIPTION", "type": "VARCHAR", "nullable": "YES"},
            {"name": "PSA_LOAD_DTS", "type": "TIMESTAMP_NTZ", "nullable": "NO"},
        ]

        sql_content = "SELECT MATNR, WERKS, DESCRIPTION FROM SRC"
        sql_file = tmp_path / "v_psa_stg_test_entity__winn_sap.sql"
        sql_file.write_text(sql_content)
        state["generated_files"] = {"sql": str(sql_file.relative_to(tmp_path.parent))}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _reconcile_columns(state)

        assert result["passed"] is True
        assert "MATNR" in result["mapped"]
        assert "WERKS" in result["mapped"]

    def test_fivetran_columns_excluded(self, tmp_path):
        """Fivetran technical columns are automatically excluded."""
        state = _make_state()
        state["profile_results"]["columns"] = [
            {"name": "TEST_ID", "type": "VARCHAR", "nullable": "NO"},
            {"name": "DESCRIPTION", "type": "VARCHAR", "nullable": "YES"},
            {"name": "_FIVETRAN_SYNCED", "type": "TIMESTAMP_NTZ", "nullable": "NO"},
            {"name": "_FIVETRAN_ID", "type": "VARCHAR", "nullable": "NO"},
            {"name": "_FIVETRAN_DELETED", "type": "BOOLEAN", "nullable": "YES"},
        ]
        state["profile_results"]["ingestion_source"] = "fivetran"

        sql_content = "SELECT TEST_ID, DESCRIPTION FROM SRC"
        sql_file = tmp_path / "v_psa_stg_test_entity__winn_sap.sql"
        sql_file.write_text(sql_content)
        state["generated_files"] = {"sql": str(sql_file.relative_to(tmp_path.parent))}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _reconcile_columns(state)

        assert result["passed"] is True
        assert "_FIVETRAN_SYNCED" in result["excluded_technical"]
        assert "_FIVETRAN_ID" in result["excluded_technical"]
        assert "_FIVETRAN_DELETED" in result["excluded_technical"]

    def test_case_insensitive_matching(self, tmp_path):
        """Column matching is case-insensitive (SQL is uppercased for comparison)."""
        state = _make_state()
        state["profile_results"]["columns"] = [
            {"name": "Test_Id", "type": "VARCHAR", "nullable": "NO"},
            {"name": "description", "type": "VARCHAR", "nullable": "YES"},
            {"name": "PSA_LOAD_DTS", "type": "TIMESTAMP_NTZ", "nullable": "NO"},
        ]

        # SQL uses mixed case
        sql_content = "SELECT test_id, DESCRIPTION FROM src"
        sql_file = tmp_path / "v_psa_stg_test_entity__winn_sap.sql"
        sql_file.write_text(sql_content)
        state["generated_files"] = {"sql": str(sql_file.relative_to(tmp_path.parent))}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _reconcile_columns(state)

        assert result["passed"] is True

    def test_word_boundary_prevents_substring_false_positive(self, tmp_path):
        """Column 'ID' should NOT match 'PROVIDER_ID' — requires word boundary."""
        state = _make_state()
        state["profile_results"]["columns"] = [
            {"name": "TEST_ID", "type": "VARCHAR", "nullable": "NO"},
            {"name": "ID", "type": "NUMBER", "nullable": "NO"},
            {"name": "PSA_LOAD_DTS", "type": "TIMESTAMP_NTZ", "nullable": "NO"},
        ]

        # SQL has PROVIDER_ID and TEST_ID, but NOT standalone ID
        sql_content = "SELECT TEST_ID, PROVIDER_ID, DESCRIPTION FROM SRC"
        sql_file = tmp_path / "v_psa_stg_test_entity__winn_sap.sql"
        sql_file.write_text(sql_content)
        state["generated_files"] = {"sql": str(sql_file.relative_to(tmp_path.parent))}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _reconcile_columns(state)

        # ID should be unmapped (not falsely matched via substring)
        assert "ID" in result["unmapped"]
        assert result["passed"] is False

    def test_custom_load_dts_column_excluded(self, tmp_path):
        """Custom LOAD_DTS source column is treated as technical (consumed by derivation)."""
        state = _make_state(load_dts_column="MY_TIMESTAMP")
        state["profile_results"]["columns"] = [
            {"name": "TEST_ID", "type": "VARCHAR", "nullable": "NO"},
            {"name": "DESCRIPTION", "type": "VARCHAR", "nullable": "YES"},
            {"name": "MY_TIMESTAMP", "type": "TIMESTAMP_NTZ", "nullable": "NO"},
            {"name": "PSA_LOAD_DTS", "type": "TIMESTAMP_NTZ", "nullable": "NO"},
        ]

        sql_content = "SELECT TEST_ID, DESCRIPTION FROM SRC"
        sql_file = tmp_path / "v_psa_stg_test_entity__winn_sap.sql"
        sql_file.write_text(sql_content)
        state["generated_files"] = {"sql": str(sql_file.relative_to(tmp_path.parent))}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _reconcile_columns(state)

        assert result["passed"] is True
        # MY_TIMESTAMP is consumed by LOAD_DTS derivation → excluded as technical
        assert "MY_TIMESTAMP" in result["excluded_technical"]
        assert "PSA_LOAD_DTS" in result["excluded_technical"]


# ===========================================================================
# SECTION 2b: Reconciliation — Secondary (Lookup) Table Columns
# ===========================================================================

class TestReconciliationSecondary:
    """Tests for secondary/lookup table column reconciliation."""

    def test_secondary_columns_mapped_when_present_in_sql(self, tmp_path):
        """Secondary columns found in SQL are reported as secondary_mapped."""
        state = _make_state()
        state["secondary"] = {
            "schema": "winn_sap",
            "table": "Z_VENDOR",
            "alias": "VND",
            "join_type": "LEFT JOIN",
            "join_on": "VENDOR_ID = VND.ID",
            "bk": None,
            "bk_name": None,
            "columns": ["VENDOR_NAME", "VENDOR_STATUS"],
        }
        sql_content = """
        WITH SRC AS (
            SELECT TEST_ID, DESCRIPTION, AMOUNT, STATUS_CODE, CREATED_DATE,
                   VENDOR_NAME, VENDOR_STATUS
            FROM {{ source('psa', 'Z_TEST_TABLE') }}
        )
        SELECT * FROM SRC
        """
        sql_file = tmp_path / "v_psa_stg_test_entity__winn_sap.sql"
        sql_file.write_text(sql_content)
        state["generated_files"] = {"sql": str(sql_file.relative_to(tmp_path.parent))}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _reconcile_columns(state)

        assert result["passed"] is True
        assert "VENDOR_NAME" in result["secondary_mapped"]
        assert "VENDOR_STATUS" in result["secondary_mapped"]
        assert len(result["secondary_unmapped"]) == 0

    def test_secondary_columns_unmapped_fails(self, tmp_path):
        """Secondary columns missing from SQL cause reconciliation failure."""
        state = _make_state()
        state["secondary"] = {
            "schema": "winn_sap",
            "table": "Z_VENDOR",
            "alias": "VND",
            "join_type": "LEFT JOIN",
            "join_on": "VENDOR_ID = VND.ID",
            "bk": None,
            "bk_name": None,
            "columns": ["VENDOR_NAME", "VENDOR_STATUS"],
        }
        # SQL has VENDOR_NAME but NOT VENDOR_STATUS
        sql_content = """
        WITH SRC AS (
            SELECT TEST_ID, DESCRIPTION, AMOUNT, STATUS_CODE, CREATED_DATE,
                   VENDOR_NAME
            FROM {{ source('psa', 'Z_TEST_TABLE') }}
        )
        SELECT * FROM SRC
        """
        sql_file = tmp_path / "v_psa_stg_test_entity__winn_sap.sql"
        sql_file.write_text(sql_content)
        state["generated_files"] = {"sql": str(sql_file.relative_to(tmp_path.parent))}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _reconcile_columns(state)

        assert result["passed"] is False
        assert "VENDOR_STATUS" in result["secondary_unmapped"]
        assert "VENDOR_NAME" in result["secondary_mapped"]

    def test_secondary_columns_with_alias_prefix(self, tmp_path):
        """Secondary columns prefixed with alias (e.g., VND_NAME) are detected."""
        state = _make_state()
        state["secondary"] = {
            "schema": "winn_sap",
            "table": "Z_VENDOR",
            "alias": "VND",
            "join_type": "LEFT JOIN",
            "join_on": "VENDOR_ID = VND.ID",
            "bk": None,
            "bk_name": None,
            "columns": ["NAME", "STATUS"],
        }
        # SQL uses alias-prefixed columns (common rename pattern)
        sql_content = """
        WITH SRC AS (
            SELECT TEST_ID, DESCRIPTION, AMOUNT, STATUS_CODE, CREATED_DATE,
                   VND_NAME, VND_STATUS
            FROM {{ source('psa', 'Z_TEST_TABLE') }}
        )
        SELECT * FROM SRC
        """
        sql_file = tmp_path / "v_psa_stg_test_entity__winn_sap.sql"
        sql_file.write_text(sql_content)
        state["generated_files"] = {"sql": str(sql_file.relative_to(tmp_path.parent))}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _reconcile_columns(state)

        assert result["passed"] is True
        assert "VND_NAME" in result["secondary_mapped"]
        assert "VND_STATUS" in result["secondary_mapped"]

    def test_no_secondary_table_empty_results(self, tmp_path):
        """Without secondary table, secondary_mapped/unmapped are empty."""
        state = _make_state()
        sql_content = """
        WITH SRC AS (
            SELECT TEST_ID, DESCRIPTION, AMOUNT, STATUS_CODE, CREATED_DATE
            FROM {{ source('psa', 'Z_TEST_TABLE') }}
        )
        SELECT * FROM SRC
        """
        sql_file = tmp_path / "v_psa_stg_test_entity__winn_sap.sql"
        sql_file.write_text(sql_content)
        state["generated_files"] = {"sql": str(sql_file.relative_to(tmp_path.parent))}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _reconcile_columns(state)

        assert result["passed"] is True
        assert result["secondary_mapped"] == []
        assert result["secondary_unmapped"] == []

    def test_secondary_with_null_columns_skipped(self, tmp_path):
        """Secondary table with columns=None (not yet specified) is skipped gracefully."""
        state = _make_state()
        state["secondary"] = {
            "schema": "winn_sap",
            "table": "Z_VENDOR",
            "alias": "VND",
            "join_type": "LEFT JOIN",
            "join_on": "VENDOR_ID = VND.ID",
            "bk": None,
            "bk_name": None,
            "columns": None,
        }
        sql_content = "SELECT TEST_ID, DESCRIPTION, AMOUNT, STATUS_CODE, CREATED_DATE FROM SRC"
        sql_file = tmp_path / "v_psa_stg_test_entity__winn_sap.sql"
        sql_file.write_text(sql_content)
        state["generated_files"] = {"sql": str(sql_file.relative_to(tmp_path.parent))}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _reconcile_columns(state)

        assert result["passed"] is True
        assert result["secondary_mapped"] == []
        assert result["secondary_unmapped"] == []

    def test_driver_passes_but_secondary_fails(self, tmp_path):
        """Overall reconciliation fails if driver is fine but secondary has unmapped."""
        state = _make_state()
        state["secondary"] = {
            "schema": "winn_sap",
            "table": "Z_VENDOR",
            "alias": "VND",
            "join_type": "LEFT JOIN",
            "join_on": "VENDOR_ID = VND.ID",
            "bk": None,
            "bk_name": None,
            "columns": ["GHOST_COLUMN"],
        }
        # All driver columns present, but GHOST_COLUMN is nowhere
        sql_content = """
        WITH SRC AS (
            SELECT TEST_ID, DESCRIPTION, AMOUNT, STATUS_CODE, CREATED_DATE
            FROM {{ source('psa', 'Z_TEST_TABLE') }}
        )
        SELECT * FROM SRC
        """
        sql_file = tmp_path / "v_psa_stg_test_entity__winn_sap.sql"
        sql_file.write_text(sql_content)
        state["generated_files"] = {"sql": str(sql_file.relative_to(tmp_path.parent))}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = _reconcile_columns(state)

        assert result["passed"] is False
        assert "GHOST_COLUMN" in result["secondary_unmapped"]
        # Driver columns should still be fine
        assert len(result["unmapped"]) == 0


# ===========================================================================
# SECTION 3: Integration — approve-profile hooks profile persistence
# ===========================================================================

class TestApproveProfileIntegration:
    """Test that approve-profile actually calls _persist_profile_markdown."""

    def test_approve_profile_calls_persistence(self, tmp_path):
        """approve-profile calls _persist_profile_markdown on success."""
        from pipeline_orchestrator import cmd_approve_profile

        state = _make_state()
        state["steps_completed"] = [
            {"step": "init", "completed_at": _now_iso()},
            {"step": "profile", "completed_at": _now_iso()},
        ]

        args = Namespace(
            model_name=state["model_name"],
            force=True,
            null_bk_sentinel=None,
        )

        fake_profile_path = tmp_path / "configs" / "test" / "profile.md"
        fake_profile_path.parent.mkdir(parents=True)
        fake_profile_path.touch()

        with patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._check_prerequisites", return_value=(True, [])), \
             patch("pipeline_orchestrator._mark_complete") as mock_mark, \
             patch("pipeline_orchestrator._persist_profile_markdown", return_value=fake_profile_path) as mock_persist, \
             patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._print_success"), \
             patch("pipeline_orchestrator._print_next_step"):
            result = cmd_approve_profile(args)

        assert result == 0
        mock_persist.assert_called_once_with(state)

    def test_approve_profile_persists_profile_md_path_to_state_file(self, tmp_path):
        """Regression for PR #1771 review: ``state['profile_md_path']`` mutated
        by ``_persist_profile_markdown`` MUST be saved to disk; otherwise
        downstream handoffs/resumptions cannot locate the evidence document.

        This is a state-ordering bug: ``_mark_complete`` saved state BEFORE
        ``_persist_profile_markdown`` mutated it, so the path was lost on
        every run. The fix re-saves state after persistence succeeds.
        """
        from pipeline_orchestrator import cmd_approve_profile

        state = _make_state()
        state["steps_completed"] = [
            {"step": "init", "completed_at": _now_iso()},
            {"step": "profile", "completed_at": _now_iso()},
        ]
        args = Namespace(
            model_name=state["model_name"],
            force=True,
            null_bk_sentinel=None,
        )

        fake_profile_path = tmp_path / "configs" / "test" / "profile.md"
        fake_profile_path.parent.mkdir(parents=True)
        fake_profile_path.touch()

        def _fake_persist(s):
            # Simulate the real function's contract: mutate state AFTER
            # _mark_complete has already saved.
            s["profile_md_path"] = "scripts/automation/configs/test/profile.md"
            return fake_profile_path

        save_calls = []

        def _fake_save(s):
            # Snapshot what's persisted at each call so we can prove the
            # post-persistence save happened.
            save_calls.append(dict(s))

        with patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._check_prerequisites", return_value=(True, [])), \
             patch("pipeline_orchestrator._save_state", side_effect=_fake_save), \
             patch("pipeline_orchestrator._persist_profile_markdown", side_effect=_fake_persist), \
             patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._print_success"), \
             patch("pipeline_orchestrator._print_next_step"):
            result = cmd_approve_profile(args)

        assert result == 0
        # Two saves expected: one inside _mark_complete, one after persistence.
        assert len(save_calls) >= 2, (
            f"Expected ≥2 _save_state calls (one inside _mark_complete, one "
            f"after _persist_profile_markdown); got {len(save_calls)}"
        )
        # The FINAL persisted snapshot must include profile_md_path.
        assert save_calls[-1].get("profile_md_path") == \
            "scripts/automation/configs/test/profile.md", (
            "profile_md_path missing from final saved state — handoff will "
            "fall back to canonical layout and may miss custom locations"
        )

    def test_approve_profile_saves_state_even_when_relative_path_fails(self, tmp_path):
        """Regression for PR #1771 Copilot round-3: when ``profile_path`` cannot be
        expressed relative to ``PROJECT_ROOT`` (e.g. symlinks), ``relative_to`` raises
        ``ValueError``. Earlier code wrapped both the print and the ``_save_state`` call
        in the same try, so ValueError would skip persistence and re-introduce the
        ordering bug. The fix saves state BEFORE attempting the relative-path display.
        """
        from pipeline_orchestrator import cmd_approve_profile

        state = _make_state()
        state["steps_completed"] = [
            {"step": "init", "completed_at": _now_iso()},
            {"step": "profile", "completed_at": _now_iso()},
        ]
        args = Namespace(
            model_name=state["model_name"],
            force=True,
            null_bk_sentinel=None,
        )

        # profile_path is OUTSIDE tmp_path → relative_to(tmp_path) will raise ValueError
        outside_path = tmp_path.parent / "outside_root" / "profile.md"
        outside_path.parent.mkdir(parents=True, exist_ok=True)
        outside_path.touch()

        def _fake_persist(s):
            s["profile_md_path"] = str(outside_path)
            return outside_path

        save_calls = []

        def _fake_save(s):
            save_calls.append(dict(s))

        with patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._check_prerequisites", return_value=(True, [])), \
             patch("pipeline_orchestrator._save_state", side_effect=_fake_save), \
             patch("pipeline_orchestrator._persist_profile_markdown", side_effect=_fake_persist), \
             patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._print_success"), \
             patch("pipeline_orchestrator._print_next_step"):
            result = cmd_approve_profile(args)

        assert result == 0
        # _save_state MUST still have been called after persistence even though
        # the display path could not be made relative.
        assert len(save_calls) >= 2, (
            f"Expected ≥2 _save_state calls; got {len(save_calls)}. "
            "ValueError on relative_to() must not skip state persistence."
        )
        assert save_calls[-1].get("profile_md_path") == str(outside_path)


# ===========================================================================
# SECTION 4: Integration — generate-code hooks reconciliation
# ===========================================================================

class TestGenerateCodeReconciliation:
    """Test that generate-code calls _reconcile_columns."""

    def test_reconcile_columns_called_after_generation(self, tmp_path):
        """generate-code calls _reconcile_columns and stores results in state."""
        from pipeline_orchestrator import cmd_generate_code

        state = _make_state()
        state["steps_completed"] = [
            {"step": "init", "completed_at": _now_iso()},
            {"step": "profile", "completed_at": _now_iso()},
            {"step": "approve-profile", "completed_at": _now_iso()},
            {"step": "generate-yaml", "completed_at": _now_iso()},
            {"step": "generate-xlsx", "completed_at": _now_iso()},
            {"step": "approve-xlsx", "completed_at": _now_iso()},
        ]
        state["design_decision"] = "stg_only"

        # Create a real XLSX file that exists
        xlsx_dir = tmp_path / "scripts" / "automation" / "mappings"
        xlsx_dir.mkdir(parents=True)
        xlsx_file = xlsx_dir / "dummy.xlsx"
        xlsx_file.touch()
        state["xlsx_path"] = str(xlsx_file.relative_to(tmp_path))

        # Create generated SQL output directory + file
        out_dir = tmp_path / "scripts" / "automation" / "models" / "int_staging_views"
        out_dir.mkdir(parents=True)
        sql_file = out_dir / "v_psa_stg_test_entity__winn_sap.sql"
        sql_file.write_text("SELECT TEST_ID, DESCRIPTION, AMOUNT FROM SRC")

        args = Namespace(model_name=state["model_name"], stg_only=True)

        reconcile_result = {
            "passed": True,
            "mapped": ["TEST_ID", "DESCRIPTION", "AMOUNT"],
            "excluded_technical": ["PSA_LOAD_DTS"],
            "excluded_hashdiff": [],
            "unmapped": [],
        }

        with patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._check_prerequisites", return_value=(True, [])), \
             patch("pipeline_orchestrator._run_command", return_value=(0, "Generated 1 model", "")), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._print_success"), \
             patch("pipeline_orchestrator._print_next_step"), \
             patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path / "scripts" / "automation"), \
             patch("pipeline_orchestrator._reconcile_columns", return_value=reconcile_result) as mock_reconcile:
            result = cmd_generate_code(args)

        assert result == 0
        mock_reconcile.assert_called_once_with(state)
        assert state["reconciliation"] == reconcile_result
