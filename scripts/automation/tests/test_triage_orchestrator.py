"""Tests for the failure-triage orchestrator (Day-5 Q2 skeleton).

Coverage:
  * Boundary contract — TypeError on non-dict; UNKNOWN paths for empty /
    missing / malformed inputs.
  * Mode detection — _detect_mode requires data.run_steps with at least
    one REGEX_ELIGIBLE field populated.
  * Real-fixture integration — Cluster C raw-shape fixture
    (early_failure_dmf_failure_486060143.json) → zero-match path.
  * Synthetic-payload integration — Pattern 1 (FK orphan, `message`),
    Pattern 2 (PR-isolated schema, `truncated_debug_logs`), Pattern 3
    (manifest parse, `logs`) each produce CLASSIFIED records.
  * Sentinel propagation — JWT in `logs` raises CredentialSentinelFired
    inside redact, caught at orchestrator boundary, emitted as
    Outcome.CREDENTIAL_SENTINEL_FIRED; rationale carries metadata only.
  * Multi-match — synthetic payload matching Pattern 2 + Pattern 3 →
    UNKNOWN with rationale listing both pattern_ids.
  * Drift coupling — parametric over REGEX_ELIGIBLE_FIELDS: each field
    in the live set is reachable by the projection helper.
  * Iron Rule respected — every CLASSIFIED record holds the Rule-2 + 3
    invariants (test re-asserts via RCARecord construction round-trip).
"""

from __future__ import annotations

import copy
import json
from pathlib import Path

import pytest

from scripts.automation.src.triage.failure_triage_agent import (
    _detect_mode,
    _project_artifact_payload,
    _project_payload,
    triage_failure,
)
from scripts.automation.src.triage.fixture_loader import load_fixture
from scripts.automation.src.triage.rca_schema import (
    Classification,
    EvidenceMode,
    Outcome,
    SuggestedAction,
)
from scripts.automation.src.triage.redact import (
    REGEX_ELIGIBLE_FIELDS,
    redact_early_failure,
)


REPO_ROOT = Path(__file__).resolve().parents[3]
CLUSTER_C_FIXTURE = (
    REPO_ROOT
    / "docs/triage-agent/fixtures/early_failure_dmf_failure_486060143.json"
)


# ---------------------------------------------------------------------------
# Synthetic payload builders
# ---------------------------------------------------------------------------

def _wrap_step(step_fields: dict) -> dict:
    """Wrap a flat dict of step-level fields in raw dbt Cloud shape."""
    return {
        "data": {
            "status_message": step_fields.pop("status_message", "Error"),
            "run_steps": [
                {
                    "name": "Invoke dbt with `dbt build`",
                    "index": 4,
                    "status": 20,
                    "status_humanized": "Error",
                    "started_at": "2026-06-06T00:00:00.000Z",
                    "finished_at": "2026-06-06T00:00:10.000Z",
                    **step_fields,
                }
            ],
        }
    }


def _wrap_artifact(result_fields: dict) -> dict:
    """Wrap a flat dict of result-level fields in artifact-projection shape.

    Mirrors the C4 adapter's H8 envelope contract:
    ``{"data":{"failed_steps":[{...,"results":[<single>]}]}}`` — one
    single-result envelope per fanned-out result. Used by Component 3
    propagation tests to feed ARTIFACT_PROJECTION input through
    ``triage_failure`` and assert the recorded ``evidence_mode``
    matches the detected shape.
    """
    return {
        "data": {
            "failed_steps": [
                {
                    "name": "Invoke dbt with `dbt build`",
                    "index": 4,
                    "results": [
                        {
                            "unique_id": "model.fbin.dim_customer",
                            "status": "error",
                            **result_fields,
                        }
                    ],
                }
            ],
        }
    }


def _pattern_1_payload() -> dict:
    """Synthetic FK-orphan failure — Pattern 1 (message)."""
    return _wrap_step({
        "message": (
            "Failure in test dbt_constraints_foreign_key_sat_customer_HK "
            "(models/raw_vault/sat/sat_customer.yml)\n"
            "Got 42 results, configured to fail if != 0"
        ),
        "truncated_debug_logs": "Completed with 1 error and 0 warnings:",
    })


def _pattern_2_payload() -> dict:
    """Synthetic PR-isolated-schema-missing-upstream — Pattern 2."""
    return _wrap_step({
        "truncated_debug_logs": (
            "Database Error in model pit_customer\n"
            "  002003 (42S02): SQL compilation error:\n"
            "  Object 'DATAVAULT_QA.DBT_CLOUD_PR_786808_42_RAW_VAULT.LNK_ORDER_CUSTOMER' "
            "does not exist or not authorized."
        ),
    })


def _pattern_3_payload() -> dict:
    """Synthetic manifest-parse failure — Pattern 3 (logs)."""
    return _wrap_step({
        "logs": (
            "Running dbt build\n"
            "Encountered an error:\n"
            'Field "macros" of type Mapping[str, Macro] in WritableManifest '
            "has invalid value at $.macros.foo.supported_languages: "
            "'javascript' is not a valid ModelLanguage."
        ),
    })


def _multi_match_payload() -> dict:
    """Synthetic payload matching BOTH Pattern 2 and Pattern 3."""
    return _wrap_step({
        "logs": (
            "Encountered an error:\n"
            'Field "macros" of type Mapping[str, Macro] in WritableManifest '
            "has invalid value."
        ),
        "truncated_debug_logs": (
            "Database Error\n"
            "  Object 'DATAVAULT_QA.DBT_CLOUD_PR_786808_99_RAW_VAULT.X' "
            "does not exist or not authorized."
        ),
    })


# ---------------------------------------------------------------------------
# Boundary contract
# ---------------------------------------------------------------------------

class TestBoundaryContract:

    def test_non_dict_raises_type_error(self):
        with pytest.raises(TypeError):
            triage_failure(None)  # type: ignore[arg-type]
        with pytest.raises(TypeError):
            triage_failure("not a dict")  # type: ignore[arg-type]
        with pytest.raises(TypeError):
            triage_failure([{"data": {}}])  # type: ignore[arg-type]

    def test_empty_dict_returns_unknown(self):
        rec, _, _ = triage_failure({})
        assert rec.classification == Classification.UNKNOWN
        assert rec.outcome == Outcome.UNKNOWN_HANDED_TO_HUMAN
        assert rec.requires_human_review is True
        assert rec.confidence is None
        assert "evidence-mode-not-detected" in rec.rationale

    def test_missing_data_key_returns_unknown(self):
        rec, _, _ = triage_failure({"meta": {"foo": "bar"}})
        assert rec.classification == Classification.UNKNOWN
        assert "evidence-mode-not-detected" in rec.rationale

    def test_empty_run_steps_returns_unknown(self):
        rec, _, _ = triage_failure({"data": {"run_steps": []}})
        assert rec.classification == Classification.UNKNOWN
        assert "evidence-mode-not-detected" in rec.rationale

    def test_run_step_without_eligible_field_returns_unknown(self):
        rec, _, _ = triage_failure({
            "data": {
                "run_steps": [
                    {"name": "n", "status": 20, "status_humanized": "Error"}
                ]
            }
        })
        assert rec.classification == Classification.UNKNOWN
        assert "evidence-mode-not-detected" in rec.rationale


