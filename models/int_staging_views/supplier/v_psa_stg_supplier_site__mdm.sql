---- SRC LAYER ----
WITH
SRC_mdmss          as ( SELECT ADDRESS_LINE_1, ADDRESS_LINE_2, ADDRESS_TYPE, BUSINESS_ID, CITY, COUNTRY, INACTIVE_DATE, LAST_RUN_DATE, POSTAL_CODE, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SITE_SOURCE_KEY, SITE_STATUS, STATE, SUPPLIER_TYPE, TAX_NUMBER FROM {{ source('mdm_supplier', 'outbound_supplier_site') }} as SRC  ),
SRC_rs             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_mdmss          as ( SELECT * FROM mdm_supplier.outbound_supplier_site )
SRC_rs             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_mdmss as (
    SELECT
        BUSINESS_ID                                                  as                                        SUPPLIER_BK
      , SITE_SOURCE_KEY                                              as                                   SUPPLIER_SITE_BK
      , BUSINESS_ID
      , SITE_SOURCE_KEY
      , LAST_RUN_DATE
      , SITE_STATUS
      , INACTIVE_DATE
      , ADDRESS_TYPE
      , ADDRESS_LINE_1
      , ADDRESS_LINE_2
      , CITY
      , STATE
      , POSTAL_CODE
      , COUNTRY
      , TAX_NUMBER
      , SUPPLIER_TYPE
      , PSA_RECORD_SOURCE
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
    FROM SRC_mdmss
)

, LOGIC_rs as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_rs
)
---- RENAME LAYER ----

, RENAME_mdmss as (
    SELECT
        SUPPLIER_BK
      , SUPPLIER_SITE_BK
      , BUSINESS_ID
      , SITE_SOURCE_KEY
      , LAST_RUN_DATE
      , SITE_STATUS
      , INACTIVE_DATE
      , ADDRESS_TYPE
      , ADDRESS_LINE_1
      , ADDRESS_LINE_2
      , CITY
      , STATE
      , POSTAL_CODE
      , COUNTRY
      , TAX_NUMBER
      , SUPPLIER_TYPE
      , PSA_RECORD_SOURCE
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_mdmss
)

, RENAME_rs as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_rs
)
---- FILTER LAYER ----

, FILTER_mdmss as (
    SELECT *
    FROM RENAME_mdmss
)

, FILTER_rs as (
    SELECT *
    FROM RENAME_rs
    WHERE rec_src = 'USOHNO.SNFL.MDMPRD.OUTBOUND_SUPPLIER_SITE'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_mdmss
    INNER JOIN FILTER_rs
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          SUPPLIER_BK
        , SUPPLIER_SITE_BK
        , BUSINESS_ID
        , SITE_SOURCE_KEY
        , LAST_RUN_DATE
        , SITE_STATUS
        , INACTIVE_DATE
        , ADDRESS_TYPE
        , ADDRESS_LINE_1
        , ADDRESS_LINE_2
        , CITY
        , STATE
        , POSTAL_CODE
        , COUNTRY
        , TAX_NUMBER
        , SUPPLIER_TYPE
        , PSA_RECORD_SOURCE
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , LOAD_DTS
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BUSINESS_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SITE_SOURCE_KEY as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_SITE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BUSINESS_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BUSINESS_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SITE_SOURCE_KEY as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_SUPPLIER_SITE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(BUSINESS_ID::text), '^^') 
            , '||', IFNULL(TRIM(SITE_SOURCE_KEY::text), '^^') 
            , '||', IFNULL(TRIM(SITE_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(INACTIVE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_LINE_1::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_LINE_2::text), '^^') 
            , '||', IFNULL(TRIM(CITY::text), '^^') 
            , '||', IFNULL(TRIM(STATE::text), '^^') 
            , '||', IFNULL(TRIM(POSTAL_CODE::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(TAX_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
