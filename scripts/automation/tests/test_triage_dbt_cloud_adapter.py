"""Tests for the dbt Cloud `get_job_run_error` adapter — Component 4.

Coverage:
  * Boundary contract — TypeError on non-dict parsed_error / run_metadata;
    required-kwarg discipline (carry-1 from C3 sign-off).
  * H8 envelope shape — `data` wrapper added, single-element
    `failed_steps` and `results` lists ([0][0] contract C2 + Mutation A
    pin both depend on).
  * Gap-F normalization — `truncated_logs` → `truncated_debug_logs`
    rename, guarded by `is not None`; MCP name dropped; NOT also
    emitted under `logs` (no untruthful Path-γ provenance).
  * Sidecar run_metadata — envelope excludes run_id/job_id/
    environment_id/git_sha (G5 boundary).
  * Per-result fan-out — N results in a step → N envelopes; each
    envelope carries one result; multi-result fixture exercises N>1.
  * Empty-results contract assertion — Gap-E `results` always ≥1
    contract enforced via raise (Mutation C target — silent-drop must
    cause this test to go RED).
  * Discriminator-agnostic — model-execution and pre-model results
    BOTH pass through with all fields preserved (`message` survives
    on model-execution; `truncated_debug_logs` post-rename survives on
    pre-model); the adapter does NOT branch on `unique_id is None`
    beyond the Gap-F normalization guard.
  * End-to-end through `triage_failure` — both real golden shapes
    classify as UNKNOWN with `evidence_mode=ARTIFACT_PROJECTION`
    (491 HASHDIFF matches no pattern per §2; pre-model manifest-parse
    content doesn't match P2's PR-isolated-schema regex/substring and
    P3 reads `logs` not `truncated_debug_logs` — both correctly
    classify as "I can't classify this, here's the evidence").

Mutation targets covered:
  * Mutation A: drop the `data` wrapper → end-to-end classification
    test goes RED (`_detect_mode` returns UNDETECTED).
  * Mutation B: skip the Gap-F rename → pre-model envelope no longer
    has `truncated_debug_logs`; the rename-presence test goes RED.
  * Mutation C: silently emit `[]` on empty results → contract-
    violation test (expects raise) goes RED.
  * Mutation D: emit per-step instead of per-result → multi-result
    fan-out test (expects N envelopes for N results) goes RED.
"""

from __future__ import annotations

from typing import Any, cast

import pytest

from scripts.automation.src.triage.dbt_cloud_adapter import (
    EmptyResultsContractViolation,
    from_dbt_cloud_error,
)
from scripts.automation.src.triage.failure_triage_agent import (
    triage_failure,
)
from scripts.automation.src.triage.rca_schema import (
    Classification,
    EvidenceMode,
    Outcome,
)


# ---------------------------------------------------------------------------
# Golden fixtures — real bytes from the Gate-A/E scan
# ---------------------------------------------------------------------------
# These mirror the exact field shapes the directive specified from the
# scanned runs. The model-execution golden carries the verbatim field
# values for run 491165226. The pre-model golden carries a representative
# truncated slice of run 485821754's real log content (the full
# 1,402,234 chars are out of scope to check in — the slice retains the
# "Encountered an error:" anchor at byte 315 and the WritableManifest
# error signature, which is the structural shape downstream P2/P3
# matchers care about). Multi-result is explicitly synthetic-but-
# realistic (the Gate-A/E scan only observed single-result runs); empty-
# results is the contract-violation exemplar.

# ---------------------------------------------------------------------------
# Model-execution shape — run 491165226 (verbatim from Gate-A/E scan)
# ---------------------------------------------------------------------------
#   unique_id:     populated ("model.dbt_datavault.fact_mrp_lines")
#   compiled_code: populated (PREVIEW_FIELD — redactor will literal-strip)
#   truncated_logs: null (Gap-F rename branch NOT taken)
#   message:       real Snowflake error text (REGEX_ELIGIBLE — P1 signal field
#                  on the model-execution shape; survival into envelope
#                  load-bearing for any future P* targeting Snowflake errors)

_RUN_491165226_RESULT = {
    "unique_id": "model.dbt_datavault.fact_mrp_lines",
    "relation_name": "datavault_dev.bus_vault.fact_mrp_lines",
    "status": "error",
    "message": (
        "Database Error in model fact_mrp_lines "
        "(models/bus_vault/fact/fact_mrp_lines.sql)\n"
        "  002000 (42000): SQL compilation error: error line 47 at position 12\n"
        "  invalid identifier 'MATERIAL_NUMBER'"
    ),
    "compiled_code": (
        "---- SRC LAYER ----\n"
        "WITH src_mrp AS (\n"
        "    SELECT * FROM {{ ref('v_psa_stg_mrp__sap') }}\n"
        ")\n"
        "SELECT * FROM src_mrp"
    ),
    "truncated_logs": None,
}


