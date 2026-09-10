---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT * FROM {{ source('profitero_security_psa', 'retailers') }} as SRC 
                        where psa_delete_ind = 'N' ),
SRC_A1             as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S1             as ( SELECT * FROM profitero_security_psa.retailers )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        NAME                                                         as                                        RETAILER_BK
      , CONVERT_TIMEZONE('UTC', UPDATED_AT)                          as                                           LOAD_DTS
      , ID
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , ALIAS
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
        RETAILER_BK
      , LOAD_DTS
      , ID
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , ALIAS
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
    WHERE rec_src = 'US.PROFITERO_SECURITY.RETAILERS'
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
          RETAILER_BK
        , LOAD_DTS
        , ID
        , COUNTRY
        , UPDATED_AT
        , IS_DELETED
        , ALIAS
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RETAILER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as RETAILER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ID::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(IS_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(ALIAS::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
