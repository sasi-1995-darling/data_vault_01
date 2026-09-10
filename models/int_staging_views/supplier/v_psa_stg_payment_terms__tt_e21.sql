---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('tt_e21prd_e21trubis', 'apvndterm') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'USOHMA.ORCL.E21PRD.APVNDTERM' )

/*
SRC_SRC            as ( SELECT * FROM tt_e21prd_e21trubis.apvndterm )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        TERMS_CODE                                                   as                                    PAYMENT_TERM_BK
      , TERMS_CODE
      , END_DAY3
      , DISC_PCT3
      , END_DAY2
      , DISC_DOM1
      , TERMS_DESC
      , END_DAY1
      , DISC_DOM2
      , DISC_DOM3
      , DISC_PCT2
      , DISC_PCT1
      , DISC_MO1
      , DISC_MO3
      , DISC_MO2
      , PROX_DATE
      , DISC_DAY2
      , DUE_DAY3
      , DUE_DAY2
      , DISC_PCT
      , PROX_DISC_DAY
      , NUMB_MTHS
      , BEG_DAY3
      , BEG_DAY1
      , BEG_DAY2
      , PROX_DOM2
      , DISC_DAYS
      , PROX_DOM1
      , DUE_DAYS
      , PROX_DISC
      , TERMS_TYPE
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
        , TERMS_CODE
        , END_DAY3
        , DISC_PCT3
        , END_DAY2
        , DISC_DOM1
        , TERMS_DESC
        , END_DAY1
        , DISC_DOM2
        , DISC_DOM3
        , DISC_PCT2
        , DISC_PCT1
        , DISC_MO1
        , DISC_MO3
        , DISC_MO2
        , PROX_DATE
        , DISC_DAY2
        , DUE_DAY3
        , DUE_DAY2
        , DISC_PCT
        , PROX_DISC_DAY
        , NUMB_MTHS
        , BEG_DAY3
        , BEG_DAY1
        , BEG_DAY2
        , PROX_DOM2
        , DISC_DAYS
        , PROX_DOM1
        , DUE_DAYS
        , PROX_DISC
        , TERMS_TYPE
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
          COALESCE(NULLIF(TRIM(CAST(TERMS_CODE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PAYMENT_TERM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(END_DAY3::text), '^^') 
            , '||', IFNULL(TRIM(DISC_PCT3::text), '^^') 
            , '||', IFNULL(TRIM(END_DAY2::text), '^^') 
            , '||', IFNULL(TRIM(DISC_DOM1::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_DESC::text), '^^') 
            , '||', IFNULL(TRIM(END_DAY1::text), '^^') 
            , '||', IFNULL(TRIM(DISC_DOM2::text), '^^') 
            , '||', IFNULL(TRIM(DISC_DOM3::text), '^^') 
            , '||', IFNULL(TRIM(DISC_PCT2::text), '^^') 
            , '||', IFNULL(TRIM(DISC_PCT1::text), '^^') 
            , '||', IFNULL(TRIM(DISC_MO1::text), '^^') 
            , '||', IFNULL(TRIM(DISC_MO3::text), '^^') 
            , '||', IFNULL(TRIM(DISC_MO2::text), '^^') 
            , '||', IFNULL(TRIM(PROX_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DISC_DAY2::text), '^^') 
            , '||', IFNULL(TRIM(DUE_DAY3::text), '^^') 
            , '||', IFNULL(TRIM(DUE_DAY2::text), '^^') 
            , '||', IFNULL(TRIM(DISC_PCT::text), '^^') 
            , '||', IFNULL(TRIM(PROX_DISC_DAY::text), '^^') 
            , '||', IFNULL(TRIM(NUMB_MTHS::text), '^^') 
            , '||', IFNULL(TRIM(BEG_DAY3::text), '^^') 
            , '||', IFNULL(TRIM(BEG_DAY1::text), '^^') 
            , '||', IFNULL(TRIM(BEG_DAY2::text), '^^') 
            , '||', IFNULL(TRIM(PROX_DOM2::text), '^^') 
            , '||', IFNULL(TRIM(DISC_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(PROX_DOM1::text), '^^') 
            , '||', IFNULL(TRIM(DUE_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(PROX_DISC::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
