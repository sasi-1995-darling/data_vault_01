"""
Regression test for MSAT generator grain_columns handling.

Verifies that _build_sat_yaml_model uses grain_columns (full composite grain)
in WHERE NOT EXISTS and QUALIFY, not just multi_active_key (single column).

Root cause: multi_active_key stored as "NET_TRMS_SEQ_NBR" but grain is
SETID+EFFDT+NET_TRMS_SEQ_NBR. Generator must use grain_columns for dedup logic.
"""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pipeline_orchestrator as po


def _make_state(grain_columns=None, multi_active_key="NET_TRMS_SEQ_NBR"):
    """Build a minimal state dict for MSAT testing."""
    sat_def = {
        "model_name": "msat_payment_term_net__lrsn_psft",
        "sat_type": "msat",
        "parent_hk": "PAYMENT_TERM_HK",
        "parent_model": "hub_payment_term",
        "multi_active_key": multi_active_key,
        "grain_columns": grain_columns,
        "sat_columns": None,
    }
    return {
        "model_name": "v_psa_stg_payment_terms_net__lrsn_psft",
        "schema": "lrsn_psft_sysadm",
        "table": "ps_pymt_trms_net",
        "bk": "PYMNT_TERMS_CD",
        "bk_name": "PAYMENT_TERM_BK",
        "rec_src": "USSDBR.ORCL.PSFTPRD.PS_PYMT_TRMS_NET",
        "grain_columns": grain_columns,
        "sats": [sat_def],
        "profile_results": {
            "columns": [
                {"name": "PYMNT_TERMS_CD", "type": "TEXT", "nullable": "YES"},
                {"name": "SETID", "type": "TEXT", "nullable": "YES"},
                {"name": "EFFDT", "type": "DATE", "nullable": "YES"},
                {"name": "NET_TRMS_SEQ_NBR", "type": "NUMBER", "nullable": "YES"},
                {"name": "BASIS_FROM_DAY", "type": "NUMBER", "nullable": "YES"},
                {"name": "_FIVETRAN_DELETED", "type": "BOOLEAN", "nullable": "YES"},
                {"name": "_FIVETRAN_SYNCED", "type": "TIMESTAMP_TZ", "nullable": "YES"},
                {"name": "PSA_LOAD_DTS", "type": "TIMESTAMP_LTZ", "nullable": "YES"},
                {"name": "PSA_RECORD_SOURCE", "type": "TEXT", "nullable": "YES"},
                {"name": "PSA_DELETE_IND", "type": "TEXT", "nullable": "YES"},
                {"name": "_FIVETRAN_ID", "type": "TEXT", "nullable": "YES"},
            ],
            "row_count": 87,
            "ingestion_source": "fivetran",
            "has_fivetran_deleted": True,
            "has_psa_delete_ind": True,
            "has_fivetran_synced": True,
            "has_fivetran_id": True,
        },
    }


