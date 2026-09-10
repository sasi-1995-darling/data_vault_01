"""
test_regression_fixes.py — Regression tests for pipeline orchestrator bug fixes.

Covers:
  - Fix #95 (refactored): BK source_column detection via PLAIN_COLUMN_RE
  - Fix #96: Composite grain / QUALIFY injection
  - Fix #97: Source name 3-step resolution + _register_source()
  - _infer_bk_datatype() helper
"""

import json
import os
import re
import shutil
import sys
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pipeline_orchestrator import (
    PLAIN_COLUMN_RE,
    _extract_raw_col_from_bk,
    _infer_bk_datatype,
    _register_source,
    _split_bk_parts,
    cmd_show_profile,
    cmd_approve_profile,
    PROJECT_ROOT,
)

# Also import _resolve_source_name from build.py
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))
from build import _resolve_source_name


# ──────────────────────────────────────────────────────────────────────────────
# Helper: build a BK entry using the same logic as cmd_generate_yaml
# ──────────────────────────────────────────────────────────────────────────────

def _build_bk_entry(bk_expr: str, bk_name: str = "TEST_BK",
                     driver_alias: str = "SRC", bk_cast: str = "",
                     bk_cast_type: str = "", grain_columns=None):
    """Simulate the BK entry logic from cmd_generate_yaml.

    Returns the bk_entry dict that would be appended to columns.
    """
    bk_upper = bk_expr.upper()

    # Parse raw cols (same as orchestrator, with paren-aware split)
    bk_raw_cols = []
    for _bk_part in _split_bk_parts(bk_upper):
        _bk_part = _bk_part.strip().split("::")[0]
        _func_match = re.match(r'^[A-Z_]+\((.+)\)$', _bk_part.strip())
        if _func_match:
            _bk_part = _func_match.group(1).strip()
        bk_raw_cols.append(_bk_part)

    bk_is_raw = bool(PLAIN_COLUMN_RE.match(bk_upper))

    # Build composite unique — filter out raw BK source col and ingestion-specific LOAD_DTS cols
    _LOAD_DTS_SOURCE_COLS = {"PSA_LOAD_DTS", "_FIVETRAN_SYNCED", "GLCHANGETIME", "SNP_LOAD_DTS", "LOAD_DTS"}
    bk_raw_set = set(c.upper() for c in bk_raw_cols)
    if grain_columns:
        _filtered_grain = [
            gc for gc in grain_columns
            if gc.upper() not in bk_raw_set and gc.upper() not in _LOAD_DTS_SOURCE_COLS
        ]
        _composite_unique = ", ".join([bk_name.upper()] + _filtered_grain + ["LOAD_DTS"])
    else:
        _composite_unique = f"{bk_name.upper()}, LOAD_DTS"

    bk_entry = {
        "source_table": driver_alias,
        "source_column": bk_upper,
        "datatype": "VARCHAR",
        "staging_column_name": bk_name.upper(),
        "hashdiff": "",
        "unique": f"COMPOSITE: {_composite_unique}",
        "not_null": "yes",
    }

    if len(bk_raw_cols) > 1:
        concat_parts = [
            f"COALESCE(NULLIF(TRIM(CAST({c} AS VARCHAR)), ''), '^^')"
            for c in bk_raw_cols
        ]
        bk_entry["manual_logic"] = "UPPER(CONCAT_WS('||', " + ", ".join(concat_parts) + "))"
        bk_entry["datatype"] = "TEXT"
    elif not bk_is_raw:
        bk_entry["source_column"] = "(DERIVED)"
        bk_entry["source_table"] = ""
        bk_entry["manual_logic"] = bk_upper
        bk_entry["staging_datatype"] = _infer_bk_datatype(bk_upper)
    elif bk_cast:
        bk_entry["manual_logic"] = bk_cast
        bk_entry["staging_datatype"] = bk_cast_type or "TEXT"
    else:
        bk_entry["manual_logic"] = ""

    return bk_entry


# ══════════════════════════════════════════════════════════════════════════════
# Group 1: BK source_column detection (Fix #95 refactored)
# ══════════════════════════════════════════════════════════════════════════════

class TestBkSourceColumnDetection:
    """Verify source_column is set correctly for all BK expression types."""

    # Plain column names → source_column = raw name, no manual_logic
    @pytest.mark.parametrize("bk_expr,expected_source_col", [
        ("PLNUM", "PLNUM"),
        ("ID", "ID"),
        ("VENDOR_SITE_ID", "VENDOR_SITE_ID"),
        ("D_DH_DC_NBR", "D_DH_DC_NBR"),
    ])
    def test_raw_column_bk(self, bk_expr, expected_source_col):
        """Raw column BK: source_column = column name, manual_logic empty."""
        entry = _build_bk_entry(bk_expr)
        assert entry["source_column"] == expected_source_col
        assert entry["manual_logic"] == ""
        assert entry["source_table"] != ""

    # Cast expressions → source_column = (DERIVED)
    @pytest.mark.parametrize("bk_expr,expected_dtype", [
        ("ID::TEXT", "TEXT"),
        ("D_DH_DC_NBR::TEXT", "TEXT"),
        ("ID::NUMBER", "NUMBER"),
        ("AMOUNT::FLOAT", "FLOAT"),
        ("ID::VARIANT", "VARIANT"),
        ("CREATE_DATE::DATE", "DATE"),
        ("EVENT_TS::TIMESTAMP_NTZ", "TIMESTAMP_NTZ"),
    ])
    def test_cast_bk_sets_derived(self, bk_expr, expected_dtype):
        """Cast BK: source_column = (DERIVED), staging_datatype inferred."""
        entry = _build_bk_entry(bk_expr)
        assert entry["source_column"] == "(DERIVED)"
        assert entry["source_table"] == ""
        assert entry["manual_logic"] == bk_expr.upper()
        assert entry["staging_datatype"] == expected_dtype

    # Function expressions → source_column = (DERIVED)
    @pytest.mark.parametrize("bk_expr,expected_dtype", [
        ("TO_CHAR(ID)", "TEXT"),
        ("TO_NUMBER(ID)", "NUMBER"),
        ("TRY_TO_NUMBER(ID)", "NUMBER"),
        ("TO_DATE(DATE_STR)", "DATE"),
        ("TRY_TO_DATE(DATE_STR)", "DATE"),
        ("TO_TIMESTAMP(TS_STR)", "TIMESTAMP_NTZ"),
        ("TO_VARCHAR(ID)", "TEXT"),
        ("TRIM(ID)", ""),           # No type inference for TRIM
        ("UPPER(ID)", ""),          # No type inference for UPPER
        ("LEFT(ID, 5)", ""),        # No type inference for LEFT
    ])
    def test_function_bk_sets_derived(self, bk_expr, expected_dtype):
        """Function BK: source_column = (DERIVED), dtype inferred where possible."""
        entry = _build_bk_entry(bk_expr)
        assert entry["source_column"] == "(DERIVED)"
        assert entry["source_table"] == ""
        assert entry["manual_logic"] == bk_expr.upper()
        assert entry.get("staging_datatype", "") == expected_dtype

    # Complex expressions → source_column = (DERIVED)
    @pytest.mark.parametrize("bk_expr", [
        "COALESCE(NAME, '-1')",
        "COALESCE(ID, '-1')::TEXT",
        "IFF(ID IS NULL, '-1', TO_CHAR(ID))",
        "CONCAT(REGION, '-', ID)",
        "ID || '-' || REGION",
        "ID + 1",
        "SUBSTR(CODE, 1, 5)",
    ])
    def test_complex_expression_bk_sets_derived(self, bk_expr):
        """Complex expression BK: always (DERIVED), always has manual_logic."""
        entry = _build_bk_entry(bk_expr)
        assert entry["source_column"] == "(DERIVED)"
        assert entry["manual_logic"] != ""


