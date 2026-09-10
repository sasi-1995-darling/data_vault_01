"""Tests for ``scripts.automation.src.triage.notifier`` — Component 7.

Covers all six byte-review focus items + Mutations A-D defeaters
(Mutation E pertains to the cron YAML, asserted in
TestCronYamlConcurrencyGuard at the bottom of this file):

  1. Issue grain is ONE per RUN aggregating N results (not N issues
     per result); self-ID line present verbatim.
     → TestOneIssuePerRunAggregating (Mutation C defeater)
     → TestSelfIdLinePresent (Mutation D defeater)

  2. H9 dedup — THE HARDEST READ:
     a. uses GH LIST-issues endpoint (NOT search) with since=now-7d
     b. stable + exact-matchable run_id=<id> marker (regex word-
        boundaries prevent run_id=12 matching run_id=123)
     c. on-match comments/updates, does NOT create second
     d. **the test that DEFEATS the wrong design**: index-lag
        scenario where the list-endpoint sees the just-created issue
        (canonical store has it) but search would return empty
        (index hasn't caught up). The correct (list) impl comments;
        the mutant (search) impl creates a duplicate. The test passes
        on list-path, FAILS on search-path. Mutation A pins this.
     → TestDedupUsesListEndpointNotSearch
     → TestDedupMarkerIsExactMatchable
     → TestDedupOnMatchCommentsNotCreates
     → TestDedupUnderSearchIndexLag (Mutation A defeater — THE CRITICAL TEST)
     → TestDedupHonorsSevenDayWindow (Mutation B defeater)

  3. §8 honesty: UNKNOWN as evidence-captured-for-human, no coverage
     metric without denominator; templating doesn't overclaim.
     → TestUnknownRenderedAsEvidence
     → TestNoCoverageMetricInBody

  4. Cron YAML: Q3-locked cadence + existing secret mechanism + ships
     PR-jobs-first (Phase-1.5 scheduled commented as documented
     follow-on).
     → TestCronYamlQ3Cadence
     → TestCronYamlUsesExistingSecrets

  5. Serial-cron concurrency: YAML concurrency: group present with
     cancel-in-progress: false (queue/skip, NOT race the cursor).
     → TestCronYamlConcurrencyGuard (Mutation E defeater)

  6. Absorbed C6 deferred findings:
     a. now_utc() aware-requirement documented at cron-wiring site
     b. concurrency assumption documented in YAML / cron entrypoint
     c. happy-path INFO log emitted by cron entrypoint per pass
     → TestCronEntrypointDocumentsNowUtcAwareness
     → TestCronEntrypointDocumentsConcurrency
     → TestCronEntrypointHappyPathInfoLog

Mutation defeats are documented in each test class's docstring —
each defeat names the mutation, the line(s) to mutate, and the
expected RED behaviour. The mutation battery runs externally via
``/tmp/run_c7_mutations.sh`` (mirrors the C5/C6 pattern).
"""

from __future__ import annotations

import inspect
import re
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Optional

import pytest
import yaml

from scripts.automation.src.triage.notifier import (
    GitHubIssuesClient,
    ResultDetail,
    RunNotificationPayload,
    SELF_ID_LINE,
    _build_body,
    _build_title,
    _marker,
    _marker_pattern,
    _PER_RUN_QUERY_SQL,
    assemble_run_payloads,
    notify_pass,
    notify_run,
)


# ---------------------------------------------------------------------------
# Test doubles
# ---------------------------------------------------------------------------


class FakeGitHubIssuesClient:
    """Scriptable GH client.

    Exposes BOTH ``list_issues`` and ``search_issues`` so that
    Mutation A (swap list→search in the dedup path) can be tested
    against an index-lag fixture: ``list_pages`` reflects the
    canonical store state, ``search_pages`` reflects the (lagging)
    search index. The production code only calls ``list_issues``;
    the FAKE having both methods lets a mutation swap the call site
    and observe the divergent behaviour.

    Per-page scripted returns: ``list_pages`` is a list-of-pages,
    consumed in call order (page 1, 2, ...). Empty list means GH
    returned nothing (cold or fully-scanned).
    """

    def __init__(self) -> None:
        # H9 production path — list-issues endpoint, the canonical store.
        self.list_pages: list[list[dict]] = []
        # Mutation A path — search endpoint, would-be lagged.
        self.search_pages: list[list[dict]] = []
        self.create_returns: dict = {"number": 999}
        self.comment_returns: dict = {"id": 12345}

        self.list_issues_calls: list[dict] = []
        self.search_issues_calls: list[dict] = []
        self.create_issue_calls: list[dict] = []
        self.add_comment_calls: list[dict] = []

        self._list_page_cursor = 0
        self._search_page_cursor = 0

        # Optional: raise on the next call (simulate transport error
        # for per-run isolation tests).
        self.raise_on_list: Optional[BaseException] = None
        self.raise_on_create: Optional[BaseException] = None
        self.raise_on_comment: Optional[BaseException] = None

    # ------ Production path ------
    def list_issues(
        self,
        *,
        owner: str,
        repo: str,
        since: str,
        state: str,
        per_page: int,
        page: int,
    ) -> list[dict]:
        self.list_issues_calls.append({
            "owner": owner, "repo": repo, "since": since,
            "state": state, "per_page": per_page, "page": page,
        })
        if self.raise_on_list is not None:
            raise self.raise_on_list
        idx = self._list_page_cursor
        if idx >= len(self.list_pages):
            return []
        self._list_page_cursor = idx + 1
        return self.list_pages[idx]

    # ------ Mutation-A path (would-be-swapped) ------
    def search_issues(
        self,
        *,
        owner: str,
        repo: str,
        query: str,
    ) -> list[dict]:
        self.search_issues_calls.append({
            "owner": owner, "repo": repo, "query": query,
        })
        idx = self._search_page_cursor
        if idx >= len(self.search_pages):
            return []
        self._search_page_cursor = idx + 1
        return self.search_pages[idx]

    # ------ Side-effect writes ------
    def create_issue(
        self,
        *,
        owner: str,
        repo: str,
        title: str,
        body: str,
        labels: list[str],
    ) -> dict:
        self.create_issue_calls.append({
            "owner": owner, "repo": repo, "title": title,
            "body": body, "labels": list(labels),
        })
        if self.raise_on_create is not None:
            raise self.raise_on_create
        return dict(self.create_returns)

    def add_comment(
        self,
        *,
        owner: str,
        repo: str,
        issue_number: int,
        body: str,
    ) -> dict:
        self.add_comment_calls.append({
            "owner": owner, "repo": repo,
            "issue_number": issue_number, "body": body,
        })
        if self.raise_on_comment is not None:
            raise self.raise_on_comment
        return dict(self.comment_returns)


