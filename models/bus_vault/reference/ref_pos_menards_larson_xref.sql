---- SRC LAYER ----
WITH
SRC_gp             as ( SELECT * FROM {{ ref('v_psa_stg_pos_cross_ref__larson_menards') }} as SRC 
                        qualify row_number() over(partition by menards_sku,larson_item_id order by load_dts desc)=1 )

/*
SRC_gp             as ( SELECT * FROM staging.v_psa_stg_pos_cross_ref__larson_menards )
*/
---- LOGIC LAYER ----

, LOGIC_gp as (
    SELECT
        CUSTOMER_SKU_HK
      , BASE_MATERIAL_HK
      , LOAD_DTS
      , MENARDS_SKU
      , LARSON_ITEM_ID
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_gp
)
---- RENAME LAYER ----

, RENAME_gp as (
    SELECT
        CUSTOMER_SKU_HK
      , BASE_MATERIAL_HK
      , LOAD_DTS
      , MENARDS_SKU
      , LARSON_ITEM_ID
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_gp
)
---- FILTER LAYER ----

, FILTER_gp as (
    SELECT *
    FROM RENAME_gp
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_gp
)

---- FINAL LAYER ----
SELECT
          CUSTOMER_SKU_HK
        , BASE_MATERIAL_HK
        , LOAD_DTS
        , MENARDS_SKU
        , LARSON_ITEM_ID
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