def _model_execution_parsed_error() -> dict:
    """Real-shape parsed `get_job_run_error` response for run 491165226.

    Top-level `failed_steps` (no `data` wrapper — that's what the
    adapter adds). Single failed step, single result. Matches the
    Gate-A/E scan's verbatim field set for the 491 HASHDIFF failure.
    """
    return {
        "failed_steps": [
            {
                "step_name": "Invoke dbt with `dbt build`",
                "target": "datavault_dev",
                "finished_at": "2026-06-12T14:22:18.000Z",
                "results": [_RUN_491165226_RESULT],
            }
        ],
    }


# ---------------------------------------------------------------------------
# Pre-model shape — run-485821754-shaped (real log slice)
# ---------------------------------------------------------------------------
#   unique_id:      null  (DISCRIMINATOR — pre-model signal)
#   compiled_code:  null  (DISCRIMINATOR — pre-model signal)
#   relation_name:  fixed sentinel "No database relation"
#   message:        fixed 47-char sentinel "run_results.json not available
#                   - returning logs"
#   truncated_logs: REPRESENTATIVE 800-char slice of run 485821754's real
#                   log content (full payload is 1,402,234 chars; the
#                   anchor "Encountered an error:" is at byte 315 of the
#                   real stream). Slice is labeled as truncated below.
#
# The slice preserves the structurally important bytes: the "Encountered
# an error:" anchor + the WritableManifest error line that P3 keys on
# (P3 reads `logs` not `truncated_debug_logs`, so the slice is here for
# byte-shape realism, not for matcher firing — see byte-review item 5
# on P2 NOT firing on this content).

_RUN_485821754_LOG_SLICE = (
    "08:10:51  Running dbt...\n"
    "/venv/dbt-sha-bb1ffc4530f741cd1a9785c66c7b017bb1ba6932/lib/python3.11/"
    "site-packages/snowflake/connector/vendored/requests/__init__.py:113: "
    "RequestsDependencyWarning: urllib3 (2.6.3) or chardet (7.4.3)/"
    "charset_normalizer (3.4.7) doesn't match a supported version!\n"
    "  warnings.warn(\n"
    "08:11:01  Encountered an error:\n"
    'Field "macros" of type Mapping[str, Macro] in WritableManifest has '
    "invalid value {'macro.dbt_datavault.test_accepted_values': {'name': "
    "'test_accepted_values', 'resource_type': 'macro', 'package_name': "
    "'dbt_datavault', 'path': 'macros/accepted_valids.sql', "
    "'original_file_path': 'macros/accepted_valids.sql', 'unique_id': "
    "'macro.dbt_datavault.test_accepted_values', 'supported_languages': "
    "['javascript']}}\n"
    "[truncated — real payload is 1,402,234 chars; slice captures the "
    "'Encountered an error:' anchor + WritableManifest signature line "
    "which are the structurally important bytes for P3 matchability]"
)

_RUN_485821754_RESULT = {
    "unique_id": None,
    "relation_name": "No database relation",
    "status": "error",
    "message": "run_results.json not available - returning logs",
    "compiled_code": None,
    "truncated_logs": _RUN_485821754_LOG_SLICE,
}


def _pre_model_parsed_error() -> dict:
    """Real-shape parsed `get_job_run_error` response for a 485821754-
    shaped pre-model failure.

    Top-level `failed_steps` (no `data` wrapper). Single failed step,
    single result. Field shape matches the Gate-A/E scan verbatim;
    `truncated_logs` content is a representative truncated slice of the
    real ~1.4M-char log payload, labeled inline.
    """
    return {
        "failed_steps": [
            {
                "step_name": "Invoke dbt with `dbt build`",
                "target": "datavault_qa",
                "finished_at": "2026-05-27T08:11:06.048Z",
                "results": [_RUN_485821754_RESULT],
            }
        ],
    }


# ---------------------------------------------------------------------------
# Multi-result shape — SYNTHETIC (labeled — Gate-A/E scan observed only
# single-result runs; this exists to exercise fan-out N>1)
# ---------------------------------------------------------------------------

