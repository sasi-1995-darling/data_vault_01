---- SRC LAYER ----
WITH
SRC_L              as ( SELECT PLANT_HK, PURCHASING_ORG_HK, PURCHASING_RECORD_DETAILS_HK, PURCHASING_RECORD_HK, REC_SRC FROM {{ ref('lnk_purchasing_record_details') }} as SRC 
                        /* QUALIFY clause is intentionally not used as DRIVING KEY is combination of all Link Keys */ ),
SRC_HPORG          as ( SELECT PURCHASING_ORG_BK, PURCHASING_ORG_HK FROM {{ ref('hub_purchasing_org_v2') }} as SRC  ),
SRC_HPL            as ( SELECT PLANT_BK, PLANT_HK FROM {{ ref('hub_plant_v1') }} as SRC  ),
SRC_HPR            as ( SELECT BKCC, PURCHASING_RECORD_BK, PURCHASING_RECORD_HK FROM {{ ref('hub_purchasing_record') }} as SRC  ),
SRC_LSAT_WINN      as ( SELECT APLFZ, BPRME, BPUMN, BPUMZ, EKGRP, ERDAT, ESOKZ, LOEKZ, NETPR, PEINH, PRDAT, PSA_DELETE_IND, PURCHASING_RECORD_DETAILS_HK, UEBTO, UNTTO, WAERS FROM {{ ref('lsat_purchasing_record_details__winn_sap') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY PURCHASING_RECORD_DETAILS_HK ORDER BY LOAD_DTS DESC)  ),
SRC_SAT_WINN       as ( SELECT BKCC, ERDAT, IDNLF, LIFNR, LMEIN, LOEKZ, MATNR, MEINS, MFRNR, PURCHASING_RECORD_HK, UMREN, UMREZ, URZLA FROM {{ ref('sat_purchasing_record__winn_sap') }} as SRC 
                         QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY purchasing_record_hk ORDER BY LOAD_DTS DESC) ),
SRC_HIT            as ( SELECT BKCC, ITEM_BK, ITEM_HK FROM {{ ref('hub_item_v1') }} as SRC  ),
SRC_HSUP           as ( SELECT BKCC, SUPPLIER_BK, SUPPLIER_HK FROM {{ ref('hub_supplier_v2') }} as SRC )

/*
SRC_L              as ( SELECT * FROM RAW_VAULT.lnk_purchasing_record_details )
SRC_HPORG          as ( SELECT * FROM RAW_VAULT.hub_purchasing_org_v2 )
SRC_HPL            as ( SELECT * FROM RAW_VAULT.hub_plant_v1 )
SRC_HPR            as ( SELECT * FROM RAW_VAULT.hub_purchasing_record )
SRC_LSAT_WINN      as ( SELECT * FROM RAW_VAULT.lsat_purchasing_record_details__winn_sap )
SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.sat_purchasing_record__winn_sap )
SRC_HIT            as ( SELECT * FROM RAW_VAULT.hub_item_v1 )
SRC_HSUP           as ( SELECT * FROM RAW_VAULT.hub_supplier_v2 )
*/
---- LOGIC LAYER ----

, LOGIC_L as (
    SELECT
        'PB_PURCHASE_INFO_RECORD'                                    as                                         PB_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                        PB_LOAD_DTS
      , REC_SRC
      , PURCHASING_ORG_HK
      , PLANT_HK
      , PURCHASING_RECORD_DETAILS_HK
      , PURCHASING_RECORD_HK
    FROM SRC_L
)

, LOGIC_HPORG as (
    SELECT
        PURCHASING_ORG_BK
      , PURCHASING_ORG_HK                                            as                                H_PURCHASING_ORG_HK
    FROM SRC_HPORG
)

, LOGIC_HPL as (
    SELECT
        PLANT_BK
      , PLANT_HK                                                     as                                         H_PLANT_HK
    FROM SRC_HPL
)

, LOGIC_HPR as (
    SELECT
        PURCHASING_RECORD_BK                                         as                          PURCHASING_INFO_RECORD_BK
      , BKCC
      , PURCHASING_RECORD_HK                                         as                             H_PURCHASING_RECORD_HK
    FROM SRC_HPR
)

, LOGIC_LSAT_WINN as (
    SELECT
        ESOKZ                                                        as                    PURCHASING_INFO_RECORD_CATEGORY
      , EKGRP                                                        as                                   PURCHASING_GROUP
      , WAERS                                                        as                                      CURRENCY_CODE
      , APLFZ                                                        as                      PLANNED_DELIVERY_TIME_IN_DAYS
      , NETPR                                                        as                                          NET_PRICE
      , PEINH                                                        as                                         PRICE_UNIT
      , BPRME                                                        as                                          PRICE_UOM
      , BPUMZ                                                        as                CONVERSION_PRICE_UOM_TO_ORDER_UOM_N
      , BPUMN                                                        as                CONVERSION_PRICE_UOM_TO_ORDER_UOM_D
      , PRDAT
      , UEBTO                                                        as                      OVER_DELIVERY_TOLORANCE_LIMIT
      , UNTTO                                                        as                     UNDER_DELIVERY_TOLORANCE_LIMIT
      , ERDAT
      , ERDAT::INTEGER                                               as                   PIR_PORG_CREATION_DATE_LSAT_WINN
      , LOEKZ                                                        as                                    LOEKZ_LSAT_WINN
      , PSA_DELETE_IND                                               as                                         IS_DELETED
      , PURCHASING_RECORD_DETAILS_HK                                 as                    LS_PURCHASING_RECORD_DETAILS_HK
    FROM SRC_LSAT_WINN
)

