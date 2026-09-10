"""
test_multi_table_e2e.py — End-to-end pipeline tests for multi-table (secondary JOIN).

Tests the FULL orchestrator flow with secondary-table flags:
  1. cmd_init with --secondary-table/schema/alias/join-on/bk → stores secondary in state
  2. cmd_profile with secondary in state → profiles secondary, detects collisions
  3. State persistence: profile_results includes secondary metadata
  4. Validation: identifier injection defense (H-2)
  5. BK expression validation against renamed columns

This is the "highest untested risk" gap — the golden file test (test_golden_files.py)
covers code generation, but not init parsing or profile/validation with secondary data.
"""

import json
import sys
from argparse import Namespace
from pathlib import Path
from unittest.mock import patch

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pipeline_orchestrator import (
    cmd_init,
    cmd_profile,
    _now_iso,
    STATE_DIR,
)
from multi_table import has_secondary, validate_bk_references_renamed_columns


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

MODEL_NAME = "v_psa_stg_mt_e2e_order_line__shopify"


def _cleanup_state(model_name):
    """Remove state file after test."""
    state_file = STATE_DIR / f"{model_name}.json"
    if state_file.exists():
        state_file.unlink()


def _base_init_args(**overrides):
    """Create a Namespace with all required cmd_init fields + secondary."""
    defaults = dict(
        model_name=MODEL_NAME,
        schema="shopify_moen",
        table="fulfillment_order_line",
        bk="ID, LINE_ITEM_ID",
        bk_name="FULFILLMENT_LINE_BK",
        rec_src="US.SHOPIFY_MOEN.FULFILLMENT_ORDER_LINE",
        objects="stg",
        force=True,
        hk=None,
        lnk_name=None,
        parent_hks=None,
        dck=None,
        sat_type=None,
        sat_parent_hk=None,
        sat_parent_model=None,
        multi_active_key=None,
        sat_name=None,
        sat_columns=None,
        grain_columns=None,
        hub_name=None,
        additional_bk=None,
        # Secondary table flags
        secondary_schema="shopify_moen",
        secondary_table="fulfillment_order",
        secondary_alias="FO",
        join_type="LEFT JOIN",
        join_on="ORDER_ID = FO.ID",
        secondary_bk="ORDER_NUMBER",
        secondary_bk_name="ORDER_HEADER_BK",
        secondary_columns=["ID", "ORDER_NUMBER", "STATUS"],
    )
    defaults.update(overrides)
    return Namespace(**defaults)


def _profile_state(model_name=MODEL_NAME):
    """Create a state that has init completed + secondary, ready for profile."""
    state = {
        "model_name": model_name,
        "schema": "shopify_moen",
        "table": "fulfillment_order_line",
        "bk": "ID, LINE_ITEM_ID",
        "bk_name": "FULFILLMENT_LINE_BK",
        "rec_src": "US.SHOPIFY_MOEN.FULFILLMENT_ORDER_LINE",
        "objects": ["stg"],
        "created_at": _now_iso(),
        "steps_completed": [{"step": "init", "completed_at": _now_iso()}],
        "profile_results": {},
        "config_path": "",
        "xlsx_path": "",
        "xlsx_validation": {},
        "generated_files": {},
        "stage3_results": {},
        "hash_keys": [],
        "secondary": {
            "schema": "shopify_moen",
            "table": "FULFILLMENT_ORDER",
            "alias": "FO",
            "join_type": "LEFT JOIN",
            "join_on": "ORDER_ID = FO.ID",
            "bk": "ORDER_NUMBER",
            "bk_name": "ORDER_HEADER_BK",
            "columns": ["ID", "ORDER_NUMBER", "STATUS"],
        },
    }
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    state_file = STATE_DIR / f"{model_name}.json"
    state_file.write_text(json.dumps(state, indent=2, default=str))
    return state


# Driver columns (what INFORMATION_SCHEMA returns for fulfillment_order_line)
DRIVER_COLUMNS = [
    ("ID", "NUMBER", "NO"),
    ("LINE_ITEM_ID", "NUMBER", "NO"),
    ("ORDER_ID", "NUMBER", "YES"),
    ("STATUS", "TEXT", "YES"),
    ("QUANTITY", "NUMBER", "YES"),
    ("_FIVETRAN_SYNCED", "TIMESTAMP_TZ", "YES"),
    ("_FIVETRAN_DELETED", "BOOLEAN", "YES"),
    ("PSA_LOAD_DTS", "TIMESTAMP_LTZ", "YES"),
    ("PSA_RECORD_SOURCE", "TEXT", "YES"),
    ("PSA_DELETE_IND", "TEXT", "YES"),
]

