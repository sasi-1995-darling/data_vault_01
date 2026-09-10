"""Failure-triage orchestrator — Day-5 Q2 skeleton (early-failure only).

Single public entrypoint:

    triage_failure(raw_payload: dict)
        -> tuple[RCARecord, RedactionResult | None, dict | None]

The 3-tuple shape was introduced in Component 5 (writer pipeline). It carries
the ``RedactionResult`` and the ``projection`` dict downstream so the writer
can derive ``error_signature_hash`` / ``evidence_json`` / ``redaction_events``
from the same artifacts the matcher consumed — without re-running the
redactor or re-projecting. See ``triage_failure`` docstring for the full
10-path return table.

Boundary contract (asserted in test_triage_orchestrator.py):

  * TypeError on non-dict input — no silent coercion.
  * Always returns a 3-tuple ``(rca, redaction, projection)`` for any
    valid dict; never returns None, never raises
    CredentialSentinelFired to the caller. The ``rca`` element is
    never None.
  * Mode not detected (no ``data.run_steps`` shape) → RCARecord with
    classification=UNKNOWN, outcome=UNKNOWN_HANDED_TO_HUMAN, rationale
    explains the missing shape. Artifact mode (``run_results.json``) is
    out of Phase-1 scope per sprint-1-deferred — zero P0.1 evidence
    supports an artifact branch today (lesson 4 spike-or-iterate).
  * CredentialSentinelFired raised by the redactor → caught at this
    boundary, recorded as RCARecord(outcome=CREDENTIAL_SENTINEL_FIRED).
    Rationale carries event METADATA only (pattern_name, field_path,
    offset, length) — NEVER the matched value (gate-d §5.6 item #6).
  * Any other (non-sentinel) Exception raised by the redactor → caught
    at this boundary as a fail-open per v2-plan §1.8: returns
    RCARecord(outcome=UNKNOWN_HANDED_TO_HUMAN), rationale carries
    ``exc_type`` ONLY (never ``str(exc)`` — un-sentinel-checked content
    by construction). KeyboardInterrupt / SystemExit propagate (the
    handler catches Exception, not BaseException). See the load-bearing
    comment at the handler site for the credential-safety rationale.
    Locked by tests/test_triage_orchestrator.py::TestRedactorFailOpen.
  * Empty projection (mode detected but no REGEX_ELIGIBLE fields populated
    post-redact) → UNKNOWN, rationale=``no extractable eligible fields``.
  * Zero pattern matches → UNKNOWN, outcome=UNKNOWN_HANDED_TO_HUMAN.
  * Exactly one pattern match → CLASSIFIED with the pattern's baseline
    confidence + suggested_action; requires_human_review mirrors the
    pattern's ``root_cause_investigation_required`` flag (Iron Rule
    already pre-validated at catalog load — Mut3a/Mut3b in
    fbin_error_catalog.py).
  * Multi-pattern match (≥2) → UNKNOWN with rationale listing the
    matched pattern_ids. Multi-pattern resolution policy is deferred
    pending real co-firing evidence (sprint-1-deferred item TBD on
    first Day-6+ co-fire).

Design notes:

  * Catalog + matcher cached at import time. Catalog YAML changes
    require process restart — acceptable because catalog is a
    deployment artifact (load_catalog raises loudly on any invariant
    violation, including the Mut series, so import-time failure is the
    safe default).
  * ``_project_payload`` runs AFTER ``redact_early_failure``. The
    redactor already invokes ``truncate_logs`` and the credential
    sentinel internally (Gate-7 ordering). Productionizing the Q1
    probe's ``build_literal_v2_payload`` BEFORE redact would skip
    sentinel + truncation entirely (P0 regression). The probe path is
    deliberately abandoned here.
  * ``REGEX_ELIGIBLE_FIELDS`` is imported live from ``redact``;
    ``_project_payload`` iterates the frozenset directly so any future
    expansion (item #16, debug_logs) lands without orchestrator changes.
    A drift-coupling parametric test in test_triage_orchestrator.py
    enforces this contract.
"""

from __future__ import annotations

import logging