def _multi_result_parsed_error() -> dict:
    """SYNTHETIC 2-result failed step. The Gate-A/E scan corpus only
    observed single-result runs, so this fixture is constructed-but-
    realistic to exercise per-result fan-out (Mutation D target —
    emitting per-step instead would yield 1 envelope where this
    expects 2).
    """
    return {
        "failed_steps": [
            {
                "step_name": "Invoke dbt with `dbt build`",
                "target": "datavault_dev",
                "finished_at": "2026-06-12T14:22:18.000Z",
                "results": [
                    {
                        "unique_id": "model.dbt_datavault.dim_customer",
                        "relation_name": "datavault_dev.bus_vault.dim_customer",
                        "status": "error",
                        "message": (
                            "Database Error in model dim_customer\n"
                            "  invalid identifier 'CUSTOMER_KEY'"
                        ),
                        "compiled_code": "SELECT * FROM customer_hub",
                        "truncated_logs": None,
                    },
                    {
                        "unique_id": "model.dbt_datavault.dim_product",
                        "relation_name": "datavault_dev.bus_vault.dim_product",
                        "status": "error",
                        "message": (
                            "Database Error in model dim_product\n"
                            "  invalid identifier 'PRODUCT_KEY'"
                        ),
                        "compiled_code": "SELECT * FROM product_hub",
                        "truncated_logs": None,
                    },
                ],
            }
        ],
    }


# ---------------------------------------------------------------------------
# Empty-results — contract violation exemplar (Gap-E asserted, not assumed)
# ---------------------------------------------------------------------------

def _empty_results_parsed_error() -> dict:
    """Failed step with `results: []` — violates Gap-E contract.

    Real dbt-Cloud get_job_run_error responses always carry ≥1 result
    per failed step. This fixture exists only to lock the
    EmptyResultsContractViolation assertion. Mutation C reverts the
    raise to silent-drop (return []) and this test must go RED.
    """
    return {
        "failed_steps": [
            {
                "step_name": "Invoke dbt with `dbt build`",
                "target": "datavault_dev",
                "finished_at": "2026-06-12T14:22:18.000Z",
                "results": [],
            }
        ],
    }


# ---------------------------------------------------------------------------
# Standard sidecar
# ---------------------------------------------------------------------------

def _run_metadata() -> dict:
    """Sidecar provenance — flows to C5 writer as kwargs. NEVER enters
    the envelope (G5)."""
    return {
        "run_id": 491165226,
        "job_id": 786800,
        "environment_id": 296452,
        "git_sha": "abc123def4567890",
    }


# ===========================================================================
# Boundary contract
# ===========================================================================

class TestBoundaryContract:

    def test_non_dict_parsed_error_raises_type_error(self):
        with pytest.raises(TypeError, match="parsed_error must be dict"):
            from_dbt_cloud_error("not a dict", _run_metadata())

    def test_none_parsed_error_raises_type_error(self):
        with pytest.raises(TypeError, match="parsed_error must be dict"):
            from_dbt_cloud_error(None, _run_metadata())

    def test_list_parsed_error_raises_type_error(self):
        """Lists are NOT silently coerced to a dict — common shape
        confusion from a sloppy upstream parser is surfaced loudly."""
        with pytest.raises(TypeError, match="parsed_error must be dict"):
            from_dbt_cloud_error([{"failed_steps": []}], _run_metadata())

    def test_non_dict_run_metadata_raises_type_error(self):
        with pytest.raises(TypeError, match="run_metadata must be dict"):
            from_dbt_cloud_error(_model_execution_parsed_error(), "not a dict")

    def test_run_metadata_is_required_kwarg_no_default(self):
        """Carry-1 from C3 sign-off — provenance args have no default.
        Forgetting to pass run_metadata is a TypeError at call time,
        not a silent default that propagates a wrong tag downstream.
        """
        with pytest.raises(TypeError):
            # Missing run_metadata entirely — should fail call-time,
            # not silently emit an envelope with no provenance attached.
            # Cast to Any to launder the deliberately-malformed call
            # past the static type checker; runtime behavior is the
            # contract under test.
            cast(Any, from_dbt_cloud_error)(_model_execution_parsed_error())

    def test_missing_failed_steps_returns_empty_list(self):
        """Parsed dict with no `failed_steps` key → []. (Distinct from
        EMPTY `results` on a present step, which raises — see
        TestEmptyResultsContract.)"""
        envelopes = from_dbt_cloud_error({}, _run_metadata())
        assert envelopes == []

    def test_non_list_failed_steps_returns_empty_list(self):
        envelopes = from_dbt_cloud_error(
            {"failed_steps": "not a list"}, _run_metadata()
        )
        assert envelopes == []


