---- SRC LAYER ----
WITH
SRC_lnk            as ( SELECT BASE_MATERIAL_HK, KEY_ACCOUNT_GROUP_HK, LNK_ACCOUNT_BASE_MATERIAL_PROMOTION_HK, PROMOTION_HK 
                        FROM {{ ref('lnk_account_base_material_promotion') }} as SRC  ),
SRC_sat            as ( SELECT ACCOUNT, ADDITIONAL_PRODUCT_DISPLAY_COST, ADDITIONAL_TRADE_FUNDING_REQUEST, BASE_INVOICE_PRICE, BASE_MATERIAL, BASE_RETAIL_PRICE, 
                        BILLBACK_AMT, BU, COGS_PER_UNIT, FUNDING, HASHDIFF, G_2_N_BEFORE_TRADE, LNK_ACCOUNT_BASE_MATERIAL_PROMOTION_HK, LOAD_DTS, OWNER, PAYMENT_TYPE, 
                        PLANNED_BASE_UNITS, PLANNED_BASE_UPSPW, PLANNED_CM_DOLLARS_BEFORE_TRADE, PLANNED_INCR_CM_DOLLARS, PLANNED_INCR_UNITS, PLANNED_PROMO_SPEND_DOLLARS, 
                        PROMO_DOLLARS_PER_UNIT_EXC_FIXED, PROMO_END_DATE_DT, PROMO_ID, PROMO_NAME, PROMO_RETAIL_PRICE, PROMO_START_DATE_DT, PROMO_STATUS, PROMO_TYPE, 
                        PURE_PLAY, REC_SRC, REPORTING_CATEGORY, RETAILER, STORE_COUNT, TRADE_SPEND, VARIABLE_COSTS_RATE, VERSION_SEQ, _MODIFIED 
                        FROM {{ ref('lmsat_account_base_material_promotion__winn_rgm') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY LNK_ACCOUNT_BASE_MATERIAL_PROMOTION_HK, PROMO_ID, PROMO_START_DATE_DT, PROMO_END_DATE_DT, VERSION_SEQ 
                        ORDER BY LOAD_DTS DESC) ),
SRC_hbm            as ( SELECT BASE_MATERIAL_BK, BASE_MATERIAL_HK FROM {{ ref('hub_base_material') }} as SRC  ),
SRC_hp             as ( SELECT PROMOTION_BK, PROMOTION_HK FROM {{ ref('hub_promotion') }} as SRC  ),
SRC_hkag           as ( SELECT KEY_ACCOUNT_GROUP_BK, KEY_ACCOUNT_GROUP_HK FROM {{ ref('hub_key_account_group') }} as SRC  ),
SRC_fs             as ( SELECT DATE, DATE_BK, FISCAL_445_CAL_WEEK_YYYYWW FROM {{ ref('dim_date_fiscal_445') }} as SRC 
                        WHERE FISCAL_445_CAL_YEAR >= 2024 /*starting point of promotion data */ ),
SRC_fe             as ( SELECT DATE, FISCAL_445_CAL_WEEK_YYYYWW FROM {{ ref('dim_date_fiscal_445') }} as SRC  ),
SRC_ref            as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE REC_SRC = 'US.EXCEL.RGM_PROMO.PROMO_FLOW_INPUT' ),
SRC_item           as ( SELECT BASE_MATERIAL, ITEM_ID FROM {{ ref('dim_item_fbin')}} as SRC 
                        WHERE BKCC = 'Hiding_Tiger' /*Only Moen Items*/ )