from scripts.automation.src.triage.fbin_error_catalog import (
    PatternMatch,
    PatternMatcher,
    load_catalog,
)
from scripts.automation.src.triage.rca_schema import (
    Classification,
    EvidenceMode,
    Outcome,
    RCARecord,
)
from scripts.automation.src.triage.redact import (
    CredentialSentinelFired,
    REGEX_ELIGIBLE_FIELDS,
    RedactionResult,
    redact_early_failure,
)


logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Module-level cached catalog + matcher
# ---------------------------------------------------------------------------
# load_catalog enforces every catalog invariant (Mut1-7, Mut9d). A failure
# here at import time is the correct behaviour: the orchestrator cannot
# emit safe RCARecords against an invalid catalog.

_CATALOG = load_catalog()
_MATCHER = PatternMatcher(_CATALOG)


# ---------------------------------------------------------------------------
# Mode detection
# ---------------------------------------------------------------------------

def _detect_mode(raw: dict) -> EvidenceMode:
    """Classify the payload's evidence shape — never returns ``None``.

    Ordered detection (C1.5 spec §4.2 Q1 LOCKED):

      1. EARLY_FAILURE first — payload has ``data.run_steps[-1]`` (a
         non-empty list whose last entry is a dict) with at least one
         REGEX_ELIGIBLE field populated somewhere in the step OR in data.
         The existing semantic ("dbt errored before producing artifacts")
         takes precedence on both-shapes-present inputs.

      2. ARTIFACT_PROJECTION second — ``data.run_steps`` is absent /
         empty / non-list / its last entry is not a dict / it carries
         no eligible field, AND ``data.failed_steps`` is a non-empty
         list with at least one dict entry whose ``results`` is a
         non-empty list of dicts where at least one ``result`` carries
         a populated REGEX_ELIGIBLE field. This shape is produced by
         the artifact adapter from ``run_results.json`` post-projection.

      3. UNDETECTED — neither shape signals. The orchestrator hands the
         run to a human via the ``UNKNOWN_HANDED_TO_HUMAN`` outcome.
         **NEVER returns ``None``** — the ``Optional[EvidenceMode]``
         signature was retired in C1.5 to make exhaustive caller
         dispatch on ``EvidenceMode`` provably total.

    Detection is shape + signal-existence only — no content classification
    against catalog patterns happens here (that would create a circular
    dependency with the matcher). The signal-existence check (a
    REGEX_ELIGIBLE field is non-empty somewhere) is the same discipline
    the EARLY_FAILURE branch has always applied: detection fires only
    when projection would have something to feed the matcher.
    """
    data = raw.get("data")
    if not isinstance(data, dict):
        return EvidenceMode.UNDETECTED

    # ---- Branch 1: EARLY_FAILURE (precedence) ------------------------
    steps = data.get("run_steps")
    if isinstance(steps, list) and steps:
        last = steps[-1]
        if isinstance(last, dict):
            for field_name in REGEX_ELIGIBLE_FIELDS:
                for source in (last, data):
                    value = source.get(field_name)
                    if isinstance(value, str) and value:
                        return EvidenceMode.EARLY_FAILURE

    # ---- Branch 2: ARTIFACT_PROJECTION -------------------------------
    failed = data.get("failed_steps")
    if isinstance(failed, list) and failed:
        for step in failed:
            if not isinstance(step, dict):
                continue
            results = step.get("results")
            if not isinstance(results, list) or not results:
                continue
            for result in results:
                if not isinstance(result, dict):
                    continue
                for field_name in REGEX_ELIGIBLE_FIELDS:
                    value = result.get(field_name)
                    if isinstance(value, str) and value:
                        return EvidenceMode.ARTIFACT_PROJECTION

    # ---- Branch 3: UNDETECTED ----------------------------------------
    return EvidenceMode.UNDETECTED


# ---------------------------------------------------------------------------
# Projection — REDACTED payload → flat dict for matcher
# ---------------------------------------------------------------------------

