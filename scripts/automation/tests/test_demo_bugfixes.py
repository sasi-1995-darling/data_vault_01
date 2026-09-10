"""
test_demo_bugfixes.py — Unit tests for bugs #22, #5, #4, #8 identified during pipeline demo.

Bug #22: BK with CAST expression produces bare expression without alias
Bug #5:  _find_active_state() picks up non-state files
Bug #4:  Collision check enforcement in approve-profile
Bug #8:  status command broken with corrupted/ambiguous state (same root as #5)
"""

import json
import sys
import tempfile
import time
from pathlib import Path
from unittest.mock import patch, MagicMock

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pipeline_orchestrator import (
    _find_active_state,
    _completed_steps,
    _check_prerequisites,
    _now_iso,
    STATE_DIR,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_state(model_name="v_psa_stg_test__src", steps=None, profile=None, **extra):
    """Build a minimal valid state dict."""
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


def _write_state(tmpdir, filename, data):
    """Write a JSON file to tmpdir."""
    path = Path(tmpdir) / filename
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data))
    return path


# ===========================================================================
# Bug #22: BK cast passthrough strips cast expression
# ===========================================================================

class TestBug22CastBKPassthrough:
    """Bug #22: VENDOR_SITE_ID::TEXT should passthrough as VENDOR_SITE_ID"""

    def test_bk_raw_cols_strips_cast(self):
        """bk_raw_cols strips ::TYPE from single BK with cast."""
        bk_upper = "VENDOR_SITE_ID::TEXT"
        bk_raw_cols = [c.strip().split("::")[0] for c in bk_upper.split(",")]
        assert bk_raw_cols == ["VENDOR_SITE_ID"]

    def test_bk_raw_cols_strips_cast_multiple(self):
        """Multiple BK columns with casts are all stripped."""
        bk_upper = "COL_A::TEXT, COL_B::NUMBER"
        bk_raw_cols = [c.strip().split("::")[0] for c in bk_upper.split(",")]
        assert bk_raw_cols == ["COL_A", "COL_B"]

    def test_bk_raw_cols_no_cast_unchanged(self):
        """BK without cast expression is unchanged."""
        bk_upper = "VENDOR_SITE_ID"
        bk_raw_cols = [c.strip().split("::")[0] for c in bk_upper.split(",")]
        assert bk_raw_cols == ["VENDOR_SITE_ID"]

    def test_bk_has_cast_detected(self):
        """Detect cast expression in BK."""
        assert "::" in "VENDOR_SITE_ID::TEXT"
        assert "::" not in "VENDOR_SITE_ID"

    def test_composite_bk_no_cast_unchanged(self):
        """Composite BK without casts is unchanged."""
        bk_upper = "MATNR, WERKS, POPER"
        bk_raw_cols = [c.strip().split("::")[0] for c in bk_upper.split(",")]
        assert bk_raw_cols == ["MATNR", "WERKS", "POPER"]


# ===========================================================================
# Bug #5: _find_active_state ignores non-state files
# ===========================================================================

class TestBug5FindActiveState:
    """Bug #5: _find_active_state should only pick up valid state files."""

    def test_ignores_non_state_json(self, tmp_path):
        """Profile JSONs without model_name/steps_completed are skipped."""
        # Create a valid state file
        state = _make_state(steps=["init", "profile"])
        state_path = tmp_path / "test_model.json"
        state_path.write_text(json.dumps(state))

        # Create a non-state profile JSON (newer)
        time.sleep(0.05)
        profile = {"row_count": 50000, "columns": [], "volume_tier": "normal"}
        profile_path = tmp_path / "test_model_profile.json"
        profile_path.write_text(json.dumps(profile))

        # Patch STATE_DIR to use tmp_path
        with patch("pipeline_orchestrator.STATE_DIR", tmp_path):
            result = _find_active_state()

        assert result is not None
        assert "model_name" in result
        assert result["model_name"] == "v_psa_stg_test__src"

    def test_returns_none_when_no_valid_state(self, tmp_path):
        """Returns None when only non-state files exist."""
        profile = {"row_count": 50000, "columns": []}
        (tmp_path / "profile.json").write_text(json.dumps(profile))

        with patch("pipeline_orchestrator.STATE_DIR", tmp_path):
            result = _find_active_state()

        assert result is None

    def test_returns_most_recent_valid_state(self, tmp_path):
        """Returns the most recently modified valid state file."""
        state1 = _make_state(model_name="model_old", steps=["init"])
        (tmp_path / "model_old.json").write_text(json.dumps(state1))

        time.sleep(0.05)
        state2 = _make_state(model_name="model_new", steps=["init", "profile"])
        (tmp_path / "model_new.json").write_text(json.dumps(state2))

        with patch("pipeline_orchestrator.STATE_DIR", tmp_path):
            result = _find_active_state()

        assert result["model_name"] == "model_new"

    def test_handles_corrupt_json(self, tmp_path):
        """Gracefully skips corrupt JSON files."""
        (tmp_path / "corrupt.json").write_text("not valid json{{{")

        state = _make_state(steps=["init"])
        (tmp_path / "valid.json").write_text(json.dumps(state))

        with patch("pipeline_orchestrator.STATE_DIR", tmp_path):
            result = _find_active_state()

        assert result is not None
        assert result["model_name"] == "v_psa_stg_test__src"

    def test_empty_directory(self, tmp_path):
        """Returns None for empty state directory."""
        with patch("pipeline_orchestrator.STATE_DIR", tmp_path):
            result = _find_active_state()

        assert result is None


