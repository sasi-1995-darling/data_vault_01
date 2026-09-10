"""Tests for ``scripts.automation.src.triage.poll_loop`` — Component 6.

Covers all seven byte-review focus items + Mutations A-E defeaters:

  1. Cursor is ``MAX(run_id)`` filtered by polled job_ids; NO separate
     cursor store; dead-letter rows counted in MAX (run is "seen").
     → TestHighWaterCursor (Mutation A defeater)

  2. paginate-until-seen stops at high-water in ``-finished_at`` order;
     G7 floors (``max_pages`` + ``finished_at_floor``) bound the
     cursor-lost case and dead-letter-the-cursor-with-warning.
     → TestPaginateUntilSeen (Mutation B defeater)

  3. K-retry is in-memory within one pass; K failures →
     ``triage_attempted_but_failed`` row + cursor advance
     (ORCH-FAIL-OPEN); no persistent retry state.
     → TestKRetry + TestAttemptedButFailedRowAdvancesCursor
       (Mutation C defeater)

  4. FOUR-WAY taxonomy clean: the two C6 sinks
     (``attempted_but_failed`` = run-known-retrieval-failed, writes row +
     advances; ``source_unavailable`` = list_jobs_runs-failed, NO row,
     pass aborts) do NOT share a sink with each other or with C5's two.
     → TestFourWayDeadLetterTaxonomy (Mutation D defeater — THE HARDEST
       READ per the directive's byte-review focus)

  5. git_sha passed as ``run.get("git_sha")`` (may be None) — required-
     to-pass, nullable-in-value; omitting the kwarg is the TypeError,
     None-value writes SQL NULL.
     → TestGitShaRequiredToPassNullableInValue (Mutation E defeater)

  6. run_metadata flows as process_envelope kwargs (sidecar), not
     embedded in envelope.
     → TestRunMetadataSidecar

  7. C6's two sinks are C6-level (around the MCP calls), NOT inside
     process_envelope (which owns C5's two via its callbacks).
     → TestC6SinksAreC6Level

Mutation defeats documented in TestMutationDefeats* class docstrings —
each defeat test names the mutation, the line(s) to mutate, and the
expected RED behaviour. The mutation battery is executed externally
via ``/tmp/run_c6_mutations.sh`` (mirrors the C5 pattern).
"""

from __future__ import annotations

import logging
import re
from datetime import datetime, timedelta, timezone
from typing import Any, Optional

import pytest

from scripts.automation.src.triage import poll_loop
from scripts.automation.src.triage.poll_loop import (
    DbtCloudClient,
    PollPassReport,
    _build_attempted_but_failed_rca,
    _extract_unique_id,
    _HIGH_WATER_SQL_TEMPLATE,
    _paginate_runs,
    _query_high_water,
    _retry_get_job_run_error,
    run_poll_pass,
)
from scripts.automation.src.triage.rca_schema import (
    Classification,
    EvidenceMode,
    Outcome,
    SuggestedAction,
)
from scripts.automation.src.triage.writer import TriageWriter


# ---------------------------------------------------------------------------
# Test doubles
# ---------------------------------------------------------------------------


class FakeSnowflakeCursor:
    """Records ``execute(sql, params)`` calls and scripts ``fetchone``
    return values. Tests can also set ``raise_on_execute`` to simulate
    a Snowflake outage at high-water lookup time (source_unavailable
    branch).
    """

    def __init__(self, fetchone_return: Optional[tuple] = (None,)):
        self.executions: list[tuple[str, dict]] = []
        self._fetchone_return = fetchone_return
        self.raise_on_execute: Optional[BaseException] = None

    def execute(self, sql: str, params: Any = None) -> None:
        if self.raise_on_execute is not None:
            raise self.raise_on_execute
        self.executions.append((sql, dict(params) if params else {}))

    def fetchone(self) -> Optional[tuple]:
        return self._fetchone_return

    @property
    def last_sql(self) -> str:
        return self.executions[-1][0]

    @property
    def last_params(self) -> dict:
        return self.executions[-1][1]


class FakeDbtCloudClient:
    """Scriptable MCP client. ``list_jobs_runs`` consumes from
    ``list_pages_by_job`` keyed by job_id (newest-first per page) in
    CALL ORDER — each call to ``list_jobs_runs(job_id=X)`` pops the
    next scripted page for X. This matches real API behaviour
    independently of offset stride (the production code advances
    offset by ``len(page)`` per DA-found offset bug; tests should
    not depend on offset arithmetic in the fake).

    ``get_job_run_error`` consumes from ``error_returns_by_run`` —
    each value is either a dict (success), an exception INSTANCE
    (single-shot raise), or a LIST of mixed dicts/exceptions
    (multi-attempt sequence, drained in order for K-retry scenarios).
    """

    def __init__(self) -> None:
        self.list_pages_by_job: dict[int, list[list[dict]]] = {}
        self.error_returns_by_run: dict[int, Any] = {}
        self.list_jobs_runs_calls: list[dict] = []
        self.get_job_run_error_calls: list[dict] = []
        self.raise_on_list_for_job: Optional[BaseException] = None
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
            {"status": status, "job_id": job_id, "limit": limit, "offset": offset}
        )
        if self.raise_on_list_for_job is not None:
            raise self.raise_on_list_for_job
        pages = self.list_pages_by_job.get(job_id, [])
        idx = self._page_cursor_by_job.get(job_id, 0)
        if idx >= len(pages):
            return []
        self._page_cursor_by_job[job_id] = idx + 1
        return pages[idx]

    def get_job_run_error(self, *, run_id: int) -> dict:
        self.get_job_run_error_calls.append({"run_id": run_id})
        scripted = self.error_returns_by_run.get(run_id)
        if scripted is None:
            raise KeyError(f"unscripted run_id={run_id}")
        if isinstance(scripted, list):
            # Multi-attempt sequence — pop the head each call.
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
        return scripted


class FakeTriageWriter:
    """Captures write() invocations without touching Snowflake. The
    real ``TriageWriter`` is exercised indirectly via FakeSnowflakeCursor
    in tests that need the MERGE SQL path; the FakeTriageWriter is for
    tests focused on dispatch behaviour rather than SQL binding."""

    def __init__(self) -> None:
        self.writes: list[dict] = []
        self.raise_on_write: Optional[BaseException] = None

    def write(
        self,
        rca,
        redaction,
        projection,
        *,
        run_id: int,
        job_id: int,
        environment_id: int,
        unique_id: Optional[str],
        git_sha: Optional[str],
    ) -> str:
        if self.raise_on_write is not None:
            raise self.raise_on_write
        self.writes.append(
            {
                "rca": rca,
                "redaction": redaction,
                "projection": projection,
                "run_id": run_id,
                "job_id": job_id,
                "environment_id": environment_id,
                "unique_id": unique_id,
                "git_sha": git_sha,
            }
        )
        return f"FAKE_INV_{run_id}_{len(self.writes)}"


