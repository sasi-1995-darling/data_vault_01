"""dbt Cloud `get_job_run_error` adapter — Component 4 (C1.5 spec v3.4 §4.5).

Single public entrypoint:

    from_dbt_cloud_error(parsed_error: dict, run_metadata: dict) -> List[dict]

Turns ONE dbt-Cloud `get_job_run_error` MCP response into N single-result
ARTIFACT_PROJECTION envelopes — one per ``failed_steps[*].results[*]``
entry — each shaped so ``triage_failure(envelope)`` reaches
``_detect_mode → ARTIFACT_PROJECTION → _project_artifact_payload``
without any further normalization in the orchestrator.

Pure function. No I/O, no MCP calls, no logging side effects, no global
state read or written. The poll loop (Component 6) is what calls MCP
and hands the parsed response here; this module is the deterministic
transform from "what MCP returned" to "what the orchestrator consumes."

Boundary contract (asserted in test_triage_dbt_cloud_adapter.py):

  * ``parsed_error`` MUST be a dict — TypeError on anything else
    (no silent coercion).
  * ``run_metadata`` is REQUIRED, no default — carries
    ``run_id``/``job_id``/``environment_id``/``git_sha`` to the C5
    writer as a SIDECAR. It does NOT enter the envelope (per spec G5);
    the envelope is the redacted-result-slice only. The required-arg
    discipline (carry-1 from C3 sign-off) makes "writer receives a
    record without provenance" structurally impossible — forgetting
    the kwarg is a ``TypeError`` at call time, not a silent default
    that propagates a wrong tag.
  * The MCP response carries ``failed_steps`` at the TOP level (no
    ``data`` wrapper). The adapter ADDS the ``data`` wrapper so the
    envelope matches the orchestrator's ``data["failed_steps"][0]["results"][0]``
    walk (locked in C2 by ``_project_artifact_payload`` and pinned by
    Mutation A — drop the wrapper → ``_detect_mode`` returns UNDETECTED
    and end-to-end classification breaks).
  * Fan-out is per-RESULT, NOT per-step. A step with N results
    produces N envelopes, each carrying a single-element ``results``
    list (the ``[0]`` position the projector + Mutation A pin both
    depend on).
  * Per the Gap-E scan (real dbt-Cloud contract): ``results`` is
    ALWAYS ≥1 — never empty. The adapter ENFORCES this contract:
    if any step's ``results`` is empty, RAISE
    ``EmptyResultsContractViolation`` rather than silently emit zero
    envelopes for that step. Loud surfacing > silent drop (carry-5
    from C3 sign-off; Mutation C target).
  * Gap-F normalization (LOCKED): each ``result`` whose
    ``truncated_logs`` field is populated (``is not None``) has that
    content REMAPPED to ``truncated_debug_logs`` (the catalog vocab,
    in ``redact.REGEX_ELIGIBLE_FIELDS``); the MCP-side
    ``truncated_logs`` name is DROPPED, NOT also emitted under
    ``logs`` (untruthful Path-γ provenance would attribute
    artifact-projection content to the early-failure walk). This
    rename is UPSTREAM of C2's projector — by the time
    ``_project_artifact_payload`` runs, the field is already correctly
    named. C2 has a backstop test asserting the projector does NOT
    rename, so the rename lives in exactly ONE place (here).
  * The adapter is DISCRIMINATOR-AGNOSTIC except for the
    ``truncated_logs is not None`` normalization guard. It does NOT
    branch on the pre-model-vs-model-execution distinction
    (``unique_id is None``). Both shapes pass through with whatever
    fields each carries — ``compiled_code``, ``message``,
    ``relation_name`` all survive into the envelope unchanged
    (subject only to the Gap-F rename). This is load-bearing for
    coverage: ``message`` is the P1 signal on model-execution shape;
    ``truncated_debug_logs`` (post-rename) is the prospective signal
    field for any future ``P*`` that targets pre-model content. Either
    silently dropped → silent coverage loss.

Step-level fields carried over (per spec §4.5):
  * ``step_name``, ``target``, ``finished_at`` are preserved on the
    step. The ``step_name``→``name`` passthrough (audit nicety so the
    redactor's PASSTHROUGH_FIELDS preserves the label) is DEFERRED
    per directive — fast-follow, not MVP. The redactor will drop
    ``step_name`` and ``target`` today (they are not in the allowlist);
    that is a downstream concern, not an adapter concern. The adapter's
    job is to preserve the spec-required fields; what the redactor
    keeps is governed by ``redact.PASSTHROUGH_FIELDS``.

Failure-mode coverage on real dbt-Cloud shapes (Gate-A/E scan,
directive-supplied):

  * Model-execution shape (e.g., run 491165226): ``unique_id``
    populated, ``compiled_code`` populated, ``truncated_logs`` null.
    Adapter passes through; envelope carries ``compiled_code`` and
    ``message``. Gap-F guard skips the rename (``truncated_logs is
    None``). End-to-end through ``triage_failure`` classifies as
    UNKNOWN with ``evidence_mode=ARTIFACT_PROJECTION`` (the 491
    HASHDIFF failure matches no current catalog pattern — the agent
    correctly surfaces "I can't classify this, here's the evidence,"
    not a false positive). Honest-coverage proof on real bytes.

  * Pre-model shape (runs 485821754, 485850628, 485851058):
    ``unique_id`` null, ``compiled_code`` null, ``relation_name`` is
    the fixed sentinel ``"No database relation"``, ``message`` is the
    fixed 47-char sentinel ``"run_results.json not available -
    returning logs"``, ``truncated_logs`` populated with 1.4M-2.9M
    chars of real error output. Adapter applies Gap-F rename →
    envelope carries ``truncated_debug_logs`` with the manifest-parse
    error content. End-to-end: P2 reads ``truncated_debug_logs`` but
    its content-signal is for the PR-isolated-schema-missing-upstream
    failure mode (different runs entirely — 487333396, 487313189); it
    does NOT match manifest-parse content. P3 (manifest_parse) reads
    ``logs`` — a different field name (the early-failure walk's field,
    NOT the artifact-projection envelope's). Result: pre-model
    envelopes classify as UNKNOWN with
    ``evidence_mode=ARTIFACT_PROJECTION``. The Mutation B "stronger
    assertion" question (P2-fires-on-pre-model end-to-end) resolves
    NO — the rename-presence assertion stands alone for Gap-F coverage.

Out of scope (later components):
  * Writer (C5): the 3-tuple return contract, the COALESCE MERGE, the
    ``_compute_signature`` priority-fallback, Flag-1 ``mode.value``
    enforcement.
  * Poll loop (C6): MCP I/O, retry policy, idempotency guards.
"""