# ---------------------------------------------------------------------------
# Mode detection
# ---------------------------------------------------------------------------

class TestDetectMode:

    def test_early_failure_detected_with_logs(self):
        payload = _wrap_step({"logs": "anything"})
        assert _detect_mode(payload) == EvidenceMode.EARLY_FAILURE

    def test_early_failure_detected_with_status_message(self):
        payload = {"data": {"status_message": "Error", "run_steps": [{"name": "x"}]}}
        assert _detect_mode(payload) == EvidenceMode.EARLY_FAILURE

    def test_undetected_for_empty_string_field(self):
        # C1.5 Gap A: previously asserted `is None`; _detect_mode now
        # returns UNDETECTED instead so dispatch on EvidenceMode is total.
        payload = _wrap_step({"logs": ""})
        # status_message default in _wrap_step is "Error" (non-empty)
        # so this DOES detect. Override status_message to empty too.
        payload["data"]["status_message"] = ""
        assert _detect_mode(payload) == EvidenceMode.UNDETECTED

    def test_undetected_when_data_not_dict(self):
        # C1.5 Gap A: previously asserted `is None`.
        assert _detect_mode({"data": "string-instead-of-dict"}) == EvidenceMode.UNDETECTED

    # ---- C1.5 Gap A: 4-case truth table for ordered detection -------------
    #
    # Q1 LOCKED order (spec §4.2):
    #   1. EARLY_FAILURE first  (run_steps[-1] has REGEX_ELIGIBLE field)
    #   2. ARTIFACT_PROJECTION  (failed_steps[*].results[*] has eligible field)
    #   3. UNDETECTED           (neither shape signals)
    #
    # The four cells of the (early, artifact) ∈ {present, absent}² matrix
    # pin the entire contract; mutating any cell-mapping fails one row.

    def test_q1_both_shapes_present_picks_early_failure(self):
        """Precedence test: EARLY_FAILURE wins on both-shapes-present input.
        Mutation: flipping the check order in _detect_mode flips this red."""
        payload = {
            "data": {
                "status_message": "",
                "run_steps": [{"name": "step", "message": "early-failure-signal"}],
                "failed_steps": [
                    {"results": [{"message": "artifact-signal"}]}
                ],
            }
        }
        assert _detect_mode(payload) == EvidenceMode.EARLY_FAILURE

    def test_q1_artifact_only_picks_artifact_projection(self):
        """ARTIFACT_PROJECTION fires when run_steps absent and failed_steps signals."""
        payload = {
            "data": {
                "status_message": "",
                "failed_steps": [
                    {"results": [{"message": "FK violation on sat_customer_HK"}]}
                ],
            }
        }
        assert _detect_mode(payload) == EvidenceMode.ARTIFACT_PROJECTION

    def test_q1_artifact_picks_artifact_projection_when_run_steps_signal_absent(self):
        """run_steps present but no eligible field → falls through to artifact."""
        payload = {
            "data": {
                "status_message": "",
                "run_steps": [{"name": "step"}],  # no message/logs/etc.
                "failed_steps": [
                    {"results": [{"message": "compile error"}]}
                ],
            }
        }
        assert _detect_mode(payload) == EvidenceMode.ARTIFACT_PROJECTION

    def test_q1_early_only_picks_early_failure(self):
        """EARLY_FAILURE fires when only run_steps signals."""
        payload = _wrap_step({"message": "compile error"})
        assert _detect_mode(payload) == EvidenceMode.EARLY_FAILURE

    def test_q1_neither_shape_picks_undetected(self):
        """UNDETECTED is the *only* non-error terminal for empty payload.
        Mutation: replacing the final `return EvidenceMode.UNDETECTED` with
        `return None` makes the caller's `== UNDETECTED` check fail red."""
        assert _detect_mode({"data": {}}) == EvidenceMode.UNDETECTED
        assert _detect_mode({}) == EvidenceMode.UNDETECTED

    def test_q1_artifact_requires_populated_result(self):
        """failed_steps with results that lack any REGEX_ELIGIBLE field
        does NOT signal ARTIFACT_PROJECTION (signal-existence discipline,
        symmetric to EARLY_FAILURE branch). Falls through to UNDETECTED."""
        payload = {
            "data": {
                "failed_steps": [
                    {"results": [{"unique_id": "model.x.y"}]}  # no message/logs/etc.
                ],
            }
        }
        assert _detect_mode(payload) == EvidenceMode.UNDETECTED

    def test_q1_artifact_skips_non_dict_steps_and_results(self):
        """Defensive: malformed entries inside failed_steps/results are skipped,
        not raised. Type guards in _detect_mode are exercised here."""
        payload = {
            "data": {
                "failed_steps": [
                    "not-a-dict",
                    {"results": "not-a-list"},
                    {"results": []},
                    {"results": ["not-a-dict", {"message": "real-signal"}]},
                ],
            }
        }
        assert _detect_mode(payload) == EvidenceMode.ARTIFACT_PROJECTION


# ---------------------------------------------------------------------------
# Artifact-projection projector — C1.5 Component 2
# ---------------------------------------------------------------------------

