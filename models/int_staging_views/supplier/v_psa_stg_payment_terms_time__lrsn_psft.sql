---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_pymt_trms_time') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.PS_PYMT_TRMS_TIME' )

/*
SRC_SRC            as ( SELECT * FROM lrsn_psft_sysadm.ps_pymt_trms_time )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
      SETID
      , PAY_TRMS_TIME_ID
      , DESCR
      , DESCRSHORT
      , TMG_BASIS_OPTION
      , TMG_REL_MONTH_VAL
      , TMG_MONTH_DUE_CD
      , TMG_DAY_DUE_CD
      , DUE_DT
      , TMG_DAY_INCR_VAL
      , TMG_MONTH_INCR_VAL
      , TMG_YEAR_INCR_VAL
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
        SETID
        , PAY_TRMS_TIME_ID
        , DESCR
        , DESCRSHORT
        , TMG_BASIS_OPTION
        , TMG_REL_MONTH_VAL
        , TMG_MONTH_DUE_CD
        , TMG_DAY_DUE_CD
        , DUE_DT
        , TMG_DAY_INCR_VAL
        , TMG_MONTH_INCR_VAL
        , TMG_YEAR_INCR_VAL
        , _FIVETRAN_ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , LOAD_DTS
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SETID::text), '^^') 
            , '||', IFNULL(TRIM(PAY_TRMS_TIME_ID::text), '^^') 
            , '||', IFNULL(TRIM(DESCR::text), '^^') 
            , '||', IFNULL(TRIM(DESCRSHORT::text), '^^') 
            , '||', IFNULL(TRIM(TMG_BASIS_OPTION::text), '^^') 
            , '||', IFNULL(TRIM(TMG_REL_MONTH_VAL::text), '^^') 
            , '||', IFNULL(TRIM(TMG_MONTH_DUE_CD::text), '^^') 
            , '||', IFNULL(TRIM(TMG_DAY_DUE_CD::text), '^^') 
            , '||', IFNULL(TRIM(DUE_DT::text), '^^') 
            , '||', IFNULL(TRIM(TMG_DAY_INCR_VAL::text), '^^') 
            , '||', IFNULL(TRIM(TMG_MONTH_INCR_VAL::text), '^^') 
            , '||', IFNULL(TRIM(TMG_YEAR_INCR_VAL::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
