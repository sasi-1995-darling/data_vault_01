"""FBIN error catalog loader + pattern matcher — v1.0.0.

Single source of truth for catalog access is the YAML at
``scripts/automation/configs/fbin_error_catalog.yml``. This module loads,
validates, and matches against that catalog.

Architecture (LOCKED — do not relax without amending catalog YAML header):

  1. **Closed-by-default loader.** Every pattern is cross-validated against
     ``rca_schema.Classification``, ``rca_schema.SuggestedAction``,
     ``redact.REGEX_ELIGIBLE_FIELDS``, and the local
     ``SUPPORTED_MATCH_LOGIC_TYPES`` set. A pattern that fails any check
     causes ``load_catalog`` to raise — no fallback, no partial accept.

  2. **YAML is the only source of patterns.** There are no inline pattern
     defaults in this module. Removing the YAML file is an immediate
     ``FileNotFoundError`` — never silent degradation to a built-in.

  3. **Iron Rule enforced at load time** (defense in depth):
        Mut3a: classification=test_failure ⟹ root_cause_investigation_required=True
        Mut3b: classification=test_failure ⟹ suggested_action ≠ MODIFY_TEST
     Mut3b is also enforced by ``rca_schema.RCARecord._enforce_invariants``
     Rule 2. Catching it here blocks misconfiguration before record
     construction; the redundancy is intentional.

  4. **PatternMatch is frozen and forward-compatible with RCARecord.**
     ``classification`` is the enum value (consumable by
     ``RCARecord.classification`` directly), ``suggested_action`` is the
     enum value, ``pattern_id`` is the stable FK for
     ``TRIAGE_INVOCATIONS.pattern_match_id``.

The eight invariants enforced here each have a dedicated mutation test in
``tests/test_triage_catalog.py``:

  Mut1  — duplicate pattern_id
  Mut2  — invalid classification value
  Mut3a — Iron Rule investigation flag missing on test_failure
  Mut3b — Iron Rule MODIFY_TEST forbidden on test_failure
  Mut4  — signal_source not in REGEX_ELIGIBLE_FIELDS
  Mut5  — match_logic.type not in SUPPORTED_MATCH_LOGIC_TYPES
  Mut6  — provenance.source_type not in SUPPORTED_PROVENANCE_SOURCE_TYPES
  Mut7  — provenance.citation does not match per-source-type regex
  Mut9d — pattern citing `logs` lacks ``max_bytes`` or declares it out of range
          [1, LOGS_MAX_BYTES]  (Day 3.8, Sprint-1 #12)
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Optional

import yaml

from scripts.automation.src.triage.rca_schema import (
    Classification,
    SuggestedAction,
)
from scripts.automation.src.triage.redact import (
    LOGS_MAX_BYTES,
    REGEX_ELIGIBLE_FIELDS,
)


CATALOG_SCHEMA_VERSION = "v1.2.0"
# v1.1.0 → v1.2.0 (backwards-compatible, additive): patterns that cite
# the `logs` signal MUST declare an integer ``max_bytes ∈ [1, LOGS_MAX_BYTES]``.
# Patterns NOT citing `logs` are unaffected. The new gate is Mut9d and
# defeats two failure modes: (a) silent buffer-overrun risk if the
# matcher reads from `logs` without a self-declared cap; (b) always-false
# matchers when max_bytes exceeds the redactor's hybrid-truncation cap.
# Source: docs/triage-agent/gate-d-logs-field-amendment.md §5 (Mut9d row).

# Supported match_logic.type values. Strict enum: adding a new match type
# requires a deliberate catalog schema version bump (see YAML header).
SUPPORTED_MATCH_LOGIC_TYPES = frozenset({"regex_and_substring"})

# Supported provenance source_type values + per-type citation regex.
# Ships ONLY the two types in active use (lessons_md, gate_d_evidence).
# `pr_retrospective` and `synthetic` deliberately NOT shipped — adding
# them requires a real catalog pattern that needs them plus a schema bump.
# The `synthetic` escape hatch in particular is withheld to prevent
# future authors from masquerading speculation as evidence (cf. Day 3
# ChatGPT-preview-list incident).
PROVENANCE_SOURCE_CITATION_REGEX: dict[str, str] = {
    "lessons_md": r"^lesson #\d+$",
    "gate_d_evidence": r"^run_id=\d+$",
}
SUPPORTED_PROVENANCE_SOURCE_TYPES = frozenset(PROVENANCE_SOURCE_CITATION_REGEX.keys())

# Default catalog path resolved from repo root via this file's location.
DEFAULT_CATALOG_PATH = (
    Path(__file__).resolve().parents[2] / "configs" / "fbin_error_catalog.yml"
)

# Required top-level keys per pattern (presence-only check; values are
# validated separately). `provenance` replaces v1.0.0's `lessons_md_ref`.
REQUIRED_PATTERN_KEYS = frozenset({
    "pattern_id",
    "classification",
    "sub_class",
    "signal_sources",
    "match_logic",
    "confidence_baseline",
    "suggested_action",
    "root_cause_investigation_required",
    "auto_retry_eligible",
    "provenance",
    "notes",
})

REQUIRED_PROVENANCE_KEYS = frozenset({"source_type", "citation"})


class CatalogValidationError(ValueError):
    """Raised when the loaded catalog violates a structural invariant."""


@dataclass(frozen=True)
class MatchClause:
    """One sub-clause of a regex_and_substring match_logic block."""

    field: str
    pattern: str
    flags: str  # "case_insensitive" | "case_sensitive"


@dataclass(frozen=True)
class Provenance:
    """Structured provenance — defeats provenance laundering.

    `source_type` MUST be in SUPPORTED_PROVENANCE_SOURCE_TYPES.
    `citation` MUST match PROVENANCE_SOURCE_CITATION_REGEX[source_type].
    `notes` is free-form context that surfaces in RCA rationale.
    """

    source_type: str
    citation: str
    notes: str = ""


@dataclass(frozen=True)
class Pattern:
    """A single catalog pattern. Frozen to prevent post-load mutation."""

    pattern_id: str
    classification: Classification
    sub_class: str
    signal_sources: tuple[str, ...]
    match_logic_type: str
    match_clauses: tuple[MatchClause, ...]
    confidence_baseline: float
    suggested_action: SuggestedAction
    root_cause_investigation_required: bool
    auto_retry_eligible: bool
    provenance: Provenance
    notes: str
    # Day 3.8 (Sprint-1 #12): patterns citing the `logs` signal MUST
    # declare an integer ``max_bytes ∈ [1, LOGS_MAX_BYTES]`` (Mut9d).
    # Patterns NOT citing `logs` carry ``max_bytes=None``.
    max_bytes: Optional[int] = None


@dataclass(frozen=True)
class PatternMatch:
    """Forward-compatible with rca_schema.RCARecord field shapes."""

    pattern_id: str
    classification: Classification
    sub_class: str
    confidence_baseline: float
    suggested_action: SuggestedAction
    root_cause_investigation_required: bool
    auto_retry_eligible: bool
    provenance: Provenance


# ---------------------------------------------------------------------------
# Loading + validation
# ---------------------------------------------------------------------------

def load_catalog(path: Optional[Path] = None) -> tuple[Pattern, ...]:
    """Load + validate the catalog YAML. Raises on any invariant violation."""
    catalog_path = path or DEFAULT_CATALOG_PATH
    if not catalog_path.exists():
        raise FileNotFoundError(f"catalog YAML not found at {catalog_path!s}")

    with catalog_path.open("r") as handle:
        raw = yaml.safe_load(handle)

    if not isinstance(raw, dict):
        raise CatalogValidationError("catalog root must be a mapping")

    version = raw.get("catalog_schema_version")
    if version != CATALOG_SCHEMA_VERSION:
        raise CatalogValidationError(
            f"catalog_schema_version must be {CATALOG_SCHEMA_VERSION!r}, "
            f"got {version!r}"
        )

    patterns_raw = raw.get("patterns")
    if not isinstance(patterns_raw, list) or not patterns_raw:
        raise CatalogValidationError("catalog must contain a non-empty 'patterns' list")

    patterns: list[Pattern] = []
    seen_ids: set[str] = set()
    for idx, entry in enumerate(patterns_raw):
        pattern = _validate_pattern(entry, idx)
        if pattern.pattern_id in seen_ids:
            raise CatalogValidationError(
                f"duplicate pattern_id {pattern.pattern_id!r} (Mut1)"
            )
        seen_ids.add(pattern.pattern_id)
        patterns.append(pattern)

    return tuple(patterns)


def _validate_pattern(entry: Any, idx: int) -> Pattern:
    """Validate one pattern entry. Each check maps to a documented mutation."""
    if not isinstance(entry, dict):
        raise CatalogValidationError(f"pattern #{idx} must be a mapping")

    missing = REQUIRED_PATTERN_KEYS - entry.keys()
    if missing:
        raise CatalogValidationError(
            f"pattern #{idx} missing required keys: {sorted(missing)}"
        )

    # Mut2: classification cross-validated against rca_schema enum.
    try:
        classification = Classification(entry["classification"])
    except ValueError as exc:
        raise CatalogValidationError(
            f"pattern #{idx} classification {entry['classification']!r} "
            f"not in rca_schema.Classification (Mut2)"
        ) from exc

    # suggested_action cross-validated against rca_schema enum.
    try:
        suggested_action = SuggestedAction(entry["suggested_action"])
    except ValueError as exc:
        raise CatalogValidationError(
            f"pattern #{idx} suggested_action {entry['suggested_action']!r} "
            f"not in rca_schema.SuggestedAction"
        ) from exc

    # Iron Rule (Mut3a + Mut3b): test_failure patterns have two coupled
    # constraints. Mut3b duplicates rca_schema Rule 2 by design — defense
    # in depth at catalog-load time.
    if classification == Classification.TEST_FAILURE:
        if entry["root_cause_investigation_required"] is not True:
            raise CatalogValidationError(
                f"pattern #{idx} ({entry['pattern_id']!r}) Iron Rule: "
                f"test_failure requires root_cause_investigation_required=true (Mut3a)"
            )
        if suggested_action == SuggestedAction.MODIFY_TEST:
            raise CatalogValidationError(
                f"pattern #{idx} ({entry['pattern_id']!r}) Iron Rule: "
                f"suggested_action='modify_test' forbidden on test_failure (Mut3b)"
            )

    # Mut4: signal_sources cross-validated against redact eligibility set.
    signal_sources = entry["signal_sources"]
    if not isinstance(signal_sources, list) or not signal_sources:
        raise CatalogValidationError(
            f"pattern #{idx} signal_sources must be a non-empty list"
        )
    invalid_signals = [s for s in signal_sources if s not in REGEX_ELIGIBLE_FIELDS]
    if invalid_signals:
        raise CatalogValidationError(
            f"pattern #{idx} signal_sources {invalid_signals!r} not in "
            f"redact.REGEX_ELIGIBLE_FIELDS (Mut4)"
        )

    # Mut9d: patterns citing the `logs` signal MUST declare an integer
    # ``max_bytes`` in the range [1, LOGS_MAX_BYTES]. Three sub-failures
    # are caught here (each is a separate test):
    #   Mut9d.1: max_bytes missing entirely
    #   Mut9d.2: max_bytes <= 0 (including bool False, which is `int(0)`)
    #   Mut9d.3: max_bytes > LOGS_MAX_BYTES (unreachable matcher)
    # Patterns NOT citing `logs` may omit max_bytes; carried as None.
    max_bytes: Optional[int] = None
    if "logs" in signal_sources:
        raw_max = entry.get("max_bytes")
        # bool is a subclass of int in Python; reject it explicitly.
        if (
            not isinstance(raw_max, int)
            or isinstance(raw_max, bool)
            or raw_max < 1
            or raw_max > LOGS_MAX_BYTES
        ):
            raise CatalogValidationError(
                f"pattern #{idx} ({entry['pattern_id']!r}) signal_sources "
                f"includes 'logs' but max_bytes ({raw_max!r}) is not an "
                f"integer in [1, {LOGS_MAX_BYTES}] (Mut9d)"
            )
        max_bytes = raw_max

    # Mut5: match_logic.type cross-validated against supported set.
    match_logic = entry["match_logic"]
    if not isinstance(match_logic, dict):
        raise CatalogValidationError(f"pattern #{idx} match_logic must be a mapping")
    mtype = match_logic.get("type")
    if mtype not in SUPPORTED_MATCH_LOGIC_TYPES:
        raise CatalogValidationError(
            f"pattern #{idx} match_logic.type {mtype!r} not in "
            f"SUPPORTED_MATCH_LOGIC_TYPES (Mut5)"
        )

    clauses = _validate_match_clauses(match_logic.get("requires_all"), idx)

    confidence = entry["confidence_baseline"]
    if not isinstance(confidence, (int, float)) or not 0.0 <= confidence <= 1.0:
        raise CatalogValidationError(
            f"pattern #{idx} confidence_baseline must be in [0.0, 1.0]"
        )

    provenance = _validate_provenance(entry["provenance"], idx, entry["pattern_id"])

    return Pattern(
        pattern_id=entry["pattern_id"],
        classification=classification,
        sub_class=entry["sub_class"],
        signal_sources=tuple(signal_sources),
        match_logic_type=mtype,
        match_clauses=clauses,
        confidence_baseline=float(confidence),
        suggested_action=suggested_action,
        root_cause_investigation_required=bool(entry["root_cause_investigation_required"]),
        auto_retry_eligible=bool(entry["auto_retry_eligible"]),
        provenance=provenance,
        notes=entry["notes"],
        max_bytes=max_bytes,
    )


def _validate_provenance(raw: Any, idx: int, pattern_id: str) -> Provenance:
    """Validate the provenance block. Two coupled checks:

    * Mut6: source_type ∈ SUPPORTED_PROVENANCE_SOURCE_TYPES
    * Mut7: citation matches the per-source-type regex

    Together these defeat provenance laundering — a pattern cannot be
    accepted unless it cites a real provenance source AND the citation
    is shaped like a real reference of that type.
    """
    if not isinstance(raw, dict):
        raise CatalogValidationError(
            f"pattern #{idx} ({pattern_id!r}) provenance must be a mapping"
        )
    missing = REQUIRED_PROVENANCE_KEYS - raw.keys()
    if missing:
        raise CatalogValidationError(
            f"pattern #{idx} ({pattern_id!r}) provenance missing keys: {sorted(missing)}"
        )
    source_type = raw["source_type"]
    if source_type not in SUPPORTED_PROVENANCE_SOURCE_TYPES:
        raise CatalogValidationError(
            f"pattern #{idx} ({pattern_id!r}) provenance.source_type {source_type!r} "
            f"not in SUPPORTED_PROVENANCE_SOURCE_TYPES (Mut6)"
        )
    citation = raw["citation"]
    if not isinstance(citation, str):
        raise CatalogValidationError(
            f"pattern #{idx} ({pattern_id!r}) provenance.citation must be a string"
        )
    expected_regex = PROVENANCE_SOURCE_CITATION_REGEX[source_type]
    if not re.fullmatch(expected_regex, citation):
        raise CatalogValidationError(
            f"pattern #{idx} ({pattern_id!r}) provenance.citation {citation!r} "
            f"does not match {source_type!r} format {expected_regex!r} (Mut7)"
        )
    notes = raw.get("notes", "")
    if not isinstance(notes, str):
        raise CatalogValidationError(
            f"pattern #{idx} ({pattern_id!r}) provenance.notes must be a string"
        )
    return Provenance(source_type=source_type, citation=citation, notes=notes)


def _validate_match_clauses(requires_all: Any, idx: int) -> tuple[MatchClause, ...]:
    """Validate a regex_and_substring requires_all block."""
    if not isinstance(requires_all, list) or not requires_all:
        raise CatalogValidationError(
            f"pattern #{idx} match_logic.requires_all must be a non-empty list"
        )
    clauses: list[MatchClause] = []
    for clause_idx, raw in enumerate(requires_all):
        if not isinstance(raw, dict):
            raise CatalogValidationError(
                f"pattern #{idx} clause #{clause_idx} must be a mapping"
            )
        for key in ("field", "pattern", "flags"):
            if key not in raw:
                raise CatalogValidationError(
                    f"pattern #{idx} clause #{clause_idx} missing {key!r}"
                )
        if raw["flags"] not in ("case_insensitive", "case_sensitive"):
            raise CatalogValidationError(
                f"pattern #{idx} clause #{clause_idx} flags must be "
                f"'case_insensitive' or 'case_sensitive'"
            )
        if raw["field"] not in REGEX_ELIGIBLE_FIELDS:
            raise CatalogValidationError(
                f"pattern #{idx} clause #{clause_idx} field {raw['field']!r} "
                f"not in REGEX_ELIGIBLE_FIELDS (Mut4)"
            )
        try:
            re.compile(raw["pattern"])
        except re.error as exc:
            # R2 construction exemption: `raw["pattern"]` at this site
            # cannot carry payload-derived content because it originates
            # from the catalog YAML at `configs/fbin_error_catalog.yaml`,
            # which is developer-authored, loaded at import-time by
            # `load_catalog`, and never populated from runtime triage
            # input. `re.error.msg` therefore describes a developer-
            # authored regex token, not payload bytes.
            # Falsifiable: this exemption fails if `raw["pattern"]` ever
            # becomes derived from runtime input at this site.
            # See: docs/triage-agent/credential-threat-model.md
            # §Construction Exemption.
            raise CatalogValidationError(
                f"pattern #{idx} clause #{clause_idx} invalid regex: {exc}"
            ) from exc
        clauses.append(MatchClause(field=raw["field"], pattern=raw["pattern"], flags=raw["flags"]))
    return tuple(clauses)


# ---------------------------------------------------------------------------
# Matching
# ---------------------------------------------------------------------------

class PatternMatcher:
    """Match redacted payloads against the loaded catalog."""

    def __init__(self, patterns: tuple[Pattern, ...]) -> None:
        self._patterns = patterns

    def match(self, redacted_payload: dict[str, Any]) -> Optional[PatternMatch]:
        """Return the first matching pattern, or None."""
        for pattern in self._patterns:
            if self._evaluate(pattern, redacted_payload):
                return _to_match(pattern)
        return None

    def match_all(self, redacted_payload: dict[str, Any]) -> list[PatternMatch]:
        """Return every matching pattern (may be empty)."""
        return [
            _to_match(p) for p in self._patterns
            if self._evaluate(p, redacted_payload)
        ]

    @staticmethod
    def _evaluate(pattern: Pattern, payload: dict[str, Any]) -> bool:
        """All clauses must match (AND semantics) for the pattern to fire."""
        for clause in pattern.match_clauses:
            value = payload.get(clause.field)
            if not isinstance(value, str):
                return False
            flags = re.IGNORECASE if clause.flags == "case_insensitive" else 0
            if not re.search(clause.pattern, value, flags):
                return False
        return True


def _to_match(pattern: Pattern) -> PatternMatch:
    return PatternMatch(
        pattern_id=pattern.pattern_id,
        classification=pattern.classification,
        sub_class=pattern.sub_class,
        confidence_baseline=pattern.confidence_baseline,
        suggested_action=pattern.suggested_action,
        root_cause_investigation_required=pattern.root_cause_investigation_required,
        auto_retry_eligible=pattern.auto_retry_eligible,
        provenance=pattern.provenance,
    )