# ===========================================================================
# H8 envelope shape — `data` wrapper + [0][0] contract (Mutation A target)
# ===========================================================================

class TestH8EnvelopeShape:

    def test_envelope_has_data_wrapper(self):
        """The adapter ADDS the `data` wrapper (MCP returns
        `failed_steps` at TOP level). The wrapper is what makes
        `_detect_mode` reach the ARTIFACT_PROJECTION branch via
        `raw.get('data')`. Mutation A: drop the wrapper → end-to-end
        classification (TestEndToEnd) breaks because _detect_mode
        returns UNDETECTED.
        """
        envelopes = from_dbt_cloud_error(
            _model_execution_parsed_error(), _run_metadata()
        )
        assert len(envelopes) == 1
        envelope = envelopes[0]
        assert "data" in envelope, (
            "envelope must have `data` wrapper — Mutation A reverts this "
            "and asserts the end-to-end classification breaks"
        )
        assert "failed_steps" in envelope["data"]

    def test_envelope_failed_steps_is_single_element_list(self):
        """One envelope per result → each envelope's `failed_steps` list
        carries exactly ONE step (the projector + Mutation-A pin both
        depend on `data['failed_steps'][0]`).
        """
        envelopes = from_dbt_cloud_error(
            _model_execution_parsed_error(), _run_metadata()
        )
        envelope = envelopes[0]
        failed_steps = envelope["data"]["failed_steps"]
        assert isinstance(failed_steps, list)
        assert len(failed_steps) == 1

    def test_envelope_results_is_single_element_list(self):
        """Per-result fan-out → each envelope's step carries exactly ONE
        result (the `[0]` position the C2 projector's `results[0]` walk
        and Mutation A pin both depend on).
        """
        envelopes = from_dbt_cloud_error(
            _model_execution_parsed_error(), _run_metadata()
        )
        results = envelopes[0]["data"]["failed_steps"][0]["results"]
        assert isinstance(results, list)
        assert len(results) == 1

    def test_envelope_preserves_step_name_target_finished_at(self):
        """Spec §4.5 names these three fields explicitly. Redactor may
        drop them downstream (step_name/target are not in PASSTHROUGH
        today — that's the deferred fast-follow), but the adapter must
        emit them so the redactor sees them.
        """
        envelopes = from_dbt_cloud_error(
            _model_execution_parsed_error(), _run_metadata()
        )
        step = envelopes[0]["data"]["failed_steps"][0]
        assert step["step_name"] == "Invoke dbt with `dbt build`"
        assert step["target"] == "datavault_dev"
        assert step["finished_at"] == "2026-06-12T14:22:18.000Z"


# ===========================================================================
# Gap-F normalization — `truncated_logs` → `truncated_debug_logs`
#                       (Mutation B target)
# ===========================================================================

