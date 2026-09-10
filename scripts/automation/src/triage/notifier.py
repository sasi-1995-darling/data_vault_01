"""Triage notifier — C7 (spec v3.4 §4.8 + §8).

Public surface:

    notify_run(
        *,
        github_client,        # GitHubIssuesClient (duck-typed)
        owner, repo,
        payload,              # RunNotificationPayload (one per dbt-Cloud run)
        now_utc=None,
        dedup_window_days=7,
        labels=None,
    ) -> NotifyResult

    notify_pass(
        *,
        github_client, snowflake_cursor,
        owner, repo,
        run_ids,              # list[int] — run_ids to notify (de-duped upstream)
        now_utc=None,
        dedup_window_days=7,
    ) -> list[NotifyResult]

    assemble_run_payloads(snowflake_cursor, *, run_ids) -> list[RunNotificationPayload]

Posts (or updates) ONE GitHub issue per dbt-Cloud run, aggregating the run's
N per-envelope results into a single body. Mandatory self-ID line on every
body. Dedup by H9 list-endpoint mechanism (NOT search).

Boundary contracts (asserted in test_triage_notifier.py):

  * **Issue grain — ONE PER RUN aggregating N results (§4.8).** A human
    triaging a failed PR wants one issue listing the run's failures, not
    N issues. The per-envelope row grain (the writer's grain) is the
    analytical grain; the per-run issue grain is the human-attention
    grain. These are DELIBERATELY distinct — both are correct for their
    consumer. Mutation C (create N issues per run instead of 1) pins
    this — TestOneIssuePerRunAggregating must go RED on the mutation.

  * **H9 list-endpoint dedup — THE HARDEST READ.** Dedup uses GitHub
    ``GET /repos/{owner}/{repo}/issues?since=...&state=all`` (the
    LIST-issues endpoint), NOT the search endpoint. Rationale: GitHub
    search has a 1-2 min index lag; the canonical issue store (list
    endpoint) has NO index lag. The crash-between-create-and-cursor-
    write window — which an earlier (G6) "same scope as cursor
    advancement" design left open — is closed by querying the
    canonical store, not the search index.

    Two-part mechanism, BOTH parts must be right:
      (a) A STABLE EXACT-MATCHABLE marker ``run_id=<id>`` in the issue
          title. Exact-matchable means ``\\brun_id=12\\b`` does NOT
          match ``run_id=123`` (regex word-boundary on both sides).
          Fuzzy substring match (``"run_id=12" in title``) would be
          wrong — a future run_id=12345 would false-positive on an
          existing run_id=12 issue.
      (b) The dedup check uses the LIST-issues endpoint, not search,
          with ``since=now-7d`` to bound the scan. Same-run issues
          older than 7d are stale enough to warrant fresh notification
          anyway.

    On match: comment the existing issue (do NOT create a second).
    No DDL column for "notified" — idempotency lives at GH (the
    side-effect site), so it survives manual issue deletion and
    cannot drift from reality (a ``notified_at`` column would drift if
    an issue were manually deleted; the list-endpoint reflects ACTUAL
    current GH state).

    Mutation A (swap list for search) pins this — the index-lag test
    (TestDedupUnderSearchIndexLag) must go RED on the mutation. The
    test fixture sets up: list-endpoint returns the just-created issue
    (canonical store has it), search-endpoint returns empty (index
    hasn't caught up). The correct (list) impl finds it and comments;
    the mutant (search) impl sees empty and creates a duplicate. THE
    TEST DEFEATS THE WRONG DESIGN — it doesn't merely "verify dedup
    works on a fresh store" (which both correct and incorrect impls
    pass).

    Mutation B (drop or narrow ``since`` window) pins the bounding —
    TestDedupHonorsSevenDayWindow must go RED on the mutation.

  * **Self-ID line — mandatory, verbatim.** Every body (created or
    appended via comment) ends with::

        *Posted via DV Failure Triage Agent automation.*

    Pinned by TestSelfIdLinePresent (Mutation D defeater). The
    self-ID line is the chain-of-custody guarantee — a human reading
    the issue must be able to tell that automation posted it without
    inspecting commit logs or repo settings.

  * **§8 honesty in the body templating** — UNKNOWN classifications
    are rendered as "evidence captured for human review", NOT as
    "triage failed." Per §8: the agent classifies the thin slice it
    honestly can; everything else is captured for corpus accretion.
    The body must not present UNKNOWN as a coverage failure. There is
    NO coverage metric in the body (a "we classified X%" claim
    requires the incoming-failure denominator, which the notifier
    does NOT have at the per-run grain). TestUnknownRenderedAsEvidence
    + TestNoCoverageMetric pin both.

  * **Empty payload guard.** ``notify_run`` with zero results returns
    ``action="skipped_empty"`` and posts NOTHING. The cron may pass
    runs that ended up with no failed envelopes (unusual but possible
    in edge cases — e.g., a run that K-failed and was dead-lettered);
    silently no-op is correct.

  * **Required-kwarg discipline.** ``owner``, ``repo``, and ``payload``
    are required keyword-only. No defaults on provenance args
    (standing rule from C1-C6).

Wiring: C7 notifier is INVOKED BY the cron entrypoint after
``run_poll_pass`` returns. The cron derives ``run_ids`` to notify from
the report (successes → query Snowflake for run_id;
``attempted_but_failed_run_ids`` → use directly), and the notifier
takes it from there. C6 (poll_loop) is UNCHANGED — the locked
PollPassReport contract is the bridge.
"""