/*
SRC_lnk            as ( SELECT * FROM raw_vault.lnk_account_base_material_promotion )
SRC_sat            as ( SELECT * FROM raw_vault.lmsat_account_base_material_promotion__winn_rgm )
SRC_hbm            as ( SELECT * FROM raw_vault.hub_base_material )
SRC_hp             as ( SELECT * FROM raw_vault.hub_promotion )
SRC_hkag           as ( SELECT * FROM raw_vault.hub_key_account_group )
SRC_fs             as ( SELECT * FROM bus_vault.dim_date_fiscal_445 )
SRC_fe             as ( SELECT * FROM bus_vault.dim_date_fiscal_445 )
SRC_ref            as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/

/*Manually added this block to Pre-aggregate POS by BASE_MATERIAL_HK + REPORTING_CUSTOMER + REPORTING_CHANNEL + fiscal week*/
, SRC_pos_weekly AS (
    SELECT
          bmat.BASE_MATERIAL_HK
        , pos.REPORTING_CUSTOMER
        , pos.REPORTING_CHANNEL
        , cal.FISCAL_445_CAL_WEEK_YYYYWW                            AS FISCAL_WEEK
        , SUM(pos.POS_QTY)                                          AS POS_QTY
    FROM {{ ref('pit_pos_fbin_weekly')}} as pos
    INNER JOIN SRC_item as item
    ON pos.ITEM_ID = item.ITEM_ID
    INNER JOIN SRC_hbm as bmat
    ON item.BASE_MATERIAL = bmat.BASE_MATERIAL_BK
    INNER JOIN SRC_fs as cal  
    ON pos.TRANSACTION_DATEKEY = cal.DATE_BK
    WHERE BRAND  = 'MOEN'
    AND REPORTING_CUSTOMER IN  ('HOME DEPOT', 'LOWES', 'MENARDS', 'AMAZON') 
    GROUP BY ALL 
) 

---- LOGIC LAYER ----

, LOGIC_lnk as (
    SELECT
        LNK_ACCOUNT_BASE_MATERIAL_PROMOTION_HK
      , KEY_ACCOUNT_GROUP_HK
      , BASE_MATERIAL_HK
      , PROMOTION_HK
    FROM SRC_lnk
)