class FakeSnowflakeCursor:
    """Captures execute() + scripts fetchall() return values."""

    def __init__(self, fetchall_return: Optional[list[tuple]] = None):
        self.executions: list[tuple[str, dict]] = []
        self._fetchall_return = fetchall_return or []

    def execute(self, sql: str, params: Any = None) -> None:
        self.executions.append((sql, dict(params) if params else {}))

    def fetchall(self) -> list[tuple]:
        return list(self._fetchall_return)

    @property
    def last_sql(self) -> str:
        return self.executions[-1][0]

    @property
    def last_params(self) -> dict:
        return self.executions[-1][1]


# ---------------------------------------------------------------------------
# Helpers / factories
# ---------------------------------------------------------------------------


def _result(
    *,
    unique_id: Optional[str] = "model.x.dim_customer",
    classification: str = "compile_error",
    evidence_mode: str = "artifact_projection",
    rationale: Optional[str] = "select 1/0 in compiled_code",
    outcome: str = "classified",
) -> ResultDetail:
    return ResultDetail(
        unique_id=unique_id,
        classification=classification,
        evidence_mode=evidence_mode,
        rationale=rationale,
        outcome=outcome,
    )


def _payload(
    *,
    run_id: int = 12345,
    job_id: int = 786800,
    results: Optional[list[ResultDetail]] = None,
) -> RunNotificationPayload:
    return RunNotificationPayload(
        run_id=run_id,
        job_id=job_id,
        results=tuple(results if results is not None else [_result()]),
    )


def _existing_issue(
    *,
    number: int,
    run_id: int,
    state: str = "open",
    extra_title: str = "1 failed result",
) -> dict:
    """Build an issue dict matching the canonical store shape."""
    return {
        "number": number,
        "title": f"[Triage] dbt-Cloud run_id={run_id} \u2014 {extra_title}",
        "state": state,
    }


def _fixed_now(year: int = 2026, month: int = 6, day: int = 19) -> datetime:
    return datetime(year, month, day, 12, 0, 0, tzinfo=timezone.utc)


# ===========================================================================
# Focus item 1 — One issue per run; self-ID line
# ===========================================================================


class TestOneIssuePerRunAggregating:
    """Mutation C: notifier creates N issues per run instead of 1
    aggregating. Mutation target: change ``notify_run`` to iterate
    over results and call ``create_issue`` per result. With a
    3-result payload, the test asserts EXACTLY ONE create call;
    mutation produces 3 → test RED.
    """

    def test_three_results_produce_exactly_one_create_call(self):
        client = FakeGitHubIssuesClient()
        payload = _payload(
            run_id=42,
            results=[
                _result(unique_id="model.a"),
                _result(unique_id="model.b"),
                _result(unique_id="model.c"),
            ],
        )
        result = notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=payload,
            now_utc=_fixed_now,
        )
        assert result.action == "created"
        assert len(client.create_issue_calls) == 1, (
            f"expected exactly 1 create_issue call (one per RUN), "
            f"got {len(client.create_issue_calls)} "
            f"(Mutation C: per-result grain breaks the human-attention "
            f"grain — would create one issue per failed model)"
        )

    def test_three_results_all_appear_in_single_body(self):
        # The single body contains all three unique_ids.
        client = FakeGitHubIssuesClient()
        payload = _payload(
            run_id=42,
            results=[
                _result(unique_id="model.a"),
                _result(unique_id="model.b"),
                _result(unique_id="model.c"),
            ],
        )
        notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=payload,
            now_utc=_fixed_now,
        )
        body = client.create_issue_calls[0]["body"]
        assert "model.a" in body
        assert "model.b" in body
        assert "model.c" in body

    def test_title_mentions_result_count(self):
        client = FakeGitHubIssuesClient()
        payload = _payload(
            run_id=42,
            results=[_result(unique_id=f"model.{i}") for i in range(5)],
        )
        notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=payload,
            now_utc=_fixed_now,
        )
        title = client.create_issue_calls[0]["title"]
        assert "5 failed result" in title

    def test_one_result_uses_singular(self):
        client = FakeGitHubIssuesClient()
        payload = _payload(run_id=42, results=[_result()])
        notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=payload,
            now_utc=_fixed_now,
        )
        title = client.create_issue_calls[0]["title"]
        # Singular form: "1 failed result" with NO trailing "s".
        assert "1 failed result" in title
        assert "1 failed results" not in title


class TestSelfIdLinePresent:
    """Mutation D: drop the self-ID line from the body. Mutation target:
    remove the SELF_ID_LINE append in ``_build_body``. The test asserts
    the verbatim string is present in BOTH the create body AND the
    comment body. Mutation removes it → test RED.
    """

    EXPECTED = "*Posted via DV Failure Triage Agent automation.*"

    def test_self_id_line_constant_is_verbatim(self):
        # Direct constant check — the directive specifies the line
        # verbatim. Any typo, reword, or capitalization change fails.
        assert SELF_ID_LINE == self.EXPECTED, (
            f"SELF_ID_LINE drifted from directive — got "
            f"{SELF_ID_LINE!r}, expected {self.EXPECTED!r}"
        )

    def test_self_id_line_in_created_body(self):
        client = FakeGitHubIssuesClient()
        notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=_payload(),
            now_utc=_fixed_now,
        )
        body = client.create_issue_calls[0]["body"]
        assert self.EXPECTED in body
        # Position check — must be at the bottom (last meaningful line)
        # so a reader scanning the foot of the issue sees it.
        assert body.rstrip().endswith(self.EXPECTED)

    def test_self_id_line_in_commented_body(self):
        # Dedup path → comment, not create — self-ID must still appear.
        client = FakeGitHubIssuesClient()
        client.list_pages = [[
            _existing_issue(number=77, run_id=12345),
        ]]
        result = notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=_payload(run_id=12345),
            now_utc=_fixed_now,
        )
        assert result.action == "commented"
        assert len(client.add_comment_calls) == 1
        body = client.add_comment_calls[0]["body"]
        assert self.EXPECTED in body
        assert body.rstrip().endswith(self.EXPECTED)


# ===========================================================================
# Focus item 2 — H9 list-endpoint dedup (THE HARDEST READ)
# ===========================================================================