from __future__ import annotations

from typing import List


# ---------------------------------------------------------------------------
# Contract violation — empty `results` on a failed step
# ---------------------------------------------------------------------------

class EmptyResultsContractViolation(ValueError):
    """Raised when ``failed_steps[*].results`` is an empty list.

    The Gap-E scan established that real dbt-Cloud
    ``get_job_run_error`` responses always carry ≥1 result per failed
    step — the contract is "results is never empty when the step
    failed." Treating an empty-results step as a silent zero-envelope
    emission would hide a contract violation (either MCP behaviour
    changed, or the upstream parser produced a malformed dict). This
    exception surfaces it loudly so the operator sees the divergence
    immediately, rather than the writer recording fewer rows than the
    failure count says it should.

    Per Mutation C: silently emitting ``[]`` on empty results must
    cause the contract-violation test to go RED.
    """


# ---------------------------------------------------------------------------
# Public entrypoint
# ---------------------------------------------------------------------------

def from_dbt_cloud_error(
    parsed_error: dict,
    run_metadata: dict,
) -> List[dict]:
    """Convert a parsed ``get_job_run_error`` MCP response into N
    ARTIFACT_PROJECTION envelopes — one per failed-step result.

    Parameters
    ----------
    parsed_error :
        The dict returned by the MCP ``get_job_run_error`` tool. The
        response carries ``failed_steps`` at the TOP level (no ``data``
        wrapper).
    run_metadata :
        Per-run provenance — ``run_id``, ``job_id``, ``environment_id``,
        ``git_sha``. SIDECAR per spec G5: does NOT enter the envelope,
        flows separately to the C5 writer as kwargs. Required-kwarg
        discipline (carry-1) makes "forgot to pass run_metadata" a
        ``TypeError`` at call time rather than a silent default.

    Returns
    -------
    List[dict]
        N envelopes, each shaped
        ``{"data": {"failed_steps": [{"step_name": str, "target": str,
        "finished_at": str, "results": [<single result dict>]}]}}``.
        Each envelope is independently consumable by ``triage_failure``.

    Raises
    ------
    TypeError
        If ``parsed_error`` or ``run_metadata`` is not a dict.
    EmptyResultsContractViolation
        If any failed step carries ``results: []`` (empty list).

    Notes
    -----
    The Gap-F rename (``truncated_logs`` → ``truncated_debug_logs``) is
    applied per-result, guarded by ``is not None``. The MCP-side
    ``truncated_logs`` name is dropped from the result dict; the
    content lands ONLY under ``truncated_debug_logs``. Path-γ
    duplication (also emitting under ``logs``) would attribute
    artifact-projection content to the early-failure walk and is
    rejected per spec §4.3.
    """
    if not isinstance(parsed_error, dict):
        raise TypeError(
            f"parsed_error must be dict, got {type(parsed_error).__name__}"
        )
    if not isinstance(run_metadata, dict):
        raise TypeError(
            f"run_metadata must be dict, got {type(run_metadata).__name__}"
        )

    failed_steps = parsed_error.get("failed_steps")
    if not isinstance(failed_steps, list):
        return []

    envelopes: List[dict] = []
    for step in failed_steps:
        if not isinstance(step, dict):
            # Non-dict step entries are not part of the dbt-Cloud
            # contract; skip silently rather than synthesize a fake
            # step. (A future tightening could raise here; today the
            # parser upstream is expected to have filtered these.)
            continue

        results = step.get("results")
        if not isinstance(results, list):
            # Missing or non-list `results` is treated as "no results
            # to fan out from this step." Distinct from empty-list,
            # which IS the contract violation: a step that failed and
            # carries a `results` key but with zero entries is the
            # exact shape the Gap-E scan ruled impossible. A step
            # with no `results` key at all (or a non-list value) is a
            # parser-shape error one layer up, not a dbt-Cloud
            # contract violation worth raising here.
            continue

        if not results:
            raise EmptyResultsContractViolation(
                f"failed_step carries empty results list "
                f"(step_name={step.get('step_name')!r}); "
                f"violates Gap-E contract (results always ≥1 per "
                f"real dbt-Cloud get_job_run_error responses)"
            )

        for result in results:
            if not isinstance(result, dict):
                # Same posture as non-dict steps: skip non-dict
                # results. Empty-list contract violation is the
                # explicit-raise case; everything else is structural
                # noise that the parser should have caught.
                continue
            envelope = _build_envelope(step, result)
            envelopes.append(envelope)

    return envelopes


