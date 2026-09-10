---- SRC LAYER ----
WITH
SRC_SSSALVPP       as ( SELECT * FROM {{ ref('v_psa_stg_stocked_stores_all__lowes_vpp') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LOWES_SKU_BK ORDER BY LOAD_DTS DESC))=1 )

/*
SRC_SSSALVPP       as ( SELECT * FROM STAGING.v_psa_stg_stocked_stores_all__lowes_vpp )
*/
---- LOGIC LAYER ----

, LOGIC_SSSALVPP as (
    SELECT
        LOWES_SKU_BK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SSSALVPP
)
---- RENAME LAYER ----

, RENAME_SSSALVPP as (
    SELECT
        LOWES_SKU_BK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SSSALVPP
)
---- FILTER LAYER ----

, FILTER_SSSALVPP as (
    SELECT *
    FROM RENAME_SSSALVPP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SSSALVPP
)

---- FINAL LAYER ----
SELECT
          LOWES_SKU_BK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LOWES_SKU_BK = JOIN_RESULT.LOWES_SKU_BK
)
{% endif %}
{% if not is_incremental() %}
union all

SELECT  GR.VALUE  AS LOWES_SKU_BK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP  as LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}