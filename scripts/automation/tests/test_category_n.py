#!/usr/bin/env python3
"""
test_category_n.py — Tests for Category N (Staging Data Integrity) + E3/C4.

Covers: N1 (no_delete_flag_filter), N2 (coalesce_on_payload_in_staging),
        E3 (qualify_order_by_load_dts), C4 (where_in_src_cte_only)

Each check has: 1 pass, 1 fail, 1+ edge case.

Run: .venv/bin/python3 -m pytest scripts/automation/tests/test_category_n.py -v
"""
import sys
from pathlib import Path

import pytest

SCRIPT_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = SCRIPT_DIR / "src"
sys.path.insert(0, str(SRC_DIR))

from code_reviewer import (
    FileStatus,
    Severity,
    check_no_delete_flag_filter,
    check_coalesce_on_payload_in_staging,
    check_primary_src_no_business_rules,
    check_qualify_order_by_load_dts,
    check_where_in_src_cte_only,
)

VPSA_PATH = "models/int_staging_views/supplier/v_psa_stg_supplier__winn_sap.sql"
HUB_PATH = "models/raw_vault/hub/hub_supplier.sql"
LINK_PATH = "models/raw_vault/link/lnk_po_item.sql"
BUS_VAULT_PATH = "models/bus_vault/pit/pit_supplier.sql"
NON_STAGING_PATH = "models/raw_vault/sat/sat_supplier__winn_sap.sql"


# ===========================================================================
# N1: check_no_delete_flag_filter (Lesson #28)
# ===========================================================================

