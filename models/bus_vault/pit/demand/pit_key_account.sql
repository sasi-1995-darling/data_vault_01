---- SRC LAYER ----
WITH
SRC_hub_key        as ( SELECT BKCC, KEY_ACCOUNT_BK, KEY_ACCOUNT_HK, REC_SRC FROM {{ ref('hub_key_account') }} as SRC  ),
SRC_sat_key        as ( SELECT BEZEI, KEY_ACCOUNT_HK, KVGR1, PSA_DELETE_IND, SPRAS FROM {{ ref('sat_key_account__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by KEY_ACCOUNT_HK,SPRAS order by load_dts DESC) )

/*
SRC_hub_key        as ( SELECT * FROM RAW_VAULT.hub_key_account )
SRC_sat_key        as ( SELECT * FROM RAW_VAULT.sat_key_account__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_hub_key as (
    SELECT
        'PIT_KEY_ACCOUNT' as PIT_REC_SRC
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP ) as PIT_LOAD_DTS
      , CURRENT_DATE  as SNAPSHOT_DTS
      , KEY_ACCOUNT_HK
      , KEY_ACCOUNT_BK
      , REC_SRC
      , BKCC
    FROM SRC_hub_key
)

, LOGIC_sat_key as (
    SELECT
        KEY_ACCOUNT_HK                                               as                             sat_key_KEY_ACCOUNT_HK
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , KVGR1                                                        as                                    CUSTOMER_GROUP1
      , BEZEI                                                        as                        CUSTOMER_GROUP1_DESCRIPTION
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
    FROM SRC_sat_key
)
---- RENAME LAYER ----

, RENAME_hub_key as (
    SELECT
        PIT_REC_SRC
      , PIT_LOAD_DTS
      , SNAPSHOT_DTS
      , KEY_ACCOUNT_HK
      , KEY_ACCOUNT_BK
      , REC_SRC
      , BKCC
    FROM LOGIC_hub_key
)

, RENAME_sat_key as (
    SELECT
        sat_key_KEY_ACCOUNT_HK
      , LANGUAGE_KEY
      , CUSTOMER_GROUP1
      , CUSTOMER_GROUP1_DESCRIPTION
      , SAT_WINN_PSA_DELETE_IND
    FROM LOGIC_sat_key
)
---- FILTER LAYER ----

, FILTER_hub_key as (
    SELECT *
    FROM RENAME_hub_key
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED' /* This filter is to exclude the ghost records */
)

, FILTER_sat_key as (
    SELECT *
    FROM RENAME_sat_key
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_hub_key
    INNER JOIN FILTER_sat_key
        ON FILTER_hub_key.KEY_ACCOUNT_HK = sat_key_KEY_ACCOUNT_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , PIT_LOAD_DTS
        , SNAPSHOT_DTS
        , KEY_ACCOUNT_HK
        , KEY_ACCOUNT_BK
        , REC_SRC
        , BKCC
        , SAT_KEY_KEY_ACCOUNT_HK
        , LANGUAGE_KEY
        , CUSTOMER_GROUP1
        , CUSTOMER_GROUP1_DESCRIPTION
        , CASE  WHEN BKCC = 'Hiding_Tiger' THEN SAT_WINN_PSA_DELETE_IND
           END as IS_DELETED 
FROM JOIN_RESULT
