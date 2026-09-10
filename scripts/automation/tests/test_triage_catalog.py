"""Tests for ``scripts/automation/src/triage/fbin_error_catalog.py`` v1.2.0.

The catalog loader enforces nine structural invariants. Each invariant has
a dedicated mutation test that intentionally builds a malformed catalog
in memory (via ``tmp_path`` YAML) and asserts the loader rejects it with
a specific error message.

Invariant → mutation → test map (kept in lockstep with loader docstring):

| #     | Invariant                                       | Mutation that breaks it                       | Guard test |
|-------|-------------------------------------------------|-----------------------------------------------|-----------|
| Mut1  | pattern_id is unique                            | Duplicate a pattern_id                        | ``TestMutations.test_mut1_duplicate_pattern_id_rejected`` |
| Mut2  | classification ∈ rca_schema.Classification      | Use a typo'd classification value             | ``TestMutations.test_mut2_invalid_classification_rejected`` |
| Mut3a | Iron Rule: test_failure ⟹ investigation flag    | Set root_cause_investigation_required=False   | ``TestMutations.test_mut3a_iron_rule_investigation_flag_required`` |
| Mut3b | Iron Rule: test_failure ⟹ no MODIFY_TEST        | Set suggested_action=modify_test              | ``TestMutations.test_mut3b_iron_rule_modify_test_forbidden`` |
| Mut4  | signal_sources ⊂ REGEX_ELIGIBLE_FIELDS          | Declare compiled_code as a signal_source      | ``TestMutations.test_mut4_signal_source_escape_rejected`` |
| Mut5  | match_logic.type ∈ SUPPORTED_MATCH_LOGIC_TYPES  | Use an unsupported match type                 | ``TestMutations.test_mut5_unsupported_match_logic_type_rejected`` |
| Mut6  | provenance.source_type ∈ supported set          | Use 'pr_retrospective' (intentionally withheld) | ``TestMutations.test_mut6_unsupported_provenance_source_type_rejected`` |
| Mut7  | provenance.citation matches per-type regex      | Use 'lesson abc' for lessons_md type          | ``TestMutations.test_mut7_provenance_citation_regex_mismatch_rejected`` |
| Mut9d | `logs` signal ⟹ max_bytes ∈ [1, LOGS_MAX_BYTES] | Add `logs` pattern without max_bytes          | ``TestMutations.test_mut9d_*`` (3 sub-cases) |

Mut3b is also enforced by ``rca_schema.RCARecord._enforce_invariants`` Rule
2. Catching it at catalog-load is defense in depth, not redundancy by
accident; see the loader docstring.

Mut9d (Day 3.8, Sprint-1 #12) is load-time only — it catches structurally
broken matcher contracts (missing, 0, negative, over-cap). Empirical
adequacy of the chosen max_bytes value for a given pattern is a SEPARATE
test layer (pattern dry-run smoke tests against the Day-4 fixtures).
Lane discipline: Mut9d.lower_bound = 1, not 1024 — see commit body.
"""

from __future__ import annotations

import copy
from pathlib import Path

import pytest
import yaml

from scripts.automation.src.triage.fbin_error_catalog import (
    CATALOG_SCHEMA_VERSION,
    CatalogValidationError,
    DEFAULT_CATALOG_PATH,
    PROVENANCE_SOURCE_CITATION_REGEX,
    Pattern,
    PatternMatcher,
    Provenance,
    SUPPORTED_MATCH_LOGIC_TYPES,
    SUPPORTED_PROVENANCE_SOURCE_TYPES,
    load_catalog,
)
from scripts.automation.src.triage.rca_schema import (
    Classification,
    SuggestedAction,
)
from scripts.automation.src.triage.redact import (
    LOGS_MAX_BYTES,
    REGEX_ELIGIBLE_FIELDS,
)


# ===========================================================================
# Fixtures
# ===========================================================================

VALID_PATTERN: dict = {
    "pattern_id": "fk_orphan_detection_failure_v1",
    "classification": "test_failure",
    "sub_class": "fk_orphan_detection",
    "signal_sources": ["message", "truncated_debug_logs"],
    "match_logic": {
        "type": "regex_and_substring",
        "requires_all": [
            {
                "field": "message",
                "pattern": "dbt_constraints_foreign_key|foreign_key.*test",
                "flags": "case_insensitive",
            },
            {
                "field": "message",
                "pattern": r"got\s+\d+\s+result|fail(ed|ure)",
                "flags": "case_insensitive",
            },
        ],
    },
    "confidence_baseline": 0.85,
    "suggested_action": "investigate_source_data",
    "root_cause_investigation_required": True,
    "auto_retry_eligible": False,
    "provenance": {
        "source_type": "lessons_md",
        "citation": "lesson #120",
        "notes": "DV 2.1 referential integrity.",
    },
    "notes": "FK constraint failure indicates orphan rows.",
}


def _write_catalog(tmp_path: Path, patterns: list[dict]) -> Path:
    """Helper: write a catalog YAML and return the path."""
    path = tmp_path / "catalog.yml"
    body = {
        "catalog_schema_version": CATALOG_SCHEMA_VERSION,
        "patterns": patterns,
    }
    path.write_text(yaml.safe_dump(body))
    return path


# ===========================================================================
# Module constants
# ===========================================================================

class TestModuleConstants:
    def test_catalog_schema_version_is_pinned(self):
        assert CATALOG_SCHEMA_VERSION == "v1.2.0"

    def test_supported_match_logic_types_is_strict(self):
        # v1.0.0 shipped exactly one match type. Adding a type requires a
        # deliberate catalog schema bump (see YAML header comment).
        assert SUPPORTED_MATCH_LOGIC_TYPES == frozenset({"regex_and_substring"})

    def test_supported_provenance_source_types_is_strict(self):
        # v1.1.0 ships exactly two: lessons_md, gate_d_evidence.
        # `pr_retrospective` and `synthetic` deliberately withheld — see
        # YAML header rationale on provenance laundering defense.
        assert SUPPORTED_PROVENANCE_SOURCE_TYPES == frozenset(
            {"lessons_md", "gate_d_evidence"}
        )

    def test_provenance_citation_regex_table_matches_source_types(self):
        # Every supported source_type MUST have a citation regex; conversely,
        # no orphan regex entries. Drift between the two would silently
        # accept patterns whose citation is unchecked.
        assert set(PROVENANCE_SOURCE_CITATION_REGEX.keys()) == SUPPORTED_PROVENANCE_SOURCE_TYPES

    def test_synthetic_source_type_is_NOT_supported(self):
        # Negative-evidence test: this is a regression guard for the
        # provenance laundering defense documented in the YAML header.
        # Re-introducing `synthetic` requires a deliberate schema bump.
        assert "synthetic" not in SUPPORTED_PROVENANCE_SOURCE_TYPES


# ===========================================================================
# Real catalog (the shipped fbin_error_catalog.yml)
# ===========================================================================

