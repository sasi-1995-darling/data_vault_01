---- SRC LAYER ----
WITH
SRC_zip_cbsa       as ( SELECT * FROM {{ ref('v_psa_stg_zip_cbsa__snfl_usps') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ZIP_HK ORDER BY LOAD_DTS ))=1 ),
SRC_zip_county     as ( SELECT * FROM {{ ref('v_psa_stg_zip_county__snfl_usps') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ZIP_HK ORDER BY LOAD_DTS ))=1 ),
SRC_zip_tract      as ( SELECT * FROM {{ ref('v_psa_stg_zip_tract__snfl_usps') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ZIP_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_zip_cbsa       as ( SELECT * FROM STAGING.v_psa_stg_zip_cbsa__snfl_usps )
, SRC_zip_county     as ( SELECT * FROM STAGING.v_psa_stg_zip_county__snfl_usps )
, SRC_zip_tract      as ( SELECT * FROM STAGING.v_psa_stg_zip_tract__snfl_usps )
*/
---- LOGIC LAYER ----

, LOGIC_zip_cbsa as (
    SELECT
        ZIP_HK
      , ZIP                                                          as                                             ZIP_BK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_zip_cbsa
)

, LOGIC_zip_county as (
    SELECT
        ZIP_HK
      , ZIP                                                          as                                             ZIP_BK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_zip_county
)

, LOGIC_zip_tract as (
    SELECT
        ZIP_HK
      , ZIP                                                          as                                             ZIP_BK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_zip_tract
)
---- RENAME LAYER ----

, RENAME_zip_cbsa as (
    SELECT
        ZIP_HK
      , ZIP_BK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_zip_cbsa
)

, RENAME_zip_county as (
    SELECT
        ZIP_HK
      , ZIP_BK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_zip_county
)

, RENAME_zip_tract as (
    SELECT
        ZIP_HK
      , ZIP_BK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_zip_tract
)
---- FILTER LAYER ----

, FILTER_zip_cbsa as (
    SELECT *
    FROM RENAME_zip_cbsa
)

, FILTER_zip_county as (
    SELECT *
    FROM RENAME_zip_county
    WHERE ZIP_HK NOT IN (
        SELECT ZIP_HK
        FROM FILTER_ZIP_CBSA)
)

, FILTER_zip_tract as (
    SELECT *
    FROM RENAME_zip_tract
    WHERE ZIP_HK NOT IN (
        SELECT ZIP_HK
        FROM FILTER_ZIP_CBSA)
AND ZIP_HK NOT IN (
        SELECT ZIP_HK
        FROM FILTER_ZIP_COUNTY)
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_zip_cbsa
    UNION ALL
    SELECT * FROM FILTER_zip_county
    UNION ALL
    SELECT * FROM FILTER_zip_tract
)

---- FINAL LAYER ----
SELECT
          ZIP_HK
        , ZIP_BK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ZIP_HK = JOIN_RESULT.ZIP_HK
)
{% endif %}{% if not is_incremental() %} union all

SELECT MD5_BINARY(GR.VALUE)  ZIP_HK
, GR.VALUE  AS ZIP_BK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}