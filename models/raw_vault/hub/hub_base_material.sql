---- SRC LAYER ----
WITH
SRC_MARA           as ( SELECT BASE_MATERIAL_BK, BASE_MATERIAL_HK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_item_master__moen_sap') }} as SRC  ),
SRC_WINNPROMO      as ( SELECT BASE_MATERIAL_BK, BASE_MATERIAL_HK, ERP_BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_consolidated_promo_flow_input__winn_rgm') }} as SRC  )

/*
SRC_MARA           as ( SELECT * FROM STAGING.v_psa_stg_item_master__moen_sap )
SRC_WINNPROMO      as ( SELECT * FROM STAGING.v_psa_stg_consolidated_promo_flow_input__winn_rgm )
*/
---- LOGIC LAYER ----

, LOGIC_MARA as (
    SELECT
        BASE_MATERIAL_HK
      , BASE_MATERIAL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_MARA
)

, LOGIC_WINNPROMO as (
    SELECT
        BASE_MATERIAL_HK
      , BASE_MATERIAL_BK
      , ERP_BKCC                                                     as                                               BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_WINNPROMO
)
---- RENAME LAYER ----

, RENAME_MARA as (
    SELECT
        BASE_MATERIAL_HK
      , BASE_MATERIAL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_MARA
)

, RENAME_WINNPROMO as (
    SELECT
        BASE_MATERIAL_HK
      , BASE_MATERIAL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_WINNPROMO
)
---- FILTER LAYER ----

, FILTER_MARA as (
    SELECT *
    FROM RENAME_MARA
)

, FILTER_WINNPROMO as (
    SELECT *
    FROM RENAME_WINNPROMO
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_MARA
    UNION ALL
    SELECT * FROM FILTER_WINNPROMO
)

---- FINAL LAYER ----
SELECT
          BASE_MATERIAL_HK
        , BASE_MATERIAL_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.BASE_MATERIAL_HK = JOIN_RESULT.BASE_MATERIAL_HK
)
{% endif %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per BKs and BKCC. */
qualify 1 = row_number() over (partition by BASE_MATERIAL_BK, BKCC order by LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS BASE_MATERIAL_HK,
GR.VALUE::text AS BASE_MATERIAL_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
