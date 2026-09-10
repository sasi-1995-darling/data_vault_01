{{
    config(
        post_hook = "{% if flags.FULL_REFRESH and target.name in ['default','dev', 'qa'] %}ALTER TABLE {{ this }} SET ROW_TIMESTAMP = TRUE{% endif %}"
    )
}}


---- SRC LAYER ----
WITH
SRC_polml          as ( 
    SELECT 
        LINE_NUM, 
        ITEM_HK, 
        LEGAL_ENTITY_HK, 
        LNK_PO_ITEM_HK, 
        LOAD_DTS, 
        PO_HEADER_HK, 
        PO_ITEM_HK, 
        REC_SRC, 
        SUPPLIER_HK
    FROM {{ ref('v_psa_stg_po_item__ml_ebs') }} as SRC 
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PO_ITEM_HK ORDER BY LOAD_DTS ))=1 
),
SRC_polsap         as ( 
    SELECT 
        EBELP, 
        ITEM_HK, 
        LEGAL_ENTITY_HK, 
        LNK_PO_ITEM_HK, 
        LOAD_DTS, 
        PO_HEADER_HK, 
        PO_ITEM_HK, 
        PURCHASING_ORG_HK, 
        PURCHASING_RECORD_HK, 
        REC_SRC, 
        SUPPLIER_HK 
    FROM {{ ref('v_psa_stg_po_item__winn_sap') }} as SRC 
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PO_ITEM_HK ORDER BY LOAD_DTS ))=1 
),
SRC_pollrsn        as ( 
    SELECT 
        ITEM_HK, 
        LEGAL_ENTITY_HK, 
        LINE_NBR, 
        LNK_PO_ITEM_HK, 
        LOAD_DTS, 
        PO_HEADER_HK, 
        PO_ITEM_HK, 
        REC_SRC, 
        SUPPLIER_HK 
    FROM {{ ref('v_psa_stg_po_item__lrsn_psft') }} as SRC 
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PO_ITEM_HK ORDER BY LOAD_DTS ))=1 
),
SRC_poltte21       as ( 
    SELECT 
        ITEM_HK, 
        LEGAL_ENTITY_HK, 
        LNK_PO_ITEM_HK, 
        LOAD_DTS, 
        PO_HEADER_HK, 
        PO_ITEM_HK, 
        PURCHASING_ORG_HK, 
        PURCHASING_RECORD_HK, 
        REC_SRC, 
        SUPPLIER_HK, 
        ITEM_NO 
    FROM {{ ref('v_psa_stg_po_item__tt_e21') }} as SRC 
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PO_ITEM_HK ORDER BY LOAD_DTS ))=1 
),
SRC_polttgp        as ( 
    SELECT 
        ITEM_HK, 
        LEGAL_ENTITY_HK, 
        LNK_PO_ITEM_HK, 
        LOAD_DTS, 
        PO_HEADER_HK, 
        PO_ITEM_HK, 
        PURCHASING_ORG_HK, 
        PURCHASING_RECORD_HK, 
        REC_SRC, 
        SUPPLIER_HK, 
        ORD 
    FROM {{ ref('v_psa_stg_po_item__tt_gp') }} as SRC 
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PO_ITEM_HK ORDER BY LOAD_DTS ))=1 
),
SRC_polemtk        as ( 
    SELECT 
        ITEM_HK, 
        LEGAL_ENTITY_HK, 
        LNK_PO_ITEM_HK, 
        LOAD_DTS, 
        PO_HEADER_HK, 
        PO_ITEM_HK, 
        PURCHASING_ORG_HK, 
        PURCHASING_RECORD_HK, 
        REC_SRC, 
        SUPPLIER_HK, 
        LINE_NUM 
    FROM {{ ref('v_psa_stg_po_item__emtk_ebs') }} as SRC 
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PO_ITEM_HK ORDER BY LOAD_DTS ))=1 
),
SRC_polfib         as ( 
    SELECT 
        ITEM_HK, 
        LEGAL_ENTITY_HK, 
        LINE_NUM,
        LNK_PO_ITEM_HK, 
        LOAD_DTS, 
        PO_HEADER_HK, 
        PO_ITEM_HK, 
        PURCHASING_ORG_HK, 
        PURCHASING_RECORD_HK, 
        REC_SRC, 
        SUPPLIER_HK 
    FROM {{ ref('v_psa_stg_po_item__fib_ocf') }} as SRC 
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PO_ITEM_HK ORDER BY LOAD_DTS ))=1 
)