class TestDedupUsesListEndpointNotSearch:
    """Pins that production code calls ``list_issues`` (NOT search) for
    dedup. The protocol surface itself omits a search method —
    asymmetry is intentional. The test verifies via call recording.
    """

    def test_dedup_calls_list_issues(self):
        client = FakeGitHubIssuesClient()
        notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=_payload(run_id=12345),
            now_utc=_fixed_now,
        )
        # At least one list_issues call must have been made for dedup.
        assert len(client.list_issues_calls) >= 1
        # NO search calls anywhere.
        assert client.search_issues_calls == []

    def test_protocol_surface_omits_search(self):
        # The GitHubIssuesClient Protocol exposes list_issues,
        # create_issue, add_comment — NOT a search method. The
        # asymmetry is the H9 contract encoded at the type surface.
        sig = inspect.getmembers(
            GitHubIssuesClient, predicate=inspect.isfunction
        )
        method_names = {name for name, _ in sig}
        assert "list_issues" in method_names
        assert "create_issue" in method_names
        assert "add_comment" in method_names
        assert not any("search" in name.lower() for name in method_names), (
            f"GitHubIssuesClient Protocol exposes a search method, but "
            f"H9 explicitly forbids using search for dedup. Method names: "
            f"{method_names}"
        )

    def test_list_issues_called_with_seven_day_since_window(self):
        client = FakeGitHubIssuesClient()
        now = _fixed_now(2026, 6, 19)
        notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=_payload(run_id=12345),
            now_utc=lambda: now,
        )
        since = client.list_issues_calls[0]["since"]
        # since = now - 7d = 2026-06-12T12:00:00Z
        expected = (now - timedelta(days=7)).strftime("%Y-%m-%dT%H:%M:%SZ")
        assert since == expected, (
            f"since must be now - 7d = {expected!r}, got {since!r}"
        )

    def test_list_issues_called_with_state_all(self):
        # state=all so closed issues count for dedup within the window.
        client = FakeGitHubIssuesClient()
        notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=_payload(),
            now_utc=_fixed_now,
        )
        assert client.list_issues_calls[0]["state"] == "all"


class TestDedupMarkerIsExactMatchable:
    """Directive: "stable + exact-matchable, not fuzzy."

    The marker ``run_id=<id>`` uses regex word boundaries on both
    sides so that ``run_id=12`` does NOT match ``run_id=123`` or
    ``run_id=12345``.
    """

    def test_exact_match_finds_same_id(self):
        pat = _marker_pattern(12345)
        assert pat.search("[Triage] dbt-Cloud run_id=12345 \u2014 1 failed result")

    def test_substring_does_NOT_match_different_id(self):
        # run_id=12 must NOT match against an issue for run_id=123.
        pat = _marker_pattern(12)
        title_for_run_123 = "[Triage] dbt-Cloud run_id=123 \u2014 1 failed result"
        assert pat.search(title_for_run_123) is None, (
            f"marker run_id=12 falsely matched title for run_id=123 "
            f"(fuzzy substring match would be a coverage bug — a future "
            f"run_id=12345 would false-positive on the run_id=12 issue)"
        )

    def test_prefix_does_NOT_match_longer_id(self):
        # Mirror case — run_id=12345 must NOT match issue for run_id=12.
        pat = _marker_pattern(12345)
        title_for_run_12 = "[Triage] dbt-Cloud run_id=12 \u2014 1 failed result"
        assert pat.search(title_for_run_12) is None

    def test_marker_string_format(self):
        assert _marker(12345) == "run_id=12345"

    def test_marker_appears_in_title(self):
        client = FakeGitHubIssuesClient()
        notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=_payload(run_id=12345),
            now_utc=_fixed_now,
        )
        title = client.create_issue_calls[0]["title"]
        assert "run_id=12345" in title


class TestDedupOnMatchCommentsNotCreates:
    """On-match behaviour: comment, do NOT create a second."""

    def test_existing_issue_triggers_comment_no_create(self):
        client = FakeGitHubIssuesClient()
        client.list_pages = [[
            _existing_issue(number=77, run_id=12345),
        ]]
        result = notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=_payload(run_id=12345),
            now_utc=_fixed_now,
        )
        assert result.action == "commented"
        assert result.issue_number == 77
        assert len(client.add_comment_calls) == 1
        assert len(client.create_issue_calls) == 0, (
            "On dedup match, a duplicate issue must NOT be created"
        )

    def test_no_match_creates_new_issue(self):
        # The list returns issues for OTHER runs but not this one.
        client = FakeGitHubIssuesClient()
        client.list_pages = [[
            _existing_issue(number=11, run_id=99999),  # different run
            _existing_issue(number=22, run_id=88888),  # different run
        ]]
        result = notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=_payload(run_id=12345),
            now_utc=_fixed_now,
        )
        assert result.action == "created"
        assert len(client.create_issue_calls) == 1
        assert len(client.add_comment_calls) == 0

    def test_closed_issue_within_window_still_dedups(self):
        # state=all means a previously-notified-then-closed issue
        # within the window still triggers comment, not duplicate.
        client = FakeGitHubIssuesClient()
        client.list_pages = [[
            _existing_issue(number=77, run_id=12345, state="closed"),
        ]]
        result = notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=_payload(run_id=12345),
            now_utc=_fixed_now,
        )
        assert result.action == "commented"
        assert result.issue_number == 77


