"""
test_prebuild_review_and_dryrun.py — Tests for:
  - [3/8] Pre-build code review gate (blocks build on FAIL)
  - [5/8] Incremental dry-run validation (dbt run --empty)
  - STG-only pipelines skip dry-run
"""

import sys
from pathlib import Path
from unittest.mock import MagicMock, patch, call

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pipeline_orchestrator import PROJECT_ROOT


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _base_state(model_name="v_psa_stg_test__src", objects=None):
    return {
        "model_name": model_name,
        "schema": "test_schema",
        "table": "test_table",
        "bk": "test_col",
        "bk_name": "TEST_BK",
        "objects": objects or ["stg"],
        "sats": [],
        "steps_completed": [
            {"step": "init"}, {"step": "profile"}, {"step": "approve-profile"},
            {"step": "generate-yaml"}, {"step": "generate-xlsx"},
            {"step": "approve-xlsx"}, {"step": "generate-code"},
            {"step": "approve-code"},
        ],
        "generated_files": {
            "sql": "scripts/automation/models/int_staging_views/v_psa_stg_test__src.sql",
            "yml": "scripts/automation/models/int_staging_views/v_psa_stg_test__src.yml",
        },
        "profile_results": {},
    }


def _setup_generated_files(tmp_path, include_sat=False):
    """Create minimal generated and target directories."""
    gen_stg = tmp_path / "scripts" / "automation" / "models" / "int_staging_views"
    gen_stg.mkdir(parents=True, exist_ok=True)
    (gen_stg / "v_psa_stg_test__src.sql").write_text("-- generated stg sql")
    (gen_stg / "v_psa_stg_test__src.yml").write_text("version: 2")

    stg_dir = tmp_path / "models" / "int_staging_views" / "supplier"
    src_dir = tmp_path / "models" / "sources"
    for d in [stg_dir, src_dir]:
        d.mkdir(parents=True, exist_ok=True)
    (src_dir / "_sources_staging_psa.yml").write_text("version: 2\nsources: []\n")

    if include_sat:
        gen_sat = tmp_path / "scripts" / "automation" / "models" / "raw_vault" / "sat"
        gen_sat.mkdir(parents=True, exist_ok=True)
        (gen_sat / "sat_test__src.sql").write_text("-- generated sat sql")
        (gen_sat / "sat_test__src.yml").write_text("version: 2")
        sat_dir = tmp_path / "models" / "raw_vault" / "sat"
        sat_dir.mkdir(parents=True, exist_ok=True)

    return stg_dir


def _args(domain="supplier", force=False, skip_build=False):
    a = MagicMock()
    a.model_name = "v_psa_stg_test__src"
    a.domain = domain
    a.force = force
    a.skip_build = skip_build
    a.skip_hub = False
    return a


# ---------------------------------------------------------------------------
# Pre-build code review gate tests
# ---------------------------------------------------------------------------

