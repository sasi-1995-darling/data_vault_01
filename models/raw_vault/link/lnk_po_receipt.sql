---- SRC LAYER ----
WITH
SRC_porml          as ( SELECT ITEM_HK, LEGAL_ENTITY_HK, LNK_PO_RECEIPT_HK, LOAD_DTS, PLANT_HK, PO_HEADER_HK, PO_ITEM_HK, PO_ITEM_RECEIPT_DK, REC_SRC, SUPPLIER_HK FROM {{ ref('v_psa_stg_po_receipt__ml_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PO_RECEIPT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_porsap         as ( SELECT ITEM_HK, LEGAL_ENTITY_HK, LNK_PO_RECEIPT_HK, LOAD_DTS, PLANT_HK, PO_HEADER_HK, PO_ITEM_HK, PO_ITEM_RECEIPT_DK, REC_SRC, SUPPLIER_HK FROM {{ ref('v_psa_stg_po_receipt__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PO_RECEIPT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_porlr          as ( SELECT ITEM_HK, LEGAL_ENTITY_HK, LNK_PO_RECEIPT_HK, LOAD_DTS, PLANT_HK, PO_HEADER_HK, PO_ITEM_HK, PO_ITEM_RECEIPT_DK, REC_SRC, SUPPLIER_HK FROM {{ ref('v_psa_stg_po_receipt__lrsn_psft') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PO_RECEIPT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_porgp          as ( SELECT ITEM_HK, LEGAL_ENTITY_HK, LNK_PO_RECEIPT_HK, LOAD_DTS, PLANT_HK, PO_HEADER_HK, PO_ITEM_HK, PO_ITEM_RECEIPT_DK, REC_SRC, SUPPLIER_HK FROM {{ ref('v_psa_stg_po_receipt__tt_gp') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PO_RECEIPT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_poltte21       as ( SELECT ITEM_HK, LEGAL_ENTITY_HK, LNK_PO_RECEIPT_HK, LOAD_DTS, PLANT_HK, PO_HEADER_HK, PO_ITEM_HK, PO_ITEM_RECEIPT_DK, REC_SRC, SUPPLIER_HK FROM {{ ref('v_psa_stg_po_item__tt_e21') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PO_RECEIPT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_poremtk        as ( SELECT ITEM_HK, LEGAL_ENTITY_HK, LNK_PO_RECEIPT_HK, LOAD_DTS, PLANT_HK, PO_HEADER_HK, PO_ITEM_HK, PO_ITEM_RECEIPT_DK, REC_SRC, SUPPLIER_HK FROM {{ ref('v_psa_stg_po_receipt__emtk_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PO_RECEIPT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_porfib         as ( SELECT ITEM_HK, LEGAL_ENTITY_HK, LNK_PO_RECEIPT_HK, LOAD_DTS, PLANT_HK, PO_HEADER_HK, PO_ITEM_HK, PO_ITEM_RECEIPT_DK, REC_SRC, SUPPLIER_HK FROM {{ ref('v_psa_stg_po_receipt__fib_ocf') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PO_RECEIPT_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_porml          as ( SELECT * FROM STAGING.v_psa_stg_po_receipt__ml_ebs )
SRC_porsap         as ( SELECT * FROM STAGING.v_psa_stg_po_receipt__winn_sap )
SRC_porlr          as ( SELECT * FROM STAGING.v_psa_stg_po_receipt__lrsn_psft )
SRC_porgp          as ( SELECT * FROM STAGING.v_psa_stg_po_receipt__tt_gp )
SRC_poltte21       as ( SELECT * FROM staging.v_psa_stg_po_item__tt_e21 )
SRC_poremtk        as ( SELECT * FROM staging.v_psa_stg_po_receipt__emtk_ebs )
SRC_porfib         as ( SELECT * FROM staging.v_psa_stg_po_receipt__fib_ocf )
*/
---- LOGIC LAYER ----

, LOGIC_porml as (
    SELECT
        LNK_PO_RECEIPT_HK
      , PO_ITEM_RECEIPT_DK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_porml
)

, LOGIC_porsap as (
    SELECT
        LNK_PO_RECEIPT_HK
      , PO_ITEM_RECEIPT_DK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_porsap
)

, LOGIC_porlr as (
    SELECT
        LNK_PO_RECEIPT_HK
      , PO_ITEM_RECEIPT_DK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_porlr
)

, LOGIC_porgp as (
    SELECT
        LNK_PO_RECEIPT_HK
      , PO_ITEM_RECEIPT_DK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_porgp
)

, LOGIC_poltte21 as (
    SELECT
        LNK_PO_RECEIPT_HK
      , PO_ITEM_RECEIPT_DK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_poltte21
)

, LOGIC_poremtk as (
    SELECT
        LNK_PO_RECEIPT_HK
      , PO_ITEM_RECEIPT_DK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_poremtk
)

, LOGIC_porfib as (
    SELECT
        LNK_PO_RECEIPT_HK
      , PO_ITEM_RECEIPT_DK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_porfib
)
---- RENAME LAYER ----

, RENAME_porml as (
    SELECT
        LNK_PO_RECEIPT_HK
      , PO_ITEM_RECEIPT_DK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_porml
)

, RENAME_porsap as (
    SELECT
        LNK_PO_RECEIPT_HK
      , PO_ITEM_RECEIPT_DK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_porsap
)

, RENAME_porlr as (
    SELECT
        LNK_PO_RECEIPT_HK
      , PO_ITEM_RECEIPT_DK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_porlr
)

, RENAME_porgp as (
    SELECT
        LNK_PO_RECEIPT_HK
      , PO_ITEM_RECEIPT_DK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_porgp
)

, RENAME_poltte21 as (
    SELECT
        LNK_PO_RECEIPT_HK
      , PO_ITEM_RECEIPT_DK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_poltte21
)

, RENAME_poremtk as (
    SELECT
        LNK_PO_RECEIPT_HK
      , PO_ITEM_RECEIPT_DK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_poremtk
)

, RENAME_porfib as (
    SELECT
        LNK_PO_RECEIPT_HK
      , PO_ITEM_RECEIPT_DK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_porfib
)
---- FILTER LAYER ----

, FILTER_porml as (
    SELECT *
    FROM RENAME_porml
)

, FILTER_porsap as (
    SELECT *
    FROM RENAME_porsap
)

, FILTER_porlr as (
    SELECT *
    FROM RENAME_porlr
)

, FILTER_porgp as (
    SELECT *
    FROM RENAME_porgp
)

, FILTER_poltte21 as (
    SELECT *
    FROM RENAME_poltte21
)

, FILTER_poremtk as (
    SELECT *
    FROM RENAME_poremtk
)

, FILTER_porfib as (
    SELECT *
    FROM RENAME_porfib
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_porml
    UNION ALL
    SELECT * FROM FILTER_porsap
    UNION ALL
    SELECT * FROM FILTER_porlr
    UNION ALL
    SELECT * FROM FILTER_porgp
    UNION ALL
    SELECT * FROM FILTER_poltte21
    UNION ALL
    SELECT * FROM FILTER_poremtk
    UNION ALL
    SELECT * FROM FILTER_porfib
)

---- FINAL LAYER ----
SELECT
          LNK_PO_RECEIPT_HK
        , PO_ITEM_RECEIPT_DK
        , PO_HEADER_HK
        , PO_ITEM_HK
        , ITEM_HK
        , SUPPLIER_HK
        , PLANT_HK
        , LEGAL_ENTITY_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_PO_RECEIPT_HK = JOIN_RESULT.LNK_PO_RECEIPT_HK
)
{% endif %}


{% if not is_incremental() %}
union all
SELECT 
 MD5_BINARY(GR.VALUE) AS LNK_PO_RECEIPT_HK
, MD5_BINARY(GR.VALUE) AS PO_ITEM_RECEIPT_DK
, MD5_BINARY(GR.VALUE) AS PO_HEADER_HK
, MD5_BINARY(GR.VALUE) AS PO_ITEM_HK
, MD5_BINARY(GR.VALUE) AS ITEM_HK
, MD5_BINARY(GR.VALUE) AS SUPPLIER_HK
, MD5_BINARY(GR.VALUE) AS PLANT_HK
, MD5_BINARY(GR.VALUE) AS LEGAL_ENTITY_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
