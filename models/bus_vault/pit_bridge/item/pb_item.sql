---- SRC LAYER ----
WITH
SRC_pbibp          as ( SELECT ACTIVE_ITEM_IND, BASE_MATERIAL, BKCC, BRAND, FORECAST_BASE_MATERIAL, ITEM_ARCHITECTURE, ITEM_ARCHITECTURE_DETAIL, 
                        ITEM_BASE_UOM, ITEM_CATEGORY, ITEM_CLASS, ITEM_FINISH, ITEM_HK, ITEM_NUMBER, ITEM_PRICE_BAND, ITEM_PRODUCT_LINE, 
                        ITEM_PRODUCT_SEGMENT, ITEM_REPORTING_CATEGORY, ITEM_ROOM_AREA_DETAIL, ITEM_SUB_CATEGORY, ITEM_SUB_CLASS, ITEM_TITLE, 
                        ITEM_TYPE_CODE, PNS_PRICE_BAND, REC_SRC, ULTIMATE_ITEM_SUPPLY_SOURCE, ITEM_TYPE_DESCRIPTION, ITEM_PRODUCT_TYPE, 
                        ITEM_STYLE, FIRST_SHIP_DATE, WHEN_NEW_DATE,
                        SALES_ORG, D_CHAIN_CODE FROM {{ ref('pb_items_by_plant') }} as SRC 
                        where 1=1 )
/*
SRC_pbibp          as ( SELECT * FROM bus_vault.pb_items_by_plant )
*/

, SRC_PBSH         as ( SELECT ITEM_ID, BKCC, MIN(TRY_TO_DATE(NULLIF(f.POSTED_DATEKEY, ''), 'YYYYMMDD')) AS FIRST_SOLD_DATE
                        FROM {{ ref('pb_shipment') }} f
                        GROUP BY ALL )
---- LOGIC LAYER ----

, LOGIC_pbibp_main as (
    SELECT
        ITEM_HK
      , ITEM_NUMBER
      , ITEM_TITLE
      , BASE_MATERIAL
      , ITEM_TYPE_CODE
      , ITEM_TYPE_DESCRIPTION
      , ACTIVE_ITEM_IND                                              as                                        ITEM_STATUS
      , BRAND
      , ITEM_CATEGORY
      , ITEM_SUB_CATEGORY
      , ITEM_CLASS
      , ITEM_SUB_CLASS
      , FORECAST_BASE_MATERIAL
      , ULTIMATE_ITEM_SUPPLY_SOURCE
      , ITEM_BASE_UOM
      , ITEM_ARCHITECTURE
      , ITEM_ARCHITECTURE_DETAIL
      , ITEM_FINISH
      , ITEM_PRICE_BAND
      , PNS_PRICE_BAND
      , ITEM_PRODUCT_LINE
      , ITEM_PRODUCT_SEGMENT
      , ITEM_REPORTING_CATEGORY
      , ITEM_ROOM_AREA_DETAIL
      , ITEM_PRODUCT_TYPE
      , ITEM_STYLE
      , MIN(FIRST_SHIP_DATE)                                         as                                       FIRST_SHIP_DATE
      , MIN(WHEN_NEW_DATE)                                           as                                         WHEN_NEW_DATE
      , REC_SRC
      , BKCC
    FROM SRC_pbibp
    GROUP BY ALL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ITEM_HK ORDER BY MIN(SALES_ORG) NULLS LAST) = 1
)

-- d_chain_code: pre-computed per (item_hk, sales_org) in pb_items_by_plant_moen (2026-06-08).
-- Collapse to one row per item via the same precedence used previously:
-- S3 > S4 > S5 > S6 > S0 > S7 > S8 > S2 > S1 > SN > SW.
, LOGIC_d_chain_code as (
    SELECT
        ITEM_HK,
        D_CHAIN_CODE
    FROM SRC_pbibp
    WHERE BKCC = 'Hiding_Tiger'
      AND D_CHAIN_CODE IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY ITEM_HK
        ORDER BY CASE D_CHAIN_CODE
                    WHEN 'S3' THEN 1
                    WHEN 'S4' THEN 2
                    WHEN 'S5' THEN 3
                    WHEN 'S6' THEN 4
                    WHEN 'S0' THEN 5
                    WHEN 'S7' THEN 6
                    WHEN 'S8' THEN 7
                    WHEN 'S2' THEN 8
                    WHEN 'S1' THEN 9
                    WHEN 'SN' THEN 10
                    WHEN 'SW' THEN 11
                    ELSE 99
                 END
    ) = 1
)

, LOGIC_pbsh as (
    SELECT
        ITEM_ID
      , BKCC
      , FIRST_SOLD_DATE
    FROM SRC_PBSH
)
---- RENAME LAYER ----