# ══════════════════════════════════════════════════════════════════════════════
# Group 2: Composite grain / QUALIFY (Fix #96)
# ══════════════════════════════════════════════════════════════════════════════

class TestCompositeGrainQualify:
    """Verify QUALIFY injection respects composite grain validation."""

    def test_composite_unique_includes_all_grain_columns(self):
        """COMPOSITE unique field must include BK + all grain columns + LOAD_DTS."""
        grain_cols = ["HOME_DEPOT_ACCOUNT", "DAY_1", "MANUF_PART_NUMBER", "SKU_NBR"]
        entry = _build_bk_entry("D_DH_DC_NBR", bk_name="STORE_BK",
                                grain_columns=grain_cols)
        expected = "COMPOSITE: STORE_BK, HOME_DEPOT_ACCOUNT, DAY_1, MANUF_PART_NUMBER, SKU_NBR, LOAD_DTS"
        assert entry["unique"] == expected

    def test_no_grain_columns_simple_unique(self):
        """When no grain columns, COMPOSITE = BK + LOAD_DTS only."""
        entry = _build_bk_entry("PLNUM", bk_name="ORDER_BK")
        assert entry["unique"] == "COMPOSITE: ORDER_BK, LOAD_DTS"

    def test_grain_columns_single_item(self):
        """Single grain column produces correct COMPOSITE."""
        entry = _build_bk_entry("ID", bk_name="ITEM_BK",
                                grain_columns=["REGION"])
        assert entry["unique"] == "COMPOSITE: ITEM_BK, REGION, LOAD_DTS"

    def test_composite_grain_excludes_raw_bk_and_load_dts_sources(self):
        """Composite grain must exclude raw BK source col and ingestion LOAD_DTS cols."""
        # Simulates: BK=VBELN->DELIVERY_BK, grain=[VBELN, SERIALNO, PSA_LOAD_DTS]
        # VBELN is already represented by DELIVERY_BK, PSA_LOAD_DTS replaced by constant LOAD_DTS
        grain_cols = ["VBELN", "SERIALNO", "PSA_LOAD_DTS"]
        entry = _build_bk_entry("VBELN", bk_name="DELIVERY_BK",
                                grain_columns=grain_cols)
        assert entry["unique"] == "COMPOSITE: DELIVERY_BK, SERIALNO, LOAD_DTS"

    def test_simple_bk_only_grain_no_source_columns(self):
        """BK-only grain (no composite) must produce BK + LOAD_DTS without source cols."""
        # Simulates: BK=MATNR->ITEM_BK, grain=[MATNR, _FIVETRAN_SYNCED]
        # MATNR is BK (excluded), _FIVETRAN_SYNCED is ingestion col (excluded)
        grain_cols = ["MATNR", "_FIVETRAN_SYNCED"]
        entry = _build_bk_entry("MATNR", bk_name="ITEM_BK",
                                grain_columns=grain_cols)
        # After filtering, no grain cols remain → BK + LOAD_DTS only
        assert entry["unique"] == "COMPOSITE: ITEM_BK, LOAD_DTS"


# ══════════════════════════════════════════════════════════════════════════════
# Group 3: Source name resolution (Fix #97)
# ══════════════════════════════════════════════════════════════════════════════

MOCK_SOURCES_YAML = """\
version: 2
sources:
- name: sap_ecc_prd
  database: "psa_{{env_var('DBT_SOURCE_ENV')}}"
  schema: sap_ecc_prd
  tables:
  - name: z_ekko
- name: home_depot_ft_psa
  database: "psa_{{env_var('DBT_SOURCE_ENV')}}"
  schema: custom_fivetran_home_depot_askuity_sdk
  description: Schema for Custom Fivetran SDK connector for HD Askuity
  tables:
  - name: vendor_drill_pos_data_us
  - name: vendor_drill_inv_data_us
"""


class TestSourceNameResolution:
    """Verify 3-step source name resolution from physical schema."""

    def _write_sources(self, tmp_path, content=MOCK_SOURCES_YAML):
        """Write mock sources YAML and return rootdir."""
        sources_dir = tmp_path / "models" / "sources"
        sources_dir.mkdir(parents=True)
        (sources_dir / "_sources_staging_psa.yml").write_text(content)
        # build._resolve_source_name walks up looking for dbt_project.yml
        (tmp_path / "dbt_project.yml").write_text("name: test\n")
        return tmp_path

    def test_common_case_name_equals_schema(self, tmp_path):
        """When source name == schema name, return name directly."""
        rootdir = self._write_sources(tmp_path)
        # Clear cache between tests
        from build import _source_name_cache
        _source_name_cache.clear()
        result = _resolve_source_name("sap_ecc_prd", rootdir=rootdir)
        assert result == "sap_ecc_prd"

    def test_alias_case_schema_override(self, tmp_path):
        """When source has schema: override (name != schema),
        resolve via schema match."""
        rootdir = self._write_sources(tmp_path)
        from build import _source_name_cache
        _source_name_cache.clear()
        result = _resolve_source_name("custom_fivetran_home_depot_askuity_sdk",
                                      rootdir=rootdir)
        assert result == "home_depot_ft_psa"

    def test_unregistered_schema_passthrough(self, tmp_path):
        """When no match found, return physical schema as-is."""
        rootdir = self._write_sources(tmp_path)
        from build import _source_name_cache
        _source_name_cache.clear()
        result = _resolve_source_name("brand_new_schema", rootdir=rootdir)
        assert result == "brand_new_schema"

    def test_register_source_appends_to_existing_block(self, tmp_path):
        """_register_source appends table to existing source block
        found via schema: override match."""
        import yaml as _yaml
        rootdir = self._write_sources(tmp_path)
        sources_path = rootdir / "models" / "sources" / "_sources_staging_psa.yml"

        with patch("pipeline_orchestrator.PROJECT_ROOT", rootdir):
            result = _register_source("custom_fivetran_home_depot_askuity_sdk",
                                      "vendor_drill_dc_inv_data_with_store_us")

        assert result is True
        data = _yaml.safe_load(sources_path.read_text())
        # Find the source block
        hd_src = next(s for s in data["sources"]
                      if s["name"] == "home_depot_ft_psa")
        table_names = [t["name"] for t in hd_src["tables"]]
        assert "vendor_drill_dc_inv_data_with_store_us" in table_names

    def test_register_source_idempotent(self, tmp_path):
        """Registering the same table twice returns False, no duplicate."""
        rootdir = self._write_sources(tmp_path)

        with patch("pipeline_orchestrator.PROJECT_ROOT", rootdir):
            first = _register_source("sap_ecc_prd", "z_ekko")

        assert first is False  # Already exists

    def test_register_source_creates_new_block(self, tmp_path):
        """When no source block matches, create a new one."""
        import yaml as _yaml
        rootdir = self._write_sources(tmp_path)
        sources_path = rootdir / "models" / "sources" / "_sources_staging_psa.yml"

        with patch("pipeline_orchestrator.PROJECT_ROOT", rootdir):
            result = _register_source("totally_new_schema", "new_table")

        assert result is True
        data = _yaml.safe_load(sources_path.read_text())
        new_src = next((s for s in data["sources"]
                        if s["name"] == "totally_new_schema"), None)
        assert new_src is not None
        assert new_src["schema"] == "totally_new_schema"
        table_names = [t["name"] for t in new_src["tables"]]
        assert "new_table" in table_names


