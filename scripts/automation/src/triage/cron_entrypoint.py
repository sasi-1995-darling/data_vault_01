"""Triage cron entrypoint — wires C6 poll_loop + C7 notifier into one pass.

Invoked once per GHA cron tick by ``.github/workflows/triage-cron.yaml``.
Performs:

  1. Snowflake connect (cursor for cursor-derivation + writer)
  2. dbt-Cloud client init (urllib + DBT_CLOUD_API_TOKEN)
  3. GitHub issues client init (urllib + GITHUB_TOKEN)
  4. ``run_poll_pass(...)`` → ``PollPassReport``
  5. Derive run_ids to notify (successes + attempted_but_failed)
  6. ``notify_pass(...)`` — one aggregated GH issue per run
  7. Happy-path INFO log (runs_polled, envelopes_processed, dead-letters)

=============================================================================
ABSORBED C6 DEFERRED FINDINGS — documented at this call site (not silently
applied in upstream modules):

  Finding 1: now_utc() — aware-vs-naive datetime requirement.
    The C6 poll_loop and C7 notifier accept ``now_utc`` as an injectable
    callable returning a tz-aware datetime. Both modules ASSUME tz-aware
    UTC; passing a naive datetime would silently corrupt cursor arithmetic
    (poll_loop's finished_at_floor_days) and dedup window arithmetic
    (notifier's since=now-7d). The fix lives HERE at the wiring site —
    the cron entrypoint constructs a known-aware datetime via
    ``datetime.now(timezone.utc)`` and passes it down. Upstream modules
    do not defensively normalize, by deliberate decision (each defensive
    normalization is a place a future bug can hide; the aware-or-fail
    contract surfaces drift loudly via TypeError on naive subtraction).
    Reviewer: if you change the now_utc factory below, verify the result
    is tz-aware via ``.tzinfo is not None``.

  Finding 2: serial-cron concurrency — cursor-as-MAX(run_id) constraint.
    The C6 cursor design (Decision 1) derives the high-water from
    ``SELECT MAX(run_id) FROM TRIAGE_INVOCATIONS WHERE job_id IN (...)``.
    This design BREAKS under concurrent pollers on the same scope —
    two passes would each read the same high-water, each process the
    same set of newly-failed runs, and each attempt to write the same
    rows (best case: unique-key MERGE prevents duplicates but wastes
    work; worst case: cursor advancement loses runs). The fix lives in
    .github/workflows/triage-cron.yaml as concurrency.cancel-in-progress=
    false — but the assumption is documented HERE so that anyone reading
    the entrypoint (e.g., adapting it for a different scheduler) sees
    the serial-cron requirement BEFORE adopting the code. Failure mode
    if violated: cursor race produces missing-notification gaps and/or
    duplicate-write contention.

  Finding 3: happy-path INFO log — operational observability.
    The cron loop is normally invisible — it succeeds quietly and the
    only visible artifact is GH issues (which appear ONLY on
    newly-failed runs). On a quiet day with zero failures, an outside
    observer cannot distinguish "loop ran, found nothing" from "loop
    is silently broken." The fix: emit ONE logger.info per pass with
    runs_polled, envelopes_processed, and dead-letter counts. GHA
    persists job logs for 90 days — this gives ops a heartbeat.
    Failure mode if dropped: silent-failure debt (no signal until a
    user reports they didn't get notified).

=============================================================================
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from typing import Any, Optional

from scripts.automation.src.triage.notifier import (
    GitHubIssuesClient,
    notify_pass,
)
from scripts.automation.src.triage.poll_loop import (
    PollPassReport,
    run_poll_pass,
)
from scripts.automation.src.triage.writer import TriageWriter

logger = logging.getLogger("triage.cron")


# ---------------------------------------------------------------------------
# now_utc — aware-datetime factory (absorbed C6 finding 1)
# ---------------------------------------------------------------------------


def _now_utc() -> datetime:
    """Return the current time as a tz-AWARE UTC datetime.

    Both poll_loop (C6) and notifier (C7) require tz-aware UTC; a naive
    datetime injected here would silently corrupt downstream arithmetic
    (the since-window in notifier's dedup, the finished_at_floor_days in
    poll_loop's pagination floor). The fix is centralized at the wiring
    site rather than defensively re-normalized in each consumer — see
    module docstring "Finding 1" for the contract reasoning.
    """
    return datetime.now(timezone.utc)


# ---------------------------------------------------------------------------
# Concrete GitHub issues client — urllib-based, satisfies notifier Protocol
# ---------------------------------------------------------------------------


class UrllibGitHubIssuesClient:
    """Minimal GH REST client satisfying notifier.GitHubIssuesClient.

    Uses urllib (no external dependencies in CI). Single-host
    (api.github.com), token-auth via Authorization header, JSON
    request/response.

    No retries here — the notifier wraps each per-run notify in a
    catch-and-log so a transient transport error on one run does not
    block the rest. Adding retries here would double-handle the
    failure class without changing the per-run-isolation semantics.

    No rate-limit handling here. GH issues API allows 5000 req/hr
    authenticated; one cron tick at 5-minute cadence makes <50
    requests in the worst case (10-page list + N create/comment for
    each newly-failed run). The order-of-magnitude headroom is the
    design margin — adding rate-limit handling before we have
    evidence of need would be premature complexity.
    """

    def __init__(self, *, token: str, base_url: str = "https://api.github.com"):
        if not token:
            raise ValueError("GitHub token is empty — cannot authenticate")
        self._token = token
        self._base_url = base_url.rstrip("/")

    def _request(
        self,
        *,
        method: str,
        path: str,
        query: Optional[dict] = None,
        body: Optional[dict] = None,
    ) -> Any:
        url = self._base_url + path
        if query:
            url = url + "?" + urllib.parse.urlencode(query)
        data = json.dumps(body).encode("utf-8") if body is not None else None
        req = urllib.request.Request(
            url=url,
            data=data,
            method=method,
            headers={
                "Authorization": f"Bearer {self._token}",
                "Accept": "application/vnd.github+json",
                "X-GitHub-Api-Version": "2022-11-28",
                "Content-Type": "application/json",
                "User-Agent": "fbin-triage-agent/1.0",
            },
        )
        with urllib.request.urlopen(req, timeout=30) as resp:  # noqa: S310
            payload = resp.read()
            return json.loads(payload) if payload else None

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
        result = self._request(
            method="GET",
            path=f"/repos/{owner}/{repo}/issues",
            query={
                "since": since,
                "state": state,
                "per_page": per_page,
                "page": page,
            },
        )
        return result or []

    def create_issue(
        self,
        *,
        owner: str,
        repo: str,
        title: str,
        body: str,
        labels: list[str],
    ) -> dict:
        return self._request(
            method="POST",
            path=f"/repos/{owner}/{repo}/issues",
            body={"title": title, "body": body, "labels": list(labels)},
        )

    def add_comment(
        self,
        *,
        owner: str,
        repo: str,
        issue_number: int,
        body: str,
    ) -> dict:
        return self._request(
            method="POST",
            path=f"/repos/{owner}/{repo}/issues/{issue_number}/comments",
            body={"body": body},
        )


# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------


def _parse_args(argv: Optional[list[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="triage-cron",
        description=(
            "One-pass triage poll + notify. Designed for serial-cron "
            "invocation — see module docstring Finding 2."
        ),
    )
    parser.add_argument(
        "--owner",
        required=True,
        help="GitHub owner (org or user) — e.g., FBWINN-Data-Analytics",
    )
    parser.add_argument(
        "--repo",
        required=True,
        help="GitHub repo name — e.g., dbt-datavault",
    )
    parser.add_argument(
        "--job-ids",
        required=True,
        help="Comma-separated dbt-Cloud job ids to poll",
    )
    parser.add_argument(
        "--dry-run",
        default="false",
        help="If 'true', poll + classify but skip GH-write step",
    )
    return parser.parse_args(argv)


def _parse_job_ids(raw: str) -> list[int]:
    if not raw or not raw.strip():
        raise ValueError("--job-ids is empty")
    parts = [p.strip() for p in raw.split(",") if p.strip()]
    if not parts:
        raise ValueError("--job-ids has no valid ids after split")
    out: list[int] = []
    for p in parts:
        if not re.fullmatch(r"\d+", p):
            raise ValueError(f"--job-ids contains non-integer token: {p!r}")
        out.append(int(p))
    return out


# ---------------------------------------------------------------------------
# Main entrypoint
# ---------------------------------------------------------------------------


def main(argv: Optional[list[str]] = None) -> int:
    """Entry point for ``python -m scripts.automation.src.triage.cron_entrypoint``.

    Returns process exit code. 0 on clean pass, non-zero on
    catastrophic failure (e.g., bad secret config) — per-run failures
    are caught and logged, NOT escalated to a non-zero exit, because
    the next cron tick will re-attempt them.
    """
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    args = _parse_args(argv)

    try:
        job_ids = _parse_job_ids(args.job_ids)
    except ValueError as exc:
        logger.error("triage_cron_arg_parse_failed reason=%s", exc)
        return 2

    dry_run = args.dry_run.lower() == "true"

    # --- Secrets (existing surface only — see triage-cron.yaml env block).
    gh_token = os.environ.get("GITHUB_TOKEN", "")
    if not gh_token and not dry_run:
        logger.error("triage_cron_missing_secret name=GITHUB_TOKEN")
        return 3

    # --- Snowflake cursor (used for poll_loop cursor + writer + notifier
    #     payload assembly).
    cursor = _open_snowflake_cursor()
    writer = TriageWriter(cursor=cursor)

    # --- dbt-Cloud client (poll_loop dependency).
    dbt_client = _open_dbt_cloud_client()

    # --- Sinks for the four-way dead-letter taxonomy. Each one logs;
    #     none escalates to a process-level exception.
    def _on_malformed_input(envelope: Any, exc: Exception) -> None:
        logger.warning(
            "triage_malformed_input run_id=%s exc=%s",
            getattr(envelope, "run_id", "?"),
            exc,
        )

    def _on_operational_error(envelope: Any, exc: Exception) -> None:
        logger.warning(
            "triage_operational_error run_id=%s exc=%s",
            getattr(envelope, "run_id", "?"),
            exc,
        )

    def _on_attempted_but_failed(run_id: int, exc: Exception) -> None:
        logger.warning(
            "triage_attempted_but_failed run_id=%s exc=%s", run_id, exc
        )

    def _on_source_unavailable(exc: Exception) -> None:
        logger.warning("triage_source_unavailable exc=%s", exc)

    # --- The pass itself. environment_id is intentionally NOT passed:
    #     run_poll_pass sources it PER-RUN from each dbt run payload, so a
    #     pass spanning PROD (786800) + DEV (786806) stamps each row with
    #     its own environment instead of one mislabeling constant. A run
    #     payload missing environment_id is logged + skipped there.
    report: PollPassReport = run_poll_pass(
        client=dbt_client,
        triage_writer=writer,
        snowflake_cursor=cursor,
        job_ids=job_ids,
        on_malformed_input=_on_malformed_input,
        on_operational_error=_on_operational_error,
        on_attempted_but_failed=_on_attempted_but_failed,
        on_source_unavailable=_on_source_unavailable,
        now_utc=_now_utc,
    )

    # --- Happy-path INFO log (absorbed C6 finding 3). Emitted REGARDLESS
    #     of whether anything was found — the heartbeat is the point.
    logger.info(
        "triage_cron_pass_complete "
        "runs_polled=%d envelopes_processed=%d "
        "attempted_but_failed=%d source_unavailable=%s cursor_lost=%s",
        report.runs_polled,
        report.envelopes_processed,
        len(report.attempted_but_failed_run_ids),
        report.source_unavailable,
        report.cursor_lost,
    )

    if dry_run:
        logger.info("triage_cron_dry_run_skip_notify")
        return 0

    # --- Derive run_ids to notify: every run touched in this pass that
    #     produced at least one TRIAGE_INVOCATIONS row OR was dead-
    #     lettered. The notifier's assemble_run_payloads queries the
    #     table for each id — runs with zero rows are silently omitted
    #     (defensive against transient writer skip).
    notify_run_ids: list[int] = []
    # invocation_ids carries "run_id::unique_id" — pull just the run_id.
    seen_run_ids: set[int] = set()
    for inv_id in report.invocation_ids:
        # Format: "<run_id>::<unique_id_or_NO_NODE>".
        head = inv_id.split("::", 1)[0]
        if re.fullmatch(r"\d+", head):
            seen_run_ids.add(int(head))
    for rid in sorted(seen_run_ids):
        notify_run_ids.append(rid)
    # Dead-lettered runs also get notified (humans need to know).
    for rid in report.attempted_but_failed_run_ids:
        if rid not in seen_run_ids:
            notify_run_ids.append(rid)

    if not notify_run_ids:
        logger.info("triage_cron_no_runs_to_notify")
        return 0

    gh_client: GitHubIssuesClient = UrllibGitHubIssuesClient(token=gh_token)

    notify_results = notify_pass(
        github_client=gh_client,
        snowflake_cursor=cursor,
        owner=args.owner,
        repo=args.repo,
        run_ids=notify_run_ids,
        now_utc=_now_utc,
    )

    created = sum(1 for r in notify_results if r.action == "created")
    commented = sum(1 for r in notify_results if r.action == "commented")
    skipped = sum(1 for r in notify_results if r.action == "skipped_empty")
    logger.info(
        "triage_cron_notify_complete created=%d commented=%d skipped=%d",
        created,
        commented,
        skipped,
    )
    return 0


# ---------------------------------------------------------------------------
# Hooks for Snowflake / dbt-Cloud — kept thin + injectable for tests
# ---------------------------------------------------------------------------


def _open_snowflake_cursor() -> Any:
    """Connect to Snowflake using keyless Workload Identity Federation.

    The cron authenticates as the TYPE=SERVICE user SA_TRIAGE_AGENT via
    GitHub OIDC (Workload Identity Federation) — there is NO password or
    keypair stored anywhere (the account has zero credential material).
    The workflow mints a short-lived GitHub OIDC token whose audience
    byte-matches the account's OIDC_AUDIENCE_LIST and passes it via
    SNOWFLAKE_WIF_TOKEN; the connector forwards it to Snowflake, which
    validates iss/sub/aud server-side against the user's WORKLOAD_IDENTITY
    config. See create_oidc_attestation in snowflake.connector.wif_util:
    provider=OIDC requires the token to be supplied explicitly (it is NOT
    auto-fetched from the GitHub Actions runtime).

    Imported lazily so unit tests on the parsing logic do not require
    snowflake-connector-python to be installed.
    """
    import snowflake.connector  # noqa: PLC0415 — see docstring

    conn = snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        authenticator="WORKLOAD_IDENTITY",
        workload_identity_provider="OIDC",
        token=os.environ["SNOWFLAKE_WIF_TOKEN"],
        role=os.environ.get("SNOWFLAKE_ROLE"),
        warehouse=os.environ.get("SNOWFLAKE_WAREHOUSE"),
        database=os.environ.get("SNOWFLAKE_DATABASE", "OPS_PROD"),
        schema=os.environ.get("SNOWFLAKE_SCHEMA", "LOGS"),
    )
    return conn.cursor()


def _open_dbt_cloud_client() -> Any:
    """Construct a duck-typed DbtCloudClient over the dbt-mcp stdio server.

    The concrete class talks to dbt-mcp (the official dbt Labs MCP
    server, ``dbt-mcp==1.19.2``) via stdio, spawning one ``uvx``
    subprocess per call. dbt-mcp owns the Admin v2 HTTP wire to
    cloud.getdbt.com and the ``failed_steps[].results[]`` projection
    the C4 adapter consumes. See ``dbt_cloud_client`` module docstring
    for the three design decisions (session-per-call, DBT_* env
    allowlist, typed-raise fail-open).

    Imported lazily so tests exercising ``main()`` arg-parsing don't
    pull the ``mcp`` package transitively.
    """
    from scripts.automation.src.triage import dbt_cloud_client  # noqa: PLC0415

    return dbt_cloud_client.StdioMcpDbtCloudClient(
        api_token=os.environ["DBT_CLOUD_API_TOKEN"],
        account_id=int(os.environ["DBT_CLOUD_ACCOUNT_ID"]),
    )


if __name__ == "__main__":
    sys.exit(main())