class TestShippedCatalog:
    def test_default_catalog_loads_without_error(self):
        patterns = load_catalog()
        assert len(patterns) >= 1

    def test_default_catalog_path_exists(self):
        assert DEFAULT_CATALOG_PATH.exists(), (
            f"shipped catalog must exist at {DEFAULT_CATALOG_PATH}"
        )

    def test_shipped_pattern_has_expected_pattern_id(self):
        patterns = load_catalog()
        ids = {p.pattern_id for p in patterns}
        assert "fk_orphan_detection_failure_v1" in ids

    def test_shipped_catalog_has_gate_d_evidence_pattern(self):
        # Day 4: Phase C added pr_isolated_schema_missing_upstream_v1
        # from Gate-D run_id=487333396. This test pins that addition so
        # accidentally dropping the second pattern breaks CI.
        patterns = load_catalog()
        ids = {p.pattern_id for p in patterns}
        assert "pr_isolated_schema_missing_upstream_v1" in ids

    def test_shipped_catalog_has_cluster_a_manifest_parse_pattern(self):
        # Day 4 Phase B: shipped manifest_parse_failure_invalid_model_language_v1
        # from Cluster A (3 confirming runs: 485821754, 485850628, 485851058).
        # FIRST pattern citing signal_sources: [logs] post-Round-3.5.5 BLOCK
        # lift. This test pins that addition so accidentally dropping the
        # third pattern breaks CI.
        patterns = load_catalog()
        ids = {p.pattern_id for p in patterns}
        assert "manifest_parse_failure_invalid_model_language_v1" in ids

    def test_shipped_catalog_count_snapshot(self):
        # Snapshot assertion: 3 patterns ship as of Day 4 Phase B.
        # Adding a fourth pattern requires updating this number AND
        # adding a presence test above + adding the new pattern_id to
        # FIXTURE-INTEGRITY parametrize lists below.
        assert len(load_catalog()) == 3

    def test_every_shipped_pattern_passes_iron_rule(self):
        # Belt-and-suspenders: even the loader-validated set must be
        # introspectable for the Iron Rule, so future engineers can
        # query the catalog directly.
        for p in load_catalog():
            if p.classification == Classification.TEST_FAILURE:
                assert p.root_cause_investigation_required is True
                assert p.suggested_action != SuggestedAction.MODIFY_TEST

    def test_every_shipped_signal_source_is_eligible(self):
        for p in load_catalog():
            for src in p.signal_sources:
                assert src in REGEX_ELIGIBLE_FIELDS

    def test_every_shipped_pattern_has_valid_provenance(self):
        # Roundtrip: every shipped pattern's provenance survives the
        # loader and is exposed as a structured Provenance dataclass.
        for p in load_catalog():
            assert isinstance(p.provenance, Provenance)
            assert p.provenance.source_type in SUPPORTED_PROVENANCE_SOURCE_TYPES
            regex = PROVENANCE_SOURCE_CITATION_REGEX[p.provenance.source_type]
            import re as _re
            assert _re.fullmatch(regex, p.provenance.citation)


# ===========================================================================
# Loader happy path (synthetic catalog)
# ===========================================================================

class TestLoaderHappyPath:
    def test_loader_returns_tuple_of_patterns(self, tmp_path):
        path = _write_catalog(tmp_path, [copy.deepcopy(VALID_PATTERN)])
        patterns = load_catalog(path)
        assert isinstance(patterns, tuple)
        assert len(patterns) == 1
        assert isinstance(patterns[0], Pattern)

    def test_loaded_pattern_carries_enum_values(self, tmp_path):
        path = _write_catalog(tmp_path, [copy.deepcopy(VALID_PATTERN)])
        (p,) = load_catalog(path)
        assert p.classification is Classification.TEST_FAILURE
        assert p.suggested_action is SuggestedAction.INVESTIGATE_SOURCE_DATA

    def test_missing_catalog_raises_file_not_found(self, tmp_path):
        with pytest.raises(FileNotFoundError):
            load_catalog(tmp_path / "does_not_exist.yml")

    def test_wrong_schema_version_rejected(self, tmp_path):
        path = tmp_path / "catalog.yml"
        path.write_text(yaml.safe_dump({
            "catalog_schema_version": "v0.9.0",
            "patterns": [copy.deepcopy(VALID_PATTERN)],
        }))
        with pytest.raises(CatalogValidationError, match="catalog_schema_version"):
            load_catalog(path)

    def test_empty_patterns_list_rejected(self, tmp_path):
        path = _write_catalog(tmp_path, [])
        with pytest.raises(CatalogValidationError, match="non-empty"):
            load_catalog(path)


# ===========================================================================
# Mutation tests — the heart of the quality gate (Gate 6)
# ===========================================================================

