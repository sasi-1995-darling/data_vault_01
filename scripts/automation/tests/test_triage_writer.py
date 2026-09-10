"""C5 — TRIAGE_INVOCATIONS writer tests.

Test surface (organized by concern):

  * TestComputeSignature           — G1+H7 hash priority + sentinel skip
  * TestI4InvariantSignatureFields — SIGNATURE_FIELDS / REGEX_ELIGIBLE_FIELDS drift
  * TestSerializeEvidenceModeFlag1 — load-bearing Flag-1 sentinel-reaches-DDL
  * TestSerializeHelpers           — symmetry checks for classification/outcome/suggested_action/evidence_json
  * TestWriterTenPathTable         — rows 1-7 of the 10-path return table (writer-side)
  * TestWriterMergeIdempotency     — COALESCE-on-both-sides + NO_NODE_PLACEHOLDER constant
  * TestWriterPostRedactContract   — writer does NOT re-run redactor (canary preserved verbatim + static grep)
  * TestWriterRequiredKwargs       — REQUIRED keyword-only dbt-Cloud ids (no defaults)
  * TestWriterReturnValue          — invocation_id is a 26-char ULID, unique per call
  * TestProcessEnvelopeWrapper     — three-dead-letter contract (rows 0, 8, 9)
  * TestUnknownRowsPersistFaithfully — coverage-reality: all 4 UNKNOWN paths persist

Mutation defeats (verified offline by the byte-review):

  * A: writer serializes via f"{mode}" instead of .value
       → TestSerializeEvidenceModeFlag1::test_sentinel_reaches_ddl RED
  * B: MERGE ON drops COALESCE / applies to only one side
       → TestWriterMergeIdempotency::test_merge_sql_coalesces_unique_id_on_both_sides RED
  * C: _compute_signature does NOT skip the sentinel
       → TestComputeSignature::test_two_pre_model_runs_with_different_logs_differ RED
  * D: writer re-imports/calls a redactor entrypoint
       → TestWriterPostRedactContract::test_writer_module_does_not_import_redactor_entrypoints RED
         + TestWriterPostRedactContract::test_canary_preserved_verbatim_through_writer RED
  * E: row-1/2/3 guard removed (no `if redaction is not None`)
       → TestWriterTenPathTable::test_row_1_undetected_evidence_json_is_null
         + test_row_2_sentinel_fired_evidence_json_is_null RED (writer would AttributeError on None.payload)
"""

from __future__ import annotations

import importlib
import json
import re
import sys
from contextlib import contextmanager
from typing import Any, Optional

import pytest

from scripts.automation.src.triage.rca_schema import (
    Classification,
    EvidenceMode,
    Outcome,
    RCARecord,
    SCHEMA_VERSION,
    SuggestedAction,
)
from scripts.automation.src.triage.redact import (
    REGEX_ELIGIBLE_FIELDS,
    RedactionResult,
)
from scripts.automation.src.triage import writer as writer_module
from scripts.automation.src.triage.writer import (
    NO_NODE_PLACEHOLDER,
    SENTINEL_MSG,
    SIGNATURE_FIELDS,
    TriageWriter,
    _compute_signature,
    _serialize_classification,
    _serialize_evidence_json,
    _serialize_evidence_mode,
    _serialize_outcome,
    _serialize_suggested_action,
    process_envelope,
)


# ---------------------------------------------------------------------------
# Test scaffolding
# ---------------------------------------------------------------------------

class FakeCursor:
    """DB-API 2.0 minimal cursor that records ``.execute`` calls.

    Use ``raise_on_execute`` to simulate writer-side operational
    errors (test_row_8_writer_exception_routes_to_operational).
    """

    def __init__(self, raise_on_execute: Optional[BaseException] = None) -> None:
        self.executions: list[tuple[str, dict]] = []
        self._raise = raise_on_execute

    def execute(self, sql: str, params: dict) -> None:
        if self._raise is not None:
            raise self._raise
        # Snapshot params (defensive copy — writer.py builds a new dict
        # each call, but a future refactor could reuse a dict and
        # mutate; defensive copy keeps the test contract local).
        self.executions.append((sql, dict(params)))

    @property
    def last_params(self) -> dict:
        assert self.executions, "no execute() calls recorded"
        return self.executions[-1][1]

    @property
    def last_sql(self) -> str:
        assert self.executions, "no execute() calls recorded"
        return self.executions[-1][0]


def make_rca(
    *,
    classification: Classification = Classification.UNKNOWN,
    evidence_mode: EvidenceMode = EvidenceMode.EARLY_FAILURE,
    outcome: Outcome = Outcome.UNKNOWN_HANDED_TO_HUMAN,
    confidence: Optional[float] = None,
    suggested_action: Optional[SuggestedAction] = None,
    requires_human_review: bool = True,
    rationale: Optional[str] = "test rationale",
) -> RCARecord:
    """Build an RCARecord with sensible defaults per evidence_mode.

    Defaults to the UNKNOWN_HANDED_TO_HUMAN outcome (most common in
    the 10-path table). Caller overrides per test as needed.
    """
    return RCARecord(
        classification=classification,
        confidence=confidence,
        suggested_action=suggested_action,
        requires_human_review=requires_human_review,
        rationale=rationale,
        evidence_mode=evidence_mode,
        outcome=outcome,
    )


def make_redaction(
    *,
    payload: Optional[dict] = None,
    redaction_events: int = 0,
) -> RedactionResult:
    """Build a RedactionResult with a default empty-envelope payload."""
    if payload is None:
        payload = {"data": {"run_steps": [{}]}}
    return RedactionResult(payload=payload, redaction_events=redaction_events)


@contextmanager
def patched_enum_value(member, sentinel: str):
    """Context manager: monkeypatch an enum member's ``_value_`` and restore.

    Uses ``object.__setattr__`` because ``Enum`` blocks normal
    ``setattr`` on members. Always restores in ``finally``, even if
    the test body raises — leaking a patched enum across tests would
    poison every downstream test that touches that member.
    """
    original = member._value_
    try:
        object.__setattr__(member, "_value_", sentinel)
        yield
    finally:
        object.__setattr__(member, "_value_", original)


