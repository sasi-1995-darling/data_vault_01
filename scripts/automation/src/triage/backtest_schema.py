"""Label schema + payload loaders for the backtest harness.

Split from `backtest.py` (Day-6 commit, post-DA review) to honor the
~250-line surface cap. This module owns the WHAT (data shapes + file
loading + path defenses). Scoring lives in `backtest_scoring.py`.
Aggregation + driver live in `backtest.py`.

Boundary contract
-----------------
* `LabelSet.model_validate(yaml_dict)` is the only sanctioned way to
  construct a label set — it enforces uniqueness, version pinning,
  and per-case invariants.
* `resolve_payload_path` is the only sanctioned way to turn a label
  entry into an on-disk path; it enforces the two allowlists
  (repo_root for fixtures, ~/scratch/ for scratch) per DA P0-2.
* `load_raw_payload` returns None for missing files so clean-clone CI
  can exercise the report path without scratch corpora present.
"""

from __future__ import annotations

from pathlib import Path
from typing import Optional

import yaml
from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from scripts.automation.src.triage.fixture_loader import load_fixture
from scripts.automation.src.triage.rca_schema import Outcome


LABEL_SCHEMA_VERSION = "v1.1.0"
# v1.0.0 → v1.1.0 (2026-06-11): repointed all 7 P0.1 labels from
# `payload_source: scratch` to `payload_source: fixture`, replacing
# `~/scratch/triage-day4/run_<id>_cluster_<X>.json` paths with the
# committed pipeline-emitted equivalents under
# `docs/triage-agent/fixtures/`. The on-disk shape of the 4 historically
# hand-sanitized fixtures (487333396, 485851058, 485821754, 486060143)
# was re-emitted through `redactor_pipeline.py --all` so all 7 carry the
# uniform 3-key envelope (`_fixture_metadata`, `data`, `status`) with the
# v1.0.0 redact-schema 8-field metadata. Activates the fixture branch of
# `resolve_payload_path` (was dead code prior to this bump) and the
# L173-181 traversal-defense `is_relative_to` check that gates it.

# Reserved sentinel for the no-match aggregation bucket in per-pattern
# metrics. Labels MUST NOT name a real pattern "UNKNOWN" — it would
# double-count with the synthetic bucket (P2-2 from Day-6 DA review).
RESERVED_BUCKET_PATTERN_ID = "UNKNOWN"


# ---------------------------------------------------------------------------
# Pydantic models
# ---------------------------------------------------------------------------


class LabelProvenance(BaseModel):
    """Per-entry provenance — explains WHY the expected values are these.

    Reviewers can audit empirically-grounded vs category-confirmed vs
    no-pattern-applicable labels by reading these fields directly.
    """

    model_config = ConfigDict(extra="forbid", frozen=True)

    cluster_source: str = Field(min_length=1, max_length=400)
    pattern_source: str = Field(min_length=1, max_length=400)
    derivation: str = Field(min_length=1, max_length=400)


class LabeledCase(BaseModel):
    """One P0.1 ground-truth label."""

    model_config = ConfigDict(extra="forbid", frozen=True)

    run_id: int = Field(gt=0)
    cluster: str = Field(pattern=r"^[A-Z]$")
    expected_pattern_id: Optional[str] = Field(default=None, max_length=120)
    expected_outcome: Outcome
    payload_source: str = Field(pattern=r"^(scratch|fixture)$")
    payload_path: str = Field(min_length=1)
    payload_shape: str = Field(pattern=r"^(raw|flat)$")
    provenance: LabelProvenance
    notes: str = Field(default="", max_length=400)

    @field_validator("expected_pattern_id")
    @classmethod
    def _reject_reserved_bucket_name(cls, value: Optional[str]) -> Optional[str]:
        # P2-2 from Day-6 DA: a label literally named "UNKNOWN" would
        # collide with the synthetic no-match bucket in per-pattern
        # metrics aggregation and double-count.
        if value == RESERVED_BUCKET_PATTERN_ID:
            raise ValueError(
                f"expected_pattern_id must not be {RESERVED_BUCKET_PATTERN_ID!r} "
                "— reserved for the no-match aggregation bucket"
            )
        return value

    @model_validator(mode="after")
    def _enforce_label_invariants(self) -> "LabeledCase":
        # If the label says UNKNOWN, expected_pattern_id MUST be absent.
        # If CLASSIFIED, expected_pattern_id is REQUIRED — otherwise the
        # case is unscoreable (the harness would not know what to match).
        if self.expected_outcome == Outcome.CLASSIFIED:
            if not self.expected_pattern_id:
                raise ValueError(
                    f"run_id={self.run_id}: expected_pattern_id is required "
                    "when expected_outcome=CLASSIFIED"
                )
        elif self.expected_outcome == Outcome.UNKNOWN_HANDED_TO_HUMAN:
            if self.expected_pattern_id is not None:
                raise ValueError(
                    f"run_id={self.run_id}: expected_pattern_id must be null "
                    "when expected_outcome=UNKNOWN_HANDED_TO_HUMAN"
                )
        # Other outcomes (CREDENTIAL_SENTINEL_FIRED, CIRCUIT_OPEN) are
        # intentionally not labellable in Phase 1 — they require dedicated
        # corpus work (sentinel test payloads, circuit-open injection).
        else:
            raise ValueError(
                f"run_id={self.run_id}: expected_outcome={self.expected_outcome} "
                "is not labellable in Phase-1 corpus"
            )
        return self


