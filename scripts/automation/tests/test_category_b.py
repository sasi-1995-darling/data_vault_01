#!/usr/bin/env python3
"""
test_category_b.py — Tests for Category B (HASHDIFF Formula) checks.

Covers: B1 (hashdiff_uses_nullif_concat), B2 (hashdiff_ifnull_trim_pattern),
        B3 (hashdiff_separator_pattern), B4 (hashdiff_excludes_metadata),
        B5 (hashdiff_includes_psa_delete_ind), B6 (hashdiff_includes_fivetran_deleted),
        B7 (hashdiff_ends_with_sentinel)

Each check has: 1 pass, 1 fail, 1+ edge case.

Run: .venv/bin/python3 -m pytest scripts/automation/tests/test_category_b.py -v
"""
import sys
from pathlib import Path

import pytest

SCRIPT_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = SCRIPT_DIR / "src"
sys.path.insert(0, str(SRC_DIR))

from code_reviewer import (
    Severity,
    check_hashdiff_uses_nullif_concat,
    check_hashdiff_ifnull_trim_pattern,
    check_hashdiff_separator_pattern,
    check_hashdiff_excludes_metadata,
    check_hashdiff_includes_psa_delete_ind,
    check_hashdiff_includes_fivetran_deleted,
    check_hashdiff_ends_with_sentinel,
    check_hashdiff_delete_flag_explicit_cast,
)

VPSA_PATH = "models/int_staging_views/supplier/v_psa_stg_supplier__lrsn_psft.sql"
NON_VPSA_PATH = "models/raw_vault/sat/sat_supplier__lrsn_psft.sql"

# ---------------------------------------------------------------------------
# Fixtures: real-world HASHDIFF patterns
# ---------------------------------------------------------------------------

# Standard Fivetran HASHDIFF (from v_psa_stg_supplier__lrsn_psft.sql)
HASHDIFF_FIVETRAN_PASS = """
---- LOGIC LAYER ----
, LOGIC_S as (
    SELECT
        VENDOR_ID::TEXT as SUPPLIER_BK
      , VENDOR_ID
      , VENDOR_STATUS
      , VENDOR_CLASS
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
    FROM SRC_S
)
---- FINAL LAYER ----
SELECT
        SUPPLIER_BK
      , VENDOR_ID
      , LOAD_DTS
      , _FIVETRAN_DELETED
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VENDOR_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
      , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(VENDOR_STATUS::text), '^^')
            , '||', IFNULL(TRIM(VENDOR_CLASS::text), '^^')
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^')
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^')
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
"""

# SNP GLUE HASHDIFF (no _FIVETRAN_DELETED, has PSA_DELETE_IND)
HASHDIFF_SNP_GLUE_PASS = """
, LOGIC_S as (
    SELECT
        LIFNR as SUPPLIER_BK
      , LIFNR
      , LAND1
      , NAME1
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
    FROM SRC_S
)
SELECT
      SUPPLIER_BK
    , LIFNR
    , LOAD_DTS
    , REC_SRC
    , BKCC
    , MD5_BINARY(UPPER(CONCAT_WS('||',
        COALESCE(NULLIF(TRIM(CAST(LIFNR as VARCHAR)),''), '^^')
      , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
      ))) as SUPPLIER_HK
    , MD5_BINARY(UPPER(NULLIF(CONCAT(
            IFNULL(TRIM(LAND1::text), '^^')
          , '||', IFNULL(TRIM(NAME1::text), '^^')
          , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^')
      ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
"""

# Model with a data column named LEDGER_BK (NOT a business key — edge case for B4)
HASHDIFF_WITH_DATA_BK_COLUMN = """
, LOGIC_S as (
    SELECT
        RLDNR as LEDGER_BK
      , RLDNR
      , ORIGIN_TYPE_BK
      , OBJECT_NUMBER_BK
      , PSA_DELETE_IND
    FROM SRC_S
)
SELECT
    LEDGER_BK
  , ORIGIN_TYPE_BK
  , OBJECT_NUMBER_BK
  , REC_SRC
  , BKCC
  , MD5_BINARY(UPPER(CONCAT_WS('||',
      COALESCE(NULLIF(TRIM(CAST(RLDNR as VARCHAR)),''), '^^')
    , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
    ))) as CONTROLLING_LEDGER_HK
  , MD5_BINARY(UPPER(NULLIF(CONCAT(
          IFNULL(TRIM(ORIGIN_TYPE_BK::text), '^^')
        , '||', IFNULL(TRIM(OBJECT_NUMBER_BK::text), '^^')
        , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^')
    ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
"""