class TestGapFNormalization:

    def test_pre_model_envelope_has_truncated_debug_logs_after_rename(self):
        """The pre-model result carries `truncated_logs` (MCP name);
        the adapter renames it to `truncated_debug_logs` (catalog
        vocab, in REGEX_ELIGIBLE_FIELDS). Mutation B reverts the
        rename and this test goes RED — the pre-model envelope would
        end up with `truncated_logs` (a name no field-allowlist knows)
        and the projector + redactor would silently drop it.

        Surface-finding: this rename-presence assertion is the SOLE
        Mutation B coverage path because the stronger end-to-end
        P2-fires-on-pre-model assertion does NOT apply — real 485821754
        log content matches P3 (`Field "macros" of type Mapping[str,
        Macro] in WritableManifest`), and P3 reads `logs` not
        `truncated_debug_logs`. P2 reads `truncated_debug_logs` but
        its content-signal is for the PR-isolated-schema-missing
        failure mode (runs 487333396/487313189), which is different
        content entirely. So the rename presence + ABSENCE of the
        MCP name carry all of Mutation B's coverage on this fixture.
        """
        envelopes = from_dbt_cloud_error(
            _pre_model_parsed_error(), _run_metadata()
        )
        result = envelopes[0]["data"]["failed_steps"][0]["results"][0]
        assert "truncated_debug_logs" in result, (
            "Gap-F rename did not fire — Mutation B target. The "
            "MCP name `truncated_logs` must be remapped to the "
            "catalog vocab `truncated_debug_logs` so the redactor's "
            "REGEX_ELIGIBLE_FIELDS allowlist recognizes it."
        )

    def test_pre_model_envelope_drops_mcp_truncated_logs_name(self):
        """The MCP-side `truncated_logs` name is DROPPED — emitting
        BOTH names would shadow the rename and allow downstream code
        to read from the wrong field. Defense-in-depth complement to
        the rename-presence assertion.
        """
        envelopes = from_dbt_cloud_error(
            _pre_model_parsed_error(), _run_metadata()
        )
        result = envelopes[0]["data"]["failed_steps"][0]["results"][0]
        assert "truncated_logs" not in result, (
            "MCP `truncated_logs` name must be dropped after Gap-F "
            "rename; emitting both names creates a downstream "
            "field-priority ambiguity."
        )

    def test_pre_model_envelope_does_not_path_gamma_to_logs(self):
        """Spec §4.3 rejects Path-γ: the renamed content must NOT also
        appear under `logs`. That field is the EARLY_FAILURE walk's
        field; attributing artifact-projection content to it would be
        an untruthful-provenance violation (the same class of bug C3
        closed for evidence_mode rationale).
        """
        envelopes = from_dbt_cloud_error(
            _pre_model_parsed_error(), _run_metadata()
        )
        result = envelopes[0]["data"]["failed_steps"][0]["results"][0]
        assert "logs" not in result, (
            "Path-γ violation: artifact-projection content must not "
            "be emitted under `logs` (the EARLY_FAILURE walk's field). "
            "The renamed `truncated_debug_logs` lives at exactly one "
            "field name."
        )

    def test_pre_model_envelope_content_preserved_after_rename(self):
        """The rename is a vocab-translation, NOT a content filter — the
        full byte content under `truncated_logs` lands under
        `truncated_debug_logs` unchanged. (Truncation lives in the
        redactor, downstream.)"""
        envelopes = from_dbt_cloud_error(
            _pre_model_parsed_error(), _run_metadata()
        )
        result = envelopes[0]["data"]["failed_steps"][0]["results"][0]
        assert result["truncated_debug_logs"] == _RUN_485821754_LOG_SLICE

    def test_model_execution_no_rename_when_truncated_logs_is_none(self):
        """Gap-F guard is `is not None` — model-execution results with
        `truncated_logs: None` skip the rename (no field emitted under
        either name). The discriminator-agnostic posture means the
        adapter doesn't need to know it's processing a model-execution
        result; the guard alone handles both shapes.
        """
        envelopes = from_dbt_cloud_error(
            _model_execution_parsed_error(), _run_metadata()
        )
        result = envelopes[0]["data"]["failed_steps"][0]["results"][0]
        assert "truncated_debug_logs" not in result
        assert "truncated_logs" not in result

    def test_rename_preserves_empty_string_distinct_from_none(self):
        """Subtle: `is not None` (not truthiness). An explicit empty
        string under `truncated_logs` should still rename (vocab
        translation), not be conflated with None. The downstream
        projector's truthy filter handles the empty-string case
        separately.
        """
        envelopes = from_dbt_cloud_error(
            {
                "failed_steps": [
                    {
                        "step_name": "step",
                        "target": "tgt",
                        "finished_at": "2026-06-12T14:22:18.000Z",
                        "results": [
                            {
                                "unique_id": None,
                                "truncated_logs": "",  # empty, NOT None
                            }
                        ],
                    }
                ],
            },
            _run_metadata(),
        )
        result = envelopes[0]["data"]["failed_steps"][0]["results"][0]
        assert "truncated_debug_logs" in result
        assert result["truncated_debug_logs"] == ""
        assert "truncated_logs" not in result


# ===========================================================================
# Sidecar run_metadata — G5 boundary (envelope excludes provenance)
# ===========================================================================

class TestSidecarRunMetadata:

    def test_envelope_excludes_run_id_job_id_environment_id_git_sha(self):
        """Spec G5: run_metadata is a SIDECAR — flows separately to the
        C5 writer as kwargs. None of its keys leak into the envelope.
        """
        envelopes = from_dbt_cloud_error(
            _model_execution_parsed_error(), _run_metadata()
        )
        envelope = envelopes[0]
        # Recursively walk the envelope and assert NONE of the
        # sidecar keys appear at any nesting level. (`unique_id` IS
        # allowed at the result level — it's a dbt-Cloud field, not
        # a run_metadata field.)
        forbidden = {"run_id", "job_id", "environment_id", "git_sha"}
        found = _collect_keys_at_any_depth(envelope)
        leaked = forbidden & found
        assert not leaked, (
            f"run_metadata keys leaked into envelope: {leaked!r}. "
            f"G5 boundary: provenance is a sidecar, not envelope content."
        )

    def test_envelope_does_not_carry_run_metadata_value(self):
        """Stronger assertion: even the VALUES from run_metadata don't
        appear in the envelope (a sloppy adapter might rename keys but
        still embed the values).
        """
        envelopes = from_dbt_cloud_error(
            _model_execution_parsed_error(), _run_metadata()
        )
        envelope = envelopes[0]
        # Walk all str values; assert the git_sha string is nowhere.
        all_str_values = _collect_str_values_at_any_depth(envelope)
        assert "abc123def4567890" not in all_str_values, (
            "git_sha value leaked into envelope — sidecar boundary "
            "must be by-name AND by-value."
        )


