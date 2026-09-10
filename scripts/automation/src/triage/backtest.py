"""Backtest harness — score `triage_failure` against the P0.1 labeled corpus.

Phase-1 scope (per session prompt 2026-06-07)
---------------------------------------------
* Step 1 deliverable: harness skeleton + scoring framework + 7-payload
  baseline scoring + label-protocol enforcement.
* OUT of scope: corpus expansion (Phase 2); score interpretation /
  new-pattern candidates / Cluster-C revival (Phase 3); CI gating
  (Phase 2 — Phase 1 ships baseline report committed, non-gating).

Module split (Day-6, post-DA review)
------------------------------------
This module owns AGGREGATION + the top-level `run_backtest` driver.

* `backtest_schema.py` — Pydantic models, label loaders, payload
  resolution + traversal defenses.
* `backtest_scoring.py` — `Verdict` enum, per-case `score_case`,
  per-case error isolation via `safe_triage`.
* `backtest_report.py` — markdown rendering + CLI entry.

Public names from the two sibling modules are re-exported here so that
existing imports of `scripts.automation.src.triage.backtest` keep
working unchanged. New code should prefer importing from the specific
module that owns the symbol.

Boundary contract
-----------------
`run_backtest(label_set, repo_root)` is pure (no I/O beyond payload
reads) and returns a `BacktestReport`. The orchestrator is invoked
once per labelled case via the production entrypoint `triage_failure
(dict)` — the harness does NOT bypass redact, projection, or matcher.
This is the entry-5 contract: backtest evidence must reflect what
production actually does.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from scripts.automation.src.triage.backtest_schema import (
    LABEL_SCHEMA_VERSION,
    RESERVED_BUCKET_PATTERN_ID,
    LabeledCase,
    LabelProvenance,
    LabelSet,
    load_labels,
    load_raw_payload,
    resolve_payload_path,
)
from scripts.automation.src.triage.backtest_scoring import (
    CaseResult,
    Verdict,
    _errored,
    _safe_triage,
    errored_case,
    extract_pattern_id,
    safe_load,
    safe_triage,
    score_case,
)
from scripts.automation.src.triage.fbin_error_catalog import CATALOG_SCHEMA_VERSION


HARNESS_VERSION = "v1.0.0"


# Re-export bundle — symbols listed here remain importable from this module
# despite living in sibling modules. Existing tests + the report module use
# these import paths; preserve them to avoid churn.
__all__ = [
    # constants
    "CATALOG_SCHEMA_VERSION",
    "HARNESS_VERSION",
    "LABEL_SCHEMA_VERSION",
    "RESERVED_BUCKET_PATTERN_ID",
    # schema
    "LabelProvenance",
    "LabeledCase",
    "LabelSet",
    "load_labels",
    "load_raw_payload",
    "resolve_payload_path",
    # scoring
    "CaseResult",
    "Verdict",
    "extract_pattern_id",
    "safe_load",
    "safe_triage",
    "errored_case",
    "_safe_triage",  # legacy alias retained for test compatibility
    "_errored",      # legacy alias retained for test compatibility
    "score_case",
    # aggregation (defined below)
    "PatternMetrics",
    "BacktestReport",
    "run_backtest",
    "_compute_pattern_metrics",
]


# ---------------------------------------------------------------------------
# Aggregation
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class PatternMetrics:
    """Precision/recall counts per pattern_id (+ the synthetic 'UNKNOWN' bucket)."""

    pattern_id: str
    true_positive: int
    false_positive: int
    false_negative: int

    @property
    def precision(self) -> Optional[float]:
        denom = self.true_positive + self.false_positive
        return self.true_positive / denom if denom else None

    @property
    def recall(self) -> Optional[float]:
        denom = self.true_positive + self.false_negative
        return self.true_positive / denom if denom else None


@dataclass(frozen=True)
class BacktestReport:
    """Aggregate report — committed as baseline (markdown rendering in sibling)."""

    label_version: str
    label_path: str
    label_notes: str
    harness_version: str
    catalog_schema_version: str
    case_count_total: int
    case_count_scored: int
    case_count_skipped: int
    case_count_errored: int
    verdict_counts: dict[Verdict, int]
    per_pattern_metrics: list[PatternMetrics]
    cases: list[CaseResult]


def _compute_pattern_metrics(
    cases: list[CaseResult],
    pattern_ids: list[str],
) -> list[PatternMetrics]:
    """Compute TP/FP/FN per pattern_id over scored (non-skipped) cases.

    "UNKNOWN" treated as a synthetic bucket so the no-match path gets
    a row in the report. SKIPPED + ERROR cases are excluded from the
    denominator entirely — they are runtime concerns, not catalog
    correctness signals.
    """
    scored = [
        c for c in cases
        if c.verdict not in {
            Verdict.SKIPPED_PAYLOAD_MISSING,
            Verdict.ERROR_DURING_TRIAGE,
        }
    ]
    metrics: list[PatternMetrics] = []
    buckets = list(pattern_ids) + [RESERVED_BUCKET_PATTERN_ID]
    for pid in buckets:
        is_expected = lambda c: (c.expected_pattern_id or RESERVED_BUCKET_PATTERN_ID) == pid  # noqa: E731
        is_observed = lambda c: (c.observed_pattern_id or RESERVED_BUCKET_PATTERN_ID) == pid  # noqa: E731
        tp = sum(1 for c in scored if is_expected(c) and is_observed(c))
        fp = sum(1 for c in scored if not is_expected(c) and is_observed(c))
        fn = sum(1 for c in scored if is_expected(c) and not is_observed(c))
        metrics.append(PatternMetrics(
            pattern_id=pid, true_positive=tp, false_positive=fp, false_negative=fn,
        ))
    return metrics


def run_backtest(
    label_set: LabelSet,
    repo_root: Path,
    *,
    label_path: str = "docs/triage-agent/fixtures/p01_labels.yml",
) -> BacktestReport:
    """Drive the harness end-to-end against `label_set.labels`.

    `label_path` is recorded in the report verbatim (P1-1 from Day-6 DA:
    the CLI may load alternative label files; the baseline must say which
    one it scored against).
    """
    cases: list[CaseResult] = []
    for case in label_set.labels:
        raw, load_error = safe_load(case, repo_root)
        if load_error is not None:
            cases.append(errored_case(case, load_error))
            continue
        if raw is None:
            cases.append(score_case(case, None))
            continue
        record, error = safe_triage(raw)
        if error is not None:
            cases.append(errored_case(case, error))
            continue
        cases.append(score_case(case, record))

    verdict_counts: dict[Verdict, int] = {v: 0 for v in Verdict}
    for c in cases:
        verdict_counts[c.verdict] += 1

    pattern_ids = sorted({
        c.expected_pattern_id
        for c in cases
        if c.expected_pattern_id is not None
    } | {
        c.observed_pattern_id
        for c in cases
        if c.observed_pattern_id is not None
    })

    return BacktestReport(
        label_version=label_set.version,
        label_path=label_path,
        label_notes=label_set.notes,
        harness_version=HARNESS_VERSION,
        catalog_schema_version=CATALOG_SCHEMA_VERSION,
        case_count_total=len(cases),
        case_count_scored=sum(
            1 for c in cases
            if c.verdict not in {
                Verdict.SKIPPED_PAYLOAD_MISSING,
                Verdict.ERROR_DURING_TRIAGE,
            }
        ),
        case_count_skipped=verdict_counts[Verdict.SKIPPED_PAYLOAD_MISSING],
        case_count_errored=verdict_counts[Verdict.ERROR_DURING_TRIAGE],
        verdict_counts=verdict_counts,
        per_pattern_metrics=_compute_pattern_metrics(cases, pattern_ids),
        cases=cases,
    )
