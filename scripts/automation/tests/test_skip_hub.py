"""
test_skip_hub.py — Tests for --skip-hub flag and ALREADY-ADDED detection.

Fix 3: --skip-hub skips hub/link placement for interrupted runs.
ALREADY-ADDED: alias collision warns and skips instead of erroring.
"""

import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pipeline_orchestrator import PROJECT_ROOT


# ---------------------------------------------------------------------------
# Helpers (shared with test_hub_protection.py)
# ---------------------------------------------------------------------------

def _base_state(model_name="v_psa_stg_test__src"):
    return {
        "model_name": model_name,
        "schema": "test_schema",
        "table": "test_table",
        "bk": "test_col",
        "bk_name": "TEST_BK",
        "steps_completed": [
            {"step": "init"}, {"step": "profile"}, {"step": "approve-profile"},
            {"step": "generate-yaml"}, {"step": "generate-xlsx"},
            {"step": "approve-xlsx"}, {"step": "generate-code"},
            {"step": "approve-code"},
        ],
    }


def _setup_generated_files(tmp_path):
    gen_stg = tmp_path / "scripts" / "automation" / "models" / "int_staging_views"
    gen_hub = tmp_path / "scripts" / "automation" / "models" / "raw_vault" / "hub"
    gen_sat = tmp_path / "scripts" / "automation" / "models" / "raw_vault" / "sat"
    gen_lnk = tmp_path / "scripts" / "automation" / "models" / "raw_vault" / "link"
    for d in [gen_stg, gen_hub, gen_sat, gen_lnk]:
        d.mkdir(parents=True, exist_ok=True)

    (gen_stg / "v_psa_stg_test__src.sql").write_text("-- generated stg sql")
    (gen_stg / "v_psa_stg_test__src.yml").write_text("version: 2")
    (gen_hub / "hub_test.sql").write_text("-- generated single-source hub")
    (gen_hub / "hub_test.yml").write_text("version: 2")
    (gen_sat / "sat_test__src.sql").write_text("-- generated sat sql")
    (gen_sat / "sat_test__src.yml").write_text("version: 2")
    (gen_lnk / "lnk_test.sql").write_text("-- generated single-source lnk")
    (gen_lnk / "lnk_test.yml").write_text("version: 2")

    stg_dir = tmp_path / "models" / "int_staging_views" / "supplier"
    hub_dir = tmp_path / "models" / "raw_vault" / "hub"
    lnk_dir = tmp_path / "models" / "raw_vault" / "link"
    sat_dir = tmp_path / "models" / "raw_vault" / "sat"
    src_dir = tmp_path / "models" / "sources"
    for d in [stg_dir, hub_dir, lnk_dir, sat_dir, src_dir]:
        d.mkdir(parents=True, exist_ok=True)

    (src_dir / "_sources_staging_psa.yml").write_text("version: 2\nsources: []\n")

    return {"stg_dir": stg_dir, "hub_dir": hub_dir, "lnk_dir": lnk_dir, "sat_dir": sat_dir}


def _args(domain="supplier", force=False, skip_hub=False):
    a = MagicMock()
    a.model_name = "v_psa_stg_test__src"
    a.domain = domain
    a.force = force
    a.skip_build = True
    a.skip_hub = skip_hub
    return a


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

class TestSkipHub:
    """--skip-hub must skip hub and link placement entirely."""

    def test_skip_hub_skips_hub_placement(self, tmp_path):
        """--skip-hub skips hub placement even when hub files would be new."""
        from pipeline_orchestrator import cmd_implement

        dirs = _setup_generated_files(tmp_path)

        state = _base_state()
        state["objects"] = ["stg", "hub"]
        state["generated_files"] = {
            "sql": "scripts/automation/models/int_staging_views/v_psa_stg_test__src.sql",
            "yml": "scripts/automation/models/int_staging_views/v_psa_stg_test__src.yml",
            "hub_sql": "scripts/automation/models/raw_vault/hub/hub_test.sql",
            "hub_yml": "scripts/automation/models/raw_vault/hub/hub_test.yml",
        }
        state["profile_results"] = {}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_code_review", return_value={"checks_run": 42, "fail_count": 0, "warn_count": 0, "findings": []}):

            rc = cmd_implement(_args(force=False, skip_hub=True))

        assert rc == 0, f"implement --skip-hub should succeed, got rc={rc}"
        # Hub file must NOT exist (was skipped)
        assert not (dirs["hub_dir"] / "hub_test.sql").exists(), \
            "Hub should not be placed with --skip-hub"

    def test_skip_hub_skips_link_placement(self, tmp_path):
        """--skip-hub also skips link placement."""
        from pipeline_orchestrator import cmd_implement

        dirs = _setup_generated_files(tmp_path)

        state = _base_state()
        state["objects"] = ["stg", "lnk"]
        state["lnks"] = [{"lnk_name": "lnk_test"}]
        state["generated_files"] = {
            "sql": "scripts/automation/models/int_staging_views/v_psa_stg_test__src.sql",
            "yml": "scripts/automation/models/int_staging_views/v_psa_stg_test__src.yml",
            "lnk_sql": "scripts/automation/models/raw_vault/link/lnk_test.sql",
            "lnk_yml": "scripts/automation/models/raw_vault/link/lnk_test.yml",
        }
        state["profile_results"] = {}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_code_review", return_value={"checks_run": 42, "fail_count": 0, "warn_count": 0, "findings": []}):

            rc = cmd_implement(_args(force=False, skip_hub=True))

        assert rc == 0, f"implement --skip-hub should succeed for lnk, got rc={rc}"
        assert not (dirs["lnk_dir"] / "lnk_test.sql").exists(), \
            "Link should not be placed with --skip-hub"


