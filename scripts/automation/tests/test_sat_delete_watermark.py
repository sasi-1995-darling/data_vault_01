"""
test_sat_delete_watermark.py — two-clock-aware SAT incremental watermark.

Two-clock hazard: for SNP GLUE, LOAD_DTS = IFF(PSA_DELETE_IND='Y', PSA_LOAD_DTS
(batch time), <GLCHANGETIME event time>) — a mixed clock, so soft-delete rows can
carry batch time exceeding event time, inflating max(load_dts) and silently
excluding later live records from the incremental window. The fix scopes the
watermark subquery to live rows and floors it.

CRITICAL: the fix is gated on the two-clock DERIVATION (SNP GLUE, or a custom
LOAD_DTS column + PSA_DELETE_IND), NOT on the mere presence of a PSA_DELETE_IND
column — Fivetran/default sources materialise PSA_DELETE_IND on a uniform clock
and must be excluded (else the scope only lowers the watermark -> re-scans).

Covers the generator (_build_sat_yaml_model) and the J6 reviewer check.
"""
import sys
from pathlib import Path

import pytest

SCRIPT_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = SCRIPT_DIR / "src"
sys.path.insert(0, str(SCRIPT_DIR))
sys.path.insert(0, str(SRC_DIR))

import pipeline_orchestrator as po
from code_review_config import FileStatus
from code_reviewer import Severity, check_sat_delete_scoped_watermark, CHECK_REGISTRY
from build import SAT_INCREMENTAL_PATTERN  # single source of truth for the double-inject guard

_SAT_DEF = {"sat_type": "sat", "parent_hk": "DELIVERY_HK", "parent_model": "hub_delivery"}
_FLOOR = "coalesce(dateadd('HOUR',-1,max(load_dts)), '1900-01-01'::timestamp)"


def _profile(ingestion="snp_glue", has_delete=True):
    cols = [{"name": "VBELN", "type": "TEXT"}, {"name": "LOAD_DTS", "type": "TIMESTAMP_NTZ"}]
    if has_delete:
        cols.append({"name": "PSA_DELETE_IND", "type": "TEXT"})
    return {"columns": cols, "ingestion_source": ingestion}


def _src_filter(row_count, ingestion="snp_glue", has_delete=True, load_dts_col=None):
    state = {"model_name": "v", "rec_src": "USOHNO.SAP.ECCPRD.DELIVERY"}
    if load_dts_col:
        state["load_dts_column"] = load_dts_col
    model = po._build_sat_yaml_model(
        state, _profile(ingestion, has_delete), ["VBELN"], "DELIVERY_BK", row_count, _SAT_DEF
    )
    return model["sources"][0]["source_layer_filter"]


# ── Generator: two-clock gate ───────────────────────────────────────────────────