def _collect_keys_at_any_depth(node) -> set:
    keys: set = set()
    if isinstance(node, dict):
        for k, v in node.items():
            keys.add(k)
            keys |= _collect_keys_at_any_depth(v)
    elif isinstance(node, list):
        for item in node:
            keys |= _collect_keys_at_any_depth(item)
    return keys


def _collect_str_values_at_any_depth(node) -> list:
    out: list = []
    if isinstance(node, dict):
        for v in node.values():
            out.extend(_collect_str_values_at_any_depth(v))
    elif isinstance(node, list):
        for item in node:
            out.extend(_collect_str_values_at_any_depth(item))
    elif isinstance(node, str):
        out.append(node)
    return out


# ===========================================================================
# Per-result fan-out (Mutation D target)
# ===========================================================================

class TestFanOut:

    def test_single_result_emits_one_envelope(self):
        envelopes = from_dbt_cloud_error(
            _model_execution_parsed_error(), _run_metadata()
        )
        assert len(envelopes) == 1

    def test_multi_result_emits_n_envelopes_one_per_result(self):
        """Fan-out is per-RESULT, NOT per-step. A step with 2 results
        → 2 envelopes. Mutation D reverts to per-step emission (1
        envelope per step regardless of result count) and this test
        goes RED.
        """
        envelopes = from_dbt_cloud_error(
            _multi_result_parsed_error(), _run_metadata()
        )
        assert len(envelopes) == 2, (
            "Mutation D target — per-result fan-out lost. 2 results "
            "in a step must produce 2 envelopes, one per result."
        )

    def test_multi_result_envelopes_carry_distinct_unique_ids(self):
        """Each envelope's single result corresponds to a distinct
        underlying failure — the dim_customer and dim_product results
        from the synthetic 2-result fixture must each land in their
        own envelope, not be combined into one envelope's results list.
        """
        envelopes = from_dbt_cloud_error(
            _multi_result_parsed_error(), _run_metadata()
        )
        unique_ids = [
            env["data"]["failed_steps"][0]["results"][0]["unique_id"]
            for env in envelopes
        ]
        assert set(unique_ids) == {
            "model.dbt_datavault.dim_customer",
            "model.dbt_datavault.dim_product",
        }


# ===========================================================================
# Empty-results contract assertion (Mutation C target)
# ===========================================================================

class TestEmptyResultsContract:

    def test_empty_results_raises_contract_violation(self):
        """Gap-E contract: real dbt-Cloud responses always carry ≥1
        result per failed step. The adapter ENFORCES this — silent
        zero-envelope emission on `results: []` would hide either MCP
        behaviour change or upstream parser corruption.

        Mutation C: revert the raise to `return []` (or `continue`) on
        empty results. This test goes RED because it expected a raise
        and got a silent return.
        """
        with pytest.raises(
            EmptyResultsContractViolation,
            match="empty results list",
        ):
            from_dbt_cloud_error(
                _empty_results_parsed_error(), _run_metadata()
            )

    def test_empty_results_error_message_names_step(self):
        """The contract-violation message must name the step (so the
        operator can locate the divergent step in the MCP response
        without grepping)."""
        with pytest.raises(
            EmptyResultsContractViolation,
            match=r"step_name='Invoke dbt with `dbt build`'",
        ):
            from_dbt_cloud_error(
                _empty_results_parsed_error(), _run_metadata()
            )


# ===========================================================================
# Discriminator-agnosticism — model-execution vs pre-model both survive
# ===========================================================================

