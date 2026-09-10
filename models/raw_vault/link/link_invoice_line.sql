---- SRC LAYER ----
WITH
SRC_SINVLML        as ( SELECT * FROM {{ ref('v_psa_stg_invoice_line__ml_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY INVOICE_INVOICE_LINE_HK ORDER BY LOAD_DTS ))=1 ),
SRC_SBILNLR        as ( SELECT * FROM {{ ref('v_psa_stg_bi_line__lrsn_psft') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY INVOICE_INVOICE_LINE_HK  ORDER BY LOAD_DTS ))=1 ),
SRC_SINVLNFB       as ( SELECT * FROM {{ ref('v_psa_stg_invoice_line__fib_ocf') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY INVOICE_INVOICE_LINE_HK  ORDER BY LOAD_DTS ))=1 )

/*
SRC_SINVLML        as ( SELECT * FROM STAGING.v_psa_stg_invoice_line__ml_ebs )
, SRC_SBILNLR        as ( SELECT * FROM STAGING.v_psa_stg_bi_line__lrsn_psft )
, SRC_SINVLNFB       as ( SELECT * FROM STAGING.v_psa_stg_invoice_line__fib_ocf )
*/
---- LOGIC LAYER ----

, LOGIC_SINVLML as (
    SELECT
        INVOICE_INVOICE_LINE_HK
      , INVOICE_LINE_HK
      , INVOICE_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SINVLML
)

, LOGIC_SBILNLR as (
    SELECT
        INVOICE_INVOICE_LINE_HK
      , INVOICE_LINE_HK
      , INVOICE_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SBILNLR
)

, LOGIC_SINVLNFB as (
    SELECT
        INVOICE_INVOICE_LINE_HK
      , INVOICE_LINE_HK
      , INVOICE_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SINVLNFB
)
---- RENAME LAYER ----

, RENAME_SINVLML as (
    SELECT
        INVOICE_INVOICE_LINE_HK
      , INVOICE_LINE_HK
      , INVOICE_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SINVLML
)

, RENAME_SBILNLR as (
    SELECT
        INVOICE_INVOICE_LINE_HK
      , INVOICE_LINE_HK
      , INVOICE_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SBILNLR
)

, RENAME_SINVLNFB as (
    SELECT
        INVOICE_INVOICE_LINE_HK
      , INVOICE_LINE_HK
      , INVOICE_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SINVLNFB
)
---- FILTER LAYER ----

, FILTER_SINVLML as (
    SELECT *
    FROM RENAME_SINVLML
)

, FILTER_SBILNLR as (
    SELECT *
    FROM RENAME_SBILNLR
)

, FILTER_SINVLNFB as (
    SELECT *
    FROM RENAME_SINVLNFB
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SINVLML
    UNION ALL
    SELECT * FROM FILTER_SBILNLR
    UNION ALL
    SELECT * FROM FILTER_SINVLNFB
)

---- FINAL LAYER ----
SELECT
          INVOICE_INVOICE_LINE_HK
        , INVOICE_LINE_HK
        , INVOICE_HK
        , ITEM_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.INVOICE_INVOICE_LINE_HK = JOIN_RESULT.INVOICE_INVOICE_LINE_HK
)
{% endif %}
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS INVOICE_INVOICE_LINE_HK,
MD5_BINARY(GR.VALUE) AS INVOICE_LINE_HK,
MD5_BINARY(GR.VALUE) AS INVOICE_HK,
MD5_BINARY(GR.VALUE) AS ITEM_HK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
