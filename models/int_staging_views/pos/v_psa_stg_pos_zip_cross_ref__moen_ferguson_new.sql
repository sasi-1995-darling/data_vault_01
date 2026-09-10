---- SRC LAYER ----
WITH
SRC_S              as ( SELECT _FILE, _MODIFIED, _FIVETRAN_SYNCED, ZIP, SAP_CUSTOMER, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND, _LINE FROM {{ source('ferguson', 'moen_usfs_fei_xref') }} as SRC 
                        /* The following qualify clause is required to pull the first row pushed to PSA based on these PK columns*/
                        qualify 1 = row_number()over (partition by zip, sap_customer, _file, _line, _fivetran_synced order by psa_load_dts) ),
SRC_A              as ( SELECT REC_SRC, BKCC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM ferguson.moen_usfs_fei_xref )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        _FILE
      , _MODIFIED
      , _FIVETRAN_SYNCED
      , ZIP
      , lpad(substring(case when position( '-',trim(zip),1) > 0 then left(trim(zip),position( '-',trim(zip),1)-1) else trim(zip) end,1,5),5,'0') as                                           ZIP_CODE
      , SAP_CUSTOMER
      , LPAD(TRIM(SAP_CUSTOMER), 10, 0)::varchar                     as                                        CUSTOMER_BK
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , _LINE
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
        _FILE
      , _MODIFIED
      , _FIVETRAN_SYNCED
      , ZIP
      , ZIP_CODE
      , SAP_CUSTOMER
      , CUSTOMER_BK
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , _LINE
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
    WHERE rec_src = 'US.EXCEL.FERGUSON.MOEN_USFS_FEI_XREF'
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
          _FILE
        , _LINE::varchar                                               as _LINE
        , _MODIFIED
        , _FIVETRAN_SYNCED
        , ZIP
        , ZIP_CODE
        , SAP_CUSTOMER
        , CUSTOMER_BK
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(_MODIFIED::text), '^^') 
            , '||', IFNULL(TRIM(SAP_CUSTOMER::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
