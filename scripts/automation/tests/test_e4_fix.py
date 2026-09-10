#!/usr/bin/env python3
"""Test E4 fix: secondary source CTEs with QUALIFY should suppress E4."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))

from code_reviewer import check_qualify_dedup_with_secondary_join, FileStatus

VPSA_PATH = "models/int_staging_views/profitero/v_psa_stg_competitive_products__fiberon_profitero_share.sql"

# Model where every secondary source CTE has QUALIFY — should NOT fire E4
SQL_ALL_SECONDARY_HAVE_QUALIFY = """
---- SRC LAYER ----
WITH
SRC_S              as ( SELECT DIM_RETAILER_PRODUCT_KEY, DIM_RETAILER_KEY FROM some_source as SRC
                        where psa_delete_ind='N'
                        qualify row_number() over(partition by DIM_RETAILER_PRODUCT_KEY order by PSA_LOAD_DTS desc)=1 ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM some_ref as SRC  ),
SRC_FAR            as ( SELECT DIM_RETAILER_PRODUCT_KEY, DIM_ACCOUNT_PRODUCT_KEY FROM some_source2 as SRC
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DIM_RETAILER_PRODUCT_KEY ORDER BY DIM_ACCOUNT_PRODUCT_KEY))=1 ),
SRC_AP             as ( SELECT DIM_ACCOUNT_PRODUCT_KEY, ACCOUNT_PRODUCT_ID FROM some_source3 as SRC
                QUALIFY ROW_NUMBER() OVER (PARTITION BY DIM_ACCOUNT_PRODUCT_KEY ORDER BY UPDATED_AT DESC) = 1 ),
SRC_r              as ( SELECT DIM_RETAILER_KEY, RETAILER_NAME FROM some_source4 as SRC
                QUALIFY ROW_NUMBER() OVER (PARTITION BY DIM_RETAILER_KEY ORDER BY UPDATED_AT DESC) = 1 )
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT s.*, far.DIM_ACCOUNT_PRODUCT_KEY, ap.ACCOUNT_PRODUCT_ID, r.RETAILER_NAME
    FROM SRC_S s
    INNER JOIN SRC_a ON '1' = '1'
    LEFT JOIN SRC_FAR far ON s.DIM_RETAILER_PRODUCT_KEY = far.DIM_RETAILER_PRODUCT_KEY
    LEFT JOIN SRC_AP ap ON far.DIM_ACCOUNT_PRODUCT_KEY = ap.DIM_ACCOUNT_PRODUCT_KEY
    LEFT JOIN SRC_r r ON s.DIM_RETAILER_KEY = r.DIM_RETAILER_KEY
)
---- FINAL LAYER ----
SELECT * FROM JOIN_RESULT
"""

# Model where one secondary CTE does NOT have QUALIFY — should fire E4
SQL_ONE_SECONDARY_MISSING_QUALIFY = """
---- SRC LAYER ----
WITH
SRC_S              as ( SELECT BK FROM some_source as SRC
                        qualify row_number() over(partition by BK order by PSA_LOAD_DTS desc)=1 ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM some_ref as SRC ),
SRC_LOOKUP         as ( SELECT LOOKUP_KEY, LOOKUP_VAL FROM some_lookup as SRC )
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT s.*, lu.LOOKUP_VAL
    FROM SRC_S s
    INNER JOIN SRC_a ON '1' = '1'
    LEFT JOIN SRC_LOOKUP lu ON s.BK = lu.LOOKUP_KEY
)
---- FINAL LAYER ----
SELECT * FROM JOIN_RESULT
"""


def test_all_secondary_ctes_have_qualify_suppresses_e4():
    """E4 should NOT fire when every secondary source CTE already has QUALIFY."""
    findings = check_qualify_dedup_with_secondary_join(
        SQL_ALL_SECONDARY_HAVE_QUALIFY, VPSA_PATH, file_status=FileStatus.NEW
    )
    assert findings == [], f"Expected no findings, got: {[f.message for f in findings]}"


def test_missing_qualify_in_secondary_fires_e4():
    """E4 should fire when a secondary source CTE lacks QUALIFY."""
    findings = check_qualify_dedup_with_secondary_join(
        SQL_ONE_SECONDARY_MISSING_QUALIFY, VPSA_PATH, file_status=FileStatus.NEW
    )
    assert len(findings) == 1
    assert findings[0].check_id == "E4"


def test_intermediate_cte_chain_with_qualify_sources():
    """E4 should NOT fire when SRC_* CTEs have QUALIFY even if JOINs target FILTER_*/LOGIC_* CTEs."""
    # Real-world pattern: SRC → LOGIC → RENAME → FILTER → JOIN_RESULT
    sql = """