from __future__ import annotations

import logging
import re
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any, Callable, Optional, Protocol

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Self-ID line — mandatory verbatim string on every body
# ---------------------------------------------------------------------------

# DO NOT CHANGE this string without updating TestSelfIdLinePresent. The
# directive pins it verbatim; a typo or rewording fails the gate.
SELF_ID_LINE = "*Posted via DV Failure Triage Agent automation.*"


# ---------------------------------------------------------------------------
# Dedup constants
# ---------------------------------------------------------------------------

# H9 list-endpoint window: 7 days bounds the scan AND defines staleness —
# same-run issues older than this warrant a fresh notification.
_DEDUP_WINDOW_DAYS = 7

# Per-page size for GH list-issues (max allowed by API is 100).
_LIST_PER_PAGE = 100

# Hard cap on pages scanned for dedup. At per_page=100 this gives 1000
# recently-updated issues — well above any realistic 7d issue volume for
# the triage repo. If a misconfigured repo (or a notification storm) ever
# exceeds this, dedup may miss an older same-run issue and create a
# duplicate; the cap exists to prevent the cron from hanging on an
# unbounded scan. Bumping is cheap if needed.
_LIST_MAX_PAGES = 10


# ---------------------------------------------------------------------------
# Public protocol — the GH client surface the notifier depends on
# ---------------------------------------------------------------------------


class GitHubIssuesClient(Protocol):
    """Duck-typed GitHub Issues API surface.

    Methods MUST be keyword-only (matches the required-kwarg discipline
    carried from C4/C5/C6). Tests inject ``FakeGitHubIssuesClient``
    recording arguments + scripting return values / exceptions; the
    C7 cron entrypoint wires a real urllib-based implementation.

    NOTE: this protocol exposes ``list_issues`` but NOT a search
    method — that asymmetry is INTENTIONAL. The dedup path (the only
    place where the choice matters) calls ``list_issues``; a future
    mutation (Mutation A) would swap in a search call, and a test
    fixture simulating index lag would catch the swap. Not exposing
    search at the protocol level reinforces the H9 contract at the
    type surface.
    """

    def list_issues(
        self,
        *,
        owner: str,
        repo: str,
        since: str,
        state: str,
        per_page: int,
        page: int,
    ) -> list[dict]:  # pragma: no cover — protocol surface only
        ...

    def create_issue(
        self,
        *,
        owner: str,
        repo: str,
        title: str,
        body: str,
        labels: list[str],
    ) -> dict:  # pragma: no cover — protocol surface only
        ...

    def add_comment(
        self,
        *,
        owner: str,
        repo: str,
        issue_number: int,
        body: str,
    ) -> dict:  # pragma: no cover — protocol surface only
        ...


# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class ResultDetail:
    """One per-envelope result, as it appears in the issue body.

    Fields are POST-SERIALIZATION strings (already ``.value``-encoded
    where they came from EvidenceMode / Classification enums via the
    Snowflake column). The notifier does NOT touch enum objects; it
    only reads strings out of the rows.
    """

    unique_id: Optional[str]
    classification: str
    evidence_mode: str
    rationale: Optional[str]
    outcome: str


