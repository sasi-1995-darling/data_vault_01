"""
test_hub_protection.py — Tests for hub/link force-overwrite protection.

Verifies that --force NEVER overwrites existing hub or link files,
while still allowing STG and SAT overwrite (single-pipeline ownership).

Incident: hub_payment_term (5-source) destroyed by implement --force.
"""

import shutil
import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pipeline_orchestrator import PROJECT_ROOT


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _base_state(model_name="v_psa_stg_test__src"):
    """Minimal state dict that passes _check_prerequisites for implement."""
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
    """Create generated files under tmp_path mimicking PROJECT_ROOT layout."""
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


def _make_existing_hub(hub_dir, name="hub_test", num_sources=5):
    """Create a multi-source hub file simulating a production hub."""
    sources = "\n".join(
        f"SRC_{i} AS (SELECT * FROM ref('v_psa_stg_source_{i}'))"
        for i in range(num_sources)
    )
    sql = f"---- SRC LAYER ----\nWITH\n{sources}\nSELECT * FROM JOIN_RESULT"
    (hub_dir / f"{name}.sql").write_text(sql)
    (hub_dir / f"{name}.yml").write_text("version: 2\nmodels:\n- name: " + name)
    return sql


def _make_existing_link(lnk_dir, name="lnk_test", num_sources=3):
    """Create a multi-source link file."""
    sources = "\n".join(
        f"SRC_{i} AS (SELECT * FROM ref('v_psa_stg_lnk_source_{i}'))"
        for i in range(num_sources)
    )
    sql = f"---- SRC LAYER ----\nWITH\n{sources}\nSELECT * FROM JOIN_RESULT"
    (lnk_dir / f"{name}.sql").write_text(sql)
    (lnk_dir / f"{name}.yml").write_text("version: 2\nmodels:\n- name: " + name)
    return sql


def _args(domain="supplier", force=False, skip_hub=False):
    """Build minimal args mock."""
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

class TestHubForceProtection:
    """--force must NEVER overwrite existing hub files."""

    def test_force_refuses_to_overwrite_existing_hub(self, tmp_path):
        """When hub exists and collision status is CLEAR, --force must refuse."""
        from pipeline_orchestrator import cmd_implement

        dirs = _setup_generated_files(tmp_path)
        original_hub = _make_existing_hub(dirs["hub_dir"])

        state = _base_state()
        state["objects"] = ["stg", "hub"]
        state["generated_files"] = {
            "sql": "scripts/automation/models/int_staging_views/v_psa_stg_test__src.sql",
            "yml": "scripts/automation/models/int_staging_views/v_psa_stg_test__src.yml",
            "hub_sql": "scripts/automation/models/raw_vault/hub/hub_test.sql",
            "hub_yml": "scripts/automation/models/raw_vault/hub/hub_test.yml",
        }
        state["profile_results"] = {
            "collision_check": {"layers": {"hub": {"status": "CLEAR"}}}
        }

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._derive_hub_name", return_value="hub_test"):

            rc = cmd_implement(_args(force=True))

        assert rc == 1, "implement --force must refuse to overwrite existing hub"
        hub_content = (dirs["hub_dir"] / "hub_test.sql").read_text()
        assert hub_content == original_hub, "Hub file content must remain unchanged"

    def test_force_allows_stg_overwrite(self, tmp_path):
        """--force correctly overwrites STG files (single-pipeline ownership)."""
        from pipeline_orchestrator import cmd_implement

        dirs = _setup_generated_files(tmp_path)
        (dirs["stg_dir"] / "v_psa_stg_test__src.sql").write_text("-- old stg")
        (dirs["stg_dir"] / "v_psa_stg_test__src.yml").write_text("version: 1")

        state = _base_state()
        state["objects"] = ["stg"]
        state["generated_files"] = {
            "sql": "scripts/automation/models/int_staging_views/v_psa_stg_test__src.sql",
            "yml": "scripts/automation/models/int_staging_views/v_psa_stg_test__src.yml",
        }
        state["profile_results"] = {}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_code_review", return_value={"checks_run": 42, "fail_count": 0, "warn_count": 0, "findings": []}):

            rc = cmd_implement(_args(force=True))

        assert rc == 0, f"implement --force should succeed for STG-only, got rc={rc}"
        stg_content = (dirs["stg_dir"] / "v_psa_stg_test__src.sql").read_text()
        assert stg_content == "-- generated stg sql", "STG file must be overwritten"

    def test_force_allows_sat_overwrite(self, tmp_path):
        """--force correctly overwrites SAT files (single-pipeline ownership)."""
        from pipeline_orchestrator import cmd_implement

        dirs = _setup_generated_files(tmp_path)
        (dirs["sat_dir"] / "sat_test__src.sql").write_text("-- old sat")
        (dirs["sat_dir"] / "sat_test__src.yml").write_text("version: 1")

        state = _base_state()
        state["objects"] = ["stg", "sat"]
        state["sats"] = [{"model_name": "sat_test__src", "sat_type": "sat",
                          "parent_hk": "TEST_HK", "parent_model": "hub_test"}]
        state["generated_files"] = {
            "sql": "scripts/automation/models/int_staging_views/v_psa_stg_test__src.sql",
            "yml": "scripts/automation/models/int_staging_views/v_psa_stg_test__src.yml",
            "sat_sql": "scripts/automation/models/raw_vault/sat/sat_test__src.sql",
            "sat_yml": "scripts/automation/models/raw_vault/sat/sat_test__src.yml",
        }
        state["profile_results"] = {}

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_code_review", return_value={"checks_run": 42, "fail_count": 0, "warn_count": 0, "findings": []}):

            rc = cmd_implement(_args(force=True))

        assert rc == 0, f"implement --force should succeed for SAT, got rc={rc}"
        sat_content = (dirs["sat_dir"] / "sat_test__src.sql").read_text()
        assert sat_content == "-- generated sat sql", "SAT file must be overwritten"


class TestLinkForceProtection:
    """--force must NEVER overwrite existing link files."""

    def test_force_refuses_to_overwrite_existing_link(self, tmp_path):
        """When link exists and collision status is CLEAR, --force must refuse."""
        from pipeline_orchestrator import cmd_implement

        dirs = _setup_generated_files(tmp_path)
        original_link = _make_existing_link(dirs["lnk_dir"])

        state = _base_state()
        state["objects"] = ["stg", "lnk"]
        state["lnks"] = [{"lnk_name": "lnk_test"}]
        state["generated_files"] = {
            "sql": "scripts/automation/models/int_staging_views/v_psa_stg_test__src.sql",
            "yml": "scripts/automation/models/int_staging_views/v_psa_stg_test__src.yml",
            "lnk_sql": "scripts/automation/models/raw_vault/link/lnk_test.sql",
            "lnk_yml": "scripts/automation/models/raw_vault/link/lnk_test.yml",
        }
        state["profile_results"] = {
            "collision_check": {"layers": {"lnk_model": {"status": "CLEAR"}}}
        }

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._derive_lnk_name", return_value="lnk_test"):

            rc = cmd_implement(_args(force=True))

        assert rc == 1, "implement --force must refuse to overwrite existing link"
        lnk_content = (dirs["lnk_dir"] / "lnk_test.sql").read_text()
        assert lnk_content == original_link, "Link file content must remain unchanged"