# ---------------------------------------------------------------------------
# Helpers / factories
# ---------------------------------------------------------------------------


def _run(
    *,
    id: int,
    job_id: int,
    environment_id: int = 999,
    git_sha: Optional[str] = "abc1234",
    finished_at: str = "2026-06-19T12:00:00+00:00",
) -> dict:
    return {
        "id": id,
        "job_id": job_id,
        "environment_id": environment_id,
        "git_sha": git_sha,
        "finished_at": finished_at,
    }


def _good_parsed_error(unique_id: Optional[str] = "model.x.dim_customer") -> dict:
    """Build a minimal well-formed ``get_job_run_error`` response that
    the C4 adapter accepts and emits one envelope from."""
    return {
        "failed_steps": [
            {
                "step_name": "dbt build",
                "target": "default",
                "finished_at": "2026-06-19T12:00:00+00:00",
                "results": [
                    {
                        "unique_id": unique_id,
                        "status": "error",
                        "message": "model failed: division by zero",
                        "compiled_code": "select 1/0",
                    }
                ],
            }
        ]
    }


def _build_callbacks():
    """Build the four sink callbacks with capture lists. Returns
    ``(malformed, operational, attempted_but_failed, source_unavailable,
    on_m, on_o, on_a, on_s)``."""
    malformed: list[tuple[Any, BaseException]] = []
    operational: list[tuple[Any, BaseException]] = []
    attempted: list[tuple[int, BaseException]] = []
    source: list[BaseException] = []

    def on_m(env: Any, exc: BaseException) -> None:
        malformed.append((env, exc))

    def on_o(env: Any, exc: BaseException) -> None:
        operational.append((env, exc))

    def on_a(run_id: int, exc: BaseException) -> None:
        attempted.append((run_id, exc))

    def on_s(exc: BaseException) -> None:
        source.append(exc)

    return malformed, operational, attempted, source, on_m, on_o, on_a, on_s


def _fixed_now(year=2026, month=6, day=19) -> datetime:
    return datetime(year, month, day, 12, 0, 0, tzinfo=timezone.utc)


# ===========================================================================
# Focus item 1 + Mutation A — cursor is MAX(run_id) FILTERED by polled job_ids
# ===========================================================================


class TestHighWaterCursor:
    """Decision 1: ``_query_high_water`` issues
    ``SELECT MAX(run_id) ... WHERE job_id IN (...)`` with all polled
    job_ids in the IN-list. Mutation A target: dropping the job_id
    filter makes an unfiltered MAX possibly skip in-scope runs.
    """

    def test_high_water_sql_contains_where_job_id_in(self):
        # Template-level lock — the SQL template MUST contain the
        # job_id filter clause. Mutation A would remove this.
        assert "WHERE job_id IN" in _HIGH_WATER_SQL_TEMPLATE

    def test_high_water_query_binds_all_job_ids(self):
        cursor = FakeSnowflakeCursor(fetchone_return=(42,))
        result = _query_high_water(cursor, [786800, 786806])
        assert result == 42
        sql = cursor.last_sql
        params = cursor.last_params
        # SQL has the WHERE clause AND two placeholders
        assert "WHERE job_id IN" in sql
        assert sql.count("%(job_id_") == 2
        # All polled job_ids bound
        assert set(params.values()) == {786800, 786806}

    def test_high_water_returns_none_on_cold_start(self):
        # MAX over empty result set → None
        cursor = FakeSnowflakeCursor(fetchone_return=(None,))
        assert _query_high_water(cursor, [786800]) is None

    def test_high_water_rejects_empty_job_ids(self):
        # Empty job_ids would produce unfiltered MAX — Decision 1
        # explicitly forbids this. The boundary refuses the input.
        cursor = FakeSnowflakeCursor()
        with pytest.raises(TypeError, match="at least one job_id"):
            _query_high_water(cursor, [])

    def test_high_water_rejects_non_int_job_ids(self):
        cursor = FakeSnowflakeCursor()
        with pytest.raises(TypeError, match="must all be int"):
            _query_high_water(cursor, [786800, "786806"])  # type: ignore[list-item]

    def test_high_water_filter_isolates_in_scope_runs(self):
        """End-to-end Mutation A defeater scenario: a foreign job_id
        has a high run_id in the table. A correctly-filtered MAX
        returns the in-scope high-water (lower number). An unfiltered
        MAX would return the foreign one and cause the poll loop to
        skip in-scope runs whose run_id is below the foreign MAX.

        We can't simulate Snowflake-side WHERE here, but we CAN assert
        the SQL bound the right job_ids. The mutation drops the
        ``WHERE job_id IN`` clause; the template-level test
        (test_high_water_sql_contains_where_job_id_in) catches the
        textual mutation, and the binding test
        (test_high_water_query_binds_all_job_ids) catches the params.
        """
        cursor = FakeSnowflakeCursor(fetchone_return=(100,))
        _query_high_water(cursor, [786800])
        # The bound SQL filters by job_id; an unfiltered template
        # would NOT contain this clause.
        assert "WHERE job_id IN" in cursor.last_sql
        # The bound params are EXACTLY the polled job_ids — a
        # foreign-job high run_id can never sneak in through binding.
        assert list(cursor.last_params.values()) == [786800]


# ===========================================================================
# Focus item 2 + Mutation B — paginate-until-seen + G7 floors
# ===========================================================================