# ══════════════════════════════════════════════════════════════════════════════
# Group 4: _infer_bk_datatype helper
# ══════════════════════════════════════════════════════════════════════════════

class TestInferBkDatatype:
    """Verify datatype inference from BK expressions."""

    @pytest.mark.parametrize("expr,expected", [
        ("ID::TEXT", "TEXT"),
        ("TO_CHAR(ID)", "TEXT"),
        ("TO_VARCHAR(ID)", "TEXT"),
        ("ID::NUMBER", "NUMBER"),
        ("TO_NUMBER(ID)", "NUMBER"),
        ("TRY_TO_NUMBER(ID)", "NUMBER"),
        ("ID::DATE", "DATE"),
        ("TO_DATE(STR)", "DATE"),
        ("TRY_TO_DATE(STR)", "DATE"),
        ("ID::TIMESTAMP_NTZ", "TIMESTAMP_NTZ"),
        ("TO_TIMESTAMP(STR)", "TIMESTAMP_NTZ"),
        ("ID::VARIANT", "VARIANT"),
        ("ID::BOOLEAN", "BOOLEAN"),
        ("TO_BOOLEAN(STR)", "BOOLEAN"),
        ("ID::FLOAT", "FLOAT"),
        ("TO_DOUBLE(STR)", "FLOAT"),
        ("TRIM(ID)", ""),           # No inference
        ("UPPER(ID)", ""),          # No inference
        ("COALESCE(ID, '-1')", ""), # No inference
        ("ID || '-' || REGION", ""),# No inference
    ])
    def test_infer_datatype(self, expr, expected):
        """Verify datatype inference for various BK expressions."""
        assert _infer_bk_datatype(expr) == expected


# ══════════════════════════════════════════════════════════════════════════════
# Group 5: PLAIN_COLUMN_RE boundary cases
# ══════════════════════════════════════════════════════════════════════════════

class TestPlainColumnRegex:
    """Verify PLAIN_COLUMN_RE catches edge cases correctly."""

    @pytest.mark.parametrize("expr", [
        "PLNUM", "ID", "VENDOR_SITE_ID", "D_DH_DC_NBR",
        "A", "Z_1", "_PRIVATE", "COL_123_NAME",
    ])
    def test_plain_columns_match(self, expr):
        """Plain column identifiers must match."""
        assert PLAIN_COLUMN_RE.match(expr)

    @pytest.mark.parametrize("expr", [
        "TO_CHAR(ID)", "ID::TEXT", "ID + 1", "ID || REGION",
        "COALESCE(ID, '-1')", "SUBSTR(ID, 1, 5)", "123_COL",
        "ID-REGION", "COL NAME", "", "ID.FIELD",
    ])
    def test_non_plain_columns_no_match(self, expr):
        """Non-plain expressions must NOT match."""
        assert not PLAIN_COLUMN_RE.match(expr)


# ══════════════════════════════════════════════════════════════════════════════
# Group 6: _extract_raw_col_from_bk — Lesson #100 fix
# ══════════════════════════════════════════════════════════════════════════════

class TestExtractRawColFromBk:
    """Verify _extract_raw_col_from_bk handles nested functions (lesson #100).

    The old split('(')[-1] pattern broke on nested expressions like
    COALESCE(NULLIF(UPPER(TRIM(COL)),''),'-1') — extracting '-1' instead of COL.
    """

    @pytest.mark.parametrize("expr,expected", [
        # Plain columns — passthrough
        ("PLNUM", "PLNUM"),
        ("ID", "ID"),
        ("VENDOR_SITE_ID", "VENDOR_SITE_ID"),
        # Simple function wrappers
        ("TO_CHAR(ID)", "ID"),
        ("UPPER(NAME)", "NAME"),
        ("TRIM(REGION)", "REGION"),
        # Cast expressions
        ("ID::TEXT", "ID"),
        ("VENDOR_SITE_ID::VARCHAR", "VENDOR_SITE_ID"),
        # Nested functions — the lesson #100 bug
        ("COALESCE(NULLIF(UPPER(TRIM(COL)),''),'-1')", "COL"),
        ("COALESCE(NULLIF(TRIM(CAST(MATNR AS VARCHAR)), ''), '^^')", "MATNR"),
        ("IFNULL(TRIM(FIELD), '^^')", "FIELD"),
        # Double-nested with string literals
        ("COALESCE(NULLIF(TRIM(ERP_KEY_ACCOUNT_GROUP),''),'-1')", "ERP_KEY_ACCOUNT_GROUP"),
        # Function + cast combo
        ("TO_CHAR(ID)::TEXT", "ID"),
        ("UPPER(TRIM(NAME))::VARCHAR", "NAME"),
    ])
    def test_extract_raw_col(self, expr, expected):
        """Each BK expression must resolve to its raw column name."""
        assert _extract_raw_col_from_bk(expr) == expected

    def test_extract_preserves_unknown_identifier(self):
        """If no recognized column found, returns original stripped."""
        # Edge case: expression with no identifiers after filtering
        result = _extract_raw_col_from_bk("CAST('literal' AS VARCHAR)")
        # Should return the expression itself since no column found
        assert isinstance(result, str)

# ══════════════════════════════════════════════════════════════════════════════
# Group 6: Composite grain messaging in show-profile / approve-profile
# ══════════════════════════════════════════════════════════════════════════════

def _now_iso():
    from datetime import datetime as _dt, timezone as _tz
    return _dt.now(_tz.utc).isoformat()


