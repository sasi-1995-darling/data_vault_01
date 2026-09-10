---- SRC LAYER ----
WITH
SRC_eina           as ( SELECT * FROM {{ ref('v_psa_stg_purchasing_records__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_PURCHASING_ITEM_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_eina           as ( SELECT * FROM STAGING.v_psa_stg_purchasing_record__winn )
*/
---- LOGIC LAYER ----

, LOGIC_eina as (
    SELECT
        SUPPLIER_PURCHASING_ITEM_HK
      , PURCHASING_RECORD_HK
      , SUPPLIER_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_eina
)
---- RENAME LAYER ----

, RENAME_eina as (
    SELECT
        SUPPLIER_PURCHASING_ITEM_HK
      , PURCHASING_RECORD_HK
      , SUPPLIER_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_eina
)
---- FILTER LAYER ----

, FILTER_eina as (
    SELECT *
    FROM RENAME_eina
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_eina
)

---- FINAL LAYER ----
SELECT
          SUPPLIER_PURCHASING_ITEM_HK
        , PURCHASING_RECORD_HK
        , SUPPLIER_HK
        , ITEM_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.SUPPLIER_PURCHASING_ITEM_HK = JOIN_RESULT.SUPPLIER_PURCHASING_ITEM_HK 
)
{% endif %} 
{% if not is_incremental() %}
union all
SELECT
         MD5_BINARY(GR.VALUE) AS SUPPLIER_PURCHASING_ITEM_HK
,        MD5_BINARY(GR.VALUE) AS PURCHASING_RECORD_HK
,        MD5_BINARY(GR.VALUE) AS SUPPLIER_HK
,        MD5_BINARY(GR.VALUE) AS ITEMS_HK
, '1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

    {% endif %}