, LOGIC_sat as (
    SELECT
        PROMO_ID                                                     as                                       PROMOTION_ID
      , OWNER                                                        as                                    PROMOTION_OWNER
      , PROMO_START_DATE_DT                                          as                           PROMOTION_START_DATE_KEY
      , PROMO_END_DATE_DT                                            as                             PROMOTION_END_DATE_KEY
      , PROMO_NAME                                                   as                                     PROMOTION_NAME
      , BASE_MATERIAL
      , BU                                                           as                                      BUSINESS_UNIT
      , PROMO_STATUS                                                 as                                   PROMOTION_STATUS
      , PROMO_TYPE                                                   as                                     PROMOTION_TYPE
      , PAYMENT_TYPE
      , ACCOUNT                                                      as                                  PROMOTION_ACCOUNT
      , PURE_PLAY
      , REPORTING_CATEGORY                                           as                       PROMOTION_REPORTING_CATEGORY
      , PROMO_START_DATE_DT                                          as                               PROMOTION_START_DATE
      , TO_CHAR(PROMO_START_DATE_DT, 'YYYYMMDD')::INTEGER            as                     PROMOTION_START_DATE__YYYYMMDD
      , PROMO_END_DATE_DT                                            as                                 PROMOTION_END_DATE
      , TO_CHAR(PROMO_END_DATE_DT, 'YYYYMMDD')::INTEGER              as                       PROMOTION_END_DATE__YYYYMMDD
      , RETAILER                                                     as                       PROMOTION_REPORTING_CUSTOMER
      , CASE WHEN PROMOTION_REPORTING_CUSTOMER = 'AMAZON' THEN 'EC' 
        WHEN PROMOTION_ACCOUNT IN ('HomeDepot.com','Lowes.COM','Amazon','Lowes.com') THEN 'EC' 
        ELSE 'RT' END                                                as                        PROMOTION_REPORTING_CHANNEL
      , STORE_COUNT                                                  as                              PROMOTION_STORE_COUNT
      , BASE_RETAIL_PRICE                                            as                                 BASE_RETAIL_PRICE_
      , TRY_TO_DOUBLE(BASE_RETAIL_PRICE_)                            as                                  BASE_RETAIL_PRICE
      , PROMO_RETAIL_PRICE                                           as                                PROMO_RETAIL_PRICE_
      , TRY_TO_DOUBLE(PROMO_RETAIL_PRICE_)                           as                                 PROMO_RETAIL_PRICE
      , PLANNED_BASE_UPSPW                                           as                                PLANNED_BASE_UPSPW_
      , TRY_TO_DOUBLE(PLANNED_BASE_UPSPW_)                           as                                 PLANNED_BASE_UPSPW
      , FUNDING                                                      as                                       FUNDING_RATE
      , ADDITIONAL_TRADE_FUNDING_REQUEST
      , ADDITIONAL_PRODUCT_DISPLAY_COST                              as                   ADDITIONAL_PRODUCT_DISPLAY_COST_
      , TRY_TO_DOUBLE(ADDITIONAL_PRODUCT_DISPLAY_COST_)              as                    ADDITIONAL_PRODUCT_DISPLAY_COST
      , BASE_INVOICE_PRICE                                           as                                BASE_INVOICE_PRICE_
      , TRY_TO_DOUBLE(BASE_INVOICE_PRICE_)                           as                                 BASE_INVOICE_PRICE
      , PLANNED_BASE_UNITS                                           as                                PLANNED_BASE_UNITS_
      , TRY_TO_DOUBLE(PLANNED_BASE_UNITS_)                           as                                 PLANNED_BASE_UNITS
      , PLANNED_INCR_UNITS                                           as                                PLANNED_INCR_UNITS_
      , TRY_TO_DOUBLE(PLANNED_INCR_UNITS_)                           as                                 PLANNED_INCR_UNITS
      , PROMO_DOLLARS_PER_UNIT_EXC_FIXED
      , BILLBACK_AMT                                                 as                                    BILLBACK_AMOUNT
      , PLANNED_PROMO_SPEND_DOLLARS
      , G_2_N_BEFORE_TRADE                                           as                              G2N_BEFORE_TRADE_RATE
      , COGS_PER_UNIT                                                as                                     COGS_PER_UNIT_
      , TRY_TO_DOUBLE(COGS_PER_UNIT_)                                as                                      COGS_PER_UNIT
      , VARIABLE_COSTS_RATE
      , PLANNED_CM_DOLLARS_BEFORE_TRADE
      , PLANNED_INCR_CM_DOLLARS
      , TRY_TO_DOUBLE(TRADE_SPEND)                                   as                                PLANNED_TRADE_SPEND
      , /*LATEST_FILE_RNK: Ranks by file recency to only load records from the same source file once, if a source file has been ingested multiple times;
        Dedup where LATEST_FILE_RNK=1 */
            ROW_NUMBER() OVER (
            PARTITION BY LNK_ACCOUNT_BASE_MATERIAL_PROMOTION_HK, PROMO_ID, VERSION_SEQ
        ORDER BY _MODIFIED DESC, LOAD_DTS DESC)                      as                                    LATEST_FILE_RNK
      , LNK_ACCOUNT_BASE_MATERIAL_PROMOTION_HK                       as         sat_LNK_ACCOUNT_BASE_MATERIAL_PROMOTION_HK
      , TRADE_SPEND
      , REC_SRC                                                      as                                        sat_REC_SRC
      , VERSION_SEQ
      , _MODIFIED
      , LOAD_DTS
      , HASHDIFF
    FROM SRC_sat
)

, LOGIC_hbm as (
    SELECT
        BASE_MATERIAL_BK
      , BASE_MATERIAL_HK                                             as                               hbm_BASE_MATERIAL_HK
    FROM SRC_hbm
)

, LOGIC_hp as (
    SELECT
        PROMOTION_BK
      , PROMOTION_HK                                                 as                                    hp_PROMOTION_HK
    FROM SRC_hp
)

, LOGIC_hkag as (
    SELECT
        KEY_ACCOUNT_GROUP_BK
      , KEY_ACCOUNT_GROUP_HK                                         as                          hkag_KEY_ACCOUNT_GROUP_HK
    FROM SRC_hkag
)

, LOGIC_fs as (
    SELECT
        DATE
      , DATE_BK
      , FISCAL_445_CAL_WEEK_YYYYWW                                   as                PROMOTION_START_FISCAL_WEEK__YYYYWW
    FROM SRC_fs
)

, LOGIC_fe as (
    SELECT
        FISCAL_445_CAL_WEEK_YYYYWW                                   as                  PROMOTION_END_FISCAL_WEEK__YYYYWW
      , DATE                                                         as                                            fe_DATE
    FROM SRC_fe
)

, LOGIC_ref as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_ref
)
---- RENAME LAYER ----