# ---------------------------------------------------------------------------
# Envelope construction
# ---------------------------------------------------------------------------

def _build_envelope(step: dict, result: dict) -> dict:
    """Build one single-result H8 envelope from a step + a single result.

    Adds the ``data`` wrapper (Mutation A target), preserves the
    spec-required step-level fields (``step_name``, ``target``,
    ``finished_at``), and applies the Gap-F rename
    (``truncated_logs`` → ``truncated_debug_logs``) to the result.

    Single-element ``failed_steps`` list and single-element ``results``
    list — the ``[0][0]`` position the C2 projector and its Mutation-A
    pin depend on.
    """
    return {
        "data": {
            "failed_steps": [
                {
                    "step_name": step.get("step_name"),
                    "target": step.get("target"),
                    "finished_at": step.get("finished_at"),
                    "results": [_normalize_result(result)],
                }
            ],
        }
    }


def _normalize_result(result: dict) -> dict:
    """Return a copy of ``result`` with Gap-F normalization applied.

    Gap-F: rename ``truncated_logs`` → ``truncated_debug_logs`` (catalog
    vocab; in ``redact.REGEX_ELIGIBLE_FIELDS``) when present. Drop the
    MCP-side ``truncated_logs`` name. Do NOT also emit under ``logs``
    (untruthful Path-γ provenance — that field is the EARLY_FAILURE
    walk's field, not the artifact projection's).

    Discriminator-agnostic except this guard: all other fields
    (``unique_id``, ``relation_name``, ``message``, ``compiled_code``,
    ``status``, etc.) pass through unchanged. The pre-model vs
    model-execution distinction does NOT cause the adapter to drop or
    branch on any field — both shapes survive into the envelope
    intact, with only the rename applied if the source field is
    populated.

    The ``is not None`` guard (not truthiness) is deliberate: an
    explicit empty string under ``truncated_logs`` should still be
    renamed (the rename is a vocab-translation, not a content filter);
    the empty-string-becomes-empty case is then handled downstream by
    the projector's ``isinstance(value, str) and value`` truthy check.
    Only ``None`` (the MODEL-EXECUTION shape signal) skips the rename.
    """
    normalized: dict = {}
    for key, value in result.items():
        if key == "truncated_logs":
            if value is not None:
                normalized["truncated_debug_logs"] = value
            # If value is None, DROP the field entirely — do not emit
            # `truncated_debug_logs: None`, which would shadow any
            # other-source `truncated_debug_logs` if one were present
            # (defense-in-depth; current contract only carries one or
            # the other, never both, but the projector's truthy filter
            # would reject None anyway).
            continue
        normalized[key] = value
    return normalized
