"""Triage poll loop — C6 (spec v3.4 §4.9).

Single public entrypoint:

    run_poll_pass(
        *,
        client,                   # DbtCloudClient (duck-typed)
        triage_writer,            # C5 TriageWriter
        snowflake_cursor,         # for MAX(run_id) high-water lookup
        job_ids,                  # in-scope dbt-Cloud job ids
        on_malformed_input,       # C5 sink callback (envelope, exc)
        on_operational_error,     # C5 sink callback (envelope, exc)
        on_attempted_but_failed,  # C6 sink callback (run_id, exc)
        on_source_unavailable,    # C6 sink callback (exc) — no run_id
        k_retries=3,
        max_pages=10,
        finished_at_floor_days=7,
        page_limit=100,
        now_utc=None,             # injectable for tests
    ) -> PollPassReport

Ties the pipeline together: ``list_jobs_runs(status=error)`` →
paginate-until-seen → per-run ``get_job_run_error`` →
``from_dbt_cloud_error`` (C4 adapter) → per-envelope
``process_envelope`` (C5 orchestrator wrapper) → writer.

Boundary contracts (asserted in test_triage_poll_loop.py):

  * **Cursor substrate — Decision 1 (directive-level decision, NOT a
    spec retrieval).** The high-water ``last_seen_run_id`` is DERIVED
    via ``SELECT MAX(run_id) FROM OPS_PROD.LOGS.TRIAGE_INVOCATIONS
    WHERE job_id IN (...)``. NO separate cursor table, NO external
    JSON. Decisive reason: the writer's MERGE-on-``(run_id,
    COALESCE(unique_id,'__NO_NODE__'))`` already makes the TABLE the
    dedup authority — it IS the durable record of what's been
    processed. A separate cursor store is a SECOND source of truth
    that can drift from the table after crash-mid-loop. Deriving
    from ``MAX(run_id)`` eliminates the drift class entirely: the
    cursor IS the table's state, so they cannot disagree. **MUST
    filter by polled job_ids** — an unfiltered MAX over the table
    (which holds rows from every polled job) could skip in-scope
    runs whose run_id is below an out-of-scope job's MAX. Dead-letter
    rows (``triage_attempted_but_failed``) are counted in MAX — a
    dead-lettered run IS "seen" (we attempted it and gave up; the
    ORCH-FAIL-OPEN intent is to advance past it), so its run_id
    legitimately contributes to the high-water.

  * **G7 cursor-lost recovery** — paginate-until-seen could otherwise
    iterate forever if the high-water run_id is no longer in API
    results (retention expiry, manual deletion). Bounded by TWO
    floors: ``max_pages`` (default 10 pages × 100/page = 1000 runs)
    AND ``finished_at_floor_days`` (default 7d). First floor hit
    ENDS pagination, logs ``cursor_lost`` warning, restarts from
    latest. Distinct from the four-way taxonomy below — this is a
    CURSOR-level dead-letter (the cursor itself is lost), not a
    run-level one.

  * **K-retry — in-memory transient handling (§4.9 G4 reading-(b)).**
    K retries against ``get_job_run_error`` within a SINGLE polling
    pass. On K transient failures for a run, write a
    ``triage_attempted_but_failed`` row carrying the real ``run_id``
    and ADVANCE the cursor (ORCH-FAIL-OPEN). NO persistent retry
    state, NO DDL change, NO MERGE UPDATE branch. Cross-poll retry
    was rejected — it would need a ``retry_count`` column.

  * **Four-way dead-letter taxonomy** — must read with NO ambiguity:

      ===================================  ====  ============================
      sink                                  owner trigger
      ===================================  ====  ============================
      ``triage_malformed_input``            C5    TypeError from triage_failure
      ``triage_operational_error``          C5    Exception from triage_failure
                                                  OR writer.write
      ``triage_attempted_but_failed``       C6    get_job_run_error(run_id)
                                                  fails K times (run known)
      ``triage_source_unavailable``         C6    list_jobs_runs itself fails
                                                  (NO run identified)
      ===================================  ====  ============================

    Structural boundary: ``source_unavailable`` is "couldn't even get
    the list of runs" (no run identified, pass can't proceed) —
    categorically different from ``attempted_but_failed`` ("got the
    run id, but get_job_run_error kept failing for THAT run"). They
    MUST NOT share a sink. ``attempted_but_failed`` writes a row
    (run_id known) and ADVANCES the cursor (run is "seen").
    ``source_unavailable`` writes NO row (no run_id) — it logs/alerts
    and the pass aborts to retry next cron tick (cursor doesn't move
    because nothing was processed).

  * **git_sha — required-to-PASS, nullable-in-VALUE.** C5's
    ``writer.write`` accepts ``git_sha: Optional[str]``. C6 passes
    ``run.get("git_sha")`` which may be None (manual-trigger /
    certain dbt-Cloud states). "Required" (must appear at the call
    site — omitting is TypeError) and "Optional[str]" (value may be
    None — writes SQL NULL) are NOT in tension. Do NOT read
    "Optional" as "omittable." Mutation E pins it.

  * **run_metadata sidecar (C4 G5)** — run_id, job_id, environment_id,
    git_sha come from the ``run`` record (``list_jobs_runs`` output)
    and flow as ``process_envelope`` kwargs — NOT embedded in the
    envelope. The C4 adapter takes ``run_metadata`` as a sidecar arg;
    C6 fans the same record out to ``process_envelope``.

  * **C6 sinks are C6-level, NOT inside process_envelope.** The two
    new sinks (``on_attempted_but_failed``, ``on_source_unavailable``)
    are invoked around the MCP calls — never inside process_envelope.
    process_envelope owns C5's two sinks via its callbacks; conflating
    the four into one would muddy the operational signal (each routes
    to a different remediation owner).

Wiring: C6 is the FIRST module in the triage subsystem to touch MCP
I/O. The MCP client is duck-typed (``DbtCloudClient`` protocol);
tests inject a ``FakeDbtCloudClient``; the C7 cron wires the real
MCP-server-fronted client.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import Any, Callable, Optional, Protocol

from scripts.automation.src.triage.dbt_cloud_adapter import from_dbt_cloud_error
from scripts.automation.src.triage.rca_schema import (
    Classification,
    EvidenceMode,
    Outcome,
    RCARecord,
    SuggestedAction,
)
from scripts.automation.src.triage.writer import TriageWriter, process_envelope

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Public protocol — the MCP-fronted client surface C6 depends on
# ---------------------------------------------------------------------------


class DbtCloudClient(Protocol):
    """Duck-typed MCP client surface (C7 wires the real one).

    Methods MUST be keyword-only (matches the MCP tool surface and
    the required-kwarg discipline carried from C4/C5). Tests inject
    a ``FakeDbtCloudClient`` recording arguments + scripting return
    values / exceptions.
    """

    def list_jobs_runs(
        self,
        *,
        status: str,
        job_id: int,
        limit: int,
        offset: int,
    ) -> list[dict]:  # pragma: no cover — protocol surface only
        ...

    def get_job_run_error(
        self,
        *,
        run_id: int,
    ) -> dict:  # pragma: no cover — protocol surface only
        ...


# ---------------------------------------------------------------------------
# PollPassReport — observable outcome of one polling pass
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class PollPassReport:
    """Outcome of one ``run_poll_pass`` invocation.

    Frozen + by-field-only equality. Consumed by C7 cron to:
      * log per-pass summary
      * decide whether to alert (any ``attempted_but_failed`` or
        ``source_unavailable``)
      * aggregate into the notifier's per-run GH issue body
    """

    high_water_at_start: Optional[int]
    runs_polled: int
    envelopes_processed: int
    invocation_ids: tuple[str, ...] = field(default_factory=tuple)
    attempted_but_failed_run_ids: tuple[int, ...] = field(default_factory=tuple)
    source_unavailable: bool = False
    cursor_lost: bool = False


# ---------------------------------------------------------------------------
# Cursor query — Decision 1 (MAX(run_id) filtered by polled job_ids)
# ---------------------------------------------------------------------------


# WARNING — the watermark MUST remain DERIVED from TRIAGE_INVOCATIONS itself.
# The self-heal property (a crashed/blocked tick writes nothing → the
# high-water cannot advance → the next healthy tick re-polls the missed runs)
# depends on this. If it is ever "optimized" into a separate cursor store that
# advances at poll-START rather than on-write, every crashed tick (e.g., a
# Snowflake network-policy block at connect) flips from "delayed one tick" to
# SILENT DATA LOSS, with nothing announcing the change in failure semantics.
# Keep the cursor table-derived (Decision 1).


# Single canonical template — the test that pins Decision 1 (Mutation A)
# greps this template for ``WHERE job_id IN`` and asserts the bound
# params include every polled job_id. Drift between template and test
# would silently break the cursor-substrate contract.
_HIGH_WATER_SQL_TEMPLATE = (
    "SELECT MAX(run_id) AS high_water "
    "FROM OPS_PROD.LOGS.TRIAGE_INVOCATIONS "
    "WHERE job_id IN ({placeholders})"
)


def _query_high_water(
    cursor: Any,
    job_ids: list[int],
) -> Optional[int]:
    """Derive the cursor high-water from ``MAX(run_id)`` filtered to
    the polled job_ids.

    Per Decision 1: the cursor IS the table's state. ``MAX(run_id)``
    over rows whose ``job_id`` is in scope = the largest run_id we
    have evidence of having processed (including dead-lettered ones,
    which carry their real run_id per the C6 ``attempted_but_failed``
    semantics).

    Returns:
        The high-water run_id, or ``None`` on first-ever poll (no
        rows in TRIAGE_INVOCATIONS for any polled job_id — MAX
        returns SQL NULL → cursor returns None → no
        paginate-until-seen target, paginate hits ``max_pages`` and
        terminates with ``cursor_lost`` flag, normal cold-start
        behaviour).

    Raises:
        TypeError if ``job_ids`` is empty or contains non-int values.
        Whatever the cursor raises on connection / SQL errors —
        propagated to ``run_poll_pass`` which routes to
        ``on_source_unavailable`` (Snowflake unreachable IS a source
        outage — same posture as MCP unreachable).
    """
    if not job_ids:
        raise TypeError(
            "_query_high_water requires at least one job_id "
            "(empty job_ids list would produce an unfiltered "
            "MAX scan which Decision 1 explicitly forbids)"
        )
    if not all(isinstance(jid, int) for jid in job_ids):
        raise TypeError(
            f"_query_high_water: job_ids must all be int, got "
            f"{[type(jid).__name__ for jid in job_ids]}"
        )

    # pyformat named bindings — each job_id is its own bind so the
    # SQL has no string-interpolated user data. The IN-list size is
    # bounded by the cron's polled-job count (Q3: 2 jobs Phase-1, 4
    # jobs Phase-1.5), well under Snowflake's IN-list limit.
    placeholders = ", ".join(f"%(job_id_{i})s" for i in range(len(job_ids)))
    sql = _HIGH_WATER_SQL_TEMPLATE.format(placeholders=placeholders)
    params = {f"job_id_{i}": jid for i, jid in enumerate(job_ids)}

    cursor.execute(sql, params)
    row = cursor.fetchone()
    # DB-API: fetchone returns a tuple (or None on empty result set);
    # Snowflake always returns the aggregate row even when no rows
    # match (high_water is SQL NULL → Python None).
    if row is None:
        return None
    return row[0]  # MAX(run_id) or None


# ---------------------------------------------------------------------------
# Pagination — paginate-until-seen with G7 floors
# ---------------------------------------------------------------------------


def _paginate_runs(
    client: DbtCloudClient,
    *,
    job_id: int,
    high_water: Optional[int],
    max_pages: int,
    finished_at_floor: datetime,
    page_limit: int,
) -> tuple[list[dict], bool]:
    """Paginate ``list_jobs_runs(status=error, order_by=-finished_at)``
    until hitting a run with ``id <= high_water``, then STOP.

    Per §4.9: run_id cursor is CORRECT in normal op because
    ``finished_at`` on ``status=error`` runs is wall-clock-monotonic
    — new error-runs appear before the high-water in
    ``-finished_at`` order. Don't re-derive this; it's scan-settled.

    G7 floors (cursor-lost recovery):
      * ``max_pages`` — hard cap on pages fetched (drop pagination if
        high-water not seen within this many pages).
      * ``finished_at_floor`` — drop pagination once we encounter a
        run older than this floor (the high-water has aged out of
        retention).

    First floor hit ends pagination AND returns ``cursor_lost=True``.
    The caller logs a WARNING and the cron treats this as a CONFIG
    problem (retention / cursor advanced too far), not a per-run
    failure.

    Returns:
        (unseen_runs, cursor_lost) where ``unseen_runs`` is in
        finished_at ASCENDING order (oldest unseen first), as the
        directive requires for processing order.
    """
    collected_newest_first: list[dict] = []
    cursor_lost = False
    saw_high_water = False
    pages_fetched = 0
    offset = 0

    while pages_fetched < max_pages:
        page = client.list_jobs_runs(
            status="error",
            job_id=job_id,
            limit=page_limit,
            offset=offset,
        )
        pages_fetched += 1

        if not page:
            # Empty page means we've exhausted the API's view of
            # error runs for this job. Stop normally — NOT a
            # cursor-lost condition (cold-start with no errors yet
            # also lands here).
            break

        for run in page:
            run_id = run.get("id")
            finished_at_raw = run.get("finished_at")
            finished_at_dt = _parse_finished_at(finished_at_raw)

            # Floor check FIRST — even if this run's id > high_water,
            # we've aged past the retention floor (the high-water is
            # gone). Treat as cursor-lost and stop.
            if (
                finished_at_dt is not None
                and finished_at_dt < finished_at_floor
            ):
                cursor_lost = True
                break

            # High-water hit — normal termination.
            if (
                high_water is not None
                and isinstance(run_id, int)
                and run_id <= high_water
            ):
                saw_high_water = True
                break

            collected_newest_first.append(run)
        else:
            # for-else: ran the page without break — advance by the
            # ACTUAL page size, not the requested ``page_limit``. The
            # dbt-Cloud API may silently cap pages below the
            # requested limit (different versions, server-side
            # throttles); using ``page_limit`` as the offset stride
            # would SKIP ``page_limit - len(page)`` runs per page —
            # silent data loss. DA-found 2026-06-19.
            offset += len(page)
            continue
        # broke out of inner loop — terminate outer too
        break

    # max_pages exhausted without seeing high-water OR a floor hit:
    # cursor is lost. (saw_high_water True OR cursor_lost True OR
    # empty-page-on-cold-start are the OK paths.)
    if (
        pages_fetched >= max_pages
        and not saw_high_water
        and not cursor_lost
        and high_water is not None
    ):
        cursor_lost = True

    # Directive: "Process unseen runs in finished_at order" — ascending
    # (oldest unseen first), since collection above is newest-first.
    return list(reversed(collected_newest_first)), cursor_lost


def _parse_finished_at(raw: Any) -> Optional[datetime]:
    """Parse an ISO-8601 ``finished_at`` value; return None on parse
    failure or absence. Used only for floor comparison — a missing
    finished_at simply means "can't apply the floor for this run,"
    not "this run is invalid."

    Accepts both ``2026-06-19T12:00:00Z`` and
    ``2026-06-19T12:00:00.123456+00:00`` shapes. UTC-normalizes
    naive timestamps (treats them as UTC — matches dbt-Cloud's
    documented behaviour).
    """
    if not isinstance(raw, str):
        return None
    try:
        # Python's fromisoformat in 3.11+ accepts the trailing Z.
        dt = datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


# ---------------------------------------------------------------------------
# K-retry — in-memory transient handling for get_job_run_error
# ---------------------------------------------------------------------------


def _retry_get_job_run_error(
    client: DbtCloudClient,
    run_id: int,
    *,
    k: int,
) -> dict:
    """Call ``client.get_job_run_error(run_id=run_id)``; retry up to
    K times on Exception. After K failures, re-raise the LAST
    exception (the caller routes to the ``attempted_but_failed``
    sink).

    K is the TOTAL attempt count, not "k extra attempts after the
    first failure" — K=3 means at most 3 calls in total. K=1 means
    no retry (the first failure is final). K=0 is rejected at the
    boundary as a configuration error.

    Does NOT catch BaseException — KeyboardInterrupt / SystemExit
    propagate (same posture as C5 process_envelope).
    """
    if k < 1:
        raise ValueError(
            f"_retry_get_job_run_error: k must be >= 1, got {k!r} "
            f"(K=0 would skip the call entirely and silently "
            f"return nothing; K<0 is nonsense)"
        )
    last_exc: Optional[BaseException] = None
    for attempt in range(1, k + 1):
        try:
            return client.get_job_run_error(run_id=run_id)
        except Exception as exc:  # noqa: BLE001 — K-retry policy
            last_exc = exc
            logger.warning(
                "get_job_run_error attempt=%d/%d run_id=%d "
                "exc_type=%s",
                attempt,
                k,
                run_id,
                type(exc).__name__,
            )
    # Loop exited without returning ⇒ all K attempts raised.
    assert last_exc is not None  # for type narrowing
    raise last_exc


# ---------------------------------------------------------------------------
# attempted_but_failed row construction
# ---------------------------------------------------------------------------


def _build_attempted_but_failed_rca(exc_type_name: str, k: int) -> RCARecord:
    """Construct the RCARecord written when ``get_job_run_error``
    fails K times for a known run_id.

    Field choices:
      * ``classification = UNKNOWN`` — we couldn't classify because
        retrieval failed; UNKNOWN is the schema-required value for
        "did not classify."
      * ``confidence = None`` — Rule 3 invariant requires None when
        classification=UNKNOWN.
      * ``suggested_action = ESCALATE_TO_HUMAN`` — operationally
        correct: K retries exhausted means a sustained external
        issue, not a self-healing transient.
      * ``requires_human_review = True`` — Rule 3 invariant.
      * ``evidence_mode = UNDETECTED`` — "no detectable evidence
        shape" semantically aligns with "couldn't retrieve evidence
        at all."
      * ``outcome = TRIAGE_ATTEMPTED_BUT_FAILED`` — the new C6 enum
        value distinguishing this operational story from
        ``UNKNOWN_HANDED_TO_HUMAN`` (which means "we DID see the
        evidence and chose to defer").
      * ``rationale`` — exc TYPE name only, NEVER ``str(exc)`` (which
        could carry credential-shaped substrings). The triage agent's
        own row-3 fail-open boundary makes the same choice; we
        mirror it here.
    """
    return RCARecord(
        classification=Classification.UNKNOWN,
        confidence=None,
        suggested_action=SuggestedAction.ESCALATE_TO_HUMAN,
        requires_human_review=True,
        rationale=(
            f"triage_attempted_but_failed after k={k} retries; "
            f"exc_type={exc_type_name}"
        ),
        evidence_mode=EvidenceMode.UNDETECTED,
        outcome=Outcome.TRIAGE_ATTEMPTED_BUT_FAILED,
    )


# ---------------------------------------------------------------------------
# Per-envelope helpers
# ---------------------------------------------------------------------------


def _extract_unique_id(envelope: dict) -> Optional[str]:
    """Pull ``unique_id`` from the single result in a C4 envelope.

    The C4 adapter shapes each envelope as ``{"data": {"failed_steps":
    [{"results": [<single result>]}]}}`` (single-element lists at both
    positions). The unique_id lives on the result. Returns None on
    any structural deviation — the writer accepts None unique_id and
    the MERGE handles it via COALESCE.
    """
    if not isinstance(envelope, dict):
        return None
    try:
        result = envelope["data"]["failed_steps"][0]["results"][0]
    except (KeyError, IndexError, TypeError):
        return None
    if not isinstance(result, dict):
        return None
    uid = result.get("unique_id")
    return uid if isinstance(uid, str) else None


def _emit_attempted_but_failed(
    *,
    triage_writer: TriageWriter,
    on_attempted_but_failed: Callable[[int, BaseException], None],
    attempted_but_failed_run_ids: list[int],
    run: dict,
    run_id: int,
    job_id: int,
    environment_id: int,
    k: int,
    exc: BaseException,
    reason: str,
) -> None:
    """Emit a ``triage_attempted_but_failed`` dead-letter row + fire
    the C6 callback + append to the report list.

    Single code site for the C6 row-writing taxonomy — the
    K-retry-exhausted path and the adapter-contract-violation path
    BOTH funnel here so the four-way taxonomy invariant has exactly
    one place to grep. ``reason`` is logged for operational
    differentiation (``k_retries_exhausted`` vs ``adapter_contract``)
    but the schema columns are identical.

    Failures of ``triage_writer.write`` propagate — if the writer
    is also down we can't make forward progress anyway, and the
    cron will pick up on next tick.
    """
    rca = _build_attempted_but_failed_rca(
        exc_type_name=type(exc).__name__,
        k=k,
    )
    triage_writer.write(
        rca,
        redaction=None,
        projection=None,
        run_id=run_id,
        job_id=job_id,
        environment_id=environment_id,
        unique_id=None,
        git_sha=run.get("git_sha"),
    )
    logger.error(
        "triage_attempted_but_failed run_id=%d job_id=%d "
        "reason=%s exc_type=%s after_k=%d",
        run_id, job_id, reason, type(exc).__name__, k,
    )
    on_attempted_but_failed(run_id, exc)
    attempted_but_failed_run_ids.append(run_id)


# ---------------------------------------------------------------------------
# Public entrypoint
# ---------------------------------------------------------------------------


def run_poll_pass(
    *,
    client: DbtCloudClient,
    triage_writer: TriageWriter,
    snowflake_cursor: Any,
    job_ids: list[int],
    environment_id: Optional[int] = None,
    on_malformed_input: Callable[[Any, BaseException], None],
    on_operational_error: Callable[[Any, BaseException], None],
    on_attempted_but_failed: Callable[[int, BaseException], None],
    on_source_unavailable: Callable[[BaseException], None],
    k_retries: int = 3,
    max_pages: int = 10,
    finished_at_floor_days: int = 7,
    page_limit: int = 100,
    now_utc: Optional[Callable[[], datetime]] = None,
) -> PollPassReport:
    """Run one polling pass against the in-scope dbt-Cloud jobs.

    Per the directive's structural shape:

      1. Query high-water via ``MAX(run_id)`` filtered to job_ids
         (Decision 1). Snowflake failure here → source_unavailable.
      2. For each polled job_id:
         a. Paginate ``list_jobs_runs(status=error)`` until high-water
            (or G7 floors). MCP failure here → source_unavailable
            (pass aborts before any envelope is processed).
         b. For each unseen run in finished_at-asc order:
            - Retry ``get_job_run_error`` up to k_retries times.
            - On K failures: write attempted_but_failed row + invoke
              on_attempted_but_failed callback + ADVANCE cursor.
            - On success: fan out via C4 → C5 process_envelope per
              envelope.

    All four sinks remain DISTINCT (the C6 ones are C6-level here,
    NOT inside process_envelope). BaseException (KeyboardInterrupt /
    SystemExit) propagates from every code path — no
    ``except BaseException`` anywhere in the loop.

    ``environment_id`` is sourced PER-RUN from each dbt run payload
    (``run["environment_id"]``) — a single pass can span multiple
    environments (e.g. PROD job 786800 + DEV job 786806), so a
    pass-level constant would mislabel rows from the other environment.
    The pass-level ``environment_id`` kwarg is an OPTIONAL fallback for
    a payload missing the field; a run carrying neither is logged +
    skipped (the NOT NULL provenance column cannot be stamped).

    Returns a PollPassReport summarizing the pass. The report is the
    cron's observation surface; nothing about pass success/failure is
    derived from log messages alone.
    """
    if k_retries < 1:
        raise ValueError(f"k_retries must be >= 1, got {k_retries!r}")
    if max_pages < 1:
        raise ValueError(f"max_pages must be >= 1, got {max_pages!r}")
    if page_limit < 1:
        raise ValueError(f"page_limit must be >= 1, got {page_limit!r}")

    now = (now_utc or _default_now_utc)()
    finished_at_floor = now - timedelta(days=finished_at_floor_days)

    # Step 1: high-water lookup — Snowflake outage routes here.
    try:
        high_water = _query_high_water(snowflake_cursor, job_ids)
    except Exception as exc:  # noqa: BLE001 — source-unavailable boundary
        logger.error(
            "triage_source_unavailable subsystem=snowflake "
            "exc_type=%s",
            type(exc).__name__,
        )
        on_source_unavailable(exc)
        return PollPassReport(
            high_water_at_start=None,
            runs_polled=0,
            envelopes_processed=0,
            source_unavailable=True,
        )

    runs_polled = 0
    envelopes_processed = 0
    invocation_ids: list[str] = []
    attempted_but_failed_run_ids: list[int] = []
    cursor_lost = False

    # Step 2: per-job pagination + per-run dispatch.
    for job_id in job_ids:
        try:
            unseen_runs, job_cursor_lost = _paginate_runs(
                client,
                job_id=job_id,
                high_water=high_water,
                max_pages=max_pages,
                finished_at_floor=finished_at_floor,
                page_limit=page_limit,
            )
        except Exception as exc:  # noqa: BLE001 — MCP list outage
            # list_jobs_runs failed for THIS job — no run identified,
            # the entire pass aborts (the four-way taxonomy: this is
            # source_unavailable, not attempted_but_failed). We do NOT
            # continue to the next job_id — a list_jobs_runs failure
            # is symptomatic of a broader MCP outage; pressing on
            # would generate noise + risk processing a partial view
            # (some jobs polled, others skipped, cursor advanced
            # inconsistently).
            logger.error(
                "triage_source_unavailable subsystem=mcp_list_jobs_runs "
                "job_id=%d exc_type=%s",
                job_id,
                type(exc).__name__,
            )
            on_source_unavailable(exc)
            return PollPassReport(
                high_water_at_start=high_water,
                runs_polled=runs_polled,
                envelopes_processed=envelopes_processed,
                invocation_ids=tuple(invocation_ids),
                attempted_but_failed_run_ids=tuple(
                    attempted_but_failed_run_ids
                ),
                source_unavailable=True,
                cursor_lost=cursor_lost,
            )

        if job_cursor_lost:
            cursor_lost = True
            logger.warning(
                "triage_cursor_lost job_id=%d high_water=%r — "
                "G7 floors hit; restarting from latest unseen runs",
                job_id,
                high_water,
            )

        for run in unseen_runs:
            runs_polled += 1
            run_id = run.get("id")
            if not isinstance(run_id, int):
                # Defensive — a list_jobs_runs response without a
                # well-formed id is a malformed source-side payload.
                # Treat as a per-run dead-letter (we can't write a row
                # without run_id, but we also can't process it). Log
                # + skip; cursor doesn't advance (subsequent passes
                # will see the same anomaly until upstream is fixed).
                logger.error(
                    "triage_attempted_but_failed reason=missing_run_id "
                    "job_id=%d", job_id,
                )
                continue

            # environment_id is PER-RUN provenance: one pass can span
            # multiple environments (e.g. PROD job 786800 + DEV job
            # 786806), so it is sourced from THIS run's payload — never a
            # pass-level constant that would mislabel rows from the other
            # environment. The pass-level ``environment_id`` is only a
            # defensive fallback for a payload missing the field.
            run_env_id = run.get("environment_id")
            if not isinstance(run_env_id, int):
                run_env_id = environment_id
            if not isinstance(run_env_id, int):
                # Neither the run payload nor the fallback carries an
                # environment_id — the NOT NULL provenance column cannot
                # be stamped. Log + skip (mirrors the missing-run_id
                # guard above); the cursor does not advance for this run.
                logger.error(
                    "triage_attempted_but_failed "
                    "reason=missing_environment_id job_id=%d run_id=%d",
                    job_id, run_id,
                )
                continue

            try:
                parsed = _retry_get_job_run_error(
                    client, run_id, k=k_retries
                )
            except Exception as exc:  # noqa: BLE001 — K-retry exhausted
                # C6 sink: per-run retrieval failed K times. Write a
                # row carrying the real run_id (so MAX(run_id) sees
                # it next pass and the cursor advances —
                # ORCH-FAIL-OPEN). Single emit-helper enforces the
                # four-way taxonomy invariant at one code site.
                _emit_attempted_but_failed(
                    triage_writer=triage_writer,
                    on_attempted_but_failed=on_attempted_but_failed,
                    attempted_but_failed_run_ids=attempted_but_failed_run_ids,
                    run=run,
                    run_id=run_id,
                    job_id=job_id,
                    environment_id=run_env_id,
                    k=k_retries,
                    exc=exc,
                    reason="k_retries_exhausted",
                )
                continue

            # Success path: fan out envelopes through C4 → C5.
            try:
                envelopes = from_dbt_cloud_error(parsed, run_metadata=run)
            except Exception as exc:  # noqa: BLE001 — adapter contract
                # C4 raised (EmptyResultsContractViolation, TypeError
                # on shape, etc.). This is a SOURCE-side contract
                # violation (the MCP response was structurally wrong)
                # — but we DO know the run_id, so treat it as a
                # per-run attempted_but_failed (same sink class as
                # K-retry exhaustion: "we got the run id but couldn't
                # produce envelopes for it"). NOT source_unavailable
                # — list_jobs_runs and get_job_run_error both
                # SUCCEEDED; the failure is at the parser layer.
                _emit_attempted_but_failed(
                    triage_writer=triage_writer,
                    on_attempted_but_failed=on_attempted_but_failed,
                    attempted_but_failed_run_ids=attempted_but_failed_run_ids,
                    run=run,
                    run_id=run_id,
                    job_id=job_id,
                    environment_id=run_env_id,
                    k=k_retries,
                    exc=exc,
                    reason="adapter_contract",
                )
                continue

            for envelope in envelopes:
                envelopes_processed += 1
                unique_id = _extract_unique_id(envelope)
                # CRITICAL: pass git_sha as run.get("git_sha") — may
                # be None (manual triggers, etc.). Required-to-PASS,
                # nullable-in-VALUE: the kwarg MUST appear (omitting
                # would TypeError at writer.write); the value MAY be
                # None (writes SQL NULL). Mutation E pins this.
                inv_id = process_envelope(
                    envelope,
                    triage_writer,
                    run_id=run_id,
                    job_id=job_id,
                    environment_id=run_env_id,
                    unique_id=unique_id,
                    git_sha=run.get("git_sha"),
                    on_malformed_input=on_malformed_input,
                    on_operational_error=on_operational_error,
                )
                if inv_id is not None:
                    invocation_ids.append(inv_id)

    return PollPassReport(
        high_water_at_start=high_water,
        runs_polled=runs_polled,
        envelopes_processed=envelopes_processed,
        invocation_ids=tuple(invocation_ids),
        attempted_but_failed_run_ids=tuple(attempted_but_failed_run_ids),
        source_unavailable=False,
        cursor_lost=cursor_lost,
    )


def _default_now_utc() -> datetime:
    """Default ``now_utc`` factory — wall-clock UTC. Tests inject a
    fixed ``datetime`` via the ``now_utc`` kwarg to make floor checks
    deterministic.
    """
    return datetime.now(timezone.utc)