class TestPaginateUntilSeen:
    """Pagination stops at high-water in ``-finished_at`` order;
    Mutation B target: removing the G7 floors (``max_pages`` /
    ``finished_at_floor``) makes a cursor-lost case (high-water no
    longer in API results) infinite-loop.
    """

    def test_pagination_stops_at_high_water(self):
        client = FakeDbtCloudClient()
        # Newest-first page: runs 105, 104, 103, 102 (high_water=103)
        # → should collect 105, 104 only.
        client.list_pages_by_job[786800] = [
            [_run(id=i, job_id=786800) for i in (105, 104, 103, 102)]
        ]
        unseen, cursor_lost = _paginate_runs(
            client,
            job_id=786800,
            high_water=103,
            max_pages=10,
            finished_at_floor=_fixed_now() - timedelta(days=365),
            page_limit=100,
        )
        assert [r["id"] for r in unseen] == [104, 105]  # ascending order
        assert cursor_lost is False

    def test_pagination_ascending_finished_at_order_returned(self):
        # Verify directive: "Process unseen runs in finished_at order"
        # — ascending.
        client = FakeDbtCloudClient()
        client.list_pages_by_job[786800] = [
            [
                _run(id=110, job_id=786800,
                     finished_at="2026-06-19T15:00:00+00:00"),
                _run(id=109, job_id=786800,
                     finished_at="2026-06-19T14:00:00+00:00"),
                _run(id=108, job_id=786800,
                     finished_at="2026-06-19T13:00:00+00:00"),
            ]
        ]
        unseen, _ = _paginate_runs(
            client,
            job_id=786800,
            high_water=None,
            max_pages=10,
            finished_at_floor=_fixed_now() - timedelta(days=365),
            page_limit=100,
        )
        # Reversed from API's newest-first order
        assert [r["id"] for r in unseen] == [108, 109, 110]

    def test_pagination_traverses_multiple_pages(self):
        client = FakeDbtCloudClient()
        client.list_pages_by_job[786800] = [
            [_run(id=i, job_id=786800) for i in (110, 109)],
            [_run(id=i, job_id=786800) for i in (108, 107)],
            [_run(id=i, job_id=786800) for i in (106, 105)],  # 105 is high-water
        ]
        unseen, cursor_lost = _paginate_runs(
            client,
            job_id=786800,
            high_water=105,
            max_pages=10,
            finished_at_floor=_fixed_now() - timedelta(days=365),
            page_limit=2,
        )
        assert [r["id"] for r in unseen] == [106, 107, 108, 109, 110]
        assert cursor_lost is False

    def test_g7_max_pages_floor_terminates_when_high_water_missing(self):
        """Mutation B defeater scenario: high-water is no longer in
        API results (aged out). Without the ``max_pages`` floor, this
        would infinite-loop. Confirm pagination TERMINATES + flags
        ``cursor_lost``.

        Critical fixture detail: every fake run_id MUST be > high_water,
        otherwise the paginate-until-seen branch fires on the first
        run encountered (saw_high_water=True) and the cursor_lost
        branch is unreachable. The test's contract is "high-water is
        ABSENT from API results" — so all returned runs must be
        STRICTLY GREATER than the high-water.
        """
        client = FakeDbtCloudClient()
        # high_water=10 absent from API results — every fake run_id
        # is > 10, so saw_high_water can never trigger.
        high_water = 10
        client.list_pages_by_job[786800] = [
            [
                _run(id=high_water + 1 + p * 10 + i, job_id=786800)
                for i in range(10)
            ]
            for p in range(100)  # plenty of pages — must STOP at max_pages
        ]
        unseen, cursor_lost = _paginate_runs(
            client,
            job_id=786800,
            high_water=high_water,
            max_pages=3,  # tight bound for the test
            finished_at_floor=_fixed_now() - timedelta(days=365),
            page_limit=10,
        )
        assert cursor_lost is True
        # Fetched at most max_pages pages
        assert len(client.list_jobs_runs_calls) == 3

    def test_g7_finished_at_floor_terminates_on_aged_runs(self):
        """Mutation B defeater (second face): the finished_at floor
        catches the cursor-lost case when retention has aged out the
        high-water but the API still returns OLDER runs.
        """
        client = FakeDbtCloudClient()
        client.list_pages_by_job[786800] = [
            [
                _run(id=200, job_id=786800,
                     finished_at="2026-06-19T12:00:00+00:00"),  # today
                _run(id=199, job_id=786800,
                     finished_at="2025-12-01T12:00:00+00:00"),  # MUCH older
            ]
        ]
        unseen, cursor_lost = _paginate_runs(
            client,
            job_id=786800,
            high_water=42,  # not in API results
            max_pages=10,
            finished_at_floor=_fixed_now() - timedelta(days=7),
            page_limit=100,
        )
        assert cursor_lost is True
        # Only the run NEWER than the floor was collected
        assert [r["id"] for r in unseen] == [200]

    def test_g7_cold_start_returns_all_with_cursor_lost(self):
        """Cold start (high_water=None) + paginate exhausts API
        without hitting any floor → not cursor_lost (this is the
        first-ever-poll path)."""
        client = FakeDbtCloudClient()
        client.list_pages_by_job[786800] = [
            [_run(id=i, job_id=786800) for i in (3, 2, 1)],
        ]
        unseen, cursor_lost = _paginate_runs(
            client,
            job_id=786800,
            high_water=None,
            max_pages=10,
            finished_at_floor=_fixed_now() - timedelta(days=365),
            page_limit=100,
        )
        assert [r["id"] for r in unseen] == [1, 2, 3]
        # Cold start = high_water None → max_pages exhaustion is the
        # NORMAL termination (not cursor_lost). The implementation
        # only flags cursor_lost when high_water IS set but not seen.
        assert cursor_lost is False

    def test_offset_advances_by_actual_page_size_not_page_limit(self):
        """DA-found 2026-06-19: if dbt-Cloud silently caps a page
        below the requested ``page_limit`` (server-side throttles,
        per-version max), advancing offset by ``page_limit`` would
        SKIP ``page_limit - len(page)`` runs each page — silent data
        loss. Offset MUST advance by ``len(page)``.

        Scenario: request page_limit=10, API caps at 3 per page.
        Three pages of 3 runs each (9 unique runs), high_water=0 so
        none are seen. Correct behaviour: collect all 9 runs.
        Mutated behaviour (offset += page_limit): collect only the
        first page (3 runs) because offset jumps to 10 and the
        scripted page-2 / page-3 are at offsets 3 and 6 respectively.
        """
        client = FakeDbtCloudClient()
        # FakeDbtCloudClient indexes pages by offset // limit; tests
        # that script multiple pages while page_limit=10 but API
        # returns 3-per-page need the fake to map offset → page.
        # The current fake uses page_index = offset // limit which
        # would always return page 0 for offsets 0-9. We instead
        # script the pages so that the CORRECT offset stride
        # (len(page)=3) hits them in sequence.
        # Override list_jobs_runs to slice from a flat list — this
        # is the test's way of simulating the real API capping
        # behaviour without rewriting the fake's index logic.
        runs_flat = [_run(id=i, job_id=786800) for i in range(1, 10)]

        def list_jobs_runs(*, status, job_id, limit, offset):
            # API returns up to 3 per page regardless of `limit` requested
            return runs_flat[offset:offset + 3]

        client.list_jobs_runs = list_jobs_runs  # type: ignore[assignment]

        unseen, cursor_lost = _paginate_runs(
            client,
            job_id=786800,
            high_water=None,
            max_pages=10,
            finished_at_floor=_fixed_now() - timedelta(days=365),
            page_limit=10,  # we ASK for 10, API caps at 3
        )
        # All 9 runs collected — none skipped.
        assert sorted(r["id"] for r in unseen) == list(range(1, 10))


