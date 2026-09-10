---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT ACTION, CONDITIONS, INDEX, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, QUESTION, QUESTION_ID, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('simplesat', 'question_rule') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM simplesat.question_rule )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        QUESTION_ID                                                  as                                        QUESTION_BK
      , INDEX
      , CONDITIONS
      , QUESTION
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , ACTION
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_D1
)

, LOGIC_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A1
)
---- RENAME LAYER ----

, RENAME_D1 as (
    SELECT
        QUESTION_BK
      , INDEX
      , CONDITIONS
      , QUESTION
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , ACTION
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_D1
)

, RENAME_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A1
)
---- FILTER LAYER ----

, FILTER_D1 as (
    SELECT *
    FROM RENAME_D1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'US.SIMPLESAT.QUESTION_RULE'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_D1
    INNER JOIN FILTER_A1
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          QUESTION_BK
        , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as LOAD_DTS
        , INDEX
        , CONDITIONS
        , QUESTION
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , ACTION
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(QUESTION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as QUESTION_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(INDEX::text), '^^') 
            , '||', IFNULL(TRIM(CONDITIONS::text), '^^') 
            , '||', IFNULL(TRIM(QUESTION::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_SYNCED::text), '^^') 
            , '||', IFNULL(TRIM(ACTION::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