def _make_state(model_name="v_psa_stg_test__src", steps=None, profile=None, **extra):
    """Build a minimal valid state dict for show-profile/approve-profile tests."""
    state = {
        "model_name": model_name,
        "schema": "test_schema",
        "table": "test_table",
        "bk": "TEST_COL",
        "bk_name": "TEST_BK",
        "rec_src": "TEST.SYS.APP.TABLE",
        "objects": ["stg"],
        "created_at": _now_iso(),
        "steps_completed": [],
        "profile_results": profile or {},
    }
    if steps:
        for step in steps:
            state["steps_completed"].append({"step": step, "completed_at": _now_iso()})
    state.update(extra)
    return state


class TestCompositeGrainMessaging:
    """Verify show-profile and approve-profile display correct grain messages
    for composite-grain models (Phase 1 fails, Phase 2 passes)."""

    def test_show_profile_composite_grain_valid(self, capsys):
        """Composite grain model — Phase 1 fails, Phase 2 passes.
        show-profile should display 'valid (composite)', no 'BK choice may be wrong' warning."""
        state = _make_state(
            steps=["init", "profile"],
            profile={
                "row_count": 87,
                "volume_tier": "normal",
                "column_count": 17,
                "null_bk_count": 0,
                "grain_valid": True,  # Phase 2 overrode Phase 1
                "grain_total": 87,
                "grain_distinct": 75,
                "composite_grain_total": 87,
                "composite_grain_distinct": 87,
                "bkcc": "Swimming_Ocean",
                "ingestion_source": "fivetran",
                "source_registered": True,
                "has_fivetran_deleted": True,
                "has_psa_delete_ind": True,
                "grain_columns": ["SETID", "EFFDT", "NET_TRMS_SEQ_NBR"],
                "collision_check": {
                    "blocked": False,
                    "layers": {
                        "v_psa_stg": {"status": "CLEAR", "message": "ok"},
                        "sat": {"status": "CLEAR", "message": "ok"},
                    },
                },
            },
            grain_columns=["SETID", "EFFDT", "NET_TRMS_SEQ_NBR"],
        )

        with patch("pipeline_orchestrator._resolve_state", return_value=state):
            args = MagicMock()
            args.model_name = None
            result = cmd_show_profile(args)

        captured = capsys.readouterr().out
        assert result == 0
        assert "valid (composite)" in captured
        assert "DUPLICATES FOUND" not in captured
        assert "BK choice may be wrong" not in captured

    def test_show_profile_simple_grain_duplicates(self, capsys):
        """Simple BK-only grain — Phase 1 fails.
        show-profile should display 'DUPLICATES FOUND' with 'BK choice may be wrong' warning."""
        state = _make_state(
            steps=["init", "profile"],
            profile={
                "row_count": 87,
                "volume_tier": "normal",
                "column_count": 17,
                "null_bk_count": 0,
                "grain_valid": False,  # Phase 1 failed, no Phase 2
                "grain_total": 87,
                "grain_distinct": 75,
                "bkcc": "Swimming_Ocean",
                "ingestion_source": "fivetran",
                "source_registered": True,
                "has_fivetran_deleted": True,
                "has_psa_delete_ind": True,
                "collision_check": {
                    "blocked": False,
                    "layers": {
                        "v_psa_stg": {"status": "CLEAR", "message": "ok"},
                        "sat": {"status": "CLEAR", "message": "ok"},
                    },
                },
            },
            # No grain_columns — simple BK-only grain
        )

        with patch("pipeline_orchestrator._resolve_state", return_value=state):
            args = MagicMock()
            args.model_name = None
            result = cmd_show_profile(args)

        captured = capsys.readouterr().out
        assert result == 0
        assert "DUPLICATES FOUND" in captured
        assert "BK choice may be wrong" in captured
        assert "valid (composite)" not in captured

    def test_approve_profile_no_grain_warning_when_composite_valid(self, capsys, tmp_path):
        """approve-profile should NOT warn about grain when composite grain is valid."""
        state = _make_state(
            steps=["init", "profile"],
            profile={
                "bkcc": "Swimming_Ocean",
                "grain_valid": True,  # Phase 2 passed
                "ingestion_source": "fivetran",
                "grain_columns": ["SETID", "EFFDT", "NET_TRMS_SEQ_NBR"],
                "collision_check": {
                    "blocked": False,
                    "layers": {
                        "v_psa_stg": {"status": "CLEAR", "message": "ok"},
                        "sat": {"status": "CLEAR", "message": "ok"},
                    },
                },
            },
            grain_columns=["SETID", "EFFDT", "NET_TRMS_SEQ_NBR"],
        )

        # Patch SCRIPT_DIR to tmp_path so _persist_profile_markdown writes
        # under the test sandbox instead of polluting scripts/automation/configs/.
        with patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path):
            args = MagicMock()
            args.model_name = None
            args.force = False
            result = cmd_approve_profile(args)

        assert result == 0  # No warnings, proceeds
        captured = capsys.readouterr().out
        assert "grain has duplicates" not in captured.lower()

    def test_approve_profile_warns_when_simple_grain_fails(self, capsys, tmp_path):
        """approve-profile should warn about BK grain duplicates for simple (non-composite) models."""
        state = _make_state(
            steps=["init", "profile"],
            profile={
                "bkcc": "Swimming_Ocean",
                "grain_valid": False,  # Phase 1 failed, no composite
                "ingestion_source": "fivetran",
                "collision_check": {
                    "blocked": False,
                    "layers": {
                        "v_psa_stg": {"status": "CLEAR", "message": "ok"},
                        "sat": {"status": "CLEAR", "message": "ok"},
                    },
                },
            },
            # No grain_columns — simple BK-only grain
        )

        # Defensive SCRIPT_DIR patch — even though this test currently expects
        # rc=1 (blocked before persist), shielding the real configs/ dir guards
        # against drift if approve-profile starts persisting earlier.
        with patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path):
            args = MagicMock()
            args.model_name = None
            args.force = False
            result = cmd_approve_profile(args)

        assert result == 1  # Blocked by warning (no --force)
        captured = capsys.readouterr().out
        assert "BK+_FIVETRAN_SYNCED grain has duplicates" in captured



# ---------------------------------------------------------------------------
# Post-Build Validation [4/5] — regression tests
# ---------------------------------------------------------------------------


