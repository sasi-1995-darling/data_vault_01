---- SRC LAYER ----
WITH
SRC_F1             as ( SELECT * FROM {{ source('centercode', 'centercode_fields') }} as SRC  ),
SRC_D1             as ( SELECT * FROM {{ source('centercode', 'centercode_data') }} as SRC  ),
SRC_A1             as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_F1             as ( SELECT * FROM centercode.centercode_fields )
, SRC_D1             as ( SELECT * FROM centercode.centercode_data )
, SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_F1 as (
    SELECT
        REPORT_TYPE                                                  as                                            FORM_BK
      , PROJECT                                                      as                                         PROJECT_BK
      , PROJECT
      , REPORT_TYPE
      , ORDINAL_POSITION
      , NAME                                                         as                                      QUESTION_NAME
      , DATA_TYPE
      , FORM_ID
      , QUESTION_ID
    FROM SRC_F1
)

, LOGIC_D1 as (
    SELECT
        CONVERT_TIMEZONE('UTC', LOAD_DATETIME)                       as                                           LOAD_DTS
      , LOAD_DATETIME
      , PROJECT                                                      as                                          D_PROJECT
      , REPORT_TYPE                                                  as                                      D_REPORT_TYPE
      , RESPONSE_ORDINAL
      , FIELD_ORDINAL
      , RESPONSE_ID
      , ANSWER_ID
      , COMPUTED_VALUE
      , VALUE_LIST
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

, RENAME_F1 as (
    SELECT
        FORM_BK
      , PROJECT_BK
      , PROJECT
      , REPORT_TYPE
      , ORDINAL_POSITION
      , QUESTION_NAME
      , DATA_TYPE
      , FORM_ID
      , QUESTION_ID
    FROM LOGIC_F1
)

, RENAME_D1 as (
    SELECT
        LOAD_DTS
      , LOAD_DATETIME
      , D_PROJECT
      , D_REPORT_TYPE
      , RESPONSE_ORDINAL
      , FIELD_ORDINAL
      , RESPONSE_ID
      , ANSWER_ID
      , COMPUTED_VALUE
      , VALUE_LIST
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

, FILTER_F1 as (
    SELECT *
    FROM RENAME_F1
)

, FILTER_D1 as (
    SELECT *
    FROM RENAME_D1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'US.CENTERCODE.CENTERCODE_DATA'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_F1
    INNER JOIN FILTER_D1
        ON PROJECT = D_PROJECT AND REPORT_TYPE = D_REPORT_TYPE AND ORDINAL_POSITION = FIELD_ORDINAL
    INNER JOIN FILTER_A1
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          FORM_BK
        , PROJECT_BK
        , LOAD_DTS
        , PROJECT
        , REPORT_TYPE
        , ORDINAL_POSITION
        , QUESTION_NAME
        , DATA_TYPE
        , FORM_ID
        , QUESTION_ID
        , LOAD_DATETIME
        , RESPONSE_ORDINAL
        , FIELD_ORDINAL
        , RESPONSE_ID
        , ANSWER_ID
        , COMPUTED_VALUE
        , VALUE_LIST
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(REPORT_TYPE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as FORM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PROJECT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PROJECT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(REPORT_TYPE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PROJECT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as FORM_PROJECT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(PROJECT::text), '^^') 
            , '||', IFNULL(TRIM(REPORT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ORDINAL_POSITION::text), '^^') 
            , '||', IFNULL(TRIM(QUESTION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(DATA_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(FORM_ID::text), '^^') 
            , '||', IFNULL(TRIM(QUESTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(LOAD_DATETIME::text), '^^') 
            , '||', IFNULL(TRIM(RESPONSE_ORDINAL::text), '^^') 
            , '||', IFNULL(TRIM(FIELD_ORDINAL::text), '^^') 
            , '||', IFNULL(TRIM(RESPONSE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ANSWER_ID::text), '^^') 
            , '||', IFNULL(TRIM(COMPUTED_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(VALUE_LIST::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
