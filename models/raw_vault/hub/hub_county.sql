---- SRC LAYER ----
WITH
SRC_county         as ( SELECT * FROM {{ ref('v_psa_stg_county__snfl_usps') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COUNTY_HK ORDER BY LOAD_DTS ))=1 ),
SRC_county_zip     as ( SELECT * FROM {{ ref('v_psa_stg_county_zip__snfl_usps') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COUNTY_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_county         as ( SELECT * FROM STAGING.v_psa_stg_county__snfl_usps )
, SRC_county_zip     as ( SELECT * FROM STAGING.v_psa_stg_county_zip__snfl_usps )
*/
---- LOGIC LAYER ----

, LOGIC_county as (
    SELECT
        COUNTY_HK
      , COUNTY_BK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_county
)

, LOGIC_county_zip as (
    SELECT
        COUNTY_HK
      , COUNTY                                                       as                                          COUNTY_BK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_county_zip
)
---- RENAME LAYER ----

, RENAME_county as (
    SELECT
        COUNTY_HK
      , COUNTY_BK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_county
)

, RENAME_county_zip as (
    SELECT
        COUNTY_HK
      , COUNTY_BK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_county_zip
)
---- FILTER LAYER ----

, FILTER_county as (
    SELECT *
    FROM RENAME_county
)

, FILTER_county_zip as (
    SELECT *
    FROM RENAME_county_zip
    WHERE COUNTY_HK NOT IN (
        SELECT COUNTY_HK
        FROM FILTER_county)
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_county
    UNION ALL
    SELECT * FROM FILTER_county_zip
)

---- FINAL LAYER ----
SELECT
          COUNTY_HK
        , COUNTY_BK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.COUNTY_HK = JOIN_RESULT.COUNTY_HK
)
{% endif %}{% if not is_incremental() %} union all

SELECT MD5_BINARY(GR.VALUE)  COUNTY_HK
, GR.VALUE  AS COUNTY_BK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}