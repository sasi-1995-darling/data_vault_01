"""Unit tests for ``scripts.automation.src.triage.rca_schema``.

The schema enforces three hard invariants that must never silently regress:

1. ``schema_version`` is pinned to ``v1.0.0``.
2. ``classification=test_failure`` MUST NOT pair with
   ``suggested_action=modify_test`` — root cause investigation is required
   for test failures, never test-modification.
3. ``classification=unknown`` forces ``confidence=None`` and
   ``requires_human_review=True``.
"""

from __future__ import annotations

import pytest
from pydantic import ValidationError

from scripts.automation.src.triage.rca_schema import (
    SCHEMA_VERSION,
    Classification,
    EvidenceMode,
    Outcome,
    RCARecord,
    SuggestedAction,
)


# ---------------------------------------------------------------------------
# Happy paths
# ---------------------------------------------------------------------------

class TestRCARecordHappyPath:

    def test_classified_test_failure_with_safe_action(self):
        """A test failure may suggest investigating source data."""
        rec = RCARecord(
            classification=Classification.TEST_FAILURE,
            confidence=0.85,
            suggested_action=SuggestedAction.INVESTIGATE_SOURCE_DATA,
            requires_human_review=False,
            evidence_mode=EvidenceMode.ARTIFACT,
            outcome=Outcome.CLASSIFIED,
        )
        assert rec.schema_version == SCHEMA_VERSION
        assert rec.classification == Classification.TEST_FAILURE

    def test_unknown_classification_minimal(self):
        """``unknown`` works with no confidence and human-review flag."""
        rec = RCARecord(
            classification=Classification.UNKNOWN,
            requires_human_review=True,
            evidence_mode=EvidenceMode.EARLY_FAILURE,
            outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
        )
        assert rec.confidence is None
        assert rec.suggested_action is None

    def test_compile_error_can_propose_fix(self):
        rec = RCARecord(
            classification=Classification.COMPILE_ERROR,
            confidence=0.95,
            suggested_action=SuggestedAction.FIX_COMPILE_ERROR,
            requires_human_review=False,
            evidence_mode=EvidenceMode.ARTIFACT,
            outcome=Outcome.CLASSIFIED,
        )
        assert rec.suggested_action == SuggestedAction.FIX_COMPILE_ERROR

    def test_record_is_frozen(self):
        """RCARecord is immutable — protects audit trail."""
        rec = RCARecord(
            classification=Classification.UNKNOWN,
            requires_human_review=True,
            evidence_mode=EvidenceMode.EARLY_FAILURE,
            outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
        )
        with pytest.raises(ValidationError):
            rec.classification = Classification.TIMEOUT  # type: ignore[misc]


# ---------------------------------------------------------------------------
# Rule 2: modify_test forbidden on test failures
# ---------------------------------------------------------------------------

class TestModifyTestForbiddenOnTestFailures:

    def test_test_failure_plus_modify_test_rejected(self):
        with pytest.raises(ValidationError) as exc:
            RCARecord(
                classification=Classification.TEST_FAILURE,
                confidence=0.99,
                suggested_action=SuggestedAction.MODIFY_TEST,
                requires_human_review=True,
                evidence_mode=EvidenceMode.ARTIFACT,
                outcome=Outcome.CLASSIFIED,
            )
        assert "modify_test" in str(exc.value)
        assert "test_failure" in str(exc.value)

    def test_modify_test_allowed_for_non_test_classifications(self):
        """modify_test is only forbidden when classification IS test_failure."""
        # e.g. a compile error in a test file might legitimately need the
        # test rewritten — that's a different scenario.
        rec = RCARecord(
            classification=Classification.COMPILE_ERROR,
            confidence=0.7,
            suggested_action=SuggestedAction.MODIFY_TEST,
            requires_human_review=True,
            evidence_mode=EvidenceMode.ARTIFACT,
            outcome=Outcome.CLASSIFIED,
        )
        assert rec.suggested_action == SuggestedAction.MODIFY_TEST


