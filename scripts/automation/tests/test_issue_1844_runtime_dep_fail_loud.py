"""
test_issue_1844_runtime_dep_fail_loud.py

Issue #1844 — enforce the runtime-dependency contract by FAILING LOUDLY on a
missing Snowflake execution path instead of silently returning None and letting
callers coerce the absence into 0 / empty / "skipped".

Design: option (C) — preflight + raise-at-boundary.
  - `_assert_snowflake_available()` preflights Snowflake-dependent commands and
    raises `SnowflakeUnavailableError` before any work when no path exists.
  - `_run_snowflake_query()` raises `SnowflakeUnavailableError` (never returns
    None) when it cannot execute — while a query that DID run and returned zero
    rows stays a legitimate empty list `[]`.

The three hard must-haves these tests guard:
  1. Preflight accepts an MCP-configured environment as a valid path (an MCP-only
     env must NOT be forced to install the connector).
  2. "cannot execute" (fail loud) is distinguished from "ran, returned []"
     (legitimate — never a false alarm).
  3. Callers propagate the exception (a single clean handler in `main()`), so no
     layer silently swallows it back into a no-op.
"""

import ast
import inspect
import os
import sys
import textwrap
from unittest.mock import MagicMock, patch

import pytest

sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parent.parent))

import pipeline_orchestrator as po


_MCP_CREDS = {
    "SNOWFLAKE_ACCOUNT": "acct",
    "SNOWFLAKE_USER": "user",
    "SNOWFLAKE_PAT": "pat-value",
}


# ═══════════════════════════════════════════════════════════════════════════════
# Preflight: _snowflake_execution_path / _assert_snowflake_available
# ═══════════════════════════════════════════════════════════════════════════════

class TestPreflight:
    """The command preflight fails loud only when NO execution path exists."""

    def test_connector_importable_attempts_real_import(self):
        # #1928: find_spec() can locate a connector whose import still fails (a
        # broken / partially-installed dependency tree). _connector_importable must
        # attempt the REAL import and return False, not report the path available
        # just because the module is locatable.
        import builtins
        real_import = builtins.__import__

        def _fail_connector(name, *args, **kwargs):
            if name.startswith("snowflake.connector"):
                raise ImportError("simulated broken dependency tree")
            return real_import(name, *args, **kwargs)

        with patch.object(builtins, "__import__", _fail_connector):
            assert po._connector_importable() is False

    def test_execution_path_prefers_connector_when_importable(self):
        with patch.object(po, "_connector_importable", return_value=True):
            assert po._snowflake_execution_path() == "connector"

    def test_execution_path_is_mcp_when_connector_absent_but_creds_present(self):
        # must-have #1: an MCP-only environment is a valid path.
        with patch.object(po, "_connector_importable", return_value=False), \
             patch.object(po, "_read_mcp_creds", return_value=dict(_MCP_CREDS)):
            assert po._snowflake_execution_path() == "mcp"

    def test_execution_path_is_none_when_neither_available(self):
        with patch.object(po, "_connector_importable", return_value=False), \
             patch.object(po, "_read_mcp_creds", return_value=None):
            assert po._snowflake_execution_path() is None

    def test_execution_path_survives_mcp_creds_read_error(self):
        # A broken mcp.json must not crash the preflight — it just means "no MCP".
        with patch.object(po, "_connector_importable", return_value=False), \
             patch.object(po, "_read_mcp_creds", side_effect=RuntimeError("boom")):
            assert po._snowflake_execution_path() is None

    def test_assert_raises_when_no_path(self):
        with patch.object(po, "_snowflake_execution_path", return_value=None):
            with pytest.raises(po.SnowflakeUnavailableError) as ei:
                po._assert_snowflake_available()
        # message is actionable
        assert "requirements-runtime.txt" in str(ei.value) or "mcp.json" in str(ei.value)

    def test_assert_passes_for_mcp_only_env(self):
        # must-have #1 end-to-end: connector absent + MCP creds present -> no raise.
        with patch.object(po, "_connector_importable", return_value=False), \
             patch.object(po, "_read_mcp_creds", return_value=dict(_MCP_CREDS)):
            po._assert_snowflake_available()  # must not raise

    def test_assert_passes_for_connector_only_env(self):
        with patch.object(po, "_connector_importable", return_value=True), \
             patch.object(po, "_read_mcp_creds", return_value=None):
            po._assert_snowflake_available()  # must not raise


# ═══════════════════════════════════════════════════════════════════════════════
# Boundary: _run_snowflake_query raises instead of returning None
# ═══════════════════════════════════════════════════════════════════════════════

