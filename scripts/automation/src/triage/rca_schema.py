"""RCA payload schema for the DV Failure Triage Agent.

Single source of truth for the structured Root-Cause Analysis (RCA) record
that the agent emits per dbt failure. Both the LLM prompt contract and the
``OPS_PROD.LOGS.TRIAGE_INVOCATIONS`` row layout derive from this schema.

Note on versioning:
  - ``SCHEMA_VERSION = "v1.0.0"`` refers to the *rca_record contract*
    version, pinned via ``model_validator`` and persisted to
    ``TRIAGE_INVOCATIONS.schema_version``.
  - The Pydantic library version (currently 2.12) is unrelated. Bumping
    the library does not bump the schema; schema bumps follow semver on
    additive vs. breaking changes to the record contract itself.
  - Policy: **strict on write, permissive on read with explicit migration**.
    Construction rejects any non-matching ``schema_version`` (see
    ``_enforce_invariants``). Read-side accuracy queries must filter
    ``WHERE schema_version = 'v1.0.0'`` explicitly. When v1.1.0 / v2.0.0
    ships, a migration shim reads prior versions — never silent coercion.

Hard rules enforced here (per ``docs/triage-agent/v2-plan.md`` §1.3 and §3):

1. ``schema_version`` is pinned to ``v1.0.0``. Bump deliberately when the
   evidence_json contract changes — downstream consumers gate on this.
2. ``classification == TEST_FAILURE`` MUST NOT pair with
   ``suggested_action == MODIFY_TEST``. Test-modifying actions require human
   approval regardless of the LLM's confidence; the schema refuses the
   combination so a bug upstream can never silently propose it.
3. ``classification == UNKNOWN`` forces ``confidence is None`` and
   ``requires_human_review is True``. First-encounter failures are handed to
   humans, not classified confidently.

Each of these three invariants is mutation-tested in
``tests/test_triage_rca_schema.py`` — silent regression of any one of them
is a high-blast-radius failure mode for the agent.
"""

from __future__ import annotations

from enum import Enum, unique
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, model_validator


SCHEMA_VERSION = "v1.0.0"


class Classification(str, Enum):
    """LLM-emitted failure category. ``UNKNOWN`` is the safe default."""

    COMPILE_ERROR = "compile_error"
    CONNECTION_ERROR = "connection_error"
    DEPENDENCY_ERROR = "dependency_error"
    DATA_QUALITY_FAILURE = "data_quality_failure"
    TEST_FAILURE = "test_failure"
    PERMISSION_ERROR = "permission_error"
    TIMEOUT = "timeout"
    UNKNOWN = "unknown"


class SuggestedAction(str, Enum):
    """Proposed remediation. ``MODIFY_TEST`` is forbidden on test failures."""

    INVESTIGATE_SOURCE_DATA = "investigate_source_data"
    FIX_COMPILE_ERROR = "fix_compile_error"
    RETRY = "retry"
    UPDATE_DEPENDENCY = "update_dependency"
    MODIFY_TEST = "modify_test"
    ESCALATE_TO_HUMAN = "escalate_to_human"
    NO_ACTION = "no_action"


@unique
class EvidenceMode(str, Enum):
    """Where the evidence came from.

    Members:
      ``ARTIFACT``             — full ``run_results.json`` artifact in scope
                                 (Phase-2+; not produced by the Phase-1 agent today).
      ``EARLY_FAILURE``        — no artifact; pre-model failure, evidence
                                 projected from ``data.run_steps[-1]``.
      ``ARTIFACT_PROJECTION``  — artifact-derived shape projected from
                                 ``data.failed_steps[*].results[*]`` into the
                                 same flat REGEX_ELIGIBLE projection the
                                 EARLY_FAILURE matcher consumes (C1.5 spec).
      ``UNDETECTED``           — neither shape carries a usable signal; the
                                 orchestrator hands the run to a human with
                                 a "no detectable evidence shape" rationale.

    Serialization contract: the DDL ``evidence_mode VARCHAR(32)`` column
    requires the bare value (e.g., ``'artifact_projection'``).  Writers MUST
    serialize via ``mode.value`` — NOT ``str(mode)`` or ``f"{mode}"``.  The
    ``(str, Enum)`` mixin's ``str()``/f-string output is version-dependent
    (e.g., on Python 3.11+ it returns ``'EvidenceMode.X'``, NOT the bare
    value), and a ``StrEnum`` migration is deliberately deferred to its
    own isolated PR with a serialization-assertion test.  The lock test
    ``test_evidence_mode_serializes_to_bare_value`` enforces this in the
    suite so the deferral lives in machine-checked behaviour, not in
    human memory.
    """

    ARTIFACT = "artifact"
    EARLY_FAILURE = "early_failure"
    ARTIFACT_PROJECTION = "artifact_projection"
    UNDETECTED = "undetected"


class Outcome(str, Enum):
    """Terminal outcome recorded in ``TRIAGE_INVOCATIONS.outcome``.

    Membership note: ``TRIAGE_ATTEMPTED_BUT_FAILED`` is the C6 poll-loop
    outcome for per-run retrieval failure (``get_job_run_error`` raised
    K times in a single polling pass). The orchestrator writes a row
    with this outcome carrying the real ``run_id`` and advances the
    cursor (ORCH-FAIL-OPEN: the run is "seen" so MAX(run_id) progresses
    and the system stays up; the row is the durable audit that we gave
    up). Distinct from C6's ``triage_source_unavailable`` sink which
    writes NO row (no run_id known — ``list_jobs_runs`` itself failed).
    """

    CLASSIFIED = "classified"
    UNKNOWN_HANDED_TO_HUMAN = "unknown_handed_to_human"
    CREDENTIAL_SENTINEL_FIRED = "credential_sentinel_fired"
    CIRCUIT_OPEN = "circuit_open"
    TRIAGE_ATTEMPTED_BUT_FAILED = "triage_attempted_but_failed"


class RCARecord(BaseModel):
    """Structured RCA record — one per triage invocation."""

    model_config = ConfigDict(extra="forbid", frozen=True)

    schema_version: str = Field(default=SCHEMA_VERSION)
    classification: Classification
    confidence: Optional[float] = Field(default=None, ge=0.0, le=1.0)
    suggested_action: Optional[SuggestedAction] = None
    requires_human_review: bool
    rationale: Optional[str] = Field(default=None, max_length=2000)
    evidence_mode: EvidenceMode
    outcome: Outcome

    @model_validator(mode="after")
    def _enforce_invariants(self) -> "RCARecord":
        # Rule 1: schema_version is pinned.
        if self.schema_version != SCHEMA_VERSION:
            raise ValueError(
                f"schema_version must be {SCHEMA_VERSION!r}, got {self.schema_version!r}"
            )

        # Rule 2: test failures MUST NOT propose test modifications.
        if (
            self.classification == Classification.TEST_FAILURE
            and self.suggested_action == SuggestedAction.MODIFY_TEST
        ):
            raise ValueError(
                "suggested_action='modify_test' is forbidden when "
                "classification='test_failure'; root cause must be investigated"
            )

        # Rule 3: UNKNOWN must defer to humans and emit no confidence.
        if self.classification == Classification.UNKNOWN:
            if self.confidence is not None:
                raise ValueError(
                    "confidence must be None when classification='unknown'"
                )
            if not self.requires_human_review:
                raise ValueError(
                    "requires_human_review must be True when classification='unknown'"
                )

        return self