class TestDedupUnderSearchIndexLag:
    """**THE CRITICAL TEST — Mutation A defeater.**

    Simulates the GH-search-index-lag scenario the H9 fix exists to
    defeat. The canonical issue store (list endpoint) has the
    just-created issue; the search index has NOT caught up (search
    returns empty for the marker).

    The CORRECT (list-endpoint) production impl finds the issue and
    comments — no duplicate created.

    The WRONG (search-endpoint) Mutation A impl sees search empty
    and creates a duplicate — this test fails on the mutation.

    This is the test that DEFEATS the wrong design, not merely
    "verifies dedup works on a fresh store" (which both correct and
    incorrect impls trivially pass — the fresh-store case doesn't
    distinguish them).
    """

    def test_list_finds_issue_that_search_misses(self):
        client = FakeGitHubIssuesClient()
        # Canonical store has the issue (just created in prior pass).
        client.list_pages = [[
            _existing_issue(number=77, run_id=12345),
        ]]
        # Search index hasn't caught up — returns empty.
        client.search_pages = [[]]

        result = notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=_payload(run_id=12345),
            now_utc=_fixed_now,
        )

        # CORRECT impl: list_issues sees it → comment → no duplicate.
        assert result.action == "commented", (
            f"Index-lag scenario: list-endpoint sees the existing issue "
            f"(canonical store), but the action was {result.action!r} — "
            f"this is the Mutation-A failure mode (using search instead "
            f"of list would see empty and create a duplicate)"
        )
        assert result.issue_number == 77
        assert len(client.create_issue_calls) == 0, (
            "Under search-index lag, a list-endpoint impl must NOT "
            "create a duplicate. If create_issue was called, dedup is "
            "using search-path semantics (Mutation A — RED)"
        )
        # Production code must have called list_issues exactly to dedup.
        assert len(client.list_issues_calls) >= 1
        # Production code must NOT have called search_issues.
        assert client.search_issues_calls == []

    def test_mutation_A_simulation_would_create_duplicate(self):
        """Demonstrates the test fixture sets up the distinguishing
        case correctly: search returns empty AND list returns the
        issue. A search-path impl would see empty → create dup; the
        list-path impl sees the issue → comment.
        """
        client = FakeGitHubIssuesClient()
        client.list_pages = [[
            _existing_issue(number=77, run_id=12345),
        ]]
        client.search_pages = [[]]

        # Verify search returns empty (the lag scenario).
        lag_dedup_result = client.search_issues(
            owner="org", repo="repo", query="run_id=12345"
        )
        assert lag_dedup_result == [], (
            "Test fixture is mis-configured — search must return empty "
            "to simulate index lag. If search returns the issue too, "
            "this test no longer distinguishes the search-path bug."
        )
        # And the list path returns it (canonical store has it).
        list_dedup_result = client.list_issues(
            owner="org", repo="repo",
            since="2026-06-12T12:00:00Z",
            state="all", per_page=100, page=1,
        )
        assert len(list_dedup_result) == 1
        assert "run_id=12345" in list_dedup_result[0]["title"]


class TestDedupHonorsSevenDayWindow:
    """Mutation B: drop or narrow ``since=now-7d`` window. With a
    narrow window (e.g., now-1min), an issue updated 25 minutes ago
    (same-cron-cadence) would not appear in list_issues → duplicate.

    The mutation target is the ``timedelta(days=dedup_window_days)``
    arithmetic in ``_find_existing_issue``. Test pattern: verify the
    ``since`` param is computed from ``dedup_window_days`` and
    defaults to 7d.
    """

    def test_default_window_is_seven_days(self):
        # The default is 7 days, matching the directive's lock.
        client = FakeGitHubIssuesClient()
        now = _fixed_now()
        notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=_payload(),
            now_utc=lambda: now,
        )
        since_iso = client.list_issues_calls[0]["since"]
        parsed = datetime.strptime(since_iso, "%Y-%m-%dT%H:%M:%SZ")
        parsed = parsed.replace(tzinfo=timezone.utc)
        delta = now - parsed
        assert delta == timedelta(days=7), (
            f"default window must be exactly 7 days, got {delta}"
        )

    def test_zero_day_window_omits_old_issues(self):
        # With dedup_window_days=0, since == now (same instant) —
        # the REAL API would omit any issue updated even 1ms ago.
        client = FakeGitHubIssuesClient()
        now = _fixed_now()
        notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=_payload(),
            now_utc=lambda: now,
            dedup_window_days=0,
        )
        since_iso = client.list_issues_calls[0]["since"]
        assert since_iso == now.strftime("%Y-%m-%dT%H:%M:%SZ")

    def test_narrow_window_drops_older_same_run_issue(self):
        """Mutation B simulation: with a narrow window, a same-run
        issue updated outside the window wouldn't be returned by
        the real GH API → duplicate created.

        We verify the since= param is computed from dedup_window_days
        — which IS what determines what the real API returns. The
        Mutation-B failure mode is: if dedup_window_days were
        hardcoded to 0 / 1-minute / etc., the API would omit the
        25-minutes-ago issue and the notifier would create a dup.
        """
        client = FakeGitHubIssuesClient()
        now = _fixed_now()
        notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=_payload(),
            now_utc=lambda: now,
            dedup_window_days=7,
        )
        since_iso = client.list_issues_calls[0]["since"]
        parsed = datetime.strptime(since_iso, "%Y-%m-%dT%H:%M:%SZ").replace(
            tzinfo=timezone.utc
        )
        # since must be MUCH older than typical cron cadence (5/30 min) —
        # otherwise the dedup window is narrower than the gap between
        # issue creation and the next pass, and crashes-between-create-
        # and-cursor-write would re-dup.
        gap = now - parsed
        assert gap >= timedelta(hours=1), (
            f"since-window ({gap}) narrower than 1h is too narrow to "
            f"cover cron cadence + retry latency — Mutation B failure mode"
        )


class TestDedupPaginatesListEndpoint:
    """The dedup scan must paginate the list endpoint up to the cap;
    a match on page 2+ is still a match."""

    def test_match_on_second_page_is_found(self):
        client = FakeGitHubIssuesClient()
        # Page 1: full page of 100 unrelated issues.
        client.list_pages = [
            [_existing_issue(number=i, run_id=99999 + i) for i in range(100)],
            # Page 2: the matching issue.
            [_existing_issue(number=200, run_id=12345)],
        ]
        result = notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=_payload(run_id=12345),
            now_utc=_fixed_now,
        )
        assert result.action == "commented"
        assert result.issue_number == 200
        # Both pages were fetched.
        assert len(client.list_issues_calls) == 2

    def test_partial_page_terminates_scan(self):
        # A partial page (< per_page) means no more pages.
        client = FakeGitHubIssuesClient()
        client.list_pages = [
            [_existing_issue(number=i, run_id=99999 + i) for i in range(50)],
        ]
        notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=_payload(run_id=12345),
            now_utc=_fixed_now,
        )
        # Only one list call — partial page terminated the scan early.
        assert len(client.list_issues_calls) == 1


# ===========================================================================
# Focus item 3 — §8 honesty in body templating
# ===========================================================================