/*
SRC_polml          as ( SELECT * FROM staging.v_psa_stg_po_item__ml_ebs )
SRC_polsap         as ( SELECT * FROM staging.v_psa_stg_po_item__winn_sap )
SRC_pollrsn        as ( SELECT * FROM staging.v_psa_stg_po_item__lrsn_psft )
SRC_poltte21       as ( SELECT * FROM staging.v_psa_stg_po_item__tt_e21 )
SRC_polttgp        as ( SELECT * FROM staging.v_psa_stg_po_item__tt_gp )
SRC_polemtk        as ( SELECT * FROM staging.v_psa_stg_po_item__emtk_ebs )
SRC_polfib         as ( SELECT * FROM staging.v_psa_stg_po_item__fib_ocf )
*/
---- LOGIC LAYER ----

, LOGIC_polml as (
    SELECT
        LNK_PO_ITEM_HK
      , PO_ITEM_HK
      , PO_HEADER_HK
      , ITEM_HK
      , LEGAL_ENTITY_HK
      , SUPPLIER_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        )))                                                          as                               PURCHASING_RECORD_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        )))                                                          as                                  PURCHASING_ORG_HK
      , LINE_NUM::TEXT                                               as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , REC_SRC
    FROM SRC_polml
)

, LOGIC_polsap as (
    SELECT
        LNK_PO_ITEM_HK
      , PO_ITEM_HK
      , PO_HEADER_HK
      , ITEM_HK
      , LEGAL_ENTITY_HK
      , SUPPLIER_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , EBELP                                                        as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , REC_SRC
    FROM SRC_polsap
)

, LOGIC_pollrsn as (
    SELECT
        LNK_PO_ITEM_HK
      , PO_ITEM_HK
      , PO_HEADER_HK
      , ITEM_HK
      , LEGAL_ENTITY_HK
      , SUPPLIER_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        )))                                                          as                               PURCHASING_RECORD_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        )))                                                          as                                  PURCHASING_ORG_HK
      , LINE_NBR                                                     as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , REC_SRC
    FROM SRC_pollrsn
)

, LOGIC_poltte21 as (
    SELECT
        LNK_PO_ITEM_HK
      , PO_ITEM_HK
      , PO_HEADER_HK
      , ITEM_HK
      , LEGAL_ENTITY_HK
      , SUPPLIER_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , ITEM_NO::TEXT                                                as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , REC_SRC
    FROM SRC_poltte21
)

, LOGIC_polttgp as (
    SELECT
        LNK_PO_ITEM_HK
      , PO_ITEM_HK
      , PO_HEADER_HK
      , ITEM_HK
      , LEGAL_ENTITY_HK
      , SUPPLIER_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , ORD::TEXT                                                    as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , REC_SRC
    FROM SRC_polttgp
)

, LOGIC_polemtk as (
    SELECT
        LNK_PO_ITEM_HK
      , PO_ITEM_HK
      , PO_HEADER_HK
      , ITEM_HK
      , LEGAL_ENTITY_HK
      , SUPPLIER_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , LINE_NUM::TEXT                                               as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , REC_SRC
    FROM SRC_polemtk
)

, LOGIC_polfib as (
    SELECT
        LNK_PO_ITEM_HK
      , PO_ITEM_HK
      , PO_HEADER_HK
      , ITEM_HK
      , LEGAL_ENTITY_HK
      , SUPPLIER_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , LINE_NUM::TEXT                                               as                                     PO_LINE_NUMBER
      , LOAD_DTS
      , REC_SRC
    FROM SRC_polfib
)
---- RENAME LAYER ----

, RENAME_polml as (
    SELECT
        LNK_PO_ITEM_HK
      , PO_ITEM_HK
      , PO_HEADER_HK
      , ITEM_HK
      , LEGAL_ENTITY_HK
      , SUPPLIER_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , PO_LINE_NUMBER
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_polml
)

