"""
test_semantic_collision.py — Tests for semantic collision check in pipeline orchestrator.

Validates DV 2.x cardinality rules:
  - v_psa_stg: 1:1 with driver source → COLLISION if exists
  - SAT:       1:1 with v_psa_stg per source → COLLISION if exists
  - HUB:       many:1 → ADD-SOURCE if exists (informational, not blocking)
  - LNK:       many:1 → ADD-SOURCE if exists (informational, not blocking)
"""

import sys
import tempfile
from pathlib import Path
from unittest.mock import patch

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pipeline_orchestrator import (
    _semantic_collision_check,
    _print_collision_report,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _base_state(**overrides):
    """Return a minimal state dict for testing."""
    state = {
        "model_name": "v_psa_stg_product_cost__moen_sap",
        "schema": "moen_sap",
        "table": "z_keko",
        "bk": "PRODUCT_COST_BK",
        "bk_name": "PRODUCT_COST_BK",
        "rec_src": "USOHNO.SAP.ECCPRD.Z_KEKO",
        "objects": ["stg"],
    }
    state.update(overrides)
    return state


def _make_file(tmpdir, relpath, content=""):
    """Create a file under tmpdir with given relative path and content."""
    fpath = Path(tmpdir) / relpath
    fpath.parent.mkdir(parents=True, exist_ok=True)
    fpath.write_text(content)
    return fpath


# ---------------------------------------------------------------------------
# v_psa_stg collision tests
# ---------------------------------------------------------------------------

class TestStgCollision:

    def test_clear_when_no_existing_models(self, tmp_path):
        """No collision when int_staging_views has no matching models."""
        state = _base_state()
        # Create empty dir
        (tmp_path / "models" / "int_staging_views").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "sat").mkdir(parents=True)

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path):
            with patch("pipeline_orchestrator._run_command", return_value=(0, "", "")):
                result = _semantic_collision_check(state)

        assert result["layers"]["v_psa_stg"]["status"] == "CLEAR"
        assert result["blocked"] is False

    def test_collision_when_existing_model_uses_same_source(self, tmp_path):
        """COLLISION when an existing v_psa_stg uses the same schema+table as driver."""
        state = _base_state()
        (tmp_path / "models" / "int_staging_views").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "sat").mkdir(parents=True)

        existing = "models/int_staging_views/v_psa_stg_product_cost__moen_sap.sql"

        def mock_run_command(cmd, cwd=None, capture=True):
            if "int_staging_views" in cmd and "source(" in cmd:
                return (0, existing, "")
            if "z_keko" in cmd:
                return (0, existing, "")
            return (0, "", "")

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path):
            with patch("pipeline_orchestrator._run_command", side_effect=mock_run_command):
                result = _semantic_collision_check(state)

        assert result["layers"]["v_psa_stg"]["status"] == "COLLISION"
        assert result["blocked"] is True
        assert existing in result["layers"]["v_psa_stg"]["files"]

    def test_no_collision_when_schema_matches_but_table_does_not(self, tmp_path):
        """CLEAR when schema matches but table name grep returns no match."""
        state = _base_state()
        (tmp_path / "models" / "int_staging_views").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "sat").mkdir(parents=True)

        def mock_run_command(cmd, cwd=None, capture=True):
            if "int_staging_views" in cmd and "source(" in cmd:
                # Schema matches, returns a candidate
                return (0, "models/int_staging_views/v_psa_stg_other__moen_sap.sql", "")
            if "z_keko" in cmd:
                # But table doesn't match
                return (0, "", "")
            return (0, "", "")

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path):
            with patch("pipeline_orchestrator._run_command", side_effect=mock_run_command):
                result = _semantic_collision_check(state)

        assert result["layers"]["v_psa_stg"]["status"] == "CLEAR"
        assert result["blocked"] is False


# ---------------------------------------------------------------------------
# HUB collision tests
# ---------------------------------------------------------------------------

class TestHubCollision:

    def test_clear_when_hub_does_not_exist(self, tmp_path):
        """CLEAR when hub model file does not exist."""
        state = _base_state(objects=["stg", "hub"])
        (tmp_path / "models" / "int_staging_views").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "hub").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "sat").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "link").mkdir(parents=True)

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path):
            with patch("pipeline_orchestrator._run_command", return_value=(0, "", "")):
                result = _semantic_collision_check(state)

        assert result["layers"]["hub"]["status"] == "CLEAR"
        assert result["blocked"] is False

    def test_add_source_when_hub_exists(self, tmp_path):
        """ADD-SOURCE when hub model file already exists."""
        state = _base_state(objects=["stg", "hub"])
        (tmp_path / "models" / "int_staging_views").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "sat").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "link").mkdir(parents=True)

        # Create the hub file
        hub_path = tmp_path / "models" / "raw_vault" / "hub" / "hub_product_cost.sql"
        hub_path.parent.mkdir(parents=True, exist_ok=True)
        hub_path.write_text("-- existing hub\n")

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path):
            with patch("pipeline_orchestrator._run_command", return_value=(0, "", "")):
                result = _semantic_collision_check(state)

        assert result["layers"]["hub"]["status"] == "ADD-SOURCE"
        # ADD-SOURCE does NOT block
        assert result["blocked"] is False

    def test_hub_not_checked_when_not_in_objects(self, tmp_path):
        """Hub layer is not checked when objects=["stg"] only."""
        state = _base_state(objects=["stg"])
        (tmp_path / "models" / "int_staging_views").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "sat").mkdir(parents=True)

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path):
            with patch("pipeline_orchestrator._run_command", return_value=(0, "", "")):
                result = _semantic_collision_check(state)

        assert "hub" not in result["layers"]
        assert "lnk" not in result["layers"]