, RENAME_lnk as (
    SELECT
        LNK_ACCOUNT_BASE_MATERIAL_PROMOTION_HK
      , KEY_ACCOUNT_GROUP_HK
      , BASE_MATERIAL_HK
      , PROMOTION_HK
    FROM LOGIC_lnk
)

, RENAME_hbm as (
    SELECT
        BASE_MATERIAL_BK
      , hbm_BASE_MATERIAL_HK
    FROM LOGIC_hbm
)

, RENAME_hkag as (
    SELECT
        KEY_ACCOUNT_GROUP_BK
      , hkag_KEY_ACCOUNT_GROUP_HK
    FROM LOGIC_hkag
)

, RENAME_hp as (
    SELECT
        PROMOTION_BK
      , hp_PROMOTION_HK
    FROM LOGIC_hp
)

, RENAME_sat as (
    SELECT
        PROMOTION_ID
      , PROMOTION_OWNER
      , PROMOTION_START_DATE_KEY
      , PROMOTION_END_DATE_KEY
      , PROMOTION_NAME
      , BASE_MATERIAL
      , BUSINESS_UNIT
      , PROMOTION_STATUS
      , PROMOTION_TYPE
      , PAYMENT_TYPE
      , PROMOTION_ACCOUNT
      , PURE_PLAY
      , PROMOTION_REPORTING_CATEGORY
      , PROMOTION_START_DATE
      , PROMOTION_START_DATE__YYYYMMDD
      , PROMOTION_END_DATE
      , PROMOTION_END_DATE__YYYYMMDD
      , PROMOTION_REPORTING_CUSTOMER
      , PROMOTION_REPORTING_CHANNEL
      , PROMOTION_STORE_COUNT
      , BASE_RETAIL_PRICE_
      , BASE_RETAIL_PRICE
      , PROMO_RETAIL_PRICE_
      , PROMO_RETAIL_PRICE
      , PLANNED_BASE_UPSPW_
      , PLANNED_BASE_UPSPW
      , FUNDING_RATE
      , ADDITIONAL_TRADE_FUNDING_REQUEST
      , ADDITIONAL_PRODUCT_DISPLAY_COST_
      , ADDITIONAL_PRODUCT_DISPLAY_COST
      , BASE_INVOICE_PRICE_
      , BASE_INVOICE_PRICE
      , PLANNED_BASE_UNITS_
      , PLANNED_BASE_UNITS
      , PLANNED_INCR_UNITS_
      , PLANNED_INCR_UNITS
      , PROMO_DOLLARS_PER_UNIT_EXC_FIXED
      , BILLBACK_AMOUNT
      , PLANNED_PROMO_SPEND_DOLLARS
      , G2N_BEFORE_TRADE_RATE
      , COGS_PER_UNIT_
      , COGS_PER_UNIT
      , VARIABLE_COSTS_RATE
      , PLANNED_CM_DOLLARS_BEFORE_TRADE
      , PLANNED_INCR_CM_DOLLARS
      , PLANNED_TRADE_SPEND
      , LATEST_FILE_RNK
      , sat_LNK_ACCOUNT_BASE_MATERIAL_PROMOTION_HK
      , TRADE_SPEND
      , sat_REC_SRC
      , VERSION_SEQ
      , _MODIFIED
      , LOAD_DTS
      , HASHDIFF
    FROM LOGIC_sat
)

, RENAME_fs as (
    SELECT
        DATE
      , DATE_BK
      , PROMOTION_START_FISCAL_WEEK__YYYYWW
    FROM LOGIC_fs
)

, RENAME_fe as (
    SELECT
        PROMOTION_END_FISCAL_WEEK__YYYYWW
      , fe_DATE
    FROM LOGIC_fe
)

, RENAME_ref as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_ref
)
---- FILTER LAYER ----

, FILTER_lnk as (
    SELECT *
    FROM RENAME_lnk
)

