---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('ml_ebs_ont', 'oe_transaction_types_tl') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM ml_ebs_ont.oe_transaction_types_tl )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        to_char(TRANSACTION_TYPE_ID)                                 as                                TRANSACTION_TYPE_BK
      , TRANSACTION_TYPE_ID
      , CREATED_BY
      , LANGUAGE
      , LAST_UPDATED_BY
      , LAST_UPDATE_LOGIN
      , REQUEST_ID
      , PROGRAM_ID
      , NAME
      , DESCRIPTION
      , PROGRAM_APPLICATION_ID
      , SOURCE_LANG
      , CREATION_DATE
      , LAST_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
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
        TRANSACTION_TYPE_BK
      , TRANSACTION_TYPE_ID
      , CREATED_BY
      , LANGUAGE
      , LAST_UPDATED_BY
      , LAST_UPDATE_LOGIN
      , REQUEST_ID
      , PROGRAM_ID
      , NAME
      , DESCRIPTION
      , PROGRAM_APPLICATION_ID
      , SOURCE_LANG
      , CREATION_DATE
      , LAST_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
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
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.TRANSACTION_TYPES'
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
          TRANSACTION_TYPE_BK
        , TRANSACTION_TYPE_ID
        , CREATED_BY
        , LANGUAGE
        , LAST_UPDATED_BY
        , LAST_UPDATE_LOGIN
        , REQUEST_ID
        , PROGRAM_ID
        , NAME
        , DESCRIPTION
        , PROGRAM_APPLICATION_ID
        , SOURCE_LANG
        , CREATION_DATE
        , LAST_UPDATE_DATE
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(TRANSACTION_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_LANG::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
