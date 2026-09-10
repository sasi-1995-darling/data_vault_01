---- SRC LAYER ----
WITH
SRC_mdmsorg        as ( SELECT LAST_RUN_DATE, ORGANIZATION_ID, PARENT_ID, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE FROM {{ source('mdm_supplier', 'outbound_supplier_org_id') }} as SRC  ),
SRC_rs             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_mdmss          as ( SELECT BUSINESS_ID, SITE_SOURCE_KEY FROM {{ source('mdm_supplier', 'outbound_supplier_site') }} as SRC 
                        qualify 1= row_number()over(partition by SITE_SOURCE_KEY order by psa_load_dts desc) )

/*
SRC_mdmsorg        as ( SELECT * FROM mdm_supplier.outbound_supplier_org_id )
SRC_rs             as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_mdmss          as ( SELECT * FROM mdm_supplier.outbound_supplier_site )
*/
---- LOGIC LAYER ----

, LOGIC_mdmsorg as (
    SELECT
        ORGANIZATION_ID                                              as                                    LEGAL_ENTITY_BK
      , PARENT_ID
      , LAST_RUN_DATE
      , ORGANIZATION_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
    FROM SRC_mdmsorg
)

, LOGIC_rs as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_rs
)

, LOGIC_mdmss as (
    SELECT
        BUSINESS_ID                                                  as                                        SUPPLIER_BK
      , SITE_SOURCE_KEY                                              as                                   SUPPLIER_SITE_BK
      , BUSINESS_ID
      , SITE_SOURCE_KEY
    FROM SRC_mdmss
)
---- RENAME LAYER ----

, RENAME_mdmss as (
    SELECT
        SUPPLIER_BK
      , SUPPLIER_SITE_BK
      , BUSINESS_ID
      , SITE_SOURCE_KEY
    FROM LOGIC_mdmss
)

, RENAME_mdmsorg as (
    SELECT
        LEGAL_ENTITY_BK
      , PARENT_ID
      , LAST_RUN_DATE
      , ORGANIZATION_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_mdmsorg
)

, RENAME_rs as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_rs
)
---- FILTER LAYER ----

, FILTER_mdmsorg as (
    SELECT *
    FROM RENAME_mdmsorg
)

, FILTER_rs as (
    SELECT *
    FROM RENAME_rs
    WHERE rec_src = 'USOHNO.SNFL.MDMPRD.OUTBOUND_SUPPLIER_ORG_ID'
)

, FILTER_mdmss as (
    SELECT *
    FROM RENAME_mdmss
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_mdmsorg
    INNER JOIN FILTER_rs
        ON '1' = '1'
    LEFT JOIN FILTER_mdmss
        ON parent_id = site_source_key
)

---- FINAL LAYER ----
SELECT
          SUPPLIER_BK
        , SUPPLIER_SITE_BK
        , LEGAL_ENTITY_BK
        , BUSINESS_ID
        , PARENT_ID
        , LAST_RUN_DATE
        , ORGANIZATION_ID
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
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
          COALESCE(NULLIF(TRIM(CAST(ORGANIZATION_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BUSINESS_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BUSINESS_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SITE_SOURCE_KEY as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ORGANIZATION_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_SITE_LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(LEGAL_ENTITY_BK::text), '^^') 
            , '||', IFNULL(TRIM(ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