class TestGeneratorTwoClockGate:
    """The scope+floor is emitted only for two-clock sources (SNP GLUE / custom LOAD_DTS)."""

    def test_snp_glue_normal_scoped_and_floored(self):
        f = _src_filter(10_000_000, "snp_glue")
        assert "coalesce(PSA_DELETE_IND,'N') = 'N'" in f
        assert _FLOOR in f
        assert "where rec_src" not in f  # <50M is global (single-REC_SRC SAT)

    def test_snp_glue_large_composes_with_rec_src(self):
        f = _src_filter(60_000_000, "snp_glue")
        assert "where rec_src = 'USOHNO.SAP.ECCPRD.DELIVERY'" in f
        assert "and coalesce(PSA_DELETE_IND,'N') = 'N'" in f
        assert _FLOOR in f

    def test_custom_load_dts_with_delete_is_scoped(self):
        # Custom LOAD_DTS column + PSA_DELETE_IND -> the derivation branches -> two-clock.
        f = _src_filter(10_000_000, "custom", has_delete=True, load_dts_col="MODIFIED_DT")
        assert "coalesce(PSA_DELETE_IND,'N') = 'N'" in f
        assert _FLOOR in f

    # ── Single-clock sources must NOT get the scope (H1 regression guard) ──

    def test_fivetran_with_psa_delete_normal_gets_no_scope(self):
        # Fivetran LOAD_DTS is uniform (_FIVETRAN_SYNCED) even with PSA_DELETE_IND.
        assert _src_filter(10_000_000, "fivetran", has_delete=True) == ""

    def test_fivetran_with_psa_delete_large_unchanged_no_scope(self):
        f = _src_filter(60_000_000, "fivetran", has_delete=True)
        assert "rec_src" in f
        assert "PSA_DELETE_IND" not in f
        assert "coalesce" not in f.lower()

    def test_custom_without_load_dts_col_gets_no_scope(self):
        # Default 'custom' LOAD_DTS = PSA_LOAD_DTS (uniform) -> single clock.
        assert _src_filter(10_000_000, "custom", has_delete=True) == ""

    def test_snp_glue_without_psa_delete_no_scope(self):
        # Defensive: no PSA_DELETE_IND column -> nothing to scope on.
        assert _src_filter(10_000_000, "snp_glue", has_delete=False) == ""

    def test_floor_present_iff_two_clock(self):
        assert "coalesce" not in _src_filter(60_000_000, "fivetran").lower()
        assert "coalesce" in _src_filter(60_000_000, "snp_glue").lower()

    def test_new_shapes_detected_by_build_regex(self):
        # Load-bearing: build.py must NOT double-inject on top of these shapes.
        for rc, ing in [(10_000_000, "snp_glue"), (60_000_000, "snp_glue"), (60_000_000, "fivetran")]:
            f = _src_filter(rc, ing)
            if f:
                assert SAT_INCREMENTAL_PATTERN.search(f), f"build.py would double-inject: {f!r}"

    def test_ge_shape_detected_by_build_regex(self):
        # #1929: existing SATs use `src.load_dts >= (...)`; build.py must detect
        # that shape too, or it double-injects a second default watermark.
        ge_block = (
            "{% if is_incremental() %}\n"
            "  where src.load_dts >= (select max(load_dts) from {{ this }})\n"
            "{% endif %}"
        )
        assert SAT_INCREMENTAL_PATTERN.search(ge_block)


# ── Reviewer check: J6 ──────────────────────────────────────────────────────────

