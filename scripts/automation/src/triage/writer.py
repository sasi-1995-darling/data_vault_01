"""TRIAGE_INVOCATIONS writer — C5 (LIVE consumer of the redaction packet).

Single public class:

    TriageWriter(cursor).write(
        rca, redaction, projection,
        *, run_id, job_id, environment_id, unique_id, git_sha,
    ) -> invocation_id

The writer is the FIRST live persistence sink for the
``(rca, redaction, projection)`` 3-tuple emitted by
``failure_triage_agent.triage_failure``. It owns the projection-to-hash
derivation, the COALESCE-MERGE idempotency contract, and the Flag-1
canonical serialization for ``evidence_mode``.

Boundary contract (asserted in test_triage_writer.py):

  * **Post-redact contract** — writer NEVER calls the redactor.
    Statically: this module does not import ``redact_early_failure``,
    ``redact_artifact``, or any redactor entrypoint (grep-checkable).
    Dynamically: a credential-shaped canary planted in
    ``redaction.payload`` is preserved verbatim in the bound
    ``evidence_json`` param. The writer is a persistence sink, not a
    redactor — re-running the redactor here would silently double-cost
    every write AND mask a redactor bug (if the upstream redactor
    missed a credential, the writer's second pass would catch it and
    the leak would never surface in tests).

  * **Flag-1 enforcement** — ``evidence_mode`` is DDL-bound as
    ``VARCHAR(32)``. On Python 3.14 ``str(EvidenceMode.ARTIFACT_PROJECTION)``
    and ``f"{EvidenceMode.ARTIFACT_PROJECTION}"`` BOTH return the
    35-char ``'EvidenceMode.ARTIFACT_PROJECTION'`` — wrong value AND
    column-overflow. Only ``.value`` returns the canonical
    ``'artifact_projection'``. The single chokepoint is
    ``_serialize_evidence_mode``; every cursor-bound ``evidence_mode``
    value goes through it. A sentinel-reaches-DDL test monkeypatches
    ``EvidenceMode.X._value_`` to a recognizable sentinel and asserts
    the sentinel reaches the bound param — this proves USAGE of
    ``.value`` end-to-end, would fail under f-string serialization.

  * **I4 invariant** — ``set(SIGNATURE_FIELDS) == REGEX_ELIGIBLE_FIELDS``
    at module import. If a future allowlist expansion (item #16,
    ``debug_logs``) lands in ``redact.REGEX_ELIGIBLE_FIELDS`` without
    a matching ``SIGNATURE_FIELDS`` entry, the writer module fails to
    import. The maintainer is forced to make an explicit priority
    decision (where in the priority tuple does the new field go?).

  * **COALESCE-MERGE idempotency** — dbt-Cloud envelopes with no
    ``unique_id`` (``unique_id IS NULL``) must still dedup correctly
    on retry. ``NULL = NULL`` is FALSE in SQL, so the MERGE's ON
    clause uses ``COALESCE(unique_id, '__NO_NODE__')`` on BOTH sides.
    Dropping the COALESCE (or applying it to only one side) would
    INSERT a duplicate row on every retry of a NULL-unique_id envelope.

  * **DDL contracts** — VARCHAR widths match the DDL exactly:
    ``invocation_id VARCHAR(26)`` (ULID), ``error_signature_hash
    VARCHAR(16)`` (xxh64 hex), ``evidence_mode VARCHAR(32)``,
    ``classification VARCHAR(64)``, ``suggested_action VARCHAR(64)``,
    ``outcome VARCHAR(64)``, ``schema_version VARCHAR(16)``,
    ``rationale VARCHAR(2000)``. Pydantic's ``RCARecord`` enforces
    ``rationale max_length=2000``; the rest are bounded by enum
    membership.

  * **created_at** — DDL has ``DEFAULT SYSDATE()``. The writer does
    NOT supply ``created_at`` in the bound params; Snowflake assigns
    the server timestamp at INSERT. This keeps wall-clock time
    consistent with the DB's view and avoids cross-host clock drift
    affecting the audit trail.

  * **VARIANT NULL** — ``evidence_json`` is bound via ``PARSE_JSON(%s)``.
    When ``redaction is None`` (rows 1-3), the param is ``None`` →
    SQL ``NULL`` → ``PARSE_JSON(NULL)`` → VARIANT NULL. No coercion to
    empty object ``{}`` (which would be semantically different —
    "redactor ran and produced an empty envelope" vs "redactor never
    ran").

Wiring: ``TriageWriter`` takes a DB-API 2.0 ``cursor`` in its
constructor. Tests inject a ``FakeCursor`` that records executions;
production code passes a snowflake-connector-python cursor. Commit /
rollback is the caller's concern (autocommit is the snowflake-connector
default; C6 may wrap multi-envelope writes in an explicit transaction
when latency matters).
"""

