---- SRC LAYER ----
WITH
SRC_bu             as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_bus_unit_tbl_fs') }} as SRC  ),
SRC_po             as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_po_hdr') }} as SRC 
                        qualify 1 = row_number()over (partition by business_unit order by psa_load_dts desc) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_bu             as ( SELECT * FROM lrsn_psft_sysadm.ps_bus_unit_tbl_fs )
, SRC_po             as ( SELECT * FROM lrsn_psft_sysadm.ps_po_hdr )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_bu as (
    SELECT
        BUSINESS_UNIT                                                as                                    LEGAL_ENTITY_BK
      , BUSINESS_UNIT
      , DESCR
      , DESCRSHORT
      , PSA_RECORD_SOURCE
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC',_FIVETRAN_SYNCED)                     as                                           LOAD_DTS
    FROM SRC_bu
)

, LOGIC_po as (
    SELECT
        BUSINESS_UNIT                                                as                                   PO_BUSINESS_UNIT
    FROM SRC_po
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_bu as (
    SELECT
        LEGAL_ENTITY_BK
      , BUSINESS_UNIT
      , DESCR
      , DESCRSHORT
      , PSA_RECORD_SOURCE
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_bu
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)

, RENAME_po as (
    SELECT
        PO_BUSINESS_UNIT
    FROM LOGIC_po
)
---- FILTER LAYER ----

, FILTER_bu as (
    SELECT *
    FROM RENAME_bu
)

, FILTER_po as (
    SELECT *
    FROM RENAME_po
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.PS_BUS_UNIT_TBL_FS'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_bu
    INNER JOIN FILTER_po
        ON business_unit = po_business_unit
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          LEGAL_ENTITY_BK
        , BUSINESS_UNIT
        , DESCR
        , DESCRSHORT
        , PSA_RECORD_SOURCE
        , _FIVETRAN_ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BUSINESS_UNIT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(DESCR::text), '^^') 
            , '||', IFNULL(TRIM(DESCRSHORT::text), '^^') 
            , '||', IFNULL(TRIM(PSA_RECORD_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
