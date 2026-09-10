#!/usr/bin/env python3
"""
test_category_cdef.py — Tests for Categories C (CTE), D (BKCC), E (Dedup), F (Date/Timezone).

Run: .venv/bin/python3 -m pytest scripts/automation/tests/test_category_cdef.py -v
"""
import sys
from pathlib import Path

import pytest

SCRIPT_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = SCRIPT_DIR / "src"
sys.path.insert(0, str(SRC_DIR))

from code_review_config import FileStatus
from code_reviewer import (
    Severity,
    # Category C
    check_cte_4layer_new_models,
    check_cte_no_nonstandard_names,
    check_final_select_from_join_result,
    # Category D
    check_bkcc_join_on_1_equals_1,
    check_bkcc_from_ref_table,
    check_bkcc_column_present,
    # Category E
    check_no_select_distinct,
    check_qualify_has_row_number,
    check_qualify_dedup_with_secondary_join,
    # Category F
    check_convert_timezone_utc,
    check_null_date_1900_placeholder,
    check_load_dts_derivation_fivetran,
    check_load_dts_derivation_snp_glue,
    check_load_dts_has_convert_timezone,
)

VPSA_PATH = "models/int_staging_views/supplier/v_psa_stg_supplier__winn_sap.sql"
BUS_VAULT_PATH = "models/bus_vault/pit_bridge/bom/pb_bom_hierarchy.sql"
SAT_PATH = "models/raw_vault/sat/sat_supplier__winn_sap.sql"

# ═══════════════════════════════════════════════════════════════════════════════
# Standard fixtures
# ═══════════════════════════════════════════════════════════════════════════════

STANDARD_6LAYER = """
---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_vendor') }} ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} )
---- LOGIC LAYER ----
, LOGIC_S as (
    SELECT VENDOR_ID::TEXT as SUPPLIER_BK, VENDOR_ID
    FROM SRC_S
)
, LOGIC_A as (
    SELECT REC_SRC, BKCC FROM SRC_A
)
---- RENAME LAYER ----
, RENAME_S as ( SELECT * FROM LOGIC_S )
, RENAME_A as ( SELECT * FROM LOGIC_A )
---- FILTER LAYER ----
, FILTER_S as ( SELECT * FROM RENAME_S )
, FILTER_A as ( SELECT * FROM RENAME_A )
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_S
    INNER JOIN FILTER_A ON '1' = '1'
)
SELECT SUPPLIER_BK, BKCC FROM JOIN_RESULT
"""

STANDARD_4LAYER = """
---- SRC LAYER ----
WITH
SRC_S as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_vendor') }} ),
SRC_BKCC as ( SELECT * FROM {{ ref('ref_business_key_collision') }} )
---- LOGIC LAYER ----
, LOGIC_S as (
    SELECT VENDOR_ID::TEXT as SUPPLIER_BK FROM SRC_S
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM LOGIC_S
    INNER JOIN SRC_BKCC ON '1' = '1'
)
SELECT SUPPLIER_BK, BKCC FROM JOIN_RESULT
"""


# ═══════════════════════════════════════════════════════════════════════════════
# C1: cte_4layer_new_models
# ═══════════════════════════════════════════════════════════════════════════════

class TestC1Cte4layerNewModels:
    """C1: New models should use 4-layer CTE, not 6-layer."""

    def test_pass_4layer_new_model(self):
        findings = check_cte_4layer_new_models(STANDARD_4LAYER, VPSA_PATH, file_status=FileStatus.NEW)
        assert findings == []

    def test_warn_6layer_new_model(self):
        findings = check_cte_4layer_new_models(STANDARD_6LAYER, VPSA_PATH, file_status=FileStatus.NEW)
        assert len(findings) == 1
        assert findings[0].check_id == "C1"
        assert findings[0].severity == Severity.WARN

    def test_edge_6layer_modified_no_warning(self):
        """Modified legacy files keep 6-layer — no warning."""
        findings = check_cte_4layer_new_models(STANDARD_6LAYER, VPSA_PATH, file_status=FileStatus.MODIFIED)
        assert findings == []

    def test_edge_non_vpsa_path(self):
        findings = check_cte_4layer_new_models(STANDARD_6LAYER, SAT_PATH, file_status=FileStatus.NEW)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# C2: cte_no_nonstandard_names
# ═══════════════════════════════════════════════════════════════════════════════

