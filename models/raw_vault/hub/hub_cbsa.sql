---- SRC LAYER ----
WITH
SRC_cbsa           as ( SELECT * FROM {{ ref('v_psa_stg_cbsa__snfl_usps') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CBSA_HK ORDER BY LOAD_DTS ))=1 ),
SRC_cbsa_zip       as ( SELECT * FROM {{ ref('v_psa_stg_cbsa_zip__snfl_usps') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CBSA_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_cbsa           as ( SELECT * FROM STAGING.v_psa_stg_cbsa__snfl_usps )
, SRC_cbsa_zip       as ( SELECT * FROM STAGING.v_psa_stg_cbsa_zip__snfl_usps )
*/
---- LOGIC LAYER ----

, LOGIC_cbsa as (
    SELECT
        CBSA_HK
      , CBSA_BK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_cbsa
)

, LOGIC_cbsa_zip as (
    SELECT
        CBSA_HK
      , CBSA                                                         as                                            CBSA_BK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_cbsa_zip
)
---- RENAME LAYER ----

, RENAME_cbsa as (
    SELECT
        CBSA_HK
      , CBSA_BK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_cbsa
)

, RENAME_cbsa_zip as (
    SELECT
        CBSA_HK
      , CBSA_BK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_cbsa_zip
)
---- FILTER LAYER ----

, FILTER_cbsa as (
    SELECT *
    FROM RENAME_cbsa
)

, FILTER_cbsa_zip as (
    SELECT *
    FROM RENAME_cbsa_zip
    WHERE CBSA_HK NOT IN (
        SELECT CBSA_HK
        FROM FILTER_cbsa)
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_cbsa
    UNION ALL
    SELECT * FROM FILTER_cbsa_zip
)

---- FINAL LAYER ----
SELECT
          CBSA_HK
        , CBSA_BK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.CBSA_HK = JOIN_RESULT.CBSA_HK
)
{% endif %}
{% if not is_incremental() %} union all

SELECT MD5_BINARY(GR.VALUE)  CBSA_HK
, GR.VALUE  AS CBSA_BK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}