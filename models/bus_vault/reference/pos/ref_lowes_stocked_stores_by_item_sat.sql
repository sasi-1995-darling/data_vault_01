---- SRC LAYER ----
WITH
SRC_SSSALVPP       as ( SELECT * FROM {{ ref('v_psa_stg_stocked_stores_all__lowes_vpp') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SSSALVPP       as ( SELECT * FROM STAGING.v_psa_stg_stocked_stores_all__lowes_vpp )
*/
---- LOGIC LAYER ----

, LOGIC_SSSALVPP as (
    SELECT
        LOWES_SKU_BK
      , WEEK_ID
      , ITEM_NUMBER                                                  as                                          LOWES_SKU
      , ITEM_DESC                                                    as                                    LOWES_ITEM_DESC
      , ASSORTMENT_NUMBER                                            as                            LOWES_ASSORTMENT_NUMBER
      , ASSORTMENT_NAME                                              as                              LOWES_ASSORTMENT_NAME
      , STOCKED_STORES
      , HOVBU_DESC                                                   as                           LOWES_BUSINESS_UNIT_DESC
      , HOVBU_ID                                                     as                             LOWES_BUSINESS_UNIT_ID
      , PRODUCT_GROUP_NUMBER                                         as                         LOWES_PRODUCT_GROUP_NUMBER
      , PRODUCT_GROUP_NAME                                           as                           LOWES_PRODUCT_GROUP_NAME
      , MERCH_DIVISION                                               as                               MERCHANDISE_DIVISION
      , MERCH_SUB_DIVISION                                           as                           MERCHANDISE_SUB_DIVISION
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SSSALVPP
)
---- RENAME LAYER ----

, RENAME_SSSALVPP as (
    SELECT
        LOWES_SKU_BK
      , WEEK_ID
      , LOWES_SKU
      , LOWES_ITEM_DESC
      , LOWES_ASSORTMENT_NUMBER
      , LOWES_ASSORTMENT_NAME
      , STOCKED_STORES
      , LOWES_BUSINESS_UNIT_DESC
      , LOWES_BUSINESS_UNIT_ID
      , LOWES_PRODUCT_GROUP_NUMBER
      , LOWES_PRODUCT_GROUP_NAME
      , MERCHANDISE_DIVISION
      , MERCHANDISE_SUB_DIVISION
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
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
        , WEEK_ID
        , LOWES_SKU
        , LOWES_ITEM_DESC
        , LOWES_ASSORTMENT_NUMBER
        , LOWES_ASSORTMENT_NAME
        , STOCKED_STORES
        , LOWES_BUSINESS_UNIT_DESC
        , LOWES_BUSINESS_UNIT_ID
        , LOWES_PRODUCT_GROUP_NUMBER
        , LOWES_PRODUCT_GROUP_NAME
        , MERCHANDISE_DIVISION
        , MERCHANDISE_SUB_DIVISION
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LOWES_SKU_BK = JOIN_RESULT.LOWES_SKU_BK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
qualify 1=row_number() over(partition by lowes_sku_bk, week_id, lowes_business_unit_desc order by psa_load_dts)
union all

SELECT
GR.VALUE::text  AS LOWES_SKU_BK
,'1900-01-01'  AS WEEK_ID
, NULL AS LOWES_SKU
, NULL AS LOWES_ITEM_DESC
, NULL AS LOWES_ASSORTMENT_NUMBER
, NULL AS LOWES_ASSORTMENT_NAME
, NULL AS STOCKED_STORES
, GR.VALUE::text AS LOWES_BUSINESS_UNIT_DESC
, NULL AS LOWES_BUSINESS_UNIT_ID
, NULL AS LOWES_PRODUCT_GROUP_NUMBER
, NULL AS LOWES_PRODUCT_GROUP_NAME
, NULL AS MERCHANDISE_DIVISION
, NULL AS MERCHANDISE_SUB_DIVISION
, NULL AS PSA_LOAD_DTS
, NULL AS PSA_RECORD_SOURCE
, NULL AS PSA_DELETE_IND
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
,''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}