# ---------------------------------------------------------------------------
# _compute_signature — G1+H7 (priority + sentinel skip)
# ---------------------------------------------------------------------------

class TestComputeSignature:
    """Hash priority-fallback + pre-model sentinel skip."""

    def test_empty_projection_returns_none(self):
        assert _compute_signature({}) is None

    def test_message_present_returns_xxh64_16_hex(self):
        result = _compute_signature({"message": "boom"})
        assert result is not None
        assert len(result) == 16
        # xxh64 hex chars
        assert re.fullmatch(r"[0-9a-f]{16}", result)

    def test_same_input_same_hash_deterministic(self):
        a = _compute_signature({"message": "x"})
        b = _compute_signature({"message": "x"})
        assert a == b

    def test_different_messages_different_hashes(self):
        a = _compute_signature({"message": "x"})
        b = _compute_signature({"message": "y"})
        assert a != b

    def test_priority_message_wins_over_status_message(self):
        from_message = _compute_signature({"message": "M"})
        from_status = _compute_signature({"status_message": "M"})
        priority = _compute_signature(
            {"message": "M", "status_message": "OTHER"}
        )
        # priority hashes the message (priority winner), not the status.
        assert priority == from_message
        # And the status-only hash is the same VALUE 'M' under
        # status_message field — same string, same xxh64 (xxh64 doesn't
        # care which field name produced the bytes).
        assert from_status == from_message

    def test_priority_full_chain_message_truncated_status_logs(self):
        # All four fields populated — message wins.
        all_fields = {
            "message": "ONE",
            "truncated_debug_logs": "TWO",
            "status_message": "THREE",
            "logs": "FOUR",
        }
        # Only-message gives same result as all-fields (priority winner).
        assert _compute_signature(all_fields) == _compute_signature(
            {"message": "ONE"}
        )

    # --- Sentinel skip (H7) — the load-bearing block ---------------------

    def test_sentinel_alone_returns_none_no_fallback(self):
        # ONLY the sentinel is present; no fallback fields → None.
        # Hashing the sentinel would cluster every pre-model failure
        # under a single hash (defeats the dedup purpose).
        assert _compute_signature({"message": SENTINEL_MSG}) is None

    def test_sentinel_with_truncated_debug_logs_uses_logs(self):
        sentinel_with_logs = _compute_signature({
            "message": SENTINEL_MSG,
            "truncated_debug_logs": "real pre-model error trace",
        })
        only_logs = _compute_signature({
            "truncated_debug_logs": "real pre-model error trace",
        })
        # Same hash — proves the sentinel-message was SKIPPED and
        # truncated_debug_logs was consulted instead.
        assert sentinel_with_logs == only_logs
        assert sentinel_with_logs is not None

    def test_two_pre_model_runs_with_different_logs_differ(self):
        """MUTATION C DEFEATER — if _compute_signature did NOT skip the
        sentinel, both runs below would collapse to the same hash
        (xxh64 of the SENTINEL_MSG string). Skipping the sentinel
        forces the priority chain to consult truncated_debug_logs,
        which differs between the runs → different hashes."""
        run_a = _compute_signature({
            "message": SENTINEL_MSG,
            "truncated_debug_logs": "stack trace from run A",
        })
        run_b = _compute_signature({
            "message": SENTINEL_MSG,
            "truncated_debug_logs": "stack trace from run B",
        })
        assert run_a is not None and run_b is not None
        assert run_a != run_b, (
            "Pre-model sentinel skip is broken — two distinct pre-model "
            "runs collapsed to the same signature. Check that "
            "_compute_signature skips SENTINEL_MSG when field=='message' "
            "and falls through to truncated_debug_logs."
        )

    def test_sentinel_skip_only_applies_to_message_field(self):
        # The skip is anchored on field == 'message'. If the sentinel
        # string appears in truncated_debug_logs (unlikely but possible),
        # it should NOT be skipped — the field anchoring matters.
        result = _compute_signature({"truncated_debug_logs": SENTINEL_MSG})
        assert result is not None  # Would be None if skip leaked to other fields

    def test_empty_string_value_treated_as_absent(self):
        # Empty string is falsy in the priority chain; falls through.
        result = _compute_signature({"message": "", "status_message": "real"})
        assert result == _compute_signature({"status_message": "real"})


# ---------------------------------------------------------------------------
# I4 invariant — SIGNATURE_FIELDS vs REGEX_ELIGIBLE_FIELDS drift
# ---------------------------------------------------------------------------

class TestI4InvariantSignatureFields:
    """Drift between SIGNATURE_FIELDS and REGEX_ELIGIBLE_FIELDS fails
    at module import — caught in test collection, not at runtime."""

    def test_invariant_holds_at_module_load(self):
        # If the writer module imported, the assertion held.
        assert set(SIGNATURE_FIELDS) == REGEX_ELIGIBLE_FIELDS

    def test_signature_fields_is_a_tuple_not_a_set(self):
        # Tuple preserves PRIORITY ORDER (set would not). Priority is
        # semantically meaningful — message > truncated_debug_logs > ...
        assert isinstance(SIGNATURE_FIELDS, tuple)

    def test_invariant_fires_on_drift_simulated_via_reimport(self, monkeypatch):
        """Simulate REGEX_ELIGIBLE_FIELDS expanding without
        SIGNATURE_FIELDS being updated — re-import writer should
        AssertionError. Catches future maintainers who add to the
        allowlist (item #16, debug_logs) but forget to choose a
        priority slot for the new field."""
        import scripts.automation.src.triage.redact as redact_mod

        # Patch REGEX_ELIGIBLE_FIELDS to include a hypothetical new field
        # that SIGNATURE_FIELDS lacks.
        drifted = frozenset(REGEX_ELIGIBLE_FIELDS | {"debug_logs"})
        monkeypatch.setattr(redact_mod, "REGEX_ELIGIBLE_FIELDS", drifted)

        # Drop the cached writer module so re-import re-evaluates the
        # module-level assert.
        sys.modules.pop("scripts.automation.src.triage.writer", None)
        with pytest.raises(AssertionError, match="SIGNATURE_FIELDS"):
            importlib.import_module("scripts.automation.src.triage.writer")

        # Un-patch BEFORE re-importing the real writer module —
        # otherwise the restoration re-import would itself fire the
        # assertion (REGEX_ELIGIBLE_FIELDS is still drifted at this
        # point; monkeypatch's auto-teardown only fires after the test
        # function returns).
        monkeypatch.undo()
        sys.modules.pop("scripts.automation.src.triage.writer", None)
        importlib.import_module("scripts.automation.src.triage.writer")