# ---------------------------------------------------------------------------
# SAT collision tests
# ---------------------------------------------------------------------------

class TestSatCollision:

    def test_clear_when_no_sat_references_model(self, tmp_path):
        """CLEAR when no SAT references the v_psa_stg model."""
        state = _base_state()
        (tmp_path / "models" / "int_staging_views").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "sat").mkdir(parents=True)

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path):
            with patch("pipeline_orchestrator._run_command", return_value=(0, "", "")):
                result = _semantic_collision_check(state)

        assert result["layers"]["sat"]["status"] == "CLEAR"
        assert result["blocked"] is False

    def test_collision_when_sat_references_model(self, tmp_path):
        """COLLISION when an existing SAT references the v_psa_stg model."""
        state = _base_state()
        (tmp_path / "models" / "int_staging_views").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "sat").mkdir(parents=True)

        sat_file = "models/raw_vault/sat/sat_product_cost.sql"

        def mock_run_command(cmd, cwd=None, capture=True):
            if "raw_vault/sat" in cmd and "ref(" in cmd:
                return (0, sat_file, "")
            return (0, "", "")

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path):
            with patch("pipeline_orchestrator._run_command", side_effect=mock_run_command):
                result = _semantic_collision_check(state)

        assert result["layers"]["sat"]["status"] == "COLLISION"
        assert result["blocked"] is True
        assert sat_file in result["layers"]["sat"]["files"]


# ---------------------------------------------------------------------------
# LNK collision tests
# ---------------------------------------------------------------------------

class TestLnkCollision:

    def test_clear_when_no_lnk_references_hub(self, tmp_path):
        """CLEAR when no link references the hub."""
        state = _base_state(objects=["stg", "hub"])
        (tmp_path / "models" / "int_staging_views").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "hub").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "sat").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "link").mkdir(parents=True)

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path):
            with patch("pipeline_orchestrator._run_command", return_value=(0, "", "")):
                result = _semantic_collision_check(state)

        assert result["layers"]["lnk"]["status"] == "CLEAR"
        assert result["blocked"] is False

    def test_add_source_when_lnk_references_hub(self, tmp_path):
        """ADD-SOURCE when an existing link references the hub."""
        state = _base_state(objects=["stg", "hub"])
        (tmp_path / "models" / "int_staging_views").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "hub").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "sat").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "link").mkdir(parents=True)

        lnk_file = "models/raw_vault/link/lnk_po_product_cost.sql"

        def mock_run_command(cmd, cwd=None, capture=True):
            if "raw_vault/link" in cmd and "ref(" in cmd:
                return (0, lnk_file, "")
            return (0, "", "")

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path):
            with patch("pipeline_orchestrator._run_command", side_effect=mock_run_command):
                result = _semantic_collision_check(state)

        assert result["layers"]["lnk"]["status"] == "ADD-SOURCE"
        # ADD-SOURCE does NOT block
        assert result["blocked"] is False


# ---------------------------------------------------------------------------
# Combined / integration scenarios
# ---------------------------------------------------------------------------

