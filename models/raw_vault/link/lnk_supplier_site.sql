---- SRC LAYER ----
WITH
SRC_SMDM           as ( SELECT LNK_SUPPLIER_SITE_HK, LOAD_DTS, REC_SRC, SUPPLIER_HK, SUPPLIER_SITE_HK FROM {{ ref('v_psa_stg_supplier_site__mdm') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_SUPPLIER_SITE_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_SMDM           as ( SELECT * FROM STAGING.v_psa_stg_supplier_site__mdm )
*/
---- LOGIC LAYER ----

, LOGIC_SMDM as (
    SELECT
        LNK_SUPPLIER_SITE_HK
      , SUPPLIER_HK
      , SUPPLIER_SITE_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SMDM
)
---- RENAME LAYER ----

, RENAME_SMDM as (
    SELECT
        LNK_SUPPLIER_SITE_HK
      , SUPPLIER_HK
      , SUPPLIER_SITE_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SMDM
)
---- FILTER LAYER ----

, FILTER_SMDM as (
    SELECT *
    FROM RENAME_SMDM
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SMDM
)

---- FINAL LAYER ----
SELECT
          LNK_SUPPLIER_SITE_HK
        , SUPPLIER_HK
        , SUPPLIER_SITE_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_SUPPLIER_SITE_HK = JOIN_RESULT.LNK_SUPPLIER_SITE_HK )
{% endif %}
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_SUPPLIER_SITE_HK,
MD5_BINARY(GR.VALUE) AS SUPPLIER_HK,
MD5_BINARY(GR.VALUE) AS SUPPLIER_SITE_HK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