# ═══════════════════════════════════════════════════════════════════════════════
# B1: hashdiff_uses_nullif_concat
# ═══════════════════════════════════════════════════════════════════════════════

class TestB1HashdiffUsesNullifConcat:
    """B1: HASHDIFF must use MD5_BINARY(UPPER(NULLIF(CONCAT(...))))."""

    def test_pass_standard_fivetran(self):
        findings = check_hashdiff_uses_nullif_concat(HASHDIFF_FIVETRAN_PASS, VPSA_PATH)
        assert findings == []

    def test_pass_standard_snp_glue(self):
        findings = check_hashdiff_uses_nullif_concat(HASHDIFF_SNP_GLUE_PASS, VPSA_PATH)
        assert findings == []

    def test_fail_missing_upper(self):
        sql = """
        , MD5_BINARY(NULLIF(CONCAT(
              IFNULL(TRIM(COL1::text), '^^')
            , '||', IFNULL(TRIM(COL2::text), '^^')
          ), '^^||^^')))  as HASHDIFF
        """
        findings = check_hashdiff_uses_nullif_concat(sql, VPSA_PATH)
        assert len(findings) >= 1
        assert any(f.check_id == "B1" for f in findings)

    def test_fail_missing_nullif(self):
        sql = """
        , MD5_BINARY(UPPER(CONCAT(
              IFNULL(TRIM(COL1::text), '^^')
            , '||', IFNULL(TRIM(COL2::text), '^^')
          )))  as HASHDIFF
        """
        findings = check_hashdiff_uses_nullif_concat(sql, VPSA_PATH)
        assert len(findings) >= 1
        assert any(f.check_id == "B1" and "NULLIF" in f.message for f in findings)

    def test_edge_skip_non_vpsa_path(self):
        """HASHDIFF checks only apply to int_staging_views/."""
        findings = check_hashdiff_uses_nullif_concat(HASHDIFF_FIVETRAN_PASS, NON_VPSA_PATH)
        assert findings == []

    def test_edge_no_hashdiff_in_file(self):
        """File without HASHDIFF should produce no findings."""
        sql = "SELECT col1, col2 FROM some_table"
        findings = check_hashdiff_uses_nullif_concat(sql, VPSA_PATH)
        assert findings == []

    def test_edge_hashdiff_passthrough(self):
        """SAT models reference HASHDIFF from stg — not a formula, just a column name."""
        sql = """
        SELECT HASHDIFF FROM {{ ref('v_psa_stg_supplier__winn_sap') }}
        """
        findings = check_hashdiff_uses_nullif_concat(sql, VPSA_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# B2: hashdiff_ifnull_trim_pattern
# ═══════════════════════════════════════════════════════════════════════════════

class TestB2HashdiffIfnullTrimPattern:
    """B2: HASHDIFF components must use IFNULL(TRIM(col::text), '^^')."""

    def test_pass_standard_pattern(self):
        findings = check_hashdiff_ifnull_trim_pattern(HASHDIFF_FIVETRAN_PASS, VPSA_PATH)
        assert findings == []

    def test_fail_uses_coalesce(self):
        sql = """
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              COALESCE(TRIM(COL1::text), '^^')
            , '||', COALESCE(TRIM(COL2::text), '^^')
          ), '^^||^^')))  as HASHDIFF
        """
        findings = check_hashdiff_ifnull_trim_pattern(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "B2"
        assert "IFNULL" in findings[0].message
        assert "COALESCE" in findings[0].message

    def test_edge_coalesce_in_hk_not_flagged(self):
        """COALESCE in HK formula (not HASHDIFF) should not trigger B2.

        HK uses COALESCE(NULLIF(TRIM(CAST(...)))), which is correct for HK.
        B2 only checks inside the HASHDIFF block.
        """
        findings = check_hashdiff_ifnull_trim_pattern(HASHDIFF_FIVETRAN_PASS, VPSA_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# B3: hashdiff_separator_pattern
# ═══════════════════════════════════════════════════════════════════════════════

class TestB3HashdiffSeparatorPattern:
    """B3: HASHDIFF uses CONCAT arguments (, '||', ) not string concat (|| '||' ||)."""

    def test_pass_standard_separators(self):
        findings = check_hashdiff_separator_pattern(HASHDIFF_FIVETRAN_PASS, VPSA_PATH)
        assert findings == []

    def test_warn_string_concatenation(self):
        sql = """
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(COL1::text), '^^') || '||' || IFNULL(TRIM(COL2::text), '^^')
          ), '^^||^^')))  as HASHDIFF
        """
        findings = check_hashdiff_separator_pattern(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "B3"
        assert findings[0].severity == Severity.WARN

    def test_edge_pipe_in_column_name_not_flagged(self):
        """Column values might contain || but that's inside TRIM, not between components."""
        findings = check_hashdiff_separator_pattern(HASHDIFF_SNP_GLUE_PASS, VPSA_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# B4: hashdiff_excludes_metadata
# ═══════════════════════════════════════════════════════════════════════════════

class TestB4HashdiffExcludesMetadata:
    """B4: HASHDIFF must NOT include HK, BK, LOAD_DTS, REC_SRC, BKCC, etc."""

    def test_pass_standard_fivetran(self):
        """Standard model: no metadata columns in HASHDIFF."""
        findings = check_hashdiff_excludes_metadata(HASHDIFF_FIVETRAN_PASS, VPSA_PATH)
        assert findings == []

    def test_fail_hk_in_hashdiff(self):
        sql = """
        , LOGIC_S as (
            SELECT VENDOR_ID::TEXT as SUPPLIER_BK
            FROM SRC_S
        )
        SELECT
          MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(VENDOR_ID as VARCHAR)),''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
          ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SUPPLIER_HK::text), '^^')
            , '||', IFNULL(TRIM(VENDOR_STATUS::text), '^^')
          ), '^^||^^')))  as HASHDIFF
        FROM JOIN_RESULT
        """
        findings = check_hashdiff_excludes_metadata(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "B4"
        assert "SUPPLIER_HK" in findings[0].message

    def test_fail_load_dts_in_hashdiff(self):
        sql = """
        , LOGIC_S as (
            SELECT VENDOR_ID::TEXT as SUPPLIER_BK
            FROM SRC_S
        )
        SELECT
          MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(VENDOR_ID as VARCHAR)),''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
          ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(VENDOR_STATUS::text), '^^')
            , '||', IFNULL(TRIM(LOAD_DTS::text), '^^')
          ), '^^||^^')))  as HASHDIFF
        FROM JOIN_RESULT
        """
        findings = check_hashdiff_excludes_metadata(sql, VPSA_PATH)
        assert len(findings) == 1
        assert "LOAD_DTS" in findings[0].message

    def test_fail_bkcc_in_hashdiff(self):
        sql = """
        , LOGIC_S as (
            SELECT VENDOR_ID::TEXT as SUPPLIER_BK
            FROM SRC_S
        )
        SELECT
          MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(VENDOR_ID as VARCHAR)),''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
          ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(VENDOR_STATUS::text), '^^')
            , '||', IFNULL(TRIM(BKCC::text), '^^')
          ), '^^||^^')))  as HASHDIFF
        FROM JOIN_RESULT
        """
        findings = check_hashdiff_excludes_metadata(sql, VPSA_PATH)
        assert len(findings) == 1
        assert "BKCC" in findings[0].message

    def test_edge_data_column_named_ledger_bk_not_flagged(self):
        """CRITICAL EDGE CASE: ORIGIN_TYPE_BK and OBJECT_NUMBER_BK are DATA columns.

        They happen to end with '_BK' but are NOT the model's business key.
        The model's BK is LEDGER_BK (aliased from RLDNR). Only LEDGER_BK should
        be excluded from HASHDIFF, not ORIGIN_TYPE_BK or OBJECT_NUMBER_BK.
        """
        findings = check_hashdiff_excludes_metadata(HASHDIFF_WITH_DATA_BK_COLUMN, VPSA_PATH)
        assert findings == [], (
            "ORIGIN_TYPE_BK and OBJECT_NUMBER_BK are data columns, not the model's BK. "
            "Only the model's own BK (LEDGER_BK, aliased via 'AS LEDGER_BK') should be excluded."
        )

    def test_edge_same_as_supplier_hk_in_hashdiff(self):
        """Another edge case: SAME_AS_SUPPLIER_HK is a DATA column, not an HK.

        From v_psa_stg_supplier_mdm_xref.sql: SAME_AS_SUPPLIER_HK is a cross-reference
        column. It happens to end with _HK but is not the model's hash key.
        """
        sql = """
        , LOGIC_S as (
            SELECT VENDOR_ID::TEXT as SUPPLIER_BK
            FROM SRC_S
        )
        SELECT
          MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(VENDOR_ID as VARCHAR)),''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
          ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SAME_AS_SUPPLIER_HK::text), '^^')
            , '||', IFNULL(TRIM(VENDOR_STATUS::text), '^^')
          ), '^^||^^')))  as HASHDIFF
        FROM JOIN_RESULT
        """
        findings = check_hashdiff_excludes_metadata(sql, VPSA_PATH)
        # SAME_AS_SUPPLIER_HK is NOT the model's own HK (SUPPLIER_HK is).
        # It's a data column that references another hub's HK — should be IN HASHDIFF.
        assert findings == [], (
            "SAME_AS_SUPPLIER_HK is a data column (cross-reference), not the model's "
            "own HK. It should be included in HASHDIFF, not flagged as excluded."
        )

    def test_edge_fivetran_synced_in_hashdiff_flagged(self):
        """_FIVETRAN_SYNCED is metadata (timestamp), not data — should be excluded."""
        sql = """
        , LOGIC_S as (
            SELECT VENDOR_ID::TEXT as SUPPLIER_BK
            FROM SRC_S
        )
        SELECT
          MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(VENDOR_ID as VARCHAR)),''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
          ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(VENDOR_STATUS::text), '^^')
            , '||', IFNULL(TRIM(_FIVETRAN_SYNCED::text), '^^')
          ), '^^||^^')))  as HASHDIFF
        FROM JOIN_RESULT
        """
        findings = check_hashdiff_excludes_metadata(sql, VPSA_PATH)
        assert len(findings) == 1
        assert "_FIVETRAN_SYNCED" in findings[0].message


# ═══════════════════════════════════════════════════════════════════════════════
# B5: hashdiff_includes_psa_delete_ind
# ═══════════════════════════════════════════════════════════════════════════════

class TestB5HashdiffIncludesPsaDeleteInd:
    """B5: PSA_DELETE_IND is DATA — must be in HASHDIFF when column exists."""

    def test_pass_psa_delete_ind_in_hashdiff(self):
        findings = check_hashdiff_includes_psa_delete_ind(HASHDIFF_FIVETRAN_PASS, VPSA_PATH)
        assert findings == []

    def test_pass_snp_glue_has_psa_delete_ind(self):
        findings = check_hashdiff_includes_psa_delete_ind(HASHDIFF_SNP_GLUE_PASS, VPSA_PATH)
        assert findings == []

    def test_fail_psa_delete_ind_missing(self):
        sql = """
        , LOGIC_S as (
            SELECT PSA_DELETE_IND FROM SRC_S
        )
        SELECT
          PSA_DELETE_IND
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(VENDOR_STATUS::text), '^^')
            , '||', IFNULL(TRIM(VENDOR_CLASS::text), '^^')
          ), '^^||^^')))  as HASHDIFF
        FROM JOIN_RESULT
        """
        findings = check_hashdiff_includes_psa_delete_ind(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "B5"
        assert "PSA_DELETE_IND" in findings[0].message

    def test_edge_no_psa_delete_ind_in_source(self):
        """If source doesn't have PSA_DELETE_IND at all, check should not fire."""
        sql = """
        SELECT
          MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(COL1::text), '^^')
          ), '^^||^^')))  as HASHDIFF
        FROM JOIN_RESULT
        """
        findings = check_hashdiff_includes_psa_delete_ind(sql, VPSA_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# B6: hashdiff_includes_fivetran_deleted
# ═══════════════════════════════════════════════════════════════════════════════

class TestB6HashdiffIncludesFivetranDeleted:
    """B6: _FIVETRAN_DELETED is DATA — must be in HASHDIFF for Fivetran sources."""

    def test_pass_fivetran_deleted_in_hashdiff(self):
        findings = check_hashdiff_includes_fivetran_deleted(HASHDIFF_FIVETRAN_PASS, VPSA_PATH)
        assert findings == []

    def test_fail_fivetran_deleted_missing(self):
        sql = """
        , LOGIC_S as (
            SELECT _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM SRC_S
        )
        SELECT
          _FIVETRAN_DELETED
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(VENDOR_STATUS::text), '^^')
            , '||', IFNULL(TRIM(VENDOR_CLASS::text), '^^')
          ), '^^||^^')))  as HASHDIFF
        FROM JOIN_RESULT
        """
        findings = check_hashdiff_includes_fivetran_deleted(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "B6"

    def test_edge_snp_glue_no_fivetran_deleted(self):
        """SNP GLUE models don't have _FIVETRAN_DELETED — check should not fire."""
        findings = check_hashdiff_includes_fivetran_deleted(HASHDIFF_SNP_GLUE_PASS, VPSA_PATH)
        assert findings == []

    def test_edge_fivetran_synced_not_confused_with_deleted(self):
        """_FIVETRAN_SYNCED is metadata (excluded by B4), _FIVETRAN_DELETED is data.

        Model has _FIVETRAN_SYNCED but not _FIVETRAN_DELETED — B6 should not fire
        because _FIVETRAN_DELETED doesn't exist in the source.
        """
        sql = """
        , LOGIC_S as (
            SELECT _FIVETRAN_SYNCED FROM SRC_S
        )
        SELECT
          MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(COL1::text), '^^')
          ), '^^||^^')))  as HASHDIFF
        FROM JOIN_RESULT
        """
        findings = check_hashdiff_includes_fivetran_deleted(sql, VPSA_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# B7: hashdiff_ends_with_sentinel
# ═══════════════════════════════════════════════════════════════════════════════

class TestB7HashdiffEndsWithSentinel:
    """B7: HASHDIFF NULLIF must close with '^^||^^' sentinel."""

    def test_pass_standard_sentinel(self):
        findings = check_hashdiff_ends_with_sentinel(HASHDIFF_FIVETRAN_PASS, VPSA_PATH)
        assert findings == []

    def test_fail_missing_sentinel(self):
        sql = """
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(COL1::text), '^^')
            , '||', IFNULL(TRIM(COL2::text), '^^')
          ), '')))  as HASHDIFF
        """
        findings = check_hashdiff_ends_with_sentinel(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "B7"
        assert findings[0].severity == Severity.FAIL

    def test_edge_sentinel_present_different_spacing(self):
        """Sentinel with different whitespace should still pass."""
        sql = """
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(COL1::text), '^^')
          ),  '^^||^^'  )))  as HASHDIFF
        """
        findings = check_hashdiff_ends_with_sentinel(sql, VPSA_PATH)
        assert findings == []

    def test_edge_no_hashdiff_no_finding(self):
        """File without HASHDIFF produces no findings."""
        sql = "SELECT col1, col2 FROM some_table"
        findings = check_hashdiff_ends_with_sentinel(sql, VPSA_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# B8: hashdiff_delete_flag_explicit_cast
# ═══════════════════════════════════════════════════════════════════════════════

class TestB8HashdiffDeleteFlagExplicitCast:
    """B8: Delete-flag columns in HASHDIFF must carry an explicit text cast.

    Complements B5/B6 (which only prove the flag NAME is present). B8 proves the
    flag carries a cast so BOOLEAN TRUE/FALSE/NULL tokenize as distinct strings.
    Runtime counterpart: tests/_vault_integrity/i_hashdiff_delete_flag_value_collapse.sql
    """

    def test_pass_fivetran_and_psa_have_cast(self):
        findings = check_hashdiff_delete_flag_explicit_cast(HASHDIFF_FIVETRAN_PASS, VPSA_PATH)
        assert findings == []

    def test_pass_snp_glue_psa_has_cast(self):
        findings = check_hashdiff_delete_flag_explicit_cast(HASHDIFF_SNP_GLUE_PASS, VPSA_PATH)
        assert findings == []

    def test_fail_fivetran_deleted_no_cast(self):
        sql = """
        SELECT
          _FIVETRAN_DELETED
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(VENDOR_STATUS::text), '^^')
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED), '^^')
          ), '^^||^^')))  as HASHDIFF
        FROM JOIN_RESULT
        """
        findings = check_hashdiff_delete_flag_explicit_cast(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "B8"
        assert findings[0].severity == Severity.FAIL
        assert "_FIVETRAN_DELETED" in findings[0].message

    def test_fail_psa_delete_ind_no_cast(self):
        sql = """
        SELECT
          MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(NAME1::text), '^^')
            , '||', IFNULL(TRIM(PSA_DELETE_IND), '^^')
          ), '^^||^^')))  as HASHDIFF
        FROM JOIN_RESULT
        """
        findings = check_hashdiff_delete_flag_explicit_cast(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "B8"
        assert "PSA_DELETE_IND" in findings[0].message

    def test_fail_gldelflag_no_cast(self):
        sql = """
        SELECT
          MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(NAME1::text), '^^')
            , '||', IFNULL(TRIM(GLDELFLAG), '^^')
          ), '^^||^^')))  as HASHDIFF
        FROM JOIN_RESULT
        """
        findings = check_hashdiff_delete_flag_explicit_cast(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "B8"
        assert "GLDELFLAG" in findings[0].message

    def test_pass_cast_function_form_accepted(self):
        """CAST(col AS VARCHAR) is an equivalent explicit cast — must not over-fire."""
        sql = """
        SELECT
          MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(VENDOR_STATUS::text), '^^')
            , '||', IFNULL(TRIM(CAST(_FIVETRAN_DELETED AS VARCHAR)), '^^')
          ), '^^||^^')))  as HASHDIFF
        FROM JOIN_RESULT
        """
        findings = check_hashdiff_delete_flag_explicit_cast(sql, VPSA_PATH)
        assert findings == []

    def test_fail_non_text_shorthand_cast_rejected(self):
        """Review #1(a): a non-text shorthand cast (::int) is not a text cast — B8 fires."""
        sql = """
        SELECT
          MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(NAME1::text), '^^')
            , '||', IFNULL(TRIM(PSA_DELETE_IND::int), '^^')
          ), '^^||^^')))  as HASHDIFF
        FROM JOIN_RESULT
        """
        findings = check_hashdiff_delete_flag_explicit_cast(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "B8"

    def test_pass_qualified_cast_function_accepted(self):
        """Review #1(b): CAST with a table qualifier before the column must not over-fire."""
        sql = """
        SELECT
          MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(NAME1::text), '^^')
            , '||', IFNULL(TRIM(CAST(LOGIC_S.PSA_DELETE_IND AS VARCHAR)), '^^')
          ), '^^||^^')))  as HASHDIFF
        FROM JOIN_RESULT
        """
        findings = check_hashdiff_delete_flag_explicit_cast(sql, VPSA_PATH)
        assert findings == []

    def test_fail_cast_function_non_text_type_rejected(self):
        """A CAST to a non-text type (NUMBER) is not a text cast — B8 fires."""
        sql = """
        SELECT
          MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(NAME1::text), '^^')
            , '||', IFNULL(TRIM(CAST(PSA_DELETE_IND AS NUMBER)), '^^')
          ), '^^||^^')))  as HASHDIFF
        FROM JOIN_RESULT
        """
        findings = check_hashdiff_delete_flag_explicit_cast(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "B8"

    def test_edge_delete_flag_bare_in_select_not_in_block(self):
        """Bare delete flag in SELECT list (outside the HASHDIFF block) must not fire.

        HASHDIFF_FIVETRAN_PASS has bare `_FIVETRAN_DELETED` / `PSA_DELETE_IND` in
        the SELECT list but cast forms inside the block — B8 scopes to the block.
        """
        findings = check_hashdiff_delete_flag_explicit_cast(HASHDIFF_FIVETRAN_PASS, VPSA_PATH)
        assert findings == []

    def test_edge_skip_non_vpsa_path(self):
        sql = """
        SELECT MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(PSA_DELETE_IND), '^^')
          ), '^^||^^')))  as HASHDIFF
        """
        findings = check_hashdiff_delete_flag_explicit_cast(sql, NON_VPSA_PATH)
        assert findings == []

    def test_edge_no_hashdiff_no_finding(self):
        sql = "SELECT col1, col2 FROM some_table"
        findings = check_hashdiff_delete_flag_explicit_cast(sql, VPSA_PATH)
        assert findings == []

    def test_gap_b6_passes_but_b8_fails_when_cast_dropped(self):
        """The exact gap B8 closes: B6 (name-present) passes, B8 (cast-present) fails.

        A hand-edit that drops `::text` from _FIVETRAN_DELETED keeps the column
        NAME in the block (so B5/B6 stay green) but loses the cast — only B8 sees it.
        """
        sql = """
        , LOGIC_S as (
            SELECT _FIVETRAN_DELETED FROM SRC_S
        )
        SELECT
          _FIVETRAN_DELETED
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(VENDOR_STATUS::text), '^^')
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED), '^^')
          ), '^^||^^')))  as HASHDIFF
        FROM JOIN_RESULT
        """
        # B6 passes — the NAME is present in the block
        assert check_hashdiff_includes_fivetran_deleted(sql, VPSA_PATH) == []
        # B8 fails — the CAST is missing
        b8 = check_hashdiff_delete_flag_explicit_cast(sql, VPSA_PATH)
        assert len(b8) == 1
        assert b8[0].check_id == "B8"
