---- SRC LAYER ----
WITH
SRC_HKA            as ( SELECT BKCC, REC_SRC, 'PIT_KEY_ACCOUNT_GROUP', KEY_ACCOUNT_GROUP_BK, KEY_ACCOUNT_GROUP_HK FROM {{ ref('hub_key_account_group') }} as SRC  ),
SRC_SK             as ( SELECT KEY_ACCOUNT_GROUP_HK, SPRAS, KVGR2, BEZEI, PSA_DELETE_IND FROM {{ ref('sat_key_account_group__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by KEY_ACCOUNT_GROUP_HK, SPRAS order by LOAD_DTS DESC) )

/*
SRC_HKA            as ( SELECT * FROM RAW_VAULT.HUB_KEY_ACCOUNT_GROUP )
SRC_SK             as ( SELECT * FROM RAW_VAULT.SAT_KEY_ACCOUNT_GROUP__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_HKA as (
    SELECT
        CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , BKCC
      , REC_SRC
      , 'PIT_KEY_ACCOUNT_GROUP'                                        as                                        PIT_REC_SRC
      , KEY_ACCOUNT_GROUP_BK
      , KEY_ACCOUNT_GROUP_HK
    FROM SRC_HKA
)

, LOGIC_SK as (
    SELECT
        KEY_ACCOUNT_GROUP_HK                                         as                            SK_KEY_ACCOUNT_GROUP_HK
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , KVGR2                                                        as                                     CUSTOMER_GROUP
      , BEZEI                                                        as                                        DESCRIPTION
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
    FROM SRC_SK
)
---- RENAME LAYER ----

, RENAME_HKA as (
    SELECT
        PIT_LOAD_DTS
      , BKCC
      , REC_SRC
      , PIT_REC_SRC
      , KEY_ACCOUNT_GROUP_BK
      , KEY_ACCOUNT_GROUP_HK
    FROM LOGIC_HKA
)

, RENAME_SK as (
    SELECT
        SK_KEY_ACCOUNT_GROUP_HK
      , LANGUAGE_KEY
      , CUSTOMER_GROUP
      , DESCRIPTION
      , SAT_WINN_PSA_DELETE_IND
    FROM LOGIC_SK
)
---- FILTER LAYER ----

, FILTER_HKA as (
    SELECT *
    FROM RENAME_HKA
)

, FILTER_SK as (
    SELECT *
    FROM RENAME_SK
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HKA
    LEFT JOIN FILTER_SK
        ON FILTER_HKA.KEY_ACCOUNT_GROUP_HK = FILTER_SK.SK_KEY_ACCOUNT_GROUP_HK
)

---- FINAL LAYER ----
SELECT
          CURRENT_DATE                                                 as SNAPSHOTDATE
        , PIT_LOAD_DTS
        , BKCC
        , REC_SRC
        , PIT_REC_SRC
        , KEY_ACCOUNT_GROUP_BK
        , KEY_ACCOUNT_GROUP_HK
        , COALESCE(LANGUAGE_KEY, '-1') as LANGUAGE_KEY
        , CUSTOMER_GROUP
        , DESCRIPTION
        , SAT_WINN_PSA_DELETE_IND
FROM JOIN_RESULT