class TestDiscriminatorAgnostic:
    """Byte-review focus item 5: the adapter does NOT branch on
    pre-model-vs-model-execution beyond the Gap-F normalization guard.
    Both `message` (P1 signal on model-execution) and
    `truncated_debug_logs` (post-rename, prospective P* signal on
    pre-model) survive into their respective envelopes. Silent
    dropping of either field would create a silent-coverage-loss
    bug invisible at unit-test time."""

    def test_model_execution_envelope_preserves_message(self):
        envelopes = from_dbt_cloud_error(
            _model_execution_parsed_error(), _run_metadata()
        )
        result = envelopes[0]["data"]["failed_steps"][0]["results"][0]
        assert "message" in result
        assert "invalid identifier 'MATERIAL_NUMBER'" in result["message"]

    def test_model_execution_envelope_preserves_compiled_code(self):
        """compiled_code lands in the envelope intact; the redactor
        downstream is what literal-strips it (PREVIEW_FIELDS). The
        adapter must NOT pre-empt that — passing through unchanged is
        the discriminator-agnostic contract."""
        envelopes = from_dbt_cloud_error(
            _model_execution_parsed_error(), _run_metadata()
        )
        result = envelopes[0]["data"]["failed_steps"][0]["results"][0]
        assert "compiled_code" in result
        assert "---- SRC LAYER ----" in result["compiled_code"]

    def test_model_execution_envelope_preserves_unique_id(self):
        envelopes = from_dbt_cloud_error(
            _model_execution_parsed_error(), _run_metadata()
        )
        result = envelopes[0]["data"]["failed_steps"][0]["results"][0]
        assert result["unique_id"] == "model.dbt_datavault.fact_mrp_lines"

    def test_model_execution_envelope_preserves_relation_name(self):
        envelopes = from_dbt_cloud_error(
            _model_execution_parsed_error(), _run_metadata()
        )
        result = envelopes[0]["data"]["failed_steps"][0]["results"][0]
        assert result["relation_name"] == (
            "datavault_dev.bus_vault.fact_mrp_lines"
        )

    def test_pre_model_envelope_preserves_unique_id_none(self):
        """Pre-model discriminator: `unique_id` is None. The adapter
        passes that through unchanged (not stripped, not defaulted)."""
        envelopes = from_dbt_cloud_error(
            _pre_model_parsed_error(), _run_metadata()
        )
        result = envelopes[0]["data"]["failed_steps"][0]["results"][0]
        assert "unique_id" in result
        assert result["unique_id"] is None

    def test_pre_model_envelope_preserves_compiled_code_none(self):
        envelopes = from_dbt_cloud_error(
            _pre_model_parsed_error(), _run_metadata()
        )
        result = envelopes[0]["data"]["failed_steps"][0]["results"][0]
        assert "compiled_code" in result
        assert result["compiled_code"] is None

    def test_pre_model_envelope_preserves_relation_name_sentinel(self):
        envelopes = from_dbt_cloud_error(
            _pre_model_parsed_error(), _run_metadata()
        )
        result = envelopes[0]["data"]["failed_steps"][0]["results"][0]
        assert result["relation_name"] == "No database relation"

    def test_pre_model_envelope_preserves_message_sentinel(self):
        """The fixed 47-char sentinel must survive — even though it's
        not actionable content, downstream consumers (signature
        computation in C5, the H7 priority-fallback) need to see the
        sentinel to apply the skip rule."""
        envelopes = from_dbt_cloud_error(
            _pre_model_parsed_error(), _run_metadata()
        )
        result = envelopes[0]["data"]["failed_steps"][0]["results"][0]
        assert result["message"] == (
            "run_results.json not available - returning logs"
        )

    def test_adapter_does_not_branch_on_unique_id_is_none(self):
        """Both shapes go through `_normalize_result` with NO
        discriminator-keyed branching beyond the Gap-F guard. We
        verify by constructing a pre-model and model-execution result
        with otherwise-identical fields and asserting they pass
        through the same way (modulo Gap-F).
        """
        # Two minimal results — only `unique_id` and `truncated_logs`
        # vary. Everything else identical.
        pre_model = {
            "unique_id": None,
            "status": "error",
            "message": "msg",
            "truncated_logs": None,  # nothing to rename
        }
        model_exec = {
            "unique_id": "model.x.y",
            "status": "error",
            "message": "msg",
            "truncated_logs": None,
        }
        envelopes_pre = from_dbt_cloud_error(
            {
                "failed_steps": [
                    {
                        "step_name": "s",
                        "target": "t",
                        "finished_at": "2026-06-12T14:22:18.000Z",
                        "results": [pre_model],
                    }
                ],
            },
            _run_metadata(),
        )
        envelopes_exec = from_dbt_cloud_error(
            {
                "failed_steps": [
                    {
                        "step_name": "s",
                        "target": "t",
                        "finished_at": "2026-06-12T14:22:18.000Z",
                        "results": [model_exec],
                    }
                ],
            },
            _run_metadata(),
        )
        r_pre = envelopes_pre[0]["data"]["failed_steps"][0]["results"][0]
        r_exec = envelopes_exec[0]["data"]["failed_steps"][0]["results"][0]
        # Both must carry: status, message. Differ only on unique_id.
        assert r_pre["status"] == r_exec["status"]
        assert r_pre["message"] == r_exec["message"]
        # Discriminator field passes through with its respective value:
        assert r_pre["unique_id"] is None
        assert r_exec["unique_id"] == "model.x.y"
        # Same set of keys (no branch-based key-set divergence):
        assert set(r_pre.keys()) == set(r_exec.keys())