# ---------------------------------------------------------------------------
# Flag-1 — evidence_mode serialization chokepoint
# ---------------------------------------------------------------------------

class TestSerializeEvidenceModeFlag1:
    """The load-bearing test in C5. Proves the writer's
    ``evidence_mode`` serialization goes through ``.value``, not
    ``str()`` / ``f-string`` (which on Py 3.14 return the 35-char
    ``'EvidenceMode.<NAME>'`` — wrong DDL value AND VARCHAR(32)
    overflow)."""

    def test_serializer_returns_value_attribute(self):
        # Baseline — no patch.
        assert (
            _serialize_evidence_mode(EvidenceMode.ARTIFACT_PROJECTION)
            == "artifact_projection"
        )
        assert (
            _serialize_evidence_mode(EvidenceMode.EARLY_FAILURE)
            == "early_failure"
        )
        assert (
            _serialize_evidence_mode(EvidenceMode.ARTIFACT)
            == "artifact"
        )
        assert (
            _serialize_evidence_mode(EvidenceMode.UNDETECTED)
            == "undetected"
        )

    def test_py314_finding_documented_str_returns_wrong_name(self):
        """Document the 3.14 hazard the writer protects against. If
        this test ever fails (Python changes (str, Enum) __str__
        behavior back), the Flag-1 protection might still be sound but
        the rationale needs revisiting."""
        m = EvidenceMode.ARTIFACT_PROJECTION
        assert str(m) == "EvidenceMode.ARTIFACT_PROJECTION"
        assert f"{m}" == "EvidenceMode.ARTIFACT_PROJECTION"
        assert m.value == "artifact_projection"
        # The two are NOT equal — the writer MUST pick the right one.
        assert str(m) != m.value

    def test_sentinel_reaches_ddl(self):
        """MUTATION A DEFEATER — the load-bearing Flag-1 enforcement test.

        Monkeypatch ``EvidenceMode.ARTIFACT_PROJECTION._value_`` to a
        recognizable sentinel string. Build an RCARecord, write it via
        the writer, and assert the patched sentinel reaches the
        cursor's bound ``evidence_mode`` param.

        Why this works:
          * Writer's chokepoint: ``_serialize_evidence_mode`` calls
            ``mode.value`` — returns the patched sentinel.
          * Mutation A (replace body with ``f"{mode}"``): f-string
            calls ``__format__`` → ``__str__`` → returns
            'EvidenceMode.ARTIFACT_PROJECTION', ignoring the patched
            ``_value_``. Bound param is the wrong string, test FAILS.

        This test would FAIL under mutation A. It is the single
        load-bearing read in Kumar's byte-review item 5.
        """
        sentinel = "SENTINEL_REACHES_DDL_xKpQ7rMz_evidence_mode"
        rca = make_rca(
            classification=Classification.UNKNOWN,
            evidence_mode=EvidenceMode.ARTIFACT_PROJECTION,
            outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
        )
        cursor = FakeCursor()
        wr = TriageWriter(cursor)

        with patched_enum_value(EvidenceMode.ARTIFACT_PROJECTION, sentinel):
            wr.write(
                rca,
                None,
                None,
                run_id=1,
                job_id=2,
                environment_id=3,
                unique_id=None,
                git_sha=None,
            )

        assert cursor.last_params["evidence_mode"] == sentinel, (
            f"Flag-1 violation: writer's evidence_mode serialization did "
            f"NOT go through .value. Bound param is "
            f"{cursor.last_params['evidence_mode']!r}; expected the "
            f"patched sentinel {sentinel!r}. On Py 3.14 this means the "
            f"writer is using str(mode) or f'{{mode}}' which produces "
            f"the 35-char 'EvidenceMode.<NAME>' string (wrong DDL value "
            f"AND overflows VARCHAR(32))."
        )

    def test_sentinel_restoration_after_test(self):
        # Run AFTER test_sentinel_reaches_ddl — assert the patch was
        # cleanly restored. Catches a leak that would poison every
        # downstream test in this session.
        assert (
            EvidenceMode.ARTIFACT_PROJECTION.value == "artifact_projection"
        )


# ---------------------------------------------------------------------------
# Other serializer helpers (Flag-1 symmetry)
# ---------------------------------------------------------------------------

class TestSerializeHelpers:
    """Symmetry: every (str, Enum) field in RCARecord serializes via
    .value. Same Py-3.14 pitfall, same chokepoint pattern."""

    def test_classification_via_value(self):
        rca = make_rca(classification=Classification.TEST_FAILURE)
        assert _serialize_classification(rca) == Classification.TEST_FAILURE.value

    def test_outcome_via_value(self):
        rca = make_rca(outcome=Outcome.CREDENTIAL_SENTINEL_FIRED)
        assert _serialize_outcome(rca) == "credential_sentinel_fired"

    def test_suggested_action_none_passes_through_as_none(self):
        rca = make_rca(suggested_action=None)
        assert _serialize_suggested_action(rca) is None

    def test_suggested_action_via_value_when_present(self):
        rca = make_rca(
            classification=Classification.PERMISSION_ERROR,
            suggested_action=SuggestedAction.ESCALATE_TO_HUMAN,
            confidence=0.9,
            requires_human_review=False,
        )
        assert (
            _serialize_suggested_action(rca)
            == SuggestedAction.ESCALATE_TO_HUMAN.value
        )

    def test_evidence_json_none_when_redaction_is_none(self):
        assert _serialize_evidence_json(None) is None

    def test_evidence_json_is_a_json_string(self):
        red = make_redaction(payload={"data": {"key": "value"}})
        result = _serialize_evidence_json(red)
        assert isinstance(result, str)
        # Round-trip
        assert json.loads(result) == {"data": {"key": "value"}}

    def test_evidence_json_distinguishes_none_from_empty(self):
        # Semantic distinction: None = "no redaction artifact" (rows
        # 1-3); empty dict = "redactor ran and produced empty" (theoretical).
        assert _serialize_evidence_json(None) is None
        assert _serialize_evidence_json(make_redaction(payload={})) == "{}"


