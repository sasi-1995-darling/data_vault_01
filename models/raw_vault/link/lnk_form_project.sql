---- SRC LAYER ----
WITH
SRC_CC             as ( SELECT * FROM {{ ref('v_psa_stg_centercode') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY FORM_PROJECT_HK, ORDINAL_POSITION ORDER BY LOAD_DTS))=1 )

/*
SRC_CC             as ( SELECT * FROM STAGING.v_psa_stg_centercode )
*/
---- LOGIC LAYER ----

, LOGIC_CC as (
    SELECT
        FORM_PROJECT_HK
      , PROJECT_HK
      , FORM_HK
      , LOAD_DTS
      , REC_SRC
      , ORDINAL_POSITION
    FROM SRC_CC
)
---- RENAME LAYER ----

, RENAME_CC as (
    SELECT
        FORM_PROJECT_HK
      , PROJECT_HK
      , FORM_HK
      , LOAD_DTS
      , REC_SRC
      , ORDINAL_POSITION
    FROM LOGIC_CC
)
---- FILTER LAYER ----

, FILTER_CC as (
    SELECT *
    FROM RENAME_CC
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_CC
)

---- FINAL LAYER ----
SELECT
          FORM_PROJECT_HK
        , PROJECT_HK
        , FORM_HK
        , LOAD_DTS
        , REC_SRC
        , ORDINAL_POSITION
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.FORM_PROJECT_HK = JOIN_RESULT.FORM_PROJECT_HK AND existing.ORDINAL_POSITION = JOIN_RESULT.ORDINAL_POSITION
)
{% endif %}
--this is to consolidate records coming from 2 diff tables with the same bkcc
QUALIFY (ROW_NUMBER() OVER(PARTITION BY FORM_PROJECT_HK, ORDINAL_POSITION ORDER BY LOAD_DTS))=1
{% if not is_incremental() %}

union all
SELECT 
 MD5_BINARY(GR.VALUE) AS FORM_PROJECT_HK
, MD5_BINARY(GR.VALUE) AS PROJECT_HK
, MD5_BINARY(GR.VALUE) AS FORM_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, CAST(GR.VALUE AS NUMBER(38,0)) AS ORDINAL_POSITION
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}