class TestN1NoDeleteFlagFilter:
    """N1: NEVER filter on _FIVETRAN_DELETED or PSA_DELETE_IND in staging."""

    def test_pass_no_delete_filter(self):
        """Clean model — delete flags in SELECT/HASHDIFF but not in WHERE."""
        sql = """
---- SRC LAYER ----
SRC_S as ( SELECT VENDOR_ID, PSA_DELETE_IND, _FIVETRAN_DELETED, PSA_LOAD_DTS
           FROM {{ source('sap', 'lfa1') }} as SRC ),
SRC_A as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC )
---- LOGIC LAYER ----
, LOGIC_S as (
    SELECT
        VENDOR_ID::TEXT as SUPPLIER_BK
      , PSA_DELETE_IND
      , _FIVETRAN_DELETED
      , MD5_BINARY(UPPER(NULLIF(CONCAT(
            IFNULL(TRIM(PSA_DELETE_IND::text), '^^')
          , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^')
        ), '^^||^^'))) as HASHDIFF
    FROM SRC_S
)
"""
        findings = check_no_delete_flag_filter(sql, VPSA_PATH)
        assert findings == []

    def test_fail_psa_delete_ind_where(self):
        """WHERE PSA_DELETE_IND = 'N' — filters out deletes."""
        sql = """
SRC_S1 as ( SELECT APP_ID, PSA_DELETE_IND, PSA_LOAD_DTS
            FROM {{ source('appbot_psa', 'ratings') }} as SRC
            WHERE PSA_DELETE_IND = 'N' ),
"""
        findings = check_no_delete_flag_filter(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "N1"
        assert findings[0].severity == Severity.FAIL
        assert "PSA_DELETE_IND" in findings[0].message

    def test_fail_fivetran_deleted_where(self):
        """WHERE ... AND _FIVETRAN_DELETED = FALSE — filters on delete flag."""
        sql = """
SRC_S as ( SELECT VENDOR_SITE_ID, _FIVETRAN_DELETED, PSA_LOAD_DTS
           FROM {{ source('ocf', 'vendor_sites') }} as SRC
           where NOT (VENDOR_SITE_ID = 0 and _FIVETRAN_DELETED = TRUE) ),
"""
        findings = check_no_delete_flag_filter(sql, VPSA_PATH)
        assert len(findings) >= 1
        assert any("_FIVETRAN_DELETED" in f.message for f in findings)

    def test_skip_bus_vault(self):
        """Bus vault models CAN legitimately filter on delete flags."""
        sql = """
SELECT * FROM {{ ref('sat_supplier') }}
WHERE PSA_DELETE_IND = 'N'
"""
        findings = check_no_delete_flag_filter(sql, BUS_VAULT_PATH)
        assert findings == []

    def test_skip_raw_vault(self):
        """Raw vault models are out of scope for this check."""
        sql = """WHERE PSA_DELETE_IND = 'N'"""
        findings = check_no_delete_flag_filter(sql, NON_STAGING_PATH)
        assert findings == []

    def test_skip_sql_comment(self):
        """Delete flag reference in a comment should not trigger."""
        sql = """
SRC_S as ( SELECT VENDOR_ID, PSA_DELETE_IND
           FROM {{ source('sap', 'lfa1') }} as SRC
           -- WHERE PSA_DELETE_IND = 'N' -- removed per lesson #28
           ),
"""
        findings = check_no_delete_flag_filter(sql, VPSA_PATH)
        assert findings == []

    def test_skip_non_sql(self):
        """Non-SQL files should be skipped."""
        sql = "WHERE PSA_DELETE_IND = 'N'"
        findings = check_no_delete_flag_filter(sql, VPSA_PATH.replace(".sql", ".yml"))
        assert findings == []


# ===========================================================================
# N2: check_coalesce_on_payload_in_staging (Lesson #58)
# ===========================================================================

class TestN2CoalesceOnPayload:
    """N2: COALESCE/IFNULL on payload columns in LOGIC CTE is prohibited."""

    def test_pass_coalesce_in_hk(self):
        """COALESCE inside MD5_BINARY (HK formula) — correct usage."""
        sql = """
, LOGIC_S as (
    SELECT
        VENDOR_ID::TEXT as SUPPLIER_BK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VENDOR_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
    FROM SRC_S
)
"""
        findings = check_coalesce_on_payload_in_staging(sql, VPSA_PATH)
        assert findings == []

    def test_fail_coalesce_on_payload(self):
        """COALESCE on a payload column in LOGIC — violation."""
        sql = """
, LOGIC_S as (
    SELECT
        VENDOR_ID::TEXT as SUPPLIER_BK
      , COALESCE(VENDOR_STATUS, 'UNKNOWN') AS VENDOR_STATUS
    FROM SRC_S
)
"""
        findings = check_coalesce_on_payload_in_staging(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "N2"
        assert findings[0].severity == Severity.WARN
        assert "VENDOR_STATUS" in findings[0].message

    def test_pass_coalesce_on_bk(self):
        """COALESCE on a BK column — allowed (null BKs cause collisions)."""
        sql = """
, LOGIC_S as (
    SELECT
        COALESCE(VENDOR_ID, '-1') AS VENDOR_BK
    FROM SRC_S
)
"""
        findings = check_coalesce_on_payload_in_staging(sql, VPSA_PATH)
        assert findings == []

    def test_skip_non_staging(self):
        """Non-staging paths are out of scope."""
        sql = """
, LOGIC_S as (
    SELECT COALESCE(VENDOR_STATUS, 'UNKNOWN') AS VENDOR_STATUS FROM SRC_S
)
"""
        findings = check_coalesce_on_payload_in_staging(sql, BUS_VAULT_PATH)
        assert findings == []

    def test_fail_ifnull_on_payload(self):
        """IFNULL on payload in LOGIC — also a violation."""
        sql = """
, LOGIC_S as (
    SELECT
        IFNULL(DESCRIPTION, 'N/A') AS DESCRIPTION
    FROM SRC_S
)
"""
        findings = check_coalesce_on_payload_in_staging(sql, VPSA_PATH)
        assert len(findings) == 1
        assert "DESCRIPTION" in findings[0].message


# ===========================================================================
# E3: check_qualify_order_by_load_dts (Lesson #61)
# ===========================================================================

class TestE3QualifyOrderByLoadDts:
    """E3: Hub/LNK QUALIFY ORDER BY must use LOAD_DTS, not raw timestamps."""

    def test_pass_order_by_load_dts(self):
        """Correct: ORDER BY LOAD_DTS in hub QUALIFY."""
        sql = """
QUALIFY (ROW_NUMBER() OVER(PARTITION BY INSTALLATION_HK ORDER BY LOAD_DTS ))=1
"""
        findings = check_qualify_order_by_load_dts(sql, HUB_PATH)
        assert findings == []

    def test_fail_order_by_glchangetime(self):
        """Violation: ORDER BY GLCHANGETIME in hub QUALIFY."""
        sql = """
QUALIFY (ROW_NUMBER() OVER(PARTITION BY COST_ELEMENT_BK ORDER BY GLCHANGETIME ))=1
"""
        findings = check_qualify_order_by_load_dts(sql, HUB_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "E3"
        assert findings[0].severity == Severity.WARN
        assert "GLCHANGETIME" in findings[0].message

    def test_fail_order_by_fivetran_synced(self):
        """Violation: ORDER BY _FIVETRAN_SYNCED in hub QUALIFY."""
        sql = """
QUALIFY (ROW_NUMBER() OVER(PARTITION BY ORDER_HEADER_BK ORDER BY _FIVETRAN_SYNCED ))=1
"""
        findings = check_qualify_order_by_load_dts(sql, HUB_PATH)
        assert len(findings) == 1
        assert "_FIVETRAN_SYNCED" in findings[0].message

    def test_skip_decode_in_link(self):
        """DECODE ORDER BY in link — intentional multi-source precedence."""
        sql = """
QUALIFY 1 = RANK() OVER (PARTITION BY LNK_HK ORDER BY DECODE(REC_SRC, 'USOHNO.SAP.ECCPRD.Z_VBAP', 1, 2))
"""
        findings = check_qualify_order_by_load_dts(sql, LINK_PATH)
        assert findings == []

    def test_skip_staging_views(self):
        """Staging views are out of scope — raw timestamps are valid there."""
        sql = """
QUALIFY (ROW_NUMBER() OVER(PARTITION BY BK ORDER BY GLCHANGETIME ))=1
"""
        findings = check_qualify_order_by_load_dts(sql, VPSA_PATH)
        assert findings == []

    def test_fail_order_by_zextractdate(self):
        """Violation: ORDER BY ZEXTRACTDATE in hub."""
        sql = """
QUALIFY (ROW_NUMBER() OVER(PARTITION BY COST_ELEMENT_BK ORDER BY ZEXTRACTDATE ))=1
"""
        findings = check_qualify_order_by_load_dts(sql, HUB_PATH)
        assert len(findings) == 1
        assert "ZEXTRACTDATE" in findings[0].message


# ===========================================================================
# C4: check_where_in_src_cte_only (Lesson #20)
# ===========================================================================

class TestC4WhereInSrcCteOnly:
    """C4: WHERE clause must be in SRC CTE, not LOGIC layer."""

    def test_pass_where_in_src(self):
        """Correct: WHERE in SRC CTE."""
        sql = """
SRC_S as ( SELECT * FROM {{ source('sap', 'lfa1') }} as SRC
           WHERE BU = 'WATER' ),
---- LOGIC LAYER ----
, LOGIC_S as (
    SELECT
        VENDOR_ID::TEXT as SUPPLIER_BK
    FROM SRC_S
)
"""
        findings = check_where_in_src_cte_only(sql, VPSA_PATH)
        assert findings == []

    def test_fail_where_in_logic(self):
        """Violation: WHERE inside LOGIC CTE."""
        sql = """
SRC_S as ( SELECT * FROM {{ source('sap', 'lfa1') }} as SRC ),
---- LOGIC LAYER ----
, LOGIC_S as (
    SELECT
        VENDOR_ID::TEXT as SUPPLIER_BK
    FROM SRC_S
    WHERE VENDOR_STATUS = 'ACTIVE'
)
"""
        findings = check_where_in_src_cte_only(sql, VPSA_PATH)
        assert len(findings) == 1
        assert findings[0].check_id == "C4"
        assert findings[0].severity == Severity.WARN
        assert "LOGIC_S" in findings[0].message

    def test_pass_where_in_filter(self):
        """WHERE in FILTER CTE — legacy 6-layer pattern, acceptable."""
        sql = """
, LOGIC_S as (
    SELECT VENDOR_ID::TEXT as SUPPLIER_BK
    FROM SRC_S
)
---- FILTER LAYER ----
, FILTER_S as (
    SELECT * FROM RENAME_S
    WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.REP_CUST'
)
"""
        findings = check_where_in_src_cte_only(sql, VPSA_PATH)
        assert findings == []

    def test_skip_non_staging(self):
        """Non-staging paths are out of scope."""
        sql = """
, LOGIC_S as (
    SELECT * FROM SRC_S
    WHERE ACTIVE = 1
)
"""
        findings = check_where_in_src_cte_only(sql, HUB_PATH)
        assert findings == []

    def test_skip_comment(self):
        """WHERE in a comment inside LOGIC should not trigger."""
        sql = """
, LOGIC_S as (
    SELECT VENDOR_ID::TEXT as SUPPLIER_BK
    -- WHERE VENDOR_STATUS = 'ACTIVE'  -- removed per lesson #20
    FROM SRC_S
)
"""
        findings = check_where_in_src_cte_only(sql, VPSA_PATH)
        assert findings == []


# ===========================================================================
# N3: check_primary_src_no_business_rules
# ===========================================================================

class TestN3PrimarySrcNoBusinessRules:
    """N3: Primary source CTE must not have WHERE/QUALIFY without inline comment."""

    def test_pass_no_where_or_qualify(self):
        """Clean model — driver SRC_S has no WHERE or QUALIFY."""
        sql = """
SRC_S as ( SELECT VENDOR_ID, PSA_LOAD_DTS
           FROM {{ source('sap', 'lfa1') }} as SRC ),
SRC_A as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC )
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_S
    INNER JOIN FILTER_A ON '1' = '1'
)
"""
        findings = check_primary_src_no_business_rules(sql, VPSA_PATH, file_status=FileStatus.NEW)
        assert findings == []

    def test_pass_with_inline_comment(self):
        """WHERE has inline comment — acceptable."""
        sql = """
SRC_S as ( SELECT VENDOR_ID, PSA_LOAD_DTS
           FROM {{ source('sap', 'lfa1') }} as SRC
           WHERE PSA_DELETE_IND = 'N' -- required per JIRA-1234
           QUALIFY ROW_NUMBER() OVER (PARTITION BY VENDOR_ID ORDER BY PSA_LOAD_DTS DESC) = 1 -- dedup for grain
),
SRC_A as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC )
, JOIN_RESULT as ( SELECT * FROM FILTER_S INNER JOIN FILTER_A ON '1' = '1' )
"""
        findings = check_primary_src_no_business_rules(sql, VPSA_PATH, file_status=FileStatus.NEW)
        assert findings == []

    def test_fail_where_no_comment(self):
        """WHERE without comment — fires."""
        sql = """
SRC_S as ( SELECT VENDOR_ID, PSA_LOAD_DTS
           FROM {{ source('sap', 'lfa1') }} as SRC
           WHERE PSA_DELETE_IND = 'N'
),
SRC_A as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC )
, JOIN_RESULT as ( SELECT * FROM FILTER_S INNER JOIN FILTER_A ON '1' = '1' )
"""
        findings = check_primary_src_no_business_rules(sql, VPSA_PATH, file_status=FileStatus.NEW)
        assert len(findings) == 1
        assert "WHERE" in findings[0].message
        assert findings[0].severity == Severity.WARN

    def test_fail_qualify_no_comment(self):
        """QUALIFY without comment — fires."""
        sql = """
SRC_S as ( SELECT VENDOR_ID, PSA_LOAD_DTS
           FROM {{ source('sap', 'lfa1') }} as SRC
           QUALIFY ROW_NUMBER() OVER (PARTITION BY VENDOR_ID ORDER BY PSA_LOAD_DTS DESC) = 1
),
SRC_A as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC )
, JOIN_RESULT as ( SELECT * FROM FILTER_S INNER JOIN FILTER_A ON '1' = '1' )
"""
        findings = check_primary_src_no_business_rules(sql, VPSA_PATH, file_status=FileStatus.NEW)
        assert len(findings) == 1
        assert "QUALIFY" in findings[0].message

    def test_fail_both_where_and_qualify(self):
        """Both WHERE and QUALIFY without comments — 2 findings."""
        sql = """
SRC_S as ( SELECT VENDOR_ID, PSA_LOAD_DTS
           FROM {{ source('sap', 'lfa1') }} as SRC
           WHERE PSA_DELETE_IND = 'N'
           QUALIFY ROW_NUMBER() OVER (PARTITION BY VENDOR_ID ORDER BY PSA_LOAD_DTS DESC) = 1
),
SRC_A as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC )
, JOIN_RESULT as ( SELECT * FROM FILTER_S INNER JOIN FILTER_A ON '1' = '1' )
"""
        findings = check_primary_src_no_business_rules(sql, VPSA_PATH, file_status=FileStatus.NEW)
        assert len(findings) == 2

    def test_join_layer_identifies_driver_not_first_cte(self):
        """SRC_b appears first with WHERE, but JOIN says SRC_S is driver — SRC_b exempt."""
        sql = """
SRC_b as ( SELECT FAR_ID FROM {{ source('sap', 'far') }}
           WHERE STATUS = 'ACTIVE'
),
SRC_S as ( SELECT VENDOR_ID, PSA_LOAD_DTS
           FROM {{ source('sap', 'lfa1') }} as SRC
),
SRC_bkcc as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC )
, JOIN_RESULT as (
    SELECT * FROM FILTER_S
    INNER JOIN FILTER_bkcc ON '1' = '1'
    LEFT JOIN FILTER_b ON FILTER_S.VENDOR_ID = FILTER_b.FAR_ID
)
"""
        findings = check_primary_src_no_business_rules(sql, VPSA_PATH, file_status=FileStatus.NEW)
        assert findings == [], "Secondary SRC_b with WHERE should be exempt"

    def test_join_layer_flags_driver_not_secondary(self):
        """SRC_promo is driver per JOIN, SRC_xref secondary with QUALIFY — only driver flagged."""
        sql = """
SRC_promo as ( SELECT ACCOUNT, PSA_LOAD_DTS FROM {{ source('rgm', 'promo') }}
              WHERE PSA_DELETE_IND = 'N'
),
SRC_a as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC ),
SRC_xref as ( SELECT ERP_KEY FROM {{ source('rgm', 'xref') }}
              QUALIFY ROW_NUMBER() OVER (PARTITION BY ERP_KEY ORDER BY PSA_LOAD_DTS DESC) = 1
)
, JOIN_RESULT as (
    SELECT * FROM FILTER_promo
    INNER JOIN FILTER_a ON '1' = '1'
    LEFT JOIN FILTER_xref ON FILTER_promo.ERP_KEY = FILTER_xref.ERP_KEY
)
"""
        findings = check_primary_src_no_business_rules(sql, VPSA_PATH, file_status=FileStatus.NEW)
        assert len(findings) == 1
        assert "SRC_promo" in findings[0].message

    def test_fallback_no_join_result(self):
        """No JOIN_RESULT — falls back to first non-BKCC SRC_*."""
        sql = """
SRC_BKCC as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} ),
SRC_ORDERS as ( SELECT ORDER_ID FROM {{ source('erp', 'orders') }}
                WHERE STATUS = 'OPEN'
)
"""
        findings = check_primary_src_no_business_rules(sql, VPSA_PATH, file_status=FileStatus.NEW)
        assert len(findings) == 1
        assert "SRC_ORDERS" in findings[0].message

    def test_fallback_logic_layer_identifies_driver(self):
        """No JOIN_RESULT but has LOGIC layer — uses first LOGIC_<suffix> to identify driver."""
        sql = """
SRC_b as ( SELECT FAR_ID FROM {{ source('sap', 'far') }}
           WHERE STATUS = 'ACTIVE'
),
SRC_a as ( SELECT VENDOR_ID FROM {{ source('sap', 'lfa1') }}
           WHERE MANDT = '100'
),
SRC_bkcc as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} )
---- LOGIC LAYER ----
, LOGIC_a as ( SELECT VENDOR_ID::TEXT as SUPPLIER_BK FROM SRC_a )
, LOGIC_b as ( SELECT FAR_ID FROM SRC_b )
, LOGIC_bkcc as ( SELECT BKCC, REC_SRC FROM SRC_bkcc )
"""
        findings = check_primary_src_no_business_rules(sql, VPSA_PATH, file_status=FileStatus.NEW)
        # LOGIC_a is first non-BKCC LOGIC → SRC_a is driver → flagged
        # SRC_b has WHERE but is secondary → exempt
        assert len(findings) == 1
        assert "SRC_a" in findings[0].message

    def test_block_comment_suppresses(self):
        """Block comment above WHERE suppresses the finding."""
        sql = """
SRC_S as ( SELECT VENDOR_ID, PSA_LOAD_DTS
           FROM {{ source('sap', 'lfa1') }} as SRC
           /* filter deletes per DV standard */
           WHERE PSA_DELETE_IND = 'N'
           QUALIFY ROW_NUMBER() OVER (PARTITION BY VENDOR_ID ORDER BY PSA_LOAD_DTS DESC) = 1
),
SRC_A as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC )
, JOIN_RESULT as ( SELECT * FROM FILTER_S INNER JOIN FILTER_A ON '1' = '1' )
"""
        findings = check_primary_src_no_business_rules(sql, VPSA_PATH, file_status=FileStatus.NEW)
        assert findings == []

    def test_skip_non_staging_path(self):
        """Non-staging model — N3 does not apply."""
        sql = """
SRC_S as ( SELECT VENDOR_ID FROM {{ source('sap', 'lfa1') }}
           WHERE PSA_DELETE_IND = 'N'
)
, JOIN_RESULT as ( SELECT * FROM FILTER_S )
"""
        findings = check_primary_src_no_business_rules(sql, NON_STAGING_PATH, file_status=FileStatus.NEW)
        assert findings == []

    def test_secondary_src_exempt_via_join_layer(self):
        """Secondary source CTE with QUALIFY is exempt when JOIN identifies different driver."""
        sql = """
SRC_S as ( SELECT VENDOR_ID, PSA_LOAD_DTS
           FROM {{ source('sap', 'lfa1') }} as SRC ),
SRC_FAR as ( SELECT FAR_ID FROM {{ source('sap', 'far') }}
             QUALIFY ROW_NUMBER() OVER (PARTITION BY FAR_ID ORDER BY PSA_LOAD_DTS DESC) = 1
),
SRC_A as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC )
, JOIN_RESULT as (
    SELECT * FROM FILTER_S
    INNER JOIN FILTER_A ON '1' = '1'
    LEFT JOIN FILTER_FAR ON FILTER_S.VENDOR_ID = FILTER_FAR.FAR_ID
)
"""
        findings = check_primary_src_no_business_rules(sql, VPSA_PATH, file_status=FileStatus.NEW)
        assert findings == []

    def test_distant_block_comment_does_not_suppress(self):
        """A block comment far above (header) should NOT suppress N3 for undocumented WHERE."""
        sql = """
SRC_S as ( SELECT VENDOR_ID, PSA_LOAD_DTS
           /* This CTE loads vendor master data from SAP LFA1 table */
           , STATUS
           , REGION
           , COUNTRY
           FROM {{ source('sap', 'lfa1') }} as SRC
           WHERE PSA_DELETE_IND = 'N'
           QUALIFY ROW_NUMBER() OVER (PARTITION BY VENDOR_ID ORDER BY PSA_LOAD_DTS DESC) = 1
),
SRC_A as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC )
, JOIN_RESULT as ( SELECT * FROM FILTER_S INNER JOIN FILTER_A ON '1' = '1' )
"""
        findings = check_primary_src_no_business_rules(sql, VPSA_PATH, file_status=FileStatus.NEW)
        # The block comment is >2 lines above WHERE — should NOT suppress either keyword
        assert len(findings) == 2
        assert findings[0].check_id == "N3"
        assert "WHERE" in findings[0].message
        assert "QUALIFY" in findings[1].message
