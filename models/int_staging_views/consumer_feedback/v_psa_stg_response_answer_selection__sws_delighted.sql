---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT EXTRA_TEXT, ID, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, RESPONSE_ANSWER_ID, TEXT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('delighted_sws', 'response_answer_selection') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_S2             as ( SELECT PRODUCT_NAME FROM {{ source('reference', 'ref_product_delighted') }} as SRC 
                        WHERE PRODUCT_NAME =  'SWS' )

/*
SRC_S1             as ( SELECT * FROM delighted_sws.response_answer_selection )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_S2             as ( SELECT * FROM reference.ref_product_delighted )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        CONVERT_TIMEZONE('UTC',PSA_LOAD_DTS)                         as                                           LOAD_DTS
      , ID
      , _FIVETRAN_DELETED                                            as                                   FIVETRAN_DELETED
      , _FIVETRAN_SYNCED                                             as                                    FIVETRAN_SYNCED
      , TEXT
      , EXTRA_TEXT
      , RESPONSE_ANSWER_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_S1
)

, LOGIC_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A1
)

, LOGIC_S2 as (
    SELECT
        PRODUCT_NAME                                                 as                                         PRODUCT_BK
    FROM SRC_S2
)
---- RENAME LAYER ----

, RENAME_S2 as (
    SELECT
        PRODUCT_BK
    FROM LOGIC_S2
)

, RENAME_S1 as (
    SELECT
        LOAD_DTS
      , ID
      , FIVETRAN_DELETED
      , FIVETRAN_SYNCED
      , TEXT
      , EXTRA_TEXT
      , RESPONSE_ANSWER_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_S1
)

, RENAME_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A1
)
---- FILTER LAYER ----

, FILTER_S1 as (
    SELECT *
    FROM RENAME_S1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'US.DELIGHTED_SWS.RESPONSE_ANSWER_SELECTION'
)

, FILTER_S2 as (
    SELECT *
    FROM RENAME_S2
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S1
    INNER JOIN FILTER_A1
        ON '1' = '1'
    INNER JOIN FILTER_S2
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PRODUCT_BK
        , LOAD_DTS
        , ID
        , FIVETRAN_DELETED
        , FIVETRAN_SYNCED
        , TEXT
        , EXTRA_TEXT
        , RESPONSE_ANSWER_ID
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ID::text), '^^') 
            , '||', IFNULL(TRIM(TEXT::text), '^^') 
            , '||', IFNULL(TRIM(EXTRA_TEXT::text), '^^') 
            , '||', IFNULL(TRIM(RESPONSE_ANSWER_ID::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