class TestPreBuildCodeReviewGate:
    """Step [3/8] — code review must block build on FAIL."""

    def test_code_review_fail_blocks_build(self, tmp_path, capsys):
        """Code review FAIL at step [3/8] should prevent dbt build."""
        from pipeline_orchestrator import cmd_implement

        _setup_generated_files(tmp_path)
        state = _base_state()

        review_result = {
            "checks_run": 46,
            "fail_count": 2,
            "warn_count": 1,
            "findings": [
                {"severity": "FAIL", "check_id": "H1", "message": "Missing HK"},
                {"severity": "FAIL", "check_id": "B2", "message": "Bad BKCC join"},
                {"severity": "WARN", "check_id": "W1", "message": "Minor warning"},
            ],
        }

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_dbt") as mock_dbt, \
             patch("pipeline_orchestrator._run_snowflake_query", return_value=[[1]]), \
             patch("pipeline_orchestrator._connector_importable", return_value=True), \
             patch("pipeline_orchestrator._run_code_review", return_value=review_result):

            # Clone succeeds so execution reaches the code-review gate at [3/8].
            mock_dbt.return_value = (0, "  schema: dbt_test_schema", "")
            rc = cmd_implement(_args())

        assert rc == 1, "Code review FAIL should return exit code 1"

        # dbt build must NEVER have been called (only debug for BKCC clone is OK)
        for c in mock_dbt.call_args_list:
            args_list = c[0][0] if c[0] else c[1].get("args_list", [])
            assert "build" not in args_list, \
                f"dbt build should not be called after code review FAIL, got: {args_list}"

        cap = capsys.readouterr()
        captured = cap.out + cap.err
        assert "Pre-build review found" in captured or "FAIL finding(s)" in captured
        assert "Fix before building" in captured or "fix before building" in captured

    def test_code_review_pass_allows_build(self, tmp_path, capsys):
        """Code review PASS at step [3/8] should allow dbt build to proceed."""
        from pipeline_orchestrator import cmd_implement

        _setup_generated_files(tmp_path)
        state = _base_state()

        review_result = {
            "checks_run": 46,
            "fail_count": 0,
            "warn_count": 3,
            "findings": [
                {"severity": "WARN", "check_id": "W1", "message": "Advisory"},
            ],
        }

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_dbt") as mock_dbt, \
             patch("pipeline_orchestrator._run_snowflake_query") as mock_sf, \
             patch("pipeline_orchestrator._connector_importable", return_value=True), \
             patch("pipeline_orchestrator._run_code_review", return_value=review_result):

            def _dbt_side_effect(args_list, **kwargs):
                if args_list[0] == "debug":
                    return (0, "  schema: dbt_test_schema", "")
                return (0, "Done. PASS=3 WARN=0 ERROR=0 SKIP=0 TOTAL=3", "")
            mock_dbt.side_effect = _dbt_side_effect
            mock_sf.return_value = [[42]]

            rc = cmd_implement(_args())

        assert rc == 0, f"Code review with only WARNs should pass, got rc={rc}"

        # Verify dbt build was called
        build_calls = [
            c for c in mock_dbt.call_args_list
            if c[0] and "build" in c[0][0]
        ]
        assert len(build_calls) >= 1, "dbt build should have been called after review PASS"

        captured = capsys.readouterr().out
        assert "Pre-build review passed" in captured


# ---------------------------------------------------------------------------
# Issue #1844 — BKCC clone / post-build validation failure modes
# ---------------------------------------------------------------------------