@dataclass(frozen=True)
class RunNotificationPayload:
    """Aggregation of one dbt-Cloud run's failed envelopes — the input
    to ``notify_run``."""

    run_id: int
    job_id: int
    results: tuple[ResultDetail, ...]


@dataclass(frozen=True)
class NotifyResult:
    """Outcome of one ``notify_run`` invocation.

    ``action`` is one of:
      * ``"created"`` — no existing issue found; new issue created.
      * ``"commented"`` — existing issue with marker found; appended
        a comment, did NOT create a duplicate.
      * ``"skipped_empty"`` — payload had zero results; nothing posted.
    """

    action: str
    issue_number: Optional[int]
    run_id: int
    marker: str


# ---------------------------------------------------------------------------
# Marker / title / body construction
# ---------------------------------------------------------------------------


def _marker(run_id: int) -> str:
    """Stable, exact-matchable marker for dedup. Format pinned —
    changing this string drifts dedup from any pre-existing issues."""
    return f"run_id={run_id}"


def _marker_pattern(run_id: int) -> "re.Pattern[str]":
    """Compile an EXACT-matchable regex for the marker. Word boundaries
    on both sides prevent ``run_id=12`` from matching ``run_id=123``
    (a future-run_id false-positive against an existing issue).
    Directive: "stable + exact-matchable, not fuzzy."
    """
    return re.compile(rf"\brun_id={run_id}\b")


def _build_title(run_id: int, n_results: int) -> str:
    """Issue title contains the marker for dedup-by-title-scan."""
    plural = "s" if n_results != 1 else ""
    return (
        f"[Triage] dbt-Cloud {_marker(run_id)} — "
        f"{n_results} failed result{plural}"
    )


def _render_one_result(idx: int, r: ResultDetail) -> list[str]:
    """Render one result block. UNKNOWN classifications render as
    "evidence captured for human review" per §8 honesty — NOT as
    "triage failed."""
    unique_id_display = r.unique_id if r.unique_id else "_(no unique_id)_"
    lines: list[str] = []
    if r.classification == "unknown":
        # §8 honesty: UNKNOWN is evidence-captured-for-human, NOT
        # failure-to-triage. The body language reflects that.
        lines.append(
            f"### {idx}. `{unique_id_display}` — UNKNOWN — "
            f"evidence captured for human review "
            f"(mode: `{r.evidence_mode}`)"
        )
    else:
        lines.append(
            f"### {idx}. `{unique_id_display}` — "
            f"`{r.classification}` (mode: `{r.evidence_mode}`)"
        )
    if r.rationale:
        # Truncate rationale to 500 chars to keep the body readable.
        # 500 is a soft choice — long enough for context, short enough
        # for skim. Truncation marker is the ellipsis horizontal char.
        rationale_text = r.rationale
        if len(rationale_text) > 500:
            rationale_text = rationale_text[:500] + "\u2026"
        lines.append("")
        lines.append(f"> {rationale_text}")
    lines.append("")
    return lines


def _build_body(payload: RunNotificationPayload) -> str:
    """Compose the GH issue body per §8 honesty rules.

    Structure:
      1. Header: marker on its own line + machine-readable note.
      2. Per-result list (one ### subheading per result).
      3. ``---`` separator.
      4. Self-ID line (Mandatory verbatim — see ``SELF_ID_LINE``).

    NO coverage metric (e.g., "classified 7/10") appears in the body —
    the notifier does NOT have the incoming-failure denominator at the
    per-run grain, and stating a coverage figure without denominator
    is the exact §8 violation we're guarding against.
    """
    n = len(payload.results)
    plural = "s" if n != 1 else ""
    # Header restates the count as "N failed result(s)" — the same
    # numerator-with-noun phrasing as the title, so a reader scanning
    # the body sees the count without scrolling up. This is the SAFE
    # phrasing per §8: it states only what we know (count of failed
    # results processed), with no implied denominator (e.g., NOT
    # "we classified N/X" or "N% coverage" — those would overclaim).
    lines: list[str] = [
        f"**Run:** job_id={payload.job_id} {_marker(payload.run_id)}",
        f"**Marker:** `{_marker(payload.run_id)}` "
        f"(machine-readable for dedup; do not edit)",
        "",
        f"## {n} failed result{plural}",
        "",
    ]
    for i, r in enumerate(payload.results, 1):
        lines.extend(_render_one_result(i, r))
    lines.append("---")
    lines.append("")
    lines.append(SELF_ID_LINE)
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# H9 list-endpoint dedup
# ---------------------------------------------------------------------------