# ---------------------------------------------------------------------------
# Writer — 10-path table (rows 1-7 are writer-side; 0, 8, 9 are wrapper-side)
# ---------------------------------------------------------------------------

class TestWriterTenPathTable:
    """Row-by-row coverage of the 10-path return table from the
    Component-5 directive §5.2. Rows 0, 8, 9 are wrapper-side and
    covered in TestProcessEnvelopeWrapper below."""

    def _build_and_write(
        self,
        rca: RCARecord,
        redaction: Optional[RedactionResult],
        projection: Optional[dict[str, str]],
        *,
        cursor: Optional[FakeCursor] = None,
        run_id: int = 12345,
        job_id: int = 678,
        environment_id: int = 9,
        unique_id: Optional[str] = "model.proj.dim_x",
        git_sha: Optional[str] = "a" * 40,
    ) -> tuple[FakeCursor, str]:
        cursor = cursor or FakeCursor()
        wr = TriageWriter(cursor)
        inv_id = wr.write(
            rca, redaction, projection,
            run_id=run_id, job_id=job_id, environment_id=environment_id,
            unique_id=unique_id, git_sha=git_sha,
        )
        return cursor, inv_id

    # --- Row 1: UNDETECTED -----------------------------------------------

    def test_row_1_undetected_evidence_json_is_null(self):
        rca = make_rca(
            classification=Classification.UNKNOWN,
            evidence_mode=EvidenceMode.UNDETECTED,
            outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
            rationale="evidence-mode-not-detected: ...",
        )
        cursor, _ = self._build_and_write(rca, None, None)
        params = cursor.last_params
        assert params["evidence_mode"] == "undetected"
        assert params["evidence_json"] is None
        assert params["error_signature_hash"] is None
        assert params["redaction_events"] == 0
        assert params["sentinel_fired"] is False
        assert params["outcome"] == "unknown_handed_to_human"

    # --- Row 2: CredentialSentinelFired ----------------------------------

    def test_row_2_sentinel_fired_evidence_json_is_null(self):
        rca = make_rca(
            classification=Classification.UNKNOWN,
            evidence_mode=EvidenceMode.EARLY_FAILURE,
            outcome=Outcome.CREDENTIAL_SENTINEL_FIRED,
            rationale="credential_sentinel_fired: pattern=jwt ...",
        )
        cursor, _ = self._build_and_write(rca, None, None)
        params = cursor.last_params
        # The sentinel_fired flag is derived from outcome — must be TRUE.
        assert params["sentinel_fired"] is True
        # Evidence intentionally discarded (per credential-threat-model R2).
        assert params["evidence_json"] is None
        assert params["error_signature_hash"] is None
        assert params["outcome"] == "credential_sentinel_fired"

    def test_row_2_sentinel_fired_flag_distinguishes_from_row_1(self):
        # Row 1 (UNDETECTED) and Row 2 (sentinel) BOTH have
        # classification=UNKNOWN and (None, None) for (redaction,
        # projection). The DISCRIMINATING column is sentinel_fired.
        rca_undetected = make_rca(
            evidence_mode=EvidenceMode.UNDETECTED,
            outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
        )
        rca_sentinel = make_rca(
            evidence_mode=EvidenceMode.EARLY_FAILURE,
            outcome=Outcome.CREDENTIAL_SENTINEL_FIRED,
        )
        cursor1, _ = self._build_and_write(rca_undetected, None, None)
        cursor2, _ = self._build_and_write(rca_sentinel, None, None)
        assert cursor1.last_params["sentinel_fired"] is False
        assert cursor2.last_params["sentinel_fired"] is True

    # --- Row 3: redactor fail-open ---------------------------------------

    def test_row_3_fail_open_evidence_json_is_null(self):
        rca = make_rca(
            classification=Classification.UNKNOWN,
            evidence_mode=EvidenceMode.EARLY_FAILURE,
            outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
            rationale="redactor_fail_open: exc_type=ValueError",
        )
        cursor, _ = self._build_and_write(rca, None, None)
        params = cursor.last_params
        assert params["evidence_json"] is None
        assert params["error_signature_hash"] is None
        # NOT a sentinel fire (outcome is UNKNOWN_HANDED_TO_HUMAN).
        assert params["sentinel_fired"] is False
        # NO redaction events (redactor crashed).
        assert params["redaction_events"] == 0

    # --- Row 4: empty projection -----------------------------------------

    def test_row_4_empty_projection_records_redaction_but_no_hash(self):
        # Redactor ran and produced an envelope, but no eligible fields
        # had content. evidence_json must be PRESENT (redaction.payload);
        # hash must be NULL (no field to sign).
        red = make_redaction(
            payload={"data": {"run_steps": [{}]}},
            redaction_events=3,
        )
        rca = make_rca(
            evidence_mode=EvidenceMode.EARLY_FAILURE,
            outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
        )
        cursor, _ = self._build_and_write(rca, red, {})
        params = cursor.last_params
        assert params["error_signature_hash"] is None  # empty projection
        assert params["evidence_json"] is not None  # redaction was preserved
        assert json.loads(params["evidence_json"]) == {
            "data": {"run_steps": [{}]}
        }
        assert params["redaction_events"] == 3

    # --- Row 5: no-match -------------------------------------------------

    def test_row_5_no_match_records_hash_and_evidence(self):
        red = make_redaction(
            payload={"data": {"run_steps": [{"message": "weird error"}]}},
            redaction_events=0,
        )
        rca = make_rca(
            classification=Classification.UNKNOWN,
            evidence_mode=EvidenceMode.EARLY_FAILURE,
            outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
            rationale="no catalog pattern matched ...",
        )
        cursor, _ = self._build_and_write(
            rca, red, {"message": "weird error"}
        )
        params = cursor.last_params
        assert params["error_signature_hash"] is not None
        assert len(params["error_signature_hash"]) == 16
        assert params["evidence_json"] is not None
        assert params["classification"] == "unknown"

    # --- Row 6: multi-match ----------------------------------------------

    def test_row_6_multi_match_records_hash_and_evidence(self):
        red = make_redaction(
            payload={"data": {"run_steps": [{"message": "M"}]}},
        )
        rca = make_rca(
            classification=Classification.UNKNOWN,
            evidence_mode=EvidenceMode.EARLY_FAILURE,
            outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
            rationale="multi-pattern match deferred (matched: [1, 2]) ...",
        )
        cursor, _ = self._build_and_write(rca, red, {"message": "M"})
        params = cursor.last_params
        assert params["error_signature_hash"] is not None
        assert params["evidence_json"] is not None
        # Still UNKNOWN — multi-match defers to humans.
        assert params["classification"] == "unknown"

    # --- Row 7: classified -----------------------------------------------

    def test_row_7_classified_records_all_fields(self):
        red = make_redaction(
            payload={"data": {"run_steps": [{"message": "permission denied"}]}},
        )
        rca = make_rca(
            classification=Classification.PERMISSION_ERROR,
            confidence=0.9,
            suggested_action=SuggestedAction.ESCALATE_TO_HUMAN,
            requires_human_review=False,
            evidence_mode=EvidenceMode.EARLY_FAILURE,
            outcome=Outcome.CLASSIFIED,
            rationale="match: permission_denied pattern",
        )
        cursor, _ = self._build_and_write(
            rca, red, {"message": "permission denied"}
        )
        params = cursor.last_params
        assert params["classification"] == "permission_error"
        assert params["confidence"] == 0.9
        assert params["suggested_action"] == "escalate_to_human"
        assert params["requires_human_review"] is False
        assert params["outcome"] == "classified"
        assert params["error_signature_hash"] is not None
        assert params["evidence_json"] is not None

    # --- Cross-cutting writer-side invariants ----------------------------

    def test_schema_version_always_pinned(self):
        rca = make_rca()
        cursor, _ = self._build_and_write(rca, None, None)
        assert cursor.last_params["schema_version"] == SCHEMA_VERSION

    def test_no_node_placeholder_in_every_write(self):
        # The MERGE binds NO_NODE_PLACEHOLDER for the COALESCE.
        rca = make_rca()
        cursor, _ = self._build_and_write(rca, None, None)
        assert cursor.last_params["no_node"] == NO_NODE_PLACEHOLDER

    def test_created_at_is_NOT_in_bound_params(self):
        # DDL has DEFAULT SYSDATE() — writer must not supply created_at.
        # Supplying it would override the DB default and risk
        # cross-host clock drift in the audit trail.
        rca = make_rca()
        cursor, _ = self._build_and_write(rca, None, None)
        assert "created_at" not in cursor.last_params


