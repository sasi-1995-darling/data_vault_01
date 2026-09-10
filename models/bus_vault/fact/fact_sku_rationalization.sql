---- SRC LAYER ----
WITH
SRC_PB             as ( SELECT
                            ITEM_HK
                          , DELETION_SEGMENT
                          , PRODUCT_SEGMENT
                          , PRODUCT_GROUP
                          , PLATFORM
                          , NODE
                          , PRODUCT_STYLE
                          , ITEM_NUMBER
                          , BASE_MATERIAL_NUMBER
                          , GS_BASE_YR_AMT
                          , GS_CURRENT_YR_AMT
                          , GS_PRIOR_YR_AMT
                          , UNITS_BASE_YR_QTY
                          , UNITS_CURRENT_YR_QTY
                          , UNITS_PRIOR_YR_QTY
                          , GS_CURRENT_YR_RT_AMT
                          , GS_CURRENT_YR_WH_AMT
                          , GS_CURRENT_YR_EC_AMT
                          , GS_CURRENT_YR_DR_AMT
                          , GS_3YR_CAGR
                          , dollar_difference_amt
                          , unit_difference_qty
                          , yoy_growth_pct
                          , PCT_RANK_PRE
                          , GS_CUM_SHARE_BY_NODE
                          , GS_VALUE_80_20_TREND_TAG_BY_NODE
                          , UNITS_CUM_SHARE_BY_NODE
                          , UNITS_VALUE_80_20_TREND_TAG_BY_NODE
                          , GS_CUM_SHARE
                          , GS_VALUE_80_20_TREND_TAG
                          , UNITS_CUM_SHARE
                          , UNITS_VALUE_80_20_TREND_TAG
                          , GS_CUM_SHARE_BY_PRODUCT_SEGMENT
                          , GS_VALUE_80_20_TREND_TAG_BY_PRODUCT_SEGMENT
                          , UNITS_CUM_SHARE_BY_PRODUCT_SEGMENT
                          , UNITS_VALUE_80_20_TREND_TAG_BY_PRODUCT_SEGMENT
                          , GS_CUM_SHARE_BY_PRODUCT_GROUP
                          , GS_VALUE_80_20_TREND_TAG_BY_PRODUCT_GROUP
                          , UNITS_CUM_SHARE_BY_PRODUCT_GROUP
                          , UNITS_VALUE_80_20_TREND_TAG_BY_PRODUCT_GROUP
                          , GS_CUM_SHARE_BY_PLATFORM
                          , GS_VALUE_80_20_TREND_TAG_BY_PLATFORM
                          , UNITS_CUM_SHARE_BY_PLATFORM
                          , UNITS_VALUE_80_20_TREND_TAG_BY_PLATFORM
                          , ITEM_FINISH
                          , PRODUCT_LINE
                          , PRODUCT_TYPE
                          , PRICE_BAND
                          , LAUNCH_DATE__YYYYMMDD
                          , LAUNCH_DATE__YYYY
                          , LAUNCH_YEAR_SOURCE
                          , PRODUCT_AGE_YEARS
                          , D_CHAIN_STATUS
                          , IS_NEWER_PRODUCT
                          , GROSS_SALES
                          , NET_SALES
                          , COGS
                          , STANDARD_MARGIN_DOLLARS
                          , PRODUCT_MARGIN_DOLLARS
                          , STANDARD_MARGIN
                          , PRODUCT_MARGIN
                          , BRAND
                          , BKCC
                          , REC_SRC
                        FROM {{ ref('pb_sku_rationalization') }} as SRC  )

/*
SRC_PB             as ( SELECT * FROM BUS_VAULT.PB_SKU_RATIONALIZATION )
*/
---- LOGIC LAYER ----