def _find_existing_issue(
    *,
    github_client: GitHubIssuesClient,
    owner: str,
    repo: str,
    run_id: int,
    now: datetime,
    dedup_window_days: int,
) -> Optional[int]:
    """H9 dedup: scan GitHub LIST-issues endpoint (NOT search) for
    an existing issue carrying the ``run_id=<id>`` marker in its
    title. Returns the issue number on match, ``None`` if not found.

    The LIST endpoint queries the canonical issue store with NO
    index lag (vs. search's 1-2 min lag). This closes the
    crash-between-create-and-cursor-write window: if we just
    created an issue in the prior cron pass and crashed before
    writing the cursor row, the next pass restarts, calls
    ``_find_existing_issue`` for the same run, and FINDS the
    pre-existing issue — no duplicate.

    Bounds:
      * ``since=now-{dedup_window_days}d`` — same-run issues older
        than the window are stale enough to warrant fresh
        notification.
      * ``state=all`` — closed issues count for dedup within the
        window. A previously-notified-then-closed run shouldn't
        get a fresh issue on the next pass.
      * ``per_page=100, max_pages=10`` — bounded scan; 1000 issues
        of headroom against realistic 7d volume.

    Returns the FIRST matching issue's number (GH default sort is
    newest-first by creation; if multiple issues somehow exist for
    the same run, comment on the newest — the older ones are
    historical artifacts the human can close).
    """
    since_iso = (now - timedelta(days=dedup_window_days)).strftime(
        "%Y-%m-%dT%H:%M:%SZ"
    )
    marker_pattern = _marker_pattern(run_id)
    for page in range(1, _LIST_MAX_PAGES + 1):
        issues = github_client.list_issues(
            owner=owner,
            repo=repo,
            since=since_iso,
            state="all",
            per_page=_LIST_PER_PAGE,
            page=page,
        )
        if not issues:
            return None
        for issue in issues:
            title = issue.get("title", "")
            if not isinstance(title, str):
                continue
            if marker_pattern.search(title):
                num = issue.get("number")
                if isinstance(num, int):
                    return num
        if len(issues) < _LIST_PER_PAGE:
            # Partial page → exhausted. (GH returns fewer than per_page
            # only when there are no more items.)
            return None
    # Hit the page cap without finding a match — log a warning and
    # treat as "not found" (subsequent passes will retry).
    logger.warning(
        "triage_notifier_dedup_page_cap_hit run_id=%d "
        "max_pages=%d per_page=%d window_days=%d — possible "
        "duplicate risk if a same-run issue exists beyond the cap",
        run_id, _LIST_MAX_PAGES, _LIST_PER_PAGE, dedup_window_days,
    )
    return None


# ---------------------------------------------------------------------------
# Public — notify_run
# ---------------------------------------------------------------------------