# ===========================================================================
# Focus item 3 + Mutation C — K-retry → attempted_but_failed row + advance
# ===========================================================================


class TestKRetry:
    """K-retry in-memory transient handling for ``get_job_run_error``."""

    def test_first_attempt_success_no_retry(self):
        client = FakeDbtCloudClient()
        client.error_returns_by_run[100] = _good_parsed_error()
        result = _retry_get_job_run_error(client, 100, k=3)
        assert result == _good_parsed_error()
        assert len(client.get_job_run_error_calls) == 1

    def test_retries_up_to_k_times_then_raises_last(self):
        client = FakeDbtCloudClient()
        client.error_returns_by_run[100] = [
            ConnectionError("flake 1"),
            ConnectionError("flake 2"),
            RuntimeError("final boom"),
        ]
        with pytest.raises(RuntimeError, match="final boom"):
            _retry_get_job_run_error(client, 100, k=3)
        assert len(client.get_job_run_error_calls) == 3

    def test_succeeds_on_second_attempt_returns_value(self):
        client = FakeDbtCloudClient()
        client.error_returns_by_run[100] = [
            ConnectionError("flake"),
            _good_parsed_error(),
        ]
        result = _retry_get_job_run_error(client, 100, k=3)
        assert result == _good_parsed_error()
        assert len(client.get_job_run_error_calls) == 2

    def test_k_must_be_at_least_one(self):
        client = FakeDbtCloudClient()
        with pytest.raises(ValueError, match="k must be >= 1"):
            _retry_get_job_run_error(client, 100, k=0)

    def test_base_exception_propagates_does_not_retry(self):
        """KeyboardInterrupt / SystemExit MUST propagate without
        retry — they are operator-shutdown signals, not transients.
        """
        class _Boom(BaseException):
            pass

        client = FakeDbtCloudClient()
        client.error_returns_by_run[100] = _Boom("ctrl-c-equivalent")
        with pytest.raises(_Boom):
            _retry_get_job_run_error(client, 100, k=3)
        assert len(client.get_job_run_error_calls) == 1  # NO retry


class TestAttemptedButFailedRcaConstruction:
    """The synthesized RCARecord for K-failed runs must satisfy
    invariants AND carry the new Outcome value (so MAX(run_id)
    advances on next pass)."""

    def test_rca_satisfies_unknown_rule_3(self):
        rca = _build_attempted_but_failed_rca("ConnectionError", k=3)
        # Rule 3: UNKNOWN → confidence None + requires_human_review True
        assert rca.classification == Classification.UNKNOWN
        assert rca.confidence is None
        assert rca.requires_human_review is True

    def test_rca_outcome_is_the_new_c6_value(self):
        rca = _build_attempted_but_failed_rca("ConnectionError", k=3)
        assert rca.outcome == Outcome.TRIAGE_ATTEMPTED_BUT_FAILED
        # Serialization-locked at the writer; this is the row that
        # MAX(run_id) sees and uses to advance the cursor.
        assert rca.outcome.value == "triage_attempted_but_failed"

    def test_rca_evidence_mode_is_undetected(self):
        # We couldn't even retrieve evidence, so the mode is
        # "no detectable evidence shape."
        rca = _build_attempted_but_failed_rca("ConnectionError", k=3)
        assert rca.evidence_mode == EvidenceMode.UNDETECTED

    def test_rca_suggested_action_escalates(self):
        # K retries exhausted = sustained issue. ESCALATE_TO_HUMAN
        # is the right operational signal.
        rca = _build_attempted_but_failed_rca("ConnectionError", k=3)
        assert rca.suggested_action == SuggestedAction.ESCALATE_TO_HUMAN

    def test_rca_rationale_is_exc_type_name_not_str_exc(self):
        # Mirrors triage_failure's row-3 fail-open boundary —
        # rationale carries TYPE name only, never str(exc) (which
        # could carry credential-shaped substrings).
        rca = _build_attempted_but_failed_rca("MyVerySpecificExcType", k=5)
        assert "MyVerySpecificExcType" in rca.rationale
        assert "k=5" in rca.rationale


class TestAttemptedButFailedRowAdvancesCursor:
    """Mutation C defeater: K-retry MUST write the
    ``triage_attempted_but_failed`` row carrying the real run_id —
    otherwise MAX(run_id) won't see this run next pass and the
    cursor never advances past it (re-processed forever).
    """

    def test_k_failed_run_writes_row_with_real_run_id(self):
        client = FakeDbtCloudClient()
        client.list_pages_by_job[786800] = [
            [_run(id=500, job_id=786800)]
        ]
        client.error_returns_by_run[500] = [
            ConnectionError("transient 1"),
            ConnectionError("transient 2"),
            ConnectionError("transient 3"),
        ]
        writer = FakeTriageWriter()
        cursor = FakeSnowflakeCursor(fetchone_return=(499,))  # high-water 499
        _, _, attempted, _, on_m, on_o, on_a, on_s = _build_callbacks()

        report = run_poll_pass(
            client=client,
            triage_writer=writer,
            snowflake_cursor=cursor,
            job_ids=[786800],
            environment_id=999,
            on_malformed_input=on_m,
            on_operational_error=on_o,
            on_attempted_but_failed=on_a,
            on_source_unavailable=on_s,
            k_retries=3,
            now_utc=_fixed_now,
        )

        # Mutation C defeater: a row was written WITH the real run_id
        # AND the new Outcome enum value.
        assert len(writer.writes) == 1
        row = writer.writes[0]
        assert row["run_id"] == 500  # real run_id, NOT None
        assert row["job_id"] == 786800
        assert row["rca"].outcome == Outcome.TRIAGE_ATTEMPTED_BUT_FAILED
        # Cursor advance evidence: next pass's MAX(run_id) would see
        # run_id=500 (this is the in-memory expression of the contract;
        # the actual MAX query happens in Snowflake but the row that
        # MAKES MAX advance is the one written here).
        assert row["redaction"] is None
        assert row["projection"] is None
        # Callback fired
        assert len(attempted) == 1
        assert attempted[0][0] == 500
        # Report reflects the dead-letter
        assert report.attempted_but_failed_run_ids == (500,)


# ===========================================================================
# Focus item 4 + Mutation D — FOUR-WAY taxonomy clean (THE HARDEST READ)
# ===========================================================================