class TestUnknownRenderedAsEvidence:
    """§8 honesty: UNKNOWN classifications render as
    "evidence captured for human review", NOT as "triage failed."
    """

    def test_unknown_classification_uses_evidence_language(self):
        payload = _payload(
            run_id=42,
            results=[
                _result(
                    unique_id="model.x",
                    classification="unknown",
                    evidence_mode="undetected",
                    rationale="no detectable evidence shape",
                ),
            ],
        )
        body = _build_body(payload)
        assert "evidence captured for human review" in body, (
            f"UNKNOWN must render as evidence-captured-for-human "
            f"(§8 honesty). Body: {body!r}"
        )

    def test_unknown_does_NOT_use_failure_language(self):
        payload = _payload(
            run_id=42,
            results=[
                _result(
                    unique_id="model.x",
                    classification="unknown",
                    evidence_mode="undetected",
                    rationale="no detectable evidence shape",
                ),
            ],
        )
        body = _build_body(payload).lower()
        # Forbidden phrases — would overclaim that UNKNOWN is a triage
        # failure rather than honest evidence capture.
        forbidden = [
            "triage failed",
            "could not triage",
            "triage unsuccessful",
            "classification failed",
        ]
        for phrase in forbidden:
            assert phrase not in body, (
                f"§8 honesty violation: body uses failure language "
                f"{phrase!r} for UNKNOWN result. Body: {body!r}"
            )

    def test_classified_result_uses_classification_value(self):
        payload = _payload(
            run_id=42,
            results=[
                _result(
                    unique_id="model.x",
                    classification="compile_error",
                    evidence_mode="artifact_projection",
                ),
            ],
        )
        body = _build_body(payload)
        # Classified result shows the classification value verbatim.
        assert "compile_error" in body


class TestNoCoverageMetricInBody:
    """§8 honesty: NO coverage metric (e.g., "we classified 7/10")
    appears in the body. Stating coverage without the incoming-failure
    denominator is the exact §8 violation guarded against.
    """

    def test_body_omits_percentage_coverage(self):
        payload = _payload(
            run_id=42,
            results=[
                _result(classification="compile_error"),
                _result(classification="unknown"),
                _result(classification="dependency_error"),
            ],
        )
        body = _build_body(payload).lower()
        # Forbidden coverage-claim patterns.
        coverage_patterns = [
            r"coverage",
            r"\d+\s*%\s*classified",
            r"\d+\s*/\s*\d+\s*classified",
            r"classification\s+rate",
        ]
        for pattern in coverage_patterns:
            assert not re.search(pattern, body), (
                f"§8 violation: body contains coverage claim matching "
                f"{pattern!r}. Body: {body!r}"
            )

    def test_body_states_only_count_with_denominator_context(self):
        # The "N failed results" header IS a count, but it's the
        # numerator only with explicit "failed result(s)" context —
        # not a coverage claim. This test pins that the header doesn't
        # drift into coverage language.
        payload = _payload(
            run_id=42,
            results=[_result() for _ in range(3)],
        )
        body = _build_body(payload)
        # The count appears as "3 failed result" — not "3/X" or "X%".
        assert "3 failed result" in body
        # No slash-style ratio appears.
        assert not re.search(r"3\s*/\s*\d+", body)


# ===========================================================================
# notify_run smoke + boundary
# ===========================================================================


class TestNotifyRunBoundary:
    def test_empty_results_returns_skipped(self):
        client = FakeGitHubIssuesClient()
        result = notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=RunNotificationPayload(
                run_id=42, job_id=786800, results=tuple()
            ),
            now_utc=_fixed_now,
        )
        assert result.action == "skipped_empty"
        assert client.create_issue_calls == []
        assert client.list_issues_calls == []

    def test_non_int_run_id_raises_typeerror(self):
        client = FakeGitHubIssuesClient()
        with pytest.raises(TypeError, match="run_id"):
            notify_run(
                github_client=client,
                owner="org",
                repo="repo",
                payload=RunNotificationPayload(
                    run_id="not-an-int",  # type: ignore[arg-type]
                    job_id=786800,
                    results=(_result(),),
                ),
                now_utc=_fixed_now,
            )

    def test_default_labels_include_triage_and_automation(self):
        client = FakeGitHubIssuesClient()
        notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=_payload(),
            now_utc=_fixed_now,
        )
        labels = client.create_issue_calls[0]["labels"]
        assert "triage" in labels
        assert "automation" in labels

    def test_custom_labels_override(self):
        client = FakeGitHubIssuesClient()
        notify_run(
            github_client=client,
            owner="org",
            repo="repo",
            payload=_payload(),
            now_utc=_fixed_now,
            labels=["custom-label"],
        )
        labels = client.create_issue_calls[0]["labels"]
        assert labels == ["custom-label"]


# ===========================================================================
# assemble_run_payloads — bridge from PollPassReport to notifier
# ===========================================================================


class TestAssembleRunPayloads:
    def test_empty_run_ids_returns_empty(self):
        cursor = FakeSnowflakeCursor()
        payloads = assemble_run_payloads(cursor, run_ids=[])
        assert payloads == []
        # No SQL executed.
        assert cursor.executions == []

    def test_non_int_run_id_raises_typeerror(self):
        cursor = FakeSnowflakeCursor()
        with pytest.raises(TypeError, match="run_ids must all be int"):
            assemble_run_payloads(
                cursor, run_ids=[12345, "not-int"],  # type: ignore[list-item]
            )

    def test_sql_uses_in_filter_with_pyformat_binds(self):
        cursor = FakeSnowflakeCursor(fetchall_return=[])
        assemble_run_payloads(cursor, run_ids=[111, 222, 333])
        assert "WHERE run_id IN" in _PER_RUN_QUERY_SQL
        assert "WHERE run_id IN" in cursor.last_sql
        assert cursor.last_params == {
            "run_id_0": 111, "run_id_1": 222, "run_id_2": 333,
        }

    def test_groups_rows_by_run_id(self):
        cursor = FakeSnowflakeCursor(fetchall_return=[
            (111, 786800, "model.a", "compile_error", "artifact_projection",
             "classified", "rationale-a"),
            (111, 786800, "model.b", "unknown", "undetected",
             "unknown_handed_to_human", "rationale-b"),
            (222, 786800, "model.c", "dependency_error", "early_failure",
             "classified", "rationale-c"),
        ])
        payloads = assemble_run_payloads(cursor, run_ids=[111, 222])
        assert len(payloads) == 2
        assert payloads[0].run_id == 111
        assert len(payloads[0].results) == 2
        assert payloads[1].run_id == 222
        assert len(payloads[1].results) == 1

    def test_missing_run_id_silently_omitted(self):
        # A run_id with no rows is omitted from output — not an error.
        cursor = FakeSnowflakeCursor(fetchall_return=[
            (111, 786800, "model.a", "compile_error", "artifact_projection",
             "classified", "rationale-a"),
        ])
        payloads = assemble_run_payloads(cursor, run_ids=[111, 999])
        assert len(payloads) == 1
        assert payloads[0].run_id == 111

    def test_preserves_input_ordering(self):
        cursor = FakeSnowflakeCursor(fetchall_return=[
            (222, 786800, "model.b", "compile_error", "artifact_projection",
             "classified", "rb"),
            (111, 786800, "model.a", "compile_error", "artifact_projection",
             "classified", "ra"),
        ])
        # Input order: 111, 222 — output must match.
        payloads = assemble_run_payloads(cursor, run_ids=[111, 222])
        assert [p.run_id for p in payloads] == [111, 222]


