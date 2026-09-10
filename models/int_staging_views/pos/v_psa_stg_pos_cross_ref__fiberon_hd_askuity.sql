---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('reference_psa', 'hd_fiberon_cross_ref') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM reference_psa.hd_fiberon_cross_ref )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        MANUF_PART_NUMBER
      , SKU
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , _FILE
      , _LINE
      , _MODIFIED
      , _FIVETRAN_SYNCED
      , ORACLE_ITEM_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        MANUF_PART_NUMBER
      , SKU
      , LOAD_DTS
      , _FILE
      , _LINE
      , _MODIFIED
      , _FIVETRAN_SYNCED
      , ORACLE_ITEM_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'US.CSV.HOMEDEPOT.HD_FIBERON_CROSS_REF'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          MANUF_PART_NUMBER
        , SKU
        , LOAD_DTS
        , _FILE
        , _LINE
        , _MODIFIED
        , _FIVETRAN_SYNCED
        , ORACLE_ITEM_ID
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SKU as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_SKU_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(MANUF_PART_NUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as FIBERON_PART_NUM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORACLE_ITEM_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as FIBERON_ITEM_NUM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(_FILE::text), '^^') 
            , '||', IFNULL(TRIM(_LINE::text), '^^') 
            , '||', IFNULL(TRIM(_MODIFIED::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_SYNCED::text), '^^') 
            , '||', IFNULL(TRIM(ORACLE_ITEM_ID::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