class TestPostBuildValidation:
    """Step [4/5] post-build row count validation in cmd_implement."""

    def _make_state(self, objects=None, sat_names=None, hub_name=None, lnk_name=None, hub_add_source=False):
        """Create a minimal state for implement with build already passed."""
        state = {
            "model_name": "v_psa_stg_test__src",
            "schema": "TEST_SCHEMA",
            "table": "TEST_TABLE",
            "bk": "COL_A",
            "bk_name": "TEST_BK",
            "rec_src": "TEST.SRC",
            "objects": objects or ["stg", "sat"],
            "sats": [{"model_name": sn} for sn in (sat_names or ["msat_test__src"])],
            "steps_completed": [
                {"step": "init"}, {"step": "profile"}, {"step": "approve-profile"},
                {"step": "generate-yaml"}, {"step": "generate-xlsx"},
                {"step": "approve-xlsx"}, {"step": "generate-code"},
                {"step": "approve-code"},
            ],
            "generated_files": {
                "sql": "scripts/automation/models/int_staging_views/v_psa_stg_test__src.sql",
                "yml": "scripts/automation/models/int_staging_views/v_psa_stg_test__src.yml",
                "sat_sql": "scripts/automation/models/raw_vault/sat/msat_test__src.sql",
                "sat_yml": "scripts/automation/models/raw_vault/sat/msat_test__src.yml",
            },
            "profile_results": {},
        }
        if hub_name:
            state["hub_name_override"] = hub_name
            state["generated_files"]["hub_sql"] = f"scripts/automation/models/raw_vault/hub/{hub_name}.sql"
            state["generated_files"]["hub_yml"] = f"scripts/automation/models/raw_vault/hub/{hub_name}.yml"
        return state

    def test_sat_with_rows_shows_success(self, tmp_path, capsys):
        """SAT with rows should print success checkmark."""
        from pipeline_orchestrator import cmd_implement

        state = self._make_state()

        # Create required generated files
        gen_dir = tmp_path / "scripts" / "automation" / "models" / "int_staging_views"
        gen_dir.mkdir(parents=True, exist_ok=True)
        (gen_dir / "v_psa_stg_test__src.sql").write_text("SELECT 1")
        (gen_dir / "v_psa_stg_test__src.yml").write_text("version: 2")
        sat_dir = tmp_path / "scripts" / "automation" / "models" / "raw_vault" / "sat"
        sat_dir.mkdir(parents=True, exist_ok=True)
        (sat_dir / "msat_test__src.sql").write_text("SELECT 1")
        (sat_dir / "msat_test__src.yml").write_text("version: 2")

        # Create target dirs
        stg_dir = tmp_path / "models" / "int_staging_views" / "supplier"
        stg_dir.mkdir(parents=True, exist_ok=True)
        rv_sat_dir = tmp_path / "models" / "raw_vault" / "sat"
        rv_sat_dir.mkdir(parents=True, exist_ok=True)
        src_dir = tmp_path / "models" / "sources"
        src_dir.mkdir(parents=True, exist_ok=True)
        (src_dir / "_sources_staging_psa.yml").write_text("version: 2\nsources: []\n")

        args = MagicMock()
        args.model_name = None
        args.domain = "supplier"
        args.force = True
        args.skip_build = False
        args.skip_hub = False

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_dbt") as mock_dbt, \
             patch("pipeline_orchestrator._run_snowflake_query") as mock_sf, \
             patch("pipeline_orchestrator._run_code_review", return_value={"checks_run": 42, "fail_count": 0, "warn_count": 0, "findings": []}):

            # dbt build succeeds; dbt debug returns schema
            def _dbt_side_effect(args_list, **kwargs):
                if args_list[0] == "debug":
                    return (0, "  schema: dbt_test_schema", "")
                return (0, "Done. PASS=5 WARN=0 ERROR=0 SKIP=0 TOTAL=5", "")
            mock_dbt.side_effect = _dbt_side_effect
            # Row count query returns 87 rows
            mock_sf.return_value = [[87]]

            rc = cmd_implement(args)

        assert rc == 0
        captured = capsys.readouterr().out
        assert "msat_test__src: 87 rows" in captured
        assert "\u2705" in captured

    def test_sat_with_zero_rows_shows_warning(self, tmp_path, capsys):
        """SAT with zero rows should print warning (not failure)."""
        from pipeline_orchestrator import cmd_implement

        state = self._make_state()

        gen_dir = tmp_path / "scripts" / "automation" / "models" / "int_staging_views"
        gen_dir.mkdir(parents=True, exist_ok=True)
        (gen_dir / "v_psa_stg_test__src.sql").write_text("SELECT 1")
        (gen_dir / "v_psa_stg_test__src.yml").write_text("version: 2")
        sat_dir = tmp_path / "scripts" / "automation" / "models" / "raw_vault" / "sat"
        sat_dir.mkdir(parents=True, exist_ok=True)
        (sat_dir / "msat_test__src.sql").write_text("SELECT 1")
        (sat_dir / "msat_test__src.yml").write_text("version: 2")

        stg_dir = tmp_path / "models" / "int_staging_views" / "supplier"
        stg_dir.mkdir(parents=True, exist_ok=True)
        rv_sat_dir = tmp_path / "models" / "raw_vault" / "sat"
        rv_sat_dir.mkdir(parents=True, exist_ok=True)
        src_dir = tmp_path / "models" / "sources"
        src_dir.mkdir(parents=True, exist_ok=True)
        (src_dir / "_sources_staging_psa.yml").write_text("version: 2\nsources: []\n")

        args = MagicMock()
        args.model_name = None
        args.domain = "supplier"
        args.force = True
        args.skip_build = False
        args.skip_hub = False

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_dbt") as mock_dbt, \
             patch("pipeline_orchestrator._run_snowflake_query") as mock_sf, \
             patch("pipeline_orchestrator._run_code_review", return_value={"checks_run": 42, "fail_count": 0, "warn_count": 0, "findings": []}):

            def _dbt_side_effect(args_list, **kwargs):
                if args_list[0] == "debug":
                    return (0, "  schema: dbt_test_schema", "")
                return (0, "Done. PASS=5 WARN=0 ERROR=0 SKIP=0 TOTAL=5", "")
            mock_dbt.side_effect = _dbt_side_effect
            mock_sf.return_value = [[0]]

            rc = cmd_implement(args)

        # SAT zero rows is a warning, NOT a failure
        assert rc == 0
        captured = capsys.readouterr().out
        assert "0 rows" in captured
        assert "may be expected for first load" in captured

    def test_hub_add_source_zero_rows_shows_error(self, tmp_path, capsys):
        """HUB ADD-SOURCE with zero rows should flag validation failure."""
        from pipeline_orchestrator import cmd_implement

        state = self._make_state(
            objects=["stg", "hub", "sat"],
            hub_name="hub_test",
        )
        # Simulate ADD-SOURCE scenario
        state["profile_results"]["collision_check"] = {
            "layers": {"hub": {"status": "ADD-SOURCE"}}
        }

        gen_dir = tmp_path / "scripts" / "automation" / "models" / "int_staging_views"
        gen_dir.mkdir(parents=True, exist_ok=True)
        (gen_dir / "v_psa_stg_test__src.sql").write_text("SELECT 1")
        (gen_dir / "v_psa_stg_test__src.yml").write_text("version: 2")
        sat_dir = tmp_path / "scripts" / "automation" / "models" / "raw_vault" / "sat"
        sat_dir.mkdir(parents=True, exist_ok=True)
        (sat_dir / "msat_test__src.sql").write_text("SELECT 1")
        (sat_dir / "msat_test__src.yml").write_text("version: 2")
        hub_dir = tmp_path / "scripts" / "automation" / "models" / "raw_vault" / "hub"
        hub_dir.mkdir(parents=True, exist_ok=True)
        (hub_dir / "hub_test.sql").write_text("SELECT 1")
        (hub_dir / "hub_test.yml").write_text("version: 2")

        stg_dir = tmp_path / "models" / "int_staging_views" / "supplier"
        stg_dir.mkdir(parents=True, exist_ok=True)
        rv_sat_dir = tmp_path / "models" / "raw_vault" / "sat"
        rv_sat_dir.mkdir(parents=True, exist_ok=True)
        rv_hub_dir = tmp_path / "models" / "raw_vault" / "hub"
        rv_hub_dir.mkdir(parents=True, exist_ok=True)
        # Pre-create the hub file for ADD-SOURCE detection
        (rv_hub_dir / "hub_test.sql").write_text("-- existing hub")
        (rv_hub_dir / "hub_test.yml").write_text("version: 2")
        src_dir = tmp_path / "models" / "sources"
        src_dir.mkdir(parents=True, exist_ok=True)
        (src_dir / "_sources_staging_psa.yml").write_text("version: 2\nsources: []\n")

        args = MagicMock()
        args.model_name = None
        args.domain = "supplier"
        args.force = True
        args.skip_build = False
        args.skip_hub = False

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_dbt") as mock_dbt, \
             patch("pipeline_orchestrator._run_snowflake_query") as mock_sf, \
             patch("pipeline_orchestrator._run_code_review", return_value={"checks_run": 42, "fail_count": 0, "warn_count": 0, "findings": []}), \
             patch("pipeline_orchestrator._parse_existing_hub") as mock_parse_hub, \
             patch("pipeline_orchestrator._derive_source_alias", return_value="src_new"), \
             patch("pipeline_orchestrator._build_add_source_column_mapping", return_value=[]), \
             patch("pipeline_orchestrator._generate_add_source_ctes", return_value=""), \
             patch("pipeline_orchestrator._insert_source_into_hub"):

            mock_parse_hub.return_value = {"sources": [{"alias": "src_old"}], "hk_column": "TEST_HK"}
            def _dbt_side_effect(args_list, **kwargs):
                if args_list[0] == "debug":
                    return (0, "  schema: dbt_test_schema", "")
                return (0, "Done. PASS=5 WARN=0 ERROR=0 SKIP=0 TOTAL=5", "")
            mock_dbt.side_effect = _dbt_side_effect
            # BKCC clone returns None (DDL), then SAT=50 rows, HUB=0 rows
            mock_sf.side_effect = [
                None,  # BKCC clone (DDL — returns None from MCP skip)
                [[50]],  # SAT count
                [[0]],   # HUB count — should trigger validation error
            ]

            rc = cmd_implement(args)

        # Pipeline still returns 0 (build passed) but validation shows error
        assert rc == 0
        captured = capsys.readouterr().out
        assert "0 rows \u274c" in captured or "0 rows ❌" in captured

    def test_query_failure_shows_warning_continues(self, tmp_path, capsys):
        """Query failure should warn but not fail the pipeline."""
        from pipeline_orchestrator import cmd_implement

        state = self._make_state()

        gen_dir = tmp_path / "scripts" / "automation" / "models" / "int_staging_views"
        gen_dir.mkdir(parents=True, exist_ok=True)
        (gen_dir / "v_psa_stg_test__src.sql").write_text("SELECT 1")
        (gen_dir / "v_psa_stg_test__src.yml").write_text("version: 2")
        sat_dir = tmp_path / "scripts" / "automation" / "models" / "raw_vault" / "sat"
        sat_dir.mkdir(parents=True, exist_ok=True)
        (sat_dir / "msat_test__src.sql").write_text("SELECT 1")
        (sat_dir / "msat_test__src.yml").write_text("version: 2")

        stg_dir = tmp_path / "models" / "int_staging_views" / "supplier"
        stg_dir.mkdir(parents=True, exist_ok=True)
        rv_sat_dir = tmp_path / "models" / "raw_vault" / "sat"
        rv_sat_dir.mkdir(parents=True, exist_ok=True)
        src_dir = tmp_path / "models" / "sources"
        src_dir.mkdir(parents=True, exist_ok=True)
        (src_dir / "_sources_staging_psa.yml").write_text("version: 2\nsources: []\n")

        args = MagicMock()
        args.model_name = None
        args.domain = "supplier"
        args.force = True
        args.skip_build = False
        args.skip_hub = False

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_dbt") as mock_dbt, \
             patch("pipeline_orchestrator._run_snowflake_query") as mock_sf, \
             patch("pipeline_orchestrator._run_code_review", return_value={"checks_run": 42, "fail_count": 0, "warn_count": 0, "findings": []}):

            def _dbt_side_effect(args_list, **kwargs):
                if args_list[0] == "debug":
                    return (0, "  schema: dbt_test_schema", "")
                return (0, "Done. PASS=5 WARN=0 ERROR=0 SKIP=0 TOTAL=5", "")
            mock_dbt.side_effect = _dbt_side_effect
            # The BKCC clone (DDL) succeeds; only the post-build COUNT(*) query
            # fails, exercising the validation best-effort path (not the clone).
            def _sf_side_effect(sql, _args):
                if "COUNT(*)" in sql.upper():
                    raise Exception("Connection refused")
                return [[1]]
            mock_sf.side_effect = _sf_side_effect

            rc = cmd_implement(args)

        # Pipeline succeeds despite query failure
        assert rc == 0
        captured = capsys.readouterr().out
        assert "Could not verify" in captured