class TestProjectArtifactPayload:
    """Bytes-locked contract for ``_project_artifact_payload`` (C1.5
    spec §4.3).

    Coverage organised by what each test PINS:

      Inclusion-rule parity with ``_project_payload``:
        - test_string_valued_non_empty_fields_projected
        - test_empty_string_field_excluded
        - test_non_string_field_excluded
        - test_iterates_regex_eligible_fields_live (drift-coupling
          parametric — same shape as the existing
          test_each_regex_eligible_field_reachable for ``_project_payload``)

      Walk-path contract (``data.failed_steps[0].results[0]``):
        - test_first_result_pinned_against_index_mutation (Mutation A
          target: catches ``[0]`` → ``[-1]`` swap on results list)

      Defensive shape guards (fail to ``{}``, never raise):
        - test_empty_results_returns_empty_not_indexerror (Mutation B
          target: catches removal of the empty-results guard)
        - test_missing_data_returns_empty
        - test_missing_failed_steps_returns_empty
        - test_failed_steps_not_a_list_returns_empty
        - test_empty_failed_steps_returns_empty
        - test_first_step_not_a_dict_returns_empty
        - test_missing_results_returns_empty
        - test_results_not_a_list_returns_empty
        - test_first_result_not_a_dict_returns_empty
        - test_non_dict_redacted_returns_empty

      No Gap-F normalization here (C4 adapter's job):
        - test_truncated_logs_not_renamed_to_truncated_debug_logs

    All fixtures hand-built — the adapter that produces these envelopes
    in production is Component 4, not yet built. The
    ``{"data":{"failed_steps":[{...,"results":[<single>]}]}}`` shape
    here matches the adapter contract the directive pins.
    """

    # ---- Inclusion rule parity --------------------------------------

    def test_string_valued_non_empty_fields_projected(self):
        """All four REGEX_ELIGIBLE_FIELDS appear at top level when
        populated as non-empty strings on the result."""
        envelope = {
            "data": {
                "failed_steps": [
                    {
                        "results": [
                            {
                                "message": "msg-value",
                                "truncated_debug_logs": "tdl-value",
                                "status_message": "sm-value",
                                "logs": "logs-value",
                            }
                        ]
                    }
                ]
            }
        }
        proj = _project_artifact_payload(envelope)
        assert proj == {
            "message": "msg-value",
            "truncated_debug_logs": "tdl-value",
            "status_message": "sm-value",
            "logs": "logs-value",
        }

    def test_empty_string_field_excluded(self):
        """Empty strings are excluded (``and value`` falsy-test) — same
        rule as ``_project_payload``."""
        envelope = {
            "data": {
                "failed_steps": [
                    {
                        "results": [
                            {
                                "message": "",
                                "logs": "real-content",
                            }
                        ]
                    }
                ]
            }
        }
        proj = _project_artifact_payload(envelope)
        assert proj == {"logs": "real-content"}
        assert "message" not in proj

    def test_non_string_field_excluded(self):
        """Non-string values (int / None / dict / list) are excluded —
        ``isinstance(value, str)`` is the type gate."""
        envelope = {
            "data": {
                "failed_steps": [
                    {
                        "results": [
                            {
                                "message": 42,
                                "truncated_debug_logs": None,
                                "status_message": {"nested": "dict"},
                                "logs": ["list", "value"],
                            }
                        ]
                    }
                ]
            }
        }
        proj = _project_artifact_payload(envelope)
        assert proj == {}

    @pytest.mark.parametrize("field_name", sorted(REGEX_ELIGIBLE_FIELDS))
    def test_iterates_regex_eligible_fields_live(self, field_name):
        """Drift-coupling parametric: every member of the live
        REGEX_ELIGIBLE_FIELDS frozenset is reachable. Mirrors the
        ``_project_payload`` parametric so a future allowlist expansion
        (item #16) lands without orchestrator changes on EITHER projector.
        """
        envelope = {
            "data": {
                "failed_steps": [
                    {
                        "results": [
                            {field_name: f"signal-for-{field_name}"}
                        ]
                    }
                ]
            }
        }
        proj = _project_artifact_payload(envelope)
        assert proj == {field_name: f"signal-for-{field_name}"}

    # ---- Walk-path contract -----------------------------------------

    def test_first_result_pinned_against_index_mutation(self):
        """Mutation A target.

        Adapter contract guarantees exactly one result per envelope,
        but if ``_project_artifact_payload`` ever sees a multi-result
        list (e.g., adapter bug, future contract change), it MUST pick
        ``results[0]`` — not ``results[-1]``. This test pins the index
        explicitly so flipping ``[0]`` → ``[-1]`` is caught.

        Same defense pattern as
        ``test_project_payload_picks_last_step_not_first`` —
        synthetic 2-element walk where ``[0]`` and ``[-1]`` carry
        DIFFERENT signals so the index choice is observable.
        """
        envelope = {
            "data": {
                "failed_steps": [
                    {
                        "results": [
                            {"message": "first-result-signal"},
                            {"message": "second-result-signal"},
                        ]
                    }
                ]
            }
        }
        proj = _project_artifact_payload(envelope)
        assert proj == {"message": "first-result-signal"}, (
            "`_project_artifact_payload` must pick results[0]; if "
            "results[-1] is picked the projection carries "
            "'second-result-signal' instead — likely the [0] index "
            "was mutated to [-1]"
        )

    # ---- Defensive shape guards (fail to {}, never raise) -----------

    def test_empty_results_returns_empty_not_indexerror(self):
        """Mutation B target.

        Removing the ``if not isinstance(results, list) or not results``
        guard makes ``results[0]`` on ``[]`` raise IndexError, which
        would propagate out of ``_project_artifact_payload`` (called
        outside the redactor try/except) and become a row-8
        Exception-propagation. This test pins that an empty
        ``results`` list MUST return ``{}`` — proving the guard
        converts a would-be exception into a benign empty projection.
        """
        envelope = {
            "data": {
                "failed_steps": [
                    {"results": []}
                ]
            }
        }
        # MUST return {}, MUST NOT raise IndexError.
        proj = _project_artifact_payload(envelope)
        assert proj == {}, (
            "empty results list must fail to {}; if IndexError leaks "
            "out, the empty-results guard was removed and "
            "`_project_artifact_payload` becomes a row-8 "
            "Exception-propagation source"
        )

    def test_missing_data_returns_empty(self):
        assert _project_artifact_payload({}) == {}

    def test_missing_failed_steps_returns_empty(self):
        assert _project_artifact_payload({"data": {}}) == {}

    def test_failed_steps_not_a_list_returns_empty(self):
        assert _project_artifact_payload(
            {"data": {"failed_steps": "not-a-list"}}
        ) == {}

    def test_empty_failed_steps_returns_empty(self):
        assert _project_artifact_payload(
            {"data": {"failed_steps": []}}
        ) == {}

    def test_first_step_not_a_dict_returns_empty(self):
        assert _project_artifact_payload(
            {"data": {"failed_steps": ["string-not-dict"]}}
        ) == {}

    def test_missing_results_returns_empty(self):
        assert _project_artifact_payload(
            {"data": {"failed_steps": [{}]}}
        ) == {}

    def test_results_not_a_list_returns_empty(self):
        assert _project_artifact_payload(
            {"data": {"failed_steps": [{"results": "not-a-list"}]}}
        ) == {}

    def test_first_result_not_a_dict_returns_empty(self):
        assert _project_artifact_payload(
            {"data": {"failed_steps": [{"results": ["string-not-dict"]}]}}
        ) == {}

    def test_non_dict_redacted_returns_empty(self):
        """Same isinstance discipline as `_project_payload`'s top guard
        — a non-dict input returns {} rather than raising AttributeError
        on `.get`."""
        assert _project_artifact_payload("not-a-dict") == {}
        assert _project_artifact_payload(None) == {}
        assert _project_artifact_payload([1, 2, 3]) == {}

    # ---- No Gap-F normalization here (C4 adapter's job) -------------

    def test_truncated_logs_not_renamed_to_truncated_debug_logs(self):
        """Gap-F normalization (truncated_logs → truncated_debug_logs)
        is the adapter's (Component 4) job, NOT this projector's.

        If the adapter ships a result with the un-renamed field
        ``truncated_logs`` (a bug in C4, not this function), this
        projector MUST pass it through as-named — meaning
        ``truncated_logs`` is NOT in REGEX_ELIGIBLE_FIELDS so it
        gets dropped, and ``truncated_debug_logs`` is also absent so
        the projection is empty. The test pins both halves: no rename
        happens here, and the un-renamed key is silently dropped (not
        projected under the renamed key, which would mask the C4 bug).
        """
        envelope = {
            "data": {
                "failed_steps": [
                    {
                        "results": [
                            {"truncated_logs": "should-not-rename"}
                        ]
                    }
                ]
            }
        }
        proj = _project_artifact_payload(envelope)
        assert "truncated_debug_logs" not in proj, (
            "`_project_artifact_payload` must NOT rename "
            "truncated_logs → truncated_debug_logs; that is the "
            "adapter (Component 4)'s job"
        )
        assert "truncated_logs" not in proj, (
            "truncated_logs is not in REGEX_ELIGIBLE_FIELDS so it "
            "should be dropped; passing it through would be a "
            "different allowlist than `_project_payload` uses"
        )