, LOGIC_PB as (
    SELECT
        ITEM_HK
      , DELETION_SEGMENT
      , PRODUCT_SEGMENT
      , PRODUCT_GROUP
      , PLATFORM
      , NODE
      , PRODUCT_STYLE
      , ITEM_NUMBER
      , BASE_MATERIAL_NUMBER
      , GS_BASE_YR_AMT
      , GS_CURRENT_YR_AMT
      , GS_PRIOR_YR_AMT
      , UNITS_BASE_YR_QTY
      , UNITS_CURRENT_YR_QTY
      , UNITS_PRIOR_YR_QTY
      , GS_CURRENT_YR_RT_AMT
      , GS_CURRENT_YR_WH_AMT
      , GS_CURRENT_YR_EC_AMT
      , GS_CURRENT_YR_DR_AMT
      , GS_3YR_CAGR
      , dollar_difference_amt
      , unit_difference_qty
      , yoy_growth_pct
      , PCT_RANK_PRE
      , GS_CUM_SHARE_BY_NODE
      , GS_VALUE_80_20_TREND_TAG_BY_NODE
      , UNITS_CUM_SHARE_BY_NODE
      , UNITS_VALUE_80_20_TREND_TAG_BY_NODE
      , GS_CUM_SHARE
      , GS_VALUE_80_20_TREND_TAG
      , UNITS_CUM_SHARE
      , UNITS_VALUE_80_20_TREND_TAG
      , GS_CUM_SHARE_BY_PRODUCT_SEGMENT
      , GS_VALUE_80_20_TREND_TAG_BY_PRODUCT_SEGMENT
      , UNITS_CUM_SHARE_BY_PRODUCT_SEGMENT
      , UNITS_VALUE_80_20_TREND_TAG_BY_PRODUCT_SEGMENT
      , GS_CUM_SHARE_BY_PRODUCT_GROUP
      , GS_VALUE_80_20_TREND_TAG_BY_PRODUCT_GROUP
      , UNITS_CUM_SHARE_BY_PRODUCT_GROUP
      , UNITS_VALUE_80_20_TREND_TAG_BY_PRODUCT_GROUP
      , GS_CUM_SHARE_BY_PLATFORM
      , GS_VALUE_80_20_TREND_TAG_BY_PLATFORM
      , UNITS_CUM_SHARE_BY_PLATFORM
      , UNITS_VALUE_80_20_TREND_TAG_BY_PLATFORM
      , ITEM_FINISH
      , PRODUCT_LINE
      , PRODUCT_TYPE
      , PRICE_BAND
      , LAUNCH_DATE__YYYYMMDD
      , LAUNCH_DATE__YYYY
      , LAUNCH_YEAR_SOURCE
      , PRODUCT_AGE_YEARS
      , D_CHAIN_STATUS
      , IS_NEWER_PRODUCT
      , GROSS_SALES
      , NET_SALES
      , COGS
      , STANDARD_MARGIN_DOLLARS
      , PRODUCT_MARGIN_DOLLARS
      , STANDARD_MARGIN
      , PRODUCT_MARGIN
      , BRAND
      , BKCC
      , REC_SRC
    FROM SRC_PB
)
---- RENAME LAYER ----

, RENAME_PB as (
    SELECT
        ITEM_HK
      , DELETION_SEGMENT
      , PRODUCT_SEGMENT
      , PRODUCT_GROUP
      , PLATFORM
      , NODE
      , PRODUCT_STYLE
      , ITEM_NUMBER
      , BASE_MATERIAL_NUMBER
      , GS_BASE_YR_AMT
      , GS_CURRENT_YR_AMT
      , GS_PRIOR_YR_AMT
      , UNITS_BASE_YR_QTY
      , UNITS_CURRENT_YR_QTY
      , UNITS_PRIOR_YR_QTY
      , GS_CURRENT_YR_RT_AMT
      , GS_CURRENT_YR_WH_AMT
      , GS_CURRENT_YR_EC_AMT
      , GS_CURRENT_YR_DR_AMT
      , GS_3YR_CAGR
      , dollar_difference_amt
      , unit_difference_qty
      , yoy_growth_pct
      , PCT_RANK_PRE
      , GS_CUM_SHARE_BY_NODE
      , GS_VALUE_80_20_TREND_TAG_BY_NODE
      , UNITS_CUM_SHARE_BY_NODE
      , UNITS_VALUE_80_20_TREND_TAG_BY_NODE
      , GS_CUM_SHARE
      , GS_VALUE_80_20_TREND_TAG
      , UNITS_CUM_SHARE
      , UNITS_VALUE_80_20_TREND_TAG
      , GS_CUM_SHARE_BY_PRODUCT_SEGMENT
      , GS_VALUE_80_20_TREND_TAG_BY_PRODUCT_SEGMENT
      , UNITS_CUM_SHARE_BY_PRODUCT_SEGMENT
      , UNITS_VALUE_80_20_TREND_TAG_BY_PRODUCT_SEGMENT
      , GS_CUM_SHARE_BY_PRODUCT_GROUP
      , GS_VALUE_80_20_TREND_TAG_BY_PRODUCT_GROUP
      , UNITS_CUM_SHARE_BY_PRODUCT_GROUP
      , UNITS_VALUE_80_20_TREND_TAG_BY_PRODUCT_GROUP
      , GS_CUM_SHARE_BY_PLATFORM
      , GS_VALUE_80_20_TREND_TAG_BY_PLATFORM
      , UNITS_CUM_SHARE_BY_PLATFORM
      , UNITS_VALUE_80_20_TREND_TAG_BY_PLATFORM
      , ITEM_FINISH
      , PRODUCT_LINE
      , PRODUCT_TYPE
      , PRICE_BAND
      , LAUNCH_DATE__YYYYMMDD
      , LAUNCH_DATE__YYYY
      , LAUNCH_YEAR_SOURCE
      , PRODUCT_AGE_YEARS
      , D_CHAIN_STATUS
      , IS_NEWER_PRODUCT
      , GROSS_SALES
      , NET_SALES
      , COGS
      , STANDARD_MARGIN_DOLLARS
      , PRODUCT_MARGIN_DOLLARS
      , STANDARD_MARGIN
      , PRODUCT_MARGIN
      , BRAND
      , BKCC
      , REC_SRC
    FROM LOGIC_PB
)
---- FILTER LAYER ----