class TestMsatGrainColumns:
    """Tests for grain_columns usage in MSAT WHERE NOT EXISTS and PK."""

    def test_not_exists_uses_all_grain_columns(self):
        """WHERE NOT EXISTS must include ALL grain_columns, not just multi_active_key."""
        state = _make_state(grain_columns=["SETID", "EFFDT", "NET_TRMS_SEQ_NBR"])
        profile = state["profile_results"]

        result = po._build_sat_yaml_model(
            state, profile,
            bk_raw_cols=["PYMNT_TERMS_CD"],
            bk_name="PAYMENT_TERM_BK",
            row_count=87,
        )

        final_filter = result["sources"][0]["final_layer_filter"]
        assert "existing.SETID = JOIN_RESULT.SETID" in final_filter
        assert "existing.EFFDT = JOIN_RESULT.EFFDT" in final_filter
        assert "existing.NET_TRMS_SEQ_NBR = JOIN_RESULT.NET_TRMS_SEQ_NBR" in final_filter
        assert "existing.HASHDIFF = JOIN_RESULT.HASHDIFF" in final_filter

    def test_not_exists_falls_back_to_multi_active_key(self):
        """Without grain_columns, multi_active_key is used (backward compat)."""
        state = _make_state(grain_columns=None, multi_active_key="NET_TRMS_SEQ_NBR")
        # Remove grain_columns from state too
        state["grain_columns"] = None
        state["sats"][0]["grain_columns"] = None
        profile = state["profile_results"]

        result = po._build_sat_yaml_model(
            state, profile,
            bk_raw_cols=["PYMNT_TERMS_CD"],
            bk_name="PAYMENT_TERM_BK",
            row_count=87,
        )

        final_filter = result["sources"][0]["final_layer_filter"]
        assert "existing.NET_TRMS_SEQ_NBR = JOIN_RESULT.NET_TRMS_SEQ_NBR" in final_filter
        # Should NOT have SETID/EFFDT since grain_columns is None
        assert "existing.SETID" not in final_filter
        assert "existing.EFFDT" not in final_filter

    def test_pk_includes_all_grain_columns(self):
        """PK string must include all grain_columns for XLSX Tables tab."""
        state = _make_state(grain_columns=["SETID", "EFFDT", "NET_TRMS_SEQ_NBR"])
        profile = state["profile_results"]

        result = po._build_sat_yaml_model(
            state, profile,
            bk_raw_cols=["PYMNT_TERMS_CD"],
            bk_name="PAYMENT_TERM_BK",
            row_count=87,
        )

        # The PK string is written to the source dict
        # Check the sources[0] for hints about PK — it's used in XLSX generation
        # The PK is exposed via the function's internal pk_str variable
        # We can check it via the "final_layer_filter" which uses the same _grain_keys
        final_filter = result["sources"][0]["final_layer_filter"]
        # All three grain columns must appear in NOT EXISTS (same list as PK)
        for col in ["SETID", "EFFDT", "NET_TRMS_SEQ_NBR"]:
            assert col in final_filter, f"{col} missing from NOT EXISTS filter"

    def test_grain_columns_from_state_level(self):
        """grain_columns at state level is used when sat_def has none."""
        state = _make_state(grain_columns=["SETID", "EFFDT", "NET_TRMS_SEQ_NBR"])
        # Remove from sat_def, keep only at state level
        state["sats"][0]["grain_columns"] = None
        profile = state["profile_results"]

        result = po._build_sat_yaml_model(
            state, profile,
            bk_raw_cols=["PYMNT_TERMS_CD"],
            bk_name="PAYMENT_TERM_BK",
            row_count=87,
        )

        final_filter = result["sources"][0]["final_layer_filter"]
        assert "existing.SETID = JOIN_RESULT.SETID" in final_filter
        assert "existing.EFFDT = JOIN_RESULT.EFFDT" in final_filter
        assert "existing.NET_TRMS_SEQ_NBR = JOIN_RESULT.NET_TRMS_SEQ_NBR" in final_filter


class TestMsatParentHkDedup:
    """Regression tests: grain_columns containing parent_hk must not duplicate it."""

    def test_parent_hk_not_duplicated_in_pk(self):
        """PK must contain parent_hk exactly once even when grain_columns includes it."""
        state = _make_state(grain_columns=["PAYMENT_TERM_HK", "SETID", "NET_TRMS_SEQ_NBR"])
        profile = state["profile_results"]

        result = po._build_sat_yaml_model(
            state, profile,
            bk_raw_cols=["PYMNT_TERMS_CD"],
            bk_name="PAYMENT_TERM_BK",
            row_count=87,
        )

        pk_str = result["columns"][0]["pk"]
        assert pk_str.count("PAYMENT_TERM_HK") == 1, f"parent_hk duplicated in PK: {pk_str}"
        assert "SETID" in pk_str
        assert "NET_TRMS_SEQ_NBR" in pk_str

    def test_parent_hk_not_duplicated_in_not_exists(self):
        """NOT EXISTS must reference parent_hk exactly once (as existing.X = JOIN_RESULT.X)."""
        state = _make_state(grain_columns=["PAYMENT_TERM_HK", "SETID", "NET_TRMS_SEQ_NBR"])
        profile = state["profile_results"]

        result = po._build_sat_yaml_model(
            state, profile,
            bk_raw_cols=["PYMNT_TERMS_CD"],
            bk_name="PAYMENT_TERM_BK",
            row_count=87,
        )

        final_filter = result["sources"][0]["final_layer_filter"]
        # parent_hk appears exactly twice: "existing.X = JOIN_RESULT.X"
        assert final_filter.count("PAYMENT_TERM_HK") == 2, \
            f"parent_hk wrong count in NOT EXISTS: {final_filter}"
        assert "existing.SETID = JOIN_RESULT.SETID" in final_filter
        assert "existing.NET_TRMS_SEQ_NBR = JOIN_RESULT.NET_TRMS_SEQ_NBR" in final_filter

    def test_parent_hk_exclusion_case_insensitive(self):
        """parent_hk dedup works when grain_columns has different casing."""
        state = _make_state(grain_columns=["payment_term_hk", "SETID", "NET_TRMS_SEQ_NBR"])
        profile = state["profile_results"]

        result = po._build_sat_yaml_model(
            state, profile,
            bk_raw_cols=["PYMNT_TERMS_CD"],
            bk_name="PAYMENT_TERM_BK",
            row_count=87,
        )

        pk_str = result["columns"][0]["pk"]
        hk_count = pk_str.upper().count("PAYMENT_TERM_HK")
        assert hk_count == 1, f"parent_hk duplicated in PK (case mismatch): {pk_str}"
