---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT * FROM {{ ref('v_psa_stg_response_answer_selection__sws_delighted') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_S1             as ( SELECT * FROM staging.v_psa_stg_response_answer_selection__sws_delighted )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        PRODUCT_HK
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
      , HASHDIFF
    FROM SRC_S1
)
---- RENAME LAYER ----

, RENAME_S1 as (
    SELECT
        PRODUCT_HK
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
      , HASHDIFF
    FROM LOGIC_S1
)
---- FILTER LAYER ----

, FILTER_S1 as (
    SELECT *
    FROM RENAME_S1
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_S1
)

---- FINAL LAYER ----
SELECT
          PRODUCT_HK
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
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PRODUCT_HK = JOIN_RESULT.PRODUCT_HK     AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF 
)
{% endif %}

 
{% if not is_incremental() %}
qualify 1= row_number()over(partition by PRODUCT_HK, HASHDIFF order by PSA_LOAD_DTS) 
union all
SELECT 
  MD5_BINARY(GR.VALUE) AS PRODUCT_HK  
  , CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
  , '0' as ID
  ,null as FIVETRAN_DELETED
  ,null as FIVETRAN_SYNCED
  ,null as TEXT
  ,null as EXTRA_TEXT
  ,null as RESPONSE_ANSWER_ID
  ,null as PSA_LOAD_DTS
  ,null as PSA_RECORD_SOURCE
  ,null as PSA_DELETE_IND 
  ,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
  , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
  , ''::BINARY as HASH_DIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}