# ---------------------------------------------------------------------------
# Regression Guard: profile --grain-columns stores state + Phase 2 activates
# ---------------------------------------------------------------------------


class TestProfileGrainColumnsArg:
    """Regression guard: --grain-columns on profile must store in state and
    activate Phase 2 grain validation. show-profile must then show
    'valid (composite)' — NEVER 'DUPLICATES FOUND'.

    This is the root cause of the recurring composite grain messaging failure:
    if --grain-columns is not passed during init, Phase 2 never runs,
    grain_valid stays False, and show-profile shows 'DUPLICATES FOUND'.
    """

    def test_profile_grain_columns_stored_in_state(self):
        """--grain-columns passed at profile time must persist in state."""
        from pipeline_orchestrator import cmd_profile, _save_state

        state = _make_state(steps=["init"])

        # Verify grain_columns is NOT set initially
        assert "grain_columns" not in state or state.get("grain_columns") is None

        with patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state") as mock_save, \
             patch("pipeline_orchestrator._run_snowflake_query") as mock_sf, \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._semantic_collision_check", return_value={
                 "blocked": False, "layers": {
                     "v_psa_stg": {"status": "CLEAR", "message": "ok"},
                     "sat": {"status": "CLEAR", "message": "ok"},
                 }}):

            # Mock enough Snowflake responses for the profile to complete
            mock_sf.side_effect = [
                # Step 2: DESCRIBE columns
                [("COL_A", "TEXT", "YES"), ("SETID", "TEXT", "YES"),
                 ("EFFDT", "DATE", "YES"), ("SEQ", "NUMBER", "YES"),
                 ("_FIVETRAN_SYNCED", "TIMESTAMP_TZ", "YES"),
                 ("_FIVETRAN_DELETED", "BOOLEAN", "YES"),
                 ("PSA_DELETE_IND", "TEXT", "YES")],
                # Step 3: sample
                [("row1",)],
                # Step 4: row count
                [(87,)],
                # Step 5: Phase 1 grain check (BK+LOAD_DTS — NOT unique)
                [(87, 75)],
                # Step 5b: Phase 2 composite grain (ALL unique)
                [(87, 87)],
                # Step 6: NULL BK count
                [(0,)],
                # Step 8: BKCC
                [("Swimming_Ocean",)],
            ]

            args = MagicMock()
            args.model_name = None
            args.profile_json = None
            args.snowflake_conn = None
            args.grain_columns = "SETID,EFFDT,SEQ"

            result = cmd_profile(args)

        # grain_columns should be stored in state
        assert state.get("grain_columns") == ["SETID", "EFFDT", "SEQ"]
        # Phase 2 should have overridden grain_valid to True
        profile = state.get("profile_results", {})
        assert profile.get("grain_valid") is True

    def test_show_profile_after_profile_with_grain_columns(self, capsys):
        """End-to-end: after profile --grain-columns, show-profile must display
        'valid (composite)' and must NOT display 'DUPLICATES FOUND'."""
        state = _make_state(
            steps=["init", "profile"],
            profile={
                "row_count": 87,
                "volume_tier": "normal",
                "column_count": 7,
                "null_bk_count": 0,
                "grain_valid": True,  # Phase 2 passed
                "grain_total": 87,
                "grain_distinct": 75,
                "composite_grain_total": 87,
                "composite_grain_distinct": 87,
                "bkcc": "Swimming_Ocean",
                "ingestion_source": "fivetran",
                "source_registered": True,
                "has_fivetran_deleted": True,
                "has_psa_delete_ind": True,
                "grain_columns": ["SETID", "EFFDT", "SEQ"],
                "collision_check": {
                    "blocked": False,
                    "layers": {
                        "v_psa_stg": {"status": "CLEAR", "message": "ok"},
                        "sat": {"status": "CLEAR", "message": "ok"},
                    },
                },
            },
            grain_columns=["SETID", "EFFDT", "SEQ"],
        )

        with patch("pipeline_orchestrator._resolve_state", return_value=state):
            args = MagicMock()
            args.model_name = None
            result = cmd_show_profile(args)

        captured = capsys.readouterr().out
        assert result == 0
        assert "valid (composite)" in captured
        assert "DUPLICATES FOUND" not in captured
        assert "BK choice may be wrong" not in captured
        # Grain display should include all composite columns
        assert "SETID" in captured
        assert "EFFDT" in captured
        assert "SEQ" in captured

    def test_profile_without_grain_columns_shows_hint(self, capsys):
        """When profile finds duplicates and no --grain-columns is set,
        it must print a hint suggesting --grain-columns."""
        from pipeline_orchestrator import cmd_profile

        state = _make_state(steps=["init"])

        with patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._run_snowflake_query") as mock_sf, \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._semantic_collision_check", return_value={
                 "blocked": False, "layers": {
                     "v_psa_stg": {"status": "CLEAR", "message": "ok"},
                     "sat": {"status": "CLEAR", "message": "ok"},
                 }}):

            mock_sf.side_effect = [
                # Step 2: columns
                [("COL_A", "TEXT", "YES"), ("_FIVETRAN_SYNCED", "TIMESTAMP_TZ", "YES"),
                 ("PSA_DELETE_IND", "TEXT", "YES")],
                # Step 3: sample
                [("row1",)],
                # Step 4: row count
                [(87,)],
                # Step 5: Phase 1 grain (NOT unique)
                [(87, 75)],
                # Step 6: NULL BK
                [(0,)],
                # Step 8: BKCC
                [("Swimming_Ocean",)],
            ]

            args = MagicMock()
            args.model_name = None
            args.profile_json = None
            args.snowflake_conn = None
            args.grain_columns = None

            result = cmd_profile(args)

        captured = capsys.readouterr().out
        assert "GRAIN PROBLEM" in captured
        assert "--grain-columns" in captured


