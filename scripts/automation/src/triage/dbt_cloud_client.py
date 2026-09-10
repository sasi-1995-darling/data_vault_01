"""Triage dbt-Cloud client — C8 (the live MCP-stdio bridge).

Resolves the DBT-CLOUD-CLIENT dormant item (`phase-1-exit-checklist.md`
§3 + `sprint-1-deferred.md #20`). After this lands, `cron_entrypoint.py`
can construct a real ``DbtCloudClient``-shaped object and the cron's
``list_jobs_runs`` / ``get_job_run_error`` calls reach a real dbt-Cloud
account via the official dbt Labs MCP server (``dbt-mcp==1.19.2``)
spawned on demand via ``uvx``.

Public surface (the two MVP methods the poll loop already consumes):

    class StdioMcpDbtCloudClient:
        def __init__(*, api_token, account_id, host="cloud.getdbt.com"): ...
        def list_jobs_runs(*, status, job_id, limit, offset) -> list[dict]: ...
        def get_job_run_error(*, run_id) -> dict | None: ...

    class FixtureReplayDbtCloudClient(StdioMcpDbtCloudClient):
        # Same surface; overrides return canned fixtures without ever
        # entering asyncio/stdio. Test-seam, never production.
        ...

    class DbtMcpInvocationError(RuntimeError): ...
    class DbtMcpEnvVarMissing(RuntimeError): ...

THREE design decisions THIS module enforces (per the C8 directive):

  Decision 1 — SESSION-PER-CALL (MVP)
  -----------------------------------
  Each public-method invocation does its own ``asyncio.run(...)`` →
  ``stdio_client(...)`` → ``ClientSession(...)`` cycle, spawning ONE
  ``uvx`` dbt-mcp subprocess per call. This matches the precedent at
  `scripts/automation/mcp_profile_patch.py:58-120` (snow-mcp) and the
  ``FixtureReplayDbtCloudClient`` Python-method seam.

  At the Q3 cadence (~672 calls/day worst case, with a typical pass
  fetching only the few unseen runs) the per-call ``uvx`` cold-start
  cost is tolerable. If observed latency shows spawn cost dominating,
  the documented optimization is **session-per-poll-pass** (open one
  ``ClientSession`` at pass start, route all calls through it, close
  at pass end). That optimization is NOT built here — it would be a
  deliberate amendment against the lifecycle-pinned baseline below.

  Lifecycle is pinned by ``test_each_call_opens_new_session`` /
  ``test_each_call_closes_session`` in ``test_triage_dbt_cloud_client``
  so a future move to session-per-pass is a deliberate, visible change.

  Decision 2 — EXPLICIT ``DBT_*`` ENV ALLOWLIST (NOT ``**os.environ``)
  -------------------------------------------------------------------
  The subprocess env is composed from a NAMED allowlist. Three names
  are INJECTED from non-environ sources (``DBT_INJECTED_ENV_VARS``):
  ``DBT_TOKEN`` and ``DBT_ACCOUNT_ID`` from the constructor, and the
  literal ``DBT_MCP_ENABLE_ADMIN_API=true`` that scopes dbt-mcp to the
  Admin API toolset (the only tools this client calls). The remaining
  names are COPIED from os.environ: ``DBT_REQUIRED_ENV_VARS``
  (``DBT_HOST``, ``DBT_PROD_ENV_ID``, ``DBT_DEV_ENV_ID``) plus a TINY
  passthrough set (``PATH``, ``HOME``) needed by ``uvx`` to resolve
  itself and find its cache.

  ``DBT_ACCOUNT_ID`` is REQUIRED by dbt-mcp's account-scoped Admin API
  (it builds ``/accounts/{id}/...`` URLs) per the official env-vars
  reference. It is injected under dbt-mcp's expected name — NOT the
  workflow-side ``DBT_CLOUD_ACCOUNT_ID`` the Python process reads.

  ``DBT_USER_ID`` and ``DBT_QA_ENV_ID`` are deliberately NOT required:
  per the dbt-mcp env-vars reference ``DBT_USER_ID`` is only needed for
  ``execute_sql`` (which this client never calls) and ``DBT_QA_ENV_ID``
  is not a recognized dbt-mcp var at all. Requiring them made the
  never-run cron loud-fail on config that dbt-mcp does not use; the
  proven-working ``.vscode/mcp.json`` omits ``DBT_USER_ID`` entirely.

  Splat-merging ``**os.environ`` was rejected: it would carry every
  GHA-runner secret (``SNOWFLAKE_PASSWORD``, ``GITHUB_TOKEN``, etc.)
  into a subprocess that has no business seeing them. The dbt-mcp
  server is a trusted upstream package, but credential-surface hygiene
  is "pass what's needed, nothing else" — the same minimize-the-surface
  discipline the redactor packet applies at the row boundary.

  Required vars are READ AT CALL TIME (not at ``__init__``) so the
  client is constructable in tests that don't exercise a call path,
  and so a missing var produces a loud ``DbtMcpEnvVarMissing`` at the
  call site rather than a silent empty string downstream in dbt-mcp.

  Decision 3 — TYPED-RAISE FAIL-OPEN (the poll loop's C6 dead-letters catch)
  -------------------------------------------------------------------------
  The client RAISES typed exceptions on failure (``DbtMcpInvocationError``
  for tool/transport failure; ``DbtMcpEnvVarMissing`` for config gaps).
  It does NOT add a second internal fail-open layer that could drift
  from the poll loop's existing four-way dead-letter taxonomy (§1.8).

  C6 already handles client failures:
    * ``list_jobs_runs`` raises  → ``source_unavailable`` (no row,
      pass aborts; cursor un-advanced).
    * ``get_job_run_error`` raises after K in-memory retries  →
      ``attempted_but_failed`` (durable row + cursor advance; the
      cursor-advance via durable row prevents the infinite reprocess
      loop that "skip + retry next pass" would create).

  CRITICAL distinction preserved by the type: ``dict | None`` carries
  TWO success states. A returned dict is "MCP call succeeded, here is
  the parsed projection". ``None`` is "MCP call succeeded, there is
  no error projection for this run" — distinct from raising. Code
  reading the return MUST treat ``None`` as success-with-no-content
  and raises as failure-with-context. Mutation C in the test suite
  pins this (swallow-and-return-None instead of raising → RED).

C4 adapter input contract (read against bytes in `dbt_cloud_adapter.py`):
  ``get_job_run_error`` returns ``{"failed_steps": [...]}`` at the TOP
  level (no ``data`` wrapper). The C4 adapter wraps the projection into
  ``{"data": {"failed_steps": [...]}}`` when emitting envelopes — the
  client must NOT pre-wrap, or every envelope would carry a doubled
  ``data.data`` path that ``triage_failure`` would not navigate.

Protocol match: signatures EXACTLY match the duck-typed
``DbtCloudClient`` Protocol at ``poll_loop.py:142`` and the
``FakeDbtCloudClient`` at ``test_triage_poll_loop.py:110`` — keyword-only
``status``/``job_id``/``limit``/``offset`` on ``list_jobs_runs`` and
keyword-only ``run_id`` on ``get_job_run_error``. The fake IS the
contract; the real client and the ``FixtureReplayDbtCloudClient``
subclass both honor that surface so the 43 existing poll-loop tests
transfer without modification.
"""

