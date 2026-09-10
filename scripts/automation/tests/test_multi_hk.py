"""
test_multi_hk.py — Tests for Multi-HK support (Phase 1 + Phase 2).

Covers:
  1. init with multiple --hk stores all definitions
  2. init without --hk → empty hash_keys (backward compat)
  3. profile --hk updates state
  4. show-profile displays HK definitions
  5. show-profile hides HK section when empty
  6. invalid --hk format rejected
  7. HK without BKCC warns for hub HK
  8. LNK HK without BKCC does NOT warn

Phase 2:
  9. generate-yaml includes HK columns from hash_keys
  10. generate-yaml deduplicates HK matching driver BK
  11. generate-yaml no HK columns when hash_keys empty (backward compat)
  12. add-raw-vault assigns hub/link types to hash_keys
  13. add-raw-vault explicit --sat-parent-hk takes precedence
"""

import json
import sys
import io
from argparse import Namespace
from pathlib import Path
from unittest.mock import patch, MagicMock

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pipeline_orchestrator import (
    cmd_init,
    cmd_profile,
    cmd_show_profile,
    cmd_generate_yaml,
    cmd_add_raw_vault,
    _now_iso,
    _save_state,
    _mark_complete,
    _completed_steps,
    _semantic_collision_check,
    STATE_DIR,
    SCRIPT_DIR,
    PROJECT_ROOT,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_state(model_name="v_psa_stg_test__hk", steps=None, hash_keys=None, **extra):
    """Build a minimal valid state dict for HK testing."""
    state = {
        "model_name": model_name,
        "schema": "test_schema",
        "table": "test_table",
        "bk": "ID",
        "bk_name": "TEST_BK",
        "rec_src": "US.TEST.APP.TABLE",
        "objects": ["stg"],
        "created_at": _now_iso(),
        "steps_completed": [],
        "profile_results": {},
        "config_path": "",
        "xlsx_path": "",
        "xlsx_validation": {},
        "generated_files": {},
        "stage3_results": {},
        "hash_keys": hash_keys or [],
    }
    if steps:
        for step in steps:
            state["steps_completed"].append({"step": step, "completed_at": _now_iso()})
    state.update(extra)
    return state


def _write_state(state):
    """Write state to pipeline state directory."""
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    state_file = STATE_DIR / f"{state['model_name']}.json"
    state_file.write_text(json.dumps(state, indent=2, default=str))
    return state_file


def _cleanup_state(model_name):
    """Remove state file after test."""
    state_file = STATE_DIR / f"{model_name}.json"
    if state_file.exists():
        state_file.unlink()


# ---------------------------------------------------------------------------
# Test 1: init with multiple --hk stores all definitions
# ---------------------------------------------------------------------------

def test_init_multi_hk_stored_in_state():
    model_name = "v_psa_stg_test_multi_hk__t1"
    try:
        args = Namespace(
            model_name=model_name,
            schema="test_schema",
            table="test_table",
            bk="ID",
            bk_name="TEST_BK",
            rec_src="US.TEST.APP.TABLE",
            objects="stg",
            force=True,
            hk=[
                "SUBSCRIPTION_HK:ID,BKCC",
                "SUBSCRIBER_HK:SUBSCRIBER_ID,BKCC",
                "LNK_SUBSCRIBER_SUBSCRIPTION_HK:SUBSCRIBER_ID,ID,BKCC",
            ],
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
            secondary_schema=None,
            secondary_table=None,
            secondary_alias=None,
            secondary_join_type=None,
            secondary_columns=None,
            sec_bk=None,
            sec_bk_name=None,
            sec_bk_expr=None,
            sec_join_key=None,
            sec_parent_join_key=None,
        )
        rc = cmd_init(args)
        assert rc == 0

        state_file = STATE_DIR / f"{model_name}.json"
        state = json.loads(state_file.read_text())

        assert "hash_keys" in state
        assert len(state["hash_keys"]) == 3

        hk0 = state["hash_keys"][0]
        assert hk0["name"] == "SUBSCRIPTION_HK"
        assert hk0["columns"] == ["ID", "BKCC"]
        assert hk0["type"] is None

        hk1 = state["hash_keys"][1]
        assert hk1["name"] == "SUBSCRIBER_HK"
        assert hk1["columns"] == ["SUBSCRIBER_ID", "BKCC"]

        hk2 = state["hash_keys"][2]
        assert hk2["name"] == "LNK_SUBSCRIBER_SUBSCRIPTION_HK"
        assert hk2["columns"] == ["SUBSCRIBER_ID", "ID", "BKCC"]
    finally:
        _cleanup_state(model_name)


# ---------------------------------------------------------------------------
# Test 2: init without --hk → empty hash_keys (backward compat)
# ---------------------------------------------------------------------------

def test_init_no_hk_backward_compat():
    model_name = "v_psa_stg_test_no_hk__t2"
    try:
        args = Namespace(
            model_name=model_name,
            schema="test_schema",
            table="test_table",
            bk="ID",
            bk_name="TEST_BK",
            rec_src="US.TEST.APP.TABLE",
            objects="stg",
            force=True,
            hk=[],
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
            secondary_schema=None,
            secondary_table=None,
            secondary_alias=None,
            secondary_join_type=None,
            secondary_columns=None,
            sec_bk=None,
            sec_bk_name=None,
            sec_bk_expr=None,
            sec_join_key=None,
            sec_parent_join_key=None,
        )
        rc = cmd_init(args)
        assert rc == 0

        state_file = STATE_DIR / f"{model_name}.json"
        state = json.loads(state_file.read_text())

        assert state["hash_keys"] == []
    finally:
        _cleanup_state(model_name)


# ---------------------------------------------------------------------------
# Test 3: profile --hk updates state
# ---------------------------------------------------------------------------

def test_profile_hk_updates_state():
    model_name = "v_psa_stg_test_profile_hk__t3"
    try:
        # Create state with init completed but no hash_keys
        state = _make_state(model_name=model_name, steps=["init"], hash_keys=[])
        _write_state(state)

        args = Namespace(
            model_name=model_name,
            hk=["ITEM_HK:ITEM_ID,BKCC", "LNK_ORDER_ITEM_HK:ORDER_ID,ITEM_ID,BKCC"],
            profile_json=None,
            snowflake_conn=None,
            grain_columns=None,
        )

        # Mock _run_snowflake_query to simulate profiling without actual connection
        with patch("pipeline_orchestrator._run_snowflake_query") as mock_query, \
             patch("pipeline_orchestrator._semantic_collision_check") as mock_collision, \
             patch("pipeline_orchestrator._run_command") as mock_cmd:

            mock_collision.return_value = {"blocked": False, "layers": {}}
            # Simulate columns query
            mock_query.side_effect = [
                # Step 2: columns
                [("ID", "NUMBER", "NO"), ("ITEM_ID", "NUMBER", "NO"),
                 ("ORDER_ID", "NUMBER", "YES"), ("NAME", "TEXT", "YES"),
                 ("_FIVETRAN_SYNCED", "TIMESTAMP_TZ", "YES"),
                 ("_FIVETRAN_DELETED", "BOOLEAN", "YES"),
                 ("PSA_DELETE_IND", "TEXT", "YES"),
                 ("PSA_LOAD_DTS", "TIMESTAMP_NTZ", "YES")],
                # Step 3: sample
                [("row1",)],
                # Step 4: count
                [(100,)],
                # Step 5: grain
                [(100, 100)],
                # Step 6: null BK
                [(0,)],
                # Step 8: BKCC
                [("TestBKCC",)],
            ]
            mock_cmd.return_value = (0, "matched", "")

            rc = cmd_profile(args)

        # Reload state and verify hash_keys were persisted
        updated = json.loads((STATE_DIR / f"{model_name}.json").read_text())
        assert len(updated["hash_keys"]) == 2
        assert updated["hash_keys"][0]["name"] == "ITEM_HK"
        assert updated["hash_keys"][0]["columns"] == ["ITEM_ID", "BKCC"]
        assert updated["hash_keys"][1]["name"] == "LNK_ORDER_ITEM_HK"
    finally:
        _cleanup_state(model_name)


# ---------------------------------------------------------------------------
# Test 4: show-profile displays HK definitions
# ---------------------------------------------------------------------------

def test_show_profile_displays_hash_keys(capsys):
    model_name = "v_psa_stg_test_show_hk__t4"
    try:
        state = _make_state(
            model_name=model_name,
            steps=["init", "profile"],
            hash_keys=[
                {"name": "SUBSCRIPTION_HK", "columns": ["ID", "BKCC"], "type": None},
                {"name": "LNK_SUB_HK", "columns": ["SUB_ID", "ID", "BKCC"], "type": "link"},
            ],
            profile_results={
                "row_count": 100,
                "volume_tier": "normal",
                "column_count": 10,
                "null_bk_count": 0,
                "grain_valid": True,
                "bkcc": "TestBKCC",
                "ingestion_source": "fivetran",
                "source_registered": True,
                "has_fivetran_deleted": True,
                "has_psa_delete_ind": False,
                "collision_check": {"blocked": False, "layers": {}},
            },
        )
        _write_state(state)

        args = Namespace(model_name=model_name)
        rc = cmd_show_profile(args)
        assert rc == 0

        captured = capsys.readouterr(); output = captured.out + captured.err
        assert "Hash Keys:" in output
        assert "SUBSCRIPTION_HK = MD5(ID, BKCC)" in output
        assert "LNK_SUB_HK = MD5(SUB_ID, ID, BKCC) → link" in output
    finally:
        _cleanup_state(model_name)


# ---------------------------------------------------------------------------
# Test 5: show-profile hides HK section when empty
# ---------------------------------------------------------------------------

def test_show_profile_no_hk_section_when_empty(capsys):
    model_name = "v_psa_stg_test_no_hk_show__t5"
    try:
        state = _make_state(
            model_name=model_name,
            steps=["init", "profile"],
            hash_keys=[],
            profile_results={
                "row_count": 50,
                "volume_tier": "normal",
                "column_count": 5,
                "null_bk_count": 0,
                "grain_valid": True,
                "bkcc": "TestBKCC",
                "ingestion_source": "fivetran",
                "source_registered": True,
                "has_fivetran_deleted": False,
                "has_psa_delete_ind": False,
                "collision_check": {"blocked": False, "layers": {}},
            },
        )
        _write_state(state)

        args = Namespace(model_name=model_name)
        rc = cmd_show_profile(args)
        assert rc == 0

        captured = capsys.readouterr(); output = captured.out + captured.err
        assert "Hash Keys:" not in output
    finally:
        _cleanup_state(model_name)


# ---------------------------------------------------------------------------
# Test 6: invalid --hk format rejected
# ---------------------------------------------------------------------------

def test_init_invalid_hk_format_rejected(capsys):
    model_name = "v_psa_stg_test_bad_hk__t6"
    try:
        args = Namespace(
            model_name=model_name,
            schema="test_schema",
            table="test_table",
            bk="ID",
            bk_name="TEST_BK",
            rec_src="US.TEST.APP.TABLE",
            objects="stg",
            force=True,
            hk=["BADFORMAT_NO_COLON"],
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
            secondary_schema=None,
            secondary_table=None,
            secondary_alias=None,
            secondary_join_type=None,
            secondary_columns=None,
            sec_bk=None,
            sec_bk_name=None,
            sec_bk_expr=None,
            sec_join_key=None,
            sec_parent_join_key=None,
        )
        rc = cmd_init(args)
        assert rc == 1

        captured = capsys.readouterr(); output = captured.out + captured.err
        assert "Invalid --hk format" in output
    finally:
        _cleanup_state(model_name)


# ---------------------------------------------------------------------------
# Test 6b: invalid --hk identifier name rejected in profile
# ---------------------------------------------------------------------------

def test_profile_hk_invalid_name_rejected(capsys):
    model_name = "v_psa_stg_test_bad_hk_name__t6b"
    try:
        state = _make_state(model_name=model_name, steps=["init"], hash_keys=[])
        _write_state(state)

        args = Namespace(
            model_name=model_name,
            hk=["DROP TABLE:COL1,BKCC"],  # invalid: spaces in HK name
            profile_json=None,
            snowflake_conn=None,
            grain_columns=None,
        )

        rc = cmd_profile(args)
        assert rc == 1

        captured = capsys.readouterr(); output = captured.out + captured.err
        assert "Invalid HK name" in output
    finally:
        _cleanup_state(model_name)


# ---------------------------------------------------------------------------
# Test 6c: invalid --hk column identifier rejected in profile
# ---------------------------------------------------------------------------

def test_profile_hk_invalid_column_rejected(capsys):
    model_name = "v_psa_stg_test_bad_hk_col__t6c"
    try:
        state = _make_state(model_name=model_name, steps=["init"], hash_keys=[])
        _write_state(state)

        args = Namespace(
            model_name=model_name,
            hk=["VALID_HK:COL1; DROP TABLE,BKCC"],  # invalid: semicolon in column
            profile_json=None,
            snowflake_conn=None,
            grain_columns=None,
        )

        rc = cmd_profile(args)
        assert rc == 1

        captured = capsys.readouterr(); output = captured.out + captured.err
        assert "Invalid HK column" in output
    finally:
        _cleanup_state(model_name)


# ---------------------------------------------------------------------------
# Test 7: HK without BKCC warns for hub HK
# ---------------------------------------------------------------------------

def test_init_hub_hk_without_bkcc_warns(capsys):
    model_name = "v_psa_stg_test_hk_warn__t7"
    try:
        args = Namespace(
            model_name=model_name,
            schema="test_schema",
            table="test_table",
            bk="ID",
            bk_name="TEST_BK",
            rec_src="US.TEST.APP.TABLE",
            objects="stg",
            force=True,
            hk=["ITEM_HK:ITEM_ID,ANOTHER_COL"],  # no BKCC
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
            secondary_schema=None,
            secondary_table=None,
            secondary_alias=None,
            secondary_join_type=None,
            secondary_columns=None,
            sec_bk=None,
            sec_bk_name=None,
            sec_bk_expr=None,
            sec_join_key=None,
            sec_parent_join_key=None,
        )
        rc = cmd_init(args)
        assert rc == 0

        captured = capsys.readouterr(); output = captured.out + captured.err
        assert "does not include BKCC" in output
    finally:
        _cleanup_state(model_name)


# ---------------------------------------------------------------------------
# Test 8: LNK HK without BKCC does NOT warn
# ---------------------------------------------------------------------------

def test_init_link_hk_without_bkcc_no_warn(capsys):
    model_name = "v_psa_stg_test_lnk_hk__t8"
    try:
        args = Namespace(
            model_name=model_name,
            schema="test_schema",
            table="test_table",
            bk="ID",
            bk_name="TEST_BK",
            rec_src="US.TEST.APP.TABLE",
            objects="stg",
            force=True,
            hk=["LNK_ITEM_ORDER_HK:ITEM_ID,ORDER_ID"],  # LNK prefix, no BKCC — should NOT warn
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
            secondary_schema=None,
            secondary_table=None,
            secondary_alias=None,
            secondary_join_type=None,
            secondary_columns=None,
            sec_bk=None,
            sec_bk_name=None,
            sec_bk_expr=None,
            sec_join_key=None,
            sec_parent_join_key=None,
        )
        rc = cmd_init(args)
        assert rc == 0

        captured = capsys.readouterr(); output = captured.out + captured.err
        assert "does not include BKCC" not in output
    finally:
        _cleanup_state(model_name)


# ===========================================================================
# Phase 2 Tests: generate-yaml + add-raw-vault
# ===========================================================================

def _make_profiled_state(model_name="v_psa_stg_test__hk_p2", hash_keys=None, **extra):
    """Build state with profile complete + sample columns for generate-yaml testing."""
    state = _make_state(
        model_name=model_name,
        steps=["init", "profile", "approve-profile"],
        hash_keys=hash_keys,
        profile_results={
            "row_count": 100,
            "volume_tier": "normal",
            "column_count": 5,
            "null_bk_count": 0,
            "grain_valid": True,
            "bkcc": "TestBKCC",
            "ingestion_source": "fivetran",
            "source_registered": True,
            "has_fivetran_deleted": True,
            "has_psa_delete_ind": True,
            "has_fivetran_synced": True,
            "has_fivetran_id": True,
            "collision_check": {"blocked": False, "layers": {}},
            "columns": [
                {"name": "ID", "type": "NUMBER", "nullable": "NO"},
                {"name": "SUBSCRIBER_ID", "type": "NUMBER", "nullable": "YES"},
                {"name": "NAME", "type": "TEXT", "nullable": "YES"},
                {"name": "STATUS", "type": "TEXT", "nullable": "YES"},
                {"name": "_FIVETRAN_SYNCED", "type": "TIMESTAMP_TZ", "nullable": "YES"},
                {"name": "_FIVETRAN_DELETED", "type": "BOOLEAN", "nullable": "YES"},
                {"name": "_FIVETRAN_ID", "type": "TEXT", "nullable": "YES"},
                {"name": "PSA_DELETE_IND", "type": "TEXT", "nullable": "YES"},
                {"name": "PSA_LOAD_DTS", "type": "TIMESTAMP_NTZ", "nullable": "YES"},
                {"name": "PSA_RECORD_SOURCE", "type": "TEXT", "nullable": "YES"},
            ],
        },
        **extra,
    )
    return state


# ---------------------------------------------------------------------------
# Test 9: generate-yaml includes HK columns from hash_keys
# ---------------------------------------------------------------------------

def test_generate_yaml_includes_hk_columns():
    model_name = "v_psa_stg_test_yaml_hk__t9"
    try:
        state = _make_profiled_state(
            model_name=model_name,
            hash_keys=[
                {"name": "SUBSCRIPTION_HK", "columns": ["ID", "BKCC"], "type": None},
                {"name": "SUBSCRIBER_HK", "columns": ["SUBSCRIBER_ID", "BKCC"], "type": None},
                {"name": "LNK_SUB_HK", "columns": ["SUBSCRIBER_ID", "ID", "BKCC"], "type": None},
            ],
        )
        _write_state(state)

        args = Namespace(model_name=model_name, bk_cast=None, bk_cast_type=None)
        rc = cmd_generate_yaml(args)
        assert rc == 0

        # Read generated YAML
        import yaml
        config_name = model_name.replace("v_psa_stg_", "")
        config_path = SCRIPT_DIR / "configs" / f"{config_name}.yml"
        assert config_path.exists(), f"YAML not found at {config_path}"

        with open(config_path) as f:
            config = yaml.safe_load(f)

        columns = config["models"][0]["columns"]
        hk_cols = [c for c in columns if c.get("staging_column_name", "").endswith("_HK")]

        # Should have 3 HKs: TEST_HK (auto from BK) + SUBSCRIPTION_HK + LNK_SUB_HK
        # SUBSCRIBER_HK would be auto-generated as the driver HK (TEST_BK -> TEST_HK)
        # Wait - BK name is TEST_BK so auto HK is TEST_HK, and all 3 user HKs are additional
        hk_names = [c["staging_column_name"] for c in hk_cols]
        assert "TEST_HK" in hk_names, f"Driver HK 'TEST_HK' missing. Got: {hk_names}"
        assert "SUBSCRIPTION_HK" in hk_names, f"SUBSCRIPTION_HK missing. Got: {hk_names}"
        assert "SUBSCRIBER_HK" in hk_names, f"SUBSCRIBER_HK missing. Got: {hk_names}"
        assert "LNK_SUB_HK" in hk_names, f"LNK_SUB_HK missing. Got: {hk_names}"

        # Verify HASH formula content
        sub_hk = next(c for c in hk_cols if c["staging_column_name"] == "SUBSCRIPTION_HK")
        assert "HASH: ID, BKCC" in sub_hk["manual_logic"]

        lnk_hk = next(c for c in hk_cols if c["staging_column_name"] == "LNK_SUB_HK")
        assert "HASH: SUBSCRIBER_ID, ID, BKCC" in lnk_hk["manual_logic"]

        # Cleanup config file
        config_path.unlink(missing_ok=True)
    finally:
        _cleanup_state(model_name)


# ---------------------------------------------------------------------------
# Test 10: generate-yaml deduplicates HK matching driver BK
# ---------------------------------------------------------------------------

def test_generate_yaml_deduplicates_driver_hk():
    model_name = "v_psa_stg_test_yaml_dedup__t10"
    try:
        state = _make_profiled_state(
            model_name=model_name,
            hash_keys=[
                # TEST_HK matches what auto-generation would produce (TEST_BK -> TEST_HK)
                {"name": "TEST_HK", "columns": ["ID", "BKCC"], "type": None},
                {"name": "EXTRA_HK", "columns": ["SUBSCRIBER_ID", "BKCC"], "type": None},
            ],
        )
        _write_state(state)

        args = Namespace(model_name=model_name, bk_cast=None, bk_cast_type=None)
        rc = cmd_generate_yaml(args)
        assert rc == 0

        import yaml
        config_name = model_name.replace("v_psa_stg_", "")
        config_path = SCRIPT_DIR / "configs" / f"{config_name}.yml"
        with open(config_path) as f:
            config = yaml.safe_load(f)

        columns = config["models"][0]["columns"]
        hk_cols = [c for c in columns if c.get("staging_column_name", "").endswith("_HK")]
        hk_names = [c["staging_column_name"] for c in hk_cols]

        # TEST_HK should appear exactly once (deduped), EXTRA_HK should be added
        assert hk_names.count("TEST_HK") == 1, f"TEST_HK duplicated: {hk_names}"
        assert "EXTRA_HK" in hk_names, f"EXTRA_HK missing: {hk_names}"

        config_path.unlink(missing_ok=True)
    finally:
        _cleanup_state(model_name)


# ---------------------------------------------------------------------------
# Test 11: generate-yaml no HK columns when hash_keys empty (backward compat)
# ---------------------------------------------------------------------------

def test_generate_yaml_no_hk_when_empty():
    model_name = "v_psa_stg_test_yaml_nohk__t11"
    try:
        state = _make_profiled_state(model_name=model_name, hash_keys=[])
        _write_state(state)

        args = Namespace(model_name=model_name, bk_cast=None, bk_cast_type=None)
        rc = cmd_generate_yaml(args)
        assert rc == 0

        import yaml
        config_name = model_name.replace("v_psa_stg_", "")
        config_path = SCRIPT_DIR / "configs" / f"{config_name}.yml"
        with open(config_path) as f:
            config = yaml.safe_load(f)

        columns = config["models"][0]["columns"]
        hk_cols = [c for c in columns if c.get("staging_column_name", "").endswith("_HK")]

        # Only the auto-generated driver HK should exist (TEST_HK from TEST_BK)
        hk_names = [c["staging_column_name"] for c in hk_cols]
        assert hk_names == ["TEST_HK"], f"Expected only TEST_HK, got: {hk_names}"

        config_path.unlink(missing_ok=True)
    finally:
        _cleanup_state(model_name)


# ---------------------------------------------------------------------------
# Test 12: add-raw-vault assigns hub/link types to hash_keys
# ---------------------------------------------------------------------------

def test_add_raw_vault_assigns_hk_types():
    model_name = "v_psa_stg_test_arv_hk__t12"
    try:
        state = _make_profiled_state(
            model_name=model_name,
            hash_keys=[
                {"name": "ITEM_HK", "columns": ["ID", "BKCC"], "type": None},
                {"name": "LNK_ITEM_ORDER_HK", "columns": ["ID", "ORDER_ID", "BKCC"], "type": None},
            ],
        )
        # add-raw-vault requires approve-xlsx to be completed
        state["steps_completed"].append({"step": "generate-yaml", "completed_at": _now_iso()})
        state["steps_completed"].append({"step": "generate-xlsx", "completed_at": _now_iso()})
        state["steps_completed"].append({"step": "approve-xlsx", "completed_at": _now_iso()})
        state["xlsx_validation"] = {"all_passed": True}
        state["xlsx_path"] = "mappings/dummy.xlsx"
        _write_state(state)

        args = Namespace(
            model_name=model_name,
            objects="hub,sat",
            hub_name=None,
            lnk_name=None,
            parent_hks=None,
            dck=None,
            sat_type="sat",
            sat_parent_hk="ITEM_HK",
            sat_parent_model="hub_test",
            multi_active_key=None,
            sat_name=None,
            grain_columns=None,
            sat_columns=None,
        )

        with patch("pipeline_orchestrator._semantic_collision_check") as mock_collision:
            mock_collision.return_value = {"blocked": False, "layers": {}}
            rc = cmd_add_raw_vault(args)

        assert rc == 0

        # Reload state and verify types assigned
        updated = json.loads((STATE_DIR / f"{model_name}.json").read_text())
        hks = updated["hash_keys"]
        item_hk = next(h for h in hks if h["name"] == "ITEM_HK")
        lnk_hk = next(h for h in hks if h["name"] == "LNK_ITEM_ORDER_HK")

        assert item_hk["type"] == "hub", f"Expected hub, got {item_hk['type']}"
        # LNK type not set because 'lnk' was not in objects
        assert lnk_hk["type"] is None, f"LNK type should be None when lnk not in objects"
    finally:
        _cleanup_state(model_name)


# ---------------------------------------------------------------------------
# Test 13: add-raw-vault explicit --sat-parent-hk takes precedence
# ---------------------------------------------------------------------------

def test_add_raw_vault_explicit_hk_precedence():
    model_name = "v_psa_stg_test_arv_explicit__t13"
    try:
        state = _make_profiled_state(
            model_name=model_name,
            hash_keys=[
                {"name": "AUTO_HK", "columns": ["ID", "BKCC"], "type": None},
            ],
        )
        state["steps_completed"].append({"step": "generate-yaml", "completed_at": _now_iso()})
        state["steps_completed"].append({"step": "generate-xlsx", "completed_at": _now_iso()})
        state["steps_completed"].append({"step": "approve-xlsx", "completed_at": _now_iso()})
        state["xlsx_validation"] = {"all_passed": True}
        state["xlsx_path"] = "mappings/dummy.xlsx"
        _write_state(state)

        args = Namespace(
            model_name=model_name,
            objects="hub,sat",
            hub_name=None,
            lnk_name=None,
            parent_hks=None,
            dck=None,
            sat_type="sat",
            sat_parent_hk="CUSTOM_EXPLICIT_HK",  # Explicit — should NOT be overridden
            sat_parent_model="hub_test",
            multi_active_key=None,
            sat_name=None,
            grain_columns=None,
            sat_columns=None,
        )

        with patch("pipeline_orchestrator._semantic_collision_check") as mock_collision:
            mock_collision.return_value = {"blocked": False, "layers": {}}
            rc = cmd_add_raw_vault(args)

        assert rc == 0

        updated = json.loads((STATE_DIR / f"{model_name}.json").read_text())
        sats = updated["sats"]
        assert len(sats) == 1
        # Explicit --sat-parent-hk takes precedence over auto-match
        assert sats[0]["parent_hk"] == "CUSTOM_EXPLICIT_HK"
    finally:
        _cleanup_state(model_name)