, LOGIC_SAT_WINN as (
    SELECT
        MATNR                                                        as                                   SAT_WINN_ITEM_BK
      , LIFNR                                                        as                               SAT_WINN_SUPPLIER_BK
      , MEINS                                                        as                                          ORDER_UOM
      , LMEIN                                                        as                                           BASE_UOM
      , UMREZ                                                        as                 CONVERSION_ORDER_UOM_TO_BASE_UOM_N
      , UMREN                                                        as                 CONVERSION_ORDER_UOM_TO_BASE_UOM_D
      , URZLA                                                        as                                  COUNTRY_OF_ORIGIN
      , IDNLF                                                        as                             VENDOR_MATERIAL_NUMBER
      , MFRNR                                                        as                                       MANUFACTURER
      , ERDAT
      , ERDAT::INTEGER                                               as                         PIR_CREATION_DATE_SAT_WINN
      , LOEKZ                                                        as                                     LOEKZ_SAT_WINN
      , PURCHASING_RECORD_HK                                         as                             S_PURCHASING_RECORD_HK
      , BKCC                                                         as                                      SAT_WINN_BKCC
    FROM SRC_SAT_WINN
)

, LOGIC_HIT as (
    SELECT
        ITEM_BK
      , ITEM_HK
      , BKCC                                                         as                                           HIT_BKCC
    FROM SRC_HIT
)

, LOGIC_HSUP as (
    SELECT
        SUPPLIER_BK
      , SUPPLIER_HK
      , BKCC                                                         as                                          HSUP_BKCC
    FROM SRC_HSUP
)
---- RENAME LAYER ----

, RENAME_L as (
    SELECT
        PB_REC_SRC
      , SNAPSHOTDATE
      , PB_LOAD_DTS
      , REC_SRC
      , PURCHASING_ORG_HK
      , PLANT_HK
      , PURCHASING_RECORD_DETAILS_HK
      , PURCHASING_RECORD_HK
    FROM LOGIC_L
)

, RENAME_HPR as (
    SELECT
        PURCHASING_INFO_RECORD_BK
      , BKCC
      , H_PURCHASING_RECORD_HK
    FROM LOGIC_HPR
)

, RENAME_HIT as (
    SELECT
        ITEM_BK
      , ITEM_HK
      , HIT_BKCC
    FROM LOGIC_HIT
)

, RENAME_HSUP as (
    SELECT
        SUPPLIER_BK
      , SUPPLIER_HK
      , HSUP_BKCC
    FROM LOGIC_HSUP
)

, RENAME_SAT_WINN as (
    SELECT
        SAT_WINN_ITEM_BK
      , SAT_WINN_SUPPLIER_BK
      , ORDER_UOM
      , BASE_UOM
      , CONVERSION_ORDER_UOM_TO_BASE_UOM_N
      , CONVERSION_ORDER_UOM_TO_BASE_UOM_D
      , COUNTRY_OF_ORIGIN
      , VENDOR_MATERIAL_NUMBER
      , MANUFACTURER
      , ERDAT
      , PIR_CREATION_DATE_SAT_WINN
      , LOEKZ_SAT_WINN
      , S_PURCHASING_RECORD_HK
      , SAT_WINN_BKCC
    FROM LOGIC_SAT_WINN
)

, RENAME_HPORG as (
    SELECT
        PURCHASING_ORG_BK
      , H_PURCHASING_ORG_HK
    FROM LOGIC_HPORG
)

, RENAME_HPL as (
    SELECT
        PLANT_BK
      , H_PLANT_HK
    FROM LOGIC_HPL
)

, RENAME_LSAT_WINN as (
    SELECT
        PURCHASING_INFO_RECORD_CATEGORY
      , PURCHASING_GROUP
      , CURRENCY_CODE
      , PLANNED_DELIVERY_TIME_IN_DAYS
      , NET_PRICE
      , PRICE_UNIT
      , PRICE_UOM
      , CONVERSION_PRICE_UOM_TO_ORDER_UOM_N
      , CONVERSION_PRICE_UOM_TO_ORDER_UOM_D
      , PRDAT
      , OVER_DELIVERY_TOLORANCE_LIMIT
      , UNDER_DELIVERY_TOLORANCE_LIMIT
      , ERDAT
      , PIR_PORG_CREATION_DATE_LSAT_WINN
      , LOEKZ_LSAT_WINN
      , IS_DELETED
      , LS_PURCHASING_RECORD_DETAILS_HK
    FROM LOGIC_LSAT_WINN
)
---- FILTER LAYER ----

