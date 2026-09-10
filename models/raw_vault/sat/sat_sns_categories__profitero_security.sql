---- SRC LAYER ----
WITH
SRC_CATSEC         as ( SELECT * FROM {{ ref('v_psa_stg_sns_categories__profitero_security') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_CATSEC         as ( SELECT * FROM STAGING.v_psa_stg_sns_categories__profitero_security )
*/
---- LOGIC LAYER ----

, LOGIC_CATSEC as (
    SELECT
        SNS_CATEGORY_HK
      , LOAD_DTS
      , ID
      , NAME
      , TYPE
      , IS_DELETED
      , UPDATED_AT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_CATSEC
)
---- RENAME LAYER ----

, RENAME_CATSEC as (
    SELECT
        SNS_CATEGORY_HK
      , LOAD_DTS
      , ID
      , NAME
      , TYPE
      , IS_DELETED
      , UPDATED_AT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_CATSEC
)
---- FILTER LAYER ----

, FILTER_CATSEC as (
    SELECT *
    FROM RENAME_CATSEC
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_CATSEC
)

---- FINAL LAYER ----
SELECT
          SNS_CATEGORY_HK
        , LOAD_DTS
        , ID
        , NAME
        , TYPE
        , IS_DELETED
        , UPDATED_AT
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
    WHERE existing.ID = JOIN_RESULT.ID
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}

 
{% if not is_incremental() %}
qualify 1 = row_number() over (partition by ID, HASHDIFF order by LOAD_DTS desc) 
union all
SELECT MD5_BINARY(GR.VALUE::varchar) AS SNS_CATEGORY_HK
	, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
	, GR.VALUE::varchar as ID
	, GR.VALUE::varchar as NAME
	, GR.VALUE::varchar as TYPE
	, NULL as IS_DELETED
	, null as UPDATED_AT
	, null as PSA_LOAD_DTS
	, null as PSA_RECORD_SOURCE
	, null as PSA_DELETE_IND
	, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        , DECODE(GR.VALUE::varchar, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
        , ''::BINARY as HASH_DIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}