# ---------------------------------------------------------------------------
# Rule 3: unknown classification invariants
# ---------------------------------------------------------------------------

class TestUnknownInvariants:

    def test_unknown_with_confidence_rejected(self):
        with pytest.raises(ValidationError) as exc:
            RCARecord(
                classification=Classification.UNKNOWN,
                confidence=0.5,
                requires_human_review=True,
                evidence_mode=EvidenceMode.EARLY_FAILURE,
                outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
            )
        assert "confidence" in str(exc.value)

    def test_unknown_without_human_review_rejected(self):
        with pytest.raises(ValidationError) as exc:
            RCARecord(
                classification=Classification.UNKNOWN,
                requires_human_review=False,
                evidence_mode=EvidenceMode.EARLY_FAILURE,
                outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
            )
        assert "human_review" in str(exc.value)


# ---------------------------------------------------------------------------
# Rule 1 + structural guards
# ---------------------------------------------------------------------------

class TestStructuralGuards:

    def test_schema_version_pinned(self):
        """Future version on write is rejected (strict-on-write policy)."""
        with pytest.raises(ValidationError) as exc:
            RCARecord(
                schema_version="v2.0.0",
                classification=Classification.UNKNOWN,
                requires_human_review=True,
                evidence_mode=EvidenceMode.EARLY_FAILURE,
                outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
            )
        assert "schema_version" in str(exc.value)

    def test_prior_schema_version_rejected_on_write(self):
        """Backward versions on write are also rejected — migration shim
        owns read-side compatibility, never the construction validator."""
        with pytest.raises(ValidationError) as exc:
            RCARecord(
                schema_version="v0.9.0",
                classification=Classification.UNKNOWN,
                requires_human_review=True,
                evidence_mode=EvidenceMode.EARLY_FAILURE,
                outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
            )
        assert "schema_version" in str(exc.value)

    def test_explicit_correct_schema_version_accepted(self):
        """Passing the current SCHEMA_VERSION explicitly is accepted —
        guards against the validator accidentally rejecting matches."""
        rec = RCARecord(
            schema_version=SCHEMA_VERSION,
            classification=Classification.UNKNOWN,
            requires_human_review=True,
            evidence_mode=EvidenceMode.EARLY_FAILURE,
            outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
        )
        assert rec.schema_version == SCHEMA_VERSION

    def test_confidence_out_of_range_rejected(self):
        with pytest.raises(ValidationError):
            RCARecord(
                classification=Classification.TEST_FAILURE,
                confidence=1.5,
                suggested_action=SuggestedAction.INVESTIGATE_SOURCE_DATA,
                requires_human_review=False,
                evidence_mode=EvidenceMode.ARTIFACT,
                outcome=Outcome.CLASSIFIED,
            )

    def test_extra_fields_forbidden(self):
        """Schema is closed — unknown fields are a contract violation."""
        with pytest.raises(ValidationError):
            RCARecord(
                classification=Classification.UNKNOWN,
                requires_human_review=True,
                evidence_mode=EvidenceMode.EARLY_FAILURE,
                outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
                rogue_field="should not be accepted",  # type: ignore[call-arg]
            )

    def test_invalid_classification_rejected(self):
        with pytest.raises(ValidationError):
            RCARecord(
                classification="totally_made_up",  # type: ignore[arg-type]
                requires_human_review=True,
                evidence_mode=EvidenceMode.EARLY_FAILURE,
                outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
            )


# ---------------------------------------------------------------------------
# EvidenceMode enum contract (C1.5 spec §4.1)
# ---------------------------------------------------------------------------
#
# The enum's value-strings are the bare-string contract the DDL column
# `evidence_mode VARCHAR(32)` depends on. The class is `(str, Enum)` —
# NOT `StrEnum` — and the migration is deliberately deferred. The tests
# below operationalize that deferral as machine-checked behaviour rather
# than human memory: a future PR that "modernizes" the base class to
# StrEnum, or that adds a duplicate value, or that touches `.value` for
# any of the four members, will fail one of these tests and be forced
# back into an explicit decision rather than sneaking through.

