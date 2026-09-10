---- SRC LAYER ----
WITH
SRC_S              as ( SELECT CREATED_BY, CREATION_DATE, DESCRIPTION, LANGUAGE, LAST_UPDATED_BY, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN, NAME, OBJECT_VERSION_NUMBER, ORA_SEED_SET_1, ORA_SEED_SET_2, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SEED_DATA_SOURCE, SOURCE_LANG, TERM_ID, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('outd_ocf_ap', 'ap_terms_tl') }} as SRC 
                        /* This filter is to remove dummy records from the source */
                        where (TERM_ID <> 0 and _FIVETRAN_DELETED = FALSE) ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM outd_ocf_ap.AP_TERMS_TL )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        TERM_ID::TEXT                                                as                                    PAYMENT_TERM_BK
      , TERM_ID
      , LANGUAGE
      , ORA_SEED_SET_1
      , LAST_UPDATE_DATE
      , OBJECT_VERSION_NUMBER
      , SOURCE_LANG
      , DESCRIPTION
      , CREATED_BY
      , LAST_UPDATE_LOGIN
      , LAST_UPDATED_BY
      , CREATION_DATE
      , SEED_DATA_SOURCE
      , NAME
      , ORA_SEED_SET_2
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        PAYMENT_TERM_BK
      , TERM_ID
      , LANGUAGE
      , ORA_SEED_SET_1
      , LAST_UPDATE_DATE
      , OBJECT_VERSION_NUMBER
      , SOURCE_LANG
      , DESCRIPTION
      , CREATED_BY
      , LAST_UPDATE_LOGIN
      , LAST_UPDATED_BY
      , CREATION_DATE
      , SEED_DATA_SOURCE
      , NAME
      , ORA_SEED_SET_2
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        BKCC
      , REC_SRC
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
    WHERE rec_src = 'USCLOUD.ORCL.OCFPRD.AP_TERMS_TL'
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
          PAYMENT_TERM_BK
        , TERM_ID
        , LANGUAGE
        , ORA_SEED_SET_1
        , LAST_UPDATE_DATE
        , OBJECT_VERSION_NUMBER
        , SOURCE_LANG
        , DESCRIPTION
        , CREATED_BY
        , LAST_UPDATE_LOGIN
        , LAST_UPDATED_BY
        , CREATION_DATE
        , SEED_DATA_SOURCE
        , NAME
        , ORA_SEED_SET_2
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(TERM_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PAYMENT_TERM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(LANGUAGE::text), '^^') 
            , '||', IFNULL(TRIM(ORA_SEED_SET_1::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_LANG::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SEED_DATA_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(ORA_SEED_SET_2::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