from __future__ import annotations

import asyncio
import json
import os
import sys
from typing import Any, Optional

__all__ = [
    "StdioMcpDbtCloudClient",
    "FixtureReplayDbtCloudClient",
    "DbtMcpInvocationError",
    "DbtMcpEnvVarMissing",
    "DBT_REQUIRED_ENV_VARS",
    "DBT_PASSTHROUGH_ENV_VARS",
    "DBT_INJECTED_ENV_VARS",
    "DBT_MCP_PACKAGE_SPEC",
    "DBT_MCP_PYTHON_VERSION",
]


# ---------------------------------------------------------------------------
# Constants — pinned, mutation-tested
# ---------------------------------------------------------------------------

# dbt-mcp upstream package + the python runtime it expects (the SUBPROCESS's
# python — independent of OUR process's python which is 3.14). Pinned to
# match `docs/triage-agent/setup.md §3` so any drift is a deliberate,
# documented change rather than a transient install behavior shift.
DBT_MCP_PACKAGE_SPEC: str = "dbt-mcp==1.19.2"
DBT_MCP_PYTHON_VERSION: str = "3.13"

# dbt-mcp env-vars COPIED from os.environ (loud-fail if absent). Scoped to
# what dbt-mcp's Admin API path actually consumes per the official env-vars
# reference: DBT_HOST (platform host) + DBT_PROD_ENV_ID. DBT_DEV_ENV_ID is
# kept to match the proven-working .vscode/mcp.json (a recognized dbt-mcp
# var). MULTICELL_ACCOUNT_PREFIX (the cell prefix, e.g. kl673) is REQUIRED
# for this multi-cell account: dbt-mcp composes it with the BARE DBT_HOST
# (us1.dbt.com) into the real host kl673.us1.dbt.com. Without it dbt-mcp
# uses the bare host and 404s every account-scoped Admin API call — the gap
# that made the first end-to-end cron poll 0 runs (the var lived only in the
# gitignored .vscode/mcp.json and was never in the tracked config). It is
# loud-fail-if-absent here so a future config that drops it crashes the cron
# instead of silently 404ing. DBT_USER_ID (execute_sql-only) and
# DBT_QA_ENV_ID (not a recognized dbt-mcp var) are intentionally EXCLUDED —
# see module docstring Decision 2.
DBT_REQUIRED_ENV_VARS: tuple[str, ...] = (
    "DBT_HOST",
    "MULTICELL_ACCOUNT_PREFIX",
    "DBT_PROD_ENV_ID",
    "DBT_DEV_ENV_ID",
)

