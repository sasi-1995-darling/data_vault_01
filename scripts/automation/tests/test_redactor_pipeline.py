"""Test suite for the redactor pipeline — Commit A.

Test surface is mutation-table driven (M1-M13 from spec freeze). Each
mutation row maps to a named test method; deleting the corresponding
production code SHOULD make exactly that test fail. M11 is a documented
partial-catch (load-bearing code comment, not test-observable).

Classes:
  TestSentinelSweep      — credential audit, the load-bearing security control
  TestPipelineGuards     — collision, depth, determinism, version-pin, log hygiene
  TestEmittedFixtureContract — output shape consumers will rely on
  TestModuleHelpers      — smoke tests for free functions

Determinism + idempotency tests are in this file so they share fixtures
with the rest of the surface. Cross-consumer contract tests for the
explicit `_fixture_metadata` strip live in `test_fixture_loader.py`
(Commit B).
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

import pytest

from scripts.automation.src.triage.redact import REDACT_SCHEMA_VERSION
from scripts.automation.src.triage.redactor_pipeline import (
    CLUSTER_TO_PATTERN,
    _audit_fixture_for_credentials,
    _iter_string_leaves,
    _output_filename,
    emit_batch,
    emit_single,
)


# ---------------------------------------------------------------------------
# Module-level constants — fixture / scratch directory addressing
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parent.parent.parent.parent
FIXTURES_DIR = REPO_ROOT / "docs" / "triage-agent" / "fixtures"
SCRATCH_DIR = Path.home() / "scratch" / "triage-day4"

# C3 (Commit B amendment): per-fixture size bands as a single source
# of truth. ALL 7 committed early-failure fixtures are now under
# contract. ±20% of the actual byte count at Commit B emission time.
# Drift outside the band signals either a redactor behavior change
# (which should bump REDACT_SCHEMA_VERSION) or a payload-shape change
# in the upstream raw scratch (which should be a deliberate decision,
# not a silent fixture growth). Adding a new fixture to FIXTURES_DIR
# must add a row here — `test_band_table_covers_all_committed_fixtures`
# enforces set-equality so accretion forces conscious-row-add.
EXPECTED_BANDS: dict[str, tuple[int, int]] = {
    # A-cluster (manifest_parse)
    "early_failure_manifest_parse_485821754.json": (63_652, 95_478),   # 79,565 actual
    "early_failure_manifest_parse_485850628.json": (64_456, 96_685),   # 80,571 actual
    "early_failure_manifest_parse_485851058.json": (63_376, 95_064),   # 79,220 actual
    # B-cluster (pr_schema_missing)
    "early_failure_pr_schema_missing_487313189.json": (20_757, 31_136),  # 25,947 actual
    "early_failure_pr_schema_missing_487333396.json": (20_006, 30_010),  # 25,008 actual
    # C-cluster (dmf_failure)
    "early_failure_dmf_failure_484675412.json": (11_822, 17_733),       # 14,778 actual
    "early_failure_dmf_failure_486060143.json": (27_042, 40_562),       # 33,802 actual
}

# Raw→fixture mapping for the LIVE-producer idempotency test. Required
# only when `~/scratch/triage-day4/` is populated; clean-clone CI
# without scratch raws skips the test (pytest.skip), not fails.
RAW_TO_FIXTURE: dict[str, str] = {
    "run_484675412_cluster_C.json": "early_failure_dmf_failure_484675412.json",
    "run_485821754_cluster_A.json": "early_failure_manifest_parse_485821754.json",
    "run_485850628_cluster_A.json": "early_failure_manifest_parse_485850628.json",
    "run_485851058_cluster_A.json": "early_failure_manifest_parse_485851058.json",
    "run_486060143_cluster_C.json": "early_failure_dmf_failure_486060143.json",
    "run_487313189_cluster_B.json": "early_failure_pr_schema_missing_487313189.json",
    "run_487333396_cluster_B.json": "early_failure_pr_schema_missing_487333396.json",
}


# ---------------------------------------------------------------------------
# Helpers — synthetic raw payload builders
# ---------------------------------------------------------------------------

def _minimal_raw_payload() -> dict:
    """Smallest viable raw dbt Cloud Admin-v2 payload.

    Must produce a fixture with non-empty `data.run_steps` after redaction
    (ADD-2 contract). Uses only PASSTHROUGH/REGEX_ELIGIBLE fields so the
    redactor preserves the step structure.
    """
    return {
        "status": {"code": 200},
        "data": {
            "status_message": "synthetic test payload",
            "run_steps": [
                {
                    "name": "Invoke dbt with `dbt build`",
                    "status": 20,
                    "status_humanized": "Error",
                    "started_at": "2026-06-09T00:00:00.000Z",
                    "finished_at": "2026-06-09T00:00:01.000Z",
                    "message": "Database Error in model dim_customer",
                    "truncated_debug_logs": "Completed with 1 error",
                }
            ],
        },
    }


def _write_raw(tmp_path: Path, payload: dict, run_id: int = 999999999,
               cluster: str = "A") -> Path:
    """Write a synthetic raw payload with convention filename."""
    path = tmp_path / f"run_{run_id}_cluster_{cluster}.json"
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


# ===========================================================================
# TestSentinelSweep — the load-bearing security control (G2-1 dual sweep)
# ===========================================================================

class TestSentinelSweep:
    """5-case suite covering M1, M2, M3, M4, M5 from the mutation table."""

    # ----- M1, M2: delete sweep call / replace raise with pass ------------

    def test_listofstrings_with_jwt_fails_closed(self, tmp_path: Path):
        """M1/M2 catcher: JWT inside a list-of-strings under an unknown
        container key — the exact hole Claude flagged.

        `_redact_node`'s list branch recurses into elements; bare str
        elements fall through to `return node` unchanged AND are never
        sentinel-scanned (the per-field sentinel only runs inside
        REGEX_ELIGIBLE_FIELDS). The dual sweep is the commit-boundary
        catch.
        """
        jwt_literal = (
            "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.dummy_signature_value"
        )
        payload = _minimal_raw_payload()
        # Inject under unknown container — survives via list-branch hole
        payload["data"]["extra_debug"] = {"debug_messages": [jwt_literal]}
        raw_path = _write_raw(tmp_path, payload, run_id=1001)
        fixture_dir = tmp_path / "fixtures"
        fixture_dir.mkdir()

        result = emit_single(raw_path, fixture_dir, seen_basenames=set())

        assert result.bucket == "sentinel_fired"
        assert result.sentinel_event is not None
        assert result.sentinel_event.pattern_name == "jwt"
        # M5 reinforcement: fail-closed leaves NO file at all
        assert list(fixture_dir.iterdir()) == [], (
            "fail-closed must leave NO file on disk (neither final nor .tmp)"
        )

    # ----- M3: delete structural-walk loop --------------------------------

    def test_pem_with_real_newlines_fails_closed(self, tmp_path: Path):
        """M3 catcher: escape-affected pattern only a structural walk catches.

        `private_key` regex anchors `-----BEGIN ... PRIVATE KEY-----`.
        When the PEM block sits as a real-newline-separated string in the
        dict, a structural walk over the dict sees it intact. `json.dumps`
        escapes real newlines to `\\n` two-char sequences; the regex
        doesn't span the escaped form so a serialized-text sweep alone
        misses it.

        Delete the walk loop (M3 mutation) → this test fails. Walk catches → pass.

        REVISION (PR 2 — v1.1.0 audit-before-transform):
        ``redact.audit_raw_for_credentials`` (called step 0 from
        ``redact_early_failure``) now owns the structural-walk
        responsibility upstream of the offline emitter's dual sweep,
        and emits a RICHER ``field_path`` than the dual sweep's
        synthetic placeholder string. The M3 catcher property is
        preserved as defense-in-depth: deleting the walk in either
        ``redact.py::_walk_str_leaves`` or
        ``redactor_pipeline.py::_audit_fixture_for_credentials`` alone
        leaves the OTHER walk catching it; deleting BOTH walks (the
        actual M3 mutation under v1.1.0) makes this test fail. The
        assertion below documents the new field_path semantics: a real
        dotted path rooted at the raw payload, not the dual-sweep
        placeholder. See ``docs/triage-agent/credential-threat-model.md`` R1.
        """
        pem = (
            "-----BEGIN PRIVATE KEY-----\n"
            "MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQ\n"
            "-----END PRIVATE KEY-----"
        )
        payload = _minimal_raw_payload()
        payload["data"]["extra_debug"] = {"key_dump": [pem]}
        raw_path = _write_raw(tmp_path, payload, run_id=1002)
        fixture_dir = tmp_path / "fixtures"
        fixture_dir.mkdir()

        result = emit_single(raw_path, fixture_dir, seen_basenames=set())

        assert result.bucket == "sentinel_fired"
        assert result.sentinel_event is not None
        assert result.sentinel_event.pattern_name == "private_key"
        # PR 2 (v1.1.0): real field_path from audit_raw_for_credentials,
        # not the dual-sweep's synthetic placeholder. The leaf was placed
        # at data.extra_debug.key_dump[0] in a list, so the path uses the
        # list-element convention ``[]`` (see redact.py::_list_element_path).
        assert (
            result.sentinel_event.field_path
            == "data.extra_debug.key_dump[]"
        )

    # ----- M4: delete serialized-text sweep --------------------------------

    def test_credential_in_key_name_fails_closed(self, tmp_path: Path):
        """M4 catcher: credential placed in a DICT KEY name within a
        PASSTHROUGH value.

        `_iter_string_leaves` yields VALUES only, never keys. The
        serialized-text sweep is the catcher for credential-shaped keys.

        Design subtlety discovered during this test: `_redact_node`
        prunes unknown key NAMES along with their unknown values
        (unknown key → value is unknown leaf → dropped → container empty
        → dropped). The credential-shaped key only reaches fixture_text
        when its parent value is preserved verbatim. PASSTHROUGH fields
        (e.g. `status`) do exactly this: `out[key] = value` keeps the
        entire dict regardless of internal keys. Injecting under
        `status` lets the AWS key reach the serialized text.

        Delete the serialized sweep loop (M4 mutation) → this test fails.
        """
        aws_key = "AKIAIOSFODNN7EXAMPLE"
        payload = _minimal_raw_payload()
        # Inject inside PASSTHROUGH `status` dict — entire value preserved
        # verbatim, so the AWS-shaped key survives into fixture_text.
        payload["status"][aws_key] = "benign_value"
        raw_path = _write_raw(tmp_path, payload, run_id=1003)
        fixture_dir = tmp_path / "fixtures"
        fixture_dir.mkdir()

        result = emit_single(raw_path, fixture_dir, seen_basenames=set())

        assert result.bucket == "sentinel_fired"
        assert result.sentinel_event is not None
        assert result.sentinel_event.pattern_name == "aws_access_key"
        # Specifically serialized-text sweep caught it (not structural walk)
        assert (
            result.sentinel_event.field_path == "<serialized_fixture_text>"
        )

    # ----- M5: skip atomic rename -----------------------------------------

    def test_failed_sweep_leaves_no_tmp_file(self, tmp_path: Path):
        """M5 catcher: on fail-closed, NO .tmp residue.

        HONEST DISCLOSURE (mutation table M11): this test observes only
        the POST-cleanup state. It catches mutations that bypass cleanup
        (M5 — skip atomic rename, leaving .tmp behind) but CANNOT catch
        a transient .tmp written before sweep ran (M11 — DA-1 ordering
        violation). M11 is comment-enforced at the emission sequence in
        `emit_single`; reordering requires a 3-step mitigation per the
        load-bearing code block there.
        """
        jwt_literal = (
            "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.dummy_signature_value"
        )
        payload = _minimal_raw_payload()
        payload["data"]["extra_debug"] = {"x": [jwt_literal]}
        raw_path = _write_raw(tmp_path, payload, run_id=1004)
        fixture_dir = tmp_path / "fixtures"
        fixture_dir.mkdir()

        result = emit_single(raw_path, fixture_dir, seen_basenames=set())

        assert result.bucket == "sentinel_fired"
        tmp_files = list(fixture_dir.glob("*.tmp"))
        json_files = list(fixture_dir.glob("*.json"))
        assert tmp_files == [], f"sweep-fail left .tmp orphan(s): {tmp_files}"
        assert json_files == [], (
            f"sweep-fail wrote fixture: {json_files} — must never reach disk"
        )

    # ----- DA finding F-1 (orig M-1): unknown cluster letter routing -----

    def test_unknown_cluster_letter_routes_to_malformed_input(
        self, tmp_path: Path
    ):
        """M-1 catcher: a filename with an unknown cluster letter (e.g.
        run_999_cluster_D.json) must bucket as malformed_input via the
        filename-mismatch branch — NOT crash _output_filename downstream.

        Without the regex restriction `[ABC]`, the unknown cluster would
        parse past RAW_FILENAME_PATTERN, get through redaction + sweep,
        then crash on _output_filename's lookup. The crash propagates
        out of emit_batch's loop, losing the batch log. Restricting the
        regex catches the bad letter before any I/O.
        """
        payload = _minimal_raw_payload()
        # Manually construct the bad filename (helper rejects unknown cluster
        # via type system, this is the adversarial case)
        raw_path = tmp_path / "run_999999999_cluster_D.json"
        raw_path.write_text(json.dumps(payload), encoding="utf-8")
        fixture_dir = tmp_path / "fixtures"
        fixture_dir.mkdir()

        # Must not raise; must bucket as malformed_input
        result = emit_single(raw_path, fixture_dir, seen_basenames=set())

        assert result.bucket == "malformed_input"
        assert "filename does not match convention" in result.malformed_reason
        assert list(fixture_dir.iterdir()) == [], (
            "malformed-input must not write any file"
        )

    # ----- Clean-payload smoke (positive control for the sweep) ----------

    def test_clean_payload_emits_successfully(self, tmp_path: Path):
        """Positive control: no credentials → fixture emitted, no fail-close."""
        payload = _minimal_raw_payload()
        raw_path = _write_raw(tmp_path, payload, run_id=1005)
        fixture_dir = tmp_path / "fixtures"
        fixture_dir.mkdir()

        result = emit_single(raw_path, fixture_dir, seen_basenames=set())

        assert result.bucket == "emitted"
        assert result.fixture_path is not None
        assert result.fixture_path.exists()
        assert result.fixture_bytes is not None
        assert result.fixture_bytes > 0


# ===========================================================================
# TestPipelineGuards — collision, depth, determinism, version-pin, log hygiene
# ===========================================================================

class TestPipelineGuards:
    """9-case suite: M6, M7, M8, M9, M10, M12, M13 + DA-4 + batch-log hygiene."""

    # ----- M6: skip DA-2 _fixture_metadata collision check ---------------

    def test_collision_raises(self, tmp_path: Path):
        """M6 catcher: raw payload with pre-existing `_fixture_metadata` key."""
        payload = _minimal_raw_payload()
        payload["_fixture_metadata"] = {"adversarial": "shadows real metadata"}
        raw_path = _write_raw(tmp_path, payload, run_id=2001)
        fixture_dir = tmp_path / "fixtures"
        fixture_dir.mkdir()

        result = emit_single(raw_path, fixture_dir, seen_basenames=set())

        assert result.bucket == "malformed_input"
        assert "_fixture_metadata" in result.malformed_reason
        assert list(fixture_dir.iterdir()) == []

    # ----- M7: skip DA-6 basename collision check ------------------------

    def test_duplicate_basename_raises(self, tmp_path: Path):
        """M7 catcher: two raws map to the same fixture basename.

        Triggered here by two raws with the same run_id+cluster (the
        basename pattern doesn't distinguish them).
        """
        a_dir = tmp_path / "a"
        b_dir = tmp_path / "b"
        a_dir.mkdir()
        b_dir.mkdir()
        raw1 = a_dir / "run_2002_cluster_A.json"
        raw2 = b_dir / "run_2002_cluster_A.json"
        raw1.write_text(json.dumps(_minimal_raw_payload()), encoding="utf-8")
        raw2.write_text(json.dumps(_minimal_raw_payload()), encoding="utf-8")
        fixture_dir = tmp_path / "fixtures"
        fixture_dir.mkdir()

        seen: set = set()
        r1 = emit_single(raw1, fixture_dir, seen)
        r2 = emit_single(raw2, fixture_dir, seen)

        assert r1.bucket == "emitted"
        assert r2.bucket == "malformed_input"
        assert "basename collision" in r2.malformed_reason

    # ----- M8: hardcode redact_schema_version instead of importing -------

    def test_redact_schema_version_matches_module_constant(
        self, tmp_path: Path
    ):
        """M8 catcher: fixture metadata.redact_schema_version equals live
        REDACT_SCHEMA_VERSION imported from redact.py.

        Field-name discipline (G4-1): the field name matches the source
        constant name exactly so the three coexisting version series
        (redact schema, label schema, gate-spec) are never ambiguous.
        Renamed from `redactor_version` in the Commit-A amendment.
        """
        payload = _minimal_raw_payload()
        raw_path = _write_raw(tmp_path, payload, run_id=2003)
        fixture_dir = tmp_path / "fixtures"
        fixture_dir.mkdir()

        result = emit_single(raw_path, fixture_dir, seen_basenames=set())
        assert result.bucket == "emitted"

        fixture = json.loads(result.fixture_path.read_text())
        assert (
            fixture["_fixture_metadata"]["redact_schema_version"]
            == REDACT_SCHEMA_VERSION
        ), (
            "fixture redact_schema_version must equal the live module "
            "constant; drift indicates someone hardcoded it instead of "
            "importing"
        )

    # ----- M9: embed full scratch path in metadata -----------------------

    def test_no_full_paths_in_metadata(self, tmp_path: Path):
        """M9 catcher: scan emitted metadata for path-shaped strings.

        Regex catches `/Users/...`, `/home/...`, `~/...`, `C:\\...`,
        `/tmp/...`, `/var/folders/...`. If a future maintainer
        "simplifies" `source_basename` to store the full path, this test
        fires.
        """
        payload = _minimal_raw_payload()
        raw_path = _write_raw(tmp_path, payload, run_id=2004)
        fixture_dir = tmp_path / "fixtures"
        fixture_dir.mkdir()

        result = emit_single(raw_path, fixture_dir, seen_basenames=set())
        assert result.bucket == "emitted"

        meta = json.loads(result.fixture_path.read_text())["_fixture_metadata"]
        meta_text = json.dumps(meta)
        forbidden = re.compile(
            r"/Users/|/home/|~/|^[A-Z]:\\|/tmp/|/var/folders/"
        )
        match = forbidden.search(meta_text)
        assert match is None, (
            f"path-shaped string found in _fixture_metadata: "
            f"{match.group()!r} in {meta_text!r}"
        )

    # ----- M10: sort_keys=False breaks determinism ------------------------

    def test_two_regenerations_byte_identical(self, tmp_path: Path):
        """M10 catcher + G8-1 determinism contract."""
        payload = _minimal_raw_payload()
        raw_path = _write_raw(tmp_path, payload, run_id=2005)
        fixture_dir = tmp_path / "fixtures"
        fixture_dir.mkdir()

        r1 = emit_single(raw_path, fixture_dir, seen_basenames=set())
        assert r1.bucket == "emitted"
        first = r1.fixture_path.read_bytes()

        r2 = emit_single(raw_path, fixture_dir, seen_basenames=set())
        assert r2.bucket == "emitted"
        second = r2.fixture_path.read_bytes()

        assert first == second, (
            "two regenerations of unchanged input produced different bytes — "
            "determinism contract violated (G8-1)"
        )

    # ----- M12: pathological depth handled deterministically -------------

    def test_pathological_depth_handled_deterministically(
        self, tmp_path: Path
    ):
        """M12 catcher: 5K-deep nested dict.

        MUST terminate without raising uncaught RecursionError. Either
        bucket is acceptable — the contract is "no uncaught raise":
          - 'malformed_input' (upstream `_redact_node` hit recursion limit)
          - 'emitted' (only possible if depth ≤ sys.getrecursionlimit)

        At depth 5000 (well above default recursion limit ~1000), this
        should bucket as malformed_input via the per-payload boundary.

        Note on the sys.setrecursionlimit() bump: CPython's recursion-
        limit behavior for json.dumps differs across 3.11 and 3.14 —
        on 3.11 the encoder hits the default limit (~1000) when
        serializing a depth-5000 fixture, on 3.14 it does not. The
        bump is scoped to ONLY the _write_raw (json.dumps) fixture-
        build step so the redactor under test still faces the
        production default recursion limit. The thing under test —
        emit_single's per-payload boundary catching _redact_node's
        recursion — is exercised under the realistic limit, not a
        raised one.
        """
        deep: Any = "leaf"
        for _ in range(5000):
            deep = {"x": deep}
        payload = _minimal_raw_payload()
        payload["data"]["pathological"] = deep

        _saved_limit = sys.getrecursionlimit()
        sys.setrecursionlimit(20000)
        try:
            raw_path = _write_raw(tmp_path, payload, run_id=2006)
        finally:
            sys.setrecursionlimit(_saved_limit)

        fixture_dir = tmp_path / "fixtures"
        fixture_dir.mkdir()

        try:
            result = emit_single(raw_path, fixture_dir, seen_basenames=set())
        except RecursionError:
            pytest.fail(
                "emit_single raised uncaught RecursionError; the per-payload "
                "boundary must catch upstream `_redact_node` recursion limit"
            )

        assert result.bucket in ("emitted", "malformed_input")
        if result.bucket == "malformed_input":
            assert "recursion" in result.malformed_reason.lower()

    # ----- M13 (ADD-2): empty payload contract validation ---------------

    def test_empty_payload_rejected_not_emitted(self, tmp_path: Path):
        """M13 catcher: empty `{}` after redaction → no `data.run_steps`
        → malformed_input bucket, NO file.

        Reverses the Gate-2 stress projection. Emitting a degenerate
        fixture would manufacture a landmine for Commit B's label
        repoint (consumers expect non-empty run_steps).
        """
        payload: dict = {}
        raw_path = _write_raw(tmp_path, payload, run_id=2007)
        fixture_dir = tmp_path / "fixtures"
        fixture_dir.mkdir()

        result = emit_single(raw_path, fixture_dir, seen_basenames=set())

        assert result.bucket == "malformed_input"
        assert "data.run_steps" in result.malformed_reason
        assert list(fixture_dir.iterdir()) == []

    # ----- DA-4: orphan refusal ------------------------------------------

    def test_orphan_tmp_refuses_to_proceed(self, tmp_path: Path):
        """DA-4 catcher: stale .tmp orphan blocks batch startup.

        Operational integrity guard (NOT credential protection — per
        DA-1 the orphan was sweep-clean before being written). Auto-
        deleting would mask the prior failure.
        """
        fixture_dir = tmp_path / "fixtures"
        fixture_dir.mkdir()
        (fixture_dir / "early_failure_orphaned.json.tmp").write_text(
            "stale", encoding="utf-8"
        )

        payload = _minimal_raw_payload()
        raw_path = _write_raw(tmp_path, payload, run_id=2008)

        with pytest.raises(RuntimeError, match="orphan"):
            emit_batch([raw_path], fixture_dir, batch_log_path=None)

    # ----- Batch-log metadata-only inheritance ---------------------------

    def test_batch_log_metadata_only_on_sentinel_fire(
        self, tmp_path: Path
    ):
        """Batch log inherits redact.py §5.6 item #6: SentinelEvent
        fields ONLY (pattern_name, field_path, offset, length). NEVER
        matched values, NEVER `str(exc)`.
        """
        jwt_literal = (
            "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJsZWFrIn0.never_in_logs_marker"
        )
        payload = _minimal_raw_payload()
        payload["data"]["extra"] = {"x": [jwt_literal]}
        raw_path = _write_raw(tmp_path, payload, run_id=2009)
        fixture_dir = tmp_path / "fixtures"
        fixture_dir.mkdir()
        batch_log = tmp_path / "_batch.json"

        emit_batch([raw_path], fixture_dir, batch_log_path=batch_log)

        log_text = batch_log.read_text()
        # Negative assertions: no part of the matched value leaks
        assert "never_in_logs_marker" not in log_text, (
            "matched credential value leaked into batch log"
        )
        # JWT prefix `eyJhbGc` is a recognizable JWT marker; must not
        # appear in batch log even if the rest was truncated
        assert "eyJhbGc" not in log_text, (
            "credential prefix leaked into batch log"
        )

        # Positive: metadata fields present
        log = json.loads(log_text)
        assert log["sentinel_fired_count"] == 1
        assert log["sentinel_fired"][0]["pattern_name"] == "jwt"
        assert "offset" in log["sentinel_fired"][0]
        assert "length" in log["sentinel_fired"][0]


# ===========================================================================
# TestEmittedFixtureContract — output shape consumers will rely on
# ===========================================================================

class TestEmittedFixtureContract:
    """Output contract that downstream consumers (orchestrator tests,
    Commit B's fixture_loader, future backtest harness) will depend on."""

    def test_emitted_fixture_root_shape(self, tmp_path: Path):
        """Emitted fixture is envelope-faithful (Q5A):
        `{_fixture_metadata, status, data}` at root, `data.run_steps`
        non-empty, `_fixture_metadata` carries exactly 8 known fields."""
        payload = _minimal_raw_payload()
        raw_path = _write_raw(tmp_path, payload, run_id=3001)
        fixture_dir = tmp_path / "fixtures"
        fixture_dir.mkdir()

        result = emit_single(raw_path, fixture_dir, seen_basenames=set())
        assert result.bucket == "emitted"

        fixture = json.loads(result.fixture_path.read_text())

        # Envelope-faithful: status + data at root, alongside metadata
        assert "_fixture_metadata" in fixture
        assert "data" in fixture
        assert "status" in fixture, "input had status, output must preserve it"

        # _fixture_metadata exactly 8 fields (CS-2 cap)
        expected_meta_keys = {
            "source_run_id",
            "source_cluster",
            "source_basename",
            "source_size_bytes",
            "content_sha256",
            "redact_schema_version",
            "email_substitution_count",
            "retained_step_count",
        }
        assert set(fixture["_fixture_metadata"].keys()) == expected_meta_keys

        # data.run_steps non-empty (ADD-2 post-redaction contract)
        assert fixture["data"]["run_steps"], "run_steps must be non-empty"

    # ----- Size-envelope contract (Commit-A amendment, verification ask #1)
    #       Extended to all 7 fixtures in Commit B amendment (C3).

    @pytest.mark.parametrize(
        "basename,band", sorted(EXPECTED_BANDS.items())
    )
    def test_committed_fixtures_within_size_envelope(
        self, basename: str, band: tuple[int, int]
    ):
        """All 7 committed early-failure fixtures stay within their
        documented ±20% size band.

        Commit-A established this contract for the 3 pipeline-emitted
        fixtures (run_ids 485850628, 487313189, 484675412); the 4
        hand-sanitized fixtures of that era were out of scope.

        Commit B brings the remaining 4 fixtures under the same
        contract by re-emitting them via the pipeline (B1 ratification
        condition (ii) satisfied). The single source of truth is
        `EXPECTED_BANDS` at module top; see
        `test_band_table_covers_all_committed_fixtures` for the
        set-equality guard that prevents accretion drift.

        Bands are ±20% of the actual byte count at emission time.
        Drift outside the band signals either a redactor behavior
        change (which should bump REDACT_SCHEMA_VERSION) or a
        payload-shape change in the upstream raw scratch (which
        should be a deliberate decision, not a silent fixture growth).

        STATIC contract — reads the committed file directly. Pairs
        with the LIVE-producer idempotency coverage in
        `TestRedactorPipelineIdempotency`.
        """
        band_low, band_high = band
        fixture_path = FIXTURES_DIR / basename
        assert fixture_path.exists(), (
            f"expected committed fixture missing: {fixture_path}"
        )
        size = fixture_path.stat().st_size
        assert band_low <= size <= band_high, (
            f"{basename} size {size} bytes outside ±20% envelope "
            f"[{band_low}, {band_high}]. If this is intentional, "
            f"update the band AND explain in the commit message."
        )

    def test_band_table_covers_all_committed_fixtures(self):
        """Set-equality guard — every `early_failure_*.json` under
        `FIXTURES_DIR` must have a corresponding row in
        `EXPECTED_BANDS`. Adding a fixture without a band row would
        leave the new fixture uncovered by the size-envelope contract;
        this test makes the accretion path conscious.
        """
        committed = {
            p.name for p in FIXTURES_DIR.glob("early_failure_*.json")
        }
        banded = set(EXPECTED_BANDS.keys())
        missing_from_table = committed - banded
        stale_in_table = banded - committed
        assert not missing_from_table, (
            f"new committed fixtures with no EXPECTED_BANDS row: "
            f"{sorted(missing_from_table)}. Add a (low, high) band "
            f"to EXPECTED_BANDS or remove the fixture."
        )
        assert not stale_in_table, (
            f"EXPECTED_BANDS rows with no committed fixture: "
            f"{sorted(stale_in_table)}. Remove the stale row "
            f"or restore the fixture."
        )


class TestRedactorPipelineIdempotency:
    """N2: live-producer raw≡fixture round-trip contract.

    The committed early-failure fixtures are the CACHED outputs of
    `emit_single(raw, ...)`. Re-running the pipeline on the SAME raw
    input must produce a BYTE-IDENTICAL fixture, locking the
    determinism property that lets us trust the committed file as
    the canonical artifact downstream consumers depend on.

    Asymmetry vs `TestEmittedFixtureContract` (both intentional, both
    required — neither sufficient alone):
      - Static (TestEmittedFixtureContract): asserts the committed
        fixture meets the SHAPE + SIZE contract. Runs in clean-clone
        CI without scratch inputs. Catches drift in committed bytes.
        Cannot catch producer drift if the bytes happen to stay in band.
      - Live (this class): re-runs the producer and asserts the bytes
        are stable across emissions. Requires `~/scratch/triage-day4/`
        with raw inputs present; pytest.skip when absent. Catches
        producer drift (non-stable dict ordering, inadvertent timestamp
        inclusion, regex-substitution non-determinism) even when the
        shape + size contracts still hold.

    Commit B (D4 review, Kumar 2026-06-11) restored this class after
    its silent drop from the Commit-B implementation manifest.
    """

    @pytest.mark.parametrize(
        "raw_basename,fixture_basename", sorted(RAW_TO_FIXTURE.items())
    )
    def test_re_emission_byte_identical_to_committed(
        self, raw_basename: str, fixture_basename: str, tmp_path: Path
    ):
        raw_path = SCRATCH_DIR / raw_basename
        if not raw_path.exists():
            pytest.skip(
                f"raw input {raw_path} not present "
                f"(clean-clone CI environment without "
                f"~/scratch/triage-day4/ corpus)"
            )
        committed_path = FIXTURES_DIR / fixture_basename
        assert committed_path.exists(), (
            f"committed fixture missing: {committed_path}"
        )

        out_dir = tmp_path / "fixtures"
        out_dir.mkdir()
        result = emit_single(raw_path, out_dir, seen_basenames=set())
        assert result.bucket == "emitted", (
            f"emission failed for {raw_basename}: bucket={result.bucket}"
        )

        re_emitted_bytes = result.fixture_path.read_bytes()
        committed_bytes = committed_path.read_bytes()
        assert re_emitted_bytes == committed_bytes, (
            f"raw≡fixture contract violated: {raw_basename} → "
            f"re-emitted ({len(re_emitted_bytes)} bytes) does not "
            f"byte-match committed {fixture_basename} "
            f"({len(committed_bytes)} bytes). Either the redactor "
            f"changed (bump REDACT_SCHEMA_VERSION + regenerate all "
            f"fixtures) or the committed fixture drifted (regenerate "
            f"via `redactor_pipeline.py` and commit the new bytes)."
        )


# ===========================================================================
# TestModuleHelpers — smoke tests for free functions
# ===========================================================================

class TestModuleHelpers:
    """Smoke tests for the small free functions used by the pipeline."""

    def test_iter_string_leaves_iterative_handles_deep_dict(self):
        """The walk is iterative (no recursion limit). 10K-deep
        list-of-dicts terminates without RecursionError."""
        node: Any = "leaf"
        for _ in range(10_000):
            node = [{"x": node}]
        leaves = list(_iter_string_leaves(node))
        assert leaves == ["leaf"]

    def test_iter_string_leaves_yields_values_not_keys(self):
        """Yields VALUES; KEYS are intentionally excluded — the
        serialized-text sweep covers them."""
        leaves = list(_iter_string_leaves(
            {"key_name_str": "value_str",
             "int_key": 42,
             "list_v": ["a", "b"]}
        ))
        assert "key_name_str" not in leaves  # keys excluded
        assert "value_str" in leaves
        assert "a" in leaves
        assert "b" in leaves
        assert 42 not in leaves  # ints excluded

    def test_output_filename_uses_cluster_pattern_mapping(self):
        """Cluster A → manifest_parse, B → pr_schema_missing, C → dmf_failure."""
        for cluster, expected_pattern in CLUSTER_TO_PATTERN.items():
            name = _output_filename({
                "source_cluster": cluster,
                "source_run_id": 12345,
            })
            assert name == f"early_failure_{expected_pattern}_12345.json"

    def test_output_filename_rejects_unknown_cluster(self):
        with pytest.raises(ValueError, match="no output-filename pattern"):
            _output_filename({"source_cluster": "Z", "source_run_id": 1})

    def test_audit_passes_on_clean_payload(self):
        """Positive control: clean payload → audit returns without raising."""
        clean = {"data": {"run_steps": [{"message": "harmless"}]}}
        clean_text = json.dumps(clean)
        # Should not raise
        _audit_fixture_for_credentials(clean, clean_text)