# ---------------------------------------------------------------------------
# MERGE idempotency — COALESCE on BOTH sides
# ---------------------------------------------------------------------------

class TestWriterMergeIdempotency:
    """The MERGE ON clause uses COALESCE(unique_id, NO_NODE_PLACEHOLDER)
    on BOTH src and tgt. Dropping the COALESCE (or applying to only
    one side) breaks NULL-unique_id dedup on retry."""

    def test_merge_sql_coalesces_unique_id_on_both_sides(self):
        """MUTATION B DEFEATER — proves the COALESCE appears on BOTH
        src.unique_id AND tgt.unique_id. Static check on the SQL
        template. Mutation B (drop COALESCE on either side) makes
        this regex fail."""
        rca = make_rca()
        cursor = FakeCursor()
        wr = TriageWriter(cursor)
        wr.write(
            rca, None, None,
            run_id=1, job_id=2, environment_id=3,
            unique_id=None, git_sha=None,
        )
        sql = cursor.last_sql
        # Both sides must COALESCE — case-insensitive whitespace-tolerant.
        # src side:
        assert re.search(
            r"COALESCE\s*\(\s*src\.unique_id\s*,",
            sql,
            re.IGNORECASE,
        ), f"src.unique_id is not COALESCE'd in MERGE ON clause:\n{sql}"
        # tgt side:
        assert re.search(
            r"COALESCE\s*\(\s*tgt\.unique_id\s*,",
            sql,
            re.IGNORECASE,
        ), f"tgt.unique_id is not COALESCE'd in MERGE ON clause:\n{sql}"

    def test_merge_sql_run_id_is_primary_dedup_key(self):
        rca = make_rca()
        cursor = FakeCursor()
        wr = TriageWriter(cursor)
        wr.write(rca, None, None, run_id=1, job_id=2, environment_id=3,
                 unique_id=None, git_sha=None)
        sql = cursor.last_sql
        assert re.search(
            r"src\.run_id\s*=\s*tgt\.run_id", sql, re.IGNORECASE
        )

    def test_no_node_placeholder_constant_value(self):
        # The constant is the contract — if anyone changes it, every
        # existing DB row's COALESCE comparison breaks.
        assert NO_NODE_PLACEHOLDER == "__NO_NODE__"

    def test_two_writes_same_run_id_null_unique_id_bind_same_placeholder(self):
        # Retry semantics: two writes with (run_id=42, unique_id=None)
        # both bind the same NO_NODE_PLACEHOLDER. In a real DB the MERGE
        # would short-circuit the second; in the FakeCursor we just see
        # two executions with matching no_node values (proving the
        # contract is wireable).
        rca = make_rca()
        cursor = FakeCursor()
        wr = TriageWriter(cursor)
        wr.write(rca, None, None, run_id=42, job_id=1, environment_id=1,
                 unique_id=None, git_sha=None)
        wr.write(rca, None, None, run_id=42, job_id=1, environment_id=1,
                 unique_id=None, git_sha=None)
        assert cursor.executions[0][1]["no_node"] == NO_NODE_PLACEHOLDER
        assert cursor.executions[1][1]["no_node"] == NO_NODE_PLACEHOLDER

    def test_merge_uses_when_not_matched_then_insert_only(self):
        # No UPDATE branch — retries silently skip; the original
        # invocation_id + created_at are preserved.
        rca = make_rca()
        cursor = FakeCursor()
        wr = TriageWriter(cursor)
        wr.write(rca, None, None, run_id=1, job_id=2, environment_id=3,
                 unique_id="x", git_sha=None)
        sql = cursor.last_sql.upper()
        assert "WHEN NOT MATCHED THEN INSERT" in sql
        assert "WHEN MATCHED" not in sql, (
            "MERGE must NOT have an UPDATE branch — retries must "
            "preserve the original row (and its invocation_id + "
            "created_at). Found a WHEN MATCHED clause."
        )