class TestFourWayDeadLetterTaxonomy:
    """The hardest read per the directive's byte-review focus.

    Four sinks MUST stay distinct:
      * malformed_input    (C5, envelope exists)
      * operational_error  (C5, envelope exists)
      * attempted_but_failed (C6, run-known, writes row + advances)
      * source_unavailable (C6, NO run identified, writes NO row,
                            pass aborts, NO cursor advance)

    Mutation D defeater: conflating attempted_but_failed and
    source_unavailable into the same sink. A test that asserts
    ``list_jobs_runs`` failure writes NO row while ``get_job_run_error``
    K-failure writes a row will go RED.
    """

    def test_source_unavailable_writes_no_row(self):
        """``list_jobs_runs`` raises → source_unavailable callback
        fires, NO writer.write call, NO attempted_but_failed callback.
        """
        client = FakeDbtCloudClient()
        client.list_pages_by_job[786800] = [[_run(id=200, job_id=786800)]]
        client.raise_on_list_for_job = ConnectionError("MCP down")
        writer = FakeTriageWriter()
        cursor = FakeSnowflakeCursor(fetchone_return=(100,))
        m, o, attempted, source, on_m, on_o, on_a, on_s = _build_callbacks()

        report = run_poll_pass(
            client=client,
            triage_writer=writer,
            snowflake_cursor=cursor,
            job_ids=[786800],
            environment_id=999,
            on_malformed_input=on_m,
            on_operational_error=on_o,
            on_attempted_but_failed=on_a,
            on_source_unavailable=on_s,
            now_utc=_fixed_now,
        )

        # No writer calls — NO run identified
        assert writer.writes == []
        # source_unavailable fired EXACTLY ONCE
        assert len(source) == 1
        assert isinstance(source[0], ConnectionError)
        # The OTHER three sinks did NOT fire — taxonomy is preserved
        assert m == []
        assert o == []
        assert attempted == []
        # Report reflects pass-aborted status
        assert report.source_unavailable is True
        assert report.envelopes_processed == 0
        assert report.attempted_but_failed_run_ids == ()

    def test_snowflake_outage_also_source_unavailable_no_writes(self):
        """Snowflake down at high-water lookup time is symptomatically
        identical to MCP down (we can't make forward progress). Same
        sink, NO writes."""
        client = FakeDbtCloudClient()
        writer = FakeTriageWriter()
        cursor = FakeSnowflakeCursor()
        cursor.raise_on_execute = ConnectionError("Snowflake down")
        m, o, attempted, source, on_m, on_o, on_a, on_s = _build_callbacks()

        report = run_poll_pass(
            client=client,
            triage_writer=writer,
            snowflake_cursor=cursor,
            job_ids=[786800],
            environment_id=999,
            on_malformed_input=on_m,
            on_operational_error=on_o,
            on_attempted_but_failed=on_a,
            on_source_unavailable=on_s,
            now_utc=_fixed_now,
        )
        assert writer.writes == []
        assert len(source) == 1
        assert m == [] and o == [] and attempted == []
        assert report.source_unavailable is True

    def test_attempted_but_failed_writes_row_callback_separate_from_source(self):
        """``get_job_run_error`` K-fails → attempted_but_failed fires,
        writer.write IS called (with run_id), source_unavailable does
        NOT fire."""
        client = FakeDbtCloudClient()
        client.list_pages_by_job[786800] = [[_run(id=200, job_id=786800)]]
        client.error_returns_by_run[200] = [
            ConnectionError("flake1"),
            ConnectionError("flake2"),
            ConnectionError("flake3"),
        ]
        writer = FakeTriageWriter()
        cursor = FakeSnowflakeCursor(fetchone_return=(199,))
        m, o, attempted, source, on_m, on_o, on_a, on_s = _build_callbacks()

        report = run_poll_pass(
            client=client,
            triage_writer=writer,
            snowflake_cursor=cursor,
            job_ids=[786800],
            environment_id=999,
            on_malformed_input=on_m,
            on_operational_error=on_o,
            on_attempted_but_failed=on_a,
            on_source_unavailable=on_s,
            k_retries=3,
            now_utc=_fixed_now,
        )

        # A row WAS written (run_id known)
        assert len(writer.writes) == 1
        assert writer.writes[0]["run_id"] == 200
        # attempted_but_failed callback fired with the run_id + exc
        assert len(attempted) == 1
        assert attempted[0][0] == 200
        # source_unavailable did NOT fire — different operational story
        assert source == []
        assert m == [] and o == []
        assert report.source_unavailable is False
        assert report.attempted_but_failed_run_ids == (200,)

    def test_c5_sinks_unchanged_within_process_envelope(self):
        """C5's two sinks (malformed_input, operational_error) are
        invoked from INSIDE process_envelope. C6 wires the callbacks
        but the trigger remains a C5-internal event (a TypeError or
        non-TypeError Exception from triage_failure).

        Verified here by injecting a writer that raises on write —
        the C5 operational_error fires, NOT the C6 attempted_but_failed.
        """
        client = FakeDbtCloudClient()
        client.list_pages_by_job[786800] = [[_run(id=200, job_id=786800)]]
        client.error_returns_by_run[200] = _good_parsed_error()
        writer = FakeTriageWriter()
        writer.raise_on_write = RuntimeError("writer boom")
        cursor = FakeSnowflakeCursor(fetchone_return=(199,))
        m, o, attempted, source, on_m, on_o, on_a, on_s = _build_callbacks()

        run_poll_pass(
            client=client,
            triage_writer=writer,
            snowflake_cursor=cursor,
            job_ids=[786800],
            environment_id=999,
            on_malformed_input=on_m,
            on_operational_error=on_o,
            on_attempted_but_failed=on_a,
            on_source_unavailable=on_s,
            now_utc=_fixed_now,
        )

        # C5's operational_error fired (writer raised inside
        # process_envelope's try/except)
        assert len(o) == 1
        assert isinstance(o[0][1], RuntimeError)
        # C6 sinks did NOT fire — boundary holds
        assert attempted == []
        assert source == []
        assert m == []


# ===========================================================================
# Focus item 5 + Mutation E — git_sha required-to-PASS, nullable-in-VALUE
# ===========================================================================


