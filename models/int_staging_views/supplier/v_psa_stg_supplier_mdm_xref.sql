---- SRC LAYER ----
WITH
SRC_xref           as ( SELECT * FROM {{ source('mdm_supplier', 'outbound_supplier_xref') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_mdm_ref_bkcc   as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_xref           as ( SELECT * FROM mdm_supplier.outbound_supplier_xref )
, SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_mdm_ref_bkcc   as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_xref as (
    SELECT
        BUSINESS_ID
      , ORIGINAL_BUSINESS_ID
      , SUPPLIER_BK
      , SOURCE_PKEY
      , SOURCE_SYSTEM
      , LAST_RUN_DATE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CASE WHEN source_system = 'usohno_sap_eccprd' THEN 'USOHNO.SAP.ECCPRD.Z_LFA1'
            WHEN source_system = 'uswioc_orcl_ebsprd' THEN 'USWIOC.ORCL.EBSPRD.AP_SUPPLIER'
            WHEN source_system = 'usohma_mssql_gpprd' THEN 'USOHMA.MSSQL.GPPRD.DBO_PM00200'
            WHEN source_system = 'usohma_orcl_e21prd' THEN 'USOHMA.ORCL.E21PRD.APVNDMSTR'
            WHEN source_system = 'ussbdr_orcl_psftprd' THEN 'USSDBR.ORCL.PSFTPRD.PS_VENDOR'
            WHEN source_system = 'uswioc_orcl_ebsemtk' THEN 'USWIOC.ORCL.EBSEMTK.AP_SUPPLIER'
        END                                                          as                                       DRVD_REC_SRC
    FROM SRC_xref
)

, LOGIC_ref_bkcc as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_ref_bkcc
)

, LOGIC_mdm_ref_bkcc as (
    SELECT
        BKCC                                                         as                                           MDM_BKCC
      , REC_SRC                                                      as                               MDM_REF_BKCC_REC_SRC
    FROM SRC_mdm_ref_bkcc
)
---- RENAME LAYER ----

, RENAME_xref as (
    SELECT
        BUSINESS_ID
      , ORIGINAL_BUSINESS_ID
      , SUPPLIER_BK
      , SOURCE_PKEY
      , SOURCE_SYSTEM
      , LAST_RUN_DATE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , DRVD_REC_SRC
    FROM LOGIC_xref
)

, RENAME_ref_bkcc as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_ref_bkcc
)

, RENAME_mdm_ref_bkcc as (
    SELECT
        MDM_BKCC
      , MDM_REF_BKCC_REC_SRC
    FROM LOGIC_mdm_ref_bkcc
)
---- FILTER LAYER ----

, FILTER_xref as (
    SELECT *
    FROM RENAME_xref
)

, FILTER_ref_bkcc as (
    SELECT *
    FROM RENAME_ref_bkcc
)

, FILTER_mdm_ref_bkcc as (
    SELECT *
    FROM RENAME_mdm_ref_bkcc
    WHERE MDM_REF_BKCC_REC_SRC = 'USOHNO.SNFL.MDMPRD.OUTBOUND_SUPPLIER'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_xref
    INNER JOIN FILTER_ref_bkcc
        ON FILTER_xref.DRVD_REC_SRC = FILTER_ref_bkcc.REC_SRC
    INNER JOIN FILTER_mdm_ref_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          BUSINESS_ID
        , ORIGINAL_BUSINESS_ID
        , SUPPLIER_BK
        , SOURCE_PKEY
        , SOURCE_SYSTEM
        , LAST_RUN_DATE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as LOAD_DTS
        , BKCC
        , REC_SRC
        , MDM_BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SUPPLIER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BUSINESS_ID as VARCHAR)),''), '^^')
        ))) as SLNK_SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SUPPLIER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BUSINESS_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(MDM_BKCC as VARCHAR)),''), '^^')
        ))) as SAME_AS_SUPPLIER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SAME_AS_SUPPLIER_HK::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_BUSINESS_ID::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_BK::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_PKEY::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_SYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
/* The following filter is to exclude the multiple loads of the same records from Informatica */
qualify 1= row_number()over(partition by SUPPLIER_BK, HASHDIFF order by PSA_LOAD_DTS )