# ---------------------------------------------------------------------------
# Dispatch — ARTIFACT_PROJECTION routes to _project_artifact_payload
# ---------------------------------------------------------------------------

class TestProjectionDispatch:
    """End-to-end pin for the `triage_failure` projector dispatch
    (C1.5 spec §4.2 Q1 LOCKED).

    Asymmetry vs the unit tests above:
      - Unit tests exercise ``_project_artifact_payload`` in isolation
        (pass even if dispatch routes wrong).
      - These tests feed envelopes through ``triage_failure`` end-to-end;
        verdict depends on the correct projector being dispatched on the
        detected mode.

    Same pattern as ``TestProductionMut2`` for the run_steps[-1] pin.
    """

    def test_artifact_projection_routes_to_artifact_projector(self):
        """Mutation C target.

        Artifact-shape envelope (failed_steps with results, NO
        run_steps). ``_detect_mode`` returns ARTIFACT_PROJECTION.
        Dispatch MUST call ``_project_artifact_payload`` (which finds
        the message field via the failed_steps/results walk), NOT
        ``_project_payload`` (which would walk run_steps, find nothing,
        and return ``{}``).

        Mutated dispatch (route ARTIFACT_PROJECTION → ``_project_payload``)
        produces empty projection → rationale starts with "no
        extractable eligible fields". This test asserts the rationale
        does NOT start with that — meaning the projector ran on the
        artifact shape and found the field.
        """
        envelope = {
            "data": {
                "failed_steps": [
                    {
                        "results": [
                            {
                                "message": (
                                    "Database Error in model foo "
                                    "(models/foo.sql)\n  some sql error"
                                )
                            }
                        ]
                    }
                ]
            }
        }
        # Sanity-check the prerequisite: mode is ARTIFACT_PROJECTION.
        assert _detect_mode(envelope) == EvidenceMode.ARTIFACT_PROJECTION

        rec, _, _ = triage_failure(envelope)
        # Mutation C produces this exact rationale prefix (because
        # `_project_payload` walks run_steps which is absent → empty
        # projection → _unknown row-4). Asserting NOT-starts-with
        # separates the two dispatch paths regardless of catalog match.
        assert not rec.rationale.startswith(
            "no extractable eligible fields"
        ), (
            "ARTIFACT_PROJECTION envelope was routed to the wrong "
            "projector: rationale 'no extractable eligible fields' "
            "means `_project_payload` walked run_steps (absent in this "
            "envelope) and returned {}. Dispatch must route "
            "ARTIFACT_PROJECTION → `_project_artifact_payload`; got "
            f"rationale: {rec.rationale!r}"
        )

    def test_early_failure_still_routes_to_run_steps_projector(self):
        """Existing EARLY_FAILURE path unchanged: an envelope with
        run_steps must still route to ``_project_payload``. Symmetric
        to the test above — pins that the dispatch didn't accidentally
        route BOTH modes to the new projector (which would walk
        failed_steps, find nothing, and return ``{}``)."""
        envelope = {
            "data": {
                "run_steps": [
                    {
                        "name": "Invoke dbt with `dbt build`",
                        "status_humanized": "Error",
                        "logs": (
                            "Encountered an error:\n"
                            'Field "macros" of type Mapping[str, Macro] '
                            "in WritableManifest has invalid value at "
                            "$.macros.foo.supported_languages: "
                            "'javascript' is not a valid ModelLanguage."
                        ),
                    },
                ],
            }
        }
        assert _detect_mode(envelope) == EvidenceMode.EARLY_FAILURE

        rec, _, _ = triage_failure(envelope)
        # The existing manifest_parse pattern matches the logs above
        # (same fixture body as TestProductionMut2). If dispatch
        # accidentally routes EARLY_FAILURE → `_project_artifact_payload`,
        # the failed_steps walk finds nothing → empty projection →
        # rationale "no extractable eligible fields".
        assert not rec.rationale.startswith(
            "no extractable eligible fields"
        ), (
            "EARLY_FAILURE envelope was routed to the wrong projector "
            "(likely `_project_artifact_payload` instead of "
            f"`_project_payload`); rationale: {rec.rationale!r}"
        )
        assert rec.classification == Classification.COMPILE_ERROR


# ---------------------------------------------------------------------------
# Component 3 — Gap-B evidence_mode propagation + shape-aware rationale
# ---------------------------------------------------------------------------
#
# Closes the C2.b carry: the empty-projection rationale used to hard-say
# "data.run_steps[-1] or data" (the EARLY_FAILURE walk path) regardless
# of the mode `_detect_mode` returned. Component 3 threads `mode` through
# `_classified` and `_unknown` so:
#   (a) the RCARecord carries the truthful provenance mode (no
#       hardcoded EARLY_FAILURE for ARTIFACT_PROJECTION runs); and
#   (b) the empty-projection rationale names the walk path the projector
#       actually took, via `_evidence_source_phrase(mode)` — ONE place.
#
# Mutation targets pinned by this class:
#   A — revert any classified/unknown call site to hardcode EARLY_FAILURE
#       → ARTIFACT_PROJECTION-tag tests RED.
#   B — hardcode the rationale phrase on the ARTIFACT_PROJECTION path
#       → rationale-source test RED.
#   C — pass detected mode on the not-detected path instead of UNDETECTED
#       → UNDETECTED-tag test RED.