# dbt-mcp env-vars INJECTED by the client from non-environ sources:
# DBT_TOKEN + DBT_ACCOUNT_ID from the constructor, and the fixed
# DBT_MCP_ENABLE_ADMIN_API flag that scopes dbt-mcp to the Admin API
# toolset. Named so the env-hygiene test can pin the allowlist as exactly
# (injected | required | passthrough) — a refactor that drops DBT_ACCOUNT_ID
# or the admin flag breaks the test loudly (this exact gap crashed the
# never-run cron).
DBT_INJECTED_ENV_VARS: tuple[str, ...] = (
    "DBT_TOKEN",
    "DBT_ACCOUNT_ID",
    "DBT_MCP_ENABLE_ADMIN_API",
)

# Non-credential operational env-vars the subprocess needs for uvx to find
# itself (PATH) and its cache (HOME). NOT credentials; not in scope for the
# minimize-the-surface rule. Explicit allowlist — adding a new passthrough
# is a deliberate change with a stated reason.
DBT_PASSTHROUGH_ENV_VARS: tuple[str, ...] = (
    "PATH",
    "HOME",
)

# MCP tool names exposed by dbt-mcp 1.19.2 (per `docs/triage-agent/setup.md
# §5` validation list). Hardcoded — the first live call will fail loudly
# via DbtMcpInvocationError if dbt-mcp's tool surface ever renames these.
_TOOL_LIST_JOBS_RUNS: str = "list_jobs_runs"
_TOOL_GET_JOB_RUN_ERROR: str = "get_job_run_error"

# Per-call hard timeouts. The dbt-mcp subprocess + MCP handshake should
# complete well under these on a healthy network. Exceeding them indicates
# a real upstream problem and should surface via DbtMcpInvocationError so
# the C6 dead-letter taxonomy can route the failure.
_INITIALIZE_TIMEOUT_SECONDS: float = 30.0
_CALL_TOOL_TIMEOUT_SECONDS: float = 60.0


# ---------------------------------------------------------------------------
# Typed exceptions — raised, never swallowed (Decision 3)
# ---------------------------------------------------------------------------


class DbtMcpInvocationError(RuntimeError):
    """Raised when a dbt-mcp tool call fails for any reason.

    Covers transport failures (subprocess refused to start, stdio pipe
    broken), MCP handshake failures (``session.initialize`` timeout),
    server-side errors (``result.isError == True``), and parse failures
    (tool returned text that is not valid JSON of the expected shape).

    Caught by the poll loop's C6 four-way dead-letter taxonomy:
      * Raised inside ``list_jobs_runs``       → ``source_unavailable``
      * Raised inside ``get_job_run_error``    → ``attempted_but_failed``
        (after K in-memory retries by the K-retry helper)
    """


class DbtMcpEnvVarMissing(RuntimeError):
    """Raised when a required ``DBT_*`` env var is missing at call time.

    Loud failure with the variable name in the message — never silently
    propagated as an empty string that would make dbt-mcp fail opaquely
    downstream with an auth/config error that doesn't name the gap.
    """