class TestJ6Check:
    _SAT = "models/raw_vault/sat/sat_x__winn_sap.sql"

    def _sql(self, inner, extra_cols="GLCHANGETIME, PSA_DELETE_IND", op=">"):
        return (
            f"SELECT {extra_cols} FROM x\n"
            "{% if is_incremental() %}\n"
            f"  where src.load_dts {op} ({inner})\n"
            "{% endif %}"
        )

    def test_flags_snp_glue_old_shape_missing_both(self):
        sql = self._sql("select dateadd('HOUR',-1,max(load_dts)) from {{ this }}")
        out = check_sat_delete_scoped_watermark(sql, self._SAT, None, FileStatus.NEW)
        assert len(out) == 1 and out[0].check_id == "J6" and out[0].severity == Severity.FAIL
        assert "live-row scope" in out[0].message and "COALESCE floor" in out[0].message

    def test_passes_correct_shape(self):
        sql = self._sql(
            "select coalesce(dateadd('HOUR',-1,max(load_dts)),'1900-01-01'::timestamp) "
            "from {{ this }} where coalesce(PSA_DELETE_IND,'N')='N'"
        )
        assert check_sat_delete_scoped_watermark(sql, self._SAT, None, FileStatus.NEW) == []

    def test_wrong_floor_sentinel_is_flagged(self):
        # #1929: a COALESCE that floors DATEADD(...) to something other than the
        # '1900-01-01' sentinel is not the loss-safe floor -- must be flagged even
        # though the live-row scope is correct.
        sql = self._sql(
            "select coalesce(dateadd('HOUR',-1,max(load_dts)),current_timestamp()) "
            "from {{ this }} where coalesce(PSA_DELETE_IND,'N')='N'"
        )
        out = check_sat_delete_scoped_watermark(sql, self._SAT, None, FileStatus.NEW)
        assert len(out) == 1
        assert "COALESCE floor" in out[0].message      # floor missing (wrong sentinel)
        assert "live-row scope" not in out[0].message  # scope IS correct

    def test_noop_without_glchangetime_fivetran(self):
        # Fivetran SAT: PSA_DELETE_IND + watermark but NO GLCHANGETIME -> no-op (H1).
        sql = self._sql(
            "select dateadd('HOUR',-1,max(load_dts)) from {{ this }}",
            extra_cols="_FIVETRAN_SYNCED, PSA_DELETE_IND",
        )
        assert check_sat_delete_scoped_watermark(sql, self._SAT, None, FileStatus.NEW) == []

    def test_noop_without_psa_delete(self):
        sql = self._sql(
            "select dateadd('HOUR',-1,max(load_dts)) from {{ this }}",
            extra_cols="GLCHANGETIME, COL",
        )
        assert check_sat_delete_scoped_watermark(sql, self._SAT, None, FileStatus.NEW) == []

    def test_noop_without_watermark(self):
        sql = (
            "SELECT GLCHANGETIME, PSA_DELETE_IND FROM x\n{% if is_incremental() %}\n"
            " WHERE NOT EXISTS (select 1 from {{ this }})\n{% endif %}"
        )
        assert check_sat_delete_scoped_watermark(sql, self._SAT, None, FileStatus.NEW) == []

    def test_noop_non_sat_file(self):
        sql = self._sql("select dateadd('HOUR',-1,max(load_dts)) from {{ this }}")
        assert check_sat_delete_scoped_watermark(
            sql, "models/raw_vault/hub/hub_x.sql", None, FileStatus.NEW
        ) == []

    def test_detects_ge_operator(self):
        # H2: `>=` watermarks must be inspected, not skipped.
        sql = self._sql("select dateadd('HOUR',-1,max(load_dts)) from {{ this }}", op=">=")
        out = check_sat_delete_scoped_watermark(sql, self._SAT, None, FileStatus.NEW)
        assert len(out) == 1 and out[0].check_id == "J6"

    def test_inverted_scope_is_flagged(self):
        # M1: scoping to DELETES (='Y') is a bug, not a pass; presence != correctness.
        sql = self._sql(
            "select coalesce(dateadd('HOUR',-1,max(load_dts)),'1900-01-01'::timestamp) "
            "from {{ this }} where coalesce(PSA_DELETE_IND,'N')='Y'"
        )
        out = check_sat_delete_scoped_watermark(sql, self._SAT, None, FileStatus.NEW)
        assert len(out) == 1
        assert "live-row scope" in out[0].message
        assert "COALESCE floor" not in out[0].message  # floor IS present

    def test_warn_on_modified(self):
        sql = self._sql("select dateadd('HOUR',-1,max(load_dts)) from {{ this }}")
        out = check_sat_delete_scoped_watermark(sql, self._SAT, None, FileStatus.MODIFIED)
        assert out and out[0].severity == Severity.WARN

    def test_multi_source_flags_only_bad_region(self):
        # M2: two watermarks — one correct, one missing scope — flag only the bad one.
        good = (
            "select coalesce(dateadd('HOUR',-1,max(load_dts)),'1900-01-01'::timestamp) "
            "from {{ this }} where rec_src='A' and coalesce(PSA_DELETE_IND,'N')='N'"
        )
        bad = "select dateadd('HOUR',-1,max(load_dts)) from {{ this }} where rec_src='B'"
        sql = (
            "SELECT GLCHANGETIME, PSA_DELETE_IND FROM x\n"
            "{% if is_incremental() %}\n where src.load_dts > (" + good + ")\n{% endif %},\n"
            "SRC2 as ( SELECT * FROM y\n"
            "{% if is_incremental() %}\n where src.load_dts > (" + bad + ")\n{% endif %} )"
        )
        out = check_sat_delete_scoped_watermark(sql, self._SAT, None, FileStatus.NEW)
        assert len(out) == 1  # only the un-scoped region is flagged

    def test_registered_in_check_registry(self):
        assert "J6" in CHECK_REGISTRY
        assert CHECK_REGISTRY["J6"].category == "J"


# ── Contract: generator output satisfies J6 ─────────────────────────────────────

class TestGeneratorSatisfiesJ6:
    """Producer -> consumer: an SNP GLUE watermark from the generator passes J6."""

    def _embed(self, src_filter):
        return f"WITH SRC as ( SELECT GLCHANGETIME, PSA_DELETE_IND FROM x {src_filter} )"

    def test_generated_normal_snp_glue_passes_j6(self):
        sql = self._embed(_src_filter(10_000_000, "snp_glue"))
        assert check_sat_delete_scoped_watermark(
            sql, "models/raw_vault/sat/sat_x__winn_sap.sql", None, FileStatus.NEW
        ) == []

    def test_generated_large_snp_glue_passes_j6(self):
        sql = self._embed(_src_filter(60_000_000, "snp_glue"))
        assert check_sat_delete_scoped_watermark(
            sql, "models/raw_vault/sat/sat_x__winn_sap.sql", None, FileStatus.NEW
        ) == []