from __future__ import annotations

from __future__ import annotations

import json
import logging
from typing import Any, Callable, Optional

import xxhash
from ulid import ULID

from scripts.automation.src.triage.failure_triage_agent import triage_failure
from scripts.automation.src.triage.rca_schema import (
    EvidenceMode,
    Outcome,
    RCARecord,
    SCHEMA_VERSION,
)
from scripts.automation.src.triage.redact import (
    REGEX_ELIGIBLE_FIELDS,
    RedactionResult,
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Module constants — fail-fast invariants asserted at import
# ---------------------------------------------------------------------------

#: Pre-model sentinel message emitted by the dbt-Cloud adapter when
#: ``run_results.json`` is unavailable for a pre-model failure. The
#: signature MUST skip this value because (a) it is constant across
#: every pre-model run and (b) hashing it would collide every pre-model
#: failure under a single ``error_signature_hash`` — defeating the
#: dedup/cluster purpose of the hash. See spec §4.7 H7.
SENTINEL_MSG = "run_results.json not available - returning logs"

#: Priority-ordered field list for ``_compute_signature``. First field
#: with a non-empty, non-sentinel value wins. Ordering matters:
#:   1. ``message`` — the matcher's primary signal (most specific)
#:   2. ``truncated_debug_logs`` — pre-model fallback (sentinel skipped)
#:   3. ``status_message`` — operational status (less specific)
#:   4. ``logs`` — raw log slab (least specific, often most volume)
#: Two pre-model runs with different ``truncated_debug_logs`` produce
#: DIFFERENT signatures (sentinel is skipped on the ``message`` field,
#: ``truncated_debug_logs`` is consulted next — and those differ across
#: runs). Locked by test_compute_signature_two_pre_model_runs_differ.
SIGNATURE_FIELDS = (
    "message",
    "truncated_debug_logs",
    "status_message",
    "logs",
)

#: COALESCE placeholder for NULL ``unique_id`` in the MERGE ON clause.
#: Constant-defined so the test can reference the same string the SQL
#: binds — drift between SQL and test would silently break the
#: idempotency contract (the test would assert against the wrong
#: placeholder and pass with a broken MERGE).
NO_NODE_PLACEHOLDER = "__NO_NODE__"

# I4 invariant — drift between SIGNATURE_FIELDS and REGEX_ELIGIBLE_FIELDS
# means the writer hashes a field the matcher cannot see (or fails to
# hash a field the matcher CAN see). Either way the
# matcher-vs-signature contract is broken. Fail at import, not at first
# write, so the failure surfaces in test collection BEFORE any
# production envelope is mis-hashed.
assert set(SIGNATURE_FIELDS) == REGEX_ELIGIBLE_FIELDS, (
    f"SIGNATURE_FIELDS membership must match REGEX_ELIGIBLE_FIELDS — "
    f"if REGEX_ELIGIBLE_FIELDS expands (e.g., spec item #16: debug_logs), "
    f"add the new field to SIGNATURE_FIELDS at a chosen priority position "
    f"AND update the priority-order doc on SIGNATURE_FIELDS. "
    f"Current SIGNATURE_FIELDS: {SIGNATURE_FIELDS}; "
    f"Current REGEX_ELIGIBLE_FIELDS: {sorted(REGEX_ELIGIBLE_FIELDS)}."
)


# ---------------------------------------------------------------------------
# Hash + serialization helpers
# ---------------------------------------------------------------------------

def _compute_signature(projection: dict[str, str]) -> Optional[str]:
    """Compute ``error_signature_hash`` from the matcher's projection.

    Priority-fallback over ``SIGNATURE_FIELDS``: first field with a
    non-empty value wins, EXCEPT the ``message`` field is skipped if
    its value equals ``SENTINEL_MSG`` (the pre-model sentinel). This
    skip ensures that for pre-model failures (where the adapter emits
    the sentinel as ``message``), the signature is derived from
    ``truncated_debug_logs`` instead — giving each pre-model run its
    own signature instead of collapsing them all under a single hash.

    Returns:
        16-char xxh64 hex digest if any eligible field has content;
        ``None`` if no field is populated (projection is empty or all
        candidates are empty/sentinel). The DDL column allows NULL.

    Why xxh64 and not blake2b: spec-mandated by v2-plan §4.7. The
    algorithm choice is recorded in the DDL column comment for
    read-side verifiability (a downstream consumer that needs to
    reverse-engineer or recompute a hash knows which algorithm to
    use). 16 hex chars = 64 bits; collision risk acceptable for the
    invocation-grouping use case (DDL is VARCHAR(16) NULL — collision
    behavior is not "wrong row" because run_id+unique_id is the
    primary dedup key in the MERGE).
    """
    for field in SIGNATURE_FIELDS:
        value = projection.get(field)
        if value and not (field == "message" and value == SENTINEL_MSG):
            return xxhash.xxh64(value).hexdigest()[:16]
    return None


def _serialize_evidence_mode(mode: EvidenceMode) -> str:
    """Flag-1 single chokepoint — DDL-bound serialization MUST go through here.

    Returns ``mode.value`` (e.g., ``'artifact_projection'``), NEVER
    ``str(mode)`` or ``f"{mode}"`` (which on Py 3.14 return the
    35-char ``'EvidenceMode.<NAME>'`` — wrong value AND overflows
    ``VARCHAR(32)``).

    Every cursor-bound ``evidence_mode`` value in this module MUST go
    through this function. The sentinel-reaches-DDL test patches
    ``EvidenceMode.X._value_`` to a recognizable string and asserts
    the patched string reaches the cursor's bound params — this proves
    USAGE of ``.value`` end-to-end (it would fail under f-string
    serialization because ``str(m)`` ignores the patched ``_value_``).
    """
    return mode.value


def _serialize_classification(rca: RCARecord) -> str:
    """Serialize ``rca.classification`` via ``.value`` (symmetry with
    Flag-1; the same pitfall applies to any (str, Enum) member)."""
    return rca.classification.value


def _serialize_outcome(rca: RCARecord) -> str:
    """Serialize ``rca.outcome`` via ``.value`` (Flag-1 symmetry)."""
    return rca.outcome.value


def _serialize_suggested_action(rca: RCARecord) -> Optional[str]:
    """Serialize ``rca.suggested_action`` via ``.value`` when present
    (Flag-1 symmetry); ``None`` passes through to SQL NULL."""
    if rca.suggested_action is None:
        return None
    return rca.suggested_action.value


def _serialize_evidence_json(redaction: Optional[RedactionResult]) -> Optional[str]:
    """Serialize ``redaction.payload`` to a JSON string for VARIANT binding.

    Returns ``None`` when ``redaction is None`` (rows 1-3 of the
    10-path table — the redactor never produced a trustworthy payload).
    The MERGE binds this value via ``PARSE_JSON(%s)``: ``None`` → SQL
    ``NULL`` → ``PARSE_JSON(NULL)`` → VARIANT NULL. Distinct from
    empty-object ``{}`` which would mean "redactor ran and produced
    nothing" (semantically wrong for rows 1-3).
    """
    if redaction is None:
        return None
    return json.dumps(redaction.payload)


# ---------------------------------------------------------------------------
# MERGE SQL — single canonical template
# ---------------------------------------------------------------------------

# pyformat (%(name)s) bindings — snowflake-connector-python default. Named
# bindings let ``no_node`` appear twice in the ON clause without duplicating
# the value in the params dict (clearer than positional %s).
#
# Why MERGE and not INSERT...ON CONFLICT: Snowflake does not support
# ``INSERT...ON CONFLICT``. MERGE is the canonical idempotent-write
# primitive. WHEN NOT MATCHED THEN INSERT is the only branch — we never
# UPDATE an existing TRIAGE_INVOCATIONS row (every retry of the same
# envelope is silently skipped, preserving the original invocation_id +
# created_at).
_MERGE_SQL = """
MERGE INTO OPS_PROD.LOGS.TRIAGE_INVOCATIONS tgt
USING (SELECT
    %(invocation_id)s          AS invocation_id,
    %(run_id)s                 AS run_id,
    %(job_id)s                 AS job_id,
    %(environment_id)s         AS environment_id,
    %(git_sha)s                AS git_sha,
    %(unique_id)s              AS unique_id,
    %(error_signature_hash)s   AS error_signature_hash,
    %(evidence_mode)s          AS evidence_mode,
    %(classification)s         AS classification,
    %(confidence)s             AS confidence,
    %(suggested_action)s       AS suggested_action,
    %(requires_human_review)s  AS requires_human_review,
    %(rationale)s              AS rationale,
    %(redaction_events)s       AS redaction_events,
    %(sentinel_fired)s         AS sentinel_fired,
    %(outcome)s                AS outcome,
    %(schema_version)s         AS schema_version,
    PARSE_JSON(%(evidence_json)s) AS evidence_json
) src
ON  src.run_id = tgt.run_id
AND COALESCE(src.unique_id, %(no_node)s) = COALESCE(tgt.unique_id, %(no_node)s)
WHEN NOT MATCHED THEN INSERT (
    invocation_id, run_id, job_id, environment_id, git_sha, unique_id,
    error_signature_hash, evidence_mode, classification, confidence,
    suggested_action, requires_human_review, rationale, redaction_events,
    sentinel_fired, outcome, schema_version, evidence_json
) VALUES (
    src.invocation_id, src.run_id, src.job_id, src.environment_id,
    src.git_sha, src.unique_id, src.error_signature_hash, src.evidence_mode,
    src.classification, src.confidence, src.suggested_action,
    src.requires_human_review, src.rationale, src.redaction_events,
    src.sentinel_fired, src.outcome, src.schema_version, src.evidence_json
)
""".strip()


# ---------------------------------------------------------------------------
# Writer
# ---------------------------------------------------------------------------

class TriageWriter:
    """Persist one triage invocation to ``OPS_PROD.LOGS.TRIAGE_INVOCATIONS``.

    Stateless writer — one ``TriageWriter`` instance can serve many
    writes against the same cursor. Tests inject a fake cursor;
    production wires a snowflake-connector cursor.
    """

    def __init__(self, cursor: Any) -> None:
        """
        Args:
            cursor: DB-API 2.0 cursor with ``.execute(sql, params)``
                where ``params`` is a dict (pyformat binding). The
                cursor's ``paramstyle`` MUST be ``pyformat`` (the
                snowflake-connector-python default). Commit/rollback
                is the caller's concern.
        """
        self._cursor = cursor

    def write(
        self,
        rca: RCARecord,
        redaction: Optional[RedactionResult],
        projection: Optional[dict[str, str]],
        *,
        run_id: int,
        job_id: int,
        environment_id: int,
        unique_id: Optional[str],
        git_sha: Optional[str],
    ) -> str:
        """Insert one TRIAGE_INVOCATIONS row (idempotent via MERGE).

        Args:
            rca: the RCARecord produced by ``triage_failure`` (element
                0 of its 3-tuple). NEVER None — ``triage_failure``
                always produces a record for any valid dict input.
            redaction: element 1 of the 3-tuple. ``None`` for rows 1-3
                of the 10-path table (UNDETECTED, sentinel-fired,
                fail-open); a RedactionResult for rows 4-7.
            projection: element 2 of the 3-tuple. ``None`` for rows
                1-3; ``{}`` (empty dict) for row 4; populated dict for
                rows 5-7.
            run_id: dbt-Cloud run id. REQUIRED keyword (no default) —
                the caller must source this from the dbt-Cloud API
                response context. Used as the primary dedup key in
                the MERGE.
            job_id: dbt-Cloud job id. REQUIRED keyword.
            environment_id: dbt-Cloud environment id. REQUIRED keyword.
            unique_id: dbt node unique_id (e.g.,
                ``model.project.dim_customer``). May be ``None`` for
                pre-model failures (no node selected yet). The MERGE
                ON clause uses ``COALESCE(unique_id, NO_NODE_PLACEHOLDER)``
                so NULL-unique_id envelopes still dedup correctly on
                retry.
            git_sha: 40-char git SHA. May be ``None`` if the dbt-Cloud
                response lacks SHA context.

        Returns:
            The 26-char ULID invocation_id assigned at write time.
            Returned for caller-side logging/tracing (the C6 loop may
            log "wrote invocation_id=X for run_id=Y"). On a duplicate
            MERGE (envelope retried), the returned invocation_id is
            the one ATTEMPTED by this call — NOT the pre-existing
            row's invocation_id. Caller should treat the return value
            as "the id this write would have used if it inserted";
            for "the canonical id for this run_id+unique_id" the
            caller must SELECT from TRIAGE_INVOCATIONS.

        Does NOT raise on duplicate; the MERGE silently skips when
        matched. Raises whatever the cursor raises on connection
        errors / SQL errors — operational concern, propagated to the
        wrapper's row-8 dead-letter routing.
        """
        invocation_id = str(ULID())

        # Projection-to-hash: empty dict and None both → no signature.
        # The ``if projection`` guard short-circuits BEFORE calling
        # ``_compute_signature(None)`` (which would AttributeError on
        # the .get call). Mutation C (signature does not skip sentinel)
        # is detected by test_compute_signature_two_pre_model_runs_differ.
        error_signature_hash = (
            _compute_signature(projection) if projection else None
        )

        # Sentinel-fired flag derives from outcome (the marker for row 2).
        # No new RCARecord field needed — outcome is already the
        # 1:1 indicator for the sentinel path.
        sentinel_fired = (rca.outcome == Outcome.CREDENTIAL_SENTINEL_FIRED)

        # Redaction-events count: 0 when no redaction ran (rows 1-3).
        redaction_events = (
            redaction.redaction_events if redaction is not None else 0
        )

        params = {
            "invocation_id": invocation_id,
            "run_id": run_id,
            "job_id": job_id,
            "environment_id": environment_id,
            "git_sha": git_sha,
            "unique_id": unique_id,
            "error_signature_hash": error_signature_hash,
            # Flag-1 chokepoint — DDL-bound evidence_mode goes through
            # _serialize_evidence_mode (which calls .value, NOT str/f-string).
            "evidence_mode": _serialize_evidence_mode(rca.evidence_mode),
            "classification": _serialize_classification(rca),
            "confidence": rca.confidence,
            "suggested_action": _serialize_suggested_action(rca),
            "requires_human_review": rca.requires_human_review,
            "rationale": rca.rationale,
            "redaction_events": redaction_events,
            "sentinel_fired": sentinel_fired,
            "outcome": _serialize_outcome(rca),
            "schema_version": SCHEMA_VERSION,
            "evidence_json": _serialize_evidence_json(redaction),
            "no_node": NO_NODE_PLACEHOLDER,
        }

        self._cursor.execute(_MERGE_SQL, params)
        return invocation_id


# ---------------------------------------------------------------------------
# Orchestrator wrapper — three-dead-letter contract
# ---------------------------------------------------------------------------

def process_envelope(
    envelope: Any,
    writer: TriageWriter,
    *,
    run_id: int,
    job_id: int,
    environment_id: int,
    unique_id: Optional[str],
    git_sha: Optional[str],
    on_malformed_input: Callable[[Any, BaseException], None],
    on_operational_error: Callable[[Any, BaseException], None],
) -> Optional[str]:
    """Triage one envelope and persist; route exceptions to dead-letters.

    Three-dead-letter contract (spec §4.9 + Component-5 directive §5.7):

      * **Row 0 — TypeError** (adapter contract violation): envelope
        is not a dict. Routed to ``on_malformed_input(envelope, exc)``.
        Does NOT call the writer. Returns None.

      * **Row 8 — Exception** (internal helper bug): any other
        Exception raised by ``triage_failure`` or ``writer.write``.
        Routed to ``on_operational_error(envelope, exc)``. The poll
        loop advances its cursor and SURVIVES — one bad envelope
        cannot stall the entire backlog.

      * **Row 9 — BaseException** (KeyboardInterrupt, SystemExit,
        GeneratorExit): NOT caught. Propagates to the caller. DO NOT
        add ``except BaseException`` here — Ctrl+C must terminate the
        process; routing it to a dead-letter would silently survive
        an operator's explicit shutdown request and log "operational
        error: KeyboardInterrupt" forever.

    The three dead-letters are intentionally DISTINCT (malformed-input
    vs operational vs the §4.9 MCP-failure that C6 owns). Conflating
    them muddies the operational signal:

      * malformed-input → adapter contract bug (fix the adapter)
      * operational     → internal helper bug (fix the helper)
      * MCP-failure     → upstream Snowflake / API outage (page on-call)

    Each routes to a different remediation owner; a single "errors"
    bucket would force on-call to triage-the-triage every time.

    Args:
        envelope: the dbt-Cloud failure payload (expected dict; row 0
            triggers if not).
        writer: a TriageWriter instance (already bound to a cursor).
        run_id, job_id, environment_id, unique_id, git_sha: passed
            through to ``writer.write`` on the success path. Required
            keyword args — no defaults (matches writer.write's contract).
        on_malformed_input: ``Callable[[envelope, exc], None]`` —
            invoked when triage_failure raises TypeError. Receives
            the original envelope + the TypeError instance. C6 wires
            this to a malformed-input dead-letter sink (DB table or
            log channel; C6's choice).
        on_operational_error: ``Callable[[envelope, exc], None]`` —
            invoked when triage_failure or writer.write raises a
            non-TypeError Exception. C6 wires this to an operational
            dead-letter sink.

    Returns:
        The invocation_id (ULID) from ``writer.write`` on success;
        ``None`` on either dead-letter path. Returning None lets the
        C6 loop distinguish "wrote successfully" from "routed to
        dead-letter" without inspecting the dead-letter sinks.
    """
    try:
        rca, redaction, projection = triage_failure(envelope)
    except TypeError as exc:
        # Row 0 — adapter contract violation. The envelope is not a
        # dict; we cannot triage it. Log + route + DO NOT call the
        # writer (no RCARecord exists).
        logger.warning(
            "triage_malformed_input exc_type=TypeError"
        )
        on_malformed_input(envelope, exc)
        return None
    except Exception as exc:  # noqa: BLE001 — three-dead-letter contract
        # Row 8 — internal helper bug. triage_failure should NOT raise
        # non-TypeError exceptions on a valid dict (it has its own
        # fail-open boundary for the redactor). If we land here, one
        # of the helpers (matcher, projector, _classified) raised.
        # Log helper class name + exception class, route, SURVIVE.
        logger.error(
            "triage_operational_error exc_type=%s",
            type(exc).__name__,
        )
        on_operational_error(envelope, exc)
        return None
    # Row 9 — BaseException: intentionally NOT caught.

    try:
        return writer.write(
            rca,
            redaction,
            projection,
            run_id=run_id,
            job_id=job_id,
            environment_id=environment_id,
            unique_id=unique_id,
            git_sha=git_sha,
        )
    except Exception as exc:  # noqa: BLE001 — writer-side row 8
        # Row 8 also covers writer-side operational errors (Snowflake
        # connection drop, malformed MERGE, etc.). Same routing as the
        # triage_failure operational branch.
        logger.error(
            "writer_operational_error exc_type=%s",
            type(exc).__name__,
        )
        on_operational_error(envelope, exc)
        return None
    # Row 9 — BaseException from writer: intentionally NOT caught.