# ---------------------------------------------------------------------------
# Post-redact contract — writer does NOT re-run the redactor
# ---------------------------------------------------------------------------

class TestWriterPostRedactContract:
    """The writer is a persistence sink, not a redactor. Two layers
    of enforcement: (a) static — writer module does not import any
    redactor entrypoint; (b) dynamic — a credential-shaped canary
    planted in redaction.payload survives verbatim through the writer."""

    def test_writer_module_does_not_import_redactor_entrypoints(self):
        """MUTATION D DEFEATER (static layer) — AST-walk the writer
        source for any redactor entrypoint import. The writer is
        ALLOWED to import ``RedactionResult`` (the data class) and
        ``REGEX_ELIGIBLE_FIELDS`` (the I4 invariant target), but MUST
        NOT import ``redact_early_failure``, ``redact_artifact``, or
        ``SentinelEvent`` / ``CredentialSentinelFired`` (the
        redactor's machinery).

        AST-walk rather than substring search — the writer's docstring
        explicitly NAMES the forbidden symbols (to document the
        contract for human readers); a substring search would
        false-positive on those docstring mentions.
        """
        import ast
        import inspect

        source = inspect.getsource(writer_module)
        tree = ast.parse(source)
        forbidden = {
            "redact_early_failure",
            "redact_artifact",
            "SentinelEvent",
            "CredentialSentinelFired",
        }
        violations: list[str] = []
        for node in ast.walk(tree):
            if isinstance(node, ast.ImportFrom):
                for alias in node.names:
                    if alias.name in forbidden:
                        violations.append(
                            f"line {node.lineno}: from {node.module} "
                            f"import {alias.name}"
                        )
            elif isinstance(node, ast.Import):
                for alias in node.names:
                    if alias.name in forbidden:
                        violations.append(
                            f"line {node.lineno}: import {alias.name}"
                        )
        assert not violations, (
            "Writer module MUST NOT import any redactor entrypoint — "
            "the writer is a persistence sink, not a redactor. "
            "Re-running the redactor here would silently double-cost "
            "every write AND mask redactor bugs (the second pass "
            "would catch leaks the first pass missed, hiding them "
            "from upstream tests). Found these forbidden imports:\n  "
            + "\n  ".join(violations)
        )

    def test_canary_preserved_verbatim_through_writer(self):
        """MUTATION D DEFEATER (dynamic layer) — plant a credential-shaped
        canary in redaction.payload. If the writer re-runs the
        redactor, the canary would be replaced with a placeholder.
        Surviving verbatim through the writer proves the writer is
        purely a persistence sink."""
        # A JWT-shaped canary — exactly the kind of token the redactor
        # would catch. (If the writer secretly re-runs the redactor,
        # this would be replaced with a <REDACTED:...> placeholder.)
        canary = (
            "eyJhbGciOiJIUzI1NiJ9_CANARY_DO_NOT_REDACT_42_"
            "abcdefghijklmnopqrstuvwxyz_"
            "0123456789_canary_jwt_lookalike_token_xyz"
        )
        red = make_redaction(
            payload={
                "data": {"run_steps": [{"message": f"failure with {canary}"}]},
            },
            redaction_events=0,
        )
        rca = make_rca(
            classification=Classification.UNKNOWN,
            evidence_mode=EvidenceMode.EARLY_FAILURE,
            outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
        )
        cursor = FakeCursor()
        wr = TriageWriter(cursor)
        wr.write(
            rca, red, {"message": f"failure with {canary}"},
            run_id=1, job_id=2, environment_id=3,
            unique_id=None, git_sha=None,
        )
        # The canary must appear VERBATIM in the bound evidence_json
        # JSON string. If the writer re-ran the redactor, the canary
        # would be replaced — assertion fails.
        evidence_str = cursor.last_params["evidence_json"]
        assert canary in evidence_str, (
            f"Canary {canary!r} did not survive verbatim through the "
            f"writer. This means the writer re-ran the redactor (or "
            f"some other transformation altered the payload). The "
            f"writer must be a pure persistence sink — redaction is "
            f"the upstream concern. Bound evidence_json: {evidence_str!r}"
        )


# ---------------------------------------------------------------------------
# Required keyword-only dbt-Cloud ids
# ---------------------------------------------------------------------------

class TestWriterRequiredKwargs:
    """All dbt-Cloud ids are REQUIRED keyword-only (no defaults). This
    forces the C6 loop to source them explicitly from the dbt-Cloud
    API response context (carry-1 from C3: never silently bind 0 or
    None for required ids — a missing id should crash loud, not
    write a corrupt audit row)."""

    @pytest.fixture
    def rca_writer(self):
        return make_rca(), TriageWriter(FakeCursor())

    def test_run_id_required(self, rca_writer):
        rca, wr = rca_writer
        with pytest.raises(TypeError):
            wr.write(rca, None, None, job_id=1, environment_id=1,
                     unique_id=None, git_sha=None)

    def test_job_id_required(self, rca_writer):
        rca, wr = rca_writer
        with pytest.raises(TypeError):
            wr.write(rca, None, None, run_id=1, environment_id=1,
                     unique_id=None, git_sha=None)

    def test_environment_id_required(self, rca_writer):
        rca, wr = rca_writer
        with pytest.raises(TypeError):
            wr.write(rca, None, None, run_id=1, job_id=1,
                     unique_id=None, git_sha=None)

    def test_unique_id_required_but_may_be_none(self, rca_writer):
        rca, wr = rca_writer
        with pytest.raises(TypeError):
            wr.write(rca, None, None, run_id=1, job_id=1, environment_id=1,
                     git_sha=None)
        # None is acceptable (pre-model failures have no node id) —
        # the caller MUST pass it explicitly though.
        cursor = FakeCursor()
        wr2 = TriageWriter(cursor)
        wr2.write(rca, None, None, run_id=1, job_id=1, environment_id=1,
                  unique_id=None, git_sha=None)
        assert cursor.last_params["unique_id"] is None

    def test_git_sha_required_but_may_be_none(self, rca_writer):
        rca, wr = rca_writer
        with pytest.raises(TypeError):
            wr.write(rca, None, None, run_id=1, job_id=1, environment_id=1,
                     unique_id=None)
        cursor = FakeCursor()
        wr2 = TriageWriter(cursor)
        wr2.write(rca, None, None, run_id=1, job_id=1, environment_id=1,
                  unique_id=None, git_sha=None)
        assert cursor.last_params["git_sha"] is None


