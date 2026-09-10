---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT * FROM {{ source('reference_psa', 'ref_product_delighted') }} as SRC  ),
SRC_A1             as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S1             as ( SELECT * FROM reference_psa.ref_product_delighted )
, SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        PRODUCT_NAME                                                 as                                         PRODUCT_BK
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
      , ID
      , PRODUCT_DESC
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_S1
)

, LOGIC_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A1
)
---- RENAME LAYER ----

, RENAME_S1 as (
    SELECT
        PRODUCT_BK
      , LOAD_DTS
      , ID
      , PRODUCT_DESC
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_S1
)

, RENAME_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A1
)
---- FILTER LAYER ----

, FILTER_S1 as (
    SELECT *
    FROM RENAME_S1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'USAZET.SNOWFLAKE.FBIN.REFERENCE.PRODUCT_DELIGHTED'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S1
    INNER JOIN FILTER_A1
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PRODUCT_BK
        , LOAD_DTS
        , ID
        , PRODUCT_DESC
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ID::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_DESC::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