, FILTER_sat as (
    SELECT *
    FROM RENAME_sat
    WHERE  sat_REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED' /* This filter is to exclude the ghost records */
    AND LATEST_FILE_RNK = 1  /* This filter to retain only the most recent file version */
    AND VERSION_SEQ = 1  /* This filter to retain only the most recent version when users modify PK attributes within files 2026-07-06*/
    AND BASE_MATERIAL IS NOT NULL
    AND BASE_INVOICE_PRICE IS NOT NULL
    AND BASE_RETAIL_PRICE IS NOT NULL
    AND PROMO_RETAIL_PRICE IS NOT NULL
    AND PLANNED_BASE_UNITS > 0
    AND PLANNED_INCR_CM_DOLLARS <> 0
    AND PLANNED_CM_DOLLARS_BEFORE_TRADE <> 0
    AND PLANNED_INCR_UNITS > 0
    AND G2N_Before_Trade_Rate < 1
    QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY PROMOTION_ID, PROMOTION_REPORTING_CUSTOMER, BASE_MATERIAL,  
    PROMOTION_START_DATE, PROMOTION_END_DATE, PROMOTION_NAME ORDER BY PLANNED_BASE_UNITS DESC)
 /*apply logic above to pull highest planned based units, apply value exclusions and outlier removal due to data entry DQ issues as per business doc "20250715- Promo Process Documentation_vf 2 2.xlsx"*/
)

, FILTER_hbm as (
    SELECT *
    FROM RENAME_hbm
)

, FILTER_hp as (
    SELECT *
    FROM RENAME_hp
)

, FILTER_hkag as (
    SELECT *
    FROM RENAME_hkag
)

, FILTER_fs as (
    SELECT *
    FROM RENAME_fs
)

, FILTER_fe as (
    SELECT *
    FROM RENAME_fe
)

, FILTER_ref as (
    SELECT *
    FROM RENAME_ref
)

---- JOIN LAYER ----
/*Manually added this block to extract distinct promo windows for POS aggregation - built early to avoid scanning full JOIN_RESULT*/
, PROMO_WINDOWS AS (
    SELECT
          lnk.BASE_MATERIAL_HK
        , sat.PROMOTION_REPORTING_CUSTOMER
        , sat.PROMOTION_REPORTING_CHANNEL
        , fs.PROMOTION_START_FISCAL_WEEK__YYYYWW
        , fe.PROMOTION_END_FISCAL_WEEK__YYYYWW
    FROM FILTER_lnk lnk
    INNER JOIN FILTER_sat sat
        ON lnk.LNK_ACCOUNT_BASE_MATERIAL_PROMOTION_HK = sat.sat_LNK_ACCOUNT_BASE_MATERIAL_PROMOTION_HK
    LEFT JOIN FILTER_fs fs
        ON sat.PROMOTION_START_DATE = fs.DATE
    LEFT JOIN FILTER_fe fe
        ON sat.PROMOTION_END_DATE = fe.fe_DATE
    WHERE fs.PROMOTION_START_FISCAL_WEEK__YYYYWW IS NOT NULL
      AND fe.PROMOTION_END_FISCAL_WEEK__YYYYWW IS NOT NULL
    QUALIFY 1 = ROW_NUMBER() OVER (
        PARTITION BY lnk.BASE_MATERIAL_HK, sat.PROMOTION_REPORTING_CUSTOMER, sat.PROMOTION_REPORTING_CHANNEL, 
                     fs.PROMOTION_START_FISCAL_WEEK__YYYYWW, fe.PROMOTION_END_FISCAL_WEEK__YYYYWW 
        ORDER BY (SELECT NULL) -- no specific ordering 
    )
)

, JOIN_RESULT as (
    SELECT *
    FROM FILTER_lnk
    INNER JOIN FILTER_sat
        ON FILTER_lnk.LNK_ACCOUNT_BASE_MATERIAL_PROMOTION_HK = sat_LNK_ACCOUNT_BASE_MATERIAL_PROMOTION_HK
    LEFT JOIN FILTER_hbm
        ON FILTER_lnk.BASE_MATERIAL_HK = hbm_BASE_MATERIAL_HK
    LEFT JOIN FILTER_hp
        ON FILTER_lnk.PROMOTION_HK = hp_PROMOTION_HK
    LEFT JOIN FILTER_hkag
        ON FILTER_lnk.KEY_ACCOUNT_GROUP_HK = hkag_KEY_ACCOUNT_GROUP_HK
    LEFT JOIN FILTER_fs
        ON FILTER_sat.PROMOTION_START_DATE = FILTER_fs.DATE
    LEFT JOIN FILTER_fe
        ON FILTER_sat.PROMOTION_END_DATE = fe_DATE
    INNER JOIN FILTER_ref
        ON '1' = '1'
)

