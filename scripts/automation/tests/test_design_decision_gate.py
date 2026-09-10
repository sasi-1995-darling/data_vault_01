"""
test_design_decision_gate.py — Tests for the Raw Vault Design Decision gate.

Lesson #106: generate-code must require explicit design decision for STG-only pipelines.
When objects == ['stg'], generate-code refuses to run unless --stg-only flag is provided
or add-raw-vault was already run (setting state["design_decision"]).

6 test scenarios:
  1. STG-only pipeline, no --stg-only flag → sys.exit(1)
  2. STG-only pipeline, --stg-only flag → design_decision = "stg_only" in state, continues
  3. Pipeline with add-raw-vault already run → design_decision = "add_raw_vault", continues
  4. Non-STG pipeline (objects includes hub) → gate skipped entirely
  5. cmd_add_raw_vault records design_decision in state
  6. approve-xlsx prompt mentions --stg-only
"""

import json
import sys
import tempfile
from argparse import Namespace
from pathlib import Path
from unittest.mock import patch, MagicMock

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pipeline_orchestrator import (
    cmd_generate_code,
    cmd_add_raw_vault,
    _prompt_raw_vault_objects,
    _completed_steps,
    _now_iso,
    _save_state,
    STATE_DIR,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_state(model_name="v_psa_stg_test__src", steps=None, objects=None, **extra):
    """Build a minimal valid state dict for gate testing."""
    state = {
        "model_name": model_name,
        "schema": "test_schema",
        "table": "test_table",
        "bk": "TEST_COL",
        "bk_name": "TEST_BK",
        "rec_src": "TEST.SYS.APP.TABLE",
        "objects": objects or ["stg"],
        "created_at": _now_iso(),
        "steps_completed": [],
        "profile_results": {},
        "xlsx_validation": {"all_passed": True},
        "xlsx_path": "mappings/dummy.xlsx",
    }
    if steps:
        for step in steps:
            state["steps_completed"].append({"step": step, "completed_at": _now_iso()})
    state.update(extra)
    return state


def _write_state_file(state, tmpdir=None):
    """Write state to the pipeline state directory (or a temp dir)."""
    if tmpdir:
        state_file = Path(tmpdir) / f"{state['model_name']}.json"
    else:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        state_file = STATE_DIR / f"{state['model_name']}.json"
    state_file.parent.mkdir(parents=True, exist_ok=True)
    state_file.write_text(json.dumps(state, indent=2, default=str))
    return state_file


# ---------------------------------------------------------------------------
# Test 1: STG-only pipeline, no --stg-only flag → sys.exit(1)
# ---------------------------------------------------------------------------
class TestDesignDecisionGate:

    def test_stg_only_no_flag_blocks(self, tmp_path):
        """generate-code must exit(1) when objects=['stg'], no design_decision, no --stg-only."""
        state = _make_state(
            steps=["init", "profile", "approve-profile", "generate-yaml",
                   "generate-xlsx", "approve-xlsx"],
            objects=["stg"],
        )
        # No design_decision key in state
        assert "design_decision" not in state

        args = Namespace(model_name=state["model_name"], stg_only=False)

        with patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._check_prerequisites", return_value=(True, [])), \
             pytest.raises(SystemExit) as exc_info:
            cmd_generate_code(args)

        assert exc_info.value.code == 1

    # ---------------------------------------------------------------------------
    # Test 2: STG-only pipeline, --stg-only flag → records stg_only, continues
    # ---------------------------------------------------------------------------
    def test_stg_only_with_flag_passes(self, tmp_path):
        """generate-code with --stg-only sets design_decision='stg_only' and continues."""
        state = _make_state(
            steps=["init", "profile", "approve-profile", "generate-yaml",
                   "generate-xlsx", "approve-xlsx"],
            objects=["stg"],
        )
        assert "design_decision" not in state

        args = Namespace(model_name=state["model_name"], stg_only=True)

        # We need to mock past the gate but verify it sets design_decision.
        # The code generation itself will fail (no XLSX file), but the gate should pass.
        with patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._check_prerequisites", return_value=(True, [])), \
             patch("pipeline_orchestrator._save_state") as mock_save:
            # Will fail at xlsx_path check, but gate should have passed
            rc = cmd_generate_code(args)

        # Gate passed: design_decision was set
        assert state["design_decision"] == "stg_only"
        mock_save.assert_called_once_with(state)

    # ---------------------------------------------------------------------------
    # Test 3: add-raw-vault already run → design_decision='add_raw_vault', gate passes
    # ---------------------------------------------------------------------------
    def test_add_raw_vault_decision_passes_gate(self, tmp_path):
        """generate-code passes gate when design_decision='add_raw_vault' already set."""
        state = _make_state(
            steps=["init", "profile", "approve-profile", "generate-yaml",
                   "generate-xlsx", "approve-xlsx"],
            objects=["stg", "hub"],
            design_decision="add_raw_vault",
        )

        args = Namespace(model_name=state["model_name"], stg_only=False)

        with patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._check_prerequisites", return_value=(True, [])):
            # Will fail at xlsx_path check, but should NOT exit(1) at the gate
            rc = cmd_generate_code(args)

        # Gate was skipped (objects != ["stg"]) — no SystemExit
        assert rc == 1  # xlsx not found, but that's expected — gate passed

    # ---------------------------------------------------------------------------
    # Test 4: Non-STG pipeline (objects includes hub) → gate skipped
    # ---------------------------------------------------------------------------
    def test_non_stg_pipeline_skips_gate(self, tmp_path):
        """generate-code skips gate entirely when objects includes hub/sat/lnk."""
        state = _make_state(
            steps=["init", "profile", "approve-profile", "generate-yaml",
                   "generate-xlsx", "approve-xlsx"],
            objects=["stg", "hub", "sat"],
            # No design_decision — but gate should still be skipped
        )
        assert "design_decision" not in state

        args = Namespace(model_name=state["model_name"], stg_only=False)

        with patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._check_prerequisites", return_value=(True, [])):
            # Should NOT exit(1) — gate skipped because objects != ["stg"]
            rc = cmd_generate_code(args)

        # xlsx not found = rc 1, but no SystemExit = gate was skipped
        assert rc == 1
        assert "design_decision" not in state  # unchanged

    # ---------------------------------------------------------------------------
    # Test 5: cmd_add_raw_vault records design_decision='add_raw_vault'
    # ---------------------------------------------------------------------------
    def test_add_raw_vault_records_decision(self, tmp_path):
        """cmd_add_raw_vault must set state['design_decision'] = 'add_raw_vault'."""
        state = _make_state(
            steps=["init", "profile", "approve-profile", "generate-yaml",
                   "generate-xlsx", "approve-xlsx"],
            objects=["stg"],
        )
        assert "design_decision" not in state

        args = Namespace(
            model_name=state["model_name"],
            objects="hub,sat",
            lnk_name=None,
            parent_hks=None,
            dck=None,
            sat_type="sat",
            sat_parent_hk="TEST_HK",
            sat_parent_model="hub_test",
            multi_active_key=None,
            sat_name=None,
        )

        with patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state") as mock_save:
            rc = cmd_add_raw_vault(args)

        assert rc == 0
        assert state["design_decision"] == "add_raw_vault"
        assert "hub" in state["objects"]
        assert "sat" in state["objects"]
        mock_save.assert_called()

    # ---------------------------------------------------------------------------
    # Test 6: approve-xlsx prompt mentions --stg-only
    # ---------------------------------------------------------------------------
    def test_approve_xlsx_prompt_mentions_stg_only(self, capsys):
        """_prompt_raw_vault_objects output must include --stg-only flag."""
        state = _make_state(objects=["stg"])

        _prompt_raw_vault_objects(state)

        captured = capsys.readouterr()
        assert "--stg-only" in captured.out
        assert "generate-code --stg-only" in captured.out


# ---------------------------------------------------------------------------
# Test: design_decision='stg_only' persists — re-running generate-code works
# ---------------------------------------------------------------------------
class TestDesignDecisionPersistence:

    def test_stg_only_decision_persists(self):
        """Once design_decision='stg_only' is set, subsequent generate-code calls pass gate."""
        state = _make_state(
            steps=["init", "profile", "approve-profile", "generate-yaml",
                   "generate-xlsx", "approve-xlsx"],
            objects=["stg"],
            design_decision="stg_only",  # already set from previous --stg-only run
        )

        args = Namespace(model_name=state["model_name"], stg_only=False)

        with patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._check_prerequisites", return_value=(True, [])):
            # Gate should pass — design_decision is already set
            rc = cmd_generate_code(args)

        # xlsx not found = rc 1, but no SystemExit = gate passed
        assert rc == 1
        assert state["design_decision"] == "stg_only"