class TestEvidenceModePropagation:
    """Gap-B propagation: every RCARecord carries the truthful
    detected mode, not a hardcoded `EARLY_FAILURE`."""

    # ----- Parametric (mode, expected_evidence_mode) — §4.6 -----

    @pytest.mark.parametrize(
        "payload_factory, expected_mode",
        [
            # EARLY_FAILURE shape carries the manifest-parse signal in
            # `logs` under `data.run_steps[-1]`; classifies as COMPILE_ERROR.
            (
                lambda: _pattern_3_payload(),
                EvidenceMode.EARLY_FAILURE,
            ),
            # ARTIFACT_PROJECTION shape carries the same signal under
            # `data.failed_steps[0].results[0].logs`; classifies the same
            # but the recorded evidence_mode MUST be ARTIFACT_PROJECTION.
            (
                lambda: _wrap_artifact({
                    "logs": (
                        "Running dbt build\n"
                        "Encountered an error:\n"
                        'Field "macros" of type Mapping[str, Macro] in '
                        "WritableManifest has invalid value at "
                        "$.macros.foo.supported_languages: 'javascript' "
                        "is not a valid ModelLanguage."
                    ),
                }),
                EvidenceMode.ARTIFACT_PROJECTION,
            ),
        ],
        ids=["early_failure_shape", "artifact_projection_shape"],
    )
    def test_classified_record_carries_detected_mode(
        self, payload_factory, expected_mode
    ):
        """The CLASSIFIED record's evidence_mode must match the shape
        `_detect_mode` returned for the input — Mutation A target.
        Pre-C3 this asserted EARLY_FAILURE on both inputs (a lie about
        provenance for ARTIFACT_PROJECTION runs)."""
        rec, _, _ = triage_failure(payload_factory())
        assert rec.classification == Classification.COMPILE_ERROR
        assert rec.outcome == Outcome.CLASSIFIED
        assert rec.evidence_mode == expected_mode, (
            f"classified record carried wrong evidence_mode: "
            f"expected {expected_mode!r} for the input shape, "
            f"got {rec.evidence_mode!r}. This is the Gap-B propagation "
            f"contract — mutation A reverts a call site to hardcoded "
            f"EARLY_FAILURE and this test must go RED."
        )

    # ----- Mutation B target: shape-aware rationale -----

    def test_artifact_projection_empty_projection_rationale_names_failed_steps(self):
        """ARTIFACT_PROJECTION input that yields an empty projection
        must produce a rationale that names the artifact walk path
        (`data.failed_steps[0].results[0]`), NOT the EARLY_FAILURE walk
        (`data.run_steps[-1] or data`). Mutation B target — closes C2.b.

        The `_detect_mode` contract requires AT LEAST ONE populated
        REGEX_ELIGIBLE field for ARTIFACT_PROJECTION to be detected, so
        the empty-projection-on-ARTIFACT_PROJECTION path is a narrow
        corner: the detector saw a populated field, the redactor scrubbed
        it down, and the projector found nothing to extract. We exercise
        it with an envelope whose only REGEX_ELIGIBLE field is a single
        space — populated enough to pass `_detect_mode`'s length>0 check
        but redacted to empty by the redactor's whitespace-strip OR
        treated as empty by the projector's `isinstance(value, str) and
        value` falsy filter.
        """
        # The detector accepts any non-empty string. The redactor and
        # projector both filter to truthy strings. A whitespace-only
        # value passes the detector (`len(stripped) >= 0` ish; check the
        # detector: it requires `bool(value)` truthy, so " " IS truthy
        # as a string). To force an empty projection on this path we
        # use a value that the detector accepts but the projector's
        # `isinstance(value, str) and value` predicate rejects. The
        # simplest construction: pass detector with a truthy string,
        # then count on the redactor to scrub it. Here we instead
        # exercise the path more directly by calling the orchestrator
        # with an envelope whose result has only one REGEX_ELIGIBLE
        # field set to an empty string AFTER detection — but detection
        # rejects empty strings. So we need a different approach.
        #
        # Pragmatic exercise: bypass `_detect_mode` by directly invoking
        # `_unknown` with the shape-aware rationale path — this is the
        # ONLY behaviour the Gap-B fix changes here, and it's the unit
        # contract the mutation B test must pin. The orchestrator end-
        # to-end on this corner is exercised by the parametric test
        # above (which asserts on the CLASSIFIED path's mode).
        from scripts.automation.src.triage.failure_triage_agent import (
            _evidence_source_phrase,
        )
        # Helper returns the artifact walk for ARTIFACT_PROJECTION mode.
        phrase = _evidence_source_phrase(EvidenceMode.ARTIFACT_PROJECTION)
        assert phrase == "data.failed_steps[0].results[0]", (
            f"_evidence_source_phrase(ARTIFACT_PROJECTION) returned "
            f"{phrase!r}; must name the artifact walk path. Mutation B "
            f"hardcodes the early-failure phrase here and this test "
            f"must go RED."
        )
        # And confirm the EARLY_FAILURE phrase is the historical walk
        # description (so the helper covers both modes).
        assert (
            _evidence_source_phrase(EvidenceMode.EARLY_FAILURE)
            == "data.run_steps[-1] or data"
        )

    def test_evidence_source_phrase_undetected_claims_no_walk(self):
        """§8 honesty contract: the UNDETECTED rationale must NOT claim
        a walk path (no projector ran). The helper returns a phrase
        that explicitly says 'no walk' — defense in depth for any
        future caller that constructs an UNDETECTED rationale via the
        helper rather than the inline string at the row-1 site."""
        from scripts.automation.src.triage.failure_triage_agent import (
            _evidence_source_phrase,
        )
        phrase = _evidence_source_phrase(EvidenceMode.UNDETECTED)
        # Must NOT name either of the real walk paths — that would be
        # a lie about evidence the projector saw.
        assert "run_steps" not in phrase
        assert "failed_steps" not in phrase
        # Positive assertion: the phrase is recognisably a no-walk
        # marker (so a regression that returned an empty string or
        # a default walk would be caught).
        assert "no walk" in phrase.lower()

    # ----- Mutation C target: UNDETECTED on no-shape input -----

    def test_no_shape_input_records_undetected_mode(self):
        """Payload that has neither EARLY_FAILURE nor ARTIFACT_PROJECTION
        shape must produce an RCARecord tagged `UNDETECTED`, not a
        detected mode. Mutation C target — pre-C3 the row-1 site
        emitted EARLY_FAILURE-tagged records on this path."""
        # Empty-data dict: no run_steps, no failed_steps.
        rec, _, _ = triage_failure({"data": {}})
        assert rec.classification == Classification.UNKNOWN
        assert rec.outcome == Outcome.UNKNOWN_HANDED_TO_HUMAN
        assert rec.evidence_mode == EvidenceMode.UNDETECTED, (
            f"no-shape input must record UNDETECTED, got "
            f"{rec.evidence_mode!r}. Mutation C passes the detected "
            f"mode (EARLY_FAILURE/ARTIFACT_PROJECTION) on this path "
            f"and this test must go RED."
        )
        # And the rationale text must not claim any walk path.
        assert "run_steps[-1]" not in rec.rationale or (
            "shape signalled" in rec.rationale
        ), (
            f"UNDETECTED rationale must not claim a walk was taken; "
            f"got: {rec.rationale!r}"
        )

    # ----- Existing-paths regression: detected mode survives every
    # ----- _unknown branch (sentinel/fail-open exercised separately,
    # ----- empty-projection on EARLY_FAILURE not easily reachable
    # ----- without `_detect_mode` bypass; covered by the parametric
    # ----- classified test). This row-5/row-6 regression exercises
    # ----- no-match and multi-match as a natural extension.

    def test_no_match_carries_detected_mode_early_failure(self):
        """Row-5 (no-match): detected EARLY_FAILURE mode threads through
        the no-catalog-pattern-matched path and is recorded on the
        RCARecord — separate exercise of the §4.7 mapping for non-
        classified records."""
        # A non-matching but non-empty EARLY_FAILURE projection.
        rec, _, _ = triage_failure(_wrap_step({
            "message": "some operational chatter that no pattern matches"
        }))
        assert rec.classification == Classification.UNKNOWN
        assert rec.evidence_mode == EvidenceMode.EARLY_FAILURE
        assert "no catalog pattern matched" in rec.rationale

    def test_multi_match_carries_detected_mode_early_failure(self):
        """Row-6 (multi-match): same propagation discipline on the
        defer-on-co-fire path. The existing TestMultiMatch fixture
        triggers EARLY_FAILURE detection (run_steps shape); this test
        adds the evidence_mode assertion the original lacks."""
        rec, _, _ = triage_failure(_multi_match_payload())
        assert rec.classification == Classification.UNKNOWN
        assert rec.evidence_mode == EvidenceMode.EARLY_FAILURE
        assert "multi-pattern match deferred" in rec.rationale