# ===========================================================================
# notify_pass — convenience wrapper + per-run isolation
# ===========================================================================


class TestNotifyPass:
    def test_one_run_one_call(self):
        cursor = FakeSnowflakeCursor(fetchall_return=[
            (111, 786800, "model.a", "compile_error", "artifact_projection",
             "classified", "rationale-a"),
        ])
        client = FakeGitHubIssuesClient()
        results = notify_pass(
            github_client=client,
            snowflake_cursor=cursor,
            owner="org",
            repo="repo",
            run_ids=[111],
            now_utc=_fixed_now,
        )
        assert len(results) == 1
        assert results[0].action == "created"

    def test_gh_failure_for_one_run_does_not_block_rest(self):
        # Per-run isolation: a transport failure on run 111 must NOT
        # prevent run 222 from being processed.
        cursor = FakeSnowflakeCursor(fetchall_return=[
            (111, 786800, "model.a", "compile_error", "artifact_projection",
             "classified", "rationale-a"),
            (222, 786800, "model.b", "compile_error", "artifact_projection",
             "classified", "rationale-b"),
        ])
        client = FakeGitHubIssuesClient()
        # Make the FIRST create_issue raise; subsequent ones succeed.
        call_count = {"n": 0}
        original_create = client.create_issue

        def flaky_create(**kw):
            call_count["n"] += 1
            if call_count["n"] == 1:
                raise RuntimeError("simulated GH transport error")
            return original_create(**kw)

        client.create_issue = flaky_create  # type: ignore[method-assign]

        results = notify_pass(
            github_client=client,
            snowflake_cursor=cursor,
            owner="org",
            repo="repo",
            run_ids=[111, 222],
            now_utc=_fixed_now,
        )
        # Only run 222 succeeded; run 111 was caught + logged.
        assert len(results) == 1
        assert results[0].run_id == 222
        # Both runs were ATTEMPTED.
        assert call_count["n"] == 2


# ===========================================================================
# Focus items 4 & 5 — Cron YAML
# ===========================================================================


CRON_YAML_PATH = (
    Path(__file__).resolve().parents[3]
    / ".github" / "workflows" / "triage-cron.yaml"
)


class TestCronYamlQ3Cadence:
    """The cron YAML ships at the Q3-locked cadence (PR jobs at
    5-min as the first scope; scheduled jobs at 30-min Phase-1.5
    documented as follow-on).
    """

    def test_cron_yaml_file_exists(self):
        assert CRON_YAML_PATH.exists(), (
            f"Cron YAML missing at {CRON_YAML_PATH}"
        )

    def test_cron_yaml_has_five_minute_schedule(self):
        content = CRON_YAML_PATH.read_text()
        # 5-min cron expression — */5 * * * *
        assert "*/5 * * * *" in content, (
            "Q3-locked cadence: PR jobs must be polled at 5-min "
            "intervals (expression '*/5 * * * *')"
        )

    def test_cron_yaml_documents_phase15_scheduled_jobs(self):
        content = CRON_YAML_PATH.read_text()
        # The 30-min Phase-1.5 schedule MAY be commented-out (ships as
        # documented follow-on); the directive permits PR-only first.
        # Test verifies the Phase-1.5 lock is at least mentioned.
        assert "30" in content and "Phase-1.5" in content, (
            "Cron YAML must reference the Q3-locked 30-min Phase-1.5 "
            "scheduled-job cadence (commented or active)"
        )

    def test_cron_yaml_locks_q3_job_ids(self):
        content = CRON_YAML_PATH.read_text()
        # Q3-locked PR jobs (must appear by id for traceability).
        assert "786800" in content, "Missing PROD PR job id 786800"
        assert "786806" in content, "Missing DEV PR job id 786806"
        # Q3-locked scheduled jobs (referenced, may be commented).
        assert "647886" in content, "Missing scheduled job id 647886"
        assert "939844" in content, "Missing scheduled job id 939844"


class TestCronYamlDbtHostCellPrefix:
    """Multi-cell host is a COUPLED PAIR — the bare cell host plus the
    cell prefix — and the workflow must carry BOTH so dbt-mcp composes
    the real host kl673.us1.dbt.com.

    Regression locked: the cron once shipped DBT_HOST=us1.dbt.com WITHOUT
    MULTICELL_ACCOUNT_PREFIX (the prefix lived only in the gitignored
    .vscode/mcp.json and setup.md's template omitted it). dbt-mcp fell
    back to the bare host and 404'd every account-scoped Admin API call,
    so the poll pulled 0 runs while the workflow stayed GREEN. This test
    asserts the PAIR — NOT "host != bare": under the multi-cell mechanism
    the bare host is CORRECT and the missing piece is the prefix var — and
    that the client allowlist actually copies the prefix to the subprocess
    (setting it in the workflow alone is inert if the allowlist drops it).
    """

    def _env_block(self) -> dict:
        loaded = yaml.safe_load(CRON_YAML_PATH.read_text())
        return loaded["jobs"]["triage-poll-and-notify"]["env"]

    def test_workflow_sets_bare_cell_host(self):
        env = self._env_block()
        assert env["DBT_HOST"] == "us1.dbt.com", (
            "DBT_HOST must be the BARE cell host (the prefix is supplied "
            "separately via MULTICELL_ACCOUNT_PREFIX); a full host here "
            "would double-compose to kl673.kl673.us1.dbt.com once the "
            "prefix var is also present"
        )

    def test_workflow_sets_multicell_prefix(self):
        env = self._env_block()
        assert env["MULTICELL_ACCOUNT_PREFIX"] == "kl673", (
            "MULTICELL_ACCOUNT_PREFIX (kl673) is REQUIRED for this "
            "multi-cell account — without it dbt-mcp uses the bare "
            "us1.dbt.com host and 404s every account-scoped Admin API "
            "call (poll pulls 0 runs while the workflow stays green)"
        )

    def test_client_allowlist_copies_multicell_prefix(self):
        from scripts.automation.src.triage.dbt_cloud_client import (
            DBT_REQUIRED_ENV_VARS,
        )

        assert "MULTICELL_ACCOUNT_PREFIX" in DBT_REQUIRED_ENV_VARS, (
            "the client must COPY MULTICELL_ACCOUNT_PREFIX into the "
            "dbt-mcp subprocess (loud-fail if absent) — setting it in "
            "the workflow env alone is inert if the allowlist drops it"
        )