class TestMutations:
    """Each mutation MUST be caught at load time, never at match time."""

    def test_mut1_duplicate_pattern_id_rejected(self, tmp_path):
        p1 = copy.deepcopy(VALID_PATTERN)
        p2 = copy.deepcopy(VALID_PATTERN)  # same pattern_id
        path = _write_catalog(tmp_path, [p1, p2])
        with pytest.raises(CatalogValidationError, match="duplicate pattern_id.*Mut1"):
            load_catalog(path)

    def test_mut2_invalid_classification_rejected(self, tmp_path):
        bad = copy.deepcopy(VALID_PATTERN)
        bad["classification"] = "frbnigle_error"  # typo, not in enum
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match="classification.*Mut2"):
            load_catalog(path)

    def test_mut3a_iron_rule_investigation_flag_required(self, tmp_path):
        bad = copy.deepcopy(VALID_PATTERN)
        bad["root_cause_investigation_required"] = False
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match="Iron Rule.*Mut3a"):
            load_catalog(path)

    def test_mut3b_iron_rule_modify_test_forbidden(self, tmp_path):
        bad = copy.deepcopy(VALID_PATTERN)
        bad["suggested_action"] = "modify_test"
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match="Iron Rule.*Mut3b"):
            load_catalog(path)

    def test_mut4_signal_source_escape_rejected(self, tmp_path):
        bad = copy.deepcopy(VALID_PATTERN)
        # compiled_code is in PREVIEW_FIELDS, NOT REGEX_ELIGIBLE_FIELDS.
        # A pattern declaring it as a signal source is the escape hatch.
        bad["signal_sources"] = ["message", "compiled_code"]
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match="signal_sources.*Mut4"):
            load_catalog(path)

    def test_mut5_unsupported_match_logic_type_rejected(self, tmp_path):
        bad = copy.deepcopy(VALID_PATTERN)
        bad["match_logic"]["type"] = "unsupported_xyz"
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match="match_logic.type.*Mut5"):
            load_catalog(path)

    def test_mut4_clause_field_also_validated(self, tmp_path):
        """The Mut4 invariant covers BOTH top-level signal_sources AND each
        clause's field. A clause leaking compiled_code would be the same
        escape hatch — verify both surfaces are protected."""
        bad = copy.deepcopy(VALID_PATTERN)
        bad["match_logic"]["requires_all"][0]["field"] = "compiled_code"
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match="Mut4"):
            load_catalog(path)

    def test_mut6_unsupported_provenance_source_type_rejected(self, tmp_path):
        """`pr_retrospective` is intentionally withheld from v1.1.0 — it MUST
        be rejected. This is the provenance-laundering defense."""
        bad = copy.deepcopy(VALID_PATTERN)
        bad["provenance"] = {
            "source_type": "pr_retrospective",
            "citation": "PR #1771 retrospective",
        }
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match="source_type.*Mut6"):
            load_catalog(path)

    def test_mut6_synthetic_source_type_rejected(self, tmp_path):
        """Explicit guard: `synthetic` is THE escape hatch the v1.1.0 design
        withholds. Any future PR that tries to ship synthetic patterns MUST
        bump the schema deliberately."""
        bad = copy.deepcopy(VALID_PATTERN)
        bad["provenance"] = {
            "source_type": "synthetic",
            "citation": "adversarial test fixture",
        }
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match="source_type.*Mut6"):
            load_catalog(path)

    def test_mut7_provenance_citation_regex_mismatch_rejected(self, tmp_path):
        """lessons_md requires `^lesson #\\d+$` — a free-text citation MUST
        be rejected even if the source_type is valid."""
        bad = copy.deepcopy(VALID_PATTERN)
        bad["provenance"] = {
            "source_type": "lessons_md",
            "citation": "see the docs somewhere",  # not 'lesson #N'
        }
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match="citation.*Mut7"):
            load_catalog(path)

    def test_mut7_gate_d_citation_regex_enforced(self, tmp_path):
        """gate_d_evidence requires `^run_id=\\d+$` — prose form rejected."""
        bad = copy.deepcopy(VALID_PATTERN)
        bad["provenance"] = {
            "source_type": "gate_d_evidence",
            "citation": "the early-failure run from Gate D",
        }
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match="citation.*Mut7"):
            load_catalog(path)

    def test_mut7_lessons_md_with_gate_d_citation_format_rejected(self, tmp_path):
        """Cross-type mismatch: source_type=lessons_md with run_id citation
        MUST be rejected. The citation regex is type-specific."""
        bad = copy.deepcopy(VALID_PATTERN)
        bad["provenance"] = {
            "source_type": "lessons_md",
            "citation": "run_id=12345",  # gate_d format, wrong source
        }
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match="citation.*Mut7"):
            load_catalog(path)

    # ------------------------------------------------------------------
    # Mut9d — logs signal ⟹ max_bytes ∈ [1, LOGS_MAX_BYTES]
    # (Day 3.8, Sprint-1 #12; see docs/triage-agent/gate-d-logs-field-amendment.md §5)
    # ------------------------------------------------------------------
    # Lane discipline (verbatim, do NOT delete):
    #   Mut9d is a LOAD-TIME catalog-validation gate. Its job is catching
    #   structurally broken matcher contracts (missing, 0, negative,
    #   over-cap). The "max_bytes=100 thinking-it's-KB" failure mode is
    #   empirically caught by pattern dry-run smoke tests against the
    #   Day-4 fixtures, not by load validation. Pinning Mut9d to
    #   [1, LOGS_MAX_BYTES] keeps the two test categories separate.
    #   Bumping the lower bound to 1024 would require empirical
    #   justification (why 1024? why not 512 or 2048?) that the Day-3.7
    #   battery did not produce.
    # ------------------------------------------------------------------

    @staticmethod
    def _logs_pattern() -> dict:
        """Base pattern that cites `logs` (so Mut9d applies)."""
        p = copy.deepcopy(VALID_PATTERN)
        p["pattern_id"] = "logs_test_pattern_v1"
        p["signal_sources"] = ["logs"]
        p["match_logic"]["requires_all"][0]["field"] = "logs"
        p["match_logic"]["requires_all"][1]["field"] = "logs"
        return p

    def test_mut9d_1_logs_signal_without_max_bytes_rejected(self, tmp_path):
        """Mut9d.1 — pattern citing `logs` with NO max_bytes key MUST be rejected."""
        bad = self._logs_pattern()
        # No max_bytes key at all
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match=r"max_bytes.*Mut9d"):
            load_catalog(path)

    def test_mut9d_2_logs_signal_max_bytes_zero_rejected(self, tmp_path):
        """Mut9d.2 — max_bytes=0 MUST be rejected (lower-bound violation)."""
        bad = self._logs_pattern()
        bad["max_bytes"] = 0
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match=r"max_bytes.*Mut9d"):
            load_catalog(path)

    def test_mut9d_2_logs_signal_max_bytes_negative_rejected(self, tmp_path):
        """Mut9d.2 (negative variant) — max_bytes < 0 MUST be rejected."""
        bad = self._logs_pattern()
        bad["max_bytes"] = -1
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match=r"max_bytes.*Mut9d"):
            load_catalog(path)

    def test_mut9d_3_logs_signal_max_bytes_over_cap_rejected(self, tmp_path):
        """Mut9d.3 — max_bytes > LOGS_MAX_BYTES MUST be rejected.

        Lock value: 65,537 = LOGS_MAX_BYTES + 1. Drift in LOGS_MAX_BYTES
        in redact.py would break this assertion at the LOGS_MAX_BYTES + 1
        boundary — forcing a deliberate sync between the two modules.
        """
        bad = self._logs_pattern()
        bad["max_bytes"] = LOGS_MAX_BYTES + 1
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match=r"max_bytes.*Mut9d"):
            load_catalog(path)

    def test_mut9d_logs_signal_max_bytes_bool_rejected(self, tmp_path):
        """Mut9d (type-narrow variant) — bool is a subclass of int in
        Python; the validator MUST reject it explicitly so a `True` value
        (which equals 1) is not silently accepted as a 1-byte cap."""
        bad = self._logs_pattern()
        bad["max_bytes"] = True  # = int(1) by inheritance
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match=r"max_bytes.*Mut9d"):
            load_catalog(path)

    def test_mut9d_logs_signal_max_bytes_string_rejected(self, tmp_path):
        """Mut9d (type-wide variant) — string value MUST be rejected."""
        bad = self._logs_pattern()
        bad["max_bytes"] = "30000"
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match=r"max_bytes.*Mut9d"):
            load_catalog(path)

    def test_mut9d_logs_signal_valid_max_bytes_accepted(self, tmp_path):
        """Mut9d positive case — max_bytes = 1 (the minimum) loads cleanly.

        Documents the lower bound is INCLUSIVE of 1. The matcher's
        empirical lower bound is a separate gate.
        """
        good = self._logs_pattern()
        good["max_bytes"] = 1
        path = _write_catalog(tmp_path, [good])
        (p,) = load_catalog(path)
        assert p.max_bytes == 1

    def test_mut9d_logs_signal_valid_max_bytes_at_cap_accepted(self, tmp_path):
        """Mut9d positive case — max_bytes = LOGS_MAX_BYTES (the cap) loads cleanly."""
        good = self._logs_pattern()
        good["max_bytes"] = LOGS_MAX_BYTES
        path = _write_catalog(tmp_path, [good])
        (p,) = load_catalog(path)
        assert p.max_bytes == LOGS_MAX_BYTES

    def test_mut9d_non_logs_pattern_without_max_bytes_accepted(self, tmp_path):
        """Mut9d negative-evidence — patterns NOT citing `logs` are
        unaffected by Mut9d and may omit max_bytes entirely.

        This is the backwards-compatibility guarantee for v1.1.0 → v1.2.0:
        every existing pattern in the shipped catalog passes through
        without modification.
        """
        good = copy.deepcopy(VALID_PATTERN)  # signal_sources = message, truncated_debug_logs
        # No max_bytes key — must still load
        assert "logs" not in good["signal_sources"]
        path = _write_catalog(tmp_path, [good])
        (p,) = load_catalog(path)
        assert p.max_bytes is None


# ===========================================================================
# Additional structural validation
# ===========================================================================

