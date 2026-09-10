---- SRC LAYER ----
WITH
SRC_CC             as ( SELECT * FROM {{ ref('v_psa_stg_centercode') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY FORM_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_CC             as ( SELECT * FROM STAGING.v_psa_stg_centercode )
*/
---- LOGIC LAYER ----

, LOGIC_CC as (
    SELECT
        FORM_HK
      , FORM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_CC
)
---- RENAME LAYER ----

, RENAME_CC as (
    SELECT
        FORM_HK
      , FORM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
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
          FORM_HK
        , FORM_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.FORM_HK = JOIN_RESULT.FORM_HK
)
{% endif %}
{% if not is_incremental() %}

union all

SELECT MD5_BINARY(GR.VALUE)  FORM_HK
, GR.VALUE  AS FORM_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}