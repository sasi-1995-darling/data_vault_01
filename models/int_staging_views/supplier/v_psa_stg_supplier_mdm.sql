---- SRC LAYER ----
WITH
SRC_mdmos          as ( SELECT * FROM {{ source('mdm_supplier', 'outbound_supplier') }} as SRC  ),
SRC_rs             as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_mdmos          as ( SELECT * FROM mdm_supplier.outbound_supplier )
, SRC_rs             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_mdmos as (
    SELECT
        BUSINESS_ID                                                  as                                        SUPPLIER_BK
      , BUSINESS_ID
      , SUPPLIER_ID
      , CREATE_DATE
      , LAST_UPDATE_DATE
      , LAST_RUN_DATE
      , NAME
      , ALTERNATE_NAME
      , INDUSTRY_TYPE
      , SUPPLIER_STATUS
      , OWNERSHIP_TYPE
      , INACTIVATION_DATE
      , REPORTING_COUNTRY
      , REPORTING_CONTINENT
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
    FROM SRC_mdmos
)

, LOGIC_rs as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_rs
)
---- RENAME LAYER ----

, RENAME_mdmos as (
    SELECT
        SUPPLIER_BK
      , BUSINESS_ID
      , SUPPLIER_ID
      , CREATE_DATE
      , LAST_UPDATE_DATE
      , LAST_RUN_DATE
      , NAME
      , ALTERNATE_NAME
      , INDUSTRY_TYPE
      , SUPPLIER_STATUS
      , OWNERSHIP_TYPE
      , INACTIVATION_DATE
      , REPORTING_COUNTRY
      , REPORTING_CONTINENT
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_mdmos
)

, RENAME_rs as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_rs
)
---- FILTER LAYER ----

, FILTER_mdmos as (
    SELECT *
    FROM RENAME_mdmos
)

, FILTER_rs as (
    SELECT *
    FROM RENAME_rs
    WHERE rec_src = 'USOHNO.SNFL.MDMPRD.OUTBOUND_SUPPLIER'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_mdmos
    INNER JOIN FILTER_rs
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          SUPPLIER_BK
        , BUSINESS_ID
        , SUPPLIER_ID
        , CREATE_DATE
        , LAST_UPDATE_DATE
        , LAST_RUN_DATE
        , NAME
        , ALTERNATE_NAME
        , INDUSTRY_TYPE
        , SUPPLIER_STATUS
        , OWNERSHIP_TYPE
        , INACTIVATION_DATE
        , REPORTING_COUNTRY
        , REPORTING_CONTINENT
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , LOAD_DTS
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SUPPLIER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(BUSINESS_ID::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_ID::text), '^^') 
            , '||', IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(ALTERNATE_NAME::text), '^^') 
            , '||', IFNULL(TRIM(INDUSTRY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(OWNERSHIP_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(INACTIVATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REPORTING_COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(REPORTING_CONTINENT::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