, RENAME_polsap as (
    SELECT
        LNK_PO_ITEM_HK
      , PO_ITEM_HK
      , PO_HEADER_HK
      , ITEM_HK
      , LEGAL_ENTITY_HK
      , SUPPLIER_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , PO_LINE_NUMBER
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_polsap
)

, RENAME_pollrsn as (
    SELECT
        LNK_PO_ITEM_HK
      , PO_ITEM_HK
      , PO_HEADER_HK
      , ITEM_HK
      , LEGAL_ENTITY_HK
      , SUPPLIER_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , PO_LINE_NUMBER
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_pollrsn
)

, RENAME_poltte21 as (
    SELECT
        LNK_PO_ITEM_HK
      , PO_ITEM_HK
      , PO_HEADER_HK
      , ITEM_HK
      , LEGAL_ENTITY_HK
      , SUPPLIER_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , PO_LINE_NUMBER
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_poltte21
)

, RENAME_polttgp as (
    SELECT
        LNK_PO_ITEM_HK
      , PO_ITEM_HK
      , PO_HEADER_HK
      , ITEM_HK
      , LEGAL_ENTITY_HK
      , SUPPLIER_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , PO_LINE_NUMBER
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_polttgp
)

, RENAME_polemtk as (
    SELECT
        LNK_PO_ITEM_HK
      , PO_ITEM_HK
      , PO_HEADER_HK
      , ITEM_HK
      , LEGAL_ENTITY_HK
      , SUPPLIER_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , PO_LINE_NUMBER
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_polemtk
)

, RENAME_polfib as (
    SELECT
        LNK_PO_ITEM_HK
      , PO_ITEM_HK
      , PO_HEADER_HK
      , ITEM_HK
      , LEGAL_ENTITY_HK
      , SUPPLIER_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , PO_LINE_NUMBER
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_polfib
)
---- FILTER LAYER ----

, FILTER_polml as (
    SELECT *
    FROM RENAME_polml
)

, FILTER_polsap as (
    SELECT *
    FROM RENAME_polsap
)

, FILTER_pollrsn as (
    SELECT *
    FROM RENAME_pollrsn
)

, FILTER_poltte21 as (
    SELECT *
    FROM RENAME_poltte21
)

, FILTER_polttgp as (
    SELECT *
    FROM RENAME_polttgp
)

, FILTER_polemtk as (
    SELECT *
    FROM RENAME_polemtk
)

, FILTER_polfib as (
    SELECT *
    FROM RENAME_polfib
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_polml
    UNION ALL
    SELECT * FROM FILTER_polsap
    UNION ALL
    SELECT * FROM FILTER_pollrsn
    UNION ALL
    SELECT * FROM FILTER_poltte21
    UNION ALL
    SELECT * FROM FILTER_polttgp
    UNION ALL
    SELECT * FROM FILTER_polemtk
    UNION ALL
    SELECT * FROM FILTER_polfib
)

---- FINAL LAYER ----
SELECT
          LNK_PO_ITEM_HK
        , PO_ITEM_HK
        , PO_HEADER_HK
        , ITEM_HK
        , LEGAL_ENTITY_HK
        , SUPPLIER_HK
        , PURCHASING_RECORD_HK
        , PURCHASING_ORG_HK
        , PO_LINE_NUMBER
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_PO_ITEM_HK = JOIN_RESULT.LNK_PO_ITEM_HK
)
{% endif %}

{% if not is_incremental() %}
union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_PO_ITEM_HK
, MD5_BINARY(GR.VALUE) AS PO_ITEM_HK
, MD5_BINARY(GR.VALUE) AS PO_HEADER_HK
, MD5_BINARY(GR.VALUE) AS ITEM_HK
, MD5_BINARY(GR.VALUE) AS LEGAL_ENTITY_HK
, MD5_BINARY(GR.VALUE) AS SUPPLIER_HK
, MD5_BINARY(GR.VALUE) AS PURCHASING_RECORD_HK
, MD5_BINARY(GR.VALUE) AS PURCHASING_ORG_HK
, GR.VALUE AS PO_LINE_NUMBER
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
