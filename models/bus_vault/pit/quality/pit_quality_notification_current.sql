{{
  config(
    materialized = 'incremental',
    unique_key='QUALITY_NOTIFICATION_HK',
    incremental_strategy= 'merge'
  )
}}

---- SRC LAYER ----
WITH
SRC_H              as ( SELECT * FROM {{ ref('hub_quality_notification') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT * FROM {{ ref('sat_quality_notification__winn_sap') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY QUALITY_NOTIFICATION_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.HUB_QUALITY_NOTIFICATION )
, SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.SAT_QUALITY_NOTIFICATION__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_QUALITY_NOTIFICATION'                                   as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , QUALITY_NOTIFICATION_HK
      , QUALITY_NOTIFICATION_BK                                     
      , BKCC
      , REC_SRC
    FROM SRC_H
)

, LOGIC_SAT_WINN as (
    SELECT
        QUALITY_NOTIFICATION_HK
      , QMART
      , QMTXT
      , MZEIT
      , CAST(STRMN AS INTEGER)                                     as                        REQUIRED_START_DATE__YYYYMMDD
      , CAST(LTRMN AS INTEGER)                                     as                          REQUIRED_END_DATE__YYYYMMDD
      , AUFNR
      , OBJNR
      , CAST(QMDAB AS INTEGER)                                        as                          COMPLETED_DATE__YYYYMMDD
      , MATKL
      , QMZAB
      , HERKZ
      , MATNR
      , LIFNUM
      , BSTNK
      , SPART
      , VKORG
      , VTWEG
      , REFNUM
      , ESTIMATED_COSTS
      , CLAIMED_COSTS
      , RESULT_COSTS
      , ZZINST_YEAR
      , ZZDATE_CODE
      , ZZREASON_KAT
      , ZZREASON_GRP
      , ZZREASON_COD
      , ZZACTION_KAT
      , ZZACTION_GRP
      , ZZACTION_COD
      , ZZCLAIM_DAMAGE
      , ZZCLAIM_INJURY
      , ZZCLAIM_LABOR
      , ZZCLAIM_PRODUCT
      , ZZCLAIM_LITIGATE
      , ZZCLAIM_SETTLE
      , ZZCLAIM_ENTITY1
      , ZZCLAIM_ENTITY2
      , ZZCLAIM_ENTITY3
      , ZZCLAIM_REF1
      , ZZCLAIM_REF2
      , ZZCLAIM_REF3
      , ZZINIT_SAV_PROJ
      , ZZFORECAST_SAV
      , ZZACTUAL_SAV
      , CAST(QMDAT AS INTEGER)                                       as                        NOTIFICATION_DATE__YYYYMMDD
      , QMNUM
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
    FROM SRC_SAT_WINN
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , QUALITY_NOTIFICATION_HK
      , QUALITY_NOTIFICATION_BK
      , BKCC                                                        as                          HUB_BKCC
      , REC_SRC                                                     as                          HUB_REC_SRC
    FROM LOGIC_H
)

, RENAME_SAT_WINN as (
    SELECT
        QUALITY_NOTIFICATION_HK                                      as                   SAT_WINN_QUALITY_NOTIFICATION_HK
      , QMART                                                        as                                  NOTIFICATION_TYPE
      , QMTXT                                                        as                                 PO_UNIT_OF_MEASURE                                                        
      , MZEIT                                                        as                                  NOTIFICATION_TIME
      , REQUIRED_START_DATE__YYYYMMDD
      , REQUIRED_END_DATE__YYYYMMDD
      , AUFNR                                                        as                                       ORDER_NUMBER
      , OBJNR                                                        as                                      OBJECT_NUMBER
      , COMPLETED_DATE__YYYYMMDD
      , MATKL                                                        as                                     MATERIAL_GROUP
      , QMZAB                                                        as                                     COMPLETED_TIME
      , HERKZ                                                        as                             ORIGIN_OF_NOTIFICATION
      , MATNR                                                        as                                        ITEM_NUMBER
      , LIFNUM                                                       as                                      VENDOR_NUMBER
      , BSTNK                                                        as                                     PURCHASE_ORDER
      , SPART                                                        as                                           DIVISION
      , VKORG                                                        as                                 SALES_ORGANIZATION
      , VTWEG                                                        as                               DISTRIBUTION_CHANNEL
      , REFNUM                                                       as                          EXTERNAL_REFERENCE_NUMBER
      , ESTIMATED_COSTS
      , CLAIMED_COSTS
      , RESULT_COSTS
      , ZZINST_YEAR                                                  as                                     INSTALLED_YEAR
      , ZZDATE_CODE                                                  as                                          DATE_CODE
      , ZZREASON_KAT                                                 as                                    REASON_CATEGORY
      , ZZREASON_GRP                                                 as                                       REASON_GROUP
      , ZZREASON_COD                                                 as                                        REASON_CODE
      , ZZACTION_KAT                                                 as                                    ACTION_CATEGORY
      , ZZACTION_GRP                                                 as                                       ACTION_GROUP
      , ZZACTION_COD                                                 as                                        ACTION_CODE
      , ZZCLAIM_DAMAGE                                               as                                 CLAIM_DAMAGE_COSTS
      , ZZCLAIM_INJURY                                               as                                 CLAIM_INJURY_COSTS
      , ZZCLAIM_LABOR                                                as                                  CLAIM_LABOR_COSTS
      , ZZCLAIM_PRODUCT                                              as                                CLAIM_PRODUCT_COSTS
      , ZZCLAIM_LITIGATE                                             as                             CLAIM_LITIGATION_COSTS
      , ZZCLAIM_SETTLE                                               as                             CLAIM_SETTLEMENT_COSTS
      , ZZCLAIM_ENTITY1                                              as                                     CLAIM_ENTITY_1
      , ZZCLAIM_ENTITY2                                              as                                     CLAIM_ENTITY_2
      , ZZCLAIM_ENTITY3                                              as                                     CLAIM_ENTITY_3
      , ZZCLAIM_REF1                                                 as                                  CLAIM_REFERENCE_1
      , ZZCLAIM_REF2                                                 as                                  CLAIM_REFERENCE_2
      , ZZCLAIM_REF3                                                 as                                  CLAIM_REFERENCE_3
      , ZZINIT_SAV_PROJ                                              as                           INITIAL_SAVINGS_ESTIMATE
      , ZZFORECAST_SAV                                               as                                  FORCASTED_SAVINGS
      , ZZACTUAL_SAV                                                 as                                     ACTUAL_SAVINGS
      , NOTIFICATION_DATE__YYYYMMDD
      , QMNUM                                                        as                                    NOTIFICATION_BK
      , PSA_DELETE_IND
      , BKCC                                                         as                                   SAT_WINN_BKCC
      , REC_SRC                                                      as                                   SAT_WINN_REC_SRC
    FROM LOGIC_SAT_WINN
)
---- FILTER LAYER ----

, FILTER_H as (
    SELECT *
    FROM RENAME_H
    WHERE HUB_REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_SAT_WINN as (
    SELECT *
    FROM RENAME_SAT_WINN
    WHERE SAT_WINN_REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_H
    LEFT JOIN FILTER_SAT_WINN
        ON FILTER_H.QUALITY_NOTIFICATION_HK = FILTER_SAT_WINN.SAT_WINN_QUALITY_NOTIFICATION_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , QUALITY_NOTIFICATION_HK
        , QUALITY_NOTIFICATION_BK
        , NOTIFICATION_TYPE
        , PO_UNIT_OF_MEASURE
        , NOTIFICATION_TIME
        , REQUIRED_START_DATE__YYYYMMDD
        , REQUIRED_END_DATE__YYYYMMDD
        , ORDER_NUMBER
        , OBJECT_NUMBER
        , COMPLETED_DATE__YYYYMMDD
        , MATERIAL_GROUP
        , COMPLETED_TIME
        , ORIGIN_OF_NOTIFICATION
        , ITEM_NUMBER
        , VENDOR_NUMBER
        , PURCHASE_ORDER
        , DIVISION
        , SALES_ORGANIZATION
        , DISTRIBUTION_CHANNEL
        , EXTERNAL_REFERENCE_NUMBER
        , ESTIMATED_COSTS
        , CLAIMED_COSTS
        , RESULT_COSTS
        , INSTALLED_YEAR
        , DATE_CODE
        , REASON_CATEGORY
        , REASON_GROUP
        , REASON_CODE
        , ACTION_CATEGORY
        , ACTION_GROUP
        , ACTION_CODE
        , CLAIM_DAMAGE_COSTS
        , CLAIM_INJURY_COSTS
        , CLAIM_LABOR_COSTS
        , CLAIM_PRODUCT_COSTS
        , CLAIM_LITIGATION_COSTS
        , CLAIM_SETTLEMENT_COSTS
        , CLAIM_ENTITY_1
        , CLAIM_ENTITY_2
        , CLAIM_ENTITY_3
        , CLAIM_REFERENCE_1
        , CLAIM_REFERENCE_2
        , CLAIM_REFERENCE_3
        , INITIAL_SAVINGS_ESTIMATE
        , FORCASTED_SAVINGS
        , ACTUAL_SAVINGS
        , NOTIFICATION_DATE__YYYYMMDD
        , COALESCE(SAT_WINN_BKCC, HUB_BKCC) as BKCC
        , COALESCE(SAT_WINN_REC_SRC, HUB_REC_SRC) as REC_SRC
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND END as IS_DELETED
FROM JOIN_RESULT
{% if is_incremental() %}
    WHERE QUALITY_NOTIFICATION_HK NOT IN (
        SELECT QUALITY_NOTIFICATION_HK 
        FROM {{ this }}
    )
    AND DATE(NOTIFICATION_DATE__YYYYMMDD) >= DATE_TRUNC('day', CURRENT_DATE() - 60)
{% endif %}