class TestCronYamlUsesExistingSecrets:
    """The cron uses keyless WIF — no new CREDENTIAL surface (directive
    §7.3, as revised by the WIF cutover). It still uses existing secret
    families (GITHUB_TOKEN, DBT_CLOUD_*, SNOWFLAKE_ACCOUNT); the only new
    secret is SNOWFLAKE_OIDC_AUDIENCE, a non-credential account-audience
    identifier (no rotation obligation). The password secret is dropped —
    SA_TRIAGE_AGENT is keyless (TYPE=SERVICE)."""

    def test_uses_existing_secret_references(self):
        content = CRON_YAML_PATH.read_text()
        # Existing secret patterns (GITHUB_TOKEN is built-in to all
        # GHA repos; DBT_CLOUD_* and SNOWFLAKE_* are existing org
        # secret families).
        has_existing = (
            "secrets.GITHUB_TOKEN" in content
            or "secrets.DBT_CLOUD" in content
            or "secrets.SNOWFLAKE" in content
        )
        assert has_existing, (
            "Cron YAML must reference existing secrets, not introduce "
            "a new secret name"
        )

    def test_no_new_secret_surface_introduced(self):
        content = CRON_YAML_PATH.read_text().lower()
        # Forbidden patterns that would suggest a NEW secret class.
        forbidden_new_secret_keywords = [
            "secrets.triage_notifier_token",
            "secrets.notifier_token",
            "secrets.triage_gh_pat",
        ]
        for kw in forbidden_new_secret_keywords:
            assert kw not in content, (
                f"Cron YAML introduces new secret surface {kw!r}; "
                f"directive forbids — use existing mechanism"
            )

    def test_workflow_is_keyless_no_password_secret(self):
        # Keyless WIF tripwire at the workflow layer (mirrors the
        # cron_entrypoint password tripwire). SA_TRIAGE_AGENT has no
        # password; re-adding a SNOWFLAKE_PASSWORD env assignment here would
        # be a security regression and break auth against a keyless user.
        # The SECRETS comment MENTIONS the dropped password, so this targets
        # an active env key (line-anchored), not any substring.
        content = CRON_YAML_PATH.read_text()
        assert not re.search(r"^\s*SNOWFLAKE_PASSWORD\s*:", content, re.M), (
            "Cron YAML must NOT set a SNOWFLAKE_PASSWORD env var — the cron "
            "is keyless WIF (SA_TRIAGE_AGENT is TYPE=SERVICE, no password). "
            "Re-introducing password auth is a security regression"
        )

    def test_workflow_wires_keyless_wif(self):
        # WIF-wiring tripwire: the workflow must (a) grant id-token: write
        # (no OIDC token can be minted without it), (b) reference the OIDC
        # audience (byte-matched to OIDC_AUDIENCE_LIST), and (c) mask the
        # minted token. Removing any one breaks auth SILENTLY — only the
        # first cron tick would surface it. Locks the load-bearing wiring
        # the mutation gate flagged as otherwise uncovered.
        content = CRON_YAML_PATH.read_text()
        # Anchor each to the actual YAML key / command — a stale COMMENT
        # mentioning these must NOT satisfy the tripwire (Copilot review).
        assert re.search(r"^\s*id-token\s*:\s*write", content, re.M), (
            "Workflow must grant 'id-token: write' as a permissions key "
            "(not just a comment) to mint the GitHub OIDC token for WIF"
        )
        assert re.search(r"^\s*SNOWFLAKE_OIDC_AUDIENCE\s*:", content, re.M), (
            "Workflow must set the SNOWFLAKE_OIDC_AUDIENCE env key (byte-"
            "matched to the account's OIDC_AUDIENCE_LIST), not just mention it"
        )
        assert re.search(r'^\s*echo "::add-mask::', content, re.M), (
            'The minted OIDC token must be masked via an echo "::add-mask::" '
            "command in the run script, not only named in a comment"
        )


class TestCronYamlConcurrencyGuard:
    """**Mutation E defeater + Absorbed C6 finding.**

    The cursor-as-MAX(run_id) design REQUIRES serial polling
    (concurrent passes race the cursor). The cron YAML must include
    a ``concurrency:`` block enforcing serial execution
    (``cancel-in-progress: false`` so new ticks queue/skip, NOT
    cancel the in-flight pass).

    Mutation E: remove the concurrency block. The test requires the
    YAML to have it — documentation without enforcement is the
    "comment that nobody reads" trap.
    """

    def test_yaml_has_concurrency_block(self):
        content = CRON_YAML_PATH.read_text()
        assert "concurrency:" in content, (
            "Cron YAML missing concurrency: block. Without it, two "
            "GHA scheduled runs can overlap and race the cursor-as-"
            "MAX(run_id) (both read same high-water, process same "
            "runs, write duplicates / fail). Serial-cron is REQUIRED."
        )

    def test_yaml_concurrency_uses_cancel_in_progress_false(self):
        content = CRON_YAML_PATH.read_text()
        # Match cancel-in-progress: false (with flexible whitespace).
        assert re.search(
            r"cancel-in-progress\s*:\s*false", content
        ), (
            "Concurrency block must set 'cancel-in-progress: false' — "
            "true would CANCEL the in-flight pass mid-run, leaving "
            "partial cursor state. We want NEW ticks to queue/skip "
            "while the in-flight pass completes."
        )

    def test_yaml_concurrency_group_includes_triage(self):
        content = CRON_YAML_PATH.read_text()
        # Group name must be a stable identifier (not unique-per-run).
        assert re.search(
            r"group\s*:\s*triage", content, re.IGNORECASE
        ), (
            "Concurrency group must name a stable identifier for "
            "the cron (e.g., 'triage-cron'). Per-run groups would "
            "still allow concurrent passes."
        )