# ---------------------------------------------------------------------------
# Return value — invocation_id ULID
# ---------------------------------------------------------------------------

class TestWriterReturnValue:
    """``writer.write`` returns the 26-char ULID it generated. Used by
    the C6 loop for tracing/logging ('wrote invocation_id=X for
    run_id=Y')."""

    def test_returns_26_char_string(self):
        rca = make_rca()
        cursor = FakeCursor()
        wr = TriageWriter(cursor)
        inv_id = wr.write(rca, None, None, run_id=1, job_id=2,
                          environment_id=3, unique_id=None, git_sha=None)
        assert isinstance(inv_id, str)
        assert len(inv_id) == 26

    def test_returns_ulid_crockford_base32(self):
        # ULID is Crockford base32 — uppercase, alphanumeric minus I/L/O/U.
        rca = make_rca()
        cursor = FakeCursor()
        wr = TriageWriter(cursor)
        inv_id = wr.write(rca, None, None, run_id=1, job_id=2,
                          environment_id=3, unique_id=None, git_sha=None)
        # Crockford excludes I, L, O, U.
        assert re.fullmatch(r"[0-9A-HJKMNP-TV-Z]{26}", inv_id), (
            f"invocation_id {inv_id!r} is not a Crockford base32 ULID"
        )

    def test_consecutive_calls_produce_unique_ids(self):
        rca = make_rca()
        cursor = FakeCursor()
        wr = TriageWriter(cursor)
        ids = [
            wr.write(rca, None, None, run_id=i, job_id=2,
                     environment_id=3, unique_id=None, git_sha=None)
            for i in range(10)
        ]
        assert len(set(ids)) == 10, "consecutive writes returned duplicate ULIDs"

    def test_returned_invocation_id_matches_bound_param(self):
        rca = make_rca()
        cursor = FakeCursor()
        wr = TriageWriter(cursor)
        inv_id = wr.write(rca, None, None, run_id=1, job_id=2,
                          environment_id=3, unique_id=None, git_sha=None)
        assert cursor.last_params["invocation_id"] == inv_id


# ---------------------------------------------------------------------------
# Orchestrator wrapper — three-dead-letter contract
# ---------------------------------------------------------------------------

class TestProcessEnvelopeWrapper:
    """Rows 0, 8, 9 of the 10-path table are wrapper-side concerns.
    Three distinct dead-letters per spec §4.9."""

    def _collect_dead_letters(self):
        malformed: list[tuple[Any, BaseException]] = []
        operational: list[tuple[Any, BaseException]] = []

        def on_m(env: Any, exc: BaseException) -> None:
            malformed.append((env, exc))

        def on_o(env: Any, exc: BaseException) -> None:
            operational.append((env, exc))

        return malformed, operational, on_m, on_o

    def test_row_0_non_dict_routes_to_malformed_input(self):
        malformed, operational, on_m, on_o = self._collect_dead_letters()
        cursor = FakeCursor()
        wr = TriageWriter(cursor)
        result = process_envelope(
            "not a dict",  # row 0 trigger
            wr,
            run_id=1, job_id=2, environment_id=3,
            unique_id=None, git_sha=None,
            on_malformed_input=on_m,
            on_operational_error=on_o,
        )
        assert result is None
        assert len(malformed) == 1
        assert malformed[0][0] == "not a dict"
        assert isinstance(malformed[0][1], TypeError)
        assert len(operational) == 0
        # Writer was NOT called — no RCARecord existed.
        assert cursor.executions == []

    def test_row_0_routes_each_non_dict_kind(self):
        # None, list, int, set — all are TypeErrors per row 0.
        for bad in [None, [], 42, set()]:
            malformed, _, on_m, on_o = self._collect_dead_letters()
            wr = TriageWriter(FakeCursor())
            process_envelope(
                bad, wr,
                run_id=1, job_id=2, environment_id=3,
                unique_id=None, git_sha=None,
                on_malformed_input=on_m, on_operational_error=on_o,
            )
            assert len(malformed) == 1, f"{type(bad).__name__} did not route"

    def test_row_8_triage_internal_exception_routes_to_operational(
        self, monkeypatch
    ):
        # Patch triage_failure as imported in writer module to raise a
        # non-TypeError exception (simulates an internal helper bug).
        def boom(payload):
            raise RuntimeError("simulated helper bug")

        monkeypatch.setattr(writer_module, "triage_failure", boom)
        malformed, operational, on_m, on_o = self._collect_dead_letters()
        cursor = FakeCursor()
        wr = TriageWriter(cursor)
        result = process_envelope(
            {"data": {}}, wr,
            run_id=1, job_id=2, environment_id=3,
            unique_id=None, git_sha=None,
            on_malformed_input=on_m, on_operational_error=on_o,
        )
        assert result is None
        assert len(malformed) == 0
        assert len(operational) == 1
        assert isinstance(operational[0][1], RuntimeError)
        # Writer was NOT called (triage failed before reaching it).
        assert cursor.executions == []

    def test_row_8_writer_exception_routes_to_operational(self):
        # Writer-side operational error (Snowflake outage simulation).
        malformed, operational, on_m, on_o = self._collect_dead_letters()
        cursor = FakeCursor(raise_on_execute=RuntimeError("snowflake down"))
        wr = TriageWriter(cursor)
        result = process_envelope(
            # A dict that triages cleanly (UNDETECTED, no projection).
            {"meta": {"foo": "bar"}}, wr,
            run_id=1, job_id=2, environment_id=3,
            unique_id=None, git_sha=None,
            on_malformed_input=on_m, on_operational_error=on_o,
        )
        assert result is None
        assert len(malformed) == 0
        assert len(operational) == 1
        assert isinstance(operational[0][1], RuntimeError)

    def test_row_9_keyboard_interrupt_propagates(self, monkeypatch):
        """BaseException MUST propagate (Ctrl+C → process terminates).
        Routing it to a dead-letter would silently survive an
        operator's explicit shutdown."""
        def boom(payload):
            raise KeyboardInterrupt()

        monkeypatch.setattr(writer_module, "triage_failure", boom)
        malformed, operational, on_m, on_o = self._collect_dead_letters()
        wr = TriageWriter(FakeCursor())
        with pytest.raises(KeyboardInterrupt):
            process_envelope(
                {"data": {}}, wr,
                run_id=1, job_id=2, environment_id=3,
                unique_id=None, git_sha=None,
                on_malformed_input=on_m, on_operational_error=on_o,
            )
        assert len(malformed) == 0
        assert len(operational) == 0

    def test_row_9_system_exit_propagates(self, monkeypatch):
        def boom(payload):
            raise SystemExit(2)

        monkeypatch.setattr(writer_module, "triage_failure", boom)
        wr = TriageWriter(FakeCursor())
        with pytest.raises(SystemExit):
            process_envelope(
                {"data": {}}, wr,
                run_id=1, job_id=2, environment_id=3,
                unique_id=None, git_sha=None,
                on_malformed_input=lambda *a: None,
                on_operational_error=lambda *a: None,
            )

    def test_row_9_writer_side_base_exception_propagates(self):
        # BaseException from the writer side also propagates.
        cursor = FakeCursor(raise_on_execute=KeyboardInterrupt())
        wr = TriageWriter(cursor)
        with pytest.raises(KeyboardInterrupt):
            process_envelope(
                {"meta": {"foo": "bar"}}, wr,
                run_id=1, job_id=2, environment_id=3,
                unique_id=None, git_sha=None,
                on_malformed_input=lambda *a: None,
                on_operational_error=lambda *a: None,
            )

    def test_happy_path_returns_invocation_id_and_writes(self):
        cursor = FakeCursor()
        wr = TriageWriter(cursor)
        result = process_envelope(
            {"meta": {"foo": "bar"}}, wr,  # → UNDETECTED, row 1
            run_id=42, job_id=1, environment_id=1,
            unique_id=None, git_sha=None,
            on_malformed_input=lambda *a: None,
            on_operational_error=lambda *a: None,
        )
        assert isinstance(result, str)
        assert len(result) == 26
        assert len(cursor.executions) == 1