def notify_run(
    *,
    github_client: GitHubIssuesClient,
    owner: str,
    repo: str,
    payload: RunNotificationPayload,
    now_utc: Optional[Callable[[], datetime]] = None,
    dedup_window_days: int = _DEDUP_WINDOW_DAYS,
    labels: Optional[list[str]] = None,
) -> NotifyResult:
    """Post (or update) ONE GitHub issue for one dbt-Cloud run,
    aggregating its N failed-envelope results into a single body.

    Per §4.8:
      * Issue grain = one per RUN, not one per envelope (human-
        attention grain ≠ analytical row grain).
      * Body lists each failed result with classification (or UNKNOWN),
        evidence_mode, rationale.
      * Self-ID line at the bottom (verbatim).

    Per H9:
      * Dedup uses GH list-issues (NOT search) with stable
        exact-matchable ``run_id=<id>`` marker.
      * On match: comment, do NOT create a duplicate.

    Args:
        github_client: duck-typed GitHubIssuesClient.
        owner, repo: target GitHub repository.
        payload: per-run aggregation (run_id, job_id, results tuple).
        now_utc: injectable clock (for deterministic ``since=now-7d``
            tests). Default uses ``datetime.now(timezone.utc)``.
            The injected callable MUST return an AWARE datetime in
            UTC — naive datetimes will produce wrong ``since`` ISO
            strings (the wall-clock will be off by the local offset).
            The default factory in this module is aware; the cron
            entrypoint documents the requirement at the injection site.
        dedup_window_days: bound on the dedup scan window (default 7).
        labels: GitHub labels for the new issue (default
            ``["triage", "automation"]``).

    Returns:
        NotifyResult with ``action`` in
        {"created", "commented", "skipped_empty"}.

    Raises:
        TypeError if payload.run_id is not int.
        Whatever the GH client raises on transport errors — propagated
        to the cron entrypoint, which logs and continues (one run's
        notification failure must not stall the rest of the pass).
    """
    if not isinstance(payload.run_id, int):
        raise TypeError(
            f"payload.run_id must be int, got "
            f"{type(payload.run_id).__name__}"
        )
    if not payload.results:
        # Defensive — a payload with zero results shouldn't reach the
        # notifier in normal flow (the cron filters), but if it does,
        # silently no-op rather than post an empty issue.
        return NotifyResult(
            action="skipped_empty",
            issue_number=None,
            run_id=payload.run_id,
            marker=_marker(payload.run_id),
        )

    now = (now_utc or _default_now_utc)()
    if labels is None:
        # Default labels — a single source of truth for the triage-bot
        # signal in the issue tracker.
        labels = ["triage", "automation"]

    existing_number = _find_existing_issue(
        github_client=github_client,
        owner=owner,
        repo=repo,
        run_id=payload.run_id,
        now=now,
        dedup_window_days=dedup_window_days,
    )
    body = _build_body(payload)

    if existing_number is not None:
        # On match: comment, do NOT create.
        github_client.add_comment(
            owner=owner,
            repo=repo,
            issue_number=existing_number,
            body=body,
        )
        logger.info(
            "triage_notifier_commented run_id=%d issue_number=%d",
            payload.run_id, existing_number,
        )
        return NotifyResult(
            action="commented",
            issue_number=existing_number,
            run_id=payload.run_id,
            marker=_marker(payload.run_id),
        )

    title = _build_title(payload.run_id, len(payload.results))
    created = github_client.create_issue(
        owner=owner,
        repo=repo,
        title=title,
        body=body,
        labels=list(labels),
    )
    num = created.get("number") if isinstance(created, dict) else None
    issue_number = num if isinstance(num, int) else None
    logger.info(
        "triage_notifier_created run_id=%d issue_number=%s",
        payload.run_id,
        issue_number if issue_number is not None else "?",
    )
    return NotifyResult(
        action="created",
        issue_number=issue_number,
        run_id=payload.run_id,
        marker=_marker(payload.run_id),
    )


# ---------------------------------------------------------------------------
# Per-pass orchestration — assemble payloads from Snowflake
# ---------------------------------------------------------------------------


# Single canonical template — TestAssembleQueryShape pins ``WHERE run_id IN``
# so a future change is forced to update the test alongside.
_PER_RUN_QUERY_SQL = (
    "SELECT run_id, job_id, unique_id, classification, "
    "evidence_mode, outcome, rationale "
    "FROM OPS_PROD.LOGS.TRIAGE_INVOCATIONS "
    "WHERE run_id IN ({placeholders}) "
    "ORDER BY run_id, created_at"
)


