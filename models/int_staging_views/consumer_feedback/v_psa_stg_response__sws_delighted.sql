---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT * FROM {{ source('delighted_sws_psa', 'response') }} as SRC  ),
SRC_A1             as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_S2             as ( SELECT * FROM {{ source('reference_psa', 'ref_product_delighted') }} as SRC 
                        WHERE PRODUCT_NAME =  'SWS' )

/*
SRC_S1             as ( SELECT * FROM delighted_sws_psa.response )
, SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_S2             as ( SELECT * FROM reference_psa.ref_product_delighted )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        CONVERT_TIMEZONE('UTC',to_timestamp(cast(updated_at as varchar))) as                                           LOAD_DTS
      , ID
      , _FIVETRAN_DELETED
      , PERSON_ID
      , _FIVETRAN_SYNCED
      , PROPERTIES_DELIGHTED_BROWSER
      , PROPERTIES_SUBSCRIBER
      , CREATED_AT
      , PROPERTIES_DELIGHTED_OPERATING_SYSTEM
      , SURVEY_TYPE
      , SCORE
      , UPDATED_AT
      , COMMENT
      , PERMALINK
      , PROPERTIES_DELIGHTED_DEVICE_TYPE
      , PROPERTIES_DELIGHTED_SOURCE
      , PROPERTIES_DELIGHTED_LINK_NAME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PROPERTIES_UTM_CAMPAIGN
      , PROPERTIES_UTM_MEDIUM
      , PROPERTIES_UTM_SOURCE
      , PROPERTIES_UTM_CONTENT
      , PROPERTIES_UTM_TERM
      , PROPERTIES_SAP_OUTBOUND_ID
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
      , _FIVETRAN_DELETED
      , PERSON_ID
      , _FIVETRAN_SYNCED
      , PROPERTIES_DELIGHTED_BROWSER
      , PROPERTIES_SUBSCRIBER
      , CREATED_AT
      , PROPERTIES_DELIGHTED_OPERATING_SYSTEM
      , SURVEY_TYPE
      , SCORE
      , UPDATED_AT
      , COMMENT
      , PERMALINK
      , PROPERTIES_DELIGHTED_DEVICE_TYPE
      , PROPERTIES_DELIGHTED_SOURCE
      , PROPERTIES_DELIGHTED_LINK_NAME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PROPERTIES_UTM_CAMPAIGN
      , PROPERTIES_UTM_MEDIUM
      , PROPERTIES_UTM_SOURCE
      , PROPERTIES_UTM_CONTENT
      , PROPERTIES_UTM_TERM
      , PROPERTIES_SAP_OUTBOUND_ID
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
    WHERE rec_src = 'US.DELIGHTED_SWS.RESPONSE'
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
        , _FIVETRAN_DELETED
        , PERSON_ID
        , _FIVETRAN_SYNCED
        , PROPERTIES_DELIGHTED_BROWSER
        , PROPERTIES_SUBSCRIBER
        , CREATED_AT
        , PROPERTIES_DELIGHTED_OPERATING_SYSTEM
        , SURVEY_TYPE
        , SCORE
        , UPDATED_AT
        , COMMENT
        , PERMALINK
        , PROPERTIES_DELIGHTED_DEVICE_TYPE
        , PROPERTIES_DELIGHTED_SOURCE
        , PROPERTIES_DELIGHTED_LINK_NAME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PROPERTIES_UTM_CAMPAIGN
        , PROPERTIES_UTM_MEDIUM
        , PROPERTIES_UTM_SOURCE
        , PROPERTIES_UTM_CONTENT
        , PROPERTIES_UTM_TERM
        , PROPERTIES_SAP_OUTBOUND_ID
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ID::text), '^^') 
            , '||', IFNULL(TRIM(PERSON_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_DELIGHTED_BROWSER::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_SUBSCRIBER::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_DELIGHTED_OPERATING_SYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(SURVEY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SCORE::text), '^^') 
            , '||', IFNULL(TRIM(COMMENT::text), '^^') 
            , '||', IFNULL(TRIM(PERMALINK::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_DELIGHTED_DEVICE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_DELIGHTED_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_DELIGHTED_LINK_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PSA_LOAD_DTS::text), '^^') 
            , '||', IFNULL(TRIM(PSA_RECORD_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_UTM_CAMPAIGN::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_UTM_MEDIUM::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_UTM_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_UTM_CONTENT::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_UTM_TERM::text), '^^') 
            , '||', IFNULL(TRIM(PROPERTIES_SAP_OUTBOUND_ID::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
