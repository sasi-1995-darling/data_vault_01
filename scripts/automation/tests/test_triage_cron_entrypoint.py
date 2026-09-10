"""Integration tests for the ``main()`` → ``run_poll_pass`` seam in
``scripts.automation.src.triage.cron_entrypoint``.

This seam was UNCOVERED before this file: ``run_poll_pass`` was unit-
tested in isolation (with a dummy ``environment_id``), but no test drove
``main()`` into the real ``run_poll_pass``. A production re-dispatch
surfaced ``TypeError: run_poll_pass() missing 1 required keyword-only
argument: 'environment_id'`` — a never-run-integration bug. These tests
exercise the wiring end-to-end so the contract between ``main()`` and
``run_poll_pass`` is locked.

The dry-run path returns 0 immediately after the pass (no GitHub write),
which makes ``main()`` drivable without network or secrets: the three
external openers (Snowflake cursor, dbt client, TriageWriter) plus the
clock are monkeypatched, and the REAL ``run_poll_pass`` runs.
"""

from __future__ import annotations

import inspect
from datetime import datetime, timezone

from scripts.automation.src.triage import cron_entrypoint, poll_loop
from scripts.automation.src.triage.poll_loop import PollPassReport


# ---------------------------------------------------------------------------
# Minimal test doubles (inlined to keep this file self-contained — it
# deliberately does not import fakes from test_triage_poll_loop).
# ---------------------------------------------------------------------------


class _FakeCursor:
    """Satisfies ``_query_high_water`` only: records ``execute`` and
    returns a scripted ``MAX(run_id)`` from ``fetchone``."""

    def __init__(self, high_water):
        self._high_water = high_water
        self.executed: list[tuple] = []

    def execute(self, sql, params=None):
        self.executed.append((sql, params))

    def fetchone(self):
        return (self._high_water,)


class _FakeDbtClient:
    """Serves one scripted page per job at offset 0 (then empty), and a
    scripted ``get_job_run_error`` per run_id."""

    def __init__(self, pages_by_job, errors_by_run):
        self._pages_by_job = pages_by_job
        self._errors_by_run = errors_by_run
        self._served: set[int] = set()
        self.list_calls: list[tuple[int, int]] = []
        self.error_calls: list[int] = []

    def list_jobs_runs(self, *, status, job_id, limit, offset):
        self.list_calls.append((job_id, offset))
        if offset == 0 and job_id not in self._served:
            self._served.add(job_id)
            return list(self._pages_by_job.get(job_id, []))
        return []

    def get_job_run_error(self, *, run_id):
        self.error_calls.append(run_id)
        return self._errors_by_run[run_id]


class _FakeWriter:
    """Captures ``write`` invocations; mirrors the real TriageWriter
    keyword contract."""

    def __init__(self):
        self.writes: list[dict] = []

    def write(
        self,
        rca,
        redaction,
        projection,
        *,
        run_id,
        job_id,
        environment_id,
        unique_id,
        git_sha,
    ):
        self.writes.append(
            {
                "run_id": run_id,
                "job_id": job_id,
                "environment_id": environment_id,
                "unique_id": unique_id,
                "git_sha": git_sha,
            }
        )
        return f"{run_id}::{unique_id or 'NO_NODE'}"


def _good_parsed_error(unique_id="model.x.dim_customer"):
    """Minimal well-formed ``get_job_run_error`` response that the C4
    adapter turns into exactly one envelope → one writer row."""
    return {
        "failed_steps": [
            {
                "step_name": "dbt build",
                "target": "default",
                "finished_at": "2026-06-30T11:00:00+00:00",
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


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


def test_main_dry_run_drives_real_poll_pass_with_per_run_env_id(monkeypatch):
    """End-to-end: ``main(--dry-run true)`` drives the REAL
    ``run_poll_pass`` over a pass spanning TWO environments (PROD job
    786800 + DEV job 786806). Asserts (a) ``main`` returns 0 — which it
    cannot if ``run_poll_pass`` raises the missing-``environment_id``
    TypeError — and (b) each written row carries ITS OWN run's
    ``environment_id``, proving per-run provenance survives the full
    wiring rather than a single mislabeling constant.
    """
    fixed_now = datetime(2026, 6, 30, 12, 0, 0, tzinfo=timezone.utc)
    finished_at = "2026-06-30T11:00:00+00:00"
    pages = {
        786800: [
            {
                "id": 501,
                "job_id": 786800,
                "environment_id": 296881,  # PROD
                "git_sha": "aaa1111",
                "finished_at": finished_at,
            }
        ],
        786806: [
            {
                "id": 502,
                "job_id": 786806,
                "environment_id": 287190,  # DEV
                "git_sha": "bbb2222",
                "finished_at": finished_at,
            }
        ],
    }
    errors = {501: _good_parsed_error(), 502: _good_parsed_error()}
    fake_client = _FakeDbtClient(pages, errors)
    fake_cursor = _FakeCursor(high_water=500)  # 501/502 both unseen
    fake_writer = _FakeWriter()

    monkeypatch.setattr(cron_entrypoint, "_now_utc", lambda: fixed_now)
    monkeypatch.setattr(
        cron_entrypoint, "_open_snowflake_cursor", lambda: fake_cursor
    )
    monkeypatch.setattr(
        cron_entrypoint, "_open_dbt_cloud_client", lambda: fake_client
    )
    monkeypatch.setattr(
        cron_entrypoint, "TriageWriter", lambda cursor: fake_writer
    )

    rc = cron_entrypoint.main(
        [
            "--owner", "FBWINN-Data-Analytics",
            "--repo", "dbt-datavault",
            "--job-ids", "786800,786806",
            "--dry-run", "true",
        ]
    )

    assert rc == 0
    by_run = {w["run_id"]: w["environment_id"] for w in fake_writer.writes}
    assert by_run == {501: 296881, 502: 287190}


def test_main_call_satisfies_run_poll_pass_signature(monkeypatch):
    """Contract lock that reproduces the production TypeError class
    directly: bind ``main``'s actual call kwargs against the REAL
    ``run_poll_pass`` signature. If ``main`` ever omits a required
    keyword (the original bug), ``Signature.bind`` raises TypeError —
    the same failure Python raised at the live call site. Also pins the
    design: ``main`` must NOT pass a pass-level ``environment_id`` (the
    pass is multi-environment; env id is sourced per-run).
    """
    real_sig = inspect.signature(poll_loop.run_poll_pass)
    captured: dict = {}

    def _spy(**kwargs):
        real_sig.bind(**kwargs)  # raises TypeError on a missing required kw
        captured.update(kwargs)
        return PollPassReport(
            high_water_at_start=None, runs_polled=0, envelopes_processed=0
        )

    monkeypatch.setattr(
        cron_entrypoint, "_open_snowflake_cursor", lambda: object()
    )
    monkeypatch.setattr(
        cron_entrypoint, "_open_dbt_cloud_client", lambda: object()
    )
    monkeypatch.setattr(
        cron_entrypoint, "TriageWriter", lambda cursor: object()
    )
    monkeypatch.setattr(cron_entrypoint, "run_poll_pass", _spy)

    rc = cron_entrypoint.main(
        [
            "--owner", "o",
            "--repo", "r",
            "--job-ids", "786800,786806",
            "--dry-run", "true",
        ]
    )

    assert rc == 0
    assert captured["job_ids"] == [786800, 786806]
    # Per-run sourcing: cron must not stamp one env id on the whole pass.
    assert "environment_id" not in captured