class TestStructuralValidation:
    def test_missing_required_key_rejected(self, tmp_path):
        bad = copy.deepcopy(VALID_PATTERN)
        del bad["provenance"]
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match="missing required keys"):
            load_catalog(path)

    def test_confidence_out_of_range_rejected(self, tmp_path):
        bad = copy.deepcopy(VALID_PATTERN)
        bad["confidence_baseline"] = 1.5
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match="confidence_baseline"):
            load_catalog(path)

    def test_invalid_regex_rejected(self, tmp_path):
        bad = copy.deepcopy(VALID_PATTERN)
        bad["match_logic"]["requires_all"][0]["pattern"] = "([unclosed"
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match="invalid regex"):
            load_catalog(path)

    def test_invalid_flags_rejected(self, tmp_path):
        bad = copy.deepcopy(VALID_PATTERN)
        bad["match_logic"]["requires_all"][0]["flags"] = "FOOBAR"
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match="flags must be"):
            load_catalog(path)

    def test_empty_signal_sources_rejected(self, tmp_path):
        bad = copy.deepcopy(VALID_PATTERN)
        bad["signal_sources"] = []
        path = _write_catalog(tmp_path, [bad])
        with pytest.raises(CatalogValidationError, match="non-empty"):
            load_catalog(path)


# ===========================================================================
# Matcher behaviour
# ===========================================================================

class TestMatcher:
    def _matcher(self):
        return PatternMatcher(load_catalog())

    def test_matches_canonical_fk_orphan_failure_message(self):
        # Snapshot: this exact payload MUST map to fk_orphan_detection_failure_v1
        # with the documented confidence + action. Changing either side is
        # a breaking change for downstream consumers.
        payload = {
            "message": (
                "Failure in test dbt_constraints_foreign_key_sat_payment_terms_"
                "PAYMENT_TERMS_HK__ref_hub_payment_terms_ (got 42 results, "
                "expected 0)"
            ),
            "truncated_debug_logs": "...",
        }
        match = self._matcher().match(payload)
        assert match is not None
        assert match.pattern_id == "fk_orphan_detection_failure_v1"
        assert match.classification is Classification.TEST_FAILURE
        assert match.suggested_action is SuggestedAction.INVESTIGATE_SOURCE_DATA
        assert match.confidence_baseline == 0.85
        assert match.root_cause_investigation_required is True
        assert match.auto_retry_eligible is False
        assert match.provenance.source_type == "lessons_md"
        assert match.provenance.citation == "lesson #120"

    def test_non_matching_payload_returns_none(self):
        payload = {
            "message": "Database adapter timeout after 600 seconds",
            "truncated_debug_logs": "connection reset",
        }
        assert self._matcher().match(payload) is None

    def test_match_requires_all_clauses(self):
        # Has the FK keyword but not the failure keyword — must NOT match.
        payload = {"message": "foreign_key test created successfully"}
        assert self._matcher().match(payload) is None

    def test_match_ignores_non_signal_fields(self):
        # compiled_code contains the keywords but is NOT a signal_source,
        # so a payload that only has compiled_code populated must not match.
        payload = {
            "compiled_code": "dbt_constraints_foreign_key got 5 results failed",
        }
        assert self._matcher().match(payload) is None

    def test_match_handles_missing_field_gracefully(self):
        assert self._matcher().match({}) is None

    def test_match_handles_non_string_field_value(self):
        assert self._matcher().match({"message": 42}) is None

    def test_match_all_returns_list(self):
        payload = {
            "message": (
                "dbt_constraints_foreign_key test failed with got 7 results"
            ),
        }
        matches = self._matcher().match_all(payload)
        assert isinstance(matches, list)
        assert len(matches) == 1


# ===========================================================================
# Contract: PatternMatch shape is RCARecord-compatible
# ===========================================================================

class TestPatternMatchContract:
    def test_pattern_match_classification_is_enum(self):
        """PatternMatch.classification must be a Classification enum so it
        plugs directly into RCARecord(classification=...) without coercion."""
        patterns = load_catalog()
        matcher = PatternMatcher(patterns)
        payload = {"message": "dbt_constraints_foreign_key got 5 results failed"}
        match = matcher.match(payload)
        assert match is not None
        assert isinstance(match.classification, Classification)
        assert isinstance(match.suggested_action, SuggestedAction)

    def test_pattern_match_is_frozen(self):
        patterns = load_catalog()
        matcher = PatternMatcher(patterns)
        payload = {"message": "dbt_constraints_foreign_key got 5 results failed"}
        match = matcher.match(payload)
        assert match is not None
        with pytest.raises((AttributeError, Exception)):
            match.pattern_id = "tampered"  # type: ignore[misc]


# ===========================================================================
# Day 4 — Pattern 2 (pr_isolated_schema_missing_upstream_v1)
# ===========================================================================
# Real Gate-D evidence from QA run 487333396 (and 487313189 as second
# confirming source). Tests below load the redacted fixture from disk so
# the catalog regex is exercised against actual dbt Cloud Admin API output,
# not a hand-tuned synthetic payload.

import json as _json

FIXTURE_DIR = (
    Path(__file__).parent.parent.parent.parent / "docs" / "triage-agent" / "fixtures"
)
POSITIVE_FIXTURE = FIXTURE_DIR / "early_failure_pr_schema_missing_487333396.json"
NEGATIVE_FIXTURE = FIXTURE_DIR / "early_failure_manifest_parse_485851058.json"
PATTERN3_POSITIVE_FIXTURE = FIXTURE_DIR / "early_failure_manifest_parse_485821754.json"

# Pipeline-emitted fixtures (per `redactor_pipeline.py --all`) carry the
# full dbt Cloud envelope `{_fixture_metadata, data, status}` with the
# raw API `data.run_steps` list preserved. The pattern-matcher regexes
# operate on flat payloads `{field: <string>}`, so test sites extract the
# error step's `truncated_debug_logs` / `logs` field via this helper.
# Filter by `status_humanized == "Error"` (not by index) to stay portable
# across re-emissions or future fixtures with different step counts — all
# four 2026-06-11 re-emits put the Error step at index 3, but the contract
# is "the failing step," not "step[3]."
def _extract_error_step_field(body: dict, field: str) -> str:
    error_steps = [
        s for s in body["data"]["run_steps"]
        if s.get("status_humanized") == "Error"
    ]
    assert error_steps, (
        "fixture envelope has no run_step with status_humanized='Error'; "
        "either the fixture is malformed or it was emitted from a non-failure run"
    )
    return error_steps[-1][field]

# Pattern 3 signature-variant payloads: small hand-constructed strings that
# exercise the regex against timestamp + macro-name variations observed in
# the P0.1 corpus dump. THESE ARE NOT REDACTED-FULL-LOG CONFIRMATIONS of
# additional runs — they are regex-robustness tests using literal text
# fragments that appear in the actual logs. The canonical fixture on disk
# (485821754) is the SINGLE end-to-end-truncated-and-matched evidence file;
# multi-run claims in provenance.notes refer to *incident occurrences*
# observed in the corpus dump, not independently-redacted fixtures.
PATTERN3_SIGNATURE_VARIANT_DIFFERENT_TIMESTAMP = (
    "11:04:14  Encountered an error:\n"
    'Field "macros" of type Mapping[str, Macro] in WritableManifest has '
    "invalid value {'macro.dbt_datavault.test_accepted_values': ...}"
)
PATTERN3_SIGNATURE_VARIANT_DIFFERENT_MACRO_NAME = (
    "11:05:41  Encountered an error:\n"
    'Field "macros" of type Mapping[str, Macro] in WritableManifest has '
    "invalid value {'macro.dbt_datavault.apply_object_tags': ...}"
)


