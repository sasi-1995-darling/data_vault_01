---- SRC LAYER ----
WITH
SRC_promo          as ( SELECT ACCOUNT, ADDITIONAL_PRODUCT_DISPLAY_COST, ADDITIONAL_TRADE_FUNDING_REQUEST, BASE_INVOICE_PRICE, BASE_MATERIAL, BASE_RETAIL_PRICE, 
                        BILLBACK_AMT, BU, COGS_PER_UNIT, FISCAL_YEAR, FUNDING, G_2_N_BEFORE_TRADE, OWNER, PAYMENT_TYPE, PLANNED_BASE_UNITS, PLANNED_BASE_UPSPW, 
                        PLANNED_CM_DOLLARS_BEFORE_TRADE, PLANNED_INCR_CM_DOLLARS, PLANNED_INCR_UNITS, PLANNED_PROMO_SPEND_DOLLARS, PROMO_DOLLARS_PER_UNIT_EXC_FIXED, 
                        PROMO_END_DATE, PROMO_ID, PROMO_NAME, PROMO_RETAIL_PRICE, PROMO_START_DATE, PROMO_STATUS, PROMO_TYPE, PSA_DELETE_IND, PSA_LOAD_DTS, 
                        PSA_RECORD_SOURCE, PURE_PLAY, REPORTING_CATEGORY, RETAILER, STORE_COUNT, TRADE_SPEND, VARIABLE_COSTS_RATE, _FILE, _FIVETRAN_SYNCED, _LINE, 
                        _MODIFIED FROM {{ source('rgm_promotion', 'promo_flow_input') }} as SRC 
                        /*The filter isolates water/moen from other BUs in promo dataset*/
                        WHERE BU = 'WATER'
                        /*The dedup  removes ONLY exact duplicates (same business key + same values due to multi-file load) 
                         and keeps all rows with different values (scenarios, splits, value changes due to DQ issues at source)*/ 
                        QUALIFY 1 = ROW_NUMBER() OVER (
                            PARTITION BY 
                                -- Business Key
                                PROMO_ID, 
                                RETAILER, 
                                BASE_MATERIAL, 
                                PROMO_START_DATE, 
                                PROMO_END_DATE,
                                PROMO_NAME,
                                -- Value Fingerprint
                                HASH(
                                    COALESCE(OWNER, ''), COALESCE(ACCOUNT, ''), COALESCE(BU, ''),
                                    COALESCE(PROMO_STATUS, ''),
                                    COALESCE(PROMO_TYPE, ''), COALESCE(PAYMENT_TYPE, ''),
                                    COALESCE(STORE_COUNT, 0), COALESCE(BASE_RETAIL_PRICE, ''),
                                    COALESCE(PROMO_RETAIL_PRICE, ''), COALESCE(PLANNED_BASE_UPSPW, ''),
                                    COALESCE(FUNDING, 0), COALESCE(ADDITIONAL_TRADE_FUNDING_REQUEST, 0),
                                    COALESCE(ADDITIONAL_PRODUCT_DISPLAY_COST, ''),
                                    COALESCE(FISCAL_YEAR, 0), COALESCE(REPORTING_CATEGORY, ''),
                                    COALESCE(PURE_PLAY, ''), COALESCE(BASE_INVOICE_PRICE, ''),
                                    COALESCE(PLANNED_BASE_UNITS, ''), COALESCE(PLANNED_INCR_UNITS, ''),
                                    COALESCE(PROMO_DOLLARS_PER_UNIT_EXC_FIXED, 0),
                                    COALESCE(BILLBACK_AMT, 0), COALESCE(PLANNED_PROMO_SPEND_DOLLARS, 0),
                                    COALESCE(G_2_N_BEFORE_TRADE, 0), COALESCE(COGS_PER_UNIT, ''),
                                    COALESCE(VARIABLE_COSTS_RATE, 0),
                                    COALESCE(PLANNED_CM_DOLLARS_BEFORE_TRADE, 0),
                                    COALESCE(PLANNED_INCR_CM_DOLLARS, 0), COALESCE(TRADE_SPEND, '')
                                )--COALESCE ensures NULL and empty values are treated as identical
                            ORDER BY _MODIFIED DESC, _FIVETRAN_SYNCED DESC, _LINE DESC
                            ) ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_erp_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_xref           as ( SELECT ERP_KEY_ACCOUNT_GROUP, ERP_REC_SRC, RETAILER_KEY_ACCOUNT_GROUP FROM {{ source('rgm_promotion', 'retailer_key_account_group_xref') }} as SRC 
                        /*The following Source Layer Filter isolates the Water lookup values for join to bring in Key account group bk for promo data*/
                        WHERE ERP_REC_SRC = 'USOHNO.SAP.ECCPRD.Z_TVV2T' )

/*
SRC_promo          as ( SELECT * FROM rgm_promotion.promo_flow_input )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_erp_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_xref           as ( SELECT * FROM rgm_promotion.retailer_key_account_group_xref )
*/
---- LOGIC LAYER ----

, LOGIC_promo as (
    SELECT
        COALESCE(NULLIF(UPPER(TRIM(BASE_MATERIAL)),''),'-1')         as                                   BASE_MATERIAL_BK
      , COALESCE(NULLIF(UPPER(TRIM(PROMO_NAME)),''),'-1')            as                                       PROMOTION_BK
      , /* VERSION_SEQ: Discriminator column to distinguish multiple concurrently valid 
            records sharing the same composite business key. Allows tracking of attribute
            changes over time across PROMO_ID, RETAILER, BASE_MATERIAL, PROMO_START_DATE,
            PROMO_END_DATE, and PROMO_NAME. Sequence: 1 = most recent, 2 = previous, 3 = older, etc. */
            ROW_NUMBER() OVER (
            PARTITION BY PROMO_ID, RETAILER, BASE_MATERIAL,
            PROMO_START_DATE, PROMO_END_DATE, PROMO_NAME
            ORDER BY _MODIFIED DESC, _FIVETRAN_SYNCED DESC, _LINE DESC
        )                                                            as                                        VERSION_SEQ
      , _FILE
      , _LINE
      , _MODIFIED
      , _FIVETRAN_SYNCED
      , PROMO_ID
      , OWNER
      , RETAILER
      , ACCOUNT
      , BU
      , PROMO_NAME
      , PROMO_STATUS
      , PROMO_TYPE
      , PAYMENT_TYPE
      , PROMO_START_DATE
      , PROMO_END_DATE
      , STORE_COUNT
      , BASE_RETAIL_PRICE
      , PROMO_RETAIL_PRICE
      , PLANNED_BASE_UPSPW
      , FUNDING
      , ADDITIONAL_TRADE_FUNDING_REQUEST
      , ADDITIONAL_PRODUCT_DISPLAY_COST
      , FISCAL_YEAR
      , REPORTING_CATEGORY
      , PURE_PLAY
      , BASE_INVOICE_PRICE
      , PLANNED_BASE_UNITS
      , PLANNED_INCR_UNITS
      , PROMO_DOLLARS_PER_UNIT_EXC_FIXED
      , BILLBACK_AMT
      , PLANNED_PROMO_SPEND_DOLLARS
      , G_2_N_BEFORE_TRADE
      , COGS_PER_UNIT
      , VARIABLE_COSTS_RATE
      , PLANNED_CM_DOLLARS_BEFORE_TRADE
      , PLANNED_INCR_CM_DOLLARS
      , TRADE_SPEND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , IFF(
            PSA_DELETE_IND = 'Y',
        PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC',_FIVETRAN_SYNCED))      as                                           LOAD_DTS
      , BASE_MATERIAL                                                as                                PROMO_BASE_MATERIAL
    FROM SRC_promo
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)

, LOGIC_erp_bkcc as (
    SELECT
        BKCC                                                         as                                           ERP_BKCC
      , REC_SRC                                                      as                               ERP_BKCC_ERP_REC_SRC
    FROM SRC_erp_bkcc
)

, LOGIC_xref as (
    SELECT
        ERP_KEY_ACCOUNT_GROUP
      , RETAILER_KEY_ACCOUNT_GROUP                                   as                                      XREF_RETAILER
      , ERP_REC_SRC                                                  as                                   XREF_ERP_REC_SRC
    FROM SRC_xref
)
---- RENAME LAYER ----

, RENAME_promo as (
    SELECT
        BASE_MATERIAL_BK
      , PROMOTION_BK
      , VERSION_SEQ
      , _FILE
      , _LINE
      , _MODIFIED
      , _FIVETRAN_SYNCED
      , PROMO_ID
      , OWNER
      , RETAILER
      , ACCOUNT
      , BU
      , PROMO_NAME
      , PROMO_STATUS
      , PROMO_TYPE
      , PAYMENT_TYPE
      , PROMO_START_DATE
      , PROMO_END_DATE
      , STORE_COUNT
      , BASE_RETAIL_PRICE
      , PROMO_RETAIL_PRICE
      , PLANNED_BASE_UPSPW
      , FUNDING
      , ADDITIONAL_TRADE_FUNDING_REQUEST
      , ADDITIONAL_PRODUCT_DISPLAY_COST
      , FISCAL_YEAR
      , REPORTING_CATEGORY
      , PURE_PLAY
      , BASE_INVOICE_PRICE
      , PLANNED_BASE_UNITS
      , PLANNED_INCR_UNITS
      , PROMO_DOLLARS_PER_UNIT_EXC_FIXED
      , BILLBACK_AMT
      , PLANNED_PROMO_SPEND_DOLLARS
      , G_2_N_BEFORE_TRADE
      , COGS_PER_UNIT
      , VARIABLE_COSTS_RATE
      , PLANNED_CM_DOLLARS_BEFORE_TRADE
      , PLANNED_INCR_CM_DOLLARS
      , TRADE_SPEND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , PROMO_BASE_MATERIAL
    FROM LOGIC_promo
)

, RENAME_xref as (
    SELECT
        ERP_KEY_ACCOUNT_GROUP
      , XREF_RETAILER
      , XREF_ERP_REC_SRC
    FROM LOGIC_xref
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)

, RENAME_erp_bkcc as (
    SELECT
        ERP_BKCC
      , ERP_BKCC_ERP_REC_SRC
    FROM LOGIC_erp_bkcc
)
---- FILTER LAYER ----

, FILTER_promo as (
    SELECT *
    FROM RENAME_promo
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE REC_SRC = 'US.EXCEL.RGM_PROMO.PROMO_FLOW_INPUT'
)

, FILTER_erp_bkcc as (
    SELECT *
    FROM RENAME_erp_bkcc
)

, FILTER_xref as (
    SELECT *
    FROM RENAME_xref
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_promo
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_xref
        ON retailer = xref_retailer
    LEFT JOIN FILTER_erp_bkcc
        ON xref_erp_rec_src = erp_bkcc_erp_rec_src
)

---- FINAL LAYER ----
SELECT
          BASE_MATERIAL_BK
        , PROMOTION_BK
        , COALESCE(NULLIF(TRIM(ERP_KEY_ACCOUNT_GROUP),''),'-1')        as KEY_ACCOUNT_GROUP_BK
        , VERSION_SEQ
        , _FILE
        , _LINE
        , _MODIFIED
        , _FIVETRAN_SYNCED
        , PROMO_ID
        , OWNER
        , RETAILER
        , ACCOUNT
        , BU
        , TRIM(PROMO_BASE_MATERIAL)                                    as BASE_MATERIAL
        , PROMO_NAME
        , PROMO_STATUS
        , PROMO_TYPE
        , PAYMENT_TYPE
        , PROMO_START_DATE
        , COALESCE(TRY_TO_DATE(PROMO_START_DATE), '9999-12-31')        as PROMO_START_DATE_DT
        , PROMO_END_DATE
        , COALESCE(TRY_TO_DATE(PROMO_END_DATE), '9999-12-31')          as PROMO_END_DATE_DT
        , STORE_COUNT
        , BASE_RETAIL_PRICE
        , IFNULL(TRY_TO_DECIMAL(BASE_RETAIL_PRICE, 10, 2),0)           as BASE_RETAIL_PRICE_DECIMAL
        , PROMO_RETAIL_PRICE
        , IFNULL(TRY_TO_DECIMAL(PROMO_RETAIL_PRICE,10,2),0)            as PROMO_RETAIL_PRICE_DECIMAL
        , PLANNED_BASE_UPSPW
        , FUNDING
        , ADDITIONAL_TRADE_FUNDING_REQUEST
        , ADDITIONAL_PRODUCT_DISPLAY_COST
        , FISCAL_YEAR
        , REPORTING_CATEGORY
        , PURE_PLAY
        , BASE_INVOICE_PRICE
        , IFNULL(TRY_TO_DECIMAL(BASE_INVOICE_PRICE, 10, 2),0)          as BASE_INVOICE_PRICE_DECIMAL
        , PLANNED_BASE_UNITS
        , IFNULL(TRY_TO_DECIMAL(PLANNED_BASE_UNITS, 10, 2),0)          as PLANNED_BASE_UNITS_DECIMAL
        , PLANNED_INCR_UNITS
        , IFNULL(TRY_TO_DECIMAL(PLANNED_INCR_UNITS, 10, 2),0)          as PLANNED_INCR_UNITS_DECIMAL
        , PROMO_DOLLARS_PER_UNIT_EXC_FIXED
        , BILLBACK_AMT
        , PLANNED_PROMO_SPEND_DOLLARS
        , G_2_N_BEFORE_TRADE
        , COGS_PER_UNIT
        , VARIABLE_COSTS_RATE
        , PLANNED_CM_DOLLARS_BEFORE_TRADE
        , PLANNED_INCR_CM_DOLLARS
        , TRADE_SPEND
        , TRY_TO_DECIMAL(TRADE_SPEND, 10, 2)                           as TRADE_SPEND_DECIMAL
        , ERP_KEY_ACCOUNT_GROUP
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , ERP_BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BASE_MATERIAL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ERP_BKCC as VARCHAR)),''), '^^')
        ))) as BASE_MATERIAL_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PROMOTION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ERP_BKCC as VARCHAR)),''), '^^')
        ))) as PROMOTION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(KEY_ACCOUNT_GROUP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ERP_BKCC as VARCHAR)),''), '^^')
        ))) as KEY_ACCOUNT_GROUP_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(KEY_ACCOUNT_GROUP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BASE_MATERIAL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PROMOTION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ERP_BKCC as VARCHAR)),''), '^^')
        ))) as LNK_ACCOUNT_BASE_MATERIAL_PROMOTION_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(OWNER::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(BU::text), '^^') 
            , '||', IFNULL(TRIM(PROMO_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(PROMO_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PAYMENT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(STORE_COUNT::text), '^^') 
            , '||', IFNULL(TRIM(BASE_RETAIL_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(PROMO_RETAIL_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(PLANNED_BASE_UPSPW::text), '^^') 
            , '||', IFNULL(TRIM(FUNDING::text), '^^') 
            , '||', IFNULL(TRIM(ADDITIONAL_TRADE_FUNDING_REQUEST::text), '^^') 
            , '||', IFNULL(TRIM(ADDITIONAL_PRODUCT_DISPLAY_COST::text), '^^') 
            , '||', IFNULL(TRIM(FISCAL_YEAR::text), '^^') 
            , '||', IFNULL(TRIM(REPORTING_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(PURE_PLAY::text), '^^') 
            , '||', IFNULL(TRIM(BASE_INVOICE_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(PLANNED_BASE_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(PLANNED_INCR_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(PROMO_DOLLARS_PER_UNIT_EXC_FIXED::text), '^^') 
            , '||', IFNULL(TRIM(BILLBACK_AMT::text), '^^') 
            , '||', IFNULL(TRIM(PLANNED_PROMO_SPEND_DOLLARS::text), '^^') 
            , '||', IFNULL(TRIM(G_2_N_BEFORE_TRADE::text), '^^') 
            , '||', IFNULL(TRIM(COGS_PER_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(VARIABLE_COSTS_RATE::text), '^^') 
            , '||', IFNULL(TRIM(PLANNED_CM_DOLLARS_BEFORE_TRADE::text), '^^') 
            , '||', IFNULL(TRIM(PLANNED_INCR_CM_DOLLARS::text), '^^') 
            , '||', IFNULL(TRIM(TRADE_SPEND::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