class TestC2CteNoNonstandardNames:
    """C2: CTE names must follow standard patterns."""

    def test_pass_standard_names(self):
        findings = check_cte_no_nonstandard_names(STANDARD_6LAYER, VPSA_PATH)
        assert findings == []

    def test_warn_nonstandard_name(self):
        sql = """
        WITH SRC_S as ( SELECT * FROM {{ source('x','y') }} )
        , TEMP_CLEANUP as ( SELECT * FROM SRC_S )
        , JOIN_RESULT as ( SELECT * FROM TEMP_CLEANUP )
        SELECT * FROM JOIN_RESULT
        """
        findings = check_cte_no_nonstandard_names(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "C2"
        assert "TEMP_CLEANUP" in findings[0].message

    def test_edge_incr_watermark_allowed(self):
        """INCR_WATERMARK is a standard CTE name for incremental models."""
        sql = """
        WITH SRC_S as ( SELECT * FROM {{ source('x','y') }} )
        , INCR_WATERMARK as ( SELECT MAX(LOAD_DTS) FROM {{ this }} GROUP BY REC_SRC )
        , JOIN_RESULT as ( SELECT * FROM SRC_S )
        SELECT * FROM JOIN_RESULT
        """
        findings = check_cte_no_nonstandard_names(sql, VPSA_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# C3: final_select_from_join_result
# ═══════════════════════════════════════════════════════════════════════════════

class TestC3FinalSelectFromJoinResult:
    """C3: Final SELECT should reference JOIN_RESULT or FINAL."""

    def test_pass_from_join_result(self):
        findings = check_final_select_from_join_result(STANDARD_6LAYER, VPSA_PATH)
        assert findings == []

    def test_warn_from_intermediate_cte(self):
        sql = """
        WITH SRC_S as ( SELECT * FROM {{ source('x','y') }} )
        , LOGIC_S as ( SELECT * FROM SRC_S )
        SELECT * FROM LOGIC_S
        """
        findings = check_final_select_from_join_result(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "C3"
        assert "LOGIC_S" in findings[0].message

    def test_pass_from_final_cte(self):
        sql = """
        WITH SRC_S as ( SELECT * FROM {{ source('x','y') }} )
        , FINAL as ( SELECT * FROM SRC_S )
        SELECT * FROM FINAL
        """
        findings = check_final_select_from_join_result(sql, VPSA_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# D1: bkcc_join_on_1_equals_1
# ═══════════════════════════════════════════════════════════════════════════════

class TestD1BkccJoin:
    """D1: BKCC must be joined via ON '1' = '1'."""

    def test_pass_standard_cross_join(self):
        findings = check_bkcc_join_on_1_equals_1(STANDARD_6LAYER, VPSA_PATH)
        assert findings == []

    def test_fail_hardcoded_bkcc(self):
        sql = """
        , LOGIC_S as (
            SELECT VENDOR_ID, 'FBIN' AS BKCC FROM SRC_S
        )
        SELECT * FROM LOGIC_S
        """
        findings = check_bkcc_join_on_1_equals_1(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "D1"
        assert findings[0].severity == Severity.FAIL

    def test_edge_no_bkcc_no_finding(self):
        """Model without BKCC — not a v_psa_stg pattern, skip."""
        sql = "SELECT col1 FROM table1"
        findings = check_bkcc_join_on_1_equals_1(sql, VPSA_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# D2: bkcc_from_ref_table
# ═══════════════════════════════════════════════════════════════════════════════

class TestD2BkccFromRefTable:
    """D2: BKCC must come from ref_business_key_collision."""

    def test_pass_ref_function(self):
        findings = check_bkcc_from_ref_table(STANDARD_6LAYER, VPSA_PATH)
        assert findings == []

    def test_pass_direct_table_name(self):
        """Legacy models may reference RAW_VAULT.REF_BUSINESS_KEY_COLLISION directly."""
        sql = """
        SRC_A as ( SELECT * FROM RAW_VAULT.REF_BUSINESS_KEY_COLLISION )
        , JOIN_RESULT as ( SELECT *, BKCC FROM SRC_A )
        SELECT BKCC FROM JOIN_RESULT
        """
        findings = check_bkcc_from_ref_table(sql, VPSA_PATH)
        assert findings == []

    def test_fail_no_ref_table(self):
        sql = """
        , LOGIC_S as (
            SELECT VENDOR_ID, 'FBIN' AS BKCC FROM SRC_S
        )
        SELECT BKCC FROM LOGIC_S
        """
        findings = check_bkcc_from_ref_table(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "D2"


# ═══════════════════════════════════════════════════════════════════════════════
# D3: bkcc_column_present
# ═══════════════════════════════════════════════════════════════════════════════

class TestD3BkccColumnPresent:
    """D3: Every v_psa_stg must output a BKCC column."""

    def test_pass_bkcc_present(self):
        findings = check_bkcc_column_present(STANDARD_6LAYER, VPSA_PATH)
        assert findings == []

    def test_fail_bkcc_missing(self):
        sql = "SELECT VENDOR_ID, LOAD_DTS FROM SRC_S"
        findings = check_bkcc_column_present(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "D3"
        assert findings[0].severity == Severity.FAIL

    def test_edge_non_vpsa_path(self):
        sql = "SELECT VENDOR_ID FROM SRC_S"  # No BKCC, but not a v_psa_stg
        findings = check_bkcc_column_present(sql, SAT_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# E1: no_select_distinct
# ═══════════════════════════════════════════════════════════════════════════════

class TestE1NoSelectDistinct:
    """E1: SELECT DISTINCT is prohibited."""

    def test_pass_no_distinct(self):
        findings = check_no_select_distinct(STANDARD_6LAYER, VPSA_PATH)
        assert findings == []

    def test_fail_select_distinct(self):
        # NOTE 2026-06-22: re-pathed from BUS_VAULT_PATH → SAT_PATH because
        # E1 is now path-scoped (bus_vault/ → WARN, everywhere else → FAIL).
        # BV-WARN coverage lives in test_category_h10_h11_n1_e1.py.
        sql = "SELECT DISTINCT col1, col2 FROM some_table"
        findings = check_no_select_distinct(sql, SAT_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "E1"
        assert findings[0].severity == Severity.FAIL

    def test_edge_distinct_in_comment_ignored(self):
        sql = """
        -- SELECT DISTINCT is not allowed
        /* SELECT DISTINCT col1 */
        SELECT col1 FROM table1
        """
        findings = check_no_select_distinct(sql, BUS_VAULT_PATH)
        assert findings == []

    def test_edge_multiple_violations(self):
        sql = """
        SELECT DISTINCT col1 FROM table1
        UNION ALL
        SELECT DISTINCT col2 FROM table2
        """
        findings = check_no_select_distinct(sql, BUS_VAULT_PATH)
        assert len(findings) == 2


# ═══════════════════════════════════════════════════════════════════════════════
# E2: qualify_has_row_number
# ═══════════════════════════════════════════════════════════════════════════════

class TestE2QualifyHasRowNumber:
    """E2: QUALIFY should use ROW_NUMBER() or RANK()."""

    def test_pass_row_number(self):
        sql = "SELECT * FROM t QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY ts DESC) = 1"
        findings = check_qualify_has_row_number(sql, VPSA_PATH)
        assert findings == []

    def test_pass_rank(self):
        sql = "SELECT * FROM t QUALIFY RANK() OVER (PARTITION BY id ORDER BY ts DESC) = 1"
        findings = check_qualify_has_row_number(sql, VPSA_PATH)
        assert findings == []

    def test_warn_dense_rank(self):
        sql = "SELECT * FROM t QUALIFY DENSE_RANK() OVER (PARTITION BY id ORDER BY ts DESC) = 1"
        findings = check_qualify_has_row_number(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "E2"
        assert findings[0].severity == Severity.WARN

    def test_edge_qualify_equals_1(self):
        """QUALIFY 1 = ROW_NUMBER() is valid (reversed order from some models)."""
        sql = "SELECT * FROM t QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY id ORDER BY ts DESC)"
        findings = check_qualify_has_row_number(sql, VPSA_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# E4: qualify_dedup_with_secondary_join
# ═══════════════════════════════════════════════════════════════════════════════


class TestE4QualifyDedupWithSecondaryJoin:
    """E4: Models with secondary JOINs (beyond BKCC) must have QUALIFY."""

    def test_pass_left_join_with_qualify(self):
        """LEFT JOIN to lookup + QUALIFY = no warning."""
        sql = """
        , JOIN_RESULT AS (
            SELECT L.*, R.DESCRIPTION
            FROM LOGIC_S L
            INNER JOIN SRC_A ON '1' = '1'
            LEFT JOIN LOGIC_R R ON L.CODE = R.CODE
            QUALIFY ROW_NUMBER() OVER (PARTITION BY SUPPLIER_BK, LOAD_DTS ORDER BY LOAD_DTS DESC) = 1
        )
        """
        findings = check_qualify_dedup_with_secondary_join(sql, VPSA_PATH, file_status=FileStatus.NEW)
        assert findings == []

    def test_warn_left_join_no_qualify(self):
        """LEFT JOIN to lookup but no QUALIFY = warning."""
        sql = """
        , JOIN_RESULT AS (
            SELECT L.*, R.DESCRIPTION
            FROM LOGIC_S L
            INNER JOIN SRC_A ON '1' = '1'
            LEFT JOIN LOGIC_R R ON L.CODE = R.CODE
        )
        """
        findings = check_qualify_dedup_with_secondary_join(sql, VPSA_PATH, file_status=FileStatus.NEW)
        assert len(findings) == 1
        assert findings[0].check_id == "E4"
        assert findings[0].severity == Severity.WARN
        assert "1 secondary JOIN" in findings[0].message

    def test_pass_only_bkcc_join(self):
        """Only BKCC join (ON '1' = '1') present — no secondary JOINs, no warning."""
        sql = """
        , JOIN_RESULT AS (
            SELECT L.*, A.BKCC
            FROM LOGIC_S L
            INNER JOIN SRC_A ON '1' = '1'
        )
        """
        findings = check_qualify_dedup_with_secondary_join(sql, VPSA_PATH, file_status=FileStatus.NEW)
        assert findings == []

    def test_skip_modified_files(self):
        """Legacy modified files are not checked."""
        sql = """
        , JOIN_RESULT AS (
            SELECT L.*, R.DESCRIPTION
            FROM LOGIC_S L
            INNER JOIN SRC_A ON '1' = '1'
            LEFT JOIN LOGIC_R R ON L.CODE = R.CODE
        )
        """
        findings = check_qualify_dedup_with_secondary_join(sql, VPSA_PATH, file_status=FileStatus.MODIFIED)
        assert findings == []

    def test_skip_non_staging(self):
        """Non-staging models are not checked."""
        sql = """
        SELECT * FROM hub_supplier LEFT JOIN sat_supplier ON hub.HK = sat.HK
        """
        findings = check_qualify_dedup_with_secondary_join(sql, SAT_PATH, file_status=FileStatus.NEW)
        assert findings == []

    def test_pass_multiple_left_joins_with_qualify(self):
        """Multiple LEFT JOINs + QUALIFY = no warning."""
        sql = """
        , JOIN_RESULT AS (
            SELECT L.*, R1.NAME, R2.CODE
            FROM LOGIC_S L
            INNER JOIN SRC_A ON '1' = '1'
            LEFT JOIN LOGIC_R1 R1 ON L.ID = R1.ID
            LEFT JOIN LOGIC_R2 R2 ON L.CODE = R2.CODE
            QUALIFY ROW_NUMBER() OVER (PARTITION BY BK, LOAD_DTS ORDER BY LOAD_DTS DESC) = 1
        )
        """
        findings = check_qualify_dedup_with_secondary_join(sql, VPSA_PATH, file_status=FileStatus.NEW)
        assert findings == []

    def test_warn_multiple_left_joins_no_qualify(self):
        """Multiple LEFT JOINs without QUALIFY flags the count."""
        sql = """
        , JOIN_RESULT AS (
            SELECT L.*, R1.NAME, R2.CODE
            FROM LOGIC_S L
            INNER JOIN SRC_A ON '1' = '1'
            LEFT JOIN LOGIC_R1 R1 ON L.ID = R1.ID
            LEFT JOIN LOGIC_R2 R2 ON L.CODE = R2.CODE
        )
        """
        findings = check_qualify_dedup_with_secondary_join(sql, VPSA_PATH, file_status=FileStatus.NEW)
        assert len(findings) == 1
        assert "2 secondary JOIN" in findings[0].message

    def test_pass_no_joins_at_all(self):
        """No JOINs = no check triggered."""
        sql = """
        , FINAL AS (
            SELECT BK, LOAD_DTS, REC_SRC FROM LOGIC_S
        )
        """
        findings = check_qualify_dedup_with_secondary_join(sql, VPSA_PATH, file_status=FileStatus.NEW)
        assert findings == []

    def test_warn_qualify_only_before_joins(self):
        """QUALIFY in SRC (source dedup) but not after secondary JOINs — still warns."""
        sql = """
        , SRC_S AS (
            SELECT * FROM {{ source('schema', 'table') }}
            QUALIFY ROW_NUMBER() OVER (PARTITION BY PK ORDER BY LOAD_DTS DESC) = 1
        )
        , LOGIC_S AS (
            SELECT COL1, COL2 FROM SRC_S
        )
        , JOIN_RESULT AS (
            SELECT L.*, R.DESCRIPTION
            FROM LOGIC_S L
            INNER JOIN SRC_A ON '1' = '1'
            LEFT JOIN LOGIC_R R ON L.CODE = R.CODE
        )
        """
        findings = check_qualify_dedup_with_secondary_join(sql, VPSA_PATH, file_status=FileStatus.NEW)
        assert len(findings) == 1
        assert findings[0].check_id == "E4"
        assert "only appears before" in findings[0].message

    def test_pass_qualify_in_final_after_joins(self):
        """QUALIFY in FINAL CTE (after all JOINs) covers everything."""
        sql = """
        , SRC_S AS (
            SELECT * FROM {{ source('schema', 'table') }}
        )
        , JOIN_RESULT AS (
            SELECT L.*, R.DESCRIPTION
            FROM LOGIC_S L
            INNER JOIN SRC_A ON '1' = '1'
            LEFT JOIN LOGIC_R R ON L.CODE = R.CODE
        )
        , FINAL AS (
            SELECT * FROM JOIN_RESULT
            QUALIFY ROW_NUMBER() OVER (PARTITION BY BK, LOAD_DTS ORDER BY LOAD_DTS DESC) = 1
        )
        """
        findings = check_qualify_dedup_with_secondary_join(sql, VPSA_PATH, file_status=FileStatus.NEW)
        assert findings == []

    def test_warn_one_lookup_deduped_another_not(self):
        """One lookup has QUALIFY (pre-join) but second lookup is after it — warns."""
        sql = """
        , LOGIC_R1 AS (
            SELECT * FROM SRC_R1
            QUALIFY ROW_NUMBER() OVER (PARTITION BY KEY ORDER BY TS DESC) = 1
        )
        , JOIN_RESULT AS (
            SELECT L.*, R1.NAME, R2.CODE
            FROM LOGIC_S L
            INNER JOIN SRC_A ON '1' = '1'
            LEFT JOIN LOGIC_R1 R1 ON L.ID = R1.ID
            LEFT JOIN LOGIC_R2 R2 ON L.CODE = R2.CODE
        )
        """
        findings = check_qualify_dedup_with_secondary_join(sql, VPSA_PATH, file_status=FileStatus.NEW)
        assert len(findings) == 1
        assert "only appears before" in findings[0].message

    def test_pass_qualify_same_cte_as_last_join(self):
        """QUALIFY in same CTE as the JOINs (inline post-join dedup) — pass."""
        sql = """
        , JOIN_RESULT AS (
            SELECT L.*, R1.NAME, R2.CODE
            FROM LOGIC_S L
            INNER JOIN SRC_A ON '1' = '1'
            LEFT JOIN LOGIC_R1 R1 ON L.ID = R1.ID
            LEFT JOIN LOGIC_R2 R2 ON L.CODE = R2.CODE
            QUALIFY ROW_NUMBER() OVER (PARTITION BY BK, LOAD_DTS ORDER BY LOAD_DTS DESC) = 1
        )
        """
        findings = check_qualify_dedup_with_secondary_join(sql, VPSA_PATH, file_status=FileStatus.NEW)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# F1: convert_timezone_utc
# ═══════════════════════════════════════════════════════════════════════════════

class TestF1ConvertTimezoneUtc:
    """F1: CONVERT_TIMEZONE must use 'UTC'."""

    def test_pass_utc(self):
        sql = "CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS) AS LOAD_DTS"
        findings = check_convert_timezone_utc(sql, VPSA_PATH)
        assert findings == []

    def test_fail_non_utc(self):
        sql = "CONVERT_TIMEZONE('America/New_York', some_col) AS some_ts"
        findings = check_convert_timezone_utc(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "F1"
        assert "America/New_York" in findings[0].message

    def test_edge_case_insensitive(self):
        sql = "convert_timezone('UTC', col) AS ts"
        findings = check_convert_timezone_utc(sql, VPSA_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# F2: null_date_1900_placeholder
# ═══════════════════════════════════════════════════════════════════════════════

class TestF2NullDate1900:
    """F2: NULL date placeholder must be '1900-01-01'."""

    def test_pass_1900(self):
        sql = "IFNULL(date_col, '1900-01-01'::TIMESTAMP)"
        findings = check_null_date_1900_placeholder(sql, VPSA_PATH)
        assert findings == []

    def test_warn_9999(self):
        sql = "IFNULL(date_col, '9999-12-31')"
        findings = check_null_date_1900_placeholder(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "F2"
        assert "'9999-12-31'" in findings[0].message

    def test_edge_non_vpsa_path(self):
        sql = "IFNULL(date_col, '9999-12-31')"
        findings = check_null_date_1900_placeholder(sql, SAT_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# F3: load_dts_derivation_fivetran
# ═══════════════════════════════════════════════════════════════════════════════

class TestF3LoadDtsFivetran:
    """F3: Fivetran LOAD_DTS must derive from _FIVETRAN_SYNCED."""

    def test_pass_fivetran_synced(self):
        sql = """
        , _FIVETRAN_SYNCED
        , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED) AS LOAD_DTS
        """
        findings = check_load_dts_derivation_fivetran(sql, VPSA_PATH)
        assert findings == []

    def test_fail_psa_load_dts_in_fivetran(self):
        sql = """
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS AS LOAD_DTS
        """
        findings = check_load_dts_derivation_fivetran(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "F3"

    def test_edge_not_fivetran_source(self):
        """Non-Fivetran source (no _FIVETRAN_SYNCED) — check should not fire."""
        sql = "CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS) AS LOAD_DTS"
        findings = check_load_dts_derivation_fivetran(sql, VPSA_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# F4: load_dts_derivation_snp_glue
# ═══════════════════════════════════════════════════════════════════════════════

class TestF4LoadDtsSnpGlue:
    """F4: SNP GLUE LOAD_DTS must use SUBSTR+FF9 mask on GLCHANGETIME."""

    def test_pass_substr_pattern(self):
        sql = """
        , GLCHANGETIME
        , IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS,
            CONVERT_TIMEZONE('UTC', TO_TIMESTAMP_NTZ(
                SUBSTR(GLCHANGETIME, 1, 14) || '.' || SUBSTR(GLCHANGETIME, 16),
                'YYYYMMDDHH24MISS.FF9'
            ))
          ) AS LOAD_DTS
        """
        findings = check_load_dts_derivation_snp_glue(sql, VPSA_PATH)
        assert findings == []

    def test_fail_direct_convert(self):
        sql = """
        , GLCHANGETIME
        , CONVERT_TIMEZONE('UTC', GLCHANGETIME) AS LOAD_DTS
        """
        findings = check_load_dts_derivation_snp_glue(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "F4"

    def test_edge_no_glchangetime(self):
        """Non-SNP GLUE source — check should not fire."""
        sql = "CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS) AS LOAD_DTS"
        findings = check_load_dts_derivation_snp_glue(sql, VPSA_PATH)
        assert findings == []


# ═══════════════════════════════════════════════════════════════════════════════
# F5: load_dts_has_convert_timezone
# ═══════════════════════════════════════════════════════════════════════════════

class TestF5LoadDtsHasConvertTimezone:
    """F5: LOAD_DTS must include CONVERT_TIMEZONE — no raw passthrough."""

    def test_pass_with_convert_timezone(self):
        sql = "CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS) AS LOAD_DTS"
        findings = check_load_dts_has_convert_timezone(sql, VPSA_PATH)
        assert findings == []

    def test_fail_raw_passthrough(self):
        sql = "PSA_LOAD_DTS AS LOAD_DTS"
        findings = check_load_dts_has_convert_timezone(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "F5"

    def test_edge_iff_with_convert_timezone(self):
        """IFF pattern has CONVERT_TIMEZONE deeper — should pass."""
        sql = """
        , IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS,
            CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)
          ) AS LOAD_DTS
        """
        findings = check_load_dts_has_convert_timezone(sql, VPSA_PATH)
        assert findings == []
