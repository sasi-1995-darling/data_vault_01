"""Component 8 — StdioMcpDbtCloudClient + FixtureReplayDbtCloudClient tests.

Five-mutation defeater battery plus fixture-replay + projection-shape
coverage. Maps 1:1 to the C8 directive's mutation table:

    Mutation A — class rename not applied (cron_entrypoint still
                 references UrllibDbtCloudClient)         → ``TestNameCorrection``
    Mutation B — env composed via **os.environ (splat)
                 instead of explicit DBT_* allowlist      → ``TestEnvAllowlist``
    Mutation C — client swallows failure & returns None
                 instead of raising DbtMcpInvocationError → ``TestFailOpenSemantics``
    Mutation D — signature drifts from poll-loop Protocol
                 (positional args / renamed kwargs)       → ``TestProtocolMatch``
    Mutation E — session not closed; stdio leaks across
                 calls                                    → ``TestLifecyclePin``

Plus:
    * ``TestFixtureReplayClient``  — Python-method seam never enters
      asyncio / stdio (precedent: ``sprint-1-deferred.md:717-734``).
    * ``TestProjectionShape``       — ``get_job_run_error`` returns
      ``{"failed_steps": ...}`` at TOP level (no ``data`` wrapper),
      matching C4 adapter input contract.

All tests use in-process fakes (``FakeAsyncContext``, ``FakeSession``,
``FakeToolResult``, ``FakeContentItem``) to mock the mcp SDK without
spawning a real ``uvx`` subprocess or hitting cloud.getdbt.com. The
mcp SDK itself does NOT need to be installed for these tests to run —
the fakes are injected via ``monkeypatch.setattr`` before any lazy
import path would resolve.
"""

from __future__ import annotations

import asyncio
import inspect
import json
import os
import sys
import types
from typing import Any, Callable

import pytest

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
if REPO_ROOT not in sys.path:
    sys.path.insert(0, REPO_ROOT)

from scripts.automation.src.triage import dbt_cloud_client  # noqa: E402
from scripts.automation.src.triage.dbt_cloud_client import (  # noqa: E402
    DBT_INJECTED_ENV_VARS,
    DBT_PASSTHROUGH_ENV_VARS,
    DBT_REQUIRED_ENV_VARS,
    DbtMcpEnvVarMissing,
    DbtMcpInvocationError,
    FixtureReplayDbtCloudClient,
    StdioMcpDbtCloudClient,
)


# ---------------------------------------------------------------------------
# Test infrastructure — in-process fakes for the mcp SDK
# ---------------------------------------------------------------------------


class FakeContentItem:
    """Mimics ``mcp.types.TextContent`` — has a ``.text`` attribute."""

    def __init__(self, text: str | None) -> None:
        self.text = text


class FakeToolResult:
    """Mimics ``mcp.types.CallToolResult`` — ``.content`` + ``.isError``
    (+ optional ``.structuredContent``, the authoritative payload channel)."""

    def __init__(
        self,
        *,
        content: list[FakeContentItem],
        is_error: bool = False,
        structured_content: Any = None,
    ) -> None:
        self.content = content
        self.isError = is_error
        # Real CallToolResult always exposes this attribute (None when the
        # tool has no output schema); mirror that so the parser's
        # getattr(result, "structuredContent", None) sees it.
        self.structuredContent = structured_content


class FakeSession:
    """Mimics ``mcp.ClientSession`` enough for the client's needs.

    Records ``initialize`` + ``call_tool`` invocations so tests can
    assert on shapes/counts/args. ``call_tool`` returns scripted
    ``FakeToolResult`` instances (or raises if scripted to).
    """

    def __init__(
        self,
        *,
        tool_response: FakeToolResult | None = None,
        tool_responses: list[Any] | None = None,
    ) -> None:
        self.initialize_called = 0
        self.call_tool_calls: list[tuple[str, dict]] = []
        if tool_responses is not None:
            self._scripted: list[Any] = list(tool_responses)
        else:
            self._scripted = [tool_response] if tool_response is not None else []
        self.closed = False

    async def __aenter__(self) -> "FakeSession":
        return self

    async def __aexit__(self, *args: Any) -> bool:
        self.closed = True
        return False

    async def initialize(self) -> None:
        self.initialize_called += 1

    async def call_tool(self, name: str, args: dict) -> FakeToolResult:
        self.call_tool_calls.append((name, dict(args)))
        if not self._scripted:
            raise AssertionError(
                f"FakeSession.call_tool unscripted for ({name!r}, {args!r})"
            )
        next_val = self._scripted.pop(0)
        if isinstance(next_val, BaseException):
            raise next_val
        return next_val


class FakeAsyncContext:
    """Async context manager that yields a fixed value on ``__aenter__``."""

    def __init__(self, value: Any, *, on_close: Callable[[], None] | None = None) -> None:
        self._value = value
        self._on_close = on_close
        self.entered = False
        self.exited = False

    async def __aenter__(self) -> Any:
        self.entered = True
        return self._value

    async def __aexit__(self, *args: Any) -> bool:
        self.exited = True
        if self._on_close is not None:
            self._on_close()
        return False


class StdioRecorder:
    """Records every call to ``stdio_client`` + the lifecycle of its ctx."""

    def __init__(self) -> None:
        self.spawn_count = 0
        self.contexts: list[FakeAsyncContext] = []
        self.last_server_params: Any = None
        self.session_factory: Callable[[], FakeSession] = lambda: FakeSession()

    def stdio_client_factory(self, server_params: Any) -> FakeAsyncContext:
        self.spawn_count += 1
        self.last_server_params = server_params
        ctx = FakeAsyncContext((object(), object()))  # (read, write) pipes
        self.contexts.append(ctx)
        return ctx

    def client_session_factory(self, read: Any, write: Any) -> FakeSession:
        return self.session_factory()