class TestAlreadyAddedSkip:
    """ADD-SOURCE with existing alias should warn and skip, not error."""

    def test_already_added_alias_skips_gracefully(self, tmp_path):
        """When alias already exists in hub, warn and continue (rc=0)."""
        from pipeline_orchestrator import cmd_implement

        dirs = _setup_generated_files(tmp_path)
        # Create existing hub file
        (dirs["hub_dir"] / "hub_test.sql").write_text("-- existing hub")
        (dirs["hub_dir"] / "hub_test.yml").write_text("version: 2")

        state = _base_state()
        state["objects"] = ["stg", "hub"]
        state["generated_files"] = {
            "sql": "scripts/automation/models/int_staging_views/v_psa_stg_test__src.sql",
            "yml": "scripts/automation/models/int_staging_views/v_psa_stg_test__src.yml",
            "hub_sql": "scripts/automation/models/raw_vault/hub/hub_test.sql",
            "hub_yml": "scripts/automation/models/raw_vault/hub/hub_test.yml",
        }
        state["profile_results"] = {
            "collision_check": {"layers": {"hub": {"status": "ADD-SOURCE"}}}
        }

        # Mock _parse_existing_hub to return sources with matching alias
        mock_parsed = {
            "sources": [{"alias": "SRC_TEST_SRC", "model": "v_psa_stg_test__src"}],
            "hk_column": "TEST_HK",
        }

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._derive_hub_name", return_value="hub_test"), \
             patch("pipeline_orchestrator._parse_existing_hub", return_value=mock_parsed), \
             patch("pipeline_orchestrator._derive_source_alias", return_value="SRC_TEST_SRC"), \
             patch("pipeline_orchestrator._run_code_review", return_value={"checks_run": 42, "fail_count": 0, "warn_count": 0, "findings": []}):

            rc = cmd_implement(_args(force=False))

        assert rc == 0, f"implement should succeed when alias already added, got rc={rc}"

    def test_already_added_alias_excludes_hub_from_build(self, tmp_path, capsys):
        """When alias already exists, hub must NOT appear in build select or git summary."""
        from pipeline_orchestrator import cmd_implement

        dirs = _setup_generated_files(tmp_path)
        (dirs["hub_dir"] / "hub_test.sql").write_text("-- existing hub")
        (dirs["hub_dir"] / "hub_test.yml").write_text("version: 2")

        state = _base_state()
        state["objects"] = ["stg", "hub"]
        state["generated_files"] = {
            "sql": "scripts/automation/models/int_staging_views/v_psa_stg_test__src.sql",
            "yml": "scripts/automation/models/int_staging_views/v_psa_stg_test__src.yml",
            "hub_sql": "scripts/automation/models/raw_vault/hub/hub_test.sql",
            "hub_yml": "scripts/automation/models/raw_vault/hub/hub_test.yml",
        }
        state["profile_results"] = {
            "collision_check": {"layers": {"hub": {"status": "ADD-SOURCE"}}}
        }

        mock_parsed = {
            "sources": [{"alias": "SRC_TEST_SRC", "model": "v_psa_stg_test__src"}],
            "hk_column": "TEST_HK",
        }

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._derive_hub_name", return_value="hub_test"), \
             patch("pipeline_orchestrator._parse_existing_hub", return_value=mock_parsed), \
             patch("pipeline_orchestrator._derive_source_alias", return_value="SRC_TEST_SRC"), \
             patch("pipeline_orchestrator._run_code_review", return_value={"checks_run": 42, "fail_count": 0, "warn_count": 0, "findings": []}):

            rc = cmd_implement(_args(force=False))

        assert rc == 0
        captured = capsys.readouterr()
        # Hub must NOT appear in build select or git summary when alias already exists
        assert "hub_test" not in captured.out.split("Models ready:")[1].split("\n")[0], \
            "Hub should not be included in build select when alias already exists"
        assert "hub_test" not in captured.out.split("Files ready for commit")[1], \
            "Hub should not appear in git summary when not modified"