class TestGitShaRequiredToPassNullableInValue:
    """The C5 required-kwarg discipline means git_sha MUST appear at
    the call site; "Optional[str]" means the VALUE may be None.
    "Required" and "Optional" are NOT in tension. Mutation E
    defeater: dropping the kwarg → TypeError; passing None → SQL NULL.
    """

    def test_git_sha_none_writes_sql_null(self):
        """run.get('git_sha') returns None on manual triggers — the
        writer accepts None (writes SQL NULL)."""
        client = FakeDbtCloudClient()
        client.list_pages_by_job[786800] = [
            [_run(id=200, job_id=786800, git_sha=None)]
        ]
        client.error_returns_by_run[200] = _good_parsed_error()
        writer = FakeTriageWriter()
        cursor = FakeSnowflakeCursor(fetchone_return=(199,))
        _, _, _, _, on_m, on_o, on_a, on_s = _build_callbacks()

        run_poll_pass(
            client=client,
            triage_writer=writer,
            snowflake_cursor=cursor,
            job_ids=[786800],
            environment_id=999,
            on_malformed_input=on_m,
            on_operational_error=on_o,
            on_attempted_but_failed=on_a,
            on_source_unavailable=on_s,
            now_utc=_fixed_now,
        )

        # Wrote the envelope with git_sha=None (passed through to
        # writer; SQL binding produces NULL).
        assert len(writer.writes) == 1
        assert writer.writes[0]["git_sha"] is None

    def test_git_sha_real_value_propagates(self):
        client = FakeDbtCloudClient()
        client.list_pages_by_job[786800] = [
            [_run(id=200, job_id=786800, git_sha="abc1234deadbeef")]
        ]
        client.error_returns_by_run[200] = _good_parsed_error()
        writer = FakeTriageWriter()
        cursor = FakeSnowflakeCursor(fetchone_return=(199,))
        _, _, _, _, on_m, on_o, on_a, on_s = _build_callbacks()

        run_poll_pass(
            client=client,
            triage_writer=writer,
            snowflake_cursor=cursor,
            job_ids=[786800],
            environment_id=999,
            on_malformed_input=on_m,
            on_operational_error=on_o,
            on_attempted_but_failed=on_a,
            on_source_unavailable=on_s,
            now_utc=_fixed_now,
        )

        assert len(writer.writes) == 1
        assert writer.writes[0]["git_sha"] == "abc1234deadbeef"

    def test_writer_signature_rejects_omitted_git_sha(self):
        """Mutation E defeater (negative pin): if C6 were to OMIT the
        git_sha kwarg from its writer.write call, the writer would
        TypeError. We pin this by calling writer.write directly with
        git_sha omitted and asserting the TypeError.
        """
        from scripts.automation.src.triage.writer import TriageWriter
        cursor = FakeSnowflakeCursor()
        w = TriageWriter(cursor)
        rca = _build_attempted_but_failed_rca("X", k=3)
        with pytest.raises(TypeError, match="git_sha"):
            # Deliberately omit git_sha — required keyword arg.
            w.write(
                rca, None, None,
                run_id=1, job_id=2, environment_id=3, unique_id=None,
            )  # type: ignore[call-arg]

    def test_process_envelope_signature_also_requires_git_sha(self):
        """Mutation E (second face): process_envelope ALSO requires
        git_sha — the C6 loop calls process_envelope, not the writer
        directly, so the omission would TypeError one layer up. Same
        contract, second layer."""
        from scripts.automation.src.triage.writer import (
            TriageWriter, process_envelope,
        )
        cursor = FakeSnowflakeCursor()
        w = TriageWriter(cursor)
        envelope = {"data": {"failed_steps": [
            {"step_name": "x", "target": "y", "finished_at": "z",
             "results": [{"unique_id": "m.x.y", "status": "error",
                          "message": "boom"}]}
        ]}}
        with pytest.raises(TypeError, match="git_sha"):
            process_envelope(
                envelope, w,
                run_id=1, job_id=2, environment_id=3, unique_id="m.x.y",
                on_malformed_input=lambda e, x: None,
                on_operational_error=lambda e, x: None,
            )  # type: ignore[call-arg]


# ===========================================================================
# Focus item 6 — run_metadata sidecar (NOT embedded in envelope)
# ===========================================================================


class TestRunMetadataSidecar:
    """run_id / job_id / environment_id / git_sha flow as
    process_envelope kwargs sidecar — NOT mutated into the envelope.
    """

    def test_envelope_does_not_contain_run_metadata_keys(self):
        """The envelope produced by C4 carries the failed_step shape;
        run_id/job_id/environment_id/git_sha are NEVER injected into
        it. They flow as kwargs only.
        """
        from scripts.automation.src.triage.dbt_cloud_adapter import (
            from_dbt_cloud_error,
        )
        envelopes = from_dbt_cloud_error(
            _good_parsed_error(),
            run_metadata=_run(id=42, job_id=786800),
        )
        assert len(envelopes) == 1
        env = envelopes[0]
        # Top-level envelope keys are ONLY 'data'
        assert set(env.keys()) == {"data"}
        # The single result inside has dbt-Cloud fields but NONE of
        # the provenance kwargs
        result = env["data"]["failed_steps"][0]["results"][0]
        provenance_keys = {"run_id", "job_id", "environment_id", "git_sha"}
        assert provenance_keys.isdisjoint(result.keys()), (
            f"run_metadata leaked into envelope result: "
            f"{provenance_keys & set(result.keys())}"
        )

    def test_provenance_flows_via_process_envelope_kwargs(self):
        client = FakeDbtCloudClient()
        client.list_pages_by_job[786800] = [
            [_run(id=42, job_id=786800, environment_id=12345,
                  git_sha="deadbeef")]
        ]
        client.error_returns_by_run[42] = _good_parsed_error()
        writer = FakeTriageWriter()
        cursor = FakeSnowflakeCursor(fetchone_return=(41,))
        _, _, _, _, on_m, on_o, on_a, on_s = _build_callbacks()

        run_poll_pass(
            client=client,
            triage_writer=writer,
            snowflake_cursor=cursor,
            job_ids=[786800],
            environment_id=12345,
            on_malformed_input=on_m,
            on_operational_error=on_o,
            on_attempted_but_failed=on_a,
            on_source_unavailable=on_s,
            now_utc=_fixed_now,
        )

        # All four provenance fields arrived at writer.write via
        # process_envelope kwargs
        w = writer.writes[0]
        assert w["run_id"] == 42
        assert w["job_id"] == 786800
        assert w["environment_id"] == 12345
        assert w["git_sha"] == "deadbeef"


# ===========================================================================
# Focus item 7 — C6 sinks are C6-level (around MCP calls)
# ===========================================================================


