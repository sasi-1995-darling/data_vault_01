---- SRC LAYER ----
WITH
SRC_S              as ( SELECT
                            INVOICE_LINE_PACING_LHK
                          , CUSTOMER_HK
                          , PLANT_HK
                          , DIVISION_HK
                          , SALES_ORGANIZATION_HK
                          , DISTRIBUTION_CHANNEL_HK
                          , ITEM_HK
                          , SALES_INVOICE_HK
                          , SALES_INVOICE_LINE_HK
                          , LOAD_DTS
                          , REC_SRC
                        FROM {{ ref('v_psa_stg_sales_invoice_line__winn_sap') }} as SRC
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY INVOICE_LINE_PACING_LHK ORDER BY LOAD_DTS ))=1 )

---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        INVOICE_LINE_PACING_LHK
      , CUSTOMER_HK
      , PLANT_HK
      , DIVISION_HK
      , SALES_ORGANIZATION_HK
      , DISTRIBUTION_CHANNEL_HK
      , ITEM_HK
      , SALES_INVOICE_HK         as INVOICE_HK
      , SALES_INVOICE_LINE_HK    as INVOICE_LINE_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_S
)

---- FINAL LAYER ----
SELECT
      INVOICE_LINE_PACING_LHK
    , CUSTOMER_HK
    , PLANT_HK
    , DIVISION_HK
    , SALES_ORGANIZATION_HK
    , DISTRIBUTION_CHANNEL_HK
    , ITEM_HK
    , INVOICE_HK
    , INVOICE_LINE_HK
    , LOAD_DTS
    , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.INVOICE_LINE_PACING_LHK = JOIN_RESULT.INVOICE_LINE_PACING_LHK
)
{% endif %}
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS INVOICE_LINE_PACING_LHK,
MD5_BINARY(GR.VALUE) AS CUSTOMER_HK,
MD5_BINARY(GR.VALUE) AS PLANT_HK,
MD5_BINARY(GR.VALUE) AS DIVISION_HK,
MD5_BINARY(GR.VALUE) AS SALES_ORGANIZATION_HK,
MD5_BINARY(GR.VALUE) AS DISTRIBUTION_CHANNEL_HK,
MD5_BINARY(GR.VALUE) AS ITEM_HK,
MD5_BINARY(GR.VALUE) AS INVOICE_HK,
MD5_BINARY(GR.VALUE) AS INVOICE_LINE_HK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}