def assemble_run_payloads(
    snowflake_cursor: Any,
    *,
    run_ids: list[int],
) -> list[RunNotificationPayload]:
    """Query TRIAGE_INVOCATIONS for the per-envelope details needed
    to compose issue bodies; group rows by run_id.

    Bridges C6's locked PollPassReport (which exposes invocation_ids
    as ULIDs, not the per-envelope details) and the notifier's body
    composition. Reading via cursor keeps the C6 contract unchanged.

    Args:
        snowflake_cursor: DB-API 2.0 cursor (matches C5/C6 pattern).
        run_ids: distinct run_ids to fetch. Empty list returns [].

    Returns:
        List of RunNotificationPayload, one per run_id that has rows.
        Run_ids with no rows in TRIAGE_INVOCATIONS are SILENTLY
        OMITTED (no payload constructed) — a run_id with no rows
        means the writer never persisted anything for it, which is
        a normal "this run had zero failed envelopes" case, not an
        error.

    Raises:
        TypeError if run_ids contains non-int values.
    """
    if not run_ids:
        return []
    if not all(isinstance(rid, int) for rid in run_ids):
        raise TypeError(
            f"assemble_run_payloads: run_ids must all be int, got "
            f"{[type(rid).__name__ for rid in run_ids]}"
        )
    placeholders = ", ".join(
        f"%(run_id_{i})s" for i in range(len(run_ids))
    )
    sql = _PER_RUN_QUERY_SQL.format(placeholders=placeholders)
    params = {f"run_id_{i}": rid for i, rid in enumerate(run_ids)}
    snowflake_cursor.execute(sql, params)
    rows = snowflake_cursor.fetchall()

    by_run: dict[int, list[ResultDetail]] = {}
    job_id_by_run: dict[int, int] = {}
    for row in rows:
        # Position-indexed unpack — matches the SELECT order above.
        # If the SELECT changes, this unpack and the test that pins
        # the column order both fail loudly.
        run_id = row[0]
        job_id = row[1]
        unique_id = row[2]
        classification = row[3]
        evidence_mode = row[4]
        outcome = row[5]
        rationale = row[6]
        by_run.setdefault(run_id, []).append(
            ResultDetail(
                unique_id=unique_id if isinstance(unique_id, str) else None,
                classification=(
                    classification if isinstance(classification, str)
                    else "unknown"
                ),
                evidence_mode=(
                    evidence_mode if isinstance(evidence_mode, str)
                    else "undetected"
                ),
                rationale=rationale if isinstance(rationale, str) else None,
                outcome=outcome if isinstance(outcome, str) else "unknown",
            )
        )
        if isinstance(job_id, int):
            job_id_by_run[run_id] = job_id

    # Preserve the caller's run_id ordering for deterministic output —
    # tests pin the order to match the input list.
    payloads: list[RunNotificationPayload] = []
    for rid in run_ids:
        if rid in by_run:
            payloads.append(
                RunNotificationPayload(
                    run_id=rid,
                    job_id=job_id_by_run.get(rid, 0),
                    results=tuple(by_run[rid]),
                )
            )
    return payloads


def notify_pass(
    *,
    github_client: GitHubIssuesClient,
    snowflake_cursor: Any,
    owner: str,
    repo: str,
    run_ids: list[int],
    now_utc: Optional[Callable[[], datetime]] = None,
    dedup_window_days: int = _DEDUP_WINDOW_DAYS,
) -> list[NotifyResult]:
    """Convenience: assemble payloads for a pass's run_ids and post
    one issue per run.

    Per-run notification failures (GH transport errors) are caught
    and logged, NOT re-raised — one failed notification must not
    stall the rest of the pass. The cron's INFO log surfaces the
    counts; operations sees aggregate behaviour.
    """
    payloads = assemble_run_payloads(snowflake_cursor, run_ids=run_ids)
    results: list[NotifyResult] = []
    for payload in payloads:
        try:
            result = notify_run(
                github_client=github_client,
                owner=owner,
                repo=repo,
                payload=payload,
                now_utc=now_utc,
                dedup_window_days=dedup_window_days,
            )
            results.append(result)
        except Exception as exc:  # noqa: BLE001 — per-run isolation
            # One run's GH transport failure must not block the rest.
            # Log + continue. The cron's INFO log surfaces the counts.
            logger.error(
                "triage_notifier_failed run_id=%d exc_type=%s",
                payload.run_id, type(exc).__name__,
            )
    return results


def _default_now_utc() -> datetime:
    """Default ``now_utc`` factory — wall-clock UTC, AWARE.

    Returns an aware datetime in UTC. The notifier's ``_find_existing_issue``
    formats this as ``YYYY-MM-DDTHH:MM:SSZ`` for the GH API ``since=``
    parameter; a naive datetime would produce a wall-clock value off by
    the local offset (and the resulting ``since`` window would be wrong
    by the same amount, opening / shrinking the dedup window inconsistently).
    The cron entrypoint documents this requirement at the injection site.
    """
    return datetime.now(timezone.utc)
