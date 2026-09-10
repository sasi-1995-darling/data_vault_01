---- SRC LAYER ----
WITH
SRC_HS             as ( SELECT BKCC, REC_SRC, SHIPMENT_BK, SHIPMENT_HK FROM {{ ref('hub_shipment') }} as SRC  ),
SRC_SS             as ( SELECT PSA_DELETE_IND, SHIPMENT_HK, SHTYP, STTRG, TDLNR, TKNUM, VSART FROM {{ ref('sat_shipment__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by SHIPMENT_HK order by LOAD_DTS DESC) )

/*
SRC_HS             as ( SELECT * FROM RAW_VAULT.HUB_SHIPMENT )
SRC_SS             as ( SELECT * FROM RAW_VAULT.SAT_SHIPMENT__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_HS as (
    SELECT
        CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                    as                                       PIT_LOAD_DTS
      , BKCC
      , 'PIT_SHIPMENT'                                                 as                                        PIT_REC_SRC
      , REC_SRC
      , SHIPMENT_BK
      , SHIPMENT_HK
    FROM SRC_HS
)

, LOGIC_SS as (
    SELECT
        SHIPMENT_HK                                                  as                                     SS_SHIPMENT_HK
      , TKNUM                                                        as                                        SHIPMENT_ID
      , SHTYP                                                        as                                      SHIPMENT_TYPE
      , TDLNR                                                        as                                         CARRIER_ID
      , VSART                                                        as                                      SHIPPING_TYPE
      , STTRG                                                        as                                     OVERALL_STATUS
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
    FROM SRC_SS
)
---- RENAME LAYER ----

, RENAME_HS as (
    SELECT
        PIT_LOAD_DTS
      , BKCC
      , PIT_REC_SRC
      , REC_SRC
      , SHIPMENT_BK
      , SHIPMENT_HK
    FROM LOGIC_HS
)

, RENAME_SS as (
    SELECT
        SS_SHIPMENT_HK
      , SHIPMENT_ID
      , SHIPMENT_TYPE
      , CARRIER_ID
      , SHIPPING_TYPE
      , OVERALL_STATUS
      , SAT_WINN_PSA_DELETE_IND
    FROM LOGIC_SS
)
---- FILTER LAYER ----

, FILTER_HS as (
    SELECT *
    FROM RENAME_HS
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'  /* This filter is to exclude the ghost records */
)

, FILTER_SS as (
    SELECT *
    FROM RENAME_SS
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HS
    INNER JOIN FILTER_SS
        ON FILTER_HS.SHIPMENT_HK = FILTER_SS.SS_SHIPMENT_HK
)

---- FINAL LAYER ----
SELECT
          row_number() over(order by 1)                                as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , PIT_LOAD_DTS
        , BKCC
        , PIT_REC_SRC
        , REC_SRC
        , SHIPMENT_BK
        , SHIPMENT_HK
        , SHIPMENT_ID
        , SHIPMENT_TYPE
        , CARRIER_ID
        , SHIPPING_TYPE
        , OVERALL_STATUS
        , CASE BKCC WHEN 'Hiding_Tiger' THEN SAT_WINN_PSA_DELETE_IND
    END as IS_DELETED
FROM JOIN_RESULT
