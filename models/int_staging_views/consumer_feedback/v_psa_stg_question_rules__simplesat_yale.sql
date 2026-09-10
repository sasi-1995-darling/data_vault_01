---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT ACTION, CONDITIONS, INDEX, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, QUESTION, QUESTION_ID, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('simplesat_yale', 'question_rule') }} as SRC
                        -- Dedup PSA re-ingestion: same QUESTION_ID+INDEX+_FIVETRAN_SYNCED = identical source record re-ingested; keep latest PSA_LOAD_DTS.
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY QUESTION_ID, INDEX, _FIVETRAN_SYNCED ORDER BY PSA_LOAD_DTS DESC))=1 ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC WHERE rec_src = 'US.SIMPLESAT_YALE.QUESTION_RULE' )

/*
SRC_D1             as ( SELECT * FROM simplesat_yale.question_rule )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        QUESTION_ID                                                  as                                        QUESTION_BK
      , QUESTION_ID
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

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_D1
    INNER JOIN SRC_A1
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
          COALESCE(NULLIF(TRIM(CAST(QUESTION_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as QUESTION_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(INDEX::text), '^^') 
            , '||', IFNULL(TRIM(CONDITIONS::text), '^^') 
            , '||', IFNULL(TRIM(QUESTION::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(ACTION::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT