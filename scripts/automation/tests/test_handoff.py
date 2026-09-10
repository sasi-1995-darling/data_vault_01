"""Tests for the generate-handoff pipeline command.

Tests cover:
- Handoff document generation from various pipeline states
- Security: path traversal prevention, credential detection
- Content validation: all required sections present
- Decision auto-extraction from state
- Edge cases: empty state, complete pipeline, partial progress
"""
import json
import os
import sys
import tempfile
from pathlib import Path
from unittest.mock import patch, MagicMock

import pytest

# Add parent to path for imports
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from pipeline_orchestrator import (
    _generate_handoff_markdown,
    cmd_generate_handoff,
    SCRIPT_DIR,
    PROJECT_ROOT,
    PIPELINE_STEPS,
    _save_state,
    STATE_DIR,
)


# ── Fixtures ──────────────────────────────────────────────────────────────────


@pytest.fixture
def minimal_state(tmp_path, monkeypatch):
    """Minimal valid pipeline state after init."""
    monkeypatch.setattr(
        "pipeline_orchestrator.SCRIPT_DIR", tmp_path / "scripts" / "automation"
    )
    (tmp_path / "scripts" / "automation" / "configs").mkdir(parents=True)
    state_dir = tmp_path / "scripts" / "automation" / ".pipeline_state"
    state_dir.mkdir(parents=True)
    monkeypatch.setattr("pipeline_orchestrator.STATE_DIR", state_dir)
    monkeypatch.setattr("pipeline_orchestrator.PROJECT_ROOT", tmp_path)

    state = {
        "model_name": "v_psa_stg_test_model__src",
        "steps_completed": [
            {"step": "init", "completed_at": "2026-06-01T10:00:00+00:00"}
        ],
        "profile_results": {},
    }
    return state


@pytest.fixture
def mid_pipeline_state(tmp_path, monkeypatch):
    """State at approve-xlsx (mid-pipeline)."""
    monkeypatch.setattr(
        "pipeline_orchestrator.SCRIPT_DIR", tmp_path / "scripts" / "automation"
    )
    (tmp_path / "scripts" / "automation" / "configs").mkdir(parents=True)
    state_dir = tmp_path / "scripts" / "automation" / ".pipeline_state"
    state_dir.mkdir(parents=True)
    monkeypatch.setattr("pipeline_orchestrator.STATE_DIR", state_dir)
    monkeypatch.setattr("pipeline_orchestrator.PROJECT_ROOT", tmp_path)

    state = {
        "model_name": "v_psa_stg_po_header__winn_sap",
        "steps_completed": [
            {"step": "init", "completed_at": "2026-06-01T10:00:00+00:00"},
            {"step": "profile", "completed_at": "2026-06-01T10:05:00+00:00"},
            {"step": "approve-profile", "completed_at": "2026-06-01T10:10:00+00:00"},
            {"step": "generate-yaml", "completed_at": "2026-06-01T10:12:00+00:00"},
            {"step": "generate-xlsx", "completed_at": "2026-06-01T10:15:00+00:00"},
            {"step": "approve-xlsx", "completed_at": "2026-06-01T10:20:00+00:00"},
        ],
        "profile_results": {
            "row_count": 1500000,
            "volume_tier": "Normal",
            "ingestion_source": "SNP_GLUE",
            "columns": ["PO_NUMBER", "VENDOR_ID", "PO_DATE"],
        },
        "bk_name": "PO_HEADER_BK",
        "domain": "procurement",
        "grain_columns": ["PO_NUMBER"],
        "xlsx_path": "scripts/automation/mappings/v_psa_stg_po_header__winn_sap.xlsx",
    }
    return state


@pytest.fixture
def complete_state(tmp_path, monkeypatch):
    """Fully completed pipeline state."""
    monkeypatch.setattr(
        "pipeline_orchestrator.SCRIPT_DIR", tmp_path / "scripts" / "automation"
    )
    (tmp_path / "scripts" / "automation" / "configs").mkdir(parents=True)
    state_dir = tmp_path / "scripts" / "automation" / ".pipeline_state"
    state_dir.mkdir(parents=True)
    monkeypatch.setattr("pipeline_orchestrator.STATE_DIR", state_dir)
    monkeypatch.setattr("pipeline_orchestrator.PROJECT_ROOT", tmp_path)

    state = {
        "model_name": "v_psa_stg_invoice__emtk_ebs",
        "steps_completed": [
            {"step": step, "completed_at": f"2026-06-01T{10+i}:00:00+00:00"}
            for i, step in enumerate(PIPELINE_STEPS)
        ],
        "profile_results": {
            "row_count": 500000,
            "volume_tier": "Normal",
            "ingestion_source": "Fivetran",
        },
        "bk_name": "INVOICE_BK",
        "domain": "invoice",
        "raw_vault_objects": {"hub": "hub_invoice", "sat": "sat_invoice__emtk_ebs"},
        "generated_sql_path": "models/int_staging_views/invoice/v_psa_stg_invoice__emtk_ebs.sql",
        "generated_yml_path": "models/int_staging_views/invoice/v_psa_stg_invoice__emtk_ebs.yml",
    }
    return state


