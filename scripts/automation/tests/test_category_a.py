#!/usr/bin/env python3
"""
test_category_a.py — Tests for Category A (Hash Key Formula) checks.

Covers: A1 (hk_uses_concat_ws), A2 (hk_coalesce_nullif_trim),
        A3 (hk_uses_raw_column_names), A4 (hk_bkcc_last_component),
        A5 (hk_has_upper_wrapper)

Each check has: 1 pass, 1 fail, 1+ edge case.

Run: .venv/bin/python3 -m pytest scripts/automation/tests/test_category_a.py -v
"""
import sys
from pathlib import Path

import pytest

SCRIPT_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = SCRIPT_DIR / "src"
sys.path.insert(0, str(SRC_DIR))

from code_reviewer import (
    Severity,
    check_hk_uses_concat_ws,
    check_hk_coalesce_nullif_trim,
    check_hk_uses_raw_column_names,
    check_hk_bkcc_last_component,
    check_hk_has_upper_wrapper,
)

# ---------------------------------------------------------------------------
# Fixtures: real-world SQL patterns extracted from the live repo
# ---------------------------------------------------------------------------

# Standard Fivetran v_psa_stg (from v_psa_stg_supplier__lrsn_psft.sql)
FIVETRAN_HK_PASS = """
---- SRC LAYER ----
WITH
SRC_S as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_vendor') }} ),
SRC_A as ( SELECT * FROM {{ ref('ref_business_key_collision') }} )
---- LOGIC LAYER ----
, LOGIC_S as (
    SELECT
        VENDOR_ID::TEXT as SUPPLIER_BK
      , VENDOR_ID
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED) as LOAD_DTS
      , _FIVETRAN_DELETED
      , PSA_DELETE_IND
    FROM SRC_S
)
, LOGIC_A as (
    SELECT REC_SRC, BKCC FROM SRC_A
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM LOGIC_S
    INNER JOIN LOGIC_A ON '1' = '1'
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

# SNP GLUE v_psa_stg (from v_psa_stg_supplier__winn_sap.sql)
SNP_GLUE_HK_PASS = """
---- LOGIC LAYER ----
, LOGIC_S as (
    SELECT
        LIFNR as SUPPLIER_BK
      , LIFNR
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS) as LOAD_DTS
      , GLCHANGETIME
      , PSA_DELETE_IND
    FROM SRC_S
)
---- FINAL LAYER ----
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

# Multi-BK HK (e.g., CONCAT('||', col1, col2) for BK then used in HK)
MULTI_BK_HK_PASS = """
---- LOGIC LAYER ----
, LOGIC_S as (
    SELECT
        CONCAT(EBELN, '||', EBELP) as PO_LINE_BK
      , EBELN
      , EBELP
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS) as LOAD_DTS
    FROM SRC_S
)
---- FINAL LAYER ----
SELECT
      PO_LINE_BK
    , EBELN
    , EBELP
    , LOAD_DTS
    , REC_SRC
    , BKCC
    , MD5_BINARY(UPPER(CONCAT_WS('||',
        COALESCE(NULLIF(TRIM(CAST(EBELN as VARCHAR)),''), '^^')
      , COALESCE(NULLIF(TRIM(CAST(EBELP as VARCHAR)),''), '^^')
      , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
      ))) as PO_LINE_HK
FROM JOIN_RESULT
"""

VPSA_PATH = "models/int_staging_views/supplier/v_psa_stg_supplier__winn_sap.sql"
NON_VPSA_PATH = "models/raw_vault/sat/sat_supplier__winn_sap.sql"


# ═══════════════════════════════════════════════════════════════════════════════
# A1: hk_uses_concat_ws
# ═══════════════════════════════════════════════════════════════════════════════