/*Aggregate POS actuals by material + retailer + reporting channel + fiscal week window*/
, POS_AGGREGATED AS (
    SELECT
          pw.BASE_MATERIAL_HK
        , pw.REPORTING_CUSTOMER
        , pw.REPORTING_CHANNEL
        , promo.PROMOTION_START_FISCAL_WEEK__YYYYWW
        , promo.PROMOTION_END_FISCAL_WEEK__YYYYWW
        , SUM(pw.POS_QTY)                                       AS ACTUAL_TOTAL_UNITS
    FROM SRC_POS_WEEKLY  AS pw
    INNER JOIN PROMO_WINDOWS AS promo
        ON pw.BASE_MATERIAL_HK = promo.BASE_MATERIAL_HK
       AND pw.REPORTING_CUSTOMER = promo.PROMOTION_REPORTING_CUSTOMER
       AND pw.REPORTING_CHANNEL = promo.PROMOTION_REPORTING_CHANNEL
       AND pw.FISCAL_WEEK >= promo.PROMOTION_START_FISCAL_WEEK__YYYYWW
       AND pw.FISCAL_WEEK <= promo.PROMOTION_END_FISCAL_WEEK__YYYYWW
    GROUP BY ALL
)

/*Join promotion data with aggregated POS actuals*/
, JOIN_RESULT_2 AS (
    SELECT
          lg.*
        , pos.ACTUAL_TOTAL_UNITS
    FROM JOIN_RESULT AS lg
    LEFT JOIN POS_AGGREGATED AS pos
        ON lg.BASE_MATERIAL_HK = pos.BASE_MATERIAL_HK
       AND lg.PROMOTION_REPORTING_CUSTOMER = pos.REPORTING_CUSTOMER
       AND lg.PROMOTION_REPORTING_CHANNEL = pos.REPORTING_CHANNEL
       AND lg.PROMOTION_START_FISCAL_WEEK__YYYYWW = pos.PROMOTION_START_FISCAL_WEEK__YYYYWW
       AND lg.PROMOTION_END_FISCAL_WEEK__YYYYWW = pos.PROMOTION_END_FISCAL_WEEK__YYYYWW
)

---- FINAL LAYER ----
SELECT
          SEQ8()                                                       as SEQ_ID
        , 'PB_PROMOTION_EFFECTIVENESS'                                 as PB_REC_SRC
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PB_LOAD_DTS
        , LNK_ACCOUNT_BASE_MATERIAL_PROMOTION_HK
        , KEY_ACCOUNT_GROUP_HK
        , BASE_MATERIAL_HK
        , PROMOTION_HK
        , BASE_MATERIAL_BK
        , KEY_ACCOUNT_GROUP_BK
        , PROMOTION_BK
        , PROMOTION_ID
        , PROMOTION_OWNER
        , PROMOTION_START_DATE_KEY
        , PROMOTION_END_DATE_KEY
        , PROMOTION_NAME
        , BASE_MATERIAL
        , BUSINESS_UNIT
        , PROMOTION_STATUS
        , PROMOTION_TYPE
        , PAYMENT_TYPE
        , PROMOTION_ACCOUNT
        , PURE_PLAY
        , PROMOTION_REPORTING_CATEGORY
        , PROMOTION_START_DATE
        , PROMOTION_START_DATE__YYYYMMDD
        , PROMOTION_END_DATE
        , PROMOTION_END_DATE__YYYYMMDD
        , PROMOTION_REPORTING_CUSTOMER
        , PROMOTION_REPORTING_CHANNEL
        , PROMOTION_START_FISCAL_WEEK__YYYYWW
        , PROMOTION_END_FISCAL_WEEK__YYYYWW
        , PROMOTION_STORE_COUNT
        , BASE_RETAIL_PRICE
        , PROMO_RETAIL_PRICE
        , PLANNED_BASE_UPSPW
        , FUNDING_RATE
        , ADDITIONAL_TRADE_FUNDING_REQUEST
        , ADDITIONAL_PRODUCT_DISPLAY_COST
        , BASE_INVOICE_PRICE
        , PLANNED_BASE_UNITS
        , PLANNED_INCR_UNITS
        , PROMO_DOLLARS_PER_UNIT_EXC_FIXED
        , BILLBACK_AMOUNT
        , PLANNED_PROMO_SPEND_DOLLARS
        , G2N_BEFORE_TRADE_RATE
        , COGS_PER_UNIT
        , VARIABLE_COSTS_RATE
        , PLANNED_CM_DOLLARS_BEFORE_TRADE
        , PLANNED_INCR_CM_DOLLARS
        , PLANNED_TRADE_SPEND
        , (ACTUAL_TOTAL_UNITS)                                         as ACTUAL_TOTAL_UNITS
        , PROMO_RETAIL_PRICE - BASE_RETAIL_PRICE                       as PROMOTION_DISCOUNT_DOLLARS
        , DIV0(PROMO_RETAIL_PRICE - BASE_RETAIL_PRICE, BASE_RETAIL_PRICE) as PROMOTION_DISCOUNT_PER_UNIT_RATE
        , FLOOR((DATEDIFF('day', PROMOTION_START_DATE, PROMOTION_END_DATE) + 7) / 7) as TOTAL_PROMOTION_WEEK_COUNT
        , PLANNED_BASE_UNITS + PLANNED_INCR_UNITS                      as PLANNED_TOTAL_UNITS
        , BASE_INVOICE_PRICE * (PLANNED_BASE_UNITS + PLANNED_INCR_UNITS) as PLANNED_TOTAL_GROSS_SALES
        , PLANNED_INCR_UNITS * BASE_INVOICE_PRICE                      as PLANNED_INCR_GROSS_SALES
        , (PLANNED_BASE_UNITS * BASE_INVOICE_PRICE * (1 - G2N_BEFORE_TRADE_RATE)) - PLANNED_PROMO_SPEND_DOLLARS as PLANNED_BASE_NET_SALES
        , (PLANNED_INCR_UNITS * BASE_INVOICE_PRICE * (1 - G2N_BEFORE_TRADE_RATE)) - PLANNED_PROMO_SPEND_DOLLARS as PLANNED_INCR_NET_SALES
        , PLANNED_BASE_NET_SALES + PLANNED_INCR_NET_SALES              as PLANNED_TOTAL_NET_SALES
        , (PLANNED_BASE_UNITS * BASE_INVOICE_PRICE * (1 - G2N_BEFORE_TRADE_RATE - VARIABLE_COSTS_RATE)) - (PLANNED_BASE_UNITS * COGS_PER_UNIT) + PLANNED_INCR_CM_DOLLARS as PLANNED_TOTAL_CM_DOLLARS
        , DIV0(PLANNED_INCR_UNITS, PLANNED_BASE_UNITS)                 as PLANNED_LIFT
        , DIV0(PLANNED_INCR_CM_DOLLARS, PLANNED_PROMO_SPEND_DOLLARS)   as PLANNED_ROI
        , ACTUAL_TOTAL_UNITS - PLANNED_BASE_UNITS                      as ACTUAL_INCREMENTAL_UNITS
        , ACTUAL_TOTAL_UNITS * BASE_INVOICE_PRICE                      as ACTUAL_TOTAL_GROSS_SALES
        , (ACTUAL_TOTAL_UNITS - PLANNED_BASE_UNITS) * BASE_INVOICE_PRICE as ACTUAL_INCREMENTAL_GROSS_SALES
        , COALESCE(ADDITIONAL_TRADE_FUNDING_REQUEST, 0) + (ACTUAL_TOTAL_UNITS * COALESCE(PROMO_DOLLARS_PER_UNIT_EXC_FIXED, 0)) as ACTUAL_TRADE_SPEND
        , (ACTUAL_TOTAL_UNITS * BASE_INVOICE_PRICE * (1 - G2N_BEFORE_TRADE_RATE))
      - (COALESCE(ADDITIONAL_TRADE_FUNDING_REQUEST, 0) + (ACTUAL_TOTAL_UNITS * COALESCE(PROMO_DOLLARS_PER_UNIT_EXC_FIXED, 0))) as ACTUAL_TOTAL_NET_SALES
        , ((ACTUAL_TOTAL_UNITS - PLANNED_BASE_UNITS) * BASE_INVOICE_PRICE * (1 - G2N_BEFORE_TRADE_RATE))
      - (COALESCE(ADDITIONAL_TRADE_FUNDING_REQUEST, 0) + (ACTUAL_TOTAL_UNITS * COALESCE(PROMO_DOLLARS_PER_UNIT_EXC_FIXED, 0))) as ACTUAL_INCREMENTAL_NET_SALES
        , ((ACTUAL_TOTAL_UNITS * BASE_INVOICE_PRICE * (1 - G2N_BEFORE_TRADE_RATE))
      - (COALESCE(ADDITIONAL_TRADE_FUNDING_REQUEST, 0) + (ACTUAL_TOTAL_UNITS * COALESCE(PROMO_DOLLARS_PER_UNIT_EXC_FIXED, 0))))
      - (ACTUAL_TOTAL_UNITS * COGS_PER_UNIT)
      - (VARIABLE_COSTS_RATE * ACTUAL_TOTAL_UNITS * BASE_INVOICE_PRICE) as ACTUAL_TOTAL_CM_DOLLARS
        , (((ACTUAL_TOTAL_UNITS - PLANNED_BASE_UNITS) * BASE_INVOICE_PRICE * (1 - G2N_BEFORE_TRADE_RATE))
      - (COALESCE(ADDITIONAL_TRADE_FUNDING_REQUEST, 0) + (ACTUAL_TOTAL_UNITS * COALESCE(PROMO_DOLLARS_PER_UNIT_EXC_FIXED, 0))))
      - ((ACTUAL_TOTAL_UNITS - PLANNED_BASE_UNITS) * COGS_PER_UNIT)
      - (VARIABLE_COSTS_RATE * (ACTUAL_TOTAL_UNITS - PLANNED_BASE_UNITS) * BASE_INVOICE_PRICE) as ACTUAL_INCREMENTAL_CM_DOLLARS
        ,  DIV0(
        (((ACTUAL_TOTAL_UNITS - PLANNED_BASE_UNITS) * BASE_INVOICE_PRICE * (1 - G2N_BEFORE_TRADE_RATE))
          - (COALESCE(ADDITIONAL_TRADE_FUNDING_REQUEST, 0) + (ACTUAL_TOTAL_UNITS * COALESCE(PROMO_DOLLARS_PER_UNIT_EXC_FIXED, 0))))
          - ((ACTUAL_TOTAL_UNITS - PLANNED_BASE_UNITS) * COGS_PER_UNIT)
          - (VARIABLE_COSTS_RATE * (ACTUAL_TOTAL_UNITS - PLANNED_BASE_UNITS) * BASE_INVOICE_PRICE),
        COALESCE(ADDITIONAL_TRADE_FUNDING_REQUEST, 0) + (ACTUAL_TOTAL_UNITS * COALESCE(PROMO_DOLLARS_PER_UNIT_EXC_FIXED, 0))
      ) as ACTUAL_ROI
        , DIV0(ACTUAL_INCREMENTAL_UNITS, PLANNED_BASE_UNITS)           as ACTUAL_LIFT
        , LATEST_FILE_RNK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
                            COALESCE(NULLIF(TRIM(CAST(KEY_ACCOUNT_GROUP_BK as VARCHAR)),''), '^^'),
                            COALESCE(NULLIF(TRIM(CAST(BASE_MATERIAL_BK as VARCHAR)),''), '^^'),
                            COALESCE(NULLIF(TRIM(CAST(PROMOTION_BK as VARCHAR)),''), '^^'),
                            COALESCE(NULLIF(TRIM(CAST(PROMOTION_START_DATE_KEY as VARCHAR)),''), '^^'),
                            COALESCE(NULLIF(TRIM(CAST(PROMOTION_END_DATE_KEY as VARCHAR)),''), '^^')
                            )))  as DIM_PROMOTION_HK
        , REC_SRC
        , BKCC
FROM JOIN_RESULT_2
QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY DIM_PROMOTION_HK, HASHDIFF ORDER BY _MODIFIED DESC)
 /*second layer logic for data entry DQ issues; users make updates that do not change promo attributes and create duplicate records 2026-07-06*/
