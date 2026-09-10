---- SRC LAYER ----
WITH
SRC_SINVML         as ( SELECT * FROM {{ ref('v_psa_stg_invoice_header__ml_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY INVOICE_SOLD_TO_ACCOUNT_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_SINVML         as ( SELECT * FROM STAGING.v_psa_stg_invoice_header__ml_ebs )
*/
---- LOGIC LAYER ----

, LOGIC_SINVML as (
    SELECT
        INVOICE_SOLD_TO_ACCOUNT_HK
      , INVOICE_HK
      , SOLD_TO_ACCOUNT_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SINVML
)
---- RENAME LAYER ----

, RENAME_SINVML as (
    SELECT
        INVOICE_SOLD_TO_ACCOUNT_HK
      , INVOICE_HK
      , SOLD_TO_ACCOUNT_HK
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
          INVOICE_SOLD_TO_ACCOUNT_HK
        , INVOICE_HK
        , SOLD_TO_ACCOUNT_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.INVOICE_SOLD_TO_ACCOUNT_HK = JOIN_RESULT.INVOICE_SOLD_TO_ACCOUNT_HK
)
{% endif %}

{% if not is_incremental() %}
union all
SELECT 
MD5_BINARY(GR.VALUE) as INVOICE_SOLD_TO_ACCOUNT_HK
, MD5_BINARY(GR.VALUE) as INVOICE_HK
, MD5_BINARY(GR.VALUE) as SOLD_TO_ACCOUNT_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}