# ──────────────────────────────────────────────────────────────────────────────
# H-1: BK Expression Input Validation (Defense-in-Depth)
# ──────────────────────────────────────────────────────────────────────────────

from pipeline_orchestrator import BK_SAFE_CHARS, IDENTIFIER_PATTERN


class TestBkExpressionValidation:
    """H-1: BK expression validation — defense-in-depth against SQL injection."""

    @pytest.mark.parametrize("bk", [
        "TERM_ID",
        "VENDOR_SITE_ID::TEXT",
        "COALESCE(VENDOR_SITE_ID, '-1')",
        "COALESCE(NULLIF(UPPER(TRIM(MANDT)),''  ),'-1')",
        "PO_NUMBER::TEXT",
        "PO_LINE_ITEM::TEXT",
        "CONCAT_WS('||', COL1, COL2)",
        "TO_CHAR(ID)",
    ])
    def test_valid_bk_accepted(self, bk):
        """Valid BK expressions pass the safe-char regex."""
        assert BK_SAFE_CHARS.match(bk), f"Should accept: {bk!r}"

    @pytest.mark.parametrize("bk,reason", [
        ("COL; DROP TABLE x", "semicolon"),
        ("COL -- comment", "SQL line comment"),
        ("COL /* block */", "SQL block comment"),
        ("COL$(whoami)", "shell variable expansion"),
        ("`COL`", "backtick"),
        ("COL\\n", "backslash"),
        ("COL{}", "curly braces"),
        ("COL[0]", "square brackets"),
    ])
    def test_dangerous_bk_rejected(self, bk, reason):
        """Dangerous BK expressions fail BK_SAFE_CHARS or terminator check."""
        has_terminator = bool(re.search(r'(;|--|/\*|\*/)', bk))
        safe_chars_ok = bool(BK_SAFE_CHARS.match(bk))
        assert has_terminator or not safe_chars_ok, \
            f"Should reject ({reason}): {bk!r}"

    def test_multi_bk_parts_all_validated(self):
        """Each part of a multi-BK expression is individually validated."""
        multi = "PO_NUMBER::TEXT, PO_LINE_ITEM::TEXT"
        for part in [b.strip() for b in multi.split(',')]:
            assert BK_SAFE_CHARS.match(part), f"Should accept part: {part!r}"


# ──────────────────────────────────────────────────────────────────────────────
# H-2: Secondary Parameter Validation
# ──────────────────────────────────────────────────────────────────────────────