def _project_payload(redacted: dict) -> dict[str, str]:
    """Flatten the REGEX_ELIGIBLE fields from a redacted early-failure
    payload into a top-level dict keyed by field name.

    The PatternMatcher reads ``payload.get(clause.field)`` at top level
    (see fbin_error_catalog.PatternMatcher._evaluate). It does not
    recurse. This projection bridges the producer shape (nested under
    ``data.run_steps[-1]`` and ``data``) and the matcher shape (flat).

    Per-field source precedence (first-non-empty wins):

      message              — data.run_steps[-1].message → data.message
      truncated_debug_logs — data.run_steps[-1].truncated_debug_logs
                           → data.truncated_debug_logs
      status_message       — data.status_message
                           → data.run_steps[-1].status_message
      logs                 — data.run_steps[-1].logs → data.logs

    Iterates REGEX_ELIGIBLE_FIELDS live so any future allowlist
    expansion (item #16) participates automatically.
    """
    data = redacted.get("data") if isinstance(redacted, dict) else None
    if not isinstance(data, dict):
        return {}
    steps = data.get("run_steps") if isinstance(data, dict) else None
    last_step: dict = {}
    if isinstance(steps, list) and steps and isinstance(steps[-1], dict):
        last_step = steps[-1]

    projection: dict[str, str] = {}
    for field_name in REGEX_ELIGIBLE_FIELDS:
        # Precedence: deepest first (run_step > data root) since the
        # failing step carries the most specific signal.
        for source in (last_step, data):
            value = source.get(field_name)
            if isinstance(value, str) and value:
                projection[field_name] = value
                break
    return projection


def _project_artifact_payload(redacted: dict) -> dict[str, str]:
    """Flatten the REGEX_ELIGIBLE fields from an artifact-projection
    payload into a top-level dict keyed by field name.

    PARALLEL to ``_project_payload`` (do NOT branch inside it — the two
    shapes are walked from different roots and a branch would entangle
    the matcher contract for both). Returns the same flat
    ``dict[str, str]`` the matcher consumes via ``_MATCHER.match_all``.

    Walks ``data["failed_steps"][0]["results"][0]`` — the ``[0][0]``
    single-result position guaranteed by the adapter contract (Component
    4 emits N single-result envelopes, one per result; each result is
    wrapped in its own ``{"data":{"failed_steps":[{...,"results":[<single>]}]}}``).

    The inclusion rule mirrors ``_project_payload`` byte-for-byte:
    iterate ``REGEX_ELIGIBLE_FIELDS`` live, include only string-valued
    non-empty fields, so any future allowlist expansion (item #16)
    participates automatically and both projectors keep the matcher's
    input shape identical.

    Defensive shape guards at every level (mirror ``_detect_mode``'s
    discipline): if any layer is missing / not-the-expected-type / empty,
    return ``{}``. NEVER raise on a malformed shape — this function is
    called OUTSIDE the redactor try/except (same position as
    ``_project_payload``), so a raise here would become a row-8
    Exception-propagation that the orchestrator routes to the
    operational dead-letter. Fail to ``{}`` (a clean row-4
    empty-projection ``_unknown`` path), not to an exception.

    Gap-F normalization (``truncated_logs`` → ``truncated_debug_logs``)
    is NOT this function's job — the adapter (Component 4) renames the
    field BEFORE building the envelope, so by the time this projector
    runs the field is already correctly named. Adding normalization
    here would put it in two places and create a drift risk.
    """
    data = redacted.get("data") if isinstance(redacted, dict) else None
    if not isinstance(data, dict):
        return {}
    failed_steps = data.get("failed_steps")
    if not isinstance(failed_steps, list) or not failed_steps:
        return {}
    first_step = failed_steps[0]
    if not isinstance(first_step, dict):
        return {}
    results = first_step.get("results")
    if not isinstance(results, list) or not results:
        return {}
    first_result = results[0]
    if not isinstance(first_result, dict):
        return {}

    projection: dict[str, str] = {}
    for field_name in REGEX_ELIGIBLE_FIELDS:
        value = first_result.get(field_name)
        if isinstance(value, str) and value:
            projection[field_name] = value
    return projection


# ---------------------------------------------------------------------------
# RCARecord constructors
# ---------------------------------------------------------------------------

