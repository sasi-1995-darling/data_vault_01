---- SRC LAYER ----
WITH
SRC_SBIHLR         as ( SELECT * FROM {{ ref('v_psa_stg_bi_hdr__lrsn_psft') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY INVOICE_SALES_REP_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_SBIHLR         as ( SELECT * FROM STAGING.v_psa_stg_bi_hdr__lrsn_psft )
*/
---- LOGIC LAYER ----

, LOGIC_SBIHLR as (
    SELECT
        INVOICE_SALES_REP_HK
      , INVOICE_HK
      , SALES_REP_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SBIHLR
)
---- RENAME LAYER ----

, RENAME_SBIHLR as (
    SELECT
        INVOICE_SALES_REP_HK
      , INVOICE_HK
      , SALES_REP_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SBIHLR
)
---- FILTER LAYER ----

, FILTER_SBIHLR as (
    SELECT *
    FROM RENAME_SBIHLR
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SBIHLR
)

---- FINAL LAYER ----
SELECT
          INVOICE_SALES_REP_HK
        , INVOICE_HK
        , SALES_REP_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.INVOICE_SALES_REP_HK = JOIN_RESULT.INVOICE_SALES_REP_HK
)
{% endif %}

{% if not is_incremental() %}
union all
SELECT 
MD5_BINARY(GR.VALUE) as INVOICE_SALES_REP_HK
, MD5_BINARY(GR.VALUE) as INVOICE_HK
, MD5_BINARY(GR.VALUE) as SALES_REP_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}