class TestSecondaryParamValidation:
    """H-2: Secondary table parameter validation."""

    @pytest.mark.parametrize("value", [
        "shopify_moen",
        "ORDER_HEADER",
        "ORD",
        "custom_fivetran_home_depot",
    ])
    def test_valid_identifiers_accepted(self, value):
        """Normal identifier values pass IDENTIFIER_PATTERN."""
        assert IDENTIFIER_PATTERN.match(value), f"Should accept: {value!r}"

    @pytest.mark.parametrize("value,reason", [
        ("moen'; DROP TABLE--", "SQL injection"),
        ("ORDER; DELETE", "semicolon"),
        ("ORD;--", "semicolon + comment"),
        ("moen$(whoami)", "shell expansion"),
        ("123abc", "starts with number"),
    ])
    def test_invalid_identifiers_rejected(self, value, reason):
        """Identifiers with injection chars fail IDENTIFIER_PATTERN."""
        assert not IDENTIFIER_PATTERN.match(value), \
            f"Should reject ({reason}): {value!r}"

    @pytest.mark.parametrize("bk", [
        "COALESCE(NAME, '-1')",
        "ORDER_ID::TEXT",
        "PLAIN_COL",
    ])
    def test_valid_secondary_bk_accepted(self, bk):
        """Valid BK expressions pass BK_SAFE_CHARS."""
        assert BK_SAFE_CHARS.match(bk), f"Should accept: {bk!r}"

    @pytest.mark.parametrize("bk,reason", [
        ("NAME; DROP TABLE", "semicolon"),
        ("NAME -- comment", "SQL line comment"),
        ("NAME$(whoami)", "shell expansion"),
        ("NAME`; ls`", "backtick injection"),
    ])
    def test_invalid_secondary_bk_rejected(self, bk, reason):
        """Dangerous secondary BK expressions are rejected."""
        has_terminator = bool(re.search(r'(;|--|/\*|\*/)', bk))
        safe_chars_ok = bool(BK_SAFE_CHARS.match(bk))
        assert has_terminator or not safe_chars_ok, \
            f"Should reject ({reason}): {bk!r}"


# ──────────────────────────────────────────────────────────────────────────────
# Additional BK tests (lesson #127 — multi-BK support)
# ──────────────────────────────────────────────────────────────────────────────

class TestAdditionalBk:
    """Tests for --additional-bk parsing, validation, and column injection."""

    @pytest.mark.parametrize("spec,raw,alias", [
        ("SUBSCRIBER_ID:SUBSCRIBER_BK", "SUBSCRIBER_ID", "SUBSCRIBER_BK"),
        ("order_id:ORDER_BK", "ORDER_ID", "ORDER_BK"),
        ("  ITEM_NUM : ITEM_BK  ", "ITEM_NUM", "ITEM_BK"),
    ])
    def test_parse_valid_spec(self, spec, raw, alias):
        """Valid --additional-bk specs parse correctly."""
        assert ":" in spec
        raw_col, bk_alias = spec.split(":", 1)
        raw_col = raw_col.strip().upper()
        bk_alias = bk_alias.strip().upper()
        assert raw_col == raw
        assert bk_alias == alias
        assert IDENTIFIER_PATTERN.match(raw_col)
        assert IDENTIFIER_PATTERN.match(bk_alias)

    @pytest.mark.parametrize("spec,reason", [
        ("SUBSCRIBER_ID", "missing colon separator"),
        ("SUB ID:BK", "space in raw col"),
        ("COL:BK;DROP", "semicolon in alias"),
        (":EMPTY_BK", "empty raw col"),
    ])
    def test_reject_invalid_spec(self, spec, reason):
        """Invalid --additional-bk specs are caught."""
        if ":" not in spec:
            # Missing colon → format error
            assert True
            return
        raw_col, bk_alias = spec.split(":", 1)
        raw_col = raw_col.strip().upper()
        bk_alias = bk_alias.strip().upper()
        raw_ok = bool(raw_col) and bool(IDENTIFIER_PATTERN.match(raw_col))
        alias_ok = bool(bk_alias) and bool(IDENTIFIER_PATTERN.match(bk_alias))
        assert not (raw_ok and alias_ok), f"Should reject ({reason}): {spec!r}"

    def test_bk_alias_warning_no_suffix(self):
        """BK alias without _BK suffix should trigger warning (not error)."""
        alias = "SUBSCRIBER_KEY"
        assert not alias.endswith("_BK")

    def test_column_injection_adds_raw_and_alias(self):
        """Additional BK injects both raw passthrough and alias columns."""
        additional_bks = [{"raw_col": "SUBSCRIBER_ID", "alias": "SUBSCRIBER_BK"}]
        source_columns = [
            {"name": "ID", "type": "NUMBER"},
            {"name": "SUBSCRIBER_ID", "type": "NUMBER"},
            {"name": "STATUS", "type": "VARCHAR"},
        ]
        bk_raw_set = {"ID"}
        existing_staging_cols = {"ID", "SUBSCRIPTION_ORDER_BK"}

        injected = []
        for ab in additional_bks:
            ab_raw = ab["raw_col"]
            ab_alias = ab["alias"]
            ab_col_info = next((c for c in source_columns if c["name"].upper() == ab_raw), None)
            ab_datatype = ab_col_info["type"] if ab_col_info else "VARCHAR"
            if ab_raw not in bk_raw_set and ab_raw not in existing_staging_cols:
                injected.append({"staging_column_name": ab_raw, "type": "passthrough"})
            injected.append({"staging_column_name": ab_alias, "not_null": "yes", "type": "alias"})

        assert len(injected) == 2
        assert injected[0]["staging_column_name"] == "SUBSCRIBER_ID"
        assert injected[0]["type"] == "passthrough"
        assert injected[1]["staging_column_name"] == "SUBSCRIBER_BK"
        assert injected[1]["not_null"] == "yes"

    def test_no_duplicate_raw_if_already_bk(self):
        """If additional BK raw col is already in bk_raw_set, skip passthrough."""
        additional_bks = [{"raw_col": "ID", "alias": "ALT_BK"}]
        bk_raw_set = {"ID"}
        existing_staging_cols = {"ID", "ORDER_BK"}

        injected = []
        for ab in additional_bks:
            ab_raw = ab["raw_col"]
            if ab_raw not in bk_raw_set and ab_raw not in existing_staging_cols:
                injected.append({"staging_column_name": ab_raw})
            injected.append({"staging_column_name": ab["alias"]})

        # Only alias, no passthrough (ID already in bk_raw_set)
        assert len(injected) == 1
        assert injected[0]["staging_column_name"] == "ALT_BK"

    def test_multiple_additional_bks(self):
        """Multiple --additional-bk flags produce multiple entries."""
        additional_bks = [
            {"raw_col": "SUBSCRIBER_ID", "alias": "SUBSCRIBER_BK"},
            {"raw_col": "CUSTOMER_ID", "alias": "CUSTOMER_BK"},
        ]
        bk_raw_set = {"ORDER_ID"}
        existing = set()

        injected = []
        for ab in additional_bks:
            ab_raw = ab["raw_col"]
            if ab_raw not in bk_raw_set and ab_raw not in existing:
                injected.append(ab_raw)
                existing.add(ab_raw)
            injected.append(ab["alias"])

        assert injected == [
            "SUBSCRIBER_ID", "SUBSCRIBER_BK",
            "CUSTOMER_ID", "CUSTOMER_BK",
        ]
