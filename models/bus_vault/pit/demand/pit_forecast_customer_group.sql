---- SRC LAYER ----
WITH
SRC_hub_key         as ( SELECT BKCC, FORECAST_CUSTOMER_GROUP_HK, FORECAST_CUSTOMER_GROUP_BK, REC_SRC FROM {{ ref('hub_forecast_customer_group') }} as SRC  ),
SRC_sat_key_1       as ( SELECT BEZEI, FORECAST_CUSTOMER_GROUP_HK, KVGR1, PSA_DELETE_IND, SPRAS FROM {{ ref('msat_forecast_customer_group1__winn_sap') }} as SRC 
                         WHERE SPRAS = 'E'
                         qualify 1= row_number() over(partition by FORECAST_CUSTOMER_GROUP_HK, SPRAS order by load_dts DESC) ),
SRC_sat_key_2       as ( SELECT BEZEI, FORECAST_CUSTOMER_GROUP_HK, KVGR2, PSA_DELETE_IND, SPRAS FROM {{ ref('msat_forecast_customer_group2__winn_sap') }} as SRC 
                         WHERE SPRAS = 'E'
                         qualify 1= row_number() over(partition by FORECAST_CUSTOMER_GROUP_HK, SPRAS order by load_dts DESC) )

---- LOGIC LAYER ----

, LOGIC_hub_key as (
    SELECT
        'PIT_FORECAST_CUSTOMER_GROUP' as PIT_REC_SRC
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP() ) as PIT_LOAD_DTS
      , CURRENT_DATE()  as SNAPSHOT_DTS
      , FORECAST_CUSTOMER_GROUP_HK
      , FORECAST_CUSTOMER_GROUP_BK
      , REC_SRC
      , BKCC
    FROM SRC_hub_key
)

, LOGIC_sat_key_1 as (
    SELECT
        FORECAST_CUSTOMER_GROUP_HK                                   as                     SAT_FORECAST_CUSTOMER_GROUP_HK
      , SPRAS                                                        as                                         LANGUAGE_KEY
      , KVGR1                                                        as                                       CUSTOMER_GROUP
      , BEZEI                                                        as                           CUSTOMER_GROUP_DESCRIPTION
      , PSA_DELETE_IND                                               as                                       PSA_DELETE_IND
    FROM SRC_sat_key_1
    -- Eliminate records where the business key exists in Sat 2
     WHERE NOT EXISTS (
        SELECT 1 
        FROM SRC_sat_key_2 
        WHERE SRC_sat_key_2.KVGR2 = SRC_sat_key_1.KVGR1
    )
)

, LOGIC_sat_key_2 as (
    SELECT
        FORECAST_CUSTOMER_GROUP_HK                                   as                     SAT_FORECAST_CUSTOMER_GROUP_HK
      , SPRAS                                                        as                                         LANGUAGE_KEY
      , KVGR2                                                        as                                       CUSTOMER_GROUP
      , BEZEI                                                        as                           CUSTOMER_GROUP_DESCRIPTION
      , PSA_DELETE_IND                                               as                                       PSA_DELETE_IND
    FROM SRC_sat_key_2
)
---- RENAME LAYER ----

, RENAME_hub_key as (
    SELECT
        PIT_REC_SRC
      , PIT_LOAD_DTS
      , SNAPSHOT_DTS
      , FORECAST_CUSTOMER_GROUP_HK
      , FORECAST_CUSTOMER_GROUP_BK
      , REC_SRC
      , BKCC
    FROM LOGIC_hub_key
)

, RENAME_sat_key_1 as (
    SELECT
        SAT_FORECAST_CUSTOMER_GROUP_HK
      , LANGUAGE_KEY
      , CUSTOMER_GROUP
      , CUSTOMER_GROUP_DESCRIPTION
      , PSA_DELETE_IND
    FROM LOGIC_sat_key_1
)

, RENAME_sat_key_2 as (
    SELECT
        SAT_FORECAST_CUSTOMER_GROUP_HK
      , LANGUAGE_KEY
      , CUSTOMER_GROUP
      , CUSTOMER_GROUP_DESCRIPTION
      , PSA_DELETE_IND
    FROM LOGIC_sat_key_2
)
---- FILTER LAYER ----

, FILTER_hub_key as (
    SELECT *
    FROM RENAME_hub_key
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'
)

, FILTER_sat_key as (
    SELECT * FROM RENAME_sat_key_1
    UNION ALL
    SELECT * FROM RENAME_sat_key_2
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_hub_key as FILTER_hub_key
    INNER JOIN FILTER_sat_key as FILTER_sat_key
        ON FILTER_hub_key.FORECAST_CUSTOMER_GROUP_HK = FILTER_sat_key.SAT_FORECAST_CUSTOMER_GROUP_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , PIT_LOAD_DTS
        , SNAPSHOT_DTS
        , FORECAST_CUSTOMER_GROUP_HK
        , FORECAST_CUSTOMER_GROUP_BK
        , REC_SRC
        , BKCC
        , LANGUAGE_KEY
        , CUSTOMER_GROUP
        , CUSTOMER_GROUP_DESCRIPTION
        , CASE WHEN BKCC = 'Hiding_Tiger' THEN PSA_DELETE_IND END as IS_DELETED 
FROM JOIN_RESULT