---- SRC LAYER ----
WITH
SRC_H              as ( SELECT * FROM {{ ref('hub_cost_center_master_data') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT * FROM {{ ref('sat_cost_center_master_data__winn_sap') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY COST_CENTER_MASTER_DATA_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.HUB_COST_CENTER_MASTER_DATA )
, SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.SAT_COST_CENTER_MASTER_DATA__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_COST_CENTER_MASTER_DATA'                                as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , COST_CENTER_MASTER_DATA_HK
      , BKCC
      , REC_SRC
    FROM SRC_H
)

, LOGIC_SAT_WINN as (
    SELECT
        KOKRS                                                        as                                CONTROLLING_AREA_BK
      , KOSTL                                                        as                                     COST_CENTER_BK
      , CAST(DATBI AS INTEGER)                                       as                            VALID_TO_DATE__YYYYMMDD
      , BUKRS                                                        as                                       COMPANY_CODE
      , WAERS                                                        as                                       CURRENCY_KEY
      , KOSAR                                                        as                               COST_CENTER_CATEGORY
      , VERAK                                                        as                                 PERSON_RESPONSIBLE
      , KHINR                                                        as                                 STD_HIERARCHY_AREA
      , FUNC_AREA                                                    as                                    FUNCTIONAL_AREA
      , ABTEI                                                        as                                         DEPARTMENT
      , PSTLZ                                                        as                                        POSTAL_CODE
      , LAND1                                                        as                                        COUNTRY_KEY
      , REGIO                                                        as                                             REGION
      , BKZKP                                                        as                                     LOCK_INDICATOR
      , CAST(DATAB AS INTEGER)                                       as                          VALID_FROM_DATE__YYYYMMDD
      , COST_CENTER_MASTER_DATA_HK                                   as                SAT_WINN_COST_CENTER_MASTER_DATA_HK
      , PSA_DELETE_IND 
    FROM SRC_SAT_WINN
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , COST_CENTER_MASTER_DATA_HK
      , BKCC
      , REC_SRC
    FROM LOGIC_H
)

, RENAME_SAT_WINN as (
    SELECT
        CONTROLLING_AREA_BK
      , COST_CENTER_BK
      , VALID_TO_DATE__YYYYMMDD
      , COMPANY_CODE
      , CURRENCY_KEY
      , COST_CENTER_CATEGORY
      , PERSON_RESPONSIBLE
      , STD_HIERARCHY_AREA
      , FUNCTIONAL_AREA
      , DEPARTMENT
      , POSTAL_CODE
      , COUNTRY_KEY
      , REGION
      , LOCK_INDICATOR
      , VALID_FROM_DATE__YYYYMMDD
      , SAT_WINN_COST_CENTER_MASTER_DATA_HK
      , PSA_DELETE_IND 
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
        ON SAT_WINN_COST_CENTER_MASTER_DATA_HK = FILTER_H.COST_CENTER_MASTER_DATA_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , SAT_WINN_COST_CENTER_MASTER_DATA_HK
        , COST_CENTER_MASTER_DATA_HK
        , CONTROLLING_AREA_BK
        , COST_CENTER_BK
        , VALID_TO_DATE__YYYYMMDD
        , COMPANY_CODE
        , CURRENCY_KEY
        , COST_CENTER_CATEGORY
        , PERSON_RESPONSIBLE
        , STD_HIERARCHY_AREA
        , FUNCTIONAL_AREA
        , DEPARTMENT
        , POSTAL_CODE
        , COUNTRY_KEY
        , REGION
        , LOCK_INDICATOR
        , VALID_FROM_DATE__YYYYMMDD
        , BKCC
        , REC_SRC
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND END as IS_DELETED
FROM JOIN_RESULT
