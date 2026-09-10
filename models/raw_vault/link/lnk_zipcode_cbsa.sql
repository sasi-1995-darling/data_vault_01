---- SRC LAYER ----
WITH
SRC_zip_cbsa       as ( SELECT * FROM {{ ref('v_psa_stg_zip_cbsa__snfl_usps') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_ZIP_CBSA_HK ORDER BY LOAD_DTS ))=1 ),
SRC_cbsa_zip       as ( SELECT * FROM {{ ref('v_psa_stg_cbsa_zip__snfl_usps') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_ZIP_CBSA_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_zip_cbsa       as ( SELECT * FROM staging.v_psa_stg_zip_cbsa__snfl_usps )
, SRC_cbsa_zip       as ( SELECT * FROM staging.v_psa_stg_cbsa_zip__snfl_usps )
*/
---- LOGIC LAYER ----

, LOGIC_zip_cbsa as (
    SELECT
        LNK_ZIP_CBSA_HK
      , ZIP_HK
      , CBSA_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_zip_cbsa
)

, LOGIC_cbsa_zip as (
    SELECT
        LNK_ZIP_CBSA_HK
      , ZIP_HK
      , CBSA_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_cbsa_zip
)
---- RENAME LAYER ----

, RENAME_zip_cbsa as (
    SELECT
        LNK_ZIP_CBSA_HK
      , ZIP_HK
      , CBSA_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_zip_cbsa
)

, RENAME_cbsa_zip as (
    SELECT
        LNK_ZIP_CBSA_HK
      , ZIP_HK
      , CBSA_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_cbsa_zip
)
---- FILTER LAYER ----

, FILTER_zip_cbsa as (
    SELECT *
    FROM RENAME_zip_cbsa
)

, FILTER_cbsa_zip as (
    SELECT *
    FROM RENAME_cbsa_zip
    WHERE LNK_ZIP_CBSA_HK NOT IN (
        SELECT LNK_ZIP_CBSA_HK
        FROM FILTER_ZIP_CBSA)
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_zip_cbsa
    UNION ALL
    SELECT * FROM FILTER_cbsa_zip
)

---- FINAL LAYER ----
SELECT
          LNK_ZIP_CBSA_HK
        , ZIP_HK
        , CBSA_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_ZIP_CBSA_HK = JOIN_RESULT.LNK_ZIP_CBSA_HK
)
{% endif %}

{% if not is_incremental() %}
union all
SELECT 
MD5_BINARY(GR.VALUE) as LNK_ZIP_CBSA_HK
, MD5_BINARY(GR.VALUE) as ZIP_HK
, MD5_BINARY(GR.VALUE) as CBSA_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}