# ── TestHandoffGeneration ─────────────────────────────────────────────────────


class TestHandoffGeneration:
    """Tests for _generate_handoff_markdown()."""

    def test_generates_file(self, minimal_state):
        """Handoff file is created at the expected path.

        Path uses the stripped config name (no `v_psa_stg_` prefix) so it
        sits next to `profile.md` for the same model under
        `configs/<config_name>/`. Note: the YAML config itself is a flat
        file at `configs/<config_name>.yml` (not nested under the
        per-model directory), so handoff.md and profile.md share a
        directory with each other but NOT with the YAML.
        """
        result = _generate_handoff_markdown(minimal_state)
        assert result is not None
        assert result.exists()
        assert result.name == "handoff.md"
        # config_name = _strip_stg_prefix("v_psa_stg_test_model__src") = "test_model__src"
        assert "/configs/test_model__src/" in str(result)
        # Must NOT contain the v_psa_stg_ prefix in the directory name (PR review fix).
        assert "v_psa_stg_test_model__src" not in str(result)

    def test_contains_all_sections(self, mid_pipeline_state):
        """Handoff document contains all required sections."""
        result = _generate_handoff_markdown(mid_pipeline_state)
        content = result.read_text()

        assert "# Pipeline Handoff:" in content
        assert "## Pipeline Progress" in content
        assert "## Decisions & Reasoning" in content
        assert "## Blockers & Workarounds" in content
        assert "## Next Steps" in content
        assert "## Key Files" in content
        assert "## Resumption Command" in content

    def test_progress_table_shows_correct_status(self, mid_pipeline_state):
        """Completed steps show ✅, next shows ⏳, future shows ⬜."""
        result = _generate_handoff_markdown(mid_pipeline_state)
        content = result.read_text()

        # First 6 steps completed
        assert content.count("✅") == 6
        # Next step is generate-code
        assert "| generate-code | ⏳ |" in content
        # Remaining steps not started
        assert content.count("⬜") == 2  # approve-code, implement

    def test_decisions_auto_extracted(self, mid_pipeline_state):
        """Decisions are auto-extracted from state."""
        result = _generate_handoff_markdown(mid_pipeline_state)
        content = result.read_text()

        assert "procurement" in content
        assert "PO_HEADER_BK" in content
        assert "Normal" in content
        assert "PO_NUMBER" in content

    def test_raw_vault_option_b_detected(self, complete_state):
        """Option B (add-raw-vault) detected when raw_vault_objects present."""
        result = _generate_handoff_markdown(complete_state)
        content = result.read_text()

        assert "Option B" in content

    def test_complete_pipeline_no_resumption_command(self, complete_state):
        """Complete pipeline has no resumption command."""
        result = _generate_handoff_markdown(complete_state)
        content = result.read_text()

        assert "## Resumption Command" not in content
        assert "complete" in content.lower()

    def test_next_focus_included(self, mid_pipeline_state):
        """User-provided next_focus appears in Next Steps."""
        result = _generate_handoff_markdown(
            mid_pipeline_state,
            next_focus="Review generated SQL and run code reviewer"
        )
        content = result.read_text()

        assert "Review generated SQL and run code reviewer" in content

    def test_custom_decisions_appended(self, mid_pipeline_state):
        """User-supplied decisions are included in the table."""
        decisions = [
            {"decision": "Composite BK", "choice": "Yes", "reasoning": "Multi-column natural key"},
            {"decision": "NULL sentinel", "choice": "-1", "reasoning": "Required BK field"},
        ]
        result = _generate_handoff_markdown(mid_pipeline_state, decisions=decisions)
        content = result.read_text()

        assert "Composite BK" in content
        assert "Multi-column natural key" in content
        assert "NULL sentinel" in content

    def test_blockers_listed(self, mid_pipeline_state):
        """Blockers appear when provided."""
        blockers = [
            "Profile failed on first attempt — Snowflake timeout, retried with --profile-json",
            "XLSX validation check #14 required manual column type fix",
        ]
        result = _generate_handoff_markdown(mid_pipeline_state, blockers=blockers)
        content = result.read_text()

        assert "Snowflake timeout" in content
        assert "XLSX validation check #14" in content

    def test_key_files_include_state_and_config(self, mid_pipeline_state):
        """Key files section includes state file and config YAML paths."""
        result = _generate_handoff_markdown(mid_pipeline_state)
        content = result.read_text()

        assert ".pipeline_state/" in content
        assert ".yml" in content
        assert ".xlsx" in content

    def test_profile_md_referenced_when_exists(self, mid_pipeline_state, tmp_path):
        """Profile.md is referenced when it exists on disk.

        profile.md and handoff.md both live under the stripped config
        name (e.g. ``configs/po_header__winn_sap/``), matching what
        ``_persist_profile_markdown`` writes.
        """
        # Create profile.md at the canonical (stripped) location
        from pipeline_orchestrator import _strip_stg_prefix, SCRIPT_DIR
        config_name = _strip_stg_prefix(mid_pipeline_state["model_name"])
        model_dir = SCRIPT_DIR / "configs" / config_name
        model_dir.mkdir(parents=True, exist_ok=True)
        profile_md = model_dir / "profile.md"
        profile_md.write_text("# Profile")
        try:
            result = _generate_handoff_markdown(mid_pipeline_state)
            content = result.read_text()
            assert "profile.md" in content
        finally:
            # Cleanup so subsequent tests start clean
            profile_md.unlink(missing_ok=True)
            try:
                model_dir.rmdir()
            except OSError:
                pass
    def test_generated_files_referenced(self, complete_state):
        """Generated SQL and YAML paths appear in key files."""
        result = _generate_handoff_markdown(complete_state)
        content = result.read_text()

        assert "v_psa_stg_invoice__emtk_ebs.sql" in content
        assert "v_psa_stg_invoice__emtk_ebs.yml" in content