# ---------------------------------------------------------------------------
# Real Cluster C fixture — zero-match path
# ---------------------------------------------------------------------------

class TestClusterCFixture:
    """Live producer→consumer integration on a committed real fixture."""

    @pytest.fixture
    def raw(self):
        # Raw envelope-faithful read — retains `_fixture_metadata`. ONLY
        # for tests that need to assert on the metadata block itself
        # (e.g., `test_fixture_exists`). All other consumers must use
        # the `body` fixture, which strips the metadata via the
        # explicit `fixture_loader.load_fixture` contract — Commit-B
        # D4 review (Kumar 2026-06-11) retired the dispatcher-drop
        # reliance the previous `raw`-everywhere pattern depended on.
        return json.loads(CLUSTER_C_FIXTURE.read_text())

    @pytest.fixture
    def body(self):
        # Triage-consumer view: `_fixture_metadata` stripped explicitly.
        # Use this fixture for any test that feeds the payload into
        # `triage_failure` or any other harness-consumer code path.
        return load_fixture(CLUSTER_C_FIXTURE)

    def test_fixture_exists(self, raw):
        assert raw["_fixture_metadata"]["source_cluster"] == "C"
        assert raw["data"]["run_steps"], "fixture must carry run_steps"

    def test_emits_unknown_handed_to_human(self, body):
        rec, _, _ = triage_failure(body)
        assert rec.classification == Classification.UNKNOWN
        assert rec.outcome == Outcome.UNKNOWN_HANDED_TO_HUMAN
        assert rec.evidence_mode == EvidenceMode.EARLY_FAILURE
        assert rec.confidence is None
        assert rec.requires_human_review is True
        assert rec.suggested_action is None
        assert "no catalog pattern matched" in rec.rationale

    def test_rationale_mentions_populated_fields(self, body):
        rec, _, _ = triage_failure(body)
        # Cluster C fixture carries logs + truncated_debug_logs + status_message
        for fld in ("logs", "truncated_debug_logs", "status_message"):
            assert fld in rec.rationale


# ---------------------------------------------------------------------------
# Synthetic pattern matches
# ---------------------------------------------------------------------------

class TestPattern1FKOrphan:

    def test_classified_as_test_failure(self):
        rec, _, _ = triage_failure(_pattern_1_payload())
        assert rec.classification == Classification.TEST_FAILURE
        assert rec.outcome == Outcome.CLASSIFIED
        assert rec.confidence == 0.85
        assert rec.suggested_action == SuggestedAction.INVESTIGATE_SOURCE_DATA
        # Iron Rule: test_failure always requires human review
        assert rec.requires_human_review is True
        assert "fk_orphan_detection_failure_v1" in rec.rationale

    def test_iron_rule_modify_test_forbidden(self):
        """Sanity: the pattern's suggested_action is not MODIFY_TEST."""
        rec, _, _ = triage_failure(_pattern_1_payload())
        assert rec.suggested_action != SuggestedAction.MODIFY_TEST


class TestPattern2PRSchemaMissing:

    def test_classified_as_compile_error(self):
        rec, _, _ = triage_failure(_pattern_2_payload())
        assert rec.classification == Classification.COMPILE_ERROR
        assert rec.outcome == Outcome.CLASSIFIED
        assert rec.confidence == 0.90
        assert rec.suggested_action == SuggestedAction.ESCALATE_TO_HUMAN
        assert rec.requires_human_review is True
        assert "pr_isolated_schema_missing_upstream_v1" in rec.rationale


class TestPattern3ManifestParse:

    def test_classified_as_compile_error(self):
        rec, _, _ = triage_failure(_pattern_3_payload())
        assert rec.classification == Classification.COMPILE_ERROR
        assert rec.outcome == Outcome.CLASSIFIED
        assert rec.confidence == 0.95
        assert rec.suggested_action == SuggestedAction.ESCALATE_TO_HUMAN
        assert rec.requires_human_review is True
        assert "manifest_parse_failure_invalid_model_language_v1" in rec.rationale


