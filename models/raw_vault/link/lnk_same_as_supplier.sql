---- SRC LAYER ----
WITH
SRC_xref           as ( SELECT * FROM {{ ref('v_psa_stg_supplier_mdm_xref') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SLNK_SUPPLIER_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_xref           as ( SELECT * FROM STAGING.v_psa_stg_supplier_mdm_xref )
*/
---- LOGIC LAYER ----

, LOGIC_xref as (
    SELECT
        SLNK_SUPPLIER_HK
      , SUPPLIER_HK
      , SAME_AS_SUPPLIER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_xref
)
---- RENAME LAYER ----

, RENAME_xref as (
    SELECT
        SLNK_SUPPLIER_HK
      , SUPPLIER_HK
      , SAME_AS_SUPPLIER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_xref
)
---- FILTER LAYER ----

, FILTER_xref as (
    SELECT *
    FROM RENAME_xref
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_xref
)

---- FINAL LAYER ----
SELECT
          SLNK_SUPPLIER_HK
        , SUPPLIER_HK
        , SAME_AS_SUPPLIER_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.SLNK_SUPPLIER_HK = JOIN_RESULT.SLNK_SUPPLIER_HK )
{% endif %}

{% if not is_incremental() %}
union all

SELECT MD5_BINARY(GR.VALUE)  SLNK_SUPPLIER_HK
, MD5_BINARY(GR.VALUE) AS SUPPLIER_HK
, MD5_BINARY(GR.VALUE) AS SAME_AS_SUPPLIER_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}