class TestEvidenceMode:
    """Lock the enum's bare-string serialization contract and membership."""

    def test_membership_is_exactly_four_values(self):
        """If a fifth member is added, this test deliberately forces the
        author to update both this assertion AND the DDL column comment
        (cross-cutting change that needs a paired-edit signal)."""
        names = {m.name for m in EvidenceMode}
        assert names == {
            "ARTIFACT", "EARLY_FAILURE",
            "ARTIFACT_PROJECTION", "UNDETECTED",
        }

    def test_unique_decorator_blocks_alias_values(self):
        """`@unique` is part of the contract — duplicate values would
        silently produce an alias and break round-trip from DDL string
        back to a single canonical EvidenceMode member.

        Verification strategy: @unique leaves no class-level marker
        attribute (it just raises at class-construction time on
        duplicates). The observable consequence on a live `@unique`-
        decorated class is that `__members__` has no aliases, i.e.,
        every name maps to a distinct member with a distinct value.
        Removing the decorator AND introducing a duplicate value
        would make `__members__` shorter than `len(EvidenceMode)`.
        """
        values = [m.value for m in EvidenceMode]
        # All values are pairwise unique
        assert len(values) == len(set(values))
        # __members__ has no aliases (alias names map back to the
        # canonical member but inflate __members__ size only when the
        # decorator is missing AND duplicates exist).
        assert len(EvidenceMode.__members__) == len(values)
        # The DDL bare strings are exactly the four expected values.
        assert set(values) == {
            "artifact", "early_failure",
            "artifact_projection", "undetected",
        }

    def test_evidence_mode_serializes_to_bare_value(self):
        """The DDL evidence_mode column requires the bare string
        ('artifact_projection'), NOT 'EvidenceMode.ARTIFACT_PROJECTION'.

        Lock the .value contract the writer MUST use. See spec §4.1:
        writer MUST serialize via .value, never via str()/f-string,
        because (str, Enum) str() behavior is version-dependent and
        unreliable (on Python 3.11+ both `str(m)` and `f"{m}"` return
        'EvidenceMode.<NAME>', NOT the bare value).

        This test locks the version-stable invariant — `.value` always
        returns the bare DDL string regardless of Python version or
        whether the base class is `(str, Enum)` or `StrEnum`. A
        StrEnum migration is its own isolated PR with a separate
        serialization-assertion test (per spec §4.1 deferral).
        """
        assert EvidenceMode.ARTIFACT.value == "artifact"
        assert EvidenceMode.EARLY_FAILURE.value == "early_failure"
        assert EvidenceMode.ARTIFACT_PROJECTION.value == "artifact_projection"
        assert EvidenceMode.UNDETECTED.value == "undetected"
        # The writer/serializer contract: ALWAYS use mode.value for DDL writes.
        # Do NOT rely on str(mode) or f"{mode}" — that behaviour is (str,Enum)-
        # version-dependent and is the migration trap §4.1 defers.

    def test_str_enum_mixin_preserves_str_equality_with_value(self):
        """The (str, Enum) mixin preserves the invariant `m == m.value`
        because EvidenceMode IS-A str subclass. This is the property
        that lets the existing redactor / catalog code treat enum
        members as strings in equality contexts. A StrEnum migration
        would preserve this; a plain `Enum` subclass would NOT —
        which is why the migration is non-trivial."""
        assert EvidenceMode.ARTIFACT == "artifact"
        assert EvidenceMode.ARTIFACT_PROJECTION == "artifact_projection"
        assert EvidenceMode.UNDETECTED == "undetected"

    def test_value_lookup_round_trip(self):
        """DDL → enum round-trip MUST work via the value-lookup form
        (this is how a future reader of the TRIAGE_INVOCATIONS table
        reconstitutes the enum from the stored bare string)."""
        for member in EvidenceMode:
            assert EvidenceMode(member.value) is member
