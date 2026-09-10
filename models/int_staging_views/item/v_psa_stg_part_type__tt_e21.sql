---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('tt_e21prd_e21trubis', 'parttype') }} as SRC 
                        /* The following qualify clause is required to pick the latest change for a day when there are Intra day changes,
                            when Fivetran resync triggered by manual sync multiple times in a day(Resync Happens usually once per week currently). Ex. cust_id ='36196' */
                            qualify 1 = row_number() over(partition by PART_TYPE, _fivetran_synced order by psa_load_dts desc) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM tt_e21prd_e21trubis.parttype )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        PART_TYPE                                                    as                                       PART_TYPE_ID
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
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
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
    WHERE rec_src = 'USOHMA.ORCL.E21PRD.PARTTYPE'
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
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(LONG_DESC::text), '^^') 
            , '||', IFNULL(TRIM(GL_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(SPEC_NEEDED::text), '^^') 
            , '||', IFNULL(TRIM(WIP_MFG_OH_PCT::text), '^^') 
            , '||', IFNULL(TRIM(TON_INCLUDE::text), '^^') 
            , '||', IFNULL(TRIM(WIP_MTRL_OH_PCT::text), '^^') 
            , '||', IFNULL(TRIM(FRT_ACRU_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(SALES_STAT_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(OVERHD_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(WIP_MTRL_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(INTR_SALES_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(INTRA_XOUT_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(SERVICE::text), '^^') 
            , '||', IFNULL(TRIM(WIP_MFG_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(AP_ACRU_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(COST_VAR_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(MIN_MARGIN::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_UPFLG::text), '^^') 
            , '||', IFNULL(TRIM(INTR_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(WIP_EXAS_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(REVENUE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CROLL_REPEATS::text), '^^') 
            , '||', IFNULL(TRIM(CROLL_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(RITOFF_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(MFG_OH_VAR_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(MTRL_EXP_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(VAR_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(MVAR_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(MTRL_OH_VAR_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(IVAR_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(WIP_LAB_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(LAB_EXP_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(INTRA_XIN_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(WIP_LAB_OH_PCT::text), '^^') 
            , '||', IFNULL(TRIM(LAB_OH_VAR_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(JOB_CLR_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(DO_COST_ROLL::text), '^^') 
            , '||', IFNULL(TRIM(TYPE_DESC::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
