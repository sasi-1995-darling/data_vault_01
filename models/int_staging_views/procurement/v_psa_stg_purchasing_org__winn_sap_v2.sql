---- SRC LAYER ----
WITH
SRC_t024e          as ( SELECT BPEFF, BUKRS, BUKRS_NTR, EKORG, EKOTX, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, KALSE, MANDT, MKALS, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, TXADR, TXFUS, TXGRU, TXKOP FROM {{ source('sap_ecc_prd', 'z_t024e') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_t024e          as ( SELECT * FROM sap_ecc_prd.Z_T024E )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_t024e as (
    SELECT
        EKORG                                                        as                                  PURCHASING_ORG_BK
      , MANDT
      , EKORG
      , GLREQUEST
      , EKOTX
      , BUKRS
      , TXADR
      , TXKOP
      , TXFUS
      , TXGRU
      , KALSE
      , MKALS
      , BPEFF
      , BUKRS_NTR
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
    FROM SRC_t024e
)

, LOGIC_ref_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_ref_bkcc
)
---- RENAME LAYER ----

, RENAME_t024e as (
    SELECT
        PURCHASING_ORG_BK
      , MANDT
      , EKORG
      , GLREQUEST
      , EKOTX
      , BUKRS
      , TXADR
      , TXKOP
      , TXFUS
      , TXGRU
      , KALSE
      , MKALS
      , BPEFF
      , BUKRS_NTR
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_t024e
)

, RENAME_ref_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_ref_bkcc
)
---- FILTER LAYER ----

, FILTER_t024e as (
    SELECT *
    FROM RENAME_t024e
)

, FILTER_ref_bkcc as (
    SELECT *
    FROM RENAME_ref_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_T024E'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_t024e
    INNER JOIN FILTER_ref_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PURCHASING_ORG_BK
        , MANDT
        , EKORG
        , GLREQUEST
        , EKOTX
        , BUKRS
        , TXADR
        , TXKOP
        , TXFUS
        , TXGRU
        , KALSE
        , MKALS
        , BPEFF
        , BUKRS_NTR
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(EKORG as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PURCHASING_ORG_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(EKOTX::text), '^^') 
            , '||', IFNULL(TRIM(BUKRS::text), '^^') 
            , '||', IFNULL(TRIM(TXADR::text), '^^') 
            , '||', IFNULL(TRIM(TXKOP::text), '^^') 
            , '||', IFNULL(TRIM(TXFUS::text), '^^') 
            , '||', IFNULL(TRIM(TXGRU::text), '^^') 
            , '||', IFNULL(TRIM(KALSE::text), '^^') 
            , '||', IFNULL(TRIM(MKALS::text), '^^') 
            , '||', IFNULL(TRIM(BPEFF::text), '^^') 
            , '||', IFNULL(TRIM(BUKRS_NTR::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
