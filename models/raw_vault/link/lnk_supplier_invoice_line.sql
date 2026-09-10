---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT LNK_SUPPLIER_INVOICE_LINE_HK, LOAD_DTS, REC_SRC, SUPPLIER_INVOICE_HK, SUPPLIER_INVOICE_LINE_HK FROM {{ ref('v_psa_stg_supplier_invoice_line__fib_ocf') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_SUPPLIER_INVOICE_LINE_HK ORDER BY LOAD_DTS)) = 1 )

/*
SRC_SRC            as ( SELECT * FROM int_staging_views.v_psa_stg_supplier_invoice_line__fib_ocf )
*/
,
SRC_EMTKEBS        as ( SELECT LNK_SUPPLIER_INVOICE_LINE_HK, LOAD_DTS, REC_SRC, SUPPLIER_INVOICE_HK, SUPPLIER_INVOICE_LINE_HK FROM {{ ref('v_psa_stg_supplier_invoice_line__emtk_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_SUPPLIER_INVOICE_LINE_HK ORDER BY LOAD_DTS)) = 1 )

/*
SRC_EMTKEBS        as ( SELECT * FROM int_staging_views.v_psa_stg_supplier_invoice_line__emtk_ebs )
*/
,
SRC_MLEBS          as ( SELECT LNK_SUPPLIER_INVOICE_LINE_HK, LOAD_DTS, REC_SRC, SUPPLIER_INVOICE_HK, SUPPLIER_INVOICE_LINE_HK FROM {{ ref('v_psa_stg_supplier_invoice_line__ml_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_SUPPLIER_INVOICE_LINE_HK ORDER BY LOAD_DTS)) = 1 )

/*
SRC_MLEBS          as ( SELECT * FROM int_staging_views.v_psa_stg_supplier_invoice_line__ml_ebs )
*/
,
SRC_WINNSAP        as ( SELECT LNK_SUPPLIER_INVOICE_LINE_HK, LOAD_DTS, REC_SRC, SUPPLIER_INVOICE_HK, SUPPLIER_INVOICE_LINE_HK FROM {{ ref('v_psa_stg_supplier_invoice_line__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_SUPPLIER_INVOICE_LINE_HK ORDER BY LOAD_DTS)) = 1 )

/*
SRC_WINNSAP        as ( SELECT * FROM int_staging_views.v_psa_stg_supplier_invoice_line__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        LNK_SUPPLIER_INVOICE_LINE_HK
      , SUPPLIER_INVOICE_HK
      , SUPPLIER_INVOICE_LINE_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SRC
)

, LOGIC_EMTKEBS as (
    SELECT
        LNK_SUPPLIER_INVOICE_LINE_HK
      , SUPPLIER_INVOICE_HK
      , SUPPLIER_INVOICE_LINE_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_EMTKEBS
)

, LOGIC_MLEBS as (
    SELECT
        LNK_SUPPLIER_INVOICE_LINE_HK
      , SUPPLIER_INVOICE_HK
      , SUPPLIER_INVOICE_LINE_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_MLEBS
)

, LOGIC_WINNSAP as (
    SELECT
        LNK_SUPPLIER_INVOICE_LINE_HK
      , SUPPLIER_INVOICE_HK
      , SUPPLIER_INVOICE_LINE_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_WINNSAP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
    UNION ALL
    SELECT *
    FROM LOGIC_EMTKEBS
    UNION ALL
    SELECT *
    FROM LOGIC_MLEBS
    UNION ALL
    SELECT *
    FROM LOGIC_WINNSAP
)

---- FINAL LAYER ----
SELECT
          LNK_SUPPLIER_INVOICE_LINE_HK
        , SUPPLIER_INVOICE_HK
        , SUPPLIER_INVOICE_LINE_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} existing
    WHERE existing.LNK_SUPPLIER_INVOICE_LINE_HK = JOIN_RESULT.LNK_SUPPLIER_INVOICE_LINE_HK
)
{% endif %}
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_SUPPLIER_INVOICE_LINE_HK,
MD5_BINARY(GR.VALUE) AS SUPPLIER_INVOICE_HK,
MD5_BINARY(GR.VALUE) AS SUPPLIER_INVOICE_LINE_HK,
'1900-01-01T00:00:00'::TIMESTAMP_NTZ AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