class TestPattern2Pattern:
    """Catalog-side assertions for Pattern 2: structure and provenance."""

    def _pattern(self):
        for p in load_catalog():
            if p.pattern_id == "pr_isolated_schema_missing_upstream_v1":
                return p
        pytest.fail("Pattern pr_isolated_schema_missing_upstream_v1 missing from shipped catalog")

    def test_classification_is_compile_error(self):
        # NOT test_failure → Iron Rule does not apply, but verifying the
        # explicit choice prevents future drift to test_failure (which would
        # also force MODIFY_TEST forbiddance — over-restrictive here).
        assert self._pattern().classification == Classification.COMPILE_ERROR

    def test_suggested_action_is_escalate_to_human(self):
        # PR-schema reconstruction is an operational fix (rebuild raw vault
        # in PR-isolated schema), not a code change. Auto-retry would just
        # hit the same missing-object error.
        assert self._pattern().suggested_action == SuggestedAction.ESCALATE_TO_HUMAN

    def test_auto_retry_eligible_is_false(self):
        # Same schema state will produce same failure. Retry without
        # rebuilding raw vault wastes compute and pollutes Cloud history.
        assert self._pattern().auto_retry_eligible is False

    def test_root_cause_investigation_required_is_true(self):
        # Schema state mismatch needs investigation: was the PR selector
        # wrong? Did a sibling PR clean the schema? Was there an upstream
        # raw_vault build failure earlier? Cannot defer without diagnosis.
        assert self._pattern().root_cause_investigation_required is True

    def test_provenance_cites_actual_run_id(self):
        # Phase D defense: regex matches `run_id=<N>` shape (per Mut7),
        # but ALSO must cite the exact run captured in the fixture.
        prov = self._pattern().provenance
        assert prov.source_type == "gate_d_evidence"
        assert prov.citation == "run_id=487333396"
        assert NEGATIVE_FIXTURE.exists()  # negative fixture must also exist

    def test_signal_sources_only_uses_allowlisted_field(self):
        # Pattern reads truncated_debug_logs ONLY. The 2.9MB `logs` field
        # was deliberately excluded from REGEX_ELIGIBLE_FIELDS (Sprint 1
        # deferred item — see early-failure-evidence.md Phase D notes).
        srcs = self._pattern().signal_sources
        assert srcs == ("truncated_debug_logs",)
        for s in srcs:
            assert s in REGEX_ELIGIBLE_FIELDS

    def test_match_logic_has_two_required_clauses(self):
        # Strong-signal pattern requires BOTH object-not-exist AND the
        # PR-schema path marker. Either alone is too generic.
        p = self._pattern()
        assert p.match_logic_type == "regex_and_substring"
        assert len(p.match_clauses) == 2


class TestPattern2Matcher:
    """End-to-end matcher contract using real redacted fixtures."""

    def _matcher(self):
        return PatternMatcher(load_catalog())

    def test_positive_fixture_loads_clean(self):
        assert POSITIVE_FIXTURE.exists(), (
            f"Positive fixture missing at {POSITIVE_FIXTURE}. Re-stage from "
            "~/scratch/triage-day4/run_487333396_cluster_B.json via "
            "`.venv/bin/python3 -m scripts.automation.src.triage.redactor_pipeline --all`."
        )
        body = _json.loads(POSITIVE_FIXTURE.read_text())
        # New envelope (post-2026-06-11 re-emission): provenance comes
        # from the pipeline's 8-field metadata, not the legacy
        # `sentinel_fired` / `redactions_applied` pair.
        #
        # `sentinel_fired` was intentionally REMOVED from the assertion
        # surface: the redactor pipeline is FAIL-CLOSED — it raises
        # CredentialSentinelFired and blocks emission on any sentinel
        # hit, so a committed fixture provably cannot carry
        # sentinel_fired=True. Asserting `is False` on a value that
        # cannot be True is theatre, not coverage; the fail-closed
        # construction is what enforces the contract.
        #
        # `email_substitution_count` (renamed from `redactions_applied`,
        # DA F-4) is the only redaction count the pipeline still emits;
        # for this committed fixture it must be 0.
        meta = body["_fixture_metadata"]
        assert meta["source_run_id"] == 487333396
        assert meta["source_cluster"] == "B"
        assert meta["email_substitution_count"] == 0

    def test_positive_fixture_matches_pattern_2(self):
        body = _json.loads(POSITIVE_FIXTURE.read_text())
        payload = {"truncated_debug_logs": _extract_error_step_field(body, "truncated_debug_logs")}
        matches = self._matcher().match_all(payload)
        ids = [m.pattern_id for m in matches]
        assert "pr_isolated_schema_missing_upstream_v1" in ids

    def test_positive_fixture_match_returns_full_metadata(self):
        body = _json.loads(POSITIVE_FIXTURE.read_text())
        payload = {"truncated_debug_logs": _extract_error_step_field(body, "truncated_debug_logs")}
        match = next(
            (
                m for m in self._matcher().match_all(payload)
                if m.pattern_id == "pr_isolated_schema_missing_upstream_v1"
            ),
            None,
        )
        assert match is not None
        assert match.classification == Classification.COMPILE_ERROR
        assert match.suggested_action == SuggestedAction.ESCALATE_TO_HUMAN
        assert match.confidence_baseline == 0.90
        assert match.auto_retry_eligible is False
        assert match.root_cause_investigation_required is True
        assert match.provenance.citation == "run_id=487333396"

    def test_negative_fixture_does_NOT_match_pattern_2(self):
        # Cluster A (manifest_parse_failure) has its error in `logs` field,
        # not in `truncated_debug_logs`. Pattern 2's regex MUST NOT
        # falsely fire on a different cluster's truncated_debug_logs.
        body = _json.loads(NEGATIVE_FIXTURE.read_text())
        payload = {"truncated_debug_logs": _extract_error_step_field(body, "truncated_debug_logs")}
        matches = self._matcher().match_all(payload)
        ids = [m.pattern_id for m in matches]
        assert "pr_isolated_schema_missing_upstream_v1" not in ids

    def test_partial_signal_does_NOT_match(self):
        # Has 'Object does not exist' but no PR-isolated schema path —
        # could be ANY missing-object error (not specifically a PR build).
        payload = {
            "truncated_debug_logs": (
                "Database Error in model foo\n"
                "002003 (42S02): SQL compilation error: Object "
                "'DATAVAULT_QA.RAW_VAULT.LNK_FOO' does not exist or not authorized"
            )
        }
        matches = self._matcher().match_all(payload)
        ids = [m.pattern_id for m in matches]
        assert "pr_isolated_schema_missing_upstream_v1" not in ids

    def test_pr_marker_alone_does_NOT_match(self):
        # Has PR-isolated schema name but no object-not-exist error.
        # Could be a successful build referencing the same schema.
        payload = {
            "truncated_debug_logs": (
                "Connecting to DATAVAULT_QA.DBT_CLOUD_PR_786808_1726_RAW_VAULT "
                "with role DBT_QA_CLOUD ... OK"
            )
        }
        matches = self._matcher().match_all(payload)
        ids = [m.pattern_id for m in matches]
        assert "pr_isolated_schema_missing_upstream_v1" not in ids

    def test_does_not_match_fk_orphan_pattern(self):
        # Cross-pattern isolation: a payload that matches pattern 2 must
        # NOT also match pattern 1 (fk_orphan). Different classifications
        # would confuse the RCARecord consumer.
        body = _json.loads(POSITIVE_FIXTURE.read_text())
        payload = {"truncated_debug_logs": _extract_error_step_field(body, "truncated_debug_logs")}
        matches = self._matcher().match_all(payload)
        ids = [m.pattern_id for m in matches]
        assert "fk_orphan_detection_failure_v1" not in ids