class TestA1HkUsesConcatWs:
    """A1: HK must use CONCAT_WS, not plain CONCAT."""

    def test_pass_standard_concat_ws(self):
        findings = check_hk_uses_concat_ws(FIVETRAN_HK_PASS, VPSA_PATH)
        assert findings == []

    def test_fail_plain_concat(self):
        sql = """
        , MD5_BINARY(UPPER(CONCAT(
            COALESCE(NULLIF(TRIM(CAST(LIFNR as VARCHAR)),''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
          ))) as SUPPLIER_HK
        """
        findings = check_hk_uses_concat_ws(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "A1"
        assert findings[0].severity == Severity.FAIL
        assert "CONCAT_WS" in findings[0].message

    def test_edge_skip_non_vpsa_path(self):
        """HK checks only apply to int_staging_views/ — sats pass through HK from stg."""
        findings = check_hk_uses_concat_ws(FIVETRAN_HK_PASS, NON_VPSA_PATH)
        assert findings == []

    def test_edge_no_hk_in_file(self):
        """File with no HK formula should produce no findings."""
        sql = "SELECT col1, col2 FROM some_table"
        findings = check_hk_uses_concat_ws(sql, VPSA_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# A2: hk_coalesce_nullif_trim
# ═══════════════════════════════════════════════════════════════════════════════

class TestA2HkCoalesceNullifTrim:
    """A2: HK components must use COALESCE(NULLIF(TRIM(CAST(...)),''),'^^')."""

    def test_pass_standard_pattern(self):
        findings = check_hk_coalesce_nullif_trim(FIVETRAN_HK_PASS, VPSA_PATH)
        assert findings == []

    def test_fail_missing_nullif(self):
        sql = """
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(TRIM(CAST(LIFNR as VARCHAR)), '^^')
          , COALESCE(TRIM(CAST(BKCC as VARCHAR)), '^^')
          ))) as SUPPLIER_HK
        """
        findings = check_hk_coalesce_nullif_trim(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "A2"
        assert findings[0].severity == Severity.FAIL
        assert "NULLIF" in findings[0].message

    def test_edge_correct_nullif_not_false_positive(self):
        """Standard pattern with NULLIF present should not trigger."""
        findings = check_hk_coalesce_nullif_trim(SNP_GLUE_HK_PASS, VPSA_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# A3: hk_uses_raw_column_names
# ═══════════════════════════════════════════════════════════════════════════════

class TestA3HkUsesRawColumnNames:
    """A3: HK must reference raw source columns, not BK aliases."""

    def test_pass_uses_raw_column(self):
        """VENDOR_ID (raw) used in HK, not SUPPLIER_BK (alias)."""
        findings = check_hk_uses_raw_column_names(FIVETRAN_HK_PASS, VPSA_PATH)
        assert findings == []

    def test_pass_snp_glue_raw_column(self):
        """LIFNR (raw) used in HK, not SUPPLIER_BK (alias)."""
        findings = check_hk_uses_raw_column_names(SNP_GLUE_HK_PASS, VPSA_PATH)
        assert findings == []

    def test_fail_uses_bk_alias(self):
        sql = """
        , LOGIC_S as (
            SELECT
                VENDOR_ID::TEXT as SUPPLIER_BK
              , VENDOR_ID
            FROM SRC_S
        )
        SELECT
            MD5_BINARY(UPPER(CONCAT_WS('||',
                COALESCE(NULLIF(TRIM(CAST(SUPPLIER_BK as VARCHAR)),''), '^^')
              , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
              ))) as SUPPLIER_HK
        FROM JOIN_RESULT
        """
        findings = check_hk_uses_raw_column_names(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "A3"
        assert "SUPPLIER_BK" in findings[0].message

    def test_edge_derived_bk_not_flagged(self):
        """Lesson #89: Complex derived BKs (CONCAT) are allowed in HK.

        When BK is derived from CONCAT(col1, '||', col2), there's no single
        raw column to reference — the BK alias is acceptable.
        """
        sql = """
        , LOGIC_S as (
            SELECT
                CONCAT(EBELN, '||', EBELP) as PO_LINE_BK
              , EBELN
              , EBELP
            FROM SRC_S
        )
        SELECT
            MD5_BINARY(UPPER(CONCAT_WS('||',
                COALESCE(NULLIF(TRIM(CAST(EBELN as VARCHAR)),''), '^^')
              , COALESCE(NULLIF(TRIM(CAST(EBELP as VARCHAR)),''), '^^')
              , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
              ))) as PO_LINE_HK
        FROM JOIN_RESULT
        """
        findings = check_hk_uses_raw_column_names(sql, VPSA_PATH)
        assert findings == []

    def test_edge_column_named_bk_status_not_flagged(self):
        """A column named BK_STATUS is NOT a business key — should not trigger.

        Only columns explicitly aliased as '<entity>_BK' via 'AS <NAME>_BK'
        in the LOGIC layer are treated as business keys.
        """
        sql = """
        , LOGIC_S as (
            SELECT
                VENDOR_ID::TEXT as SUPPLIER_BK
              , VENDOR_ID
              , BK_STATUS
            FROM SRC_S
        )
        SELECT
            MD5_BINARY(UPPER(CONCAT_WS('||',
                COALESCE(NULLIF(TRIM(CAST(VENDOR_ID as VARCHAR)),''), '^^')
              , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
              ))) as SUPPLIER_HK
        FROM JOIN_RESULT
        """
        findings = check_hk_uses_raw_column_names(sql, VPSA_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# A4: hk_bkcc_last_component
# ═══════════════════════════════════════════════════════════════════════════════

class TestA4HkBkccLastComponent:
    """A4: BKCC must be the last argument in HK CONCAT_WS."""

    def test_pass_bkcc_last(self):
        findings = check_hk_bkcc_last_component(FIVETRAN_HK_PASS, VPSA_PATH)
        assert findings == []

    def test_pass_multi_bk_bkcc_last(self):
        """Multi-BK: BKCC still last after all raw columns."""
        findings = check_hk_bkcc_last_component(MULTI_BK_HK_PASS, VPSA_PATH)
        assert findings == []

    def test_fail_bkcc_first(self):
        sql = """
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(LIFNR as VARCHAR)),''), '^^')
          ))) as SUPPLIER_HK
        """
        findings = check_hk_bkcc_last_component(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "A4"
        assert findings[0].severity == Severity.FAIL
        assert "BKCC" in findings[0].message

    def test_edge_no_bkcc_no_finding(self):
        """HK without BKCC component (shouldn't happen, but don't crash)."""
        sql = """
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(LIFNR as VARCHAR)),''), '^^')
          ))) as SUPPLIER_HK
        """
        findings = check_hk_bkcc_last_component(sql, VPSA_PATH)
        assert findings == []  # No BKCC found, no finding


# ═══════════════════════════════════════════════════════════════════════════════
# A5: hk_has_upper_wrapper
# ═══════════════════════════════════════════════════════════════════════════════

class TestA5HkHasUpperWrapper:
    """A5: HK formula must be wrapped in UPPER(...)."""

    def test_pass_has_upper(self):
        findings = check_hk_has_upper_wrapper(FIVETRAN_HK_PASS, VPSA_PATH)
        assert findings == []

    def test_fail_missing_upper(self):
        sql = """
        , MD5_BINARY(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(LIFNR as VARCHAR)),''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
          )) as SUPPLIER_HK
        """
        findings = check_hk_has_upper_wrapper(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "A5"
        assert findings[0].severity == Severity.FAIL

    def test_edge_case_insensitive_upper(self):
        """UPPER in any case should pass."""
        sql = """
        , md5_binary(upper(concat_ws('||',
            coalesce(nullif(trim(cast(LIFNR as varchar)),''), '^^')
          , coalesce(nullif(trim(cast(BKCC as varchar)),''), '^^')
          ))) as SUPPLIER_HK
        """
        findings = check_hk_has_upper_wrapper(sql, VPSA_PATH)
        assert findings == []