# ---------------------------------------------------------------------------
# StdioMcpDbtCloudClient — the live bridge
# ---------------------------------------------------------------------------


class StdioMcpDbtCloudClient:
    """Synchronous client over the dbt-mcp stdio MCP server.

    Talks to dbt-mcp (the official dbt Labs MCP server, ``dbt-mcp==1.19.2``)
    via stdio, spawning ONE ``uvx`` subprocess per public-method call
    (Decision 1, session-per-call). dbt-mcp owns the HTTP wire to
    ``cloud.getdbt.com`` and the ``failed_steps[].results[]`` projection;
    this client never talks to ``cloud.getdbt.com`` directly.

    Public methods are SYNC because the poll loop consumer
    (``run_poll_pass``, ``process_envelope``) is sync. Internal async
    machinery is wrapped by ``asyncio.run`` per call.

    Constructor signature is keyword-only ``(api_token, account_id,
    host="cloud.getdbt.com")`` — ``api_token`` flows into the dbt-mcp
    subprocess env as ``DBT_TOKEN`` (never embedded in tool args);
    ``account_id`` is held for future per-call use; ``host`` defaults
    to the dbt-Cloud production host. ``cron_entrypoint`` constructs
    this with the two env-var values; ``host`` defaults are sufficient
    for the MVP cron paths.
    """

    def __init__(
        self,
        *,
        api_token: str,
        account_id: int,
        host: str = "cloud.getdbt.com",
    ) -> None:
        if not isinstance(api_token, str) or not api_token:
            raise ValueError("api_token must be a non-empty string")
        if not isinstance(account_id, int):
            raise TypeError(
                f"account_id must be int, got {type(account_id).__name__}"
            )
        if not isinstance(host, str) or not host:
            raise ValueError("host must be a non-empty string")
        self._api_token = api_token
        self._account_id = account_id
        self._host = host

    # ----- Public surface (matches DbtCloudClient Protocol exactly) -----

    def list_jobs_runs(
        self,
        *,
        status: str,
        job_id: int,
        limit: int,
        offset: int,
    ) -> list[dict]:
        """List job runs filtered by ``status``, scoped to ``job_id``.

        Returns the parsed list of run dicts from dbt-mcp. Empty list
        means "no runs match the filter at this offset" — distinct from
        raising on retrieval failure.

        Raises ``DbtMcpInvocationError`` on any transport/server/parse
        failure; the poll loop's C6 ``source_unavailable`` dead-letter
        catches that and aborts the pass without writing a row.
        """
        args = {
            "status": status,
            "job_id": job_id,
            "limit": limit,
            "offset": offset,
        }
        parsed = self._call_tool_sync(_TOOL_LIST_JOBS_RUNS, args)
        if parsed is None:
            # MCP returned content but parsing yielded nothing — treat as
            # empty page rather than failure. The poll loop's
            # paginate-until-seen treats an empty page as end-of-data.
            return []
        if not isinstance(parsed, list):
            raise DbtMcpInvocationError(
                f"list_jobs_runs: expected JSON list from dbt-mcp, "
                f"got {type(parsed).__name__}"
            )
        return parsed

    def get_job_run_error(self, *, run_id: int) -> Optional[dict]:
        """Fetch the parsed error projection for one run.

        Returns the dbt-mcp projection ``{"failed_steps": [...]}`` at
        the TOP level (no ``data`` wrapper — the C4 adapter adds it).

        Returns ``None`` if dbt-mcp's response carries no error
        projection for this run (a legitimate success state, distinct
        from failure — preserved per Decision 3 / Mutation C).

        Raises ``DbtMcpInvocationError`` on transport/server/parse
        failure; the poll loop's K-retry helper retries within a pass
        and the C6 ``attempted_but_failed`` dead-letter catches the
        final raise after retry exhaustion.
        """
        args = {"run_id": run_id}
        parsed = self._call_tool_sync(_TOOL_GET_JOB_RUN_ERROR, args)
        if parsed is None:
            return None
        if not isinstance(parsed, dict):
            raise DbtMcpInvocationError(
                f"get_job_run_error: expected JSON object from dbt-mcp, "
                f"got {type(parsed).__name__}"
            )
        return parsed

    # ----- Internal: env composition (Decision 2) -----

    def _compose_subprocess_env(self) -> dict[str, str]:
        """Compose the explicit env for the dbt-mcp subprocess.

        ALLOWLIST = injected | required | passthrough:
          * ``DBT_INJECTED_ENV_VARS`` — ``DBT_TOKEN`` + ``DBT_ACCOUNT_ID``
            from the constructor, and the literal
            ``DBT_MCP_ENABLE_ADMIN_API=true`` (scopes dbt-mcp to the Admin
            API toolset this client uses).
          * ``DBT_REQUIRED_ENV_VARS`` — copied from os.environ, loud-fail
            if missing.
          * ``DBT_PASSTHROUGH_ENV_VARS`` — copied from os.environ, omitted
            silently if missing (operational, not contract-required).

        ``DBT_ACCOUNT_ID`` is injected under dbt-mcp's expected name (the
        account-scoped Admin API requires it); the workflow-side
        ``DBT_CLOUD_ACCOUNT_ID`` is NOT passed through.

        Splat-merging ``**os.environ`` is intentionally avoided so a
        future ``GITHUB_TOKEN`` / ``SNOWFLAKE_PASSWORD`` / similar
        secret cannot leak into the dbt-mcp subprocess's env. Mutation B
        proves it via ABSENCE assertion on a planted non-DBT secret.
        """
        env: dict[str, str] = {
            "DBT_TOKEN": self._api_token,
            "DBT_ACCOUNT_ID": str(self._account_id),
            "DBT_MCP_ENABLE_ADMIN_API": "true",
        }
        for var in DBT_REQUIRED_ENV_VARS:
            # Treat empty/whitespace-only the SAME as missing: GitHub
            # Actions resolves an undefined secret/var to an empty string,
            # so a blank value is the same misconfiguration as an absent
            # one — and propagating '' would make dbt-mcp fail opaquely
            # downstream instead of naming the gap here.
            value = os.environ.get(var, "")
            if not value.strip():
                raise DbtMcpEnvVarMissing(
                    f"Required env var not set or empty: {var}. The dbt-mcp "
                    f"subprocess needs a non-empty {var} (see "
                    f"docs/triage-agent/setup.md §4)."
                )
            env[var] = value
        for var in DBT_PASSTHROUGH_ENV_VARS:
            if var in os.environ:
                env[var] = os.environ[var]
        return env

    # ----- Internal: server params + async core -----

    def _build_server_params(self) -> Any:
        """Build StdioServerParameters for spawning dbt-mcp via uvx.

        Lazy import of mcp.* keeps the test for env composition / arg
        validation runnable even on a machine without the mcp package
        installed (CI installs from requirements.txt; local-dev
        contributors may not have it).
        """
        from mcp import StdioServerParameters  # noqa: PLC0415 — see docstring

        return StdioServerParameters(
            command="uvx",
            args=[
                "--python",
                DBT_MCP_PYTHON_VERSION,
                "--from",
                DBT_MCP_PACKAGE_SPEC,
                "dbt-mcp",
            ],
            env=self._compose_subprocess_env(),
        )

    def _call_tool_sync(self, tool_name: str, args: dict) -> Any:
        """Sync wrapper around the per-call async stdio session.

        One ``asyncio.run`` per call (Decision 1, session-per-call).
        Any exception from the async core surfaces as
        ``DbtMcpInvocationError`` (Decision 3, typed-raise).
        """
        try:
            return asyncio.run(self._call_tool_async(tool_name, args))
        except DbtMcpInvocationError:
            raise
        except DbtMcpEnvVarMissing:
            # Loud config-gap failure — let it propagate without
            # repackaging.
            raise
        except BaseException as exc:
            # Includes asyncio.TimeoutError, subprocess errors, broken
            # stdio pipe, and anything mcp.* raises. Re-raised as
            # typed-class so callers can pattern-match without
            # depending on mcp's exception hierarchy.
            raise DbtMcpInvocationError(
                f"dbt-mcp tool {tool_name!r} call failed: "
                f"{type(exc).__name__}: {exc}"
            ) from exc

    async def _call_tool_async(self, tool_name: str, args: dict) -> Any:
        """One stdio session: spawn → initialize → call → parse → close.

        Lifecycle is per-call (Decision 1). Both ``stdio_client`` and
        ``ClientSession`` are async context managers; exiting them
        triggers subprocess termination + session close. The
        lifecycle-pin test asserts each call opens AND closes its own
        session (no leak, no reuse).
        """
        from mcp import ClientSession  # noqa: PLC0415 — lazy
        from mcp.client.stdio import stdio_client  # noqa: PLC0415 — lazy

        server_params = self._build_server_params()
        async with stdio_client(server_params) as (read_stream, write_stream):
            async with ClientSession(read_stream, write_stream) as session:
                await asyncio.wait_for(
                    session.initialize(),
                    timeout=_INITIALIZE_TIMEOUT_SECONDS,
                )
                result = await asyncio.wait_for(
                    session.call_tool(tool_name, args),
                    timeout=_CALL_TOOL_TIMEOUT_SECONDS,
                )
                return self._parse_tool_result(tool_name, result)

    @staticmethod
    def _parse_tool_result(tool_name: str, result: Any) -> Any:
        """Parse a dbt-mcp tool result into a plain Python object.

        Prefers ``structuredContent`` — the authoritative, un-flattened
        payload. The MCP SDK wraps a tool's return value under a
        ``"result"`` key in ``structuredContent`` (``{"result": <value>}``
        for generic list/dict returns). Critically, the UNstructured
        ``content`` channel FLATTENS a *list* return into one item per
        element (``mcp.server.fastmcp`` ``_convert_to_content`` →
        ``chain.from_iterable``), so reading ``content[0]`` alone would
        silently drop runs 2..N of a multi-run ``list_jobs_runs`` response.
        ``structuredContent`` carries the whole value intact. Verified
        against mcp 1.26.0 / dbt-mcp 1.19.2 (client returns a bare
        ``list[dict]``; the SDK wraps it under ``result``).

        Falls back to the first JSON ``content`` text item when
        ``structuredContent`` is absent (older / non-annotated tools).
        Either channel feeds the per-method ``isinstance`` checks in the
        public methods, which fail loud on a shape mismatch.

        Returns ``None`` when neither channel yields a payload — the
        legitimate "no content" state that ``get_job_run_error``
        translates to "no error found".

        Raises ``DbtMcpInvocationError`` on ``isError`` or on JSON
        parse failure.
        """
        if getattr(result, "isError", False):
            err_text = ""
            for item in getattr(result, "content", []) or []:
                text = getattr(item, "text", None)
                if text:
                    err_text = text[:500]
                    break
            raise DbtMcpInvocationError(
                f"dbt-mcp tool {tool_name!r} returned isError=True: "
                f"{err_text or '(no error text)'}"
            )
        # PREFER structuredContent — the un-flattened, authoritative payload.
        # For a list return the ``content`` channel is flattened per-element,
        # so only structuredContent preserves the full list (see docstring).
        structured = getattr(result, "structuredContent", None)
        if isinstance(structured, dict) and "result" in structured:
            return structured["result"]
        # FALLBACK — no structuredContent (older / non-annotated tools): parse
        # the first JSON text item. The public method's isinstance check still
        # enforces the expected shape and fails loud on a mismatch.
        for item in getattr(result, "content", []) or []:
            text = getattr(item, "text", None)
            if not text:
                continue
            try:
                return json.loads(text)
            except (json.JSONDecodeError, TypeError) as exc:
                raise DbtMcpInvocationError(
                    f"dbt-mcp tool {tool_name!r} returned non-JSON "
                    f"text content: {type(exc).__name__}: {exc}"
                ) from exc
        # No structured content and no text content — distinct from isError;
        # treat as success-with-no-payload. The caller (``list_jobs_runs`` /
        # ``get_job_run_error``) decides what that means in context.
        return None