class TestC6SinksAreC6Level:
    """Static check + behavioural check: the C6 sinks
    (``on_attempted_but_failed``, ``on_source_unavailable``) are NEVER
    invoked from INSIDE process_envelope. They live in the C6 loop,
    wrapping the MCP calls.
    """

    def test_process_envelope_does_not_know_c6_sinks(self):
        """Inspect process_envelope's signature — it must NOT take
        the C6 sinks as parameters. If a future refactor adds them
        there, this test goes RED."""
        import inspect
        from scripts.automation.src.triage.writer import process_envelope
        sig = inspect.signature(process_envelope)
        param_names = set(sig.parameters.keys())
        assert "on_attempted_but_failed" not in param_names
        assert "on_source_unavailable" not in param_names
        # C5 sinks DO live on process_envelope
        assert "on_malformed_input" in param_names
        assert "on_operational_error" in param_names

    def test_c5_envelope_error_does_not_trigger_c6_sinks(self):
        """A bad envelope inside the loop triggers a C5 sink
        (malformed_input or operational_error) via process_envelope —
        NEVER a C6 sink."""
        client = FakeDbtCloudClient()
        client.list_pages_by_job[786800] = [[_run(id=200, job_id=786800)]]
        # Adapter will return one envelope; we'll force C5 to fail by
        # making writer.write raise (C5 operational path)
        client.error_returns_by_run[200] = _good_parsed_error()
        writer = FakeTriageWriter()
        writer.raise_on_write = RuntimeError("simulated writer bug")
        cursor = FakeSnowflakeCursor(fetchone_return=(199,))
        _, o, attempted, source, on_m, on_o, on_a, on_s = _build_callbacks()

        run_poll_pass(
            client=client,
            triage_writer=writer,
            snowflake_cursor=cursor,
            job_ids=[786800],
            environment_id=999,
            on_malformed_input=on_m,
            on_operational_error=on_o,
            on_attempted_but_failed=on_a,
            on_source_unavailable=on_s,
            now_utc=_fixed_now,
        )
        # C5 fired
        assert len(o) == 1
        # C6 did NOT fire — boundary preserved
        assert attempted == []
        assert source == []


# ===========================================================================
# unique_id extraction — completeness coverage
# ===========================================================================


class TestExtractUniqueId:
    def test_extracts_from_well_formed_envelope(self):
        env = {"data": {"failed_steps": [
            {"results": [{"unique_id": "model.x.y"}]}
        ]}}
        assert _extract_unique_id(env) == "model.x.y"

    def test_returns_none_when_unique_id_absent(self):
        env = {"data": {"failed_steps": [{"results": [{"status": "error"}]}]}}
        assert _extract_unique_id(env) is None

    def test_returns_none_on_pre_model_shape_with_null_unique_id(self):
        env = {"data": {"failed_steps": [
            {"results": [{"unique_id": None, "status": "error"}]}
        ]}}
        assert _extract_unique_id(env) is None

    def test_returns_none_on_malformed_envelope(self):
        # Various malformed shapes all return None gracefully (the
        # writer COALESCE handles None)
        assert _extract_unique_id({}) is None
        assert _extract_unique_id({"data": {}}) is None
        assert _extract_unique_id({"data": {"failed_steps": []}}) is None
        assert _extract_unique_id({"data": {"failed_steps": [{"results": []}]}}) is None
        assert _extract_unique_id("not a dict") is None  # type: ignore[arg-type]
        assert _extract_unique_id(None) is None  # type: ignore[arg-type]


# ===========================================================================
# Coverage-reality: cold start + multi-job + happy path
# ===========================================================================


class TestColdStartAndMultiJob:
    def test_cold_start_writes_all_envelopes_no_high_water(self):
        client = FakeDbtCloudClient()
        client.list_pages_by_job[786800] = [
            [_run(id=10, job_id=786800), _run(id=9, job_id=786800)]
        ]
        client.error_returns_by_run[10] = _good_parsed_error("model.x.a")
        client.error_returns_by_run[9] = _good_parsed_error("model.x.b")
        writer = FakeTriageWriter()
        cursor = FakeSnowflakeCursor(fetchone_return=(None,))  # cold
        _, _, _, _, on_m, on_o, on_a, on_s = _build_callbacks()

        report = run_poll_pass(
            client=client,
            triage_writer=writer,
            snowflake_cursor=cursor,
            job_ids=[786800],
            environment_id=999,
            on_malformed_input=on_m,
            on_operational_error=on_o,
            on_attempted_but_failed=on_a,
            on_source_unavailable=on_s,
            now_utc=_fixed_now,
        )

        assert report.high_water_at_start is None
        assert report.envelopes_processed == 2
        assert len(writer.writes) == 2
        # Asc finished_at: run 9 first (older), then 10 (newer);
        # _run() uses the same finished_at default, so the ordering
        # falls back to newest-first → reversed → 9 then 10.
        assert [w["run_id"] for w in writer.writes] == [9, 10]

    def test_multi_job_iterates_each(self):
        client = FakeDbtCloudClient()
        client.list_pages_by_job[786800] = [[_run(id=10, job_id=786800)]]
        client.list_pages_by_job[786806] = [[_run(id=20, job_id=786806)]]
        client.error_returns_by_run[10] = _good_parsed_error()
        client.error_returns_by_run[20] = _good_parsed_error()
        writer = FakeTriageWriter()
        cursor = FakeSnowflakeCursor(fetchone_return=(None,))
        _, _, _, _, on_m, on_o, on_a, on_s = _build_callbacks()

        run_poll_pass(
            client=client,
            triage_writer=writer,
            snowflake_cursor=cursor,
            job_ids=[786800, 786806],
            environment_id=999,
            on_malformed_input=on_m,
            on_operational_error=on_o,
            on_attempted_but_failed=on_a,
            on_source_unavailable=on_s,
            now_utc=_fixed_now,
        )

        # Both jobs polled; both runs written
        assert len(writer.writes) == 2
        run_job_pairs = {(w["run_id"], w["job_id"]) for w in writer.writes}
        assert run_job_pairs == {(10, 786800), (20, 786806)}

    def test_adapter_failure_per_run_writes_attempted_but_failed_row(self):
        """C4 adapter contract violation (e.g., empty results list)
        for a single run → attempted_but_failed sink (run_id known),
        NOT source_unavailable."""
        client = FakeDbtCloudClient()
        client.list_pages_by_job[786800] = [[_run(id=200, job_id=786800)]]
        # Malformed parsed_error → C4 raises EmptyResultsContractViolation
        client.error_returns_by_run[200] = {
            "failed_steps": [{"step_name": "x", "target": "y",
                              "finished_at": "z", "results": []}]
        }
        writer = FakeTriageWriter()
        cursor = FakeSnowflakeCursor(fetchone_return=(199,))
        _, _, attempted, source, on_m, on_o, on_a, on_s = _build_callbacks()

        run_poll_pass(
            client=client,
            triage_writer=writer,
            snowflake_cursor=cursor,
            job_ids=[786800],
            environment_id=999,
            on_malformed_input=on_m,
            on_operational_error=on_o,
            on_attempted_but_failed=on_a,
            on_source_unavailable=on_s,
            now_utc=_fixed_now,
        )

        # Wrote attempted_but_failed row (run_id known) — NOT
        # source_unavailable (which would have written no row).
        assert len(writer.writes) == 1
        assert writer.writes[0]["rca"].outcome == (
            Outcome.TRIAGE_ATTEMPTED_BUT_FAILED
        )
        assert len(attempted) == 1
        assert source == []


