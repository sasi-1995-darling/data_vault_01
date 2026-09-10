---- SRC LAYER ----
WITH
SRC_SINVML         as ( SELECT * FROM {{ ref('v_psa_stg_invoice_header__ml_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY INVOICE_BILL_TO_SITE_USE_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_SINVML         as ( SELECT * FROM STAGING.v_psa_stg_invoice_header__ml_ebs )
*/
---- LOGIC LAYER ----

, LOGIC_SINVML as (
    SELECT
        INVOICE_BILL_TO_SITE_USE_HK
      , INVOICE_HK
      , BILL_TO_SITE_USE_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SINVML
)
---- RENAME LAYER ----

, RENAME_SINVML as (
    SELECT
        INVOICE_BILL_TO_SITE_USE_HK
      , INVOICE_HK
      , BILL_TO_SITE_USE_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SINVML
)
---- FILTER LAYER ----

, FILTER_SINVML as (
    SELECT *
    FROM RENAME_SINVML
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SINVML
)

---- FINAL LAYER ----
SELECT
          INVOICE_BILL_TO_SITE_USE_HK
        , INVOICE_HK
        , BILL_TO_SITE_USE_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.INVOICE_BILL_TO_SITE_USE_HK = JOIN_RESULT.INVOICE_BILL_TO_SITE_USE_HK
)
{% endif %}

{% if not is_incremental() %}
union all
SELECT 
MD5_BINARY(GR.VALUE) as INVOICE_BILL_TO_SITE_USE_HK
, MD5_BINARY(GR.VALUE) as INVOICE_HK
, MD5_BINARY(GR.VALUE) as BILL_TO_SITE_USE_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}