---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_pymt_trms_dscnt') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.PS_PYMT_TRMS_DSCNT' )

/*
SRC_SRC            as ( SELECT * FROM lrsn_psft_sysadm.ps_pymt_trms_dscnt )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        PYMNT_TERMS_CD                                               as                                    PAYMENT_TERM_BK
      , PYMNT_TERMS_CD
      , SETID
      , EFFDT
      , NET_TRMS_SEQ_NBR
      , DSCNT_TRMS_SEQ_NBR
      , DSCNT_TRMS_TIME_ID
      , TERMS_ADJUST_DAYS
      , DSCNT_TRMS_PERCENT
      , DSCNT_TRMS_AMOUNT
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_SRC
)

, LOGIC_ref_bkcc as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_ref_bkcc
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
    INNER JOIN LOGIC_ref_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PAYMENT_TERM_BK
        , PYMNT_TERMS_CD
        , SETID
        , EFFDT
        , NET_TRMS_SEQ_NBR
        , DSCNT_TRMS_SEQ_NBR
        , DSCNT_TRMS_TIME_ID
        , TERMS_ADJUST_DAYS
        , DSCNT_TRMS_PERCENT
        , DSCNT_TRMS_AMOUNT
        , _FIVETRAN_ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , LOAD_DTS
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PYMNT_TERMS_CD as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PAYMENT_TERM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SETID::text), '^^') 
            , '||', IFNULL(TRIM(EFFDT::text), '^^') 
            , '||', IFNULL(TRIM(NET_TRMS_SEQ_NBR::text), '^^') 
            , '||', IFNULL(TRIM(DSCNT_TRMS_SEQ_NBR::text), '^^') 
            , '||', IFNULL(TRIM(DSCNT_TRMS_TIME_ID::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_ADJUST_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(DSCNT_TRMS_PERCENT::text), '^^') 
            , '||', IFNULL(TRIM(DSCNT_TRMS_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