def _evidence_source_phrase(mode: EvidenceMode) -> str:
    """Return the human-readable evidence-source path for ``mode``.

    Centralizes the mode→walk-path mapping so rationale strings stay
    shape-aware in ONE place. Closes carry C2.b (Component 2 byte-review
    2026-06-19): the empty-projection rationale must name the walk path
    the projector ACTUALLY took, not the EARLY_FAILURE walk regardless
    of mode.

    Per the C1.5 spec §8 honesty contract: UNDETECTED returns a no-walk
    phrase — by definition no projector ran for that mode, so claiming
    any walk path would be a lie. The empty-projection site cannot
    reach this branch in current code (UNDETECTED short-circuits before
    the redactor at the orchestrator's mode-not-detected guard), but
    the branch exists as defense-in-depth: any future caller that
    constructs an UNDETECTED rationale via this helper still gets
    honest text, not a fabricated walk.
    """
    if mode == EvidenceMode.EARLY_FAILURE:
        return "data.run_steps[-1] or data"
    if mode == EvidenceMode.ARTIFACT_PROJECTION:
        return "data.failed_steps[0].results[0]"
    # EvidenceMode.UNDETECTED (and any future enum value reaching this
    # function): no walk path exists.
    return "(no walk — evidence mode not detected)"


def _unknown(
    *,
    rationale: str,
    outcome: Outcome,
    evidence_mode: EvidenceMode,
) -> RCARecord:
    """Build an UNKNOWN-classification RCARecord. Schema Rule 3 forces
    confidence=None and requires_human_review=True.

    ``evidence_mode`` is REQUIRED (no default). Component 3 (Gap-B
    propagation) removed the ``EARLY_FAILURE`` default so every call
    site must explicitly pass the mode in scope at that point. The
    role-correct mode per §4.7 row mapping:

      row 1 (mode-not-detected)              → ``EvidenceMode.UNDETECTED``
      rows 2/3 (sentinel-fired / fail-open)  → detected ``mode``
      rows 4/5/6 (empty / no-match / multi)  → detected ``mode``

    The hardcoded default would silently mis-tag ARTIFACT_PROJECTION
    runs as EARLY_FAILURE if any new call site forgot to pass it; the
    required-kwarg discipline makes that impossible.
    """
    return RCARecord(
        classification=Classification.UNKNOWN,
        confidence=None,
        suggested_action=None,
        requires_human_review=True,
        rationale=rationale,
        evidence_mode=evidence_mode,
        outcome=outcome,
    )


def _classified(match: PatternMatch, evidence_mode: EvidenceMode) -> RCARecord:
    """Build a CLASSIFIED RCARecord from a single PatternMatch.

    Iron Rule (test_failure ⟹ root_cause_investigation_required=True
    AND suggested_action ≠ MODIFY_TEST) is already pre-validated at
    catalog load. RCARecord._enforce_invariants re-checks Rule 2 as
    defense in depth.

    ``evidence_mode`` is the mode ``_detect_mode`` returned for the
    payload that produced this match — threaded through Component 3
    (Gap-B). The hardcoded ``EARLY_FAILURE`` literal that lived here
    pre-C3 was a lie about provenance for ARTIFACT_PROJECTION runs.
    """
    rationale = (
        f"pattern_id={match.pattern_id} "
        f"sub_class={match.sub_class} "
        f"provenance={match.provenance.source_type}:{match.provenance.citation}"
    )
    return RCARecord(
        classification=match.classification,
        confidence=match.confidence_baseline,
        suggested_action=match.suggested_action,
        requires_human_review=match.root_cause_investigation_required,
        rationale=rationale,
        evidence_mode=evidence_mode,
        outcome=Outcome.CLASSIFIED,
    )


# ---------------------------------------------------------------------------
# Public entrypoint
# ---------------------------------------------------------------------------

