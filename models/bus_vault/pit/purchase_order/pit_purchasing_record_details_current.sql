---- SRC LAYER ----
WITH
SRC_H              as ( SELECT * FROM {{ ref('lnk_purchasing_record_details') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT * FROM {{ ref('lsat_purchasing_record_details__winn_sap') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY PURCHASING_RECORD_DETAILS_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.LNK_PURCHASING_RECORD_DETAILS )
, SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.LSAT_PURCHASING_RECORD_DETAILS__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_PURCHASING_RECORD_DETAIL'                               as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , PURCHASING_RECORD_DETAILS_HK
      , REC_SRC
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , PLANT_HK
    FROM SRC_H
)

, LOGIC_SAT_WINN as (
    SELECT
        INFNR                                                        as                               PURCHASING_RECORD_BK
      , EKORG                                                        as                                  PURCHASING_ORG_BK
      , WERKS                                                        as                                           PLANT_BK
      , NETPR                                                        as                                          NET_PRICE
      , PEINH                                                        as                                         PRICE_UNIT
      , BKCC
      , PRDAT
      , LOEKZ
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
      , PURCHASING_RECORD_DETAILS_HK                                 as              SAT_WINN_PURCHASING_RECORD_DETAILS_HK
    FROM SRC_SAT_WINN
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , PURCHASING_RECORD_DETAILS_HK
      , REC_SRC
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , PLANT_HK
    FROM LOGIC_H
)

, RENAME_SAT_WINN as (
    SELECT
        PURCHASING_RECORD_BK
      , PURCHASING_ORG_BK
      , PLANT_BK
      , NET_PRICE
      , PRICE_UNIT
      , BKCC
      , PRDAT      
      , LOEKZ
      , SAT_WINN_PSA_DELETE_IND
      , SAT_WINN_PURCHASING_RECORD_DETAILS_HK
    FROM LOGIC_SAT_WINN
)
---- FILTER LAYER ----

, FILTER_H as (
    SELECT *
    FROM RENAME_H
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_SAT_WINN as (
    SELECT *
    FROM RENAME_SAT_WINN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_H
    LEFT JOIN FILTER_SAT_WINN
        ON FILTER_H.PURCHASING_RECORD_DETAILS_HK = SAT_WINN_PURCHASING_RECORD_DETAILS_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , PURCHASING_RECORD_DETAILS_HK
        , PURCHASING_RECORD_BK
        , PURCHASING_ORG_BK
        , PLANT_BK
        , NET_PRICE
        , PRICE_UNIT
        , TRY_TO_DATE(PRDAT, 'YYYYMMDD')                               as PRICE_DATE        
        , CASE WHEN LOEKZ ='X' THEN 'Y'
        WHEN LOEKZ ='' THEN 'N' END as PURCHASING_RECORD_DETAIL_DEL_IND
        , BKCC
        , REC_SRC
        , PURCHASING_RECORD_HK
        , PURCHASING_ORG_HK
        , PLANT_HK
FROM JOIN_RESULT