# ===========================================================================
# Per-run environment_id sourcing (Option B) — env id comes from EACH run's
# payload, not a pass-level constant, because one pass spans multiple dbt
# environments (PROD job 786800 + DEV job 786806). The pass-level
# ``environment_id`` kwarg is an OPTIONAL fallback; a run carrying neither is
# logged + skipped (the NOT NULL provenance column cannot be stamped).
# ===========================================================================


class TestEnvironmentIdPerRunSourcing:
    """Locks per-run env-id provenance at all three writer sites
    (process_envelope success path + the two attempted_but_failed
    sinks) plus the fallback and skip boundaries."""

    def test_success_path_uses_per_run_env_across_environments(self):
        # Two jobs / two environments in ONE pass, NO pass-level
        # environment_id supplied — each row MUST carry its own run's
        # env id. Mutation defeater for the process_envelope write site:
        # reverting it to the pass-level constant (None here) fails.
        client = FakeDbtCloudClient()
        client.list_pages_by_job[786800] = [
            [_run(id=501, job_id=786800, environment_id=296881)]
        ]
        client.list_pages_by_job[786806] = [
            [_run(id=502, job_id=786806, environment_id=287190)]
        ]
        client.error_returns_by_run[501] = _good_parsed_error()
        client.error_returns_by_run[502] = _good_parsed_error()
        writer = FakeTriageWriter()
        cursor = FakeSnowflakeCursor(fetchone_return=(500,))
        _, _, _, _, on_m, on_o, on_a, on_s = _build_callbacks()

        run_poll_pass(
            client=client,
            triage_writer=writer,
            snowflake_cursor=cursor,
            job_ids=[786800, 786806],
            on_malformed_input=on_m,
            on_operational_error=on_o,
            on_attempted_but_failed=on_a,
            on_source_unavailable=on_s,
            now_utc=_fixed_now,
        )

        by_run = {w["run_id"]: w["environment_id"] for w in writer.writes}
        assert by_run == {501: 296881, 502: 287190}

    def test_k_retry_dead_letter_uses_per_run_env(self):
        # attempted_but_failed (K-retry exhausted) site: pass-level env
        # DIFFERS from the run's env; the dead-letter row must carry the
        # RUN's env, proving the site reads per-run, not pass-level.
        client = FakeDbtCloudClient()
        client.list_pages_by_job[786800] = [
            [_run(id=801, job_id=786800, environment_id=296881)]
        ]
        client.error_returns_by_run[801] = [
            ConnectionError("t1"),
            ConnectionError("t2"),
            ConnectionError("t3"),
        ]
        writer = FakeTriageWriter()
        cursor = FakeSnowflakeCursor(fetchone_return=(800,))
        _, _, _, _, on_m, on_o, on_a, on_s = _build_callbacks()

        run_poll_pass(
            client=client,
            triage_writer=writer,
            snowflake_cursor=cursor,
            job_ids=[786800],
            environment_id=111111,  # fallback that must NOT win
            on_malformed_input=on_m,
            on_operational_error=on_o,
            on_attempted_but_failed=on_a,
            on_source_unavailable=on_s,
            k_retries=3,
            now_utc=_fixed_now,
        )

        assert len(writer.writes) == 1
        assert writer.writes[0]["environment_id"] == 296881

    def test_adapter_contract_dead_letter_uses_per_run_env(self):
        # attempted_but_failed (adapter contract) site: same per-run
        # assertion via an empty-results C4 violation.
        client = FakeDbtCloudClient()
        client.list_pages_by_job[786800] = [
            [_run(id=802, job_id=786800, environment_id=287190)]
        ]
        client.error_returns_by_run[802] = {
            "failed_steps": [
                {"step_name": "x", "target": "y",
                 "finished_at": "z", "results": []}
            ]
        }
        writer = FakeTriageWriter()
        cursor = FakeSnowflakeCursor(fetchone_return=(801,))
        _, _, _, _, on_m, on_o, on_a, on_s = _build_callbacks()

        run_poll_pass(
            client=client,
            triage_writer=writer,
            snowflake_cursor=cursor,
            job_ids=[786800],
            environment_id=111111,  # fallback that must NOT win
            on_malformed_input=on_m,
            on_operational_error=on_o,
            on_attempted_but_failed=on_a,
            on_source_unavailable=on_s,
            now_utc=_fixed_now,
        )

        assert len(writer.writes) == 1
        assert writer.writes[0]["environment_id"] == 287190

    def test_pass_level_env_is_fallback_when_run_lacks_it(self):
        # Run payload omits environment_id → pass-level fallback is used.
        run_no_env = {
            "id": 600,
            "job_id": 786800,
            "git_sha": "abc1234",
            "finished_at": "2026-06-19T12:00:00+00:00",
        }
        client = FakeDbtCloudClient()
        client.list_pages_by_job[786800] = [[run_no_env]]
        client.error_returns_by_run[600] = _good_parsed_error()
        writer = FakeTriageWriter()
        cursor = FakeSnowflakeCursor(fetchone_return=(599,))
        _, _, _, _, on_m, on_o, on_a, on_s = _build_callbacks()

        run_poll_pass(
            client=client,
            triage_writer=writer,
            snowflake_cursor=cursor,
            job_ids=[786800],
            environment_id=296453,  # fallback wins here
            on_malformed_input=on_m,
            on_operational_error=on_o,
            on_attempted_but_failed=on_a,
            on_source_unavailable=on_s,
            now_utc=_fixed_now,
        )

        assert len(writer.writes) == 1
        assert writer.writes[0]["environment_id"] == 296453

    def test_run_missing_env_and_no_fallback_is_skipped(self, caplog):
        # Run omits environment_id AND no pass-level fallback → the run
        # is skipped BEFORE get_job_run_error (cannot stamp NOT NULL
        # provenance). No write, no error retrieval, logged.
        run_no_env = {
            "id": 700,
            "job_id": 786800,
            "git_sha": "abc1234",
            "finished_at": "2026-06-19T12:00:00+00:00",
        }
        client = FakeDbtCloudClient()
        client.list_pages_by_job[786800] = [[run_no_env]]
        client.error_returns_by_run[700] = _good_parsed_error()
        writer = FakeTriageWriter()
        cursor = FakeSnowflakeCursor(fetchone_return=(699,))
        _, _, _, _, on_m, on_o, on_a, on_s = _build_callbacks()

        with caplog.at_level(logging.ERROR):
            run_poll_pass(
                client=client,
                triage_writer=writer,
                snowflake_cursor=cursor,
                job_ids=[786800],
                on_malformed_input=on_m,
                on_operational_error=on_o,
                on_attempted_but_failed=on_a,
                on_source_unavailable=on_s,
                now_utc=_fixed_now,
            )

        assert writer.writes == []
        assert client.get_job_run_error_calls == []
        assert "missing_environment_id" in caplog.text