def triage_failure(
    raw_payload: dict,
) -> tuple[RCARecord, RedactionResult | None, dict | None]:
    """Triage a raw dbt Cloud failure payload and emit a structured RCA.

    Returns a 3-tuple ``(rca, redaction, projection)`` per the C5 10-path
    table (Component-5 directive §5.2). The second and third elements are
    carried through so the writer can derive ``redaction_events``,
    ``evidence_json``, and ``error_signature_hash`` from the same artifacts
    the matcher consumed — NOT by re-running the redactor or re-projecting.

    Return shape per exit path (full table; row 0 raises, rows 8/9 propagate):

    ===  =========================  ============================
    Row  exit                       returned 3-tuple
    ===  =========================  ============================
    0    non-dict input             raises TypeError
    1    mode == UNDETECTED         (_unknown(...), None, None)
    2    CredentialSentinelFired    (_unknown(...), None, None)
    3    redactor fail-open         (_unknown(...), None, None)
    4    empty projection           (_unknown(...), redaction, {})
    5    no-match                   (_unknown(...), redaction, projection)
    6    multi-match                (_unknown(...), redaction, projection)
    7    classified                 (_classified(...), redaction, projection)
    8    uncaught Exception         PROPAGATES (wrapper's operational DLQ)
    9    uncaught BaseException     PROPAGATES (KeyboardInterrupt/SystemExit)
    ===  =========================  ============================

    Rows 1-3: ``redaction is None`` AND ``projection is None`` — the
    redactor either did not run or failed; writer records the RCARecord
    with ``redaction_events=0``, ``evidence_json=NULL``, ``hash=NULL``.

    Row 4: ``redaction is NOT None`` AND ``projection == {}`` — the
    redactor ran successfully but no eligible fields had content; writer
    records ``redaction_events`` from the redaction AND
    ``evidence_json = redaction.payload`` (the cleaned envelope) but
    ``hash = NULL`` (no field to sign — the writer's guard
    ``if projection`` falses on an empty dict).

    Rows 5-7: both populated — writer records redaction_events,
    evidence_json, AND hash (computed from the same projection the
    matcher consumed). The hash is computed in the writer (not here)
    because the projection-to-hash mapping is a writer concern; the
    orchestrator just hands over the artifacts.

    See module docstring for full boundary contract (R1-R8).
    """
    if not isinstance(raw_payload, dict):
        raise TypeError(
            f"triage_failure expects dict, got {type(raw_payload).__name__}"
        )

    mode = _detect_mode(raw_payload)
    if mode == EvidenceMode.UNDETECTED:
        # Row 1: no projection target exists — redactor never invoked.
        return (
            _unknown(
                rationale=(
                    "evidence-mode-not-detected: payload lacks data.run_steps "
                    "with at least one REGEX_ELIGIBLE field AND lacks "
                    "data.failed_steps[*].results[*] with a populated "
                    "REGEX_ELIGIBLE field. Neither EARLY_FAILURE nor "
                    "ARTIFACT_PROJECTION shape signalled — no projection "
                    "target exists."
                ),
                outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
                evidence_mode=EvidenceMode.UNDETECTED,
            ),
            None,
            None,
        )

    try:
        redaction = redact_early_failure(raw_payload)
    except CredentialSentinelFired as exc:
        # Row 2: sentinel fail-closed — redaction is intentionally
        # discarded (the partial redaction.payload may contain
        # un-sentinelled fragments by construction; v2-plan §1.8 +
        # credential-threat-model.md R2). evidence_json MUST be NULL.
        event = exc.event
        return (
            _unknown(
                rationale=(
                    f"credential_sentinel_fired: pattern={event.pattern_name} "
                    f"field_path={event.field_path} "
                    f"offset={event.offset} length={event.length}"
                ),
                outcome=Outcome.CREDENTIAL_SENTINEL_FIRED,
                evidence_mode=mode,
            ),
            None,
            None,
        )
    except Exception as exc:
        # Row 3: fail-open boundary (v2-plan §1.8 stateless fail-open).
        # ──────────────────────────────────────────────────────────────────
        # Catches `Exception`, NOT `BaseException` — so KeyboardInterrupt
        # and SystemExit propagate (locked by
        # TestRedactorFailOpen::test_keyboard_interrupt_propagates). The
        # CredentialSentinelFired handler above runs first by class
        # precedence, so a real sentinel never reaches this branch (locked
        # by test_credential_sentinel_still_wins).
        #
        # Rationale carries `exc_type` ONLY — never `str(exc)`. The
        # exception message on this path is un-sentinel-checked content by
        # construction (the redactor's credential guarantees do not hold
        # for exceptions raised before/around the sentinel pass), so
        # `str(exc)` may carry raw input fragments. A char cap is not a
        # credential mitigation (a 200-char credential is still a leaked
        # credential). Locked by test_no_credential_substring_in_any_field.
        #
        # Application log uses `logger.error` NOT `logger.exception` —
        # `logger.exception` would emit the traceback, and the traceback
        # includes `str(exc)`. Same trust-boundary posture applied to
        # both rationale and log; routing the leak from one boundary to
        # another is not a mitigation. Phase-2 error-store channel will
        # carry the debug detail; sprint-1-deferred.md #23 (deferred
        # Test 5 — caplog record.exc_info is None) locks the log contract
        # once that channel firms up. DO NOT FLIP `error` → `exception`
        # to "improve debuggability" — see entry-4 *Credential-safety
        # design* in phase-1-exit-checklist.md.
        #
        # This handler is the canonical inline expression for
        # docs/triage-agent/credential-threat-model.md R2. The three
        # rejected intuitions above (channel-routing, truncation-before-
        # scan, char-caps) are reasoned in full here because the
        # code-side context is where future maintainers look first.
        # The threat model is the centralized authority; this is the
        # worked example it cites.
        #
        # Writer-side: evidence_json MUST be NULL (no trustworthy
        # redaction artifact exists — redactor crashed). 10-path row 3.
        exc_type = type(exc).__name__
        logger.error("redactor_fail_open exc_type=%s", exc_type)
        return (
            _unknown(
                rationale=f"redactor_fail_open: exc_type={exc_type}",
                outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
                evidence_mode=mode,
            ),
            None,
            None,
        )

    projection: dict[str, str]
    if mode == EvidenceMode.ARTIFACT_PROJECTION:
        projection = _project_artifact_payload(redaction.payload)
    else:
        # EvidenceMode.EARLY_FAILURE is the only other shape _detect_mode
        # returns today (UNDETECTED is handled before the redactor call
        # above). A future mode (e.g., EvidenceMode.ARTIFACT once the
        # full-artifact path is built) would fall through to here and
        # produce an empty projection → row-4 _unknown — a safe fallback,
        # not a crash. C1.5 spec §4.2 Q1 LOCKED.
        projection = _project_payload(redaction.payload)
    if not projection:
        # Row 4: redaction ran cleanly but no eligible fields had content.
        # Carry the (now-empty) projection dict through — writer's
        # `if projection` guard will short-circuit to hash=NULL, but
        # redaction.payload is still recorded as evidence_json. This
        # preserves the "the redactor saw this envelope and found
        # nothing matchable" signal — distinct from rows 1-3 where the
        # redactor never produced an envelope.
        return (
            _unknown(
                rationale=(
                    "no extractable eligible fields: redacted payload has "
                    f"no REGEX_ELIGIBLE content under {_evidence_source_phrase(mode)}"
                ),
                outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
                evidence_mode=mode,
            ),
            redaction,
            projection,
        )

    matches = _MATCHER.match_all(projection)
    if not matches:
        # Row 5: projection present, no pattern matched.
        return (
            _unknown(
                rationale=(
                    "no catalog pattern matched the projected signal "
                    f"(eligible fields populated: {sorted(projection.keys())})"
                ),
                outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
                evidence_mode=mode,
            ),
            redaction,
            projection,
        )

    if len(matches) >= 2:
        # Row 6: multi-match deferred to humans.
        ids = sorted(m.pattern_id for m in matches)
        return (
            _unknown(
                rationale=(
                    f"multi-pattern match deferred (matched: {ids}); "
                    "resolution policy pending real co-fire evidence"
                ),
                outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
                evidence_mode=mode,
            ),
            redaction,
            projection,
        )

    # Row 7: single match → CLASSIFIED.
    return (_classified(matches[0], mode), redaction, projection)