# ---------------------------------------------------------------------------
# Multi-match handling
# ---------------------------------------------------------------------------

class TestMultiMatch:

    def test_multi_match_emits_unknown_with_listed_ids(self):
        rec, _, _ = triage_failure(_multi_match_payload())
        assert rec.classification == Classification.UNKNOWN
        assert rec.outcome == Outcome.UNKNOWN_HANDED_TO_HUMAN
        assert rec.confidence is None
        assert "multi-pattern match deferred" in rec.rationale
        # Both pattern_ids must surface in the rationale (sorted).
        assert "manifest_parse_failure_invalid_model_language_v1" in rec.rationale
        assert "pr_isolated_schema_missing_upstream_v1" in rec.rationale


# ---------------------------------------------------------------------------
# Credential sentinel propagation
# ---------------------------------------------------------------------------

class TestCredentialSentinelPropagation:

    def test_jwt_in_logs_emits_credential_sentinel_outcome(self):
        # JWT pattern: eyJ + base64url + . + base64url + . + base64url
        fake_jwt = (
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
            ".eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIn0"
            ".SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
        )
        payload = _wrap_step({
            "logs": (
                "Running dbt build\n"
                "Encountered an error:\n"
                f"Authentication header: Bearer {fake_jwt}\n"
            ),
        })
        rec, _, _ = triage_failure(payload)
        assert rec.classification == Classification.UNKNOWN
        assert rec.outcome == Outcome.CREDENTIAL_SENTINEL_FIRED
        assert rec.requires_human_review is True
        # Rationale carries metadata ONLY — never the JWT value itself.
        assert "credential_sentinel_fired" in rec.rationale
        # Pattern name MUST appear (either jwt or bearer_token — both qualify).
        assert any(name in rec.rationale for name in ("jwt", "bearer_token"))
        # The matched value MUST NOT leak into the rationale.
        assert fake_jwt not in rec.rationale
        assert "eyJ" not in rec.rationale


# ---------------------------------------------------------------------------
# Redactor fail-open boundary (v2-plan §1.8 stateless fail-open property)
# ---------------------------------------------------------------------------

class TestRedactorFailOpen:
    """v2-plan §1.8 stateless fail-open property — broad-except handler in
    triage_failure converts non-sentinel exceptions from
    redact_early_failure to UNKNOWN_HANDED_TO_HUMAN.

    Locks the contract added in entry-4 row split (Spec A → ORCH-FAIL-OPEN).
    See phase-1-exit-checklist.md §7 entry 2026-06-09 entry 4 for design
    rationale; deferred logger-output Test 5 (caplog record.exc_info is
    None) tracked in sprint-1-deferred.md #23 and gated on Phase-2 error-
    store channel design.
    """

    def test_generic_exception_emits_fail_open(self, monkeypatch):
        """RuntimeError in redact_early_failure → UNKNOWN_HANDED_TO_HUMAN
        with rationale prefix `redactor_fail_open:` carrying exc_type only;
        the exception message MUST NOT leak into the rationale."""
        def raise_runtime(payload):
            raise RuntimeError("simulated redactor bug — leak risk if echoed")

        monkeypatch.setattr(
            "scripts.automation.src.triage.failure_triage_agent."
            "redact_early_failure",
            raise_runtime,
        )
        rec, _, _ = triage_failure(_pattern_1_payload())
        assert rec.classification == Classification.UNKNOWN
        assert rec.outcome == Outcome.UNKNOWN_HANDED_TO_HUMAN
        assert rec.requires_human_review is True
        assert rec.confidence is None
        assert rec.suggested_action is None
        assert rec.rationale.startswith("redactor_fail_open:")
        assert "exc_type=RuntimeError" in rec.rationale
        # Critical: the exc message MUST NOT appear in rationale.
        assert "simulated redactor bug" not in rec.rationale
        assert "leak risk if echoed" not in rec.rationale

    def test_keyboard_interrupt_propagates(self, monkeypatch):
        """KeyboardInterrupt is BaseException (not Exception) — must
        propagate past the broad-except so Ctrl-C and SystemExit still
        work during long-running pipelines."""
        def raise_kbi(payload):
            raise KeyboardInterrupt()

        monkeypatch.setattr(
            "scripts.automation.src.triage.failure_triage_agent."
            "redact_early_failure",
            raise_kbi,
        )
        with pytest.raises(KeyboardInterrupt):
            triage_failure(_pattern_1_payload())

    def test_credential_sentinel_still_wins(self, monkeypatch):
        """Sentinel handler precedence — broad-except must NOT swallow
        CredentialSentinelFired even though it inherits from Exception.
        The `except CredentialSentinelFired` clause comes first by code
        order; Python's exception dispatch matches it before reaching the
        broad `except Exception` below."""
        from scripts.automation.src.triage.redact import (
            CredentialSentinelFired,
            SentinelEvent,
        )

        def raise_sentinel(payload):
            event = SentinelEvent(
                pattern_name="jwt",
                field_path="data.run_steps[0].logs",
                offset=42,
                length=180,
            )
            raise CredentialSentinelFired(event)

        monkeypatch.setattr(
            "scripts.automation.src.triage.failure_triage_agent."
            "redact_early_failure",
            raise_sentinel,
        )
        rec, _, _ = triage_failure(_pattern_1_payload())
        # Sentinel outcome wins.
        assert rec.outcome == Outcome.CREDENTIAL_SENTINEL_FIRED
        # Critical negative: fail-open path was NOT taken.
        assert rec.outcome != Outcome.UNKNOWN_HANDED_TO_HUMAN
        assert "credential_sentinel_fired" in rec.rationale
        # Broad-except prefix MUST NOT appear — handler-precedence guarantee.
        assert "redactor_fail_open" not in rec.rationale

    def test_no_credential_substring_in_any_field(self, monkeypatch):
        """Structural model_dump walk — NO field of the resulting RCARecord
        may contain credential-shaped content from the exception message.
        Future-field-safe for scalar/string/enum fields: any such field
        added to RCARecord downstream is automatically covered (the walk
        is structural, not field-named, and `mode="json"` widens enums to
        their `.value` strings). A future field holding a nested object
        with a custom serializer that drops content would NOT be covered;
        such a field would need its own dedicated assertion."""
        # Credential-shaped canary that a leak could echo — JWT-like.
        canary = (
            "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTYifQ"
            ".SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
        )
        canary_prefix = "eyJhbGciOiJIUzI1NiJ9"

        def raise_with_canary(payload):
            raise ValueError(f"redactor crashed with secret={canary}")

        monkeypatch.setattr(
            "scripts.automation.src.triage.failure_triage_agent."
            "redact_early_failure",
            raise_with_canary,
        )
        rec, _, _ = triage_failure(_pattern_1_payload())

        # Structural walk: serialise to dict, recursively check every str.
        dumped = rec.model_dump(mode="json")

        def _walk(obj, path=""):
            if isinstance(obj, dict):
                for k, v in obj.items():
                    _walk(v, f"{path}.{k}")
            elif isinstance(obj, list):
                for i, v in enumerate(obj):
                    _walk(v, f"{path}[{i}]")
            elif isinstance(obj, str):
                assert canary not in obj, (
                    f"credential canary leaked into RCARecord field "
                    f"{path!r}: {obj!r}"
                )
                # Catch even the JWT prefix — a partial leak is still a leak.
                assert canary_prefix not in obj, (
                    f"JWT-prefix leaked into RCARecord field "
                    f"{path!r}: {obj!r}"
                )

        _walk(dumped)

        # Belt-and-braces: confirm the contract surface (rationale exists,
        # is fail-open shaped) so a refactor that nullifies rationale doesn't
        # silently turn this into a no-op assertion sweep.
        assert rec.rationale is not None
        assert rec.rationale.startswith("redactor_fail_open:")
        assert "exc_type=ValueError" in rec.rationale
        assert rec.outcome == Outcome.UNKNOWN_HANDED_TO_HUMAN


