---- SRC LAYER ----
WITH
SRC_sisap          as ( SELECT * FROM {{ ref('v_psa_stg_sales_invoice__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SALES_INVOICE_HK ORDER BY LOAD_DTS ))=1 ),
SRC_silsap         as ( SELECT * FROM {{ ref('v_psa_stg_sales_invoice_line__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SALES_INVOICE_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_sisap          as ( SELECT * FROM staging.v_psa_stg_sales_invoice__winn_sap )
, SRC_silsap         as ( SELECT * FROM staging.v_psa_stg_sales_invoice_line__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_sisap as (
    SELECT
        SALES_INVOICE_HK
      , SOLD_TO_CUST_HK
      , PAYER_CUST_HK
      , SALES_INVOICE_BK
      , SOLD_TO_CUST_BK
      , PAYER_CUST_BK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_sisap
)

, LOGIC_silsap as (
    SELECT
        SALES_INVOICE_HK                                             as                             LINES_SALES_INVOICE_HK
      , SALES_INVOICE_LINE_HK
      , ITEM_HK
      , SALES_INVOICE_LINE_BK
      , ITEM_BK
    FROM SRC_silsap
)
---- RENAME LAYER ----

, RENAME_sisap as (
    SELECT
        SALES_INVOICE_HK
      , SOLD_TO_CUST_HK
      , PAYER_CUST_HK
      , SALES_INVOICE_BK
      , SOLD_TO_CUST_BK
      , PAYER_CUST_BK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_sisap
)

, RENAME_silsap as (
    SELECT
        LINES_SALES_INVOICE_HK
      , SALES_INVOICE_LINE_HK
      , ITEM_HK
      , SALES_INVOICE_LINE_BK
      , ITEM_BK
    FROM LOGIC_silsap
)
---- FILTER LAYER ----

, FILTER_sisap as (
    SELECT *
    FROM RENAME_sisap
)

, FILTER_silsap as (
    SELECT *
    FROM RENAME_silsap
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_sisap
    INNER JOIN FILTER_silsap
        ON FILTER_sisap.SALES_INVOICE_HK = FILTER_silsap.LINES_SALES_INVOICE_HK
)

---- FINAL LAYER ----
SELECT
          SALES_INVOICE_HK
        , SOLD_TO_CUST_HK
        , PAYER_CUST_HK
        , SALES_INVOICE_LINE_HK
        , ITEM_HK
        , LOAD_DTS
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SALES_INVOICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PAYER_CUST_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SOLD_TO_CUST_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SALES_INVOICE_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        ))) as SALES_INVOICE_ITEM_HK
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.SALES_INVOICE_HK = JOIN_RESULT.SALES_INVOICE_HK
)
{% endif %}

{% if not is_incremental() %}
union all
SELECT 

 MD5_BINARY(GR.VALUE) AS SALES_INVOICE_HK
, MD5_BINARY(GR.VALUE) AS SOLD_TO_CUST_HK
, MD5_BINARY(GR.VALUE) AS PAYER_CUST_HK
, MD5_BINARY(GR.VALUE) AS SALES_INVOICE_LINE_HK
, MD5_BINARY(GR.VALUE) AS ITEM_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, MD5_BINARY(GR.VALUE) AS sales_invoice_item_hk
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}