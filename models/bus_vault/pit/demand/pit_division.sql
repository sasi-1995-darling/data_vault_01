---- SRC LAYER ----
WITH
SRC_HD             as ( SELECT BKCC, 'PIT_DIVISION', DIVISION_BK, DIVISION_HK, REC_SRC FROM {{ ref('hub_division') }} as SRC  ),
SRC_SD             as ( SELECT DIVISION_HK, SPRAS, SPART, VTEXT, PSA_DELETE_IND FROM {{ ref('sat_division__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by DIVISION_HK, SPRAS order by LOAD_DTS DESC) )

/*
SRC_HD             as ( SELECT * FROM RAW_VAULT.HUB_DIVISION )
SRC_SD             as ( SELECT * FROM RAW_VAULT.SAT_DIVISION__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_HD as (
    SELECT
        CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , BKCC
      , 'PIT_DIVISION'                                               as                                        PIT_REC_SRC
      , DIVISION_BK
      , DIVISION_HK
      , REC_SRC
    FROM SRC_HD
)

, LOGIC_SD as (
    SELECT
        DIVISION_HK                                                  as                                     SD_DIVISION_HK
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , SPART                                                        as                                           DIVISION
      , VTEXT                                                        as                                      DIVISION_NAME
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
    FROM SRC_SD
)
---- RENAME LAYER ----

, RENAME_HD as (
    SELECT
        PIT_LOAD_DTS
      , BKCC
      , PIT_REC_SRC
      , DIVISION_BK
      , DIVISION_HK
      , REC_SRC
    FROM LOGIC_HD
)

, RENAME_SD as (
    SELECT
        SD_DIVISION_HK
      , LANGUAGE_KEY
      , DIVISION
      , DIVISION_NAME
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
        ON FILTER_HD.DIVISION_HK = FILTER_SD.SD_DIVISION_HK
)

---- FINAL LAYER ----
SELECT
          CURRENT_DATE                                                 as SNAPSHOTDATE
        , PIT_LOAD_DTS
        , BKCC
        , REC_SRC
        , PIT_REC_SRC
        , DIVISION_BK
        , DIVISION_HK
        , LANGUAGE_KEY
        , DIVISION
        , DIVISION_NAME
        , SAT_WINN_PSA_DELETE_IND
FROM JOIN_RESULT