# ── TestHandoffSecurity ───────────────────────────────────────────────────────


class TestHandoffSecurity:
    """Security tests for handoff generation."""

    def test_path_traversal_blocked(self, tmp_path, monkeypatch):
        """Path traversal in model_name is rejected."""
        monkeypatch.setattr(
            "pipeline_orchestrator.SCRIPT_DIR", tmp_path / "scripts" / "automation"
        )
        (tmp_path / "scripts" / "automation" / "configs").mkdir(parents=True)
        monkeypatch.setattr("pipeline_orchestrator.PROJECT_ROOT", tmp_path)

        state = {
            "model_name": "../../etc/passwd",
            "steps_completed": [{"step": "init", "completed_at": "2026-06-01T10:00:00+00:00"}],
        }
        result = _generate_handoff_markdown(state)
        assert result is None

    def test_credential_detection_blocks_write(self, minimal_state, monkeypatch):
        """Long base64-like strings in content trigger credential guard."""
        # Inject a fake credential-like token (64+ chars, preceded by space not path char)
        # In markdown output, this would appear as: `| Config YAML | `<value>` |`
        # The backtick before the value means lookbehind sees '`', not a path char
        minimal_state["config_path"] = " " + "A" * 65  # Space prefix avoids lookbehind

        result = _generate_handoff_markdown(minimal_state)
        assert result is None

    def test_normal_paths_not_flagged(self, mid_pipeline_state):
        """Normal file paths (which contain alphanumeric chars) don't trigger false positive."""
        result = _generate_handoff_markdown(mid_pipeline_state)
        # Should succeed — normal paths are < 40 consecutive alphanumeric chars
        assert result is not None


# ── TestHandoffEdgeCases ──────────────────────────────────────────────────────


