---- SRC LAYER ----
WITH
SRC_H              as ( SELECT * FROM {{ ref('hub_purchasing_record') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT * FROM {{ ref('sat_purchasing_record__winn_sap') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY PURCHASING_RECORD_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.HUB_PURCHASING_RECORD )
, SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.SAT_PURCHASING_RECORD__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_PURCHASING_RECORD'                                      as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , PURCHASING_RECORD_HK
      , PURCHASING_RECORD_BK
      , BKCC
      , REC_SRC
    FROM SRC_H
)

, LOGIC_SAT_WINN as (
    SELECT
        URZLA                                                        as                                   COUNTRY_OF_ISSUE
      , MEINS                                                        as                                 PO_UNIT_OF_MEASURE
      , UMREZ                                                        as                           NUMERATOR_UOM_CONVERSION
      , UMREN                                                        as                         DENOMINATOR_UOM_CONVERSION
      , LMEIN                                                        as                               BASE_UNIT_OF_MEASURE
      , CASE WHEN LOEKZ ='X' THEN 'Y'
        WHEN LOEKZ ='' THEN 'N' END                                  as                          PURCHASING_RECORD_DEL_IND
      , ERDAT                                                        as                    PURCHASING_RECORD_CREATION_DATE
      , PURCHASING_RECORD_HK                                         as                      SAT_WINN_PURCHASING_RECORD_HK
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
    FROM SRC_SAT_WINN
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , PURCHASING_RECORD_HK
      , PURCHASING_RECORD_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_H
)

, RENAME_SAT_WINN as (
    SELECT
        COUNTRY_OF_ISSUE
      , PO_UNIT_OF_MEASURE
      , NUMERATOR_UOM_CONVERSION
      , DENOMINATOR_UOM_CONVERSION
      , BASE_UNIT_OF_MEASURE
      , PURCHASING_RECORD_DEL_IND
      , PURCHASING_RECORD_CREATION_DATE
      , SAT_WINN_PURCHASING_RECORD_HK
      , SAT_WINN_PSA_DELETE_IND
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
        ON FILTER_H.PURCHASING_RECORD_HK = SAT_WINN_PURCHASING_RECORD_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , PURCHASING_RECORD_HK
        , PURCHASING_RECORD_BK
        , COUNTRY_OF_ISSUE
        , PO_UNIT_OF_MEASURE
        , NUMERATOR_UOM_CONVERSION
        , DENOMINATOR_UOM_CONVERSION
        , BASE_UNIT_OF_MEASURE
        , PURCHASING_RECORD_DEL_IND
        , PURCHASING_RECORD_CREATION_DATE
        , BKCC
        , REC_SRC
FROM JOIN_RESULT