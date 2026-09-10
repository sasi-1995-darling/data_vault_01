---- SRC LAYER ----
WITH
SRC_pursap         as ( SELECT * FROM {{ ref('v_psa_stg_purchase_requisition__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PURCHASE_REQUISITION_HK ORDER BY LOAD_DTS ))=1 ),
SRC_purml          as ( SELECT * FROM {{ ref('v_psa_stg_purchase_requisition__ml_ascp') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PURCHASE_REQUISITION_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_pursap         as ( SELECT * FROM staging.v_psa_stg_purchase_requisition__winn_sap )
, SRC_purml          as ( SELECT * FROM staging.v_psa_stg_purchase_requisition__ml_ascp )
*/
---- LOGIC LAYER ----

, LOGIC_pursap as (
    SELECT
        LNK_PURCHASE_REQUISITION_HK
      , PURCHASE_REQUISITION_HK
      , SUPPLIER_HK
      , ITEM_HK
      , PLANT_HK
      , PURCHASING_ORG_HK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , PURCHASING_RECORD_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_pursap
)

, LOGIC_purml as (
    SELECT
        LNK_PURCHASE_REQUISITION_HK
      , PURCHASE_REQUISITION_HK
      , SUPPLIER_HK
      , ITEM_HK
      , PLANT_HK
      , PURCHASING_ORG_HK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , PURCHASING_RECORD_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_purml
)
---- RENAME LAYER ----

, RENAME_pursap as (
    SELECT
        LNK_PURCHASE_REQUISITION_HK
      , PURCHASE_REQUISITION_HK
      , SUPPLIER_HK
      , ITEM_HK
      , PLANT_HK
      , PURCHASING_ORG_HK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , PURCHASING_RECORD_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_pursap
)

, RENAME_purml as (
    SELECT
        LNK_PURCHASE_REQUISITION_HK
      , PURCHASE_REQUISITION_HK
      , SUPPLIER_HK
      , ITEM_HK
      , PLANT_HK
      , PURCHASING_ORG_HK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , PURCHASING_RECORD_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_purml
)
---- FILTER LAYER ----

, FILTER_pursap as (
    SELECT *
    FROM RENAME_pursap
)

, FILTER_purml as (
    SELECT *
    FROM RENAME_purml
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_pursap
    UNION ALL
    SELECT * FROM FILTER_purml
)

---- FINAL LAYER ----
SELECT
          LNK_PURCHASE_REQUISITION_HK
        , PURCHASE_REQUISITION_HK
        , SUPPLIER_HK
        , ITEM_HK
        , PLANT_HK
        , PURCHASING_ORG_HK
        , PO_HEADER_HK
        , PO_ITEM_HK
        , PURCHASING_RECORD_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_PURCHASE_REQUISITION_HK = JOIN_RESULT.LNK_PURCHASE_REQUISITION_HK
)
{% endif %}
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_PURCHASE_REQUISITION_HK,
MD5_BINARY(GR.VALUE) AS PURCHASE_REQUISITION_HK,
MD5_BINARY(GR.VALUE) AS SUPPLIER_HK,
MD5_BINARY(GR.VALUE) AS ITEM_HK,
MD5_BINARY(GR.VALUE) AS PLANT_HK,
MD5_BINARY(GR.VALUE) AS PURCHASING_ORG_HK,
MD5_BINARY(GR.VALUE) AS PO_HEADER_HK,
MD5_BINARY(GR.VALUE) AS PO_ITEM_HK,
MD5_BINARY(GR.VALUE) AS PURCHASING_RECORD_HK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