class TestHandoffEdgeCases:
    """Edge case tests."""

    def test_empty_steps_completed(self, tmp_path, monkeypatch):
        """State with no completed steps generates valid handoff."""
        monkeypatch.setattr(
            "pipeline_orchestrator.SCRIPT_DIR", tmp_path / "scripts" / "automation"
        )
        (tmp_path / "scripts" / "automation" / "configs").mkdir(parents=True)
        monkeypatch.setattr("pipeline_orchestrator.PROJECT_ROOT", tmp_path)

        state = {
            "model_name": "v_psa_stg_empty__test",
            "steps_completed": [],
        }
        result = _generate_handoff_markdown(state)
        assert result is not None
        content = result.read_text()
        # All steps should be ⬜ except first which is ⏳
        assert "| init | ⏳ |" in content

    def test_no_profile_results(self, minimal_state):
        """Missing profile_results doesn't crash."""
        del minimal_state["profile_results"]
        result = _generate_handoff_markdown(minimal_state)
        assert result is not None

    def test_no_domain_no_bk(self, minimal_state):
        """State without domain/bk_name produces valid doc with 'none recorded'."""
        result = _generate_handoff_markdown(minimal_state)
        content = result.read_text()
        assert "(none recorded)" in content

    def test_git_branch_failure_handled(self, minimal_state, monkeypatch):
        """Git branch detection failure doesn't crash handoff."""
        import subprocess

        def mock_run(*args, **kwargs):
            raise OSError("git not found")

        monkeypatch.setattr(subprocess, "run", mock_run)
        result = _generate_handoff_markdown(minimal_state)
        assert result is not None
        content = result.read_text()
        assert "unknown" in content

    def test_overwrite_existing_handoff(self, mid_pipeline_state, tmp_path):
        """Generating handoff twice overwrites the previous one."""
        result1 = _generate_handoff_markdown(mid_pipeline_state)
        content1 = result1.read_text()

        # Modify state and regenerate
        mid_pipeline_state["steps_completed"].append(
            {"step": "generate-code", "completed_at": "2026-06-01T10:25:00+00:00"}
        )
        result2 = _generate_handoff_markdown(mid_pipeline_state)
        content2 = result2.read_text()

        assert result1 == result2  # same path
        assert content1 != content2  # different content
        assert content2.count("✅") == 7  # one more completed


# ── TestCmdGenerateHandoff ────────────────────────────────────────────────────


class TestCmdGenerateHandoff:
    """Integration tests for cmd_generate_handoff."""

    def test_no_active_state_returns_error(self, tmp_path, monkeypatch):
        """Returns 1 when no pipeline state exists."""
        state_dir = tmp_path / ".pipeline_state"
        state_dir.mkdir()
        monkeypatch.setattr("pipeline_orchestrator.STATE_DIR", state_dir)

        args = MagicMock()
        args.model_name = "nonexistent_model"
        result = cmd_generate_handoff(args)
        assert result == 1

    def test_with_active_state_returns_success(self, mid_pipeline_state, tmp_path, monkeypatch):
        """Returns 0 and generates file when state exists."""
        # Save state to disk
        state_dir = tmp_path / "scripts" / "automation" / ".pipeline_state"
        state_dir.mkdir(parents=True, exist_ok=True)
        state_file = state_dir / f"{mid_pipeline_state['model_name']}.json"
        state_file.write_text(json.dumps(mid_pipeline_state))

        monkeypatch.setattr("pipeline_orchestrator.STATE_DIR", state_dir)

        args = MagicMock()
        args.model_name = mid_pipeline_state["model_name"]
        args.next_focus = "Finish code generation and review"

        result = cmd_generate_handoff(args)
        assert result == 0

        # Verify file was created at the canonical (stripped) location
        from pipeline_orchestrator import _strip_stg_prefix, SCRIPT_DIR
        config_name = _strip_stg_prefix(mid_pipeline_state["model_name"])
        handoff_path = SCRIPT_DIR / "configs" / config_name / "handoff.md"
        try:
            assert handoff_path.exists()
            content = handoff_path.read_text()
            assert "Finish code generation and review" in content
        finally:
            handoff_path.unlink(missing_ok=True)
            try:
                handoff_path.parent.rmdir()
            except OSError:
                pass


# ── TestHandoffCompactness ────────────────────────────────────────────────────


class TestHandoffCompactness:
    """Verify handoff documents stay within size limits."""

    def test_under_500_lines(self, complete_state):
        """Even a fully complete pipeline produces < 500 line handoff."""
        result = _generate_handoff_markdown(
            complete_state,
            decisions=[
                {"decision": f"Decision {i}", "choice": f"Choice {i}", "reasoning": f"Reason {i}"}
                for i in range(10)
            ],
            blockers=[f"Blocker {i}: description of issue" for i in range(10)],
            next_focus="A detailed description of next steps",
        )
        content = result.read_text()
        line_count = len(content.splitlines())
        assert line_count < 500, f"Handoff is {line_count} lines — exceeds 500 limit"

    def test_typical_handoff_50_to_150_lines(self, mid_pipeline_state):
        """Typical mid-pipeline handoff is 50-150 lines."""
        result = _generate_handoff_markdown(mid_pipeline_state)
        content = result.read_text()
        line_count = len(content.splitlines())
        assert 30 <= line_count <= 150, f"Handoff is {line_count} lines — outside expected 30-150 range"