# ===========================================================================
# Focus item 6 — Absorbed C6 deferred findings
# ===========================================================================


CRON_ENTRYPOINT_PATH = (
    Path(__file__).resolve().parents[1]
    / "src" / "triage" / "cron_entrypoint.py"
)


class TestCronEntrypointDocumentsNowUtcAwareness:
    """C6 deferred finding #1: now_utc() aware-vs-naive requirement
    documented at the cron-wiring call site (NOT defensively normalized
    in C6/C7 modules).
    """

    def test_cron_entrypoint_exists(self):
        assert CRON_ENTRYPOINT_PATH.exists(), (
            f"Cron entrypoint missing at {CRON_ENTRYPOINT_PATH}"
        )

    def test_cron_entrypoint_documents_aware_datetime_requirement(self):
        content = CRON_ENTRYPOINT_PATH.read_text()
        content_lower = content.lower()
        # The aware-datetime requirement must be mentioned at the
        # cron entrypoint (where the clock is wired into the loop).
        assert "aware" in content_lower and "datetime" in content_lower, (
            "Cron entrypoint must document the aware-datetime "
            "requirement (absorbed C6 deferred finding) — naive "
            "datetimes injected here would corrupt the dedup "
            "since-window arithmetic"
        )
        assert "now_utc" in content, (
            "Cron entrypoint must reference now_utc by name (the "
            "exact kwarg this documentation pertains to)"
        )


class TestCronEntrypointDocumentsConcurrency:
    """C6 deferred finding #2: serial-cron concurrency assumption
    documented as a known constraint (NOT silently assumed)."""

    def test_cron_entrypoint_documents_serial_assumption(self):
        content = CRON_ENTRYPOINT_PATH.read_text()
        content_lower = content.lower()
        # Either "serial" or "concurrency" must appear in a comment/docstring
        # explaining the cursor-race constraint.
        assert "serial" in content_lower or "concurrency" in content_lower, (
            "Cron entrypoint must document the serial-cron assumption "
            "(absorbed C6 deferred finding). The cursor-as-MAX(run_id) "
            "design breaks under concurrent pollers on the same scope; "
            "this can't be silently assumed"
        )
        assert "cursor" in content_lower, (
            "Documentation must explain WHY serial is required (cursor "
            "race), not just state it"
        )


class TestCronEntrypointHappyPathInfoLog:
    """C6 deferred finding #3: happy-path INFO log per pass (runs-
    processed count + dead-letter counts) so operations can see the
    loop is alive.
    """

    def test_cron_entrypoint_emits_info_log_per_pass(self):
        content = CRON_ENTRYPOINT_PATH.read_text()
        # The entrypoint must invoke a logger.info call summarising
        # the pass — the directive specifies "runs-processed count,
        # dead-letter counts by sink."
        assert re.search(r"logger\.info\s*\(", content), (
            "Cron entrypoint must emit at least one logger.info call "
            "(absorbed C6 deferred finding — happy-path observability)"
        )
        # The log must reference key report fields.
        for required in ["runs_polled", "envelopes_processed"]:
            assert required in content, (
                f"Happy-path INFO log must include {required!r} so "
                f"operations sees runs-processed counts"
            )


class TestCronEntrypointUsesKeylessWif:
    """Tripwire: the cron authenticates via keyless Workload Identity
    Federation, never a password. SA_TRIAGE_AGENT is TYPE=SERVICE and has
    no password — reverting to password auth would be both a security
    regression and an immediate auth failure. Locks the keyless design in
    place (same tripwire logic as the HASHDIFF value-collapse test).
    """

    def test_cron_entrypoint_uses_workload_identity(self):
        content = CRON_ENTRYPOINT_PATH.read_text()
        assert 'authenticator="WORKLOAD_IDENTITY"' in content, (
            "Cron entrypoint must authenticate via Workload Identity "
            'Federation (authenticator="WORKLOAD_IDENTITY")'
        )
        assert 'workload_identity_provider="OIDC"' in content, (
            "Cron entrypoint must use the OIDC workload-identity provider"
        )

    def test_cron_entrypoint_does_not_use_password_auth(self):
        content = CRON_ENTRYPOINT_PATH.read_text()
        # Target the connect kwarg specifically (password=os.environ[...]) so
        # unrelated prose mentioning "password=" can't false-trip (Copilot review).
        assert "password=os.environ" not in content, (
            "Cron entrypoint must NOT pass a password kwarg — SA_TRIAGE_AGENT "
            "is keyless (TYPE=SERVICE, no password). Reverting to a "
            "password is a security regression and breaks auth"
        )


# ===========================================================================
# Marker / title smoke tests
# ===========================================================================


class TestMarkerAndTitleConstants:
    def test_marker_is_lowercase_runid_equals_int(self):
        assert _marker(42) == "run_id=42"
        assert _marker(786800) == "run_id=786800"

    def test_title_includes_marker_and_count(self):
        title = _build_title(42, 3)
        assert "run_id=42" in title
        assert "3 failed result" in title

    def test_title_prefix_is_triage_tag(self):
        title = _build_title(42, 1)
        assert title.startswith("[Triage]")


# ===========================================================================
# Body templating — long-rationale truncation, no-rationale, etc.
# ===========================================================================


class TestBodyTemplating:
    def test_rationale_longer_than_500_chars_is_truncated(self):
        long_rationale = "x" * 600
        payload = _payload(
            results=[
                _result(rationale=long_rationale),
            ],
        )
        body = _build_body(payload)
        # Truncation marker (ellipsis horizontal char) present.
        assert "\u2026" in body
        # Full rationale NOT present.
        assert long_rationale not in body

    def test_no_rationale_omits_quote_block(self):
        payload = _payload(
            results=[_result(rationale=None)],
        )
        body = _build_body(payload)
        # No ">" quote block when rationale is None.
        lines = body.split("\n")
        quote_lines = [ln for ln in lines if ln.startswith("> ")]
        assert quote_lines == []

    def test_no_unique_id_renders_placeholder(self):
        payload = _payload(
            results=[_result(unique_id=None)],
        )
        body = _build_body(payload)
        assert "_(no unique_id)_" in body

    def test_marker_appears_in_body_separate_from_title(self):
        # Defensive: the marker is in BOTH title and body so a future
        # change moving dedup to body-scan would still work.
        payload = _payload(run_id=12345)
        body = _build_body(payload)
        assert "run_id=12345" in body