, FILTER_PB as (
    SELECT *
    FROM RENAME_PB
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PB
)

---- FINAL LAYER ----
SELECT
        ITEM_HK
      , DELETION_SEGMENT
      , PRODUCT_SEGMENT
      , PRODUCT_GROUP
      , PLATFORM
      , NODE
      , PRODUCT_STYLE
      , ITEM_NUMBER
      , BASE_MATERIAL_NUMBER
      , GS_BASE_YR_AMT
      , GS_CURRENT_YR_AMT
      , GS_PRIOR_YR_AMT
      , UNITS_BASE_YR_QTY
      , UNITS_CURRENT_YR_QTY
      , UNITS_PRIOR_YR_QTY
      , GS_CURRENT_YR_RT_AMT
      , GS_CURRENT_YR_WH_AMT
      , GS_CURRENT_YR_EC_AMT
      , GS_CURRENT_YR_DR_AMT
      , GS_3YR_CAGR
      , dollar_difference_amt
      , unit_difference_qty
      , yoy_growth_pct
      , PCT_RANK_PRE
      , GS_CUM_SHARE_BY_NODE
      , GS_VALUE_80_20_TREND_TAG_BY_NODE
      , UNITS_CUM_SHARE_BY_NODE
      , UNITS_VALUE_80_20_TREND_TAG_BY_NODE
      , GS_CUM_SHARE
      , GS_VALUE_80_20_TREND_TAG
      , UNITS_CUM_SHARE
      , UNITS_VALUE_80_20_TREND_TAG
      , GS_CUM_SHARE_BY_PRODUCT_SEGMENT
      , GS_VALUE_80_20_TREND_TAG_BY_PRODUCT_SEGMENT
      , UNITS_CUM_SHARE_BY_PRODUCT_SEGMENT
      , UNITS_VALUE_80_20_TREND_TAG_BY_PRODUCT_SEGMENT
      , GS_CUM_SHARE_BY_PRODUCT_GROUP
      , GS_VALUE_80_20_TREND_TAG_BY_PRODUCT_GROUP
      , UNITS_CUM_SHARE_BY_PRODUCT_GROUP
      , UNITS_VALUE_80_20_TREND_TAG_BY_PRODUCT_GROUP
      , GS_CUM_SHARE_BY_PLATFORM
      , GS_VALUE_80_20_TREND_TAG_BY_PLATFORM
      , UNITS_CUM_SHARE_BY_PLATFORM
      , UNITS_VALUE_80_20_TREND_TAG_BY_PLATFORM
      , ITEM_FINISH
      , PRODUCT_LINE
      , PRODUCT_TYPE
      , PRICE_BAND
      , LAUNCH_DATE__YYYYMMDD
      , LAUNCH_DATE__YYYY
      , LAUNCH_YEAR_SOURCE
      , PRODUCT_AGE_YEARS
      , D_CHAIN_STATUS
      , IS_NEWER_PRODUCT
      , GROSS_SALES
      , NET_SALES
      , COGS
      , STANDARD_MARGIN_DOLLARS
      , PRODUCT_MARGIN_DOLLARS
      , STANDARD_MARGIN
      , PRODUCT_MARGIN
      , BRAND
      , BKCC
      , REC_SRC
FROM JOIN_RESULT
