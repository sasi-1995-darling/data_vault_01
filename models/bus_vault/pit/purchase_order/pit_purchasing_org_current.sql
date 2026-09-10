---- SRC LAYER ----
WITH
SRC_H              as ( SELECT * FROM {{ ref('hub_purchasing_org') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT * FROM {{ ref('sat_purchasing_org__winn_sap') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY PURCHASING_ORG_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.HUB_PURCHASING_ORG )
, SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.SAT_PURCHASING_ORG__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_PURCHASING_ORG'                                         as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , PURCHASING_ORG_HK
      , PURCHASING_ORG_BK
      , BKCC
      , REC_SRC
    FROM SRC_H
)

, LOGIC_SAT_WINN as (
    SELECT
        EKNAM                                                        as                                PURCHASING_ORG_DESC
      , PURCHASING_ORG_HK                                            as                         SAT_WINN_PURCHASING_ORG_HK
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
    FROM SRC_SAT_WINN
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , PURCHASING_ORG_HK
      , PURCHASING_ORG_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_H
)

, RENAME_SAT_WINN as (
    SELECT
        PURCHASING_ORG_DESC
      , SAT_WINN_PURCHASING_ORG_HK
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
        ON FILTER_H.PURCHASING_ORG_HK = SAT_WINN_PURCHASING_ORG_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , PURCHASING_ORG_HK
        , PURCHASING_ORG_BK
        , PURCHASING_ORG_DESC
        , BKCC
        , REC_SRC
FROM JOIN_RESULT