---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ ref('v_psa_stg_amz_category__security_profitero_share') }} as SRC 
{% if is_incremental() %}
      where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
    {% endif %} )

/*
SRC_SRC            as ( SELECT * FROM int_staging_views.v_psa_stg_amz_category__security_profitero_share )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        SNS_CATEGORY_HK
      , AMZ_CATEGORY_ID
      , DIM_AMZ_CATEGORY_KEY
      , AMZ_CATEGORY_NAME
      , AMZ_CATEGORY_TYPE
      , CREATED_AT
      , UPDATED_AT
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SRC
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
)

---- FINAL LAYER ----
SELECT
          SNS_CATEGORY_HK
        , AMZ_CATEGORY_ID
        , DIM_AMZ_CATEGORY_KEY
        , AMZ_CATEGORY_NAME
        , AMZ_CATEGORY_TYPE
        , CREATED_AT
        , UPDATED_AT
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} existing
    WHERE existing.SNS_CATEGORY_HK = JOIN_RESULT.SNS_CATEGORY_HK
      AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by SNS_CATEGORY_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS SNS_CATEGORY_HK,
GR.VALUE::NUMBER(38,0) AS AMZ_CATEGORY_ID,
NULL AS DIM_AMZ_CATEGORY_KEY,
NULL AS AMZ_CATEGORY_NAME,
NULL AS AMZ_CATEGORY_TYPE,
NULL AS CREATED_AT,
NULL AS UPDATED_AT,
'N' AS PSA_DELETE_IND,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'1900-01-01T00:00:00'::TIMESTAMP_NTZ AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
MD5_BINARY('') AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