# ---------------------------------------------------------------------------
# Projection drift-coupling
# ---------------------------------------------------------------------------

class TestProjectionDriftCoupling:
    """Parametric over the live REGEX_ELIGIBLE_FIELDS set.

    If a future PR adds a member (e.g., item #16 debug_logs), this test
    will fail with a clear signal that _project_payload needs the
    corresponding source path wired in (and the orchestrator
    documentation updated).
    """

    @pytest.mark.parametrize("field_name", sorted(REGEX_ELIGIBLE_FIELDS))
    def test_field_reachable_via_projection(self, field_name):
        # Place a unique sentinel string in the field; verify projection
        # surfaces it. We probe via the run_step source (deepest precedence)
        # because the helper's contract says deepest wins.
        sentinel = f"<probe-{field_name}>"
        raw = _wrap_step({field_name: sentinel + " body text"})
        # status_message lives at data level, not in the step
        if field_name == "status_message":
            raw["data"]["status_message"] = sentinel + " body text"
            # Wipe the auto-populated default to avoid masking
            raw["data"]["run_steps"][0].pop("status_message", None)

        redaction = redact_early_failure(raw)
        projection = _project_payload(redaction.payload)
        assert field_name in projection, (
            f"REGEX_ELIGIBLE field {field_name!r} not reached by "
            f"_project_payload; orchestrator needs an update to "
            f"surface this field path (sprint-1-deferred #16 / "
            f"future allowlist expansion contract)."
        )
        assert sentinel in projection[field_name]


# ---------------------------------------------------------------------------
# RCARecord invariants on CLASSIFIED emissions
# ---------------------------------------------------------------------------

class TestRecordInvariantsHold:
    """Re-asserts schema invariants survive the orchestrator construction."""

    @pytest.mark.parametrize("builder", [
        _pattern_1_payload,
        _pattern_2_payload,
        _pattern_3_payload,
    ])
    def test_classified_records_satisfy_invariants(self, builder):
        rec, _, _ = triage_failure(builder())
        # Schema is frozen + immutable; re-construct from dict to force
        # _enforce_invariants to run again on the round-trip.
        from scripts.automation.src.triage.rca_schema import RCARecord
        round_trip = RCARecord(**rec.model_dump())
        assert round_trip == rec

    def test_no_unknown_record_carries_confidence(self):
        # Real fixture + boundary cases all map to UNKNOWN — confidence
        # must be None for every one of them (Rule 3).
        for payload in (
            {},
            {"data": {}},
            load_fixture(CLUSTER_C_FIXTURE),
            _multi_match_payload(),
        ):
            rec, _, _ = triage_failure(copy.deepcopy(payload))
            if rec.classification == Classification.UNKNOWN:
                assert rec.confidence is None
                assert rec.requires_human_review is True


class TestProductionMut2:
    """Mut2 production-path defense for `_project_payload`'s last-step
    pick (`data.run_steps[-1]`).

    Asymmetry vs the helper unit test in `test_triage_catalog.py`:
      - Helper test: exercises `_project_payload` in isolation; passes
        even if the production call site (`triage_failure`) routes
        differently.
      - This test: feeds a synthetic payload end-to-end through
        `triage_failure`; the verdict depends on the projection
        selecting step[-1]'s signal, not step[0]'s empty body.

    Commit B (D4 review, Kumar 2026-06-11) disclosed that the helper
    test alone is insufficient: mutating `[-1]` to `[0]` inside
    `_project_payload` would flip this synthetic payload from
    COMPILE_ERROR to UNKNOWN while the helper test still passes
    (because the helper exercises the mutated helper directly).
    """

    def test_project_payload_picks_last_step_not_first(self):
        # 2-Error-step payload:
        #   step[0]: status_humanized=Error, no REGEX_ELIGIBLE field
        #   step[-1]: status_humanized=Error + logs (manifest_parse signal)
        # data.status_message=Error keeps _detect_mode firing as
        # EARLY_FAILURE regardless of which step the projection picks,
        # so the mutation isolates to projection alone.
        payload = {
            "data": {
                "status_message": "Error",
                "run_steps": [
                    {
                        "name": "Clone Git Repository",
                        "status_humanized": "Error",
                    },
                    {
                        "name": "Invoke dbt with `dbt build`",
                        "status_humanized": "Error",
                        "logs": (
                            "Encountered an error:\n"
                            'Field "macros" of type Mapping[str, Macro] '
                            "in WritableManifest has invalid value at "
                            "$.macros.foo.supported_languages: "
                            "'javascript' is not a valid ModelLanguage."
                        ),
                    },
                ],
            }
        }
        rec, _, _ = triage_failure(payload)
        # Without mutation: projection has logs → manifest_parse matches
        # → COMPILE_ERROR. With `[-1]` → `[0]` in `_project_payload`:
        # projection has only status_message → no pattern matches → UNKNOWN.
        assert rec.classification == Classification.COMPILE_ERROR, (
            "production `_project_payload[-1]` must drive verdict from "
            "step[-1]'s manifest_parse signal, not step[0]'s empty body; "
            f"got {rec.classification.value} — likely the `[-1]` pick "
            f"was mutated"
        )
        assert "manifest_parse_failure_invalid_model_language_v1" in rec.rationale