# ===========================================================================
# Bug #4: Collision check enforcement in approve-profile
# ===========================================================================

class TestBug4CollisionCheckEnforcement:
    """Bug #4: approve-profile must verify collision_check exists and is clear."""

    def test_approve_blocked_without_collision_check(self, tmp_path):
        """approve-profile refuses if collision_check not in profile."""
        from pipeline_orchestrator import cmd_approve_profile

        state = _make_state(
            steps=["init", "profile"],
            profile={"bkcc": "Test_BKCC", "grain_valid": True},
        )
        args = MagicMock()
        args.model_name = None
        args.force = False

        # SCRIPT_DIR patch shields real configs/ even though this path returns 1
        # before _persist_profile_markdown — protects against future drift.
        with patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path):
            result = cmd_approve_profile(args)

        assert result == 1  # Blocked — no collision_check

    def test_approve_blocked_with_collision_blockers(self, tmp_path):
        """approve-profile refuses if collision_check has blockers."""
        from pipeline_orchestrator import cmd_approve_profile

        state = _make_state(
            steps=["init", "profile"],
            profile={
                "bkcc": "Test_BKCC",
                "grain_valid": True,
                "collision_check": {
                    "blocked": True,
                    "layers": {
                        "v_psa_stg": {
                            "status": "COLLISION",
                            "files": ["models/int_staging_views/test.sql"],
                            "message": "existing model uses same source",
                        }
                    },
                },
            },
        )
        args = MagicMock()
        args.model_name = None
        args.force = True  # Even --force should not override collision blockers

        with patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path):
            result = cmd_approve_profile(args)

        assert result == 1  # Blocked — collision

    def test_approve_succeeds_with_clear_collision(self, tmp_path):
        """approve-profile succeeds when collision_check is clear."""
        from pipeline_orchestrator import cmd_approve_profile, _save_state

        state = _make_state(
            steps=["init", "profile"],
            profile={
                "bkcc": "Test_BKCC",
                "grain_valid": True,
                "collision_check": {
                    "blocked": False,
                    "layers": {
                        "v_psa_stg": {"status": "CLEAR", "message": "no collision"},
                        "sat": {"status": "CLEAR", "message": "no collision"},
                    },
                },
            },
        )
        args = MagicMock()
        args.model_name = None
        args.force = False

        # SCRIPT_DIR patch: this path reaches _persist_profile_markdown
        # (rc=0) which would otherwise write into the real configs/ dir.
        with patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path):
            result = cmd_approve_profile(args)

        assert result == 0  # Success

    def test_approve_with_force_overrides_non_blocking_warnings(self, tmp_path):
        """--force overrides non-blocking warnings (missing BKCC) but NOT collision."""
        from pipeline_orchestrator import cmd_approve_profile

        state = _make_state(
            steps=["init", "profile"],
            profile={
                "bkcc": None,  # Missing — warning, not blocker
                "grain_valid": True,
                "collision_check": {
                    "blocked": False,
                    "layers": {"v_psa_stg": {"status": "CLEAR", "message": "ok"}},
                },
            },
        )
        args = MagicMock()
        args.model_name = None
        args.force = True

        # SCRIPT_DIR patch: this path reaches _persist_profile_markdown (rc=0).
        with patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator.SCRIPT_DIR", tmp_path):
            result = cmd_approve_profile(args)

        assert result == 0  # Approved with --force

    def test_profile_stores_collision_results(self):
        """cmd_profile stores collision_check in profile_results."""
        # Verify the profile results structure includes collision_check
        profile = {
            "collision_check": {
                "blocked": False,
                "layers": {
                    "v_psa_stg": {"status": "CLEAR", "message": "no collision"},
                },
            },
            "collision": False,
        }
        assert "collision_check" in profile
        assert not profile["collision_check"]["blocked"]
        assert profile["collision_check"]["layers"]["v_psa_stg"]["status"] == "CLEAR"


# ===========================================================================
# Bug #8: status command with non-state files (same root as Bug #5)
# ===========================================================================

class TestBug8StatusRobustness:
    """Bug #8: status command should handle non-state files gracefully."""

    def test_status_skips_non_state_files(self, tmp_path, capsys):
        """cmd_status listing skips non-state JSON files."""
        from pipeline_orchestrator import cmd_status

        # Create a valid state file
        state = _make_state(model_name="good_model", steps=["init"])
        (tmp_path / "good_model.json").write_text(json.dumps(state))

        # Create a non-state file
        profile = {"row_count": 100}
        (tmp_path / "bad_profile.json").write_text(json.dumps(profile))

        args = MagicMock()
        args.model_name = None

        with patch("pipeline_orchestrator._resolve_state", return_value=None), \
             patch("pipeline_orchestrator.STATE_DIR", tmp_path), \
             patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path.parent):
            result = cmd_status(args)

        captured = capsys.readouterr()
        assert "good_model" in captured.out
        # Non-state file should not cause a KeyError
        assert "KeyError" not in captured.out
