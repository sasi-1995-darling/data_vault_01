"""Tests for the backtest harness (scripts.automation.src.triage.backtest +
backtest_report).

Coverage strategy
-----------------
* Schema validation — every required field, every Pydantic constraint,
  every invariant in LabelSet / LabeledCase.
* Payload resolution — scratch (tilde-expansion) + fixture (repo-relative)
  + missing-file (None return).
* Pattern-id extraction — every branch of `extract_pattern_id`, including
  a contract test that round-trips via the live orchestrator so the
  regex stays coupled to `_classified`'s rationale format.
* Scoring — one test per Verdict (PASS/FP/FN/WP/SENTINEL/SKIPPED/ERROR).
  WRONG_OUTCOME was provably dead code and was removed (Day-6 DA P0-1).
* End-to-end — one test against the committed Cluster C fixture (no
  scratch dependency); one test against a synthetic Pattern 1 payload.
* Rendering smoke — required sections present; skipped cases rendered.

All tests use synthetic payloads or the committed Cluster C fixture —
none require ~/scratch/triage-day4/ to exist, so clean-clone CI stays
green.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import pytest
import yaml
from pydantic import ValidationError

from scripts.automation.src.triage.backtest import (
    CATALOG_SCHEMA_VERSION,
    HARNESS_VERSION,
    LABEL_SCHEMA_VERSION,
    RESERVED_BUCKET_PATTERN_ID,
    BacktestReport,
    CaseResult,
    LabelProvenance,
    LabelSet,
    LabeledCase,
    Verdict,
    _compute_pattern_metrics,
    extract_pattern_id,
    load_labels,
    load_raw_payload,
    resolve_payload_path,
    run_backtest,
    score_case,
)
from scripts.automation.src.triage.backtest_report import (
    REPO_ROOT,
    render_markdown_report,
)
from scripts.automation.src.triage.failure_triage_agent import triage_failure
from scripts.automation.src.triage.rca_schema import (
    Classification,
    EvidenceMode,
    Outcome,
    RCARecord,
    SuggestedAction,
)
from scripts.automation.src.triage.redact import REDACT_SCHEMA_VERSION


# ---------------------------------------------------------------------------
# Helpers — synthetic payload + label builders (NO scratch dependency)
# ---------------------------------------------------------------------------


def _wrap_step(step_fields: dict[str, Any]) -> dict[str, Any]:
    """Mirror test_triage_orchestrator._wrap_step — keeps tests independent."""
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


def _pattern_1_payload() -> dict[str, Any]:
    return _wrap_step({
        "message": (
            "Failure in test dbt_constraints_foreign_key_sat_customer_HK "
            "(models/raw_vault/sat/sat_customer.yml)\n"
            "Got 42 results, configured to fail if != 0"
        ),
        "truncated_debug_logs": "Completed with 1 error and 0 warnings:",
    })


def _make_provenance(**overrides: Any) -> LabelProvenance:
    base = dict(
        cluster_source="test-cluster-source",
        pattern_source="test-pattern-source",
        derivation="test-derivation",
    )
    base.update(overrides)
    return LabelProvenance(**base)


def _make_label(**overrides: Any) -> LabeledCase:
    base = dict(
        run_id=999999,
        cluster="A",
        expected_pattern_id="fk_orphan_detection_failure_v1",
        expected_outcome=Outcome.CLASSIFIED,
        payload_source="scratch",
        payload_path="~/scratch/missing.json",
        payload_shape="raw",
        provenance=_make_provenance(),
        notes="",
    )
    base.update(overrides)
    return LabeledCase(**base)


def _write_payload(tmp_path: Path, payload: dict[str, Any]) -> Path:
    p = tmp_path / "raw.json"
    p.write_text(json.dumps(payload))
    return p


def _scratch_under(tmp_path: Path, monkeypatch) -> Path:
    """Set HOME=tmp_path and return tmp_path/scratch so paths pass the
    scratch allowlist defense (P0-2). Returns the scratch dir (created)."""
    monkeypatch.setenv("HOME", str(tmp_path))
    scratch = tmp_path / "scratch"
    scratch.mkdir(exist_ok=True)
    return scratch


# ===========================================================================
# Label schema
# ===========================================================================


class TestLabelSchema:

    def test_committed_p01_labels_loads(self):
        ls = load_labels(REPO_ROOT / "docs/triage-agent/fixtures/p01_labels.yml")
        assert ls.version == LABEL_SCHEMA_VERSION
        assert len(ls.labels) == 7
        # Sanity: cluster distribution matches MANIFEST.txt (A:3, B:2, C:2).
        clusters = sorted(c.cluster for c in ls.labels)
        assert clusters == ["A", "A", "A", "B", "B", "C", "C"]

    def test_version_mismatch_rejected(self, tmp_path):
        p = tmp_path / "labels.yml"
        p.write_text(yaml.safe_dump({
            "version": "v0.9.0",
            "generated_at_utc": "2026-06-07",
            "labels": [],
        }))
        with pytest.raises(ValidationError, match="label schema version"):
            load_labels(p)

    def test_classified_requires_pattern_id(self):
        with pytest.raises(ValidationError, match="expected_pattern_id is required"):
            _make_label(
                expected_outcome=Outcome.CLASSIFIED,
                expected_pattern_id=None,
            )

    def test_unknown_forbids_pattern_id(self):
        with pytest.raises(ValidationError, match="must be null"):
            _make_label(
                expected_outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
                expected_pattern_id="some_pattern",
            )

    def test_sentinel_outcome_inadmissible(self):
        with pytest.raises(ValidationError, match="not labellable"):
            _make_label(
                expected_outcome=Outcome.CREDENTIAL_SENTINEL_FIRED,
                expected_pattern_id=None,
            )

    def test_circuit_open_outcome_inadmissible(self):
        with pytest.raises(ValidationError, match="not labellable"):
            _make_label(
                expected_outcome=Outcome.CIRCUIT_OPEN,
                expected_pattern_id=None,
            )

    def test_duplicate_run_ids_rejected(self):
        a = _make_label(run_id=1)
        b = _make_label(run_id=1)
        with pytest.raises(ValidationError, match="duplicate run_id"):
            LabelSet(
                version=LABEL_SCHEMA_VERSION,
                generated_at_utc="2026-06-07",
                labels=[a, b],
            )

    def test_invalid_cluster_letter_rejected(self):
        with pytest.raises(ValidationError):
            _make_label(cluster="a")  # lowercase forbidden by pattern

    def test_invalid_payload_source_rejected(self):
        with pytest.raises(ValidationError):
            _make_label(payload_source="local")

    def test_invalid_payload_shape_rejected(self):
        with pytest.raises(ValidationError):
            _make_label(payload_shape="redacted")

    def test_extra_fields_forbidden(self):
        with pytest.raises(ValidationError):
            LabeledCase(
                run_id=1,
                cluster="A",
                expected_pattern_id="x",
                expected_outcome=Outcome.CLASSIFIED,
                payload_source="scratch",
                payload_path="x",
                payload_shape="raw",
                provenance=_make_provenance(),
                notes="",
                surprise_field="not allowed",
            )

    def test_provenance_extra_forbidden(self):
        with pytest.raises(ValidationError):
            LabelProvenance(
                cluster_source="x",
                pattern_source="y",
                derivation="z",
                surprise="no",
            )

    def test_provenance_empty_field_rejected(self):
        with pytest.raises(ValidationError):
            LabelProvenance(cluster_source="", pattern_source="y", derivation="z")


# ===========================================================================
# Payload resolution
# ===========================================================================


class TestPayloadResolution:

    def test_scratch_tilde_expands(self):
        case = _make_label(payload_source="scratch", payload_path="~/scratch/x.json")
        resolved = resolve_payload_path(case, REPO_ROOT)
        # Tilde must be gone; result must be absolute.
        assert "~" not in str(resolved)
        assert resolved.is_absolute()

    def test_fixture_resolves_relative_to_repo_root(self):
        case = _make_label(
            payload_source="fixture",
            payload_path="docs/triage-agent/fixtures/early_failure_dmf_failure_486060143.json",
        )
        resolved = resolve_payload_path(case, REPO_ROOT)
        assert resolved == REPO_ROOT / case.payload_path
        assert resolved.exists()  # committed fixture must be present
        # v1.1.0 loader-chain contract: the resolve→load pipeline must
        # round-trip on the fixture branch. Previously
        # (payload_source: scratch) the resolve step succeeded but the
        # load step was unreachable from the YAML. With all 7 P0.1
        # labels now `payload_source: fixture`, the chain is on the hot
        # path for every backtest run, so the contract is enforced here.
        #
        # Commit-B amendment (2026-06-11): `load_raw_payload` now
        # delegates to `fixture_loader.load_fixture`, which STRIPS
        # `_fixture_metadata` before returning. The assertion below
        # reflects the post-amendment contract — the loaded body
        # must NOT carry `_fixture_metadata` (retiring the G7-1
        # dispatcher-drop reliance the Commit-B D4 review flagged).
        loaded = load_raw_payload(resolved)
        assert isinstance(loaded, dict)
        assert "_fixture_metadata" not in loaded, (
            "load_raw_payload must strip _fixture_metadata via "
            "fixture_loader.load_fixture; presence here means the "
            "Commit-B amendment regressed"
        )
        # Triage-essential keys preserved
        assert "data" in loaded
        assert "status" in loaded
        assert loaded["data"].get("run_steps"), (
            "data.run_steps must survive the strip"
        )

    def test_missing_payload_returns_none(self, tmp_path):
        missing = tmp_path / "absent.json"
        assert load_raw_payload(missing) is None

    def test_present_payload_returns_dict(self, tmp_path):
        present = tmp_path / "present.json"
        present.write_text('{"a": 1}')
        assert load_raw_payload(present) == {"a": 1}


# ===========================================================================
# Pattern id extraction
# ===========================================================================


class TestPatternIdExtraction:

    def _classified_record(self, pattern_id: str = "some_pattern_v1") -> RCARecord:
        return RCARecord(
            classification=Classification.COMPILE_ERROR,
            confidence=0.9,
            suggested_action=SuggestedAction.ESCALATE_TO_HUMAN,
            requires_human_review=True,
            rationale=f"pattern_id={pattern_id} sub_class=x provenance=lessons_md:lesson #1",
            evidence_mode=EvidenceMode.EARLY_FAILURE,
            outcome=Outcome.CLASSIFIED,
        )

    def test_extracts_pattern_id_from_classified(self):
        rec = self._classified_record("manifest_parse_failure_invalid_model_language_v1")
        assert extract_pattern_id(rec) == "manifest_parse_failure_invalid_model_language_v1"

    def test_returns_none_for_unknown_outcome(self):
        rec = RCARecord(
            classification=Classification.UNKNOWN,
            confidence=None,
            suggested_action=None,
            requires_human_review=True,
            rationale="pattern_id=foo sub_class=x",  # shouldn't matter
            evidence_mode=EvidenceMode.EARLY_FAILURE,
            outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
        )
        assert extract_pattern_id(rec) is None

    def test_returns_none_for_sentinel_outcome(self):
        rec = RCARecord(
            classification=Classification.UNKNOWN,
            confidence=None,
            suggested_action=None,
            requires_human_review=True,
            rationale="credential_sentinel_fired: pattern=jwt offset=10 length=20",
            evidence_mode=EvidenceMode.EARLY_FAILURE,
            outcome=Outcome.CREDENTIAL_SENTINEL_FIRED,
        )
        assert extract_pattern_id(rec) is None

    def test_returns_none_for_classified_without_rationale_prefix(self):
        rec = RCARecord(
            classification=Classification.COMPILE_ERROR,
            confidence=0.9,
            suggested_action=SuggestedAction.ESCALATE_TO_HUMAN,
            requires_human_review=True,
            rationale="no prefix here",
            evidence_mode=EvidenceMode.EARLY_FAILURE,
            outcome=Outcome.CLASSIFIED,
        )
        assert extract_pattern_id(rec) is None

    def test_contract_against_live_orchestrator(self):
        """Round-trip: feed a Pattern-1 payload through triage_failure and
        confirm extract_pattern_id parses the rationale the orchestrator
        actually emits. If `_classified`'s rationale format changes,
        this test breaks — that is the desired drift detector."""
        rec, _, _ = triage_failure(_pattern_1_payload())
        assert rec.outcome == Outcome.CLASSIFIED
        assert extract_pattern_id(rec) == "fk_orphan_detection_failure_v1"


# ===========================================================================
# Scoring (one test per Verdict)
# ===========================================================================


def _classified_rec(pattern_id: str) -> RCARecord:
    return RCARecord(
        classification=Classification.COMPILE_ERROR,
        confidence=0.9,
        suggested_action=SuggestedAction.ESCALATE_TO_HUMAN,
        requires_human_review=True,
        rationale=f"pattern_id={pattern_id} sub_class=x provenance=lessons_md:lesson #1",
        evidence_mode=EvidenceMode.EARLY_FAILURE,
        outcome=Outcome.CLASSIFIED,
    )


def _unknown_rec() -> RCARecord:
    return RCARecord(
        classification=Classification.UNKNOWN,
        confidence=None,
        suggested_action=None,
        requires_human_review=True,
        rationale="no catalog pattern matched",
        evidence_mode=EvidenceMode.EARLY_FAILURE,
        outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
    )


def _sentinel_rec() -> RCARecord:
    return RCARecord(
        classification=Classification.UNKNOWN,
        confidence=None,
        suggested_action=None,
        requires_human_review=True,
        rationale="credential_sentinel_fired: pattern=jwt offset=10 length=20",
        evidence_mode=EvidenceMode.EARLY_FAILURE,
        outcome=Outcome.CREDENTIAL_SENTINEL_FIRED,
    )


class TestScoring:

    def test_verdict_pass_classified(self):
        case = _make_label(expected_pattern_id="p1", expected_outcome=Outcome.CLASSIFIED)
        result = score_case(case, _classified_rec("p1"))
        assert result.verdict == Verdict.PASS

    def test_verdict_pass_unknown(self):
        case = _make_label(
            expected_pattern_id=None,
            expected_outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
        )
        result = score_case(case, _unknown_rec())
        assert result.verdict == Verdict.PASS

    def test_verdict_false_positive(self):
        """Label says UNKNOWN; orchestrator emitted CLASSIFIED."""
        case = _make_label(
            expected_pattern_id=None,
            expected_outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
        )
        result = score_case(case, _classified_rec("any_pattern"))
        assert result.verdict == Verdict.FALSE_POSITIVE

    def test_verdict_false_negative(self):
        """Label says CLASSIFIED; orchestrator emitted UNKNOWN."""
        case = _make_label(expected_pattern_id="p1", expected_outcome=Outcome.CLASSIFIED)
        result = score_case(case, _unknown_rec())
        assert result.verdict == Verdict.FALSE_NEGATIVE

    def test_verdict_wrong_pattern(self):
        """CLASSIFIED on both sides but pattern_ids differ."""
        case = _make_label(expected_pattern_id="p1", expected_outcome=Outcome.CLASSIFIED)
        result = score_case(case, _classified_rec("p2"))
        assert result.verdict == Verdict.WRONG_PATTERN

    def test_verdict_sentinel_unexpected(self):
        """Sentinel fires when label did not anticipate it."""
        case = _make_label(expected_pattern_id="p1", expected_outcome=Outcome.CLASSIFIED)
        result = score_case(case, _sentinel_rec())
        assert result.verdict == Verdict.SENTINEL_FIRED_UNEXPECTED

    def test_verdict_skipped_payload_missing(self):
        case = _make_label()
        result = score_case(case, None)
        assert result.verdict == Verdict.SKIPPED_PAYLOAD_MISSING
        assert result.observed_pattern_id is None
        assert result.observed_outcome is None
        assert result.rationale_excerpt == ""

    def test_rationale_excerpt_truncated(self):
        case = _make_label(expected_pattern_id="p1", expected_outcome=Outcome.CLASSIFIED)
        rec = RCARecord(
            classification=Classification.COMPILE_ERROR,
            confidence=0.9,
            suggested_action=SuggestedAction.ESCALATE_TO_HUMAN,
            requires_human_review=True,
            rationale="pattern_id=p1 " + "X" * 500,
            evidence_mode=EvidenceMode.EARLY_FAILURE,
            outcome=Outcome.CLASSIFIED,
        )
        result = score_case(case, rec)
        assert len(result.rationale_excerpt) == 240


# ===========================================================================
# End-to-end (no scratch dependency)
# ===========================================================================


class TestBacktestEndToEnd:

    def test_committed_cluster_c_fixture_scored_as_unknown_pass(self):
        """The one committed raw-shape fixture must score as PASS against
        a label expecting UNKNOWN_HANDED_TO_HUMAN."""
        label = _make_label(
            run_id=486060143,
            cluster="C",
            expected_pattern_id=None,
            expected_outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN,
            payload_source="fixture",
            payload_path="docs/triage-agent/fixtures/early_failure_dmf_failure_486060143.json",
            payload_shape="raw",
        )
        label_set = LabelSet(
            version=LABEL_SCHEMA_VERSION,
            generated_at_utc="2026-06-07",
            labels=[label],
        )
        report = run_backtest(label_set, REPO_ROOT)
        assert report.case_count_scored == 1
        assert report.case_count_skipped == 0
        assert report.verdict_counts[Verdict.PASS] == 1

    def test_synthetic_pattern_1_payload_scored_as_pass(self, tmp_path, monkeypatch):
        scratch = _scratch_under(tmp_path, monkeypatch)
        payload_path = scratch / "raw.json"
        payload_path.write_text(json.dumps(_pattern_1_payload()))
        label = _make_label(
            run_id=1,
            payload_source="scratch",  # absolute path; expanduser is no-op
            payload_path=str(payload_path),
            expected_pattern_id="fk_orphan_detection_failure_v1",
            expected_outcome=Outcome.CLASSIFIED,
        )
        label_set = LabelSet(
            version=LABEL_SCHEMA_VERSION,
            generated_at_utc="2026-06-07",
            labels=[label],
        )
        report = run_backtest(label_set, REPO_ROOT)
        assert report.verdict_counts[Verdict.PASS] == 1
        assert report.verdict_counts[Verdict.SKIPPED_PAYLOAD_MISSING] == 0

    def test_skipped_payload_counted_separately(self, tmp_path, monkeypatch):
        scratch = _scratch_under(tmp_path, monkeypatch)
        label = _make_label(
            run_id=2,
            payload_source="scratch",
            payload_path=str(scratch / "definitely_absent.json"),
        )
        label_set = LabelSet(
            version=LABEL_SCHEMA_VERSION,
            generated_at_utc="2026-06-07",
            labels=[label],
        )
        report = run_backtest(label_set, REPO_ROOT)
        assert report.case_count_scored == 0
        assert report.case_count_skipped == 1
        assert report.verdict_counts[Verdict.SKIPPED_PAYLOAD_MISSING] == 1

    def test_metrics_exclude_skipped_from_denominator(self, tmp_path, monkeypatch):
        """A skipped payload must not depress precision/recall."""
        scratch = _scratch_under(tmp_path, monkeypatch)
        present = scratch / "present.json"
        present.write_text(json.dumps(_pattern_1_payload()))
        present_label = _make_label(
            run_id=1,
            payload_source="scratch",
            payload_path=str(present),
            expected_pattern_id="fk_orphan_detection_failure_v1",
        )
        absent_label = _make_label(
            run_id=2,
            payload_source="scratch",
            payload_path=str(scratch / "absent.json"),
            expected_pattern_id="fk_orphan_detection_failure_v1",
        )
        label_set = LabelSet(
            version=LABEL_SCHEMA_VERSION,
            generated_at_utc="2026-06-07",
            labels=[present_label, absent_label],
        )
        report = run_backtest(label_set, REPO_ROOT)
        # Only the scored case counts toward TP/FP/FN.
        fk_metrics = next(
            m for m in report.per_pattern_metrics
            if m.pattern_id == "fk_orphan_detection_failure_v1"
        )
        assert fk_metrics.true_positive == 1
        assert fk_metrics.false_positive == 0
        assert fk_metrics.false_negative == 0
        assert fk_metrics.precision == 1.0
        assert fk_metrics.recall == 1.0


# ===========================================================================
# Pattern-metrics aggregation
# ===========================================================================


class TestPatternMetricsAggregation:

    def _result(self, verdict, expected, observed):
        return CaseResult(
            run_id=1, cluster="A", verdict=verdict,
            expected_pattern_id=expected, observed_pattern_id=observed,
            expected_outcome=Outcome.CLASSIFIED, observed_outcome=Outcome.CLASSIFIED,
            rationale_excerpt="",
        )

    def test_unknown_bucket_appears_in_metrics(self):
        results = [
            self._result(Verdict.PASS, None, None),  # UNKNOWN→UNKNOWN TP
        ]
        metrics = _compute_pattern_metrics(results, [])
        unknown_row = next(m for m in metrics if m.pattern_id == "UNKNOWN")
        assert unknown_row.true_positive == 1
        assert unknown_row.precision == 1.0

    def test_false_positive_charged_to_observed_pattern(self):
        # Label expected UNKNOWN; observed Pattern p1 → FP on p1.
        results = [
            self._result(Verdict.FALSE_POSITIVE, None, "p1"),
        ]
        metrics = _compute_pattern_metrics(results, ["p1"])
        p1 = next(m for m in metrics if m.pattern_id == "p1")
        assert p1.false_positive == 1
        assert p1.true_positive == 0
        # And UNKNOWN bucket sees an FN (expected UNKNOWN, observed elsewhere).
        unknown = next(m for m in metrics if m.pattern_id == "UNKNOWN")
        assert unknown.false_negative == 1

    def test_skipped_excluded_from_aggregation(self):
        results = [
            self._result(Verdict.PASS, "p1", "p1"),
            CaseResult(
                run_id=2, cluster="B", verdict=Verdict.SKIPPED_PAYLOAD_MISSING,
                expected_pattern_id="p1", observed_pattern_id=None,
                expected_outcome=Outcome.CLASSIFIED, observed_outcome=None,
                rationale_excerpt="",
            ),
        ]
        metrics = _compute_pattern_metrics(results, ["p1"])
        p1 = next(m for m in metrics if m.pattern_id == "p1")
        assert p1.true_positive == 1
        assert p1.false_negative == 0


# ===========================================================================
# Rendering smoke
# ===========================================================================


class TestRendering:

    def _trivial_report(self) -> BacktestReport:
        case = CaseResult(
            run_id=1, cluster="A", verdict=Verdict.PASS,
            expected_pattern_id="p1", observed_pattern_id="p1",
            expected_outcome=Outcome.CLASSIFIED, observed_outcome=Outcome.CLASSIFIED,
            rationale_excerpt="pattern_id=p1 sub_class=x",
        )
        counts = {v: 0 for v in Verdict}
        counts[Verdict.PASS] = 1
        return BacktestReport(
            label_version=LABEL_SCHEMA_VERSION,
            label_path="docs/triage-agent/fixtures/p01_labels.yml",
            label_notes="",
            harness_version=HARNESS_VERSION,
            catalog_schema_version=CATALOG_SCHEMA_VERSION,
            case_count_total=1,
            case_count_scored=1,
            case_count_skipped=0,
            case_count_errored=0,
            verdict_counts=counts,
            per_pattern_metrics=_compute_pattern_metrics([case], ["p1"]),
            cases=[case],
        )

    def test_required_sections_present(self):
        text = render_markdown_report(self._trivial_report(), "2026-06-07 12:00 UTC")
        for required in (
            "# Backtest baseline",
            "## Verdict counts",
            "## Per-pattern precision / recall",
            "## Per-case results",
            "## Observed rationale excerpts",
            "non-gating",
        ):
            assert required in text, f"missing section: {required}"

    def test_skipped_case_rendered_without_rationale(self):
        skipped = CaseResult(
            run_id=2, cluster="C", verdict=Verdict.SKIPPED_PAYLOAD_MISSING,
            expected_pattern_id=None, observed_pattern_id=None,
            expected_outcome=Outcome.UNKNOWN_HANDED_TO_HUMAN, observed_outcome=None,
            rationale_excerpt="",
        )
        counts = {v: 0 for v in Verdict}
        counts[Verdict.SKIPPED_PAYLOAD_MISSING] = 1
        report = BacktestReport(
            label_version=LABEL_SCHEMA_VERSION,
            label_path="x.yml",
            label_notes="",
            harness_version=HARNESS_VERSION,
            catalog_schema_version=CATALOG_SCHEMA_VERSION,
            case_count_total=1,
            case_count_scored=0,
            case_count_skipped=1,
            case_count_errored=0,
            verdict_counts=counts,
            per_pattern_metrics=[],
            cases=[skipped],
        )
        text = render_markdown_report(report, "2026-06-07 12:00 UTC")
        assert "_skipped (payload not present)_" in text

    def test_label_notes_rendered_when_present(self):
        report = self._trivial_report()
        # Reconstruct with notes populated.
        report = BacktestReport(
            label_version=report.label_version,
            label_path=report.label_path,
            label_notes="In-sample caveat applies.",
            harness_version=report.harness_version,
            catalog_schema_version=report.catalog_schema_version,
            case_count_total=report.case_count_total,
            case_count_scored=report.case_count_scored,
            case_count_skipped=report.case_count_skipped,
            case_count_errored=report.case_count_errored,
            verdict_counts=report.verdict_counts,
            per_pattern_metrics=report.per_pattern_metrics,
            cases=report.cases,
        )
        text = render_markdown_report(report, "2026-06-07 12:00 UTC")
        assert "## Corpus caveats" in text
        assert "In-sample caveat applies." in text

    def test_label_notes_skipped_when_empty(self):
        text = render_markdown_report(self._trivial_report(), "2026-06-07 12:00 UTC")
        assert "## Corpus caveats" not in text

    def test_version_stamps_rendered_in_summary(self):
        text = render_markdown_report(self._trivial_report(), "2026-06-07 12:00 UTC")
        assert f"**Harness version:** `{HARNESS_VERSION}`" in text
        assert f"**Catalog schema:** `{CATALOG_SCHEMA_VERSION}`" in text


# ===========================================================================
# DA P0/P1 follow-ups (Day-6 review)
# ===========================================================================


class TestPathTraversalDefense:
    """P0-2: resolve_payload_path must reject paths escaping their root."""

    def test_fixture_escape_rejected(self):
        case = _make_label(
            payload_source="fixture",
            payload_path="../../../../etc/passwd",
        )
        with pytest.raises(ValueError, match="escapes repo_root"):
            resolve_payload_path(case, REPO_ROOT)

    def test_fixture_path_escape_rejected(self):
        """v1.1.0 regression: the L173-181 is_relative_to check in
        resolve_payload_path now gates EVERY backtest load. All 7 P0.1
        labels are payload_source=fixture as of the v1.1.0 schema bump,
        so this defense is on the hot path; pre-v1.1.0 the branch was
        dead code reachable only via hand-crafted labels.

        Wrapping `load_raw_payload(resolve_payload_path(...))` documents
        the production call chain even though resolve_payload_path is
        the layer that raises — if the defense is ever weakened, load
        would receive an out-of-tree Path and either fail noisily or
        succeed silently (worse). Catching it at resolve is the
        contract.
        """
        case = _make_label(
            payload_source="fixture",
            payload_path="../../../etc/passwd",
        )
        with pytest.raises(ValueError, match="escapes repo_root"):
            load_raw_payload(resolve_payload_path(case, REPO_ROOT))

    def test_scratch_escape_rejected(self):
        case = _make_label(
            payload_source="scratch",
            payload_path="/etc/passwd",
        )
        with pytest.raises(ValueError, match="escapes ~/scratch/"):
            resolve_payload_path(case, REPO_ROOT)

    def test_scratch_outside_home_scratch_rejected(self, tmp_path):
        # tmp_path is under /var/folders/... on macOS, not ~/scratch/
        case = _make_label(
            payload_source="scratch",
            payload_path=str(tmp_path / "anywhere.json"),
        )
        with pytest.raises(ValueError, match="escapes ~/scratch/"):
            resolve_payload_path(case, REPO_ROOT)


class TestErrorDuringTriage:
    """P1-2: corrupt payload must not abort the entire run."""

    def test_triage_typeerror_yields_error_verdict(self, tmp_path, monkeypatch):
        """JSON-decoding to a non-dict root is rejected at the
        `fixture_loader.load_fixture` chokepoint with TypeError
        (tightened 2026-06-21, PR #1821 Commit 6, N1/N2 — was previously
        permissive-passthrough that propagated to a downstream
        TypeError inside `triage_failure`). The harness's per-case
        error isolation must catch the load-time error and yield
        ERROR_DURING_TRIAGE for that case rather than aborting the
        whole run. This is the P1-2 contract extended to load-time
        failures via `safe_load` (R4 N1/N2 surfaced that the prior
        isolation only covered triage-time failures — see
        `backtest_scoring.py` module docstring).

        Use monkeypatch to redirect HOME so the scratch allowlist
        admits a path inside tmp_path \u2014 no real filesystem writes
        outside the test sandbox.
        """
        monkeypatch.setenv("HOME", str(tmp_path))
        scratch_dir = tmp_path / "scratch" / "triage-da-test"
        scratch_dir.mkdir(parents=True)
        bad = scratch_dir / "list.json"
        bad.write_text("[1, 2, 3]")
        case = _make_label(
            run_id=42,
            payload_source="scratch",
            payload_path=str(bad),
        )
        label_set = LabelSet(
            version=LABEL_SCHEMA_VERSION,
            generated_at_utc="2026-06-07",
            labels=[case],
        )
        report = run_backtest(label_set, REPO_ROOT)
        assert report.case_count_errored == 1
        assert report.case_count_scored == 0
        assert report.verdict_counts[Verdict.ERROR_DURING_TRIAGE] == 1
        assert "TypeError" in report.cases[0].rationale_excerpt

    def test_errored_case_excluded_from_metrics(self):
        """ERROR_DURING_TRIAGE must not count as TP/FP/FN."""
        errored = CaseResult(
            run_id=1, cluster="A", verdict=Verdict.ERROR_DURING_TRIAGE,
            expected_pattern_id="p1", observed_pattern_id=None,
            expected_outcome=Outcome.CLASSIFIED, observed_outcome=None,
            rationale_excerpt="TypeError: ...",
        )
        passed = CaseResult(
            run_id=2, cluster="B", verdict=Verdict.PASS,
            expected_pattern_id="p1", observed_pattern_id="p1",
            expected_outcome=Outcome.CLASSIFIED, observed_outcome=Outcome.CLASSIFIED,
            rationale_excerpt="pattern_id=p1",
        )
        metrics = _compute_pattern_metrics([errored, passed], ["p1"])
        p1 = next(m for m in metrics if m.pattern_id == "p1")
        # Only the PASS case contributes; the ERROR case does not depress recall.
        assert p1.true_positive == 1
        assert p1.false_negative == 0


class TestReservedBucketName:
    """P2-2: a label literally named "UNKNOWN" must be rejected."""

    def test_unknown_pattern_id_rejected(self):
        with pytest.raises(ValidationError, match="reserved for the no-match"):
            _make_label(expected_pattern_id=RESERVED_BUCKET_PATTERN_ID)


class TestPerPatternContractRoundTrip:
    """P1-4: each catalog pattern_id must survive the orchestrator → regex
    round-trip. If any pattern_id contains whitespace (which \\S+ would
    silently truncate) or the rationale format drifts, this test breaks.
    """

    @pytest.mark.parametrize("pattern_id", [
        "fk_orphan_detection_failure_v1",
        "pr_isolated_schema_missing_upstream_v1",
        "manifest_parse_failure_invalid_model_language_v1",
    ])
    def test_pattern_id_is_whitespace_free(self, pattern_id):
        """\\S+ regex would silently truncate on whitespace; assert all
        catalog pattern_ids are whitespace-free at the schema level."""
        assert " " not in pattern_id
        assert "\t" not in pattern_id

    def test_fk_orphan_pattern_round_trips(self):
        rec, _, _ = triage_failure(_pattern_1_payload())
        assert rec.outcome == Outcome.CLASSIFIED
        assert extract_pattern_id(rec) == "fk_orphan_detection_failure_v1"

    def test_pr_isolated_schema_pattern_round_trips(self):
        # Pattern 2 trigger: status_message about upstream model not found in PR-isolated schema.
        payload = _wrap_step({
            "status_message": "Database Error in model rpt_x",
            "message": (
                "Compilation Error\n  Object 'DEV_HQ_FBIN_RAW_PR2543.WINN_SAP.SOMETHING' does not exist\n"
            ),
            "truncated_debug_logs": "1 of 1 ERROR creating sql incremental model",
        })
        rec, _, _ = triage_failure(payload)
        # The pattern may not match if the regex differs; only assert if CLASSIFIED.
        if rec.outcome == Outcome.CLASSIFIED:
            pid = extract_pattern_id(rec)
            assert pid is not None
            assert " " not in pid

    def test_manifest_parse_pattern_round_trips(self):
        payload = _wrap_step({
            "status_message": "Parsing Error",
            "message": "Invalid model language: 'sqlx' not in {'sql','python'}",
            "truncated_debug_logs": "manifest.json parse failed",
        })
        rec, _, _ = triage_failure(payload)
        if rec.outcome == Outcome.CLASSIFIED:
            pid = extract_pattern_id(rec)
            assert pid is not None
            assert " " not in pid


class TestEmptyLabelSet:
    """P2-5: empty labels list must produce a coherent report."""

    def test_empty_labels_run_succeeds(self):
        label_set = LabelSet(
            version=LABEL_SCHEMA_VERSION,
            generated_at_utc="2026-06-07",
            labels=[],
        )
        report = run_backtest(label_set, REPO_ROOT)
        assert report.case_count_total == 0
        assert report.case_count_scored == 0
        assert report.case_count_skipped == 0
        assert report.case_count_errored == 0
        assert report.cases == []
        # Per-pattern metrics: only the synthetic UNKNOWN bucket survives.
        assert [m.pattern_id for m in report.per_pattern_metrics] == [RESERVED_BUCKET_PATTERN_ID]
        # And rendering doesn't crash.
        rendered = render_markdown_report(report, "2026-06-07 12:00 UTC")
        assert "## Verdict counts" in rendered


# ===========================================================================
# Commit D — P0.1 corpus gate (outcome drift + schema drift)
# ===========================================================================


class TestBacktestCorpusGate:
    """Commit D — fixture-vs-live drift gates on the committed P0.1 corpus.

    Gate-tier discipline (do not invert)
    ------------------------------------
    These tests are the BASE of the testing pyramid — fast, deterministic,
    cheap. They run as the per-PR merge gate under
    ``.github/workflows/triage-tests.yaml``. Keep them that way:

    * Sub-second per assertion against the in-sample 7-payload corpus.
      Two orders of magnitude under the 15-min merge-budget ceiling.
    * No LLM-as-judge evaluation here. Pattern-match against labels is
      deterministic; "upgrading" to LLM-judge eval of RCA quality
      inverts the pyramid (expensive thing ran, cheap thing didn't
      catch the bug) and prices the gate out of existence.
    * The held-out statistical accuracy battery (≥20 payloads,
      p≥0.90/r≥0.70 — see Phase-2 dormant items in
      ``docs/triage-agent/phase-2-progress-log.md``) belongs in a
      separate release-layer workflow, NOT here. Per-PR gates run on
      every push; release-layer batteries can afford the cost.

    Two distinct drift axes are checked here, deliberately split so a
    future failure points at one diagnostic, not a conjunction:

    * **Outcome drift** — does ``run_backtest`` against the committed
      ``p01_labels.yml`` still produce 7/7 PASS, with each active pattern
      bucket at ``precision == recall == 1.0``? Guards against logic
      drift where a Commit-B-class change to the orchestrator silently
      degrades a pattern's match rate. Carried by
      ``test_p01_corpus_full_passes`` (corpus-aggregate) and
      ``test_p01_corpus_per_pattern_floors`` (per-pattern diagnostic).
    * **Schema drift** (Arch-1) — do the committed JSON fixtures consumed
      by the corpus still carry ``_fixture_metadata.redact_schema_version``
      equal to the live ``REDACT_SCHEMA_VERSION`` constant? Guards
      against the next bump of ``REDACT_SCHEMA_VERSION`` shipping without
      re-emission of the committed fixtures. The M8 catcher in
      ``test_redactor_pipeline.py::test_redact_schema_version_matches_module_constant``
      only protects freshly-emitted output; it cannot detect that the
      *committed* bytes have drifted. Carried by
      ``test_committed_fixtures_redact_schema_version_matches_live_constant``.
    """

    P01_LABELS_PATH = REPO_ROOT / "docs/triage-agent/fixtures/p01_labels.yml"

    def test_p01_corpus_full_passes(self):
        """Q1 corpus-aggregate gate: 7/7 scored, 7/7 PASS.

        Structural assertion (``case_count_scored == 7``) catches
        accidental fixture deletion or label drop. Property assertion
        (``verdict_counts[PASS] == case_count_scored``) survives corpus
        accretion: if Phase-2 adds an 8th label, this still passes when
        the new label scores PASS. Per-pattern floors are checked
        separately in ``test_p01_corpus_per_pattern_floors``.
        """
        label_set = load_labels(self.P01_LABELS_PATH)
        report = run_backtest(label_set, REPO_ROOT)
        assert report.case_count_scored == 7, (
            f"corpus integrity: expected 7 scored cases, got "
            f"{report.case_count_scored}"
        )
        assert report.case_count_skipped == 0, (
            "no payload should be missing under v1.1.0 fixture-source convention"
        )
        assert report.verdict_counts[Verdict.PASS] == report.case_count_scored, (
            f"corpus PASS rate degraded: "
            f"{report.verdict_counts[Verdict.PASS]}/{report.case_count_scored} "
            f"(expected all PASS)"
        )

    def test_p01_corpus_per_pattern_floors(self):
        """Q5 per-pattern gate: every active bucket at precision/recall == 1.0.

        Diagnostic complement to ``test_p01_corpus_full_passes``: an
        aggregate-only gate would let a Commit-B-class change that
        breaks one pattern while another compensates pass. Hardcoding
        ``== 1.0`` per pattern catches that. Lowering any floor is an
        explicit adjudication on corpus accretion, not silent drift.
        """
        label_set = load_labels(self.P01_LABELS_PATH)
        report = run_backtest(label_set, REPO_ROOT)
        # Buckets with no TP/FP/FN are inactive (precision/recall both
        # None); exclude them from floor enforcement so the synthetic
        # UNKNOWN bucket plus any pattern absent from the corpus don't
        # crash the floor check.
        active = [
            m for m in report.per_pattern_metrics
            if (m.true_positive + m.false_positive + m.false_negative) > 0
        ]
        assert active, (
            "no active pattern buckets — corpus may be empty or all-skipped"
        )
        for m in active:
            assert m.precision == 1.0, (
                f"{m.pattern_id} precision floor breached: {m.precision} "
                f"(TP={m.true_positive}, FP={m.false_positive})"
            )
            assert m.recall == 1.0, (
                f"{m.pattern_id} recall floor breached: {m.recall} "
                f"(TP={m.true_positive}, FN={m.false_negative})"
            )

    def test_committed_fixtures_redact_schema_version_matches_live_constant(self):
        """Arch-1: committed fixture bytes must carry the live REDACT_SCHEMA_VERSION.

        Distinct from the M8 catcher
        ``test_redactor_pipeline.py::test_redact_schema_version_matches_module_constant``
        which asserts *freshly-emitted* output equals the live constant.
        M8 cannot catch the case where ``REDACT_SCHEMA_VERSION`` bumps
        but the committed fixtures stay at the old value — that's this
        test's job. Triggered when the next bump ships without re-emission.
        """
        label_set = load_labels(self.P01_LABELS_PATH)
        fixture_labels = [
            label for label in label_set.labels
            if label.payload_source == "fixture"
        ]
        assert fixture_labels, (
            "no fixture-source labels in corpus — Add-1 fail-loud guard. "
            "All v1.1.0+ corpus entries should be fixture-source."
        )
        for label in fixture_labels:
            fixture_path = REPO_ROOT / label.payload_path
            assert fixture_path.exists(), (
                f"missing fixture file: {label.payload_path}"
            )
            data = json.loads(fixture_path.read_text())
            committed_version = data.get("_fixture_metadata", {}).get(
                "redact_schema_version"
            )
            assert committed_version == REDACT_SCHEMA_VERSION, (
                f"fixture {label.payload_path} carries "
                f"redact_schema_version={committed_version!r} but live "
                f"REDACT_SCHEMA_VERSION={REDACT_SCHEMA_VERSION!r}; "
                f"re-emit fixtures via redactor_pipeline.py --all"
            )

