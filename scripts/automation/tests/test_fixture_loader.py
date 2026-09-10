"""Tests for `scripts.automation.src.triage.fixture_loader`.

Covers the explicit `_fixture_metadata` strip contract that retires
G7-1 dispatcher-drop reliance on the redactor's "Unknown leaf — drop"
branch. See module docstring for the D4-review rationale.

Test classes:
  TestLoadFixtureStripsMetadata — happy-path strip
  TestLoadFixtureIdempotent    — pop-with-default no-op behavior on raws
  TestLoadFixtureRoundTrip     — real committed fixture round-trip
"""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from scripts.automation.src.triage.fixture_loader import load_fixture


REPO_ROOT = Path(__file__).resolve().parents[3]
FIXTURES_DIR = REPO_ROOT / "docs" / "triage-agent" / "fixtures"


class TestLoadFixtureStripsMetadata:
    """Synthetic-envelope coverage of the strip contract."""

    def test_metadata_block_removed(self, tmp_path: Path):
        envelope = {
            "_fixture_metadata": {
                "content_sha256": "abc",
                "source_basename": "run_999_cluster_A.json",
                "source_run_id": 999,
                "source_cluster": "A",
                "source_size_bytes": 42,
                "redact_schema_version": "v0.0.0",
                "email_substitution_count": 0,
                "retained_step_count": 1,
            },
            "data": {"run_steps": [{"name": "step"}]},
            "status": {"code": 200},
        }
        path = tmp_path / "env.json"
        path.write_text(json.dumps(envelope), encoding="utf-8")

        body = load_fixture(path)

        assert "_fixture_metadata" not in body, (
            "load_fixture must strip _fixture_metadata; leaving it "
            "behind keeps the harness in G7-1 dispatcher-drop posture"
        )

    def test_data_and_status_preserved(self, tmp_path: Path):
        envelope = {
            "_fixture_metadata": {"source_run_id": 1, "source_cluster": "B"},
            "data": {"run_steps": [{"name": "step", "status_humanized": "Error"}]},
            "status": {"code": 200, "is_success": False},
        }
        path = tmp_path / "env.json"
        path.write_text(json.dumps(envelope), encoding="utf-8")

        body = load_fixture(path)

        assert body["data"] == envelope["data"]
        assert body["status"] == envelope["status"]
        assert set(body.keys()) == {"data", "status"}


class TestLoadFixtureIdempotent:
    """Pop-with-default makes load_fixture safe on payloads that never
    carried `_fixture_metadata` — raw scratch payloads, hand-built
    test bodies, future schema variants. Single-chokepoint design
    depends on this no-op property at the scratch branch of
    `resolve_payload_path`."""

    def test_raw_payload_without_metadata_unchanged(self, tmp_path: Path):
        # Mimics a raw scratch payload: dbt Cloud Admin-v2 shape,
        # no envelope wrapping
        raw = {
            "status": {"code": 200},
            "data": {
                "status_message": "Error",
                "run_steps": [
                    {"name": "Invoke dbt", "status_humanized": "Error"}
                ],
            },
        }
        path = tmp_path / "raw.json"
        path.write_text(json.dumps(raw), encoding="utf-8")

        body = load_fixture(path)

        # Bytes-equivalent (no metadata to strip; nothing to add)
        assert body == raw

    def test_empty_dict_returns_empty_dict(self, tmp_path: Path):
        path = tmp_path / "empty.json"
        path.write_text("{}", encoding="utf-8")
        assert load_fixture(path) == {}

    def test_non_dict_root_raises_typeerror(self, tmp_path: Path):
        # JSON allows top-level lists/scalars, but load_fixture's contract
        # is dict-only — non-dict roots are rejected at the chokepoint
        # rather than propagating through callers' `Optional[dict]`
        # types. Tightened 2026-06-21 (PR #1821 Commit 6, R4 finding
        # N1/N2): was previously permissive-passthrough; the caller
        # trace showed no production callsite consumes non-dict roots
        # (every one does dict access on the return), so the typed
        # contract is enforced. If a real non-dict fixture ever needs
        # to ship, widen at that point with a known requirement, not
        # pre-emptively here.
        path = tmp_path / "list.json"
        path.write_text("[1, 2, 3]", encoding="utf-8")
        with pytest.raises(TypeError, match="must be a JSON object"):
            load_fixture(path)


class TestLoadFixtureRoundTrip:
    """Real committed fixture round-trip — proves the strip works on
    the actual envelope shape redactor_pipeline.py emits."""

    @pytest.mark.parametrize("basename", [
        "early_failure_dmf_failure_484675412.json",
        "early_failure_dmf_failure_486060143.json",
        "early_failure_manifest_parse_485821754.json",
        "early_failure_manifest_parse_485850628.json",
        "early_failure_manifest_parse_485851058.json",
        "early_failure_pr_schema_missing_487313189.json",
        "early_failure_pr_schema_missing_487333396.json",
    ])
    def test_committed_fixture_loads_clean(self, basename: str):
        path = FIXTURES_DIR / basename
        assert path.exists(), f"committed fixture missing: {path}"

        body = load_fixture(path)

        # Metadata gone
        assert "_fixture_metadata" not in body, (
            f"{basename}: _fixture_metadata not stripped"
        )
        # Triage-essential keys preserved
        assert "data" in body, f"{basename}: data key missing after strip"
        assert isinstance(body["data"], dict)
        assert body["data"].get("run_steps"), (
            f"{basename}: run_steps must be non-empty after strip"
        )