---- SRC LAYER ----
WITH
SRC_S as ( SELECT BK, COL1 FROM some_source
           qualify row_number() over(partition by BK order by PSA_LOAD_DTS desc)=1 ),
SRC_a as ( SELECT BKCC, REC_SRC FROM ref_bkcc ),
SRC_FAR as ( SELECT FK, LOOKUP_KEY FROM some_fact
             QUALIFY ROW_NUMBER() OVER(PARTITION BY FK ORDER BY LOOKUP_KEY)=1 ),
SRC_AP as ( SELECT LOOKUP_KEY, VAL FROM some_dim
            QUALIFY ROW_NUMBER() OVER (PARTITION BY LOOKUP_KEY ORDER BY TS DESC) = 1 )
---- LOGIC LAYER ----
, LOGIC_S as ( SELECT BK, COL1 FROM SRC_S )
, LOGIC_a as ( SELECT BKCC, REC_SRC FROM SRC_a )
, LOGIC_p as (
    SELECT far.FK, ap.VAL
    FROM SRC_FAR far
    LEFT JOIN SRC_AP ap ON far.LOOKUP_KEY = ap.LOOKUP_KEY
)
---- RENAME LAYER ----
, RENAME_S as ( SELECT * FROM LOGIC_S )
, RENAME_a as ( SELECT * FROM LOGIC_a )
, RENAME_p as ( SELECT * FROM LOGIC_p )
---- FILTER LAYER ----
, FILTER_S as ( SELECT * FROM RENAME_S )
, FILTER_a as ( SELECT * FROM RENAME_a )
, FILTER_p as ( SELECT * FROM RENAME_p )
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_a ON '1' = '1'
    LEFT JOIN FILTER_p ON FILTER_S.BK = FILTER_p.FK
)
---- FINAL LAYER ----
SELECT * FROM JOIN_RESULT
    """
    findings = check_qualify_dedup_with_secondary_join(sql, VPSA_PATH, file_status=FileStatus.NEW)
    assert findings == [], f"Expected no findings, got: {[f.message for f in findings]}"


def test_commented_out_src_ctes_ignored():
    """E4 should ignore SRC_* CTEs inside block comments."""
    sql = """
WITH
SRC_S as ( SELECT BK FROM source1
           QUALIFY ROW_NUMBER() OVER (PARTITION BY BK ORDER BY TS DESC) = 1 ),
SRC_a as ( SELECT BKCC, REC_SRC FROM ref_business_key_collision ),
SRC_R as ( SELECT KEY, VAL FROM source2
           QUALIFY ROW_NUMBER() OVER (PARTITION BY KEY ORDER BY TS DESC) = 1 )
/*
SRC_S as ( SELECT * FROM schema.table1 )
, SRC_R as ( SELECT * FROM schema.table2 )
*/
, JOIN_RESULT as (
    SELECT *
    FROM SRC_S
    INNER JOIN SRC_a ON '1' = '1'
    LEFT JOIN SRC_R ON SRC_S.BK = SRC_R.KEY
)
SELECT * FROM JOIN_RESULT
    """
    findings = check_qualify_dedup_with_secondary_join(sql, VPSA_PATH, file_status=FileStatus.NEW)
    assert findings == [], f"Expected no findings, got: {[f.message for f in findings]}"


if __name__ == "__main__":
    test_all_secondary_ctes_have_qualify_suppresses_e4()
    print("PASS: test_all_secondary_ctes_have_qualify_suppresses_e4")
    test_missing_qualify_in_secondary_fires_e4()
    print("PASS: test_missing_qualify_in_secondary_fires_e4")