# ===========================================================================
# End-to-end through triage_failure — Mutation A target + honest-coverage
# proof on real bytes
# ===========================================================================

class TestEndToEnd:
    """The honest-coverage proof. Both real golden shapes flow through
    the adapter → triage_failure and produce UNKNOWN classifications
    with `evidence_mode=ARTIFACT_PROJECTION` — the agent correctly
    surfaces "I can't classify this, here's the evidence" rather than
    a false positive against either P1 or P2.

    Per directive byte-review item 7: the 491 HASHDIFF failure
    matches NO catalog pattern (per §2 coverage reality), so the
    end-to-end classification IS the honesty-of-coverage assertion.
    Mutation A (drop the `data` wrapper) flips _detect_mode to
    UNDETECTED and these tests' `evidence_mode=ARTIFACT_PROJECTION`
    assertion goes RED — Mutation A's coverage path runs through here.
    """

    def test_model_execution_end_to_end_classifies_as_unknown_artifact(self):
        envelopes = from_dbt_cloud_error(
            _model_execution_parsed_error(), _run_metadata()
        )
        rec, _, _ = triage_failure(envelopes[0])
        assert rec.classification == Classification.UNKNOWN, (
            "491 HASHDIFF / invalid-identifier matches no current "
            "catalog pattern — must classify as UNKNOWN (honest "
            "coverage), not a false positive against P1 or P2."
        )
        assert rec.evidence_mode == EvidenceMode.ARTIFACT_PROJECTION, (
            "Mutation A target — drop the `data` wrapper and this "
            "becomes UNDETECTED, breaking the end-to-end contract."
        )
        assert rec.outcome == Outcome.UNKNOWN_HANDED_TO_HUMAN

    def test_pre_model_end_to_end_classifies_as_unknown_artifact(self):
        """Pre-model envelope: `truncated_debug_logs` (post Gap-F
        rename) contains manifest-parse content. P2 reads
        `truncated_debug_logs` but its content-signal is for
        PR-isolated-schema-missing (different failure mode entirely);
        P3 reads `logs` (different field). Result: UNKNOWN with
        `evidence_mode=ARTIFACT_PROJECTION`. This is the
        surface-finding from byte-review item 5 (whether the real
        485821754 content matches P2 — answer: NO).
        """
        envelopes = from_dbt_cloud_error(
            _pre_model_parsed_error(), _run_metadata()
        )
        rec, _, _ = triage_failure(envelopes[0])
        assert rec.classification == Classification.UNKNOWN
        assert rec.evidence_mode == EvidenceMode.ARTIFACT_PROJECTION
        assert rec.outcome == Outcome.UNKNOWN_HANDED_TO_HUMAN

    def test_multi_result_end_to_end_each_envelope_classifies_independently(
        self,
    ):
        """Each envelope from a multi-result fan-out is independently
        consumable by triage_failure — proves the per-result emission
        is not just a structural slice but a triageable unit."""
        envelopes = from_dbt_cloud_error(
            _multi_result_parsed_error(), _run_metadata()
        )
        assert len(envelopes) == 2
        # C5 3-tuple unpack — index [0] for the RCARecord; redaction +
        # projection are not asserted here (covered by writer tests).
        records = [triage_failure(env)[0] for env in envelopes]
        # Both classify as UNKNOWN (the synthetic dim_customer and
        # dim_product invalid-identifier errors match no pattern):
        assert all(
            r.classification == Classification.UNKNOWN for r in records
        )
        # Both carry the correct evidence_mode:
        assert all(
            r.evidence_mode == EvidenceMode.ARTIFACT_PROJECTION
            for r in records
        )
