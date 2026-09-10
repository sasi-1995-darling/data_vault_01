---- SRC LAYER ----
WITH
SRC_p              as ( SELECT ACCOUNT, CREATE_TIME, CURRENCY_CODE, DELETE_TIME, DISPLAY_NAME, EXPIRE_TIME, INDUSTRY_CATEGORY, NAME, PARENT, PROPERTY_TYPE, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SERVICE_LEVEL, TIME_ZONE, UPDATE_TIME, _FIVETRAN_SYNCED FROM {{ source('google_analytics_4_moen_dtc', 'properties') }} as SRC 
                        /* The following qualify clause is required to pull the first row pushed to PSA based on these PK columns*/
                        qualify 1 = row_number() over(partition by  display_name order by psa_load_dts )  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_act            as ( SELECT DISPLAY_NAME, NAME FROM {{ source('google_analytics_4_moen_dtc', 'accounts') }} as SRC 
                        /* The following qualify clause is required to pull the first row pushed to PSA based on these PK columns*/
                        qualify 1 = row_number() over(partition by  display_name order by psa_load_dts )  )

/*
SRC_p              as ( SELECT * FROM google_analytics_4_moen_dtc.properties )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_act            as ( SELECT * FROM google_analytics_4_moen_dtc.accounts )
*/
---- LOGIC LAYER ----

, LOGIC_p as (
    SELECT
        NAME
      , PROPERTY_TYPE
      , CREATE_TIME
      , UPDATE_TIME
      , PARENT
      , DISPLAY_NAME
      , INDUSTRY_CATEGORY
      , TIME_ZONE
      , CURRENCY_CODE
      , SERVICE_LEVEL
      , DELETE_TIME
      , EXPIRE_TIME
      , ACCOUNT
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_p
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)

, LOGIC_act as (
    SELECT
        DISPLAY_NAME                                                 as                               ACCOUNT_DISPLAY_NAME
      , NAME                                                         as                                           ACT_NAME
    FROM SRC_act
)
---- RENAME LAYER ----

, RENAME_p as (
    SELECT
        NAME
      , PROPERTY_TYPE
      , CREATE_TIME
      , UPDATE_TIME
      , PARENT
      , DISPLAY_NAME
      , INDUSTRY_CATEGORY
      , TIME_ZONE
      , CURRENCY_CODE
      , SERVICE_LEVEL
      , DELETE_TIME
      , EXPIRE_TIME
      , ACCOUNT
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_p
)

, RENAME_act as (
    SELECT
        ACCOUNT_DISPLAY_NAME
      , ACT_NAME
    FROM LOGIC_act
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_p as (
    SELECT *
    FROM RENAME_p
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'US.API.GOOGLE_ANALYTICS_WINN_DTC.PROPERTIES'
)

, FILTER_act as (
    SELECT *
    FROM RENAME_act
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_p
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_act
        ON FILTER_p.ACCOUNT = ACT_NAME
)

---- FINAL LAYER ----
SELECT
          UPPER(TRIM(DISPLAY_NAME))                                    as ECOMMERCE_PROPERTY_BK
        , NAME
        , PROPERTY_TYPE
        , CREATE_TIME
        , UPDATE_TIME
        , PARENT
        , DISPLAY_NAME
        , INDUSTRY_CATEGORY
        , TIME_ZONE
        , CURRENCY_CODE
        , SERVICE_LEVEL
        , DELETE_TIME
        , EXPIRE_TIME
        , ACCOUNT
        , ACCOUNT_DISPLAY_NAME
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , CONVERT_TIMEZONE('UTC',_FIVETRAN_SYNCED)                     as LOAD_DTS
        , REC_SRC
        , BKCC
        , UPPER(TRIM(ACCOUNT_DISPLAY_NAME))                            as ECOMMERCE_ACCOUNT_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ECOMMERCE_PROPERTY_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ECOMMERCE_PROPERTY_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ECOMMERCE_ACCOUNT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ECOMMERCE_ACCOUNT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ECOMMERCE_ACCOUNT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ECOMMERCE_PROPERTY_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_ECOMMERCE_ACCOUNT_PROPERTY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(CREATE_TIME::text), '^^') 
            , '||', IFNULL(TRIM(UPDATE_TIME::text), '^^') 
            , '||', IFNULL(TRIM(PARENT::text), '^^') 
            , '||', IFNULL(TRIM(DISPLAY_NAME::text), '^^') 
            , '||', IFNULL(TRIM(INDUSTRY_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(TIME_ZONE::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SERVICE_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(DELETE_TIME::text), '^^') 
            , '||', IFNULL(TRIM(EXPIRE_TIME::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
