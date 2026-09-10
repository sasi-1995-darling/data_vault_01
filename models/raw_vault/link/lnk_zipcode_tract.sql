---- SRC LAYER ----
WITH
SRC_zip_tract      as ( SELECT * FROM {{ ref('v_psa_stg_zip_tract__snfl_usps') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_ZIP_TRACT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_tract_zip      as ( SELECT * FROM {{ ref('v_psa_stg_tract_zip__snfl_usps') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_ZIP_TRACT_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_zip_tract      as ( SELECT * FROM staging.v_psa_stg_zip_tract__snfl_usps )
, SRC_tract_zip      as ( SELECT * FROM staging.v_psa_stg_tract_zip__snfl_usps )
*/
---- LOGIC LAYER ----

, LOGIC_zip_tract as (
    SELECT
        LNK_ZIP_TRACT_HK
      , ZIP_HK
      , TRACT_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_zip_tract
)

, LOGIC_tract_zip as (
    SELECT
        LNK_ZIP_TRACT_HK
      , ZIP_HK
      , TRACT_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_tract_zip
)
---- RENAME LAYER ----

, RENAME_zip_tract as (
    SELECT
        LNK_ZIP_TRACT_HK
      , ZIP_HK
      , TRACT_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_zip_tract
)

, RENAME_tract_zip as (
    SELECT
        LNK_ZIP_TRACT_HK
      , ZIP_HK
      , TRACT_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_tract_zip
)
---- FILTER LAYER ----

, FILTER_zip_tract as (
    SELECT *
    FROM RENAME_zip_tract
)

, FILTER_tract_zip as (
    SELECT *
    FROM RENAME_tract_zip
    WHERE LNK_ZIP_TRACT_HK NOT IN (
        SELECT LNK_ZIP_TRACT_HK
        FROM FILTER_zip_tract)
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_zip_tract
    UNION ALL
    SELECT * FROM FILTER_tract_zip
)

---- FINAL LAYER ----
SELECT
          LNK_ZIP_TRACT_HK
        , ZIP_HK
        , TRACT_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_ZIP_TRACT_HK = JOIN_RESULT.LNK_ZIP_TRACT_HK
)
{% endif %}

{% if not is_incremental() %}
union all
SELECT 
MD5_BINARY(GR.VALUE) as LNK_ZIP_TRACT_HK
, MD5_BINARY(GR.VALUE) as ZIP_HK
, MD5_BINARY(GR.VALUE) as TRACT_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}