class TestFixtureIntegrity:
    """Defense-in-depth: fixtures committed to git must be PII-clean."""

    # Direct unit tests for the `_extract_error_step_field` helper.
    # Without these, mutations of the helper's selection rule (e.g.,
    # `error_steps[-1]` \u2192 `error_steps[0]`, or `== "Error"` \u2192
    # `== "Errored"`) are silent on the current 7-fixture corpus
    # because each fixture has exactly one Error step. The synthetic
    # bodies below construct the multi-Error-step case that the real
    # fixtures don't currently exercise, so mutation Mut2 (last vs
    # first) is catchable independently of corpus drift.
    def test_extract_error_step_field_returns_latest_error(self):
        body = {
            "data": {
                "run_steps": [
                    {"status_humanized": "Success", "logs": "ok_0"},
                    {"status_humanized": "Error", "logs": "first_error"},
                    {"status_humanized": "Error", "logs": "second_error"},
                ]
            }
        }
        # Contract: when multiple Error steps are present, return the LAST
        # (matches dbt-cli semantics of "latest aborted step").
        assert _extract_error_step_field(body, "logs") == "second_error"

    def test_extract_error_step_field_filters_by_humanized_status(self):
        body = {
            "data": {
                "run_steps": [
                    {"status_humanized": "Success", "logs": "ignore_success"},
                    {"status_humanized": "Cancelled", "logs": "ignore_cancelled"},
                    {"status_humanized": "Error", "logs": "the_error"},
                ]
            }
        }
        # Contract: only steps with status_humanized == "Error" are
        # selected; "Errored" / "Cancelled" / "Failed" / etc. are not
        # equivalents \u2014 dbt Cloud uses "Error" exactly.
        assert _extract_error_step_field(body, "logs") == "the_error"

    def test_extract_error_step_field_raises_when_no_error_step(self):
        body = {
            "data": {
                "run_steps": [
                    {"status_humanized": "Success", "logs": "all_passed"},
                ]
            }
        }
        # Contract: assertion fires loudly on a fixture that has no
        # Error step (would otherwise return None or IndexError silently).
        with pytest.raises(AssertionError, match="status_humanized='Error'"):
            _extract_error_step_field(body, "logs")

    # Empty-parametrize guard. pytest.mark.parametrize with an empty
    # iterable issues a warning ("got empty parameter set") but does
    # NOT fail the session — so glob-parametrized tests below would
    # silently pass-by-no-cases if somebody nukes the fixture dir or
    # renames files outside the early_failure_*.json convention. This
    # standalone test asserts exact set membership against the expected
    # 7-file P0.1 corpus, making any corpus drift loud at the consumer
    # boundary. Pair with `p01_labels.yml` v1.1.0 (7 entries) and the
    # `phase-2-progress-log.md` corpus-listing table.
    def test_corpus_contains_expected_fixtures(self):
        EXPECTED_BASENAMES = {
            "early_failure_dmf_failure_484675412.json",
            "early_failure_dmf_failure_486060143.json",
            "early_failure_manifest_parse_485821754.json",
            "early_failure_manifest_parse_485850628.json",
            "early_failure_manifest_parse_485851058.json",
            "early_failure_pr_schema_missing_487313189.json",
            "early_failure_pr_schema_missing_487333396.json",
        }
        actual = {p.name for p in FIXTURE_DIR.glob("early_failure_*.json")}
        assert actual == EXPECTED_BASENAMES, (
            f"Fixture corpus drifted from expected 7-file P0.1 set.\n"
            f"  missing: {sorted(EXPECTED_BASENAMES - actual)}\n"
            f"  extra:   {sorted(actual - EXPECTED_BASENAMES)}\n"
            f"If intentional, update EXPECTED_BASENAMES here AND in\n"
            f"`p01_labels.yml` + `phase-2-progress-log.md`."
        )

    @pytest.mark.parametrize(
        "fixture",
        sorted(FIXTURE_DIR.glob("early_failure_*.json")),
        ids=lambda p: p.name,
    )
    def test_fixture_contains_no_credentials(self, fixture):
        import re as _re
        raw = fixture.read_text()
        # Scan for credential-shaped strings that should have been redacted.
        # If any fire, the fixture was staged from an unredacted payload —
        # remove it from git history AND fix the redact path.
        forbidden = {
            "JWT-shape": _re.compile(r"eyJ[a-zA-Z0-9_-]{20,}\.[a-zA-Z0-9_-]{20,}"),
            "AWS-key":   _re.compile(r"AKIA[0-9A-Z]{16}"),
            "GitHub-PAT": _re.compile(r"ghp_[a-zA-Z0-9]{36}"),
            "private-key-header": _re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY"),
        }
        for name, rx in forbidden.items():
            assert not rx.search(raw), f"Fixture {fixture.name} contains {name}"

    @pytest.mark.parametrize(
        "fixture",
        sorted(FIXTURE_DIR.glob("early_failure_*.json")),
        ids=lambda p: p.name,
    )
    def test_fixture_metadata_documents_provenance(self, fixture):
        # Structural CS-2 enforcement: the redactor pipeline caps the
        # fixture metadata at exactly 8 fields (see redactor_pipeline.py
        # docstring: "Exactly 8 fields. Growing past 8 needs justification").
        # `set(meta.keys()) == EXPECTED_8` catches both DROPPED fields
        # (regression) and ADDED fields (uncoordinated growth) at the
        # consumer boundary — a single inequality protects the contract
        # in both directions, where `for key in EXPECTED: assert key in meta`
        # only catches drops.
        body = _json.loads(fixture.read_text())
        meta = body["_fixture_metadata"]
        EXPECTED_8 = {
            "content_sha256",
            "email_substitution_count",
            "redact_schema_version",
            "retained_step_count",
            "source_basename",
            "source_cluster",
            "source_run_id",
            "source_size_bytes",
        }
        assert set(meta.keys()) == EXPECTED_8, (
            f"{fixture.name} metadata fields drifted from the pipeline contract.\n"
            f"  expected: {sorted(EXPECTED_8)}\n"
            f"  actual:   {sorted(meta.keys())}\n"
            f"  missing:  {sorted(EXPECTED_8 - set(meta.keys()))}\n"
            f"  extra:    {sorted(set(meta.keys()) - EXPECTED_8)}\n"
            "If this is intentional, update EXPECTED_8 and the CS-2 cap\n"
            "comment in redactor_pipeline.py."
        )


# ===========================================================================
# Pattern 3 — manifest_parse_failure_invalid_model_language_v1
#
# FIRST shipped pattern citing signal_sources: [logs] post-Round-3.5.5 BLOCK
# lift (truncate_logs v2 landed in d72e20b5). Derived from 3 Gate-D
# confirming runs in P0.1 corpus, all QA env 296453, all compile-phase
# manifest parse failures, all OUT-OF-WINDOW under Day-3.8 hybrid truncation
# (margin -2.67 MB), all recovered in-window via Round-3.5.5 v2 Rule 3.
#
# Regex style is intentionally divergent from Pattern 2: literal whitespace
# (not \s+) because WritableManifest error text is statically emitted by
# dbt-core. Pattern notes in fbin_error_catalog.yml document the rationale.
# ===========================================================================