# ---------------------------------------------------------------------------
# Coverage-reality: every UNKNOWN path persists faithfully
# ---------------------------------------------------------------------------

class TestUnknownRowsPersistFaithfully:
    """Every UNKNOWN row (rows 1-6) must reach the DB. A silent drop
    would mean lost backlog visibility — UNKNOWN failures are
    EXACTLY the population that humans need to inspect to expand
    pattern coverage. The writer must not silently filter them."""

    def test_row_1_undetected_persists(self):
        cursor = FakeCursor()
        wr = TriageWriter(cursor)
        wr.write(
            make_rca(
                evidence_mode=EvidenceMode.UNDETECTED,
                outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
                rationale="evidence-mode-not-detected: ...",
            ),
            None, None,
            run_id=1, job_id=2, environment_id=3,
            unique_id=None, git_sha=None,
        )
        assert len(cursor.executions) == 1
        assert cursor.last_params["classification"] == "unknown"
        assert "not-detected" in cursor.last_params["rationale"]

    def test_row_2_sentinel_persists(self):
        cursor = FakeCursor()
        wr = TriageWriter(cursor)
        wr.write(
            make_rca(
                evidence_mode=EvidenceMode.EARLY_FAILURE,
                outcome=Outcome.CREDENTIAL_SENTINEL_FIRED,
                rationale="credential_sentinel_fired: pattern=jwt ...",
            ),
            None, None,
            run_id=1, job_id=2, environment_id=3,
            unique_id=None, git_sha=None,
        )
        assert len(cursor.executions) == 1
        assert cursor.last_params["sentinel_fired"] is True

    def test_row_3_fail_open_persists(self):
        cursor = FakeCursor()
        wr = TriageWriter(cursor)
        wr.write(
            make_rca(
                evidence_mode=EvidenceMode.EARLY_FAILURE,
                outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
                rationale="redactor_fail_open: exc_type=ValueError",
            ),
            None, None,
            run_id=1, job_id=2, environment_id=3,
            unique_id=None, git_sha=None,
        )
        assert len(cursor.executions) == 1
        assert "redactor_fail_open" in cursor.last_params["rationale"]

    def test_row_4_empty_projection_persists(self):
        cursor = FakeCursor()
        wr = TriageWriter(cursor)
        wr.write(
            make_rca(
                evidence_mode=EvidenceMode.EARLY_FAILURE,
                outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
                rationale="no extractable eligible fields: ...",
            ),
            make_redaction(redaction_events=2), {},
            run_id=1, job_id=2, environment_id=3,
            unique_id=None, git_sha=None,
        )
        assert len(cursor.executions) == 1
        assert cursor.last_params["redaction_events"] == 2
        assert cursor.last_params["evidence_json"] is not None
        assert cursor.last_params["error_signature_hash"] is None

    def test_row_5_no_match_persists(self):
        cursor = FakeCursor()
        wr = TriageWriter(cursor)
        wr.write(
            make_rca(
                evidence_mode=EvidenceMode.EARLY_FAILURE,
                outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
                rationale="no catalog pattern matched ...",
            ),
            make_redaction(), {"message": "weird"},
            run_id=1, job_id=2, environment_id=3,
            unique_id=None, git_sha=None,
        )
        assert len(cursor.executions) == 1
        assert cursor.last_params["error_signature_hash"] is not None

    def test_row_6_multi_match_persists(self):
        cursor = FakeCursor()
        wr = TriageWriter(cursor)
        wr.write(
            make_rca(
                evidence_mode=EvidenceMode.EARLY_FAILURE,
                outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
                rationale="multi-pattern match deferred ...",
            ),
            make_redaction(), {"message": "M"},
            run_id=1, job_id=2, environment_id=3,
            unique_id=None, git_sha=None,
        )
        assert len(cursor.executions) == 1
        assert "multi-pattern" in cursor.last_params["rationale"]
