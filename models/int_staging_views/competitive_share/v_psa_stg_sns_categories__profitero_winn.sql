---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('profitero', 'sns_categories') }} as SRC 
                        where psa_delete_ind='N'
                        qualify row_number() over(partition by id order by psa_load_dts desc)=1 ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM profitero.sns_categories )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        coalesce(nullif(trim(ID::varchar), ''), '-1')                as                                    SNS_CATEGORY_BK
      , ID::varchar                                                  as                                                 ID
      , CONVERT_TIMEZONE('UTC', IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, coalesce(updated_at,PSA_LOAD_DTS))) as                                           LOAD_DTS
      , NAME
      , TYPE
      , IS_DELETED
      , UPDATED_AT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_S
)

, LOGIC_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        SNS_CATEGORY_BK
      , ID
      , LOAD_DTS
      , NAME
      , TYPE
      , IS_DELETED
      , UPDATED_AT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_S
)

, RENAME_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'US.PROFITERO_WINN.SNS_CATEGORIES'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          SNS_CATEGORY_BK
        , ID
        , LOAD_DTS
        , NAME
        , TYPE
        , IS_DELETED
        , UPDATED_AT
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SNS_CATEGORY_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SNS_CATEGORY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(TYPE::text), '^^') 
            , '||', IFNULL(TRIM(IS_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_AT::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