class TestPattern3Pattern:
    """Catalog-side assertions for Pattern 3: structure, provenance, Mut9d."""

    def _pattern(self):
        for p in load_catalog():
            if p.pattern_id == "manifest_parse_failure_invalid_model_language_v1":
                return p
        pytest.fail(
            "Pattern manifest_parse_failure_invalid_model_language_v1 "
            "missing from shipped catalog"
        )

    def test_classification_is_compile_error(self):
        # Manifest parse fails at static-compile boundary; NOT test_failure.
        # Iron Rule does not apply, but explicit assertion prevents future
        # drift to test_failure (which would over-restrict the action set).
        assert self._pattern().classification == Classification.COMPILE_ERROR

    def test_suggested_action_is_escalate_to_human(self):
        # Fix is dbt-datavault package upgrade or dbt-core version pin,
        # not a code change in any model. Auto-retry would reproduce the
        # same WritableManifest rejection deterministically.
        assert self._pattern().suggested_action == SuggestedAction.ESCALATE_TO_HUMAN

    def test_auto_retry_eligible_is_false(self):
        # Deterministic failure mode; retry wastes compute and pollutes
        # Cloud history without any chance of success.
        assert self._pattern().auto_retry_eligible is False

    def test_root_cause_investigation_required_is_true(self):
        # Package compatibility decision needs human review: upgrade
        # dbt-datavault, pin dbt-core, or accept dbt-core regression.
        assert self._pattern().root_cause_investigation_required is True

    def test_provenance_cites_actual_run_id(self):
        # Mut7-shape (run_id=<N>) AND must cite the canonical fixture run.
        prov = self._pattern().provenance
        assert prov.source_type == "gate_d_evidence"
        assert prov.citation == "run_id=485821754"
        assert PATTERN3_POSITIVE_FIXTURE.exists()

    def test_signal_sources_cites_logs_field(self):
        # FIRST pattern using `logs` since BLOCK lift. Lock the choice so
        # accidental drift to truncated_debug_logs (which doesn't contain
        # the manifest-parse signature in these payloads) breaks CI.
        srcs = self._pattern().signal_sources
        assert srcs == ("logs",)
        for s in srcs:
            assert s in REGEX_ELIGIBLE_FIELDS

    def test_max_bytes_equals_logs_max_bytes_cap(self):
        # Mut9d enforces max_bytes ∈ [1, LOGS_MAX_BYTES] for logs-citing
        # patterns at catalog-load. Locking the exact value here proves
        # the pattern uses the FULL truncator cap (smaller values would
        # silently shrink the match window).
        assert self._pattern().max_bytes == LOGS_MAX_BYTES

    def test_match_logic_has_two_required_clauses(self):
        # Clause 1 (Encountered an error:) is the truncator's selected
        # anchor and guarantees the regex hits the head-window output.
        # Clause 2 (WritableManifest signature) isolates this mode from
        # other 'Encountered an error:' modes.
        p = self._pattern()
        assert p.match_logic_type == "regex_and_substring"
        assert len(p.match_clauses) == 2

    def test_match_clauses_use_case_sensitive_flag(self):
        # WritableManifest is a dbt-core class name with a specific case;
        # case_insensitive would risk matching unrelated text containing
        # the lowercase tokens. Lock case_sensitive choice.
        for clause in self._pattern().match_clauses:
            assert clause.flags == "case_sensitive", (
                f"Pattern 3 clause field={clause.field!r} uses {clause.flags!r}; "
                "must be case_sensitive (dbt-core class name)"
            )


class TestPattern3Matcher:
    """End-to-end matcher contract using real Round-3.5.5-truncated fixtures."""

    def _matcher(self):
        return PatternMatcher(load_catalog())

    # NOTE: the legacy `test_positive_fixture_loads_clean` was removed in
    # the 2026-06-11 v1.1.0 fixture re-emission. It asserted on metadata
    # fields (`truncate_strategy`, `truncated_logs_bytes`, `raw_logs_bytes`,
    # `redactions_applied`) that the redactor pipeline no longer emits, and
    # — more importantly — it was a static assertion about a JSON file
    # produced once at fixture-creation time and frozen. The pattern would
    # silently stop firing on real payloads while every other test still
    # passed.
    #
    # The load-bearing truncator-to-pattern contract is now carried by
    # TestPattern3TruncatorMatcherContract::test_truncator_rule3_head_window_output_satisfies_pattern_3_regex
    # below, which runs the LIVE truncate_logs v2 algorithm on synthetic
    # >LOGS_MAX_BYTES input and matches the truncator output against the
    # pattern. That test catches drift in either the truncator OR the
    # regex; the deleted frozen-fixture test caught neither.

    def test_positive_fixture_matches_pattern_3(self):
        body = _json.loads(PATTERN3_POSITIVE_FIXTURE.read_text())
        payload = {"logs": _extract_error_step_field(body, "logs")}
        matches = self._matcher().match_all(payload)
        ids = [m.pattern_id for m in matches]
        assert "manifest_parse_failure_invalid_model_language_v1" in ids

    def test_positive_fixture_match_returns_full_metadata(self):
        body = _json.loads(PATTERN3_POSITIVE_FIXTURE.read_text())
        payload = {"logs": _extract_error_step_field(body, "logs")}
        match = next(
            (
                m for m in self._matcher().match_all(payload)
                if m.pattern_id == "manifest_parse_failure_invalid_model_language_v1"
            ),
            None,
        )
        assert match is not None
        assert match.classification == Classification.COMPILE_ERROR
        assert match.suggested_action == SuggestedAction.ESCALATE_TO_HUMAN
        assert match.confidence_baseline == 0.95
        assert match.auto_retry_eligible is False
        assert match.root_cause_investigation_required is True
        assert match.provenance.citation == "run_id=485821754"

    def test_regex_matches_signature_variant_different_timestamp(self):
        # Regex-robustness: matches the signature when timestamp differs
        # from the canonical fixture's. Hand-constructed payload using
        # literal text fragments observed in the P0.1 corpus dump.
        # NOT a separate-run confirmation — see provenance notes for
        # the actual multi-incident evidence statement.
        payload = {"logs": PATTERN3_SIGNATURE_VARIANT_DIFFERENT_TIMESTAMP}
        matches = self._matcher().match_all(payload)
        ids = [m.pattern_id for m in matches]
        assert "manifest_parse_failure_invalid_model_language_v1" in ids

    def test_regex_matches_signature_variant_different_macro_name(self):
        # Regex-robustness: matches when the OFFENDING macro name varies.
        # P0.1 corpus dump showed multiple macros (test_accepted_values,
        # apply_object_tags, others) appearing in the failure dict; the
        # regex must match REGARDLESS of which macro happens to be cited
        # first. NOT a separate-run confirmation.
        payload = {"logs": PATTERN3_SIGNATURE_VARIANT_DIFFERENT_MACRO_NAME}
        matches = self._matcher().match_all(payload)
        ids = [m.pattern_id for m in matches]
        assert "manifest_parse_failure_invalid_model_language_v1" in ids

    def test_pattern2_negative_fixture_does_NOT_match_pattern_3(self):
        # Cross-pattern isolation. Pattern 2's negative fixture
        # (485851058 manifest parse, ONLY truncated_debug_logs field)
        # must NOT match Pattern 3 either, because Pattern 3 reads
        # `logs`, which is absent from this fixture.
        body = _json.loads(NEGATIVE_FIXTURE.read_text())
        payload = {"truncated_debug_logs": _extract_error_step_field(body, "truncated_debug_logs")}
        matches = self._matcher().match_all(payload)
        ids = [m.pattern_id for m in matches]
        assert "manifest_parse_failure_invalid_model_language_v1" not in ids

    def test_pattern2_positive_fixture_does_NOT_match_pattern_3(self):
        # Cross-pattern isolation. Pattern 2's positive payload (PR
        # schema missing object) must NOT trigger Pattern 3 — different
        # error mode, different signature.
        body = _json.loads(POSITIVE_FIXTURE.read_text())
        payload = {"truncated_debug_logs": _extract_error_step_field(body, "truncated_debug_logs")}
        matches = self._matcher().match_all(payload)
        ids = [m.pattern_id for m in matches]
        assert "manifest_parse_failure_invalid_model_language_v1" not in ids

    def test_anchor_alone_does_NOT_match(self):
        # Clause 1 alone ('Encountered an error:') is a generic dbt
        # banner. Without the WritableManifest signature, the pattern
        # must NOT fire — Iron-Rule-equivalent for compile_error:
        # a generic banner is not diagnostic.
        payload = {
            "logs": (
                "08:00:00  Encountered an error:\n"
                "Some other error that has nothing to do with manifest parsing"
            )
        }
        matches = self._matcher().match_all(payload)
        ids = [m.pattern_id for m in matches]
        assert "manifest_parse_failure_invalid_model_language_v1" not in ids

    def test_signature_alone_in_wrong_field_does_NOT_match(self):
        # If the WritableManifest signature appears in `truncated_debug_logs`
        # rather than `logs`, Pattern 3 must NOT match — Mut4 enforces
        # field-level isolation; this test proves it at the matcher boundary.
        payload = {
            "truncated_debug_logs": (
                "08:11:01  Encountered an error:\n"
                'Field "macros" of type Mapping[str, Macro] in WritableManifest '
                "has invalid value {...}"
            )
        }
        matches = self._matcher().match_all(payload)
        ids = [m.pattern_id for m in matches]
        assert "manifest_parse_failure_invalid_model_language_v1" not in ids

    def test_case_sensitivity_drift_detector(self):
        # Pattern 3 uses case_sensitive flags. Lower-cased 'writablemanifest'
        # must NOT match — this acts as a drift detector if dbt-core ever
        # changes class-name casing in the error formatter.
        payload = {
            "logs": (
                "08:11:01  encountered an error:\n"  # also lowercase
                'field "macros" of type mapping[str, macro] in writablemanifest '
                "has invalid value {...}"
            )
        }
        matches = self._matcher().match_all(payload)
        ids = [m.pattern_id for m in matches]
        assert "manifest_parse_failure_invalid_model_language_v1" not in ids

    def test_does_not_match_pattern2(self):
        # Cross-pattern isolation: Pattern 3's positive payload must NOT
        # also match Pattern 2 (different signal_sources field). Mut4
        # field-isolation enforced at the matcher boundary.
        body = _json.loads(PATTERN3_POSITIVE_FIXTURE.read_text())
        payload = {"logs": _extract_error_step_field(body, "logs")}
        matches = self._matcher().match_all(payload)
        ids = [m.pattern_id for m in matches]
        assert "pr_isolated_schema_missing_upstream_v1" not in ids

    def test_does_not_match_fk_orphan_pattern(self):
        # Cross-pattern isolation against Pattern 1 (test_failure).
        body = _json.loads(PATTERN3_POSITIVE_FIXTURE.read_text())
        payload = {"logs": _extract_error_step_field(body, "logs")}
        matches = self._matcher().match_all(payload)
        ids = [m.pattern_id for m in matches]
        assert "fk_orphan_detection_failure_v1" not in ids