class TestBkccCloneAndValidationFailModes:
    """The DEV BKCC clone must fail loud; post-build validation is best-effort."""

    def test_bkcc_clone_propagates_snowflake_unavailable(self, tmp_path):
        """must-have #3: the clone at step [2c/8] must NOT swallow a Snowflake
        execution failure into a best-effort warning (which previously printed a
        false 'Cloned ...'). It must propagate so the command fails loud, before
        the build is ever reached."""
        import os
        from pipeline_orchestrator import cmd_implement, SnowflakeUnavailableError

        _setup_generated_files(tmp_path)
        state = _base_state()
        review_result = {
            "checks_run": 46, "fail_count": 0, "warn_count": 0, "findings": [],
        }

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_dbt") as mock_dbt, \
             patch("pipeline_orchestrator._run_snowflake_query") as mock_sf, \
             patch("pipeline_orchestrator._connector_importable", return_value=True), \
             patch("pipeline_orchestrator._run_code_review", return_value=review_result), \
             patch.dict(os.environ, {"DBT_ENVIRON": "dev"}):

            mock_dbt.return_value = (0, "  schema: dbt_test_schema", "")
            mock_sf.side_effect = SnowflakeUnavailableError("driver missing at clone")

            with pytest.raises(SnowflakeUnavailableError):
                cmd_implement(_args())

        # The clone runs at [2c/8], BEFORE the build — a loud clone failure must
        # stop the pipeline, so dbt build must never have been reached.
        for c in mock_dbt.call_args_list:
            args_list = c[0][0] if c[0] else []
            assert "build" not in args_list

    def test_bkcc_clone_mcp_only_fails_before_dbt_debug(self, tmp_path):
        """#1928: the clone is DDL, which snow-mcp cannot run. An MCP-only
        environment (connector missing but MCP creds present) passes the general
        _assert_snowflake_available() path check, so the clone must ALSO preflight
        the Python connector specifically and fail BEFORE `dbt debug` — not after
        wasting time on it and only then failing at the clone."""
        import os
        from pipeline_orchestrator import cmd_implement, SnowflakeUnavailableError

        _setup_generated_files(tmp_path)
        state = _base_state()
        review_result = {
            "checks_run": 46, "fail_count": 0, "warn_count": 0, "findings": [],
        }

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_dbt") as mock_dbt, \
             patch("pipeline_orchestrator._run_snowflake_query") as mock_sf, \
             patch("pipeline_orchestrator._connector_importable", return_value=False), \
             patch("pipeline_orchestrator._read_mcp_creds", return_value={"account": "x"}), \
             patch("pipeline_orchestrator._run_code_review", return_value=review_result), \
             patch.dict(os.environ, {"DBT_ENVIRON": "dev"}):

            # _assert_snowflake_available() passes (MCP path present), but the
            # DDL clone needs the connector, so cmd_implement must raise.
            with pytest.raises(SnowflakeUnavailableError):
                cmd_implement(_args())

        # Must fail at the connector preflight, BEFORE `dbt debug` and the clone.
        for c in mock_dbt.call_args_list:
            args_list = c[0][0] if c[0] else []
            assert "debug" not in args_list, "must fail before `dbt debug`"
        mock_sf.assert_not_called()  # clone SQL must never have run

    def test_postbuild_validation_snowflake_unavailable_is_best_effort(self, tmp_path, capsys):
        """Post-build validation is deliberately best-effort: a Snowflake path
        lost AFTER a green build must NOT retroactively fail it. It reports an
        honest 'validation skipped' and the command still succeeds."""
        import os
        from pipeline_orchestrator import cmd_implement, SnowflakeUnavailableError

        _setup_generated_files(tmp_path, include_sat=True)
        state = _base_state(objects=["stg", "sat"])
        state["sats"] = [{"model_name": "sat_test__src"}]
        state["generated_files"]["sat_sql"] = "scripts/automation/models/raw_vault/sat/sat_test__src.sql"
        state["generated_files"]["sat_yml"] = "scripts/automation/models/raw_vault/sat/sat_test__src.yml"
        review_result = {
            "checks_run": 46, "fail_count": 0, "warn_count": 0, "findings": [],
        }

        def _sf_side_effect(sql, args):
            # Clone (DDL) succeeds; only the post-build COUNT(*) loses its path.
            if "COUNT(*)" in sql.upper():
                raise SnowflakeUnavailableError("path lost during validation")
            return [[1]]

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_dbt") as mock_dbt, \
             patch("pipeline_orchestrator._run_snowflake_query", side_effect=_sf_side_effect), \
             patch("pipeline_orchestrator._connector_importable", return_value=True), \
             patch("pipeline_orchestrator._run_code_review", return_value=review_result), \
             patch.dict(os.environ, {"DBT_ENVIRON": "dev"}):

            def _dbt_side_effect(args_list, **kwargs):
                if args_list[0] == "debug":
                    return (0, "  schema: dbt_test_schema", "")
                return (0, "Done. PASS=3 WARN=0 ERROR=0 SKIP=0 TOTAL=3", "")
            mock_dbt.side_effect = _dbt_side_effect

            rc = cmd_implement(_args())

        assert rc == 0  # build succeeded; a validation skip must not fail it
        captured = capsys.readouterr().out
        assert "row-count check skipped" in captured

    def test_clone_target_schema_unparseable_is_fatal(self, tmp_path, capsys):
        """Precondition: if 'dbt debug' yields no parseable target schema, the
        clone cannot refresh BKCC, so implement must FAIL HARD (not skip+build
        against a stale/missing REF_BUSINESS_KEY_COLLISION)."""
        import os
        from pipeline_orchestrator import cmd_implement

        _setup_generated_files(tmp_path)
        state = _base_state()
        review_result = {
            "checks_run": 46, "fail_count": 0, "warn_count": 0, "findings": [],
        }

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_dbt") as mock_dbt, \
             patch("pipeline_orchestrator._run_snowflake_query") as mock_sf, \
             patch("pipeline_orchestrator._connector_importable", return_value=True), \
             patch("pipeline_orchestrator._run_code_review", return_value=review_result), \
             patch.dict(os.environ, {"DBT_ENVIRON": "dev"}):

            mock_dbt.return_value = (0, "  Connection test: OK\n  All checks passed!", "")

            rc = cmd_implement(_args())

        assert rc == 1
        combined = "".join(capsys.readouterr())
        assert "precondition failed" in combined
        mock_sf.assert_not_called()          # clone SQL must never have run
        for c in mock_dbt.call_args_list:    # build must never have been reached
            args_list = c[0][0] if c[0] else []
            assert "build" not in args_list

    def test_clone_dbt_debug_error_is_fatal(self, tmp_path, capsys):
        """Precondition: if 'dbt debug' itself errors, the clone cannot be
        verified, so implement must FAIL HARD rather than build via defer."""
        import os
        from pipeline_orchestrator import cmd_implement

        _setup_generated_files(tmp_path)
        state = _base_state()
        review_result = {
            "checks_run": 46, "fail_count": 0, "warn_count": 0, "findings": [],
        }

        def _dbt_side(args_list, **kw):
            if args_list[0] == "debug":
                raise RuntimeError("dbt not configured")
            return (0, "Done. PASS=1 WARN=0 ERROR=0 SKIP=0 TOTAL=1", "")

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_dbt", side_effect=_dbt_side), \
             patch("pipeline_orchestrator._run_snowflake_query") as mock_sf, \
             patch("pipeline_orchestrator._connector_importable", return_value=True), \
             patch("pipeline_orchestrator._run_code_review", return_value=review_result), \
             patch.dict(os.environ, {"DBT_ENVIRON": "dev"}):

            rc = cmd_implement(_args())

        assert rc == 1
        combined = "".join(capsys.readouterr())
        assert "precondition failed" in combined
        assert "dbt not configured" in combined
        mock_sf.assert_not_called()

    def test_clone_skipped_under_skip_build(self, tmp_path, capsys):
        """--skip-build skips the clone precondition entirely: there is no local
        build to protect, so an unavailable Snowflake path must not block it."""
        import os
        from pipeline_orchestrator import cmd_implement

        _setup_generated_files(tmp_path)
        state = _base_state()
        review_result = {
            "checks_run": 46, "fail_count": 0, "warn_count": 0, "findings": [],
        }

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_dbt") as mock_dbt, \
             patch("pipeline_orchestrator._run_snowflake_query") as mock_sf, \
             patch("pipeline_orchestrator._assert_snowflake_available") as mock_pre, \
             patch("pipeline_orchestrator._run_code_review", return_value=review_result), \
             patch.dict(os.environ, {"DBT_ENVIRON": "dev"}):

            mock_dbt.return_value = (0, "Done. PASS=1 WARN=0 ERROR=0 SKIP=0 TOTAL=1", "")

            cmd_implement(_args(skip_build=True))

        captured = capsys.readouterr().out
        assert "BKCC clone SKIPPED (--skip-build" in captured
        mock_sf.assert_not_called()   # clone SQL never ran
        mock_pre.assert_not_called()  # preflight never even reached


