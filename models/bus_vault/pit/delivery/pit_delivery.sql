---- SRC LAYER ----
WITH
SRC_HD             as ( SELECT BKCC, DELIVERY_BK, DELIVERY_HK, REC_SRC FROM {{ ref('hub_delivery_v1') }} as SRC  ),
SRC_SD             as ( SELECT DELIVERY_HK, KUNNR, LFDAT, WADAT_IST, PSA_DELETE_IND, VBELN, VSTEL FROM {{ ref('sat_delivery__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by DELIVERY_HK order by LOAD_DTS DESC) )

/*
SRC_HD             as ( SELECT * FROM RAW_VAULT.HUB_DELIVERY_V1 )
SRC_SD             as ( SELECT * FROM RAW_VAULT.SAT_DELIVERY__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_HD as (
    SELECT
        CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , BKCC
      , 'PIT_DELIVERY'                                               as                                        PIT_REC_SRC
      , REC_SRC
      , DELIVERY_BK
      , DELIVERY_HK
    FROM SRC_HD
)

, LOGIC_SD as (
    SELECT
        DELIVERY_HK                                                  as                                     SD_DELIVERY_HK
      , VBELN                                                        as                                        DELIVERY_ID
      , KUNNR                                                        as                                SHIP_TO_CUSTOMER_ID
      , VSTEL                                                        as                                  SHIPPING_POINT_ID
      , WADAT_IST                                                    as                            ACTUAL_GOODS_ISSUE_DATE
      , LFDAT                                                        as                              PLANNED_DELIVERY_DATE
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
    FROM SRC_SD
)
---- RENAME LAYER ----

, RENAME_HD as (
    SELECT
        PIT_LOAD_DTS
      , BKCC
      , PIT_REC_SRC
      , REC_SRC
      , DELIVERY_BK
      , DELIVERY_HK
    FROM LOGIC_HD
)

, RENAME_SD as (
    SELECT
        SD_DELIVERY_HK
      , DELIVERY_ID
      , SHIP_TO_CUSTOMER_ID
      , SHIPPING_POINT_ID
      , ACTUAL_GOODS_ISSUE_DATE
      , PLANNED_DELIVERY_DATE
      , SAT_WINN_PSA_DELETE_IND
    FROM LOGIC_SD
)
---- FILTER LAYER ----

, FILTER_HD as (
    SELECT *
    FROM RENAME_HD
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'  /* This filter is to exclude the ghost records */
)

, FILTER_SD as (
    SELECT *
    FROM RENAME_SD
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HD
    INNER JOIN FILTER_SD
        ON FILTER_HD.DELIVERY_HK = FILTER_SD.SD_DELIVERY_HK
)

---- FINAL LAYER ----
SELECT
          row_number() over(order by 1)                                as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , PIT_LOAD_DTS
        , BKCC
        , PIT_REC_SRC
        , REC_SRC
        , DELIVERY_BK
        , DELIVERY_HK
        , DELIVERY_ID
        , SHIP_TO_CUSTOMER_ID
        , SHIPPING_POINT_ID
        , ACTUAL_GOODS_ISSUE_DATE::INTEGER                             as ACTUAL_GOODS_ISSUE_DATE__YYYYMMDD
        , PLANNED_DELIVERY_DATE::INTEGER                               as PLANNED_DELIVERY_DATE__YYYYMMDD
        , CASE BKCC WHEN 'Hiding_Tiger' THEN SAT_WINN_PSA_DELETE_IND
    END as IS_DELETED
FROM JOIN_RESULT
