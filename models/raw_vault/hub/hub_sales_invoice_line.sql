---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT SALES_INVOICE_LINE_HK , SALES_INVOICE_LINE_BK , BKCC , LOAD_DTS , REC_SRC FROM {{ ref('v_psa_stg_sales_invoice_line__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SALES_INVOICE_LINE_BK ORDER BY LOAD_DTS))=1 )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.v_psa_stg_sales_invoice_line__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        SALES_INVOICE_LINE_HK
      , SALES_INVOICE_LINE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SWINN
)
---- RENAME LAYER ----

, RENAME_SWINN as (
    SELECT
        SALES_INVOICE_LINE_HK
      , SALES_INVOICE_LINE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SWINN
)
---- FILTER LAYER ----

, FILTER_SWINN as (
    SELECT *
    FROM RENAME_SWINN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SWINN
)

---- FINAL LAYER ----
SELECT
          SALES_INVOICE_LINE_HK
        , SALES_INVOICE_LINE_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.SALES_INVOICE_LINE_HK= JOIN_RESULT.SALES_INVOICE_LINE_HK
)
{% endif %}
 QUALIFY ROW_NUMBER() OVER(PARTITION BY SALES_INVOICE_LINE_BK, BKCC ORDER BY LOAD_DTS)=1
{% if not is_incremental() %}
 union all
 
 SELECT MD5_BINARY(GR.VALUE) SALES_INVOICE_LINE_HK
 , GR.VALUE AS SALES_INVOICE_LINE_BK
 , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
 , CONVERT_TIMEZONE('UTC','1900-01-01') AS LOAD_DTS
 , 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
 FROM
 TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
 {% endif %}