, FILTER_L as (
    SELECT *
    FROM RENAME_L
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'  /* This filter is to exclude the ghost records */
 
)

, FILTER_HPORG as (
    SELECT *
    FROM RENAME_HPORG
)

, FILTER_HPL as (
    SELECT *
    FROM RENAME_HPL
)

, FILTER_HPR as (
    SELECT *
    FROM RENAME_HPR
)

, FILTER_LSAT_WINN as (
    SELECT *
    FROM RENAME_LSAT_WINN
)

, FILTER_SAT_WINN as (
    SELECT *
    FROM RENAME_SAT_WINN
)

, FILTER_HIT as (
    SELECT *
    FROM RENAME_HIT
)

, FILTER_HSUP as (
    SELECT *
    FROM RENAME_HSUP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_L
    LEFT JOIN FILTER_HPORG
        ON FILTER_L.PURCHASING_ORG_HK = H_PURCHASING_ORG_HK
    LEFT JOIN FILTER_HPL
        ON FILTER_L.PLANT_HK = H_PLANT_HK
    LEFT JOIN FILTER_HPR
        ON FILTER_L.PURCHASING_RECORD_HK = H_PURCHASING_RECORD_HK
    LEFT JOIN FILTER_LSAT_WINN
        ON FILTER_L.PURCHASING_RECORD_DETAILS_HK = LS_PURCHASING_RECORD_DETAILS_HK
    LEFT JOIN FILTER_SAT_WINN
        ON FILTER_L.PURCHASING_RECORD_HK = S_PURCHASING_RECORD_HK
    LEFT JOIN FILTER_HIT
        ON FILTER_SAT_WINN.SAT_WINN_ITEM_BK = FILTER_HIT.ITEM_BK AND SAT_WINN_BKCC = HIT_BKCC
    LEFT JOIN FILTER_HSUP
        ON FILTER_SAT_WINN.SAT_WINN_SUPPLIER_BK = FILTER_HSUP.SUPPLIER_BK AND SAT_WINN_BKCC = HSUP_BKCC
)

---- FINAL LAYER ----
SELECT
          PB_REC_SRC
        , SNAPSHOTDATE
        , PB_LOAD_DTS
        , PURCHASING_INFO_RECORD_BK
        , ITEM_BK
        , SUPPLIER_BK
        , PURCHASING_ORG_BK
        , PLANT_BK
        , PURCHASING_INFO_RECORD_CATEGORY
        , ORDER_UOM
        , BASE_UOM
        , CONVERSION_ORDER_UOM_TO_BASE_UOM_N
        , CONVERSION_ORDER_UOM_TO_BASE_UOM_D
        , COUNTRY_OF_ORIGIN
        , VENDOR_MATERIAL_NUMBER
        , MANUFACTURER
        , PURCHASING_GROUP
        , CURRENCY_CODE
        , PLANNED_DELIVERY_TIME_IN_DAYS
        , NET_PRICE
        , PRICE_UNIT
        , PRICE_UOM
        , CONVERSION_PRICE_UOM_TO_ORDER_UOM_N
        , CONVERSION_PRICE_UOM_TO_ORDER_UOM_D
        , PRDAT::INTEGER                                               as PRICE_VALID_UNTIL__YYYYMMDD
        , OVER_DELIVERY_TOLORANCE_LIMIT
        , UNDER_DELIVERY_TOLORANCE_LIMIT
        , PIR_CREATION_DATE_SAT_WINN                                   as PIR_CREATION_DATE__YYYYMMDD
        , LOEKZ_SAT_WINN
        , CASE WHEN BKCC = 'Hiding_Tiger' AND LOEKZ_SAT_WINN = 'X' 
               THEN 'Y'                                                                          
               ELSE 'N'
        END as PIR_DELETE_INDICATOR
        , PIR_PORG_CREATION_DATE_LSAT_WINN                             as PIR_PORG_CREATION_DATE__YYYYMMDD
        , LOEKZ_LSAT_WINN
        , CASE WHEN BKCC = 'Hiding_Tiger' AND LOEKZ_LSAT_WINN = 'X' 
               THEN 'Y'                                                                          
               ELSE 'N'
        END as PIR_PORG_DELETE_INDICATOR
        , IS_DELETED
        , REC_SRC
        , BKCC
        , ITEM_HK
        , SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PURCHASING_INFO_RECORD_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PURCHASING_ORG_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PURCHASING_INFO_RECORD_CATEGORY as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PURCHASING_INFO_RECORD_ORG_HK
FROM JOIN_RESULT
/* Exclude records that do not exist in EINA and are older than 2002 */
where NOT (PURCHASING_INFO_RECORD_BK IS NULL AND PIR_PORG_CREATION_DATE__YYYYMMDD <= 20021231)
