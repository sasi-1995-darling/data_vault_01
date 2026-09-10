---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('profitero_security', 'sales') }} as SRC 
                        where psa_delete_ind='N'
                        qualify row_number() over(partition by date,asin,sns_category_id order by psa_load_dts desc)=1 ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM profitero_security.sales )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        coalesce(nullif(trim(ASIN), ''), '-1')                       as                                            ASIN_BK
      , coalesce(nullif(trim(SNS_CATEGORY_ID), ''), '-1')            as                                    SNS_CATEGORY_BK
      , DATE
      , CONVERT_TIMEZONE('UTC', IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, coalesce(updated_at,psa_load_dts))) as                                           LOAD_DTS
      , ASIN
      , SNS_CATEGORY_ID
      , PLATFORM
      , FIRST_PARTY_SALES
      , THIRD_PARTY_SALES
      , TOTAL_SALES
      , FIRST_PARTY_UNITS
      , THIRD_PARTY_UNITS
      , TOTAL_UNITS
      , REPORTED_IN_ARA
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_S
)

, LOGIC_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        ASIN_BK
      , SNS_CATEGORY_BK
      , DATE
      , LOAD_DTS
      , ASIN
      , SNS_CATEGORY_ID
      , PLATFORM
      , FIRST_PARTY_SALES
      , THIRD_PARTY_SALES
      , TOTAL_SALES
      , FIRST_PARTY_UNITS
      , THIRD_PARTY_UNITS
      , TOTAL_UNITS
      , REPORTED_IN_ARA
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_S
)

, RENAME_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
    WHERE psa_delete_ind='N'
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'US.PROFITERO_SECURITY.SALES'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          ASIN_BK
        , SNS_CATEGORY_BK
        , DATE
        , LOAD_DTS
        , ASIN
        , SNS_CATEGORY_ID
        , PLATFORM
        , FIRST_PARTY_SALES
        , THIRD_PARTY_SALES
        , TOTAL_SALES
        , FIRST_PARTY_UNITS
        , THIRD_PARTY_UNITS
        , TOTAL_UNITS
        , REPORTED_IN_ARA
        , UPDATED_AT
        , IS_DELETED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SNS_CATEGORY_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SNS_CATEGORY_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ASIN_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ASIN_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ASIN_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SNS_CATEGORY_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ASIN_SNS_CATEGORY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(PLATFORM::text), '^^') 
            , '||', IFNULL(TRIM(FIRST_PARTY_SALES::text), '^^') 
            , '||', IFNULL(TRIM(THIRD_PARTY_SALES::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_SALES::text), '^^') 
            , '||', IFNULL(TRIM(FIRST_PARTY_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(THIRD_PARTY_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(REPORTED_IN_ARA::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