class TestCombinedScenarios:

    def test_all_clear_stg_only(self, tmp_path):
        """All layers CLEAR for stg-only pipeline."""
        state = _base_state(objects=["stg"])
        (tmp_path / "models" / "int_staging_views").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "sat").mkdir(parents=True)

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path):
            with patch("pipeline_orchestrator._run_command", return_value=(0, "", "")):
                result = _semantic_collision_check(state)

        assert result["blocked"] is False
        assert result["layers"]["v_psa_stg"]["status"] == "CLEAR"
        assert result["layers"]["sat"]["status"] == "CLEAR"
        assert "hub" not in result["layers"]

    def test_all_clear_stg_plus_hub(self, tmp_path):
        """All layers CLEAR for stg+hub pipeline."""
        state = _base_state(objects=["stg", "hub"])
        (tmp_path / "models" / "int_staging_views").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "hub").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "sat").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "link").mkdir(parents=True)

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path):
            with patch("pipeline_orchestrator._run_command", return_value=(0, "", "")):
                result = _semantic_collision_check(state)

        assert result["blocked"] is False
        for layer in ("v_psa_stg", "hub", "sat", "lnk"):
            assert result["layers"][layer]["status"] == "CLEAR"

    def test_stg_collision_blocks_even_if_hub_clear(self, tmp_path):
        """v_psa_stg COLLISION blocks the pipeline even if hub is CLEAR."""
        state = _base_state(objects=["stg", "hub"])
        (tmp_path / "models" / "int_staging_views").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "hub").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "sat").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "link").mkdir(parents=True)

        stg_file = "models/int_staging_views/v_psa_stg_product_cost__moen_sap.sql"

        def mock_run_command(cmd, cwd=None, capture=True):
            if "int_staging_views" in cmd and "source(" in cmd:
                return (0, stg_file, "")
            if "z_keko" in cmd:
                return (0, stg_file, "")
            return (0, "", "")

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path):
            with patch("pipeline_orchestrator._run_command", side_effect=mock_run_command):
                result = _semantic_collision_check(state)

        assert result["blocked"] is True
        assert result["layers"]["v_psa_stg"]["status"] == "COLLISION"
        assert result["layers"]["hub"]["status"] == "CLEAR"

    def test_hub_add_source_does_not_block(self, tmp_path):
        """Hub ADD-SOURCE is informational — does not block."""
        state = _base_state(objects=["stg", "hub"])
        (tmp_path / "models" / "int_staging_views").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "sat").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "link").mkdir(parents=True)

        # Create existing hub
        hub_path = tmp_path / "models" / "raw_vault" / "hub" / "hub_product_cost.sql"
        hub_path.parent.mkdir(parents=True, exist_ok=True)
        hub_path.write_text("-- existing hub\n")

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path):
            with patch("pipeline_orchestrator._run_command", return_value=(0, "", "")):
                result = _semantic_collision_check(state)

        assert result["blocked"] is False
        assert result["layers"]["hub"]["status"] == "ADD-SOURCE"

    def test_sat_collision_plus_hub_add_source(self, tmp_path):
        """SAT COLLISION blocks even when hub is ADD-SOURCE."""
        state = _base_state(objects=["stg", "hub"])
        (tmp_path / "models" / "int_staging_views").mkdir(parents=True)
        (tmp_path / "models" / "raw_vault" / "link").mkdir(parents=True)

        # Create existing hub
        hub_path = tmp_path / "models" / "raw_vault" / "hub" / "hub_product_cost.sql"
        hub_path.parent.mkdir(parents=True, exist_ok=True)
        hub_path.write_text("-- existing hub\n")

        # SAT collision
        sat_dir = tmp_path / "models" / "raw_vault" / "sat"
        sat_dir.mkdir(parents=True)

        sat_file = "models/raw_vault/sat/sat_product_cost.sql"

        def mock_run_command(cmd, cwd=None, capture=True):
            if "raw_vault/sat" in cmd and "ref(" in cmd:
                return (0, sat_file, "")
            return (0, "", "")

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path):
            with patch("pipeline_orchestrator._run_command", side_effect=mock_run_command):
                result = _semantic_collision_check(state)

        assert result["blocked"] is True
        assert result["layers"]["sat"]["status"] == "COLLISION"
        assert result["layers"]["hub"]["status"] == "ADD-SOURCE"


# ---------------------------------------------------------------------------
# _print_collision_report tests
# ---------------------------------------------------------------------------

class TestPrintCollisionReport:

    def test_report_all_clear(self, capsys):
        """Report prints correctly for all-clear scenario."""
        result = {
            "layers": {
                "v_psa_stg": {"status": "CLEAR", "message": "no collision"},
                "sat": {"status": "CLEAR", "message": "no sat collision"},
            },
            "blocked": False,
        }
        _print_collision_report(result)
        out = capsys.readouterr().out
        assert "CLEAR" in out
        assert "All checks passed" in out
        assert "BLOCKED" not in out

    def test_report_with_collision(self, capsys):
        """Report prints correctly for collision scenario."""
        result = {
            "layers": {
                "v_psa_stg": {
                    "status": "COLLISION",
                    "message": "existing model(s) already use schema.table",
                    "files": ["models/int_staging_views/v_psa_stg_foo.sql"],
                },
                "sat": {"status": "CLEAR", "message": "no sat collision"},
            },
            "blocked": True,
        }
        _print_collision_report(result)
        out = capsys.readouterr().out
        assert "COLLISION" in out
        assert "BLOCKED" in out
        assert "v_psa_stg_foo.sql" in out

    def test_report_with_add_source(self, capsys):
        """Report prints correctly for ADD-SOURCE scenario."""
        result = {
            "layers": {
                "v_psa_stg": {"status": "CLEAR", "message": "no collision"},
                "hub": {
                    "status": "ADD-SOURCE",
                    "message": "hub_foo exists",
                    "file": "models/raw_vault/hub/hub_foo.sql",
                },
                "sat": {"status": "CLEAR", "message": "no sat collision"},
            },
            "blocked": False,
        }
        _print_collision_report(result)
        out = capsys.readouterr().out
        assert "ADD-SOURCE" in out
        assert "hub_foo.sql" in out
        assert "All checks passed" in out