class TestPattern3TruncatorMatcherContract:
    """End-to-end: synthetic >LOGS_MAX_BYTES log, run through the LIVE
    truncate_logs v2 algorithm, then matched. This is the contract that
    binds Pattern 3 to the Round-3.5.5 truncator algorithm — it catches
    drift in EITHER the truncator (e.g., someone removes
    'Encountered an error:' from ERROR_ANCHORS, or reorders priorities
    so a generic tail anchor wins again) OR the regex (e.g., someone
    introduces a literal-space mismatch).

    Without this test, the fixture-metadata assertions in
    TestPattern3Matcher are not a truncator contract — they're static
    assertions about a JSON file produced once at fixture-creation time
    and frozen. The pattern would silently stop firing on real payloads
    while every other test still passed.
    """

    def _matcher(self):
        return PatternMatcher(load_catalog())

    def test_truncator_rule3_head_window_output_satisfies_pattern_3_regex(self):
        from scripts.automation.src.triage.redact import truncate_logs

        # Realistic head segment with both Pattern 3 regex clauses present.
        head = (
            "11:04:14  Encountered an error:\n"
            'Field "macros" of type Mapping[str, Macro] in WritableManifest '
            "has invalid value {'macro.dbt_datavault.test_accepted_values': "
            "{'name': 'test_accepted_values', 'resource_type': 'macro', "
            "'package_name': 'dbt_datavault'}}\n"
        )
        # Pad with realistic-looking tail content so total > LOGS_MAX_BYTES,
        # AND include a generic "failed with N errors" line in the tail to
        # prove Rule 3 head-window selection wins over generic anchors at
        # the tail of the log.
        tail_decoy = ("Failed with 1 errors\n" * 5000)  # ~95 KB
        raw_log = head + tail_decoy
        assert len(raw_log) > LOGS_MAX_BYTES, "test setup must trigger truncation"

        truncated, strategy = truncate_logs(raw_log)
        # Strategy contract: Rule 3 selected the head-window for our anchor.
        assert strategy == "head:Encountered an error:", (
            f"Expected Rule 3 head-window selection, got {strategy!r}. "
            "ERROR_ANCHORS reordering or anchor removal would break this; "
            "Pattern 3 would silently stop matching production payloads."
        )
        # Output size contract: hybrid-truncated to the cap.
        assert len(truncated) == LOGS_MAX_BYTES

        # Matcher contract: truncated output still satisfies BOTH Pattern 3
        # clauses. This is the load-bearing assertion — it binds the
        # pattern to the truncator's output, not to a frozen JSON file.
        matches = self._matcher().match_all({"logs": truncated})
        ids = [m.pattern_id for m in matches]
        assert "manifest_parse_failure_invalid_model_language_v1" in ids

    def test_truncator_short_log_noop_path_also_satisfies_pattern_3(self):
        from scripts.automation.src.triage.redact import truncate_logs

        # Short log path (under SHORT_LOG_THRESHOLD): the truncator returns
        # the log unchanged with strategy='noop:short'. Pattern 3 must
        # still match — proves the pattern is not coupled to a specific
        # truncation outcome, only to the field-content contract.
        short_log = (
            "08:00:00  Encountered an error:\n"
            'Field "macros" of type Mapping[str, Macro] in WritableManifest '
            "has invalid value {'macro.x': {}}\n"
        )
        truncated, strategy = truncate_logs(short_log)
        assert strategy == "noop:short"
        assert truncated == short_log

        matches = self._matcher().match_all({"logs": truncated})
        ids = [m.pattern_id for m in matches]
        assert "manifest_parse_failure_invalid_model_language_v1" in ids