class TestBoundaryRaisesInsteadOfNone:
    """`_run_snowflake_query` never returns None: it returns rows or raises."""

    def test_raises_on_missing_driver(self):
        # CORE #1844 case: MCP falls through AND the connector cannot be imported.
        with patch.object(po, "_read_mcp_config_sdk", return_value={}), \
             patch.object(po, "_mcp_sdk_query", return_value=None), \
             patch.dict(sys.modules, {"snowflake.connector": None}):
            with pytest.raises(po.SnowflakeUnavailableError) as ei:
                po._run_snowflake_query("SELECT 1", MagicMock())
        assert "not installed" in str(ei.value)
        assert po._run_snowflake_query.last_error == "snowflake-connector-python not installed"

    def test_ddl_missing_driver_message_is_ddl_aware(self):
        # A DDL statement skips MCP (snow-mcp rejects DDL), so a driver-free env
        # must not claim the MCP path is "unavailable" -- it must say the
        # connector is required for DDL even when MCP is configured.
        with patch.dict(sys.modules, {"snowflake.connector": None}):
            with pytest.raises(po.SnowflakeUnavailableError) as ei:
                po._run_snowflake_query("CREATE OR REPLACE TABLE t CLONE s", MagicMock())
        msg = str(ei.value)
        assert "DDL" in msg and "connector is required" in msg
        assert "MCP path is unavailable" not in msg

    def test_raises_on_no_credentials(self):
        # Driver importable, MCP falls through, but no credentials anywhere.
        env = {k: "" for k in (
            "SNOWFLAKE_PAT", "SNOWFLAKE_PASSWORD", "SNOWFLAKE_ACCOUNT", "SNOWFLAKE_USER",
        )}
        args = MagicMock()
        args.snowflake_conn = None
        with patch.object(po, "_read_mcp_config_sdk", return_value={}), \
             patch.object(po, "_mcp_sdk_query", return_value=None), \
             patch.object(po, "_read_mcp_creds", return_value=None), \
             patch.dict(os.environ, env, clear=False):
            with pytest.raises(po.SnowflakeUnavailableError) as ei:
                po._run_snowflake_query("SELECT 1", args)
        assert "credentials" in str(ei.value).lower()

    def test_returns_empty_list_is_legitimate_not_raise(self):
        # must-have #2: a query that RAN and matched zero rows returns [], not None,
        # and must NOT be turned into a false "cannot execute" alarm.
        with patch.object(po, "_read_mcp_config_sdk", return_value={}), \
             patch.object(po, "_mcp_sdk_query", return_value=[]):
            result = po._run_snowflake_query("SELECT * FROM t WHERE 1=0", MagicMock())
        assert result == []

    def test_returns_rows_on_success(self):
        with patch.object(po, "_read_mcp_config_sdk", return_value={}), \
             patch.object(po, "_mcp_sdk_query", return_value=[("X", "5")]):
            result = po._run_snowflake_query("SELECT name, n FROM t", MagicMock())
        # MCP string values are coerced to native types downstream.
        assert result == [("X", 5)]

    def test_source_contract_never_returns_none(self):
        # Raise-contract (conformance): no `return None` may reappear in the
        # boundary function — that would let a caller silently swallow it again.
        src = textwrap.dedent(inspect.getsource(po._run_snowflake_query))
        tree = ast.parse(src)
        offenders = [
            node.lineno
            for node in ast.walk(tree)
            if isinstance(node, ast.Return)
            and (node.value is None
                 or (isinstance(node.value, ast.Constant) and node.value.value is None))
        ]
        assert not offenders, (
            f"_run_snowflake_query must never `return None` (found at relative "
            f"lines {offenders}); raise SnowflakeUnavailableError instead."
        )


# ═══════════════════════════════════════════════════════════════════════════════
# Callers propagate — no silent swallow one layer up (must-have #3)
# ═══════════════════════════════════════════════════════════════════════════════

class TestCallersPropagate:
    """The exception reaches a single clean handler; no caller swallows it."""

    def _profile_state(self):
        return {
            "model_name": "v_psa_stg_widget__acme",
            "schema": "acme_src",
            "table": "widget",
            "bk": "WIDGET_ID",
        }

    def _profile_args(self):
        args = MagicMock()
        args.model_name = None
        args.profile_json = None
        args.grain_columns = None
        args.load_dts_column = None
        args.hk = None
        return args

    def test_cmd_profile_propagates_preflight_failure(self):
        # cmd_profile must NOT catch the preflight failure — it propagates so the
        # single main() handler reports it and exits non-zero.
        with patch.object(po, "_resolve_state", return_value=self._profile_state()), \
             patch.object(po, "_check_prerequisites", return_value=(True, [])), \
             patch.object(po, "_save_state"), \
             patch.object(po, "_snowflake_execution_path", return_value=None):
            with pytest.raises(po.SnowflakeUnavailableError):
                po.cmd_profile(self._profile_args())

    def test_cmd_profile_profile_json_bypasses_preflight(self):
        # The driver-free escape hatch must still work with NO execution path.
        args = self._profile_args()
        args.profile_json = "/tmp/precomputed_profile.json"
        with patch.object(po, "_resolve_state", return_value=self._profile_state()), \
             patch.object(po, "_check_prerequisites", return_value=(True, [])), \
             patch.object(po, "_save_state"), \
             patch.object(po, "_snowflake_execution_path", return_value=None), \
             patch.object(po, "_load_profile_json", return_value=0) as mock_load:
            rc = po.cmd_profile(args)
        assert rc == 0
        mock_load.assert_called_once()


# ═══════════════════════════════════════════════════════════════════════════════
# main() converts the exception into a clean, actionable, non-zero exit
# ═══════════════════════════════════════════════════════════════════════════════

class TestMainHandler:
    """A missing execution path exits non-zero with guidance and NO traceback."""

    def test_main_snowflake_unavailable_clean_exit(self, capsys):
        def _boom(_args):
            raise po.SnowflakeUnavailableError("driver missing and MCP unavailable")

        with patch.object(po, "cmd_status", _boom), \
             patch.object(sys, "argv", ["pipeline_orchestrator.py", "status"]):
            rc = po.main()

        assert rc == 1
        combined = "".join(capsys.readouterr())
        assert "driver missing and MCP unavailable" in combined
        assert "requirements-runtime.txt" in combined  # actionable guidance
        assert "Traceback" not in combined              # expected failure, not a crash