# ---------------------------------------------------------------------------
# Incremental dry-run tests
# ---------------------------------------------------------------------------

class TestIncrementalDryRun:
    """Step [5/8] — dbt run --empty validates incremental SQL."""

    def test_stg_only_skips_dry_run(self, tmp_path, capsys):
        """STG-only pipelines (Option A) should skip step [5/8] dry-run."""
        from pipeline_orchestrator import cmd_implement

        _setup_generated_files(tmp_path)
        state = _base_state(objects=["stg"])

        review_result = {
            "checks_run": 46, "fail_count": 0, "warn_count": 0, "findings": [],
        }

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_dbt") as mock_dbt, \
             patch("pipeline_orchestrator._run_snowflake_query") as mock_sf, \
             patch("pipeline_orchestrator._run_code_review", return_value=review_result):

            def _dbt_side_effect(args_list, **kwargs):
                if args_list[0] == "debug":
                    return (0, "  schema: dbt_test_schema", "")
                return (0, "Done. PASS=3 WARN=0 ERROR=0 SKIP=0 TOTAL=3", "")
            mock_dbt.side_effect = _dbt_side_effect
            mock_sf.return_value = [[42]]

            rc = cmd_implement(_args())

        assert rc == 0

        # Verify --empty was NOT called (only debug + build calls)
        for c in mock_dbt.call_args_list:
            args_list = c[0][0] if c[0] else []
            assert "--empty" not in args_list, \
                f"--empty should not be called for STG-only, got: {args_list}"

        captured = capsys.readouterr().out
        assert "skipped (no Raw Vault models)" in captured or "STG-only pipeline" in captured

    def test_rv_models_trigger_dry_run(self, tmp_path, capsys):
        """Pipelines with RV models should run dbt run --empty at step [5/8]."""
        from pipeline_orchestrator import cmd_implement

        _setup_generated_files(tmp_path, include_sat=True)
        state = _base_state(objects=["stg", "sat"])
        state["sats"] = [{"model_name": "sat_test__src"}]
        state["generated_files"]["sat_sql"] = "scripts/automation/models/raw_vault/sat/sat_test__src.sql"
        state["generated_files"]["sat_yml"] = "scripts/automation/models/raw_vault/sat/sat_test__src.yml"

        review_result = {
            "checks_run": 46, "fail_count": 0, "warn_count": 0, "findings": [],
        }

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_dbt") as mock_dbt, \
             patch("pipeline_orchestrator._run_snowflake_query") as mock_sf, \
             patch("pipeline_orchestrator._run_code_review", return_value=review_result):

            def _dbt_side_effect(args_list, **kwargs):
                if args_list[0] == "debug":
                    return (0, "  schema: dbt_test_schema", "")
                return (0, "Done. PASS=5 WARN=0 ERROR=0 SKIP=0 TOTAL=5", "")
            mock_dbt.side_effect = _dbt_side_effect
            mock_sf.return_value = [[42]]

            rc = cmd_implement(_args())

        assert rc == 0

        # Verify --empty was called with the sat model name
        empty_calls = [
            c for c in mock_dbt.call_args_list
            if c[0] and "--empty" in c[0][0]
        ]
        assert len(empty_calls) == 1, f"Expected 1 --empty call, got {len(empty_calls)}"
        empty_args = empty_calls[0][0][0]
        assert "sat_test__src" in empty_args, f"--empty should target sat_test__src, got: {empty_args}"

        captured = capsys.readouterr().out
        assert "Incremental dry-run passed" in captured

    def test_dry_run_failure_blocks_pr(self, tmp_path, capsys):
        """Dry-run failure blocks the pipeline — incremental syntax error must be fixed."""
        from pipeline_orchestrator import cmd_implement

        _setup_generated_files(tmp_path, include_sat=True)
        state = _base_state(objects=["stg", "sat"])
        state["sats"] = [{"model_name": "sat_test__src"}]
        state["generated_files"]["sat_sql"] = "scripts/automation/models/raw_vault/sat/sat_test__src.sql"
        state["generated_files"]["sat_yml"] = "scripts/automation/models/raw_vault/sat/sat_test__src.yml"

        review_result = {
            "checks_run": 46, "fail_count": 0, "warn_count": 0, "findings": [],
        }

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state") as mock_save, \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_dbt") as mock_dbt, \
             patch("pipeline_orchestrator._run_snowflake_query") as mock_sf, \
             patch("pipeline_orchestrator._run_code_review", return_value=review_result):

            def _dbt_side_effect(args_list, **kwargs):
                if args_list[0] == "debug":
                    return (0, "  schema: dbt_test_schema", "")
                if "--empty" in args_list:
                    # Dry-run fails — incremental block has syntax error
                    return (1, "Database Error in model sat_test__src\n  Compilation Error: dangling AND", "")
                return (0, "Done. PASS=5 WARN=0 ERROR=0 SKIP=0 TOTAL=5", "")
            mock_dbt.side_effect = _dbt_side_effect
            mock_sf.return_value = [[42]]

            rc = cmd_implement(_args())

        # Dry-run failure must block — incremental syntax error breaks next load
        assert rc == 1, f"Dry-run failure should return rc=1, got rc={rc}"

        captured = capsys.readouterr().out
        assert "PIPELINE FAILED" in captured
        assert "Incremental path has syntax errors" in captured
        assert "Fix incremental block syntax before creating PR" in captured
        assert "next incremental production load" in captured

    def test_dry_run_skip_build_skips_dry_run(self, tmp_path, capsys):
        """--skip-build should also skip the dry-run step."""
        from pipeline_orchestrator import cmd_implement

        _setup_generated_files(tmp_path, include_sat=True)
        state = _base_state(objects=["stg", "sat"])
        state["sats"] = [{"model_name": "sat_test__src"}]
        state["generated_files"]["sat_sql"] = "scripts/automation/models/raw_vault/sat/sat_test__src.sql"
        state["generated_files"]["sat_yml"] = "scripts/automation/models/raw_vault/sat/sat_test__src.yml"

        review_result = {
            "checks_run": 46, "fail_count": 0, "warn_count": 0, "findings": [],
        }

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_dbt") as mock_dbt, \
             patch("pipeline_orchestrator._run_code_review", return_value=review_result):

            rc = cmd_implement(_args(skip_build=True))

        assert rc == 0

        # Verify --empty was NOT called
        for c in mock_dbt.call_args_list:
            args_list = c[0][0] if c[0] else []
            assert "--empty" not in args_list, \
                f"--empty should not be called with --skip-build, got: {args_list}"

        captured = capsys.readouterr().out
        assert "SKIPPED (--skip-build)" in captured

    def test_dry_run_keyboard_interrupt_treated_as_pass(self, tmp_path, capsys):
        """KeyboardInterrupt during dry-run (agent timeout) should NOT fail the pipeline."""
        from pipeline_orchestrator import cmd_implement

        _setup_generated_files(tmp_path, include_sat=True)
        state = _base_state(objects=["stg", "sat"])
        state["sats"] = [{"model_name": "sat_test__src"}]
        state["generated_files"]["sat_sql"] = "scripts/automation/models/raw_vault/sat/sat_test__src.sql"
        state["generated_files"]["sat_yml"] = "scripts/automation/models/raw_vault/sat/sat_test__src.yml"

        review_result = {
            "checks_run": 46, "fail_count": 0, "warn_count": 0, "findings": [],
        }

        # Simulate: build passes, dry-run gets KeyboardInterrupt
        keyboard_interrupt_output = (
            "Encountered an error:\n"
            "Traceback (most recent call last):\n"
            "  File \"/venv/dbt-compatible/lib/python3.11/site-packages/dbt/cli/main.py\"\n"
            "KeyboardInterrupt\n"
        )

        def mock_dbt_side_effect(args_list, **kwargs):
            if "--empty" in args_list:
                return (1, keyboard_interrupt_output, "")
            if args_list[0] == "debug":
                return (0, "  schema: dbt_test_schema", "")
            # Normal build pass
            return (0, "Done. PASS=3 WARN=0 ERROR=0 SKIP=0 TOTAL=3", "")

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_dbt", side_effect=mock_dbt_side_effect), \
             patch("pipeline_orchestrator._run_code_review", return_value=review_result), \
             patch("pipeline_orchestrator._run_snowflake_query", return_value=[[42]]):

            rc = cmd_implement(_args())

        assert rc == 0, f"KeyboardInterrupt in dry-run should not fail pipeline, got rc={rc}"

        captured = capsys.readouterr().out
        assert "interrupted" in captured.lower(), \
            "Should report the interrupt was detected"
        assert "Treating dry-run as PASS" in captured, \
            "Should treat KeyboardInterrupt as pass (not a real SQL error)"

    def test_dry_run_session_occupied_retries_with_cancel(self, tmp_path, capsys):
        """Session occupied on first attempt should retry with cancel and succeed."""
        from pipeline_orchestrator import cmd_implement

        _setup_generated_files(tmp_path, include_sat=True)
        state = _base_state(objects=["stg", "sat"])
        state["sats"] = [{"model_name": "sat_test__src"}]
        state["generated_files"]["sat_sql"] = "scripts/automation/models/raw_vault/sat/sat_test__src.sql"
        state["generated_files"]["sat_yml"] = "scripts/automation/models/raw_vault/sat/sat_test__src.yml"

        review_result = {
            "checks_run": 46, "fail_count": 0, "warn_count": 0, "findings": [],
        }

        # First --empty call: session occupied (skip_cancel=True, optimistic)
        # Second --empty call: succeeds (skip_cancel=False, cancel freed session)
        call_count = {"empty": 0}

        def mock_dbt_side_effect(args_list, **kwargs):
            if "--empty" in args_list:
                call_count["empty"] += 1
                if call_count["empty"] == 1:
                    # First attempt (skip_cancel=True): session still occupied
                    return (1, "Encountered an error: Session occupied. Please wait until your invocation has been completed.", "")
                # Second attempt (skip_cancel=False): cancel freed it
                return (0, "Done. PASS=1 WARN=0 ERROR=0 SKIP=0 TOTAL=1", "")
            if args_list[0] == "debug":
                return (0, "  schema: dbt_test_schema", "")
            return (0, "Done. PASS=5 WARN=0 ERROR=0 SKIP=0 TOTAL=5", "")

        with patch("pipeline_orchestrator.PROJECT_ROOT", tmp_path), \
             patch("pipeline_orchestrator._resolve_state", return_value=state), \
             patch("pipeline_orchestrator._save_state"), \
             patch("pipeline_orchestrator._mark_complete"), \
             patch("pipeline_orchestrator._register_source", return_value=True), \
             patch("pipeline_orchestrator._run_dbt", side_effect=mock_dbt_side_effect), \
             patch("pipeline_orchestrator._run_code_review", return_value=review_result), \
             patch("pipeline_orchestrator._run_snowflake_query", return_value=[[42]]), \
             patch("time.sleep"):  # Don't actually wait in tests

            rc = cmd_implement(_args())

        assert rc == 0
        assert call_count["empty"] == 2, f"Expected 2 --empty calls (1 retry), got {call_count['empty']}"

        captured = capsys.readouterr().out
        assert "Session occupied" in captured
        assert "Incremental dry-run passed" in captured
