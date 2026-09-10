---- SRC LAYER ----
WITH
SRC_tract          as ( SELECT * FROM {{ ref('v_psa_stg_tract_zip__snfl_usps') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY TRACT_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_tract          as ( SELECT * FROM STAGING.v_psa_stg_tract_zip__snfl_usps )
*/
---- LOGIC LAYER ----

, LOGIC_tract as (
    SELECT
        TRACT_HK
      , TRACT_BK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_tract
)
---- RENAME LAYER ----

, RENAME_tract as (
    SELECT
        TRACT_HK
      , TRACT_BK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_tract
)
---- FILTER LAYER ----

, FILTER_tract as (
    SELECT *
    FROM RENAME_tract
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_tract
)

---- FINAL LAYER ----
SELECT
          TRACT_HK
        , TRACT_BK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.TRACT_HK = JOIN_RESULT.TRACT_HK
)
{% endif %}
{% if not is_incremental() %} union all

SELECT MD5_BINARY(GR.VALUE)  TRACT_HK
, GR.VALUE  AS TRACT_BK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}