def _install_mcp_fakes(
    monkeypatch: pytest.MonkeyPatch,
    recorder: StdioRecorder,
    *,
    sessions: list[FakeSession] | None = None,
) -> None:
    """Inject fake mcp.* into sys.modules so lazy imports resolve to fakes.

    The client lazily imports ``mcp`` and ``mcp.client.stdio`` inside its
    methods (so unit tests that never trigger a call path don't require
    the mcp package to be installed). Tests that DO trigger a call path
    monkeypatch ``sys.modules`` to fake module instances exposing the
    minimal surface the client uses.
    """
    session_iter = iter(sessions) if sessions is not None else None

    def session_factory() -> FakeSession:
        if session_iter is None:
            return FakeSession()
        try:
            return next(session_iter)
        except StopIteration as exc:
            raise AssertionError(
                "test wired fewer sessions than the client requested"
            ) from exc

    recorder.session_factory = session_factory

    fake_mcp = types.ModuleType("mcp")
    fake_mcp.ClientSession = recorder.client_session_factory  # type: ignore[attr-defined]
    fake_mcp.StdioServerParameters = lambda **kwargs: kwargs  # type: ignore[attr-defined]

    fake_mcp_client = types.ModuleType("mcp.client")
    fake_mcp_client_stdio = types.ModuleType("mcp.client.stdio")
    fake_mcp_client_stdio.stdio_client = recorder.stdio_client_factory  # type: ignore[attr-defined]
    fake_mcp_client.stdio = fake_mcp_client_stdio  # type: ignore[attr-defined]

    monkeypatch.setitem(sys.modules, "mcp", fake_mcp)
    monkeypatch.setitem(sys.modules, "mcp.client", fake_mcp_client)
    monkeypatch.setitem(sys.modules, "mcp.client.stdio", fake_mcp_client_stdio)


def _set_required_env(monkeypatch: pytest.MonkeyPatch) -> None:
    """Plant every DBT_REQUIRED_ENV_VARS entry (incl. the non-DBT_*
    MULTICELL_ACCOUNT_PREFIX) with stable test values."""
    monkeypatch.setenv("DBT_HOST", "us1.dbt.com")
    monkeypatch.setenv("MULTICELL_ACCOUNT_PREFIX", "kl673")
    monkeypatch.setenv("DBT_PROD_ENV_ID", "296881")
    monkeypatch.setenv("DBT_DEV_ENV_ID", "287190")


# ===========================================================================
# Mutation A — TestNameCorrection
# ===========================================================================


class TestNameCorrection:
    """Mutation A: rename UrllibDbtCloudClient → StdioMcpDbtCloudClient.

    If the rename is NOT applied (i.e. cron_entrypoint still references
    UrllibDbtCloudClient OR the new class does not exist), these tests
    fail.
    """

    def test_stdio_mcp_dbt_cloud_client_class_exists_at_module_attribute(self) -> None:
        assert hasattr(dbt_cloud_client, "StdioMcpDbtCloudClient")
        assert isinstance(dbt_cloud_client.StdioMcpDbtCloudClient, type)

    def test_urllib_dbt_cloud_client_does_not_exist(self) -> None:
        # Strict ABSENCE assertion — the old name must not be reachable
        # via any attribute path on the module.
        assert not hasattr(dbt_cloud_client, "UrllibDbtCloudClient"), (
            "UrllibDbtCloudClient is the pre-C8 placeholder name; the "
            "rename to StdioMcpDbtCloudClient must be exclusive."
        )

    def test_cron_entrypoint_imports_renamed_class(self) -> None:
        # Source-level check (not import-time) so we don't pull
        # cron_entrypoint's heavy deps. The string must appear and the
        # old name must not.
        from scripts.automation.src.triage import cron_entrypoint

        source = inspect.getsource(cron_entrypoint)
        assert "StdioMcpDbtCloudClient" in source, (
            "cron_entrypoint must construct the renamed class"
        )
        assert "UrllibDbtCloudClient" not in source, (
            "cron_entrypoint must not reference the pre-C8 name"
        )


# ===========================================================================
# Mutation B — TestEnvAllowlist (the HARDEST READ — env hygiene)
# ===========================================================================


class TestEnvAllowlist:
    """Mutation B: subprocess env must use explicit DBT_* allowlist.

    Splat-merging ``**os.environ`` is rejected by these tests via
    ABSENCE assertions on planted non-DBT secrets.
    """

    def test_required_dbt_vars_present_in_composed_env(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        _set_required_env(monkeypatch)
        client = StdioMcpDbtCloudClient(api_token="TOKEN_xyz", account_id=999)
        env = client._compose_subprocess_env()
        assert env["DBT_TOKEN"] == "TOKEN_xyz"
        for var in DBT_REQUIRED_ENV_VARS:
            assert var in env, f"required DBT_* var missing: {var}"

    def test_account_id_injected_under_dbt_mcp_name(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        # dbt-mcp's Admin API is account-scoped and reads DBT_ACCOUNT_ID.
        # The client must inject the constructor's account_id under THAT
        # name — not the workflow-side DBT_CLOUD_ACCOUNT_ID. A missing
        # DBT_ACCOUNT_ID is what would crash the cron's first Admin API
        # call (list_jobs_runs).
        _set_required_env(monkeypatch)
        client = StdioMcpDbtCloudClient(api_token="TOKEN", account_id=173296)
        env = client._compose_subprocess_env()
        assert env["DBT_ACCOUNT_ID"] == "173296"
        assert "DBT_CLOUD_ACCOUNT_ID" not in env, (
            "dbt-mcp reads DBT_ACCOUNT_ID; the workflow-side name must "
            "NOT leak into the subprocess env"
        )

    def test_admin_api_toolset_enabled_in_subprocess_env(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        # The cron calls only Admin API tools (list_jobs_runs /
        # get_job_run_error). Pin DBT_MCP_ENABLE_ADMIN_API=true so a
        # refactor cannot silently drop the toolset scoping.
        _set_required_env(monkeypatch)
        client = StdioMcpDbtCloudClient(api_token="TOKEN", account_id=1)
        env = client._compose_subprocess_env()
        assert env["DBT_MCP_ENABLE_ADMIN_API"] == "true"

    def test_execute_sql_only_vars_not_required(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        # DBT_USER_ID (execute_sql-only) and DBT_QA_ENV_ID (not a
        # recognized dbt-mcp var) must NOT be required by the admin-only
        # cron. Regression: requiring them loud-failed the never-run cron
        # on config dbt-mcp's Admin API does not consume.
        _set_required_env(monkeypatch)
        monkeypatch.delenv("DBT_USER_ID", raising=False)
        monkeypatch.delenv("DBT_QA_ENV_ID", raising=False)
        client = StdioMcpDbtCloudClient(api_token="TOKEN", account_id=1)
        env = client._compose_subprocess_env()  # must NOT raise
        assert "DBT_USER_ID" not in env
        assert "DBT_QA_ENV_ID" not in env

    def test_dbt_token_sourced_from_constructor_not_environ(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        _set_required_env(monkeypatch)
        # If a different DBT_TOKEN happens to be in the process env, the
        # client must IGNORE it — token flows from the constructor arg.
        monkeypatch.setenv("DBT_TOKEN", "WRONG_TOKEN_from_environ")
        client = StdioMcpDbtCloudClient(api_token="CORRECT_TOKEN", account_id=1)
        env = client._compose_subprocess_env()
        assert env["DBT_TOKEN"] == "CORRECT_TOKEN"

    @pytest.mark.parametrize(
        "secret_name",
        ["SNOWFLAKE_PASSWORD", "GITHUB_TOKEN", "AWS_SECRET_ACCESS_KEY"],
    )
    def test_non_dbt_secret_absent_from_subprocess_env(
        self, monkeypatch: pytest.MonkeyPatch, secret_name: str
    ) -> None:
        # Plant a fake secret in the test process's env. If the client
        # splat-merged **os.environ, this secret would leak into the
        # subprocess env. The allowlist must keep it out.
        _set_required_env(monkeypatch)
        monkeypatch.setenv(secret_name, f"PLANTED_SECRET_VALUE_for_{secret_name}")
        client = StdioMcpDbtCloudClient(api_token="TOKEN", account_id=1)
        env = client._compose_subprocess_env()
        assert secret_name not in env, (
            f"secret {secret_name!r} leaked into dbt-mcp subprocess env "
            f"— allowlist is not exclusive"
        )

    def test_no_unlisted_env_var_leaks_into_subprocess_env(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        # Plant arbitrarily-named vars that are NOT on the allowlist and
        # NOT on the passthrough list. None should appear in the env.
        _set_required_env(monkeypatch)
        for unlisted in (
            "RANDOM_VAR_FROM_RUNNER",
            "CI_CONFIG_PATH",
            "VAULT_TOKEN",
            "OPENAI_API_KEY",
        ):
            monkeypatch.setenv(unlisted, "PLANTED")
        client = StdioMcpDbtCloudClient(api_token="TOKEN", account_id=1)
        env = client._compose_subprocess_env()
        # Compute the union of every name the client is allowed to copy.
        allowed = (
            set(DBT_INJECTED_ENV_VARS)
            | set(DBT_REQUIRED_ENV_VARS)
            | set(DBT_PASSTHROUGH_ENV_VARS)
        )
        for key in env:
            assert key in allowed, (
                f"unexpected env var leaked into subprocess env: {key!r}"
            )

    @pytest.mark.parametrize("missing_var", list(DBT_REQUIRED_ENV_VARS))
    def test_missing_required_dbt_var_raises_loudly_with_name(
        self, monkeypatch: pytest.MonkeyPatch, missing_var: str
    ) -> None:
        _set_required_env(monkeypatch)
        monkeypatch.delenv(missing_var, raising=False)
        client = StdioMcpDbtCloudClient(api_token="TOKEN", account_id=1)
        with pytest.raises(DbtMcpEnvVarMissing) as exc_info:
            client._compose_subprocess_env()
        assert missing_var in str(exc_info.value), (
            f"DbtMcpEnvVarMissing message must name the missing var "
            f"({missing_var!r}) so cron logs surface the gap"
        )

    @pytest.mark.parametrize("blank_value", ["", "   "])
    @pytest.mark.parametrize("blank_var", list(DBT_REQUIRED_ENV_VARS))
    def test_empty_required_dbt_var_raises_loudly_with_name(
        self,
        monkeypatch: pytest.MonkeyPatch,
        blank_var: str,
        blank_value: str,
    ) -> None:
        # GitHub Actions resolves an undefined secret/var to an EMPTY
        # string, so a blank required var is the same misconfiguration as
        # a missing one — it must loud-fail here (naming the var) rather
        # than feed '' to dbt-mcp for an opaque downstream auth/config
        # error. Pins the empty-value guard a refactor could drop.
        _set_required_env(monkeypatch)
        monkeypatch.setenv(blank_var, blank_value)
        client = StdioMcpDbtCloudClient(api_token="TOKEN", account_id=1)
        with pytest.raises(DbtMcpEnvVarMissing) as exc_info:
            client._compose_subprocess_env()
        assert blank_var in str(exc_info.value), (
            f"DbtMcpEnvVarMissing message must name the blank var "
            f"({blank_var!r}) so cron logs surface the gap"
        )

    def test_path_passthrough_present_when_in_environ(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        _set_required_env(monkeypatch)
        monkeypatch.setenv("PATH", "/usr/bin:/custom/path")
        client = StdioMcpDbtCloudClient(api_token="TOKEN", account_id=1)
        env = client._compose_subprocess_env()
        assert env["PATH"] == "/usr/bin:/custom/path", (
            "PATH passthrough lets uvx resolve itself in the subprocess"
        )

    def test_home_passthrough_present_when_in_environ(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        _set_required_env(monkeypatch)
        monkeypatch.setenv("HOME", "/runner/home")
        client = StdioMcpDbtCloudClient(api_token="TOKEN", account_id=1)
        env = client._compose_subprocess_env()
        assert env["HOME"] == "/runner/home"

    def test_passthrough_silently_omitted_when_var_unset(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        # If PATH is somehow unset in the process env, the client must
        # not raise — passthroughs are best-effort, distinct from
        # required vars.
        _set_required_env(monkeypatch)
        monkeypatch.delenv("PATH", raising=False)
        monkeypatch.delenv("HOME", raising=False)
        client = StdioMcpDbtCloudClient(api_token="TOKEN", account_id=1)
        env = client._compose_subprocess_env()  # must not raise
        assert "PATH" not in env
        assert "HOME" not in env

    def test_allowlist_constants_match_documented_set(self) -> None:
        # Pin the allowlist contents — adding/removing an entry must be
        # a deliberate test edit, not an unchecked drift.
        assert DBT_REQUIRED_ENV_VARS == (
            "DBT_HOST",
            "MULTICELL_ACCOUNT_PREFIX",
            "DBT_PROD_ENV_ID",
            "DBT_DEV_ENV_ID",
        )
        assert DBT_INJECTED_ENV_VARS == (
            "DBT_TOKEN",
            "DBT_ACCOUNT_ID",
            "DBT_MCP_ENABLE_ADMIN_API",
        )
        assert DBT_PASSTHROUGH_ENV_VARS == ("PATH", "HOME")


# ===========================================================================
# Mutation C — TestFailOpenSemantics
# ===========================================================================


class TestFailOpenSemantics:
    """Mutation C: failures must RAISE; None preserved as 'no error found'."""

    def test_list_jobs_runs_raises_on_session_initialize_failure(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        _set_required_env(monkeypatch)
        recorder = StdioRecorder()
        # Session whose call_tool path will never be reached because
        # initialize raises. We simulate the failure by injecting an
        # exception-yielding stdio_client.
        broken_ctx = FakeAsyncContext((object(), object()))

        async def broken_aenter(self_: Any) -> Any:
            raise OSError("stdio pipe refused")

        broken_ctx.__class__ = type(
            "BrokenCtx",
            (FakeAsyncContext,),
            {"__aenter__": broken_aenter},
        )
        recorder.stdio_client_factory = lambda server_params: broken_ctx  # type: ignore[assignment]
        _install_mcp_fakes(monkeypatch, recorder)

        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        with pytest.raises(DbtMcpInvocationError) as exc_info:
            client.list_jobs_runs(status="error", job_id=786800, limit=20, offset=0)
        assert "list_jobs_runs" in str(exc_info.value)
        assert "OSError" in str(exc_info.value) or "stdio pipe refused" in str(exc_info.value)

    def test_get_job_run_error_raises_typed_on_is_error_response(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        _set_required_env(monkeypatch)
        recorder = StdioRecorder()
        session = FakeSession(
            tool_response=FakeToolResult(
                content=[FakeContentItem("Run not found")],
                is_error=True,
            ),
        )
        _install_mcp_fakes(monkeypatch, recorder, sessions=[session])

        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        with pytest.raises(DbtMcpInvocationError) as exc_info:
            client.get_job_run_error(run_id=999_999)
        assert "isError=True" in str(exc_info.value)
        assert "Run not found" in str(exc_info.value)

    def test_get_job_run_error_returns_none_when_response_has_no_text_content(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        # 'no error found' state: content is empty / has no .text — this
        # is legitimate, must not raise, must return None.
        _set_required_env(monkeypatch)
        recorder = StdioRecorder()
        session = FakeSession(
            tool_response=FakeToolResult(content=[], is_error=False),
        )
        _install_mcp_fakes(monkeypatch, recorder, sessions=[session])

        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        result = client.get_job_run_error(run_id=12345)
        assert result is None, (
            "no-text-content response must be returned as None "
            "(distinct from raise — Decision 3 semantics)"
        )

    def test_get_job_run_error_raises_on_non_json_text_content(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        _set_required_env(monkeypatch)
        recorder = StdioRecorder()
        session = FakeSession(
            tool_response=FakeToolResult(
                content=[FakeContentItem("not valid json {{{")],
                is_error=False,
            ),
        )
        _install_mcp_fakes(monkeypatch, recorder, sessions=[session])

        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        with pytest.raises(DbtMcpInvocationError) as exc_info:
            client.get_job_run_error(run_id=12345)
        assert "non-JSON" in str(exc_info.value)

    def test_get_job_run_error_raises_when_dbt_mcp_returns_non_dict(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        # If dbt-mcp returns a JSON array or scalar where a dict is
        # expected, the client must raise (not coerce / not return).
        _set_required_env(monkeypatch)
        recorder = StdioRecorder()
        session = FakeSession(
            tool_response=FakeToolResult(
                content=[FakeContentItem(json.dumps([1, 2, 3]))],
                is_error=False,
            ),
        )
        _install_mcp_fakes(monkeypatch, recorder, sessions=[session])

        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        with pytest.raises(DbtMcpInvocationError) as exc_info:
            client.get_job_run_error(run_id=1)
        assert "expected JSON object" in str(exc_info.value)

    def test_list_jobs_runs_raises_when_dbt_mcp_returns_non_list(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        _set_required_env(monkeypatch)
        recorder = StdioRecorder()
        session = FakeSession(
            tool_response=FakeToolResult(
                content=[FakeContentItem(json.dumps({"oops": "scalar"}))],
                is_error=False,
            ),
        )
        _install_mcp_fakes(monkeypatch, recorder, sessions=[session])

        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        with pytest.raises(DbtMcpInvocationError) as exc_info:
            client.list_jobs_runs(status="error", job_id=786800, limit=20, offset=0)
        assert "expected JSON list" in str(exc_info.value)

    def test_env_var_missing_propagates_distinct_from_invocation_error(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        # The poll loop's C6 dead-letter taxonomy may want to surface
        # config gaps differently from transport failures. The two
        # exception classes must NOT collapse into one another.
        _set_required_env(monkeypatch)
        monkeypatch.delenv("DBT_HOST", raising=False)
        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        with pytest.raises(DbtMcpEnvVarMissing):
            client.list_jobs_runs(status="error", job_id=1, limit=20, offset=0)

    def test_dbt_mcp_env_var_missing_is_distinct_class_from_invocation_error(
        self,
    ) -> None:
        assert not issubclass(DbtMcpEnvVarMissing, DbtMcpInvocationError)
        assert not issubclass(DbtMcpInvocationError, DbtMcpEnvVarMissing)
        # Both must be RuntimeError-ish for ergonomic broad catches.
        assert issubclass(DbtMcpEnvVarMissing, RuntimeError)
        assert issubclass(DbtMcpInvocationError, RuntimeError)


# ===========================================================================
# TestStructuredContentParsing — MCP-SDK envelope (verified 2026-07-02)
# ===========================================================================


class TestStructuredContentParsing:
    """The MCP SDK returns a tool's value in ``structuredContent`` as
    ``{"result": <value>}`` and FLATTENS a list return across the
    unstructured ``content`` channel (one item per element). The client
    MUST read ``structuredContent`` so a multi-run ``list_jobs_runs`` does
    not silently collapse to run #1. Ground truth: mcp 1.26.0 /
    dbt-mcp 1.19.2 (client returns a bare ``list[dict]``; the SDK wraps it
    under ``result``; ``_convert_to_content`` flattens lists).
    """

    def test_list_jobs_runs_returns_full_list_from_structured_content(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        # TRIPWIRE — the exact 2026-07-02 regression. structuredContent
        # carries all 3 runs; the flattened ``content`` (one item per run)
        # would yield only run #1 if the parser wrongly read content[0].
        _set_required_env(monkeypatch)
        runs = [{"id": 101}, {"id": 102}, {"id": 103}]
        recorder = StdioRecorder()
        session = FakeSession(
            tool_response=FakeToolResult(
                # Real dbt-mcp flattens the list here (one item per run)...
                content=[FakeContentItem(json.dumps(r)) for r in runs],
                # ...and carries the whole list here (authoritative).
                structured_content={"result": runs},
            ),
        )
        _install_mcp_fakes(monkeypatch, recorder, sessions=[session])

        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        out = client.list_jobs_runs(status="error", job_id=786800, limit=20, offset=0)
        assert out == runs, (
            "list_jobs_runs MUST return the full list from structuredContent "
            "— not just the first flattened content item (the multi-run "
            "silent-drop regression)"
        )

    def test_structured_content_preferred_over_flattened_content(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        # If content[0] and structuredContent disagree, structuredContent
        # wins — content is a lossy, flattened view of a list return.
        _set_required_env(monkeypatch)
        runs = [{"id": 1}, {"id": 2}]
        recorder = StdioRecorder()
        session = FakeSession(
            tool_response=FakeToolResult(
                content=[FakeContentItem(json.dumps({"id": 1}))],  # only run #1
                structured_content={"result": runs},  # full list
            ),
        )
        _install_mcp_fakes(monkeypatch, recorder, sessions=[session])
        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        out = client.list_jobs_runs(status="error", job_id=1, limit=20, offset=0)
        assert out == runs

    def test_get_job_run_error_unwraps_dict_from_structured_content(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        _set_required_env(monkeypatch)
        payload = {"failed_steps": [{"name": "dbt run"}]}
        recorder = StdioRecorder()
        session = FakeSession(
            tool_response=FakeToolResult(
                content=[FakeContentItem(json.dumps(payload))],
                structured_content={"result": payload},
            ),
        )
        _install_mcp_fakes(monkeypatch, recorder, sessions=[session])
        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        assert client.get_job_run_error(run_id=42) == payload

    def test_get_job_run_error_none_result_preserved_through_structured_path(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        # "no error found" semantics: structuredContent {"result": None} must
        # still surface as None (not a raise, not an empty dict).
        _set_required_env(monkeypatch)
        recorder = StdioRecorder()
        session = FakeSession(
            tool_response=FakeToolResult(
                content=[],
                structured_content={"result": None},
            ),
        )
        _install_mcp_fakes(monkeypatch, recorder, sessions=[session])
        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        assert client.get_job_run_error(run_id=7) is None

    def test_fallback_to_content_when_structured_absent(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        # Care-point: prove the fallback path is LIVE (structuredContent
        # absent → parse the JSON text item). A legacy / non-annotated server
        # that puts the whole list in one content item must still parse —
        # otherwise the fallback is untested code shipped on faith.
        _set_required_env(monkeypatch)
        runs = [{"id": 9}, {"id": 10}]
        recorder = StdioRecorder()
        session = FakeSession(
            tool_response=FakeToolResult(
                content=[FakeContentItem(json.dumps(runs))],  # whole list, one item
                structured_content=None,  # no structured channel
            ),
        )
        _install_mcp_fakes(monkeypatch, recorder, sessions=[session])
        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        assert client.list_jobs_runs(status="error", job_id=1, limit=20, offset=0) == runs

    def test_structured_content_wrong_inner_type_still_fails_loud(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        # The loud-fail property must survive the structuredContent path: a
        # dict where list_jobs_runs expects a list still raises.
        _set_required_env(monkeypatch)
        recorder = StdioRecorder()
        session = FakeSession(
            tool_response=FakeToolResult(
                content=[],
                structured_content={"result": {"oops": "not a list"}},
            ),
        )
        _install_mcp_fakes(monkeypatch, recorder, sessions=[session])
        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        with pytest.raises(DbtMcpInvocationError) as exc_info:
            client.list_jobs_runs(status="error", job_id=1, limit=20, offset=0)
        assert "expected JSON list" in str(exc_info.value)


# ===========================================================================
# Mutation D — TestProtocolMatch
# ===========================================================================


class TestProtocolMatch:
    """Mutation D: signatures EXACTLY match FakeDbtCloudClient."""

    def test_list_jobs_runs_signature_matches_fake(self) -> None:
        # Import the fake from the existing poll-loop test module.
        from scripts.automation.tests.test_triage_poll_loop import FakeDbtCloudClient

        real_sig = inspect.signature(StdioMcpDbtCloudClient.list_jobs_runs)
        fake_sig = inspect.signature(FakeDbtCloudClient.list_jobs_runs)
        # Param NAMES + KIND must match (positional-or-keyword-only).
        # Excluding 'self' on both sides (it appears in both, same kind).
        real_params = {
            name: p.kind
            for name, p in real_sig.parameters.items()
            if name != "self"
        }
        fake_params = {
            name: p.kind
            for name, p in fake_sig.parameters.items()
            if name != "self"
        }
        assert real_params == fake_params, (
            f"signature drift: real={real_params} fake={fake_params}"
        )

    def test_get_job_run_error_signature_matches_fake(self) -> None:
        from scripts.automation.tests.test_triage_poll_loop import FakeDbtCloudClient

        real_sig = inspect.signature(StdioMcpDbtCloudClient.get_job_run_error)
        fake_sig = inspect.signature(FakeDbtCloudClient.get_job_run_error)
        real_params = {
            name: p.kind
            for name, p in real_sig.parameters.items()
            if name != "self"
        }
        fake_params = {
            name: p.kind
            for name, p in fake_sig.parameters.items()
            if name != "self"
        }
        assert real_params == fake_params, (
            f"signature drift: real={real_params} fake={fake_params}"
        )

    def test_list_jobs_runs_params_are_keyword_only(self) -> None:
        sig = inspect.signature(StdioMcpDbtCloudClient.list_jobs_runs)
        non_self = [p for n, p in sig.parameters.items() if n != "self"]
        for p in non_self:
            assert p.kind == inspect.Parameter.KEYWORD_ONLY, (
                f"{p.name} must be KEYWORD_ONLY — call sites pass kwargs only"
            )

    def test_get_job_run_error_params_are_keyword_only(self) -> None:
        sig = inspect.signature(StdioMcpDbtCloudClient.get_job_run_error)
        non_self = [p for n, p in sig.parameters.items() if n != "self"]
        for p in non_self:
            assert p.kind == inspect.Parameter.KEYWORD_ONLY

    def test_fixture_replay_client_signatures_match_real_client(self) -> None:
        for method_name in ("list_jobs_runs", "get_job_run_error"):
            real = inspect.signature(getattr(StdioMcpDbtCloudClient, method_name))
            fixture = inspect.signature(
                getattr(FixtureReplayDbtCloudClient, method_name)
            )
            real_kinds = {n: p.kind for n, p in real.parameters.items() if n != "self"}
            fixture_kinds = {
                n: p.kind for n, p in fixture.parameters.items() if n != "self"
            }
            assert real_kinds == fixture_kinds, (
                f"FixtureReplay diverges from real on {method_name}: "
                f"real={real_kinds} fixture={fixture_kinds}"
            )

    def test_real_client_satisfies_poll_loop_dbt_cloud_client_protocol(
        self,
    ) -> None:
        # The DbtCloudClient Protocol is structural (PEP 544). isinstance
        # on @runtime_checkable Protocol is the spec. The protocol is
        # NOT runtime-checkable in current source, so we approximate by
        # verifying the method names + signatures.
        from scripts.automation.src.triage.poll_loop import DbtCloudClient

        proto_methods = {
            name
            for name, val in vars(DbtCloudClient).items()
            if callable(val) and not name.startswith("_")
        }
        # The Protocol declares list_jobs_runs + get_job_run_error.
        assert proto_methods == {"list_jobs_runs", "get_job_run_error"}, (
            f"DbtCloudClient Protocol surface drifted: {proto_methods}"
        )
        # Real client implements both with matching signatures.
        for method_name in proto_methods:
            assert hasattr(StdioMcpDbtCloudClient, method_name)
            assert hasattr(FixtureReplayDbtCloudClient, method_name)

    def test_constructor_keyword_only_args(self) -> None:
        sig = inspect.signature(StdioMcpDbtCloudClient.__init__)
        for name in ("api_token", "account_id", "host"):
            param = sig.parameters[name]
            assert param.kind == inspect.Parameter.KEYWORD_ONLY, (
                f"{name} must be KEYWORD_ONLY in constructor "
                f"(prevents positional drift)"
            )


# ===========================================================================
# Mutation E — TestLifecyclePin (session-per-call)
# ===========================================================================


class TestLifecyclePin:
    """Mutation E: every public call opens AND closes its own session."""

    def test_each_list_jobs_runs_call_opens_a_new_session(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        _set_required_env(monkeypatch)
        recorder = StdioRecorder()
        sessions = [
            FakeSession(
                tool_response=FakeToolResult(
                    content=[FakeContentItem(json.dumps([{"id": i}]))],
                ),
            )
            for i in range(3)
        ]
        _install_mcp_fakes(monkeypatch, recorder, sessions=sessions)

        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        for _ in range(3):
            client.list_jobs_runs(status="error", job_id=786800, limit=20, offset=0)
        assert recorder.spawn_count == 3, (
            f"expected 3 stdio_client spawns (one per call); got {recorder.spawn_count}"
        )

    def test_each_get_job_run_error_call_opens_a_new_session(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        _set_required_env(monkeypatch)
        recorder = StdioRecorder()
        sessions = [
            FakeSession(
                tool_response=FakeToolResult(
                    content=[FakeContentItem(json.dumps({"failed_steps": []}))],
                ),
            )
            for _ in range(5)
        ]
        _install_mcp_fakes(monkeypatch, recorder, sessions=sessions)

        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        for run_id in range(100, 105):
            client.get_job_run_error(run_id=run_id)
        assert recorder.spawn_count == 5

    def test_session_context_exits_after_each_call(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        _set_required_env(monkeypatch)
        recorder = StdioRecorder()
        sessions = [
            FakeSession(
                tool_response=FakeToolResult(
                    content=[FakeContentItem(json.dumps([]))],
                ),
            )
            for _ in range(2)
        ]
        _install_mcp_fakes(monkeypatch, recorder, sessions=sessions)

        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        client.list_jobs_runs(status="error", job_id=1, limit=20, offset=0)
        client.list_jobs_runs(status="error", job_id=1, limit=20, offset=0)

        # Both stdio_client contexts must have been EXITED, not merely
        # entered. A leak (entered but not exited) would mean the uvx
        # subprocess is still running after the call returned.
        assert all(ctx.exited for ctx in recorder.contexts), (
            "stdio_client context must exit (subprocess termination) "
            "after each call — session-per-call lifecycle pin"
        )
        # And both sessions must have been closed.
        assert all(s.closed for s in sessions), (
            "ClientSession must close after each call"
        )

    def test_session_closes_even_when_tool_call_raises(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        _set_required_env(monkeypatch)
        recorder = StdioRecorder()
        session = FakeSession(tool_responses=[RuntimeError("tool blew up")])
        _install_mcp_fakes(monkeypatch, recorder, sessions=[session])

        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        with pytest.raises(DbtMcpInvocationError):
            client.get_job_run_error(run_id=1)
        # The session must STILL have closed (no leak on exception).
        assert session.closed, (
            "ClientSession must close on the exception path — async "
            "context managers handle this; the test pins it because "
            "Decision 3 (typed-raise) only works if cleanup runs"
        )
        assert all(ctx.exited for ctx in recorder.contexts), (
            "stdio_client context must exit on the exception path "
            "(otherwise uvx subprocess leaks)"
        )

    def test_no_session_reuse_across_calls(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        _set_required_env(monkeypatch)
        recorder = StdioRecorder()
        sessions = [
            FakeSession(
                tool_response=FakeToolResult(
                    content=[FakeContentItem(json.dumps([]))],
                ),
            )
            for _ in range(3)
        ]
        _install_mcp_fakes(monkeypatch, recorder, sessions=sessions)

        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        for _ in range(3):
            client.list_jobs_runs(status="error", job_id=1, limit=20, offset=0)

        # Each session must have been initialize()d exactly once. A
        # reused session would show >1 on at least one of them.
        for s in sessions:
            assert s.initialize_called == 1, (
                f"session reused across calls — initialize called "
                f"{s.initialize_called} times"
            )


# ===========================================================================
# TestFixtureReplayClient — Python-method seam (no asyncio, no stdio)
# ===========================================================================


class TestFixtureReplayClient:
    """FixtureReplay overrides the public methods; never enters asyncio."""

    def test_replays_canned_list_pages_for_job(self) -> None:
        client = FixtureReplayDbtCloudClient(
            list_pages_by_job={
                786800: [
                    [{"id": 1}, {"id": 2}],
                    [{"id": 3}],
                    [],  # exhaustion sentinel
                ],
            },
        )
        page1 = client.list_jobs_runs(status="error", job_id=786800, limit=20, offset=0)
        page2 = client.list_jobs_runs(status="error", job_id=786800, limit=20, offset=20)
        page3 = client.list_jobs_runs(status="error", job_id=786800, limit=20, offset=40)
        assert page1 == [{"id": 1}, {"id": 2}]
        assert page2 == [{"id": 3}]
        assert page3 == []

    def test_returns_empty_list_for_unscripted_job(self) -> None:
        # list_jobs_runs is permissive — an unscripted job_id returns []
        # (same as "no more pages") rather than raising.
        client = FixtureReplayDbtCloudClient()
        assert client.list_jobs_runs(status="error", job_id=999, limit=20, offset=0) == []

    def test_returns_canned_dict_for_scripted_run(self) -> None:
        client = FixtureReplayDbtCloudClient(
            error_returns_by_run={
                123: {"failed_steps": [{"step_index": 0}]},
            },
        )
        result = client.get_job_run_error(run_id=123)
        assert result == {"failed_steps": [{"step_index": 0}]}

    def test_returns_none_for_scripted_no_error_run(self) -> None:
        client = FixtureReplayDbtCloudClient(
            error_returns_by_run={456: None},
        )
        assert client.get_job_run_error(run_id=456) is None

    def test_raises_for_scripted_exception_run(self) -> None:
        client = FixtureReplayDbtCloudClient(
            error_returns_by_run={
                789: DbtMcpInvocationError("scripted transport failure"),
            },
        )
        with pytest.raises(DbtMcpInvocationError) as exc_info:
            client.get_job_run_error(run_id=789)
        assert "scripted transport failure" in str(exc_info.value)

    def test_raises_key_error_for_unscripted_run(self) -> None:
        client = FixtureReplayDbtCloudClient()
        with pytest.raises(KeyError) as exc_info:
            client.get_job_run_error(run_id=42)
        assert "42" in str(exc_info.value)

    def test_sequence_supports_retry_scenarios(self) -> None:
        # Multi-attempt sequence — first call raises, second succeeds.
        # Mirrors how K-retry tests use FakeDbtCloudClient.
        client = FixtureReplayDbtCloudClient(
            error_returns_by_run={
                999: [
                    DbtMcpInvocationError("transient"),
                    {"failed_steps": [{"step_index": 0}]},
                ],
            },
        )
        with pytest.raises(DbtMcpInvocationError):
            client.get_job_run_error(run_id=999)
        result = client.get_job_run_error(run_id=999)
        assert result == {"failed_steps": [{"step_index": 0}]}

    def test_records_all_calls_for_assertions(self) -> None:
        client = FixtureReplayDbtCloudClient(
            list_pages_by_job={1: [[{"id": 1}]]},
            error_returns_by_run={11: {"failed_steps": []}},
        )
        client.list_jobs_runs(status="error", job_id=1, limit=20, offset=0)
        client.get_job_run_error(run_id=11)
        assert client.list_jobs_runs_calls == [
            {"status": "error", "job_id": 1, "limit": 20, "offset": 0}
        ]
        assert client.get_job_run_error_calls == [{"run_id": 11}]

    def test_call_tool_sync_raises_loudly(self) -> None:
        # If anything sneaks into the asyncio path via the fixture, the
        # method-seam guard raises AssertionError. This pins the
        # "no subprocess, no asyncio" contract.
        client = FixtureReplayDbtCloudClient()
        with pytest.raises(AssertionError) as exc_info:
            client._call_tool_sync("list_jobs_runs", {})
        assert "must not invoke the MCP stdio" in str(exc_info.value)

    def test_call_tool_async_raises_loudly(self) -> None:
        client = FixtureReplayDbtCloudClient()
        with pytest.raises(AssertionError) as exc_info:
            asyncio.run(client._call_tool_async("list_jobs_runs", {}))
        assert "must not enter asyncio" in str(exc_info.value)

    def test_is_subclass_of_real_client(self) -> None:
        # isinstance checks against the real class must succeed — this
        # is the "production-shape fixture" property.
        client = FixtureReplayDbtCloudClient()
        assert isinstance(client, StdioMcpDbtCloudClient)


# ===========================================================================
# TestProjectionShape — C4 adapter input contract
# ===========================================================================


class TestProjectionShape:
    """get_job_run_error returns {'failed_steps': ...} at TOP level."""

    def test_get_job_run_error_returns_failed_steps_at_top_level(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        # dbt-mcp's response wire format: text content is a JSON object
        # with failed_steps at the top level. The client must not
        # double-wrap into {"data": {"failed_steps": ...}}.
        _set_required_env(monkeypatch)
        recorder = StdioRecorder()
        projection = {
            "failed_steps": [
                {
                    "step_index": 0,
                    "results": [
                        {
                            "unique_id": "model.example.foo",
                            "status": "error",
                            "message": "compilation error: missing ref",
                        }
                    ],
                }
            ],
        }
        session = FakeSession(
            tool_response=FakeToolResult(
                content=[FakeContentItem(json.dumps(projection))],
                is_error=False,
            ),
        )
        _install_mcp_fakes(monkeypatch, recorder, sessions=[session])

        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        result = client.get_job_run_error(run_id=1)

        assert result == projection, (
            "client must pass through dbt-mcp's payload verbatim — no "
            "{'data': ...} wrapper added (the C4 adapter adds it)"
        )
        assert "failed_steps" in result
        assert "data" not in result, (
            "client must NOT pre-wrap into {'data': ...}; the adapter "
            "owns that wrapping at the envelope boundary"
        )

    def test_list_jobs_runs_returns_list_of_run_dicts_top_level(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        _set_required_env(monkeypatch)
        recorder = StdioRecorder()
        runs = [
            {"id": 12345, "status": "error", "job_id": 786800},
            {"id": 12346, "status": "error", "job_id": 786800},
        ]
        session = FakeSession(
            tool_response=FakeToolResult(
                content=[FakeContentItem(json.dumps(runs))],
                is_error=False,
            ),
        )
        _install_mcp_fakes(monkeypatch, recorder, sessions=[session])

        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        result = client.list_jobs_runs(status="error", job_id=786800, limit=20, offset=0)
        assert result == runs

    def test_list_jobs_runs_returns_empty_list_when_no_content(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        # 'No more pages' state — the client converts no-content into
        # an empty list (not None), so the poll loop's
        # paginate-until-seen terminates cleanly.
        _set_required_env(monkeypatch)
        recorder = StdioRecorder()
        session = FakeSession(
            tool_response=FakeToolResult(content=[], is_error=False),
        )
        _install_mcp_fakes(monkeypatch, recorder, sessions=[session])

        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        result = client.list_jobs_runs(status="error", job_id=1, limit=20, offset=0)
        assert result == []


# ===========================================================================
# Tool name + subprocess-args pinning
# ===========================================================================


class TestToolNames:
    """Hardcoded tool names + uvx args — pinned to surface upstream drift."""

    def test_list_jobs_runs_calls_named_dbt_mcp_tool(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        _set_required_env(monkeypatch)
        recorder = StdioRecorder()
        session = FakeSession(
            tool_response=FakeToolResult(
                content=[FakeContentItem(json.dumps([]))],
            ),
        )
        _install_mcp_fakes(monkeypatch, recorder, sessions=[session])

        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        client.list_jobs_runs(status="error", job_id=786800, limit=20, offset=0)
        assert session.call_tool_calls == [
            (
                "list_jobs_runs",
                {"status": "error", "job_id": 786800, "limit": 20, "offset": 0},
            )
        ]

    def test_get_job_run_error_calls_named_dbt_mcp_tool(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        _set_required_env(monkeypatch)
        recorder = StdioRecorder()
        session = FakeSession(
            tool_response=FakeToolResult(
                content=[FakeContentItem(json.dumps({"failed_steps": []}))],
            ),
        )
        _install_mcp_fakes(monkeypatch, recorder, sessions=[session])

        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        client.get_job_run_error(run_id=12345)
        assert session.call_tool_calls == [
            ("get_job_run_error", {"run_id": 12345})
        ]

    def test_uvx_subprocess_args_are_pinned(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        _set_required_env(monkeypatch)
        recorder = StdioRecorder()
        session = FakeSession(
            tool_response=FakeToolResult(
                content=[FakeContentItem(json.dumps([]))],
            ),
        )
        _install_mcp_fakes(monkeypatch, recorder, sessions=[session])

        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        client.list_jobs_runs(status="error", job_id=1, limit=20, offset=0)

        params = recorder.last_server_params
        # In the fakes, StdioServerParameters is a lambda returning a
        # plain dict of its kwargs. Verify the command + args layout.
        assert params["command"] == "uvx"
        assert params["args"] == [
            "--python",
            "3.13",
            "--from",
            "dbt-mcp==1.19.2",
            "dbt-mcp",
        ]


# ===========================================================================
# Constructor validation
# ===========================================================================


class TestConstructorValidation:
    """Type + emptiness checks at construction — fail loud, fail early."""

    def test_empty_api_token_rejected(self) -> None:
        with pytest.raises(ValueError, match="api_token"):
            StdioMcpDbtCloudClient(api_token="", account_id=1)

    def test_non_string_api_token_rejected(self) -> None:
        with pytest.raises(ValueError, match="api_token"):
            StdioMcpDbtCloudClient(api_token=None, account_id=1)  # type: ignore[arg-type]

    def test_non_int_account_id_rejected(self) -> None:
        with pytest.raises(TypeError, match="account_id"):
            StdioMcpDbtCloudClient(api_token="T", account_id="999")  # type: ignore[arg-type]

    def test_empty_host_rejected(self) -> None:
        with pytest.raises(ValueError, match="host"):
            StdioMcpDbtCloudClient(api_token="T", account_id=1, host="")

    def test_default_host_is_cloud_dbt(self) -> None:
        client = StdioMcpDbtCloudClient(api_token="T", account_id=1)
        assert client._host == "cloud.getdbt.com"
