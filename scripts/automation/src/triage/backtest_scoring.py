"""Verdict enum + per-case scoring for the backtest harness.

Split from `backtest.py` (Day-6 commit, post-DA review) to honor the
~250-line surface cap. This module owns the HOW (compare one
orchestrator emission to one expected label, producing a Verdict and
a CaseResult). Schema lives in `backtest_schema.py`. Aggregation +
driver live in `backtest.py`.

Pattern-id extraction
---------------------
The orchestrator's `_classified` builds a rationale prefixed with
`pattern_id=<id> sub_class=...`. The harness parses this prefix via
`_PATTERN_ID_RE`. If the rationale format ever changes, both the
orchestrator AND this regex must be updated — covered by
TestPatternIdExtraction.test_contract_against_live_orchestrator.

Per-case error isolation
------------------------
`safe_load` catches load-time errors (TypeError from non-dict roots
rejected by `fixture_loader.load_fixture`, `json.JSONDecodeError` on
corrupt payload bytes, `OSError` on filesystem trouble) and
`safe_triage` catches any exception out of `triage_failure` itself.
A single bad case cannot abort the entire run (DA P1-2). The errored
case is recorded as `Verdict.ERROR_DURING_TRIAGE` and excluded from
precision/recall denominators. `ValueError` from `resolve_payload_path`
(path-escape rejection, P0-2 security boundary) deliberately propagates
as fatal — a label pointing outside the allowlisted root is a
configuration bug or attack signal, not a data-quality issue, and
downgrading it to per-case ERROR would mask the boundary breach.

The load-time wrapper was added 2026-06-21 (PR #1821 Commit 6, R4
N1/N2): tightening `load_fixture` to reject non-dict roots at the
chokepoint moved the TypeError origin from `triage_failure` (downstream)
to `load_fixture` (upstream), surfacing that the P1-2 isolation contract
was only half-implemented — it covered triage-time failures but not
load-time ones. The CI gate under python3.11 caught the gap; this fix
makes the harness honor its full documented contract.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from enum import Enum
from typing import Optional

from scripts.automation.src.triage.backtest_schema import LabeledCase
from scripts.automation.src.triage.failure_triage_agent import triage_failure
from scripts.automation.src.triage.rca_schema import Outcome, RCARecord


# Matches the prefix `pattern_id=<id> ` produced by orchestrator._classified.
# Pattern ids are catalog-side identifiers — no whitespace, no quotes
# (enforced upstream by fbin_error_catalog.SUPPORTED_PATTERN_ID_REGEX).
_PATTERN_ID_RE = re.compile(r"^pattern_id=(\S+)")


# ---------------------------------------------------------------------------
# Verdicts (one per orchestrator branch; matches Verdict-coverage tests)
# ---------------------------------------------------------------------------


class Verdict(str, Enum):
    """Outcome of comparing one orchestrator emission to its expected label.

    SKIPPED_PAYLOAD_MISSING and ERROR_DURING_TRIAGE are NOT scored into
    precision/recall — they are book-kept separately so the harness
    stays runnable in environments that lack the scratch corpus
    (clean-clone CI) and is robust to a single bad payload corrupting
    the rest of the run (Day-6 DA P1-2: corrupted JSON would TypeError
    inside triage_failure and abort the entire backtest mid-loop).
    """

    PASS = "pass"
    FALSE_POSITIVE = "false_positive"          # CLASSIFIED, label says UNKNOWN
    FALSE_NEGATIVE = "false_negative"          # UNKNOWN, label says CLASSIFIED
    WRONG_PATTERN = "wrong_pattern"            # CLASSIFIED but wrong pattern_id
    SENTINEL_FIRED_UNEXPECTED = "sentinel_fired_unexpected"
    SKIPPED_PAYLOAD_MISSING = "skipped_payload_missing"
    ERROR_DURING_TRIAGE = "error_during_triage"


# ---------------------------------------------------------------------------
# Per-case scoring
# ---------------------------------------------------------------------------


def extract_pattern_id(record: RCARecord) -> Optional[str]:
    """Return the pattern_id from a CLASSIFIED record's rationale.

    Returns None for UNKNOWN records and for CREDENTIAL_SENTINEL_FIRED
    rationales (those don't carry a pattern_id prefix).
    """
    if record.outcome != Outcome.CLASSIFIED:
        return None
    if not record.rationale:
        return None
    match = _PATTERN_ID_RE.match(record.rationale)
    return match.group(1) if match else None


@dataclass(frozen=True)
class CaseResult:
    """Per-case scoring outcome."""

    run_id: int
    cluster: str
    verdict: Verdict
    expected_pattern_id: Optional[str]
    observed_pattern_id: Optional[str]
    expected_outcome: Outcome
    observed_outcome: Optional[Outcome]
    rationale_excerpt: str  # first 240 chars; empty for SKIPPED


def score_case(case: LabeledCase, record: Optional[RCARecord]) -> CaseResult:
    """Score one case. `record is None` → SKIPPED_PAYLOAD_MISSING."""
    if record is None:
        return CaseResult(
            run_id=case.run_id,
            cluster=case.cluster,
            verdict=Verdict.SKIPPED_PAYLOAD_MISSING,
            expected_pattern_id=case.expected_pattern_id,
            observed_pattern_id=None,
            expected_outcome=case.expected_outcome,
            observed_outcome=None,
            rationale_excerpt="",
        )

    observed_pattern_id = extract_pattern_id(record)
    observed_outcome = record.outcome
    excerpt = (record.rationale or "")[:240]

    # Sentinel fired but label did not anticipate it → unexpected.
    # (Phase-1 corpus has no sentinel-positive labels — see
    # LabeledCase._enforce_label_invariants.)
    if observed_outcome == Outcome.CREDENTIAL_SENTINEL_FIRED:
        verdict = Verdict.SENTINEL_FIRED_UNEXPECTED
    elif case.expected_outcome == Outcome.UNKNOWN_HANDED_TO_HUMAN:
        # Label says no pattern should match.
        verdict = (
            Verdict.PASS
            if observed_outcome == Outcome.UNKNOWN_HANDED_TO_HUMAN
            else Verdict.FALSE_POSITIVE
        )
    else:  # label says CLASSIFIED
        if observed_outcome != Outcome.CLASSIFIED:
            verdict = Verdict.FALSE_NEGATIVE
        elif observed_pattern_id != case.expected_pattern_id:
            verdict = Verdict.WRONG_PATTERN
        else:
            verdict = Verdict.PASS

    return CaseResult(
        run_id=case.run_id,
        cluster=case.cluster,
        verdict=verdict,
        expected_pattern_id=case.expected_pattern_id,
        observed_pattern_id=observed_pattern_id,
        expected_outcome=case.expected_outcome,
        observed_outcome=observed_outcome,
        rationale_excerpt=excerpt,
    )


def safe_triage(raw: dict) -> tuple[Optional[RCARecord], Optional[str]]:
    """Invoke triage_failure with per-case error isolation.

    Returns (record, error_message). Either record is non-None and
    error_message is None, or vice-versa. Triggered by Day-6 DA P1-2:
    a TypeError or JSON-malformed payload in one case would otherwise
    abort the entire run.

    Backtest scope: the C5 writer's redaction/projection elements are
    NOT needed for scoring (verdict is computed from the RCARecord
    alone — classification, outcome, rationale). The 3-tuple's second
    and third elements are intentionally discarded here. Writer-side
    persistence is a separate concern handled by the C5 writer in
    production, never invoked from backtest scoring.
    """
    try:
        rec, _, _ = triage_failure(raw)
        return rec, None
    except Exception as exc:  # noqa: BLE001 — isolate any failure mode
        # R2: exc_type only — no str(exc). Exception is raised while
        # handling a triage payload; exc.args may carry payload fragments.
        # Canonical expression: failure_triage_agent.py:256-285.
        # See: docs/triage-agent/credential-threat-model.md R2.
        return None, f"{type(exc).__name__}"


def errored_case(case: LabeledCase, error_message: str) -> CaseResult:
    """Construct an ERROR_DURING_TRIAGE result for one case."""
    return CaseResult(
        run_id=case.run_id,
        cluster=case.cluster,
        verdict=Verdict.ERROR_DURING_TRIAGE,
        expected_pattern_id=case.expected_pattern_id,
        observed_pattern_id=None,
        expected_outcome=case.expected_outcome,
        observed_outcome=None,
        rationale_excerpt=error_message[:240],
    )


def safe_load(
    case: "LabeledCase",
    repo_root: "Path",
) -> tuple[Optional[dict], Optional[str]]:
    """Resolve a label's payload path and load the raw dict, with
    per-case error isolation matching `safe_triage`'s contract.

    Returns (raw, error_message). Either raw is non-None (or None for
    SKIPPED_PAYLOAD_MISSING per `load_raw_payload`'s contract) and
    error_message is None, or raw is None and error_message is set
    to the exception type name.

    Catches: `TypeError` (non-dict root rejected by `load_fixture`
    after the 2026-06-21 tightening, PR #1821 N1/N2), `JSONDecodeError`
    (corrupt payload bytes), `OSError` (filesystem trouble beyond
    'file missing', which `load_raw_payload` already handles as
    None-return).

    Does NOT catch `ValueError` from `resolve_payload_path` — path
    escape is a P0-2 security-boundary violation, not a data-quality
    issue, and must abort the run rather than be silently downgraded
    to per-case ERROR. R2-style sanitization applies to the error
    message: only `type(exc).__name__` is recorded, never `str(exc)`
    (which could carry payload fragments). Mirrors `safe_triage`.
    """
    # Late imports to avoid a circular dep at module load time:
    # backtest_scoring is the lower-level module; backtest_schema imports
    # symbols from here in some configurations. Keeping these imports
    # function-local matches the existing pattern used elsewhere in the
    # module for cross-sibling helpers.
    import json as _json
    from scripts.automation.src.triage.backtest_schema import (
        load_raw_payload as _load_raw_payload,
        resolve_payload_path as _resolve_payload_path,
    )
    try:
        payload_path = _resolve_payload_path(case, repo_root)
        raw = _load_raw_payload(payload_path)
        return raw, None
    except (TypeError, _json.JSONDecodeError, OSError) as exc:
        return None, f"{type(exc).__name__}"


# Private aliases preserved for the test suite (existing imports of
# `_safe_triage` and `_errored` continue to work).
_safe_triage = safe_triage
_errored = errored_case