class LabelSet(BaseModel):
    """Top-level label-file schema."""

    model_config = ConfigDict(extra="forbid", frozen=True)

    version: str
    generated_at_utc: str
    notes: str = Field(default="", max_length=2000)
    labels: list[LabeledCase]

    @field_validator("version")
    @classmethod
    def _pin_version(cls, value: str) -> str:
        if value != LABEL_SCHEMA_VERSION:
            raise ValueError(
                f"label schema version must be {LABEL_SCHEMA_VERSION!r}, "
                f"got {value!r} — bump LABEL_SCHEMA_VERSION + add migration "
                "shim if the entry shape changed"
            )
        return value

    @model_validator(mode="after")
    def _unique_run_ids(self) -> "LabelSet":
        seen: set[int] = set()
        for case in self.labels:
            if case.run_id in seen:
                raise ValueError(f"duplicate run_id in labels: {case.run_id}")
            seen.add(case.run_id)
        return self


# ---------------------------------------------------------------------------
# Loaders
# ---------------------------------------------------------------------------


def load_labels(label_path: Path) -> LabelSet:
    """Load and validate the label file. Raises on any schema violation."""
    raw = yaml.safe_load(label_path.read_text())
    if not isinstance(raw, dict):
        raise ValueError(f"label file {label_path} must be a YAML mapping")
    return LabelSet.model_validate(raw)


def resolve_payload_path(case: LabeledCase, repo_root: Path) -> Path:
    """Resolve label.payload_path to an absolute Path with traversal defense.

    P0-2 from Day-6 DA: a malicious or mistaken label entry could request
    payloads outside the intended directories (`docs/triage-agent/` for
    fixtures, `~/scratch/` for scratch). The harness's rendered baseline
    is an audit artifact — leaking arbitrary file contents into rationale
    excerpts is a real concern.

    Fixture branch: resolve against repo_root and assert the result stays
    inside repo_root.
    Scratch branch: expand `~`, resolve, and assert the result stays inside
    `~/scratch/` (the only allowlist-authorized scratch root).
    """
    if case.payload_source == "fixture":
        candidate = (repo_root / case.payload_path).resolve()
        repo_root_resolved = repo_root.resolve()
        if not candidate.is_relative_to(repo_root_resolved):
            raise ValueError(
                f"run_id={case.run_id}: fixture payload_path "
                f"{case.payload_path!r} escapes repo_root"
            )
        return candidate
    if case.payload_source == "scratch":
        candidate = Path(case.payload_path).expanduser().resolve()
        scratch_root = (Path.home() / "scratch").resolve()
        if not candidate.is_relative_to(scratch_root):
            raise ValueError(
                f"run_id={case.run_id}: scratch payload_path "
                f"{case.payload_path!r} escapes ~/scratch/"
            )
        return candidate
    raise ValueError(  # pragma: no cover (caught by Pydantic pattern)
        f"unknown payload_source: {case.payload_source}"
    )


def load_raw_payload(payload_path: Path) -> Optional[dict]:
    """Load a raw dbt Cloud payload from disk. Returns None if missing.

    None signals SKIPPED_PAYLOAD_MISSING — the harness does NOT fail-loud
    here so clean-clone CI environments without scratch corpora can still
    exercise the report-generation path.

    Delegates to `fixture_loader.load_fixture` so the single chokepoint
    explicitly strips `_fixture_metadata` from committed fixtures (the
    `fixture` branch of `resolve_payload_path`) while remaining a no-op
    on scratch raws (the `scratch` branch — raws never carry the
    envelope wrapper). Retires the G7-1 dispatcher-drop reliance Kumar
    flagged in D4 review 2026-06-11.

    The `Optional[dict]` return type is honest because `load_fixture`
    enforces a JSON-object root (raises `TypeError` on non-dict);
    propagating a non-dict through this function's typed return is
    therefore impossible by construction at HEAD (PR #1821 Commit 6,
    R4 finding N1/N2).
    """
    if not payload_path.exists():
        return None
    return load_fixture(payload_path)
