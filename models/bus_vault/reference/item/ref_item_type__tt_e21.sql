---- SRC LAYER ----
WITH
SRC_SPTYTTE        as ( SELECT * FROM {{ ref('v_psa_stg_part_type__tt_e21') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PART_TYPE_ID ORDER BY LOAD_DTS DESC))=1 )

/*
SRC_SPTYTTE        as ( SELECT * FROM STAGING.v_psa_stg_part_type__tt_e21 )
*/
---- LOGIC LAYER ----

, LOGIC_SPTYTTE as (
    SELECT
        PART_TYPE_ID
      , LONG_DESC
      , GL_ACCT
      , SPEC_NEEDED
      , WIP_MFG_OH_PCT
      , TON_INCLUDE
      , WIP_MTRL_OH_PCT
      , FRT_ACRU_ACCT
      , SALES_STAT_ACCT
      , OVERHD_ACCT
      , WIP_MTRL_ACCT
      , INTR_SALES_ACCT
      , INTRA_XOUT_ACCT
      , SERVICE
      , WIP_MFG_ACCT
      , AP_ACRU_ACCT
      , COST_VAR_ACCT
      , MIN_MARGIN
      , PRICE_UPFLG
      , INTR_ACCT
      , WIP_EXAS_ACCT
      , REVENUE_CODE
      , CROLL_REPEATS
      , CROLL_SEQ
      , RITOFF_ACCT
      , MFG_OH_VAR_ACCT
      , MTRL_EXP_ACCT
      , VAR_ACCT
      , MVAR_ACCT
      , MTRL_OH_VAR_ACCT
      , IVAR_ACCT
      , WIP_LAB_ACCT
      , LAB_EXP_ACCT
      , INTRA_XIN_ACCT
      , WIP_LAB_OH_PCT
      , LAB_OH_VAR_ACCT
      , JOB_CLR_ACCT
      , DO_COST_ROLL
      , TYPE_DESC
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SPTYTTE
)
---- RENAME LAYER ----

, RENAME_SPTYTTE as (
    SELECT
        PART_TYPE_ID
      , LONG_DESC
      , GL_ACCT
      , SPEC_NEEDED
      , WIP_MFG_OH_PCT
      , TON_INCLUDE
      , WIP_MTRL_OH_PCT
      , FRT_ACRU_ACCT
      , SALES_STAT_ACCT
      , OVERHD_ACCT
      , WIP_MTRL_ACCT
      , INTR_SALES_ACCT
      , INTRA_XOUT_ACCT
      , SERVICE
      , WIP_MFG_ACCT
      , AP_ACRU_ACCT
      , COST_VAR_ACCT
      , MIN_MARGIN
      , PRICE_UPFLG
      , INTR_ACCT
      , WIP_EXAS_ACCT
      , REVENUE_CODE
      , CROLL_REPEATS
      , CROLL_SEQ
      , RITOFF_ACCT
      , MFG_OH_VAR_ACCT
      , MTRL_EXP_ACCT
      , VAR_ACCT
      , MVAR_ACCT
      , MTRL_OH_VAR_ACCT
      , IVAR_ACCT
      , WIP_LAB_ACCT
      , LAB_EXP_ACCT
      , INTRA_XIN_ACCT
      , WIP_LAB_OH_PCT
      , LAB_OH_VAR_ACCT
      , JOB_CLR_ACCT
      , DO_COST_ROLL
      , TYPE_DESC
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SPTYTTE
)
---- FILTER LAYER ----

, FILTER_SPTYTTE as (
    SELECT *
    FROM RENAME_SPTYTTE
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SPTYTTE
)

---- FINAL LAYER ----
SELECT
          PART_TYPE_ID
        , LONG_DESC
        , GL_ACCT
        , SPEC_NEEDED
        , WIP_MFG_OH_PCT
        , TON_INCLUDE
        , WIP_MTRL_OH_PCT
        , FRT_ACRU_ACCT
        , SALES_STAT_ACCT
        , OVERHD_ACCT
        , WIP_MTRL_ACCT
        , INTR_SALES_ACCT
        , INTRA_XOUT_ACCT
        , SERVICE
        , WIP_MFG_ACCT
        , AP_ACRU_ACCT
        , COST_VAR_ACCT
        , MIN_MARGIN
        , PRICE_UPFLG
        , INTR_ACCT
        , WIP_EXAS_ACCT
        , REVENUE_CODE
        , CROLL_REPEATS
        , CROLL_SEQ
        , RITOFF_ACCT
        , MFG_OH_VAR_ACCT
        , MTRL_EXP_ACCT
        , VAR_ACCT
        , MVAR_ACCT
        , MTRL_OH_VAR_ACCT
        , IVAR_ACCT
        , WIP_LAB_ACCT
        , LAB_EXP_ACCT
        , INTRA_XIN_ACCT
        , WIP_LAB_OH_PCT
        , LAB_OH_VAR_ACCT
        , JOB_CLR_ACCT
        , DO_COST_ROLL
        , TYPE_DESC
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , _FIVETRAN_ID
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