# Secondary columns (fulfillment_order)
SECONDARY_COLUMNS = [
    ("ID", "NUMBER"),
    ("ORDER_NUMBER", "TEXT"),
    ("STATUS", "TEXT"),
    ("ASSIGNED_LOCATION_ID", "NUMBER"),
    ("CREATED_AT", "TIMESTAMP_TZ"),
    ("_FIVETRAN_SYNCED", "TIMESTAMP_TZ"),
    ("_FIVETRAN_DELETED", "BOOLEAN"),
    ("PSA_LOAD_DTS", "TIMESTAMP_LTZ"),
    ("PSA_RECORD_SOURCE", "TEXT"),
]


def _build_profile_query_mock():
    """Build a mock for _run_snowflake_query that handles all cmd_profile queries."""
    def side_effect(sql, args):
        sql_upper = sql.upper()

        # INFORMATION_SCHEMA for driver (more specific match first)
        if "INFORMATION_SCHEMA" in sql_upper and "FULFILLMENT_ORDER_LINE" in sql_upper:
            return DRIVER_COLUMNS

        # INFORMATION_SCHEMA for secondary (less specific — matches after driver check)
        if "INFORMATION_SCHEMA" in sql_upper and "FULFILLMENT_ORDER" in sql_upper:
            return SECONDARY_COLUMNS

        # Sample data
        if "LIMIT 5" in sql_upper:
            return [("1", "100", "101", "open", "2")]

        # Grain validation (must check before COUNT(*) since subquery has COUNT)
        if "_GRP_CNT" in sql_upper:
            return [(50000, 50000)]

        # Row count
        if "SELECT COUNT(*)" in sql_upper:
            return [(50000,)]

        # NULL BK check
        if "IS NULL" in sql_upper:
            return [(0,)]

        # BKCC lookup
        if "REF_BUSINESS_KEY_COLLISION" in sql_upper:
            return [("017",)]

        return []

    return side_effect


# ---------------------------------------------------------------------------
# Test 1: cmd_init with secondary flags stores secondary in state
# ---------------------------------------------------------------------------

class TestInitWithSecondary:
    """cmd_init correctly parses and stores secondary table state."""

    def teardown_method(self):
        _cleanup_state(MODEL_NAME)

    def test_init_stores_secondary_block(self):
        """Full --secondary-* flags produce correct state['secondary']."""
        args = _base_init_args()
        rc = cmd_init(args)
        assert rc == 0

        state_file = STATE_DIR / f"{MODEL_NAME}.json"
        state = json.loads(state_file.read_text())

        assert "secondary" in state
        sec = state["secondary"]
        assert sec["schema"] == "shopify_moen"
        assert sec["alias"] == "FO"
        assert sec["join_type"] == "LEFT JOIN"
        assert sec["join_on"] == "ORDER_ID = FO.ID"
        assert sec["bk"] == "ORDER_NUMBER"
        assert sec["bk_name"] == "ORDER_HEADER_BK"
        assert sec["columns"] == ["ID", "ORDER_NUMBER", "STATUS"]

    def test_init_secondary_alias_auto_derived(self):
        """When --secondary-alias omitted, alias is derived from table name."""
        args = _base_init_args(secondary_alias=None)
        rc = cmd_init(args)
        assert rc == 0

        state = json.loads((STATE_DIR / f"{MODEL_NAME}.json").read_text())
        assert state["secondary"]["alias"] == "FO"

    def test_init_secondary_schema_defaults_to_driver(self):
        """When --secondary-schema omitted, defaults to driver --schema."""
        args = _base_init_args(secondary_schema=None)
        rc = cmd_init(args)
        assert rc == 0

        state = json.loads((STATE_DIR / f"{MODEL_NAME}.json").read_text())
        assert state["secondary"]["schema"] == "shopify_moen"

    def test_init_no_secondary_no_block(self):
        """Without --secondary-table, no secondary block in state."""
        args = _base_init_args(secondary_table=None)
        rc = cmd_init(args)
        assert rc == 0

        state = json.loads((STATE_DIR / f"{MODEL_NAME}.json").read_text())
        assert "secondary" not in state or state.get("secondary") is None

    def test_init_secondary_identifier_injection_blocked(self):
        """H-2: SQL-unsafe characters in --secondary-table are rejected."""
        args = _base_init_args(secondary_table="order; DROP TABLE--")
        rc = cmd_init(args)
        assert rc == 1

    def test_init_secondary_bk_sql_terminator_blocked(self):
        """SQL terminators in --secondary-bk are rejected."""
        args = _base_init_args(secondary_bk="NAME; DROP TABLE x")
        rc = cmd_init(args)
        assert rc == 1


# ---------------------------------------------------------------------------
# Test 2: cmd_profile with secondary → profiles + detects collisions
# ---------------------------------------------------------------------------

class TestProfileWithSecondary:
    """cmd_profile correctly handles secondary table profiling."""

    def teardown_method(self):
        _cleanup_state(MODEL_NAME)

    @patch("pipeline_orchestrator._run_command")
    @patch("pipeline_orchestrator._semantic_collision_check")
    @patch("pipeline_orchestrator._run_snowflake_query")
    def test_profile_detects_collisions(self, mock_query, mock_collision, mock_cmd):
        """Secondary columns colliding with driver get auto-prefixed."""
        _profile_state()

        mock_query.side_effect = _build_profile_query_mock()
        mock_collision.return_value = {"blocked": False, "layers": {}, "status": "pass"}
        mock_cmd.return_value = (0, "", "")

        args = Namespace(
            model=MODEL_NAME,
            profile_json=None,
            grain_columns=None,
            force=False,
            hk=None,
        )

        rc = cmd_profile(args)
        assert rc == 0

        state = json.loads((STATE_DIR / f"{MODEL_NAME}.json").read_text())
        sec = state["secondary"]

        # Collisions: ID and STATUS exist in both driver and secondary
        assert "ID" in sec["collisions"]
        assert "STATUS" in sec["collisions"]

        # Auto-rename: ID → FO_ID, STATUS → FO_STATUS
        assert sec["rename_map"]["ID"] == "FO_ID"
        assert sec["rename_map"]["STATUS"] == "FO_STATUS"
        # ORDER_NUMBER is unique to secondary → not renamed
        assert sec["rename_map"]["ORDER_NUMBER"] == "ORDER_NUMBER"

        # Ingestion detected
        assert sec["ingestion"] == "fivetran"

    @patch("pipeline_orchestrator._run_command")
    @patch("pipeline_orchestrator._semantic_collision_check")
    @patch("pipeline_orchestrator._run_snowflake_query")
    def test_profile_bk_references_renamed_columns(self, mock_query, mock_collision, mock_cmd):
        """BK referencing a collision-renamed column raises ValueError."""
        state = _profile_state()
        # BK uses "ID" which will collide with driver → renamed to FO_ID
        state["secondary"]["bk"] = "ID"
        (STATE_DIR / f"{MODEL_NAME}.json").write_text(
            json.dumps(state, indent=2, default=str)
        )

        mock_query.side_effect = _build_profile_query_mock()
        mock_collision.return_value = {"blocked": False, "layers": {}, "status": "pass"}
        mock_cmd.return_value = (0, "", "")

        args = Namespace(
            model=MODEL_NAME,
            profile_json=None,
            grain_columns=None,
            force=False,
            hk=None,
        )

        with pytest.raises(ValueError, match="renamed to"):
            cmd_profile(args)


# ---------------------------------------------------------------------------
# Test 3: has_secondary utility
# ---------------------------------------------------------------------------

class TestHasSecondary:
    def test_with_secondary(self):
        state = _profile_state()
        assert has_secondary(state) is True

    def test_without_secondary(self):
        assert has_secondary({}) is False
        assert has_secondary({"secondary": None}) is False

    def teardown_method(self):
        _cleanup_state(MODEL_NAME)


# ---------------------------------------------------------------------------
# Test 4: validate_bk_references_renamed_columns (unit level)
# ---------------------------------------------------------------------------

class TestBkRenameValidation:
    """Direct unit tests for validate_bk_references_renamed_columns."""

    def test_valid_bk_uses_renamed_column(self):
        """BK using the renamed alias passes validation."""
        state = {
            "secondary": {
                "bk": "FO_ID",
                "rename_map": {"ID": "FO_ID", "ORDER_NUMBER": "ORDER_NUMBER"},
                "collisions": ["ID"],
            }
        }
        validate_bk_references_renamed_columns(state)

    def test_bk_uses_original_colliding_name(self):
        """BK using original name that was renamed raises ValueError."""
        state = {
            "secondary": {
                "bk": "ID",
                "rename_map": {"ID": "FO_ID", "ORDER_NUMBER": "ORDER_NUMBER"},
                "collisions": ["ID"],
            }
        }
        with pytest.raises(ValueError, match="renamed to"):
            validate_bk_references_renamed_columns(state)

    def test_no_secondary_is_noop(self):
        """Without secondary block, validation is a no-op."""
        validate_bk_references_renamed_columns({})
        validate_bk_references_renamed_columns({"secondary": None})

    def test_no_bk_is_noop(self):
        """Without secondary.bk, validation is a no-op."""
        state = {
            "secondary": {
                "bk": None,
                "rename_map": {"ID": "FO_ID"},
                "collisions": ["ID"],
            }
        }
        validate_bk_references_renamed_columns(state)