, RENAME_pbibp_main as (
    SELECT
        ITEM_HK
      , ITEM_NUMBER
      , ITEM_TITLE
      , BASE_MATERIAL
      , ITEM_TYPE_CODE
      , ITEM_TYPE_DESCRIPTION
      , ITEM_STATUS
      , BRAND
      , ITEM_CATEGORY
      , ITEM_SUB_CATEGORY
      , ITEM_CLASS
      , ITEM_SUB_CLASS
      , FORECAST_BASE_MATERIAL
      , ULTIMATE_ITEM_SUPPLY_SOURCE
      , ITEM_BASE_UOM
      , ITEM_ARCHITECTURE
      , ITEM_ARCHITECTURE_DETAIL
      , ITEM_FINISH
      , ITEM_PRICE_BAND
      , PNS_PRICE_BAND
      , ITEM_PRODUCT_LINE
      , ITEM_PRODUCT_SEGMENT
      , ITEM_REPORTING_CATEGORY
      , ITEM_ROOM_AREA_DETAIL
      , ITEM_PRODUCT_TYPE
      , ITEM_STYLE
      , FIRST_SHIP_DATE
      , WHEN_NEW_DATE
      , REC_SRC
      , BKCC
    FROM LOGIC_pbibp_main
)

, RENAME_d_chain_code as (
    SELECT
        ITEM_HK
      , D_CHAIN_CODE
    FROM LOGIC_d_chain_code
)

, RENAME_pbsh as (
    SELECT
        ITEM_ID
      , BKCC
      , FIRST_SOLD_DATE
    FROM LOGIC_pbsh
)
---- FILTER LAYER ----

, FILTER_pbibp_main as (
    SELECT *
    FROM RENAME_pbibp_main
)

, FILTER_pbibp_d_chain_code as (
    SELECT *
    FROM RENAME_d_chain_code
)

, FILTER_pbsh as (
    SELECT *
    FROM RENAME_pbsh
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT
        a.ITEM_HK                                                    as                                            ITEM_ID
      , a.ITEM_NUMBER
      , a.ITEM_TITLE
      , a.BASE_MATERIAL
      , a.ITEM_TYPE_CODE
      , a.ITEM_TYPE_DESCRIPTION
      , a.ITEM_STATUS
      , a.BRAND
      , a.ITEM_CATEGORY
      , a.ITEM_SUB_CATEGORY
      , a.ITEM_CLASS
      , a.ITEM_SUB_CLASS
      , a.FORECAST_BASE_MATERIAL
      , a.ULTIMATE_ITEM_SUPPLY_SOURCE
      , a.ITEM_BASE_UOM
      , a.ITEM_ARCHITECTURE
      , a.ITEM_ARCHITECTURE_DETAIL
      , a.ITEM_FINISH
      , a.ITEM_PRICE_BAND
      , a.PNS_PRICE_BAND
      , a.ITEM_PRODUCT_LINE
      , a.ITEM_PRODUCT_SEGMENT
      , a.ITEM_REPORTING_CATEGORY
      , a.ITEM_ROOM_AREA_DETAIL
      , a.ITEM_PRODUCT_TYPE
      , a.ITEM_STYLE
      , COALESCE(TO_NUMBER(TO_CHAR(COALESCE(a.FIRST_SHIP_DATE, a.WHEN_NEW_DATE, b.FIRST_SOLD_DATE), 'YYYYMMDD')), 19000101) as LAUNCH_DATE__YYYYMMDD
      , COALESCE(CASE
            WHEN a.FIRST_SHIP_DATE IS NOT NULL THEN 'first_ship_date'
            WHEN a.WHEN_NEW_DATE   IS NOT NULL THEN 'when_new_date'
            WHEN b.FIRST_SOLD_DATE IS NOT NULL THEN 'fact_first_sold'
            ELSE NULL
        END, 'N/A')                                                  as LAUNCH_DATE_SOURCE
      , COALESCE(c.D_CHAIN_CODE, 'N/A')                              as D_CHAIN_CODE
      , a.REC_SRC
      , a.BKCC
    FROM FILTER_pbibp_main a
    LEFT JOIN FILTER_pbsh b
      ON a.ITEM_HK = b.ITEM_ID
    LEFT JOIN FILTER_pbibp_d_chain_code c
      ON a.ITEM_HK = c.ITEM_HK
)

---- FINAL LAYER ----
SELECT
        random() as seq_id
        , current_timestamp as snapshot_dts
        , ITEM_ID
        , ITEM_NUMBER
        , ITEM_TITLE
        , BASE_MATERIAL
        , ITEM_TYPE_CODE
        , ITEM_TYPE_DESCRIPTION
        , ITEM_STATUS
        , BRAND
        , ITEM_CATEGORY
        , ITEM_SUB_CATEGORY
        , ITEM_CLASS
        , ITEM_SUB_CLASS
        , FORECAST_BASE_MATERIAL
        , ULTIMATE_ITEM_SUPPLY_SOURCE
        , ITEM_BASE_UOM
        , ITEM_ARCHITECTURE
        , ITEM_ARCHITECTURE_DETAIL
        , ITEM_FINISH
        , ITEM_PRICE_BAND
        , PNS_PRICE_BAND
        , ITEM_PRODUCT_LINE
        , ITEM_PRODUCT_SEGMENT
        , ITEM_REPORTING_CATEGORY
        , ITEM_ROOM_AREA_DETAIL
        , ITEM_PRODUCT_TYPE
        , ITEM_STYLE
        , LAUNCH_DATE__YYYYMMDD
        , LAUNCH_DATE_SOURCE
        , D_CHAIN_CODE
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
