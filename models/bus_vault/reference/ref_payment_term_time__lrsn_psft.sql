
---- SRC LAYER ----
WITH
SRC_PYMNT_TERMS_TIME          as ( SELECT * FROM {{ ref('v_psa_stg_payment_terms_time__lrsn_psft') }} as SRC  )

/*
SRC_SSM            as ( SELECT * FROM staging.v_psa_stg_payment_terms_time__lrsn_psft )
*/
---- LOGIC LAYER ----

, LOGIC_PYMNT_TERMS_TIME  as (
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
    FROM SRC_PYMNT_TERMS_TIME 
)

---- RENAME LAYER ----

, RENAME_PYMNT_TERMS_TIME  as (
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
    FROM LOGIC_PYMNT_TERMS_TIME 
)

---- FILTER LAYER ----

, FILTER_PYMNT_TERMS_TIME  as (
    SELECT *
    FROM RENAME_PYMNT_TERMS_TIME 
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PYMNT_TERMS_TIME

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
FROM JOIN_RESULT