# ---------------------------------------------------------------------------
# FixtureReplayDbtCloudClient — Python-method seam for tests (precedent-locked)
# ---------------------------------------------------------------------------


class FixtureReplayDbtCloudClient(StdioMcpDbtCloudClient):
    """Test seam: returns canned fixture dicts keyed by ``(operation, key)``.

    NEVER enters asyncio / stdio_client / ClientSession — overrides the
    public methods directly so the test path makes ZERO subprocess
    spawns. This is the "mock at the Python-method seam, not the wire"
    discipline locked by the House MCP-wrapper precedent at
    ``sprint-1-deferred.md:717-734``.

    The subclass relationship gives ``isinstance(x, StdioMcpDbtCloudClient)``
    a single source of truth for "this is a dbt-Cloud client" while
    keeping the test seam free of any ``uvx`` / dbt-mcp / network
    dependency. The poll-loop tests already consume a similar fake
    (``FakeDbtCloudClient`` at ``test_triage_poll_loop.py:110``); this
    subclass is the production-shape fixture equivalent.

    Scripting model mirrors ``FakeDbtCloudClient``:
      * ``list_pages_by_job[job_id]`` is a list of pages; each call
        pops the next page (cursor advances per job_id, independent of
        offset arithmetic).
      * ``error_returns_by_run[run_id]`` is either a dict (success),
        ``None`` (legitimate no-error result), a ``BaseException``
        instance (single-shot raise), or a list of mixed values
        (multi-attempt sequence for K-retry tests).
    """

    def __init__(
        self,
        *,
        api_token: str = "FIXTURE_TOKEN",
        account_id: int = 0,
        host: str = "fixtures.local",
        list_pages_by_job: Optional[dict[int, list[list[dict]]]] = None,
        error_returns_by_run: Optional[dict[int, Any]] = None,
    ) -> None:
        super().__init__(api_token=api_token, account_id=account_id, host=host)
        self.list_pages_by_job: dict[int, list[list[dict]]] = (
            dict(list_pages_by_job) if list_pages_by_job else {}
        )
        self.error_returns_by_run: dict[int, Any] = (
            dict(error_returns_by_run) if error_returns_by_run else {}
        )
        self.list_jobs_runs_calls: list[dict] = []
        self.get_job_run_error_calls: list[dict] = []
        self._page_cursor_by_job: dict[int, int] = {}

    def list_jobs_runs(
        self,
        *,
        status: str,
        job_id: int,
        limit: int,
        offset: int,
    ) -> list[dict]:
        self.list_jobs_runs_calls.append(
            {
                "status": status,
                "job_id": job_id,
                "limit": limit,
                "offset": offset,
            }
        )
        pages = self.list_pages_by_job.get(job_id, [])
        idx = self._page_cursor_by_job.get(job_id, 0)
        if idx >= len(pages):
            return []
        self._page_cursor_by_job[job_id] = idx + 1
        return pages[idx]

    def get_job_run_error(self, *, run_id: int) -> Optional[dict]:
        self.get_job_run_error_calls.append({"run_id": run_id})
        if run_id not in self.error_returns_by_run:
            raise KeyError(
                f"unscripted run_id={run_id} (add an entry to "
                f"error_returns_by_run before calling)"
            )
        scripted = self.error_returns_by_run[run_id]
        if isinstance(scripted, list):
            if not scripted:
                raise RuntimeError(
                    f"run_id={run_id} sequence exhausted "
                    f"(test wired too few entries for the retry count)"
                )
            next_val = scripted.pop(0)
            if isinstance(next_val, BaseException):
                raise next_val
            return next_val
        if isinstance(scripted, BaseException):
            raise scripted
        # dict or None — both legitimate per the type signature.
        return scripted

    # Override the internal async/stdio path to a loud error: any code
    # path that reaches it through the fixture client is a bug (the
    # fixture is supposed to short-circuit at the public-method seam).
    def _call_tool_sync(self, tool_name: str, args: dict) -> Any:  # noqa: D401
        raise AssertionError(
            "FixtureReplayDbtCloudClient must not invoke the MCP stdio "
            "path — override list_jobs_runs / get_job_run_error at the "
            "Python-method seam (precedent-locked, "
            "sprint-1-deferred.md:717-734)."
        )

    async def _call_tool_async(self, tool_name: str, args: dict) -> Any:  # noqa: D401
        raise AssertionError(
            "FixtureReplayDbtCloudClient must not enter asyncio/stdio."
        )


# ---------------------------------------------------------------------------
# Module-level convenience for cron_entrypoint — kept thin
# ---------------------------------------------------------------------------


def _module_uses_only_sys_python(  # pragma: no cover — diagnostic helper
) -> str:
    """Diagnostic hook for the live-traffic smoke check.

    Returns the runtime Python that THIS module loaded under. Useful
    for verifying that the cron's Python (3.11/3.12/3.14, etc.) is
    independent of dbt-mcp's subprocess Python (pinned 3.13 via
    DBT_MCP_PYTHON_VERSION).
    """
    return sys.version
