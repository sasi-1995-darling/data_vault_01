---- SRC LAYER ----
WITH
SRC_LD             as ( SELECT DELIVERIES_IN_SHIPMENT_LHK, DELIVERY_HK, REC_SRC, SHIPMENT_HK FROM {{ ref('lnk_deliveries_in_shipment') }} as SRC  ),
SRC_SSL            as ( SELECT DELIVERIES_IN_SHIPMENT_LHK, TPNUM, VBELN FROM {{ ref('lsat_shipment_line__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by DELIVERIES_IN_SHIPMENT_LHK order by LOAD_DTS DESC) ),
SRC_HS             as ( SELECT SHIPMENT_BK, SHIPMENT_HK FROM {{ ref('hub_shipment') }} as SRC  ),
SRC_HD             as ( SELECT BKCC, DELIVERY_BK, DELIVERY_HK FROM {{ ref('hub_delivery_v1') }} as SRC  ),
SRC_SD             as ( SELECT BTGEW, DELIVERY_HK, NTGEW, PSA_DELETE_IND, VOLUM FROM {{ ref('sat_delivery__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by DELIVERY_HK order by LOAD_DTS DESC) ),
SRC_SS             as ( SELECT DALBG, DALEN, DAREG, DATBG, DATEN, DISTZ, DPABF, DPLBG, DPLEN, DPREG, DPTBG, DPTEN, DTABF, DTMEG, SHIPMENT_HK, SHTYP, TDLNR, TKNUM FROM {{ ref('sat_shipment__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by SHIPMENT_HK order by LOAD_DTS DESC) )

/*
SRC_LD             as ( SELECT * FROM RAW_VAULT.LNK_DELIVERIES_IN_SHIPMENT )
SRC_SSL            as ( SELECT * FROM RAW_VAULT.LSAT_SHIPMENT_LINE__WINN_SAP )
SRC_HS             as ( SELECT * FROM RAW_VAULT.HUB_SHIPMENT )
SRC_HD             as ( SELECT * FROM RAW_VAULT.HUB_DELIVERY_V1 )
SRC_SD             as ( SELECT * FROM RAW_VAULT.SAT_DELIVERY__WINN_SAP )
SRC_SS             as ( SELECT * FROM RAW_VAULT.SAT_SHIPMENT__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_LD as (
    SELECT
        CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PB_LOAD_DTS
      , 'PB_SHIPMENT'                                                as                                        PB_REC_SRC
      , REC_SRC
      , DELIVERY_HK
      , SHIPMENT_HK
      , DELIVERIES_IN_SHIPMENT_LHK
    FROM SRC_LD
)

, LOGIC_SSL as (
    SELECT
        DELIVERIES_IN_SHIPMENT_LHK                                   as                     SSL_DELIVERIES_IN_SHIPMENT_LHK
      , VBELN                                                        as                                        DELIVERY_ID
      , TPNUM                                                        as                                   SHIPMENT_ITEM_ID
    FROM SRC_SSL
)

, LOGIC_HS as (
    SELECT
        SHIPMENT_HK                                                  as                                     HS_SHIPMENT_HK
      , SHIPMENT_BK
    FROM SRC_HS
)

, LOGIC_HD as (
    SELECT
        BKCC
      , DELIVERY_BK
      , DELIVERY_HK                                                  as                                     HD_DELIVERY_HK
    FROM SRC_HD
)

, LOGIC_SD as (
    SELECT
        DELIVERY_HK                                                  as                                     SD_DELIVERY_HK
      , CAST(BTGEW AS DECIMAL(18,2))                                 as                           DELIVERY_GROSS_WEIGHT_KG
      , CAST(NTGEW AS DECIMAL(18,2))                                 as                             DELIVERY_NET_WEIGHT_KG
      , CAST(VOLUM AS DECIMAL(18,2))                                 as                                    DELIVERY_VOLUME
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
    FROM SRC_SD
)

, LOGIC_SS as (
    SELECT
        SHIPMENT_HK                                                  as                                     SS_SHIPMENT_HK
      , TKNUM                                                        as                                        SHIPMENT_ID
      , TDLNR                                                        as                                         CARRIER_ID
      , SHTYP                                                        as                                      SHIPMENT_TYPE
      , DPREG                                                        as                              PLANNED_CHECK_IN_DATE
      , DAREG                                                        as                               ACTUAL_CHECK_IN_DATE
      , DPLBG                                                        as                            PLAN_LOADING_START_DATE
      , DPLEN                                                        as                              PLAN_LOADING_END_DATE
      , DALBG                                                        as                          ACTUAL_LOADING_START_DATE
      , DALEN                                                        as                            ACTUAL_LOADING_END_DATE
      , DPABF                                                        as                        PLANNED_SHIPMENT_COMPLETION
      , DTABF                                                        as                         ACTUAL_SHIPMENT_COMPLETION
      , DPTBG                                                        as                        PLANNED_SHIPMENT_START_DATE
      , DPTEN                                                        as                          PLANNED_SHIPMENT_END_DATE
      , DATBG                                                        as                         ACTUAL_SHIPMENT_START_DATE
      , DATEN                                                        as                           ACTUAL_SHIPMENT_END_DATE
      , DTMEG                                                        as                          REF_TOTAL_SHIPMENT_WEIGHT_UNIT
      , DISTZ                                                        as                        REF_TOTAL_SHIPMENT_DISTANCE
    FROM SRC_SS
)
---- RENAME LAYER ----

, RENAME_LD as (
    SELECT
        PB_LOAD_DTS
      , PB_REC_SRC
      , REC_SRC
      , DELIVERY_HK
      , SHIPMENT_HK
      , DELIVERIES_IN_SHIPMENT_LHK
    FROM LOGIC_LD
)

, RENAME_HD as (
    SELECT
        BKCC
      , DELIVERY_BK
      , HD_DELIVERY_HK
    FROM LOGIC_HD
)

, RENAME_HS as (
    SELECT
        HS_SHIPMENT_HK
      , SHIPMENT_BK
    FROM LOGIC_HS
)

, RENAME_SSL as (
    SELECT
        SSL_DELIVERIES_IN_SHIPMENT_LHK
      , DELIVERY_ID
      , SHIPMENT_ITEM_ID
    FROM LOGIC_SSL
)

, RENAME_SD as (
    SELECT
        SD_DELIVERY_HK
      , DELIVERY_GROSS_WEIGHT_KG
      , DELIVERY_NET_WEIGHT_KG
      , DELIVERY_VOLUME
      , SAT_WINN_PSA_DELETE_IND
    FROM LOGIC_SD
)

, RENAME_SS as (
    SELECT
        SS_SHIPMENT_HK
      , SHIPMENT_ID
      , CARRIER_ID
      , SHIPMENT_TYPE
      , PLANNED_CHECK_IN_DATE
      , ACTUAL_CHECK_IN_DATE
      , PLAN_LOADING_START_DATE
      , PLAN_LOADING_END_DATE
      , ACTUAL_LOADING_START_DATE
      , ACTUAL_LOADING_END_DATE
      , PLANNED_SHIPMENT_COMPLETION
      , ACTUAL_SHIPMENT_COMPLETION
      , PLANNED_SHIPMENT_START_DATE
      , PLANNED_SHIPMENT_END_DATE
      , ACTUAL_SHIPMENT_START_DATE
      , ACTUAL_SHIPMENT_END_DATE
      , REF_TOTAL_SHIPMENT_WEIGHT_UNIT
      , REF_TOTAL_SHIPMENT_DISTANCE
    FROM LOGIC_SS
)
---- FILTER LAYER ----

, FILTER_LD as (
    SELECT *
    FROM RENAME_LD
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'
)

, FILTER_SSL as (
    SELECT *
    FROM RENAME_SSL
)

, FILTER_HS as (
    SELECT *
    FROM RENAME_HS
)

, FILTER_HD as (
    SELECT *
    FROM RENAME_HD
)

, FILTER_SD as (
    SELECT *
    FROM RENAME_SD
)

, FILTER_SS as (
    SELECT *
    FROM RENAME_SS
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LD
    INNER JOIN FILTER_SSL
        ON FILTER_LD.DELIVERIES_IN_SHIPMENT_LHK = FILTER_SSL.SSL_DELIVERIES_IN_SHIPMENT_LHK
    LEFT JOIN FILTER_HS
        ON FILTER_LD.SHIPMENT_HK = FILTER_HS.HS_SHIPMENT_HK
    LEFT JOIN FILTER_HD
        ON FILTER_LD.DELIVERY_HK = FILTER_HD.HD_DELIVERY_HK
    LEFT JOIN FILTER_SD
        ON FILTER_HD.HD_DELIVERY_HK = FILTER_SD.SD_DELIVERY_HK
    LEFT JOIN FILTER_SS
        ON FILTER_HS.HS_SHIPMENT_HK = FILTER_SS.SS_SHIPMENT_HK
)

---- FINAL LAYER ----
SELECT
          row_number() over(order by 1)                                as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , PB_LOAD_DTS
        , BKCC
        , PB_REC_SRC
        , REC_SRC
        , DELIVERY_HK
        , SHIPMENT_HK
        , DELIVERY_BK
        , SHIPMENT_BK
        , DELIVERY_ID
        , SHIPMENT_ITEM_ID
        , DELIVERY_GROSS_WEIGHT_KG
        , DELIVERY_NET_WEIGHT_KG
        , DELIVERY_VOLUME
        , SHIPMENT_ID
        , CARRIER_ID
        , SHIPMENT_TYPE
        , PLANNED_CHECK_IN_DATE :: INTEGER AS PLANNED_CHECK_IN_DATE__YYYYMMDD
        , ACTUAL_CHECK_IN_DATE :: INTEGER AS ACTUAL_CHECK_IN_DATE__YYYYMMDD
        , PLAN_LOADING_START_DATE :: INTEGER AS PLAN_LOADING_START_DATE__YYYYMMDD
        , PLAN_LOADING_END_DATE :: INTEGER AS PLAN_LOADING_END_DATE__YYYYMMDD
        , ACTUAL_LOADING_START_DATE :: INTEGER AS ACTUAL_LOADING_START_DATE__YYYYMMDD
        , ACTUAL_LOADING_END_DATE :: INTEGER AS ACTUAL_LOADING_END_DATE__YYYYMMDD
        , PLANNED_SHIPMENT_COMPLETION :: INTEGER AS PLANNED_SHIPMENT_COMPLETION__YYYYMMDD
        , ACTUAL_SHIPMENT_COMPLETION :: INTEGER AS ACTUAL_SHIPMENT_COMPLETION__YYYYMMDD
        , PLANNED_SHIPMENT_START_DATE :: INTEGER AS PLANNED_SHIPMENT_START_DATE__YYYYMMDD
        , PLANNED_SHIPMENT_END_DATE :: INTEGER AS PLANNED_SHIPMENT_END_DATE__YYYYMMDD
        , ACTUAL_SHIPMENT_START_DATE :: INTEGER AS ACTUAL_SHIPMENT_START_DATE__YYYYMMDD
        , ACTUAL_SHIPMENT_END_DATE :: INTEGER AS ACTUAL_SHIPMENT_END_DATE__YYYYMMDD
        , REF_TOTAL_SHIPMENT_WEIGHT_UNIT
        , REF_TOTAL_SHIPMENT_DISTANCE
        , CASE WHEN BKCC = 'Hiding_Tiger' THEN SAT_WINN_PSA_DELETE_IND
           END as IS_DELETED 
FROM JOIN_RESULT
