---- SRC LAYER ----
WITH
SRC_E21            as ( SELECT LNK_SUPPLIER_PAYMENT_TERM_HK, SUPPLIER_HK, PAYMENT_TERM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_supplier__tt_e21') }} as SRC
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_SUPPLIER_PAYMENT_TERM_HK ORDER BY LOAD_DTS)) = 1 )
, SRC_GP           as ( SELECT LNK_SUPPLIER_PAYMENT_TERM_HK, SUPPLIER_HK, PAYMENT_TERM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_supplier__tt_gp') }} as SRC
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_SUPPLIER_PAYMENT_TERM_HK ORDER BY LOAD_DTS)) = 1 )

/*
SRC_E21            as ( SELECT * FROM int_staging_views.v_psa_stg_supplier__tt_e21 )
SRC_GP             as ( SELECT * FROM int_staging_views.v_psa_stg_supplier__tt_gp )
*/
---- LOGIC LAYER ----

, LOGIC_E21 as (
    SELECT
        LNK_SUPPLIER_PAYMENT_TERM_HK
      , SUPPLIER_HK
      , PAYMENT_TERM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_E21
)

, LOGIC_GP as (
    SELECT
        LNK_SUPPLIER_PAYMENT_TERM_HK
      , SUPPLIER_HK
      , PAYMENT_TERM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_GP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM LOGIC_E21

    union all

    SELECT * FROM LOGIC_GP
)

---- FINAL LAYER ----
SELECT
          LNK_SUPPLIER_PAYMENT_TERM_HK
        , SUPPLIER_HK
        , PAYMENT_TERM_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} existing
    WHERE existing.LNK_SUPPLIER_PAYMENT_TERM_HK = JOIN_RESULT.LNK_SUPPLIER_PAYMENT_TERM_HK
)
{% endif %}
{% if not is_incremental() %}

union all
SELECT
MD5_BINARY(GR.VALUE) AS LNK_SUPPLIER_PAYMENT_TERM_HK,
MD5_BINARY(GR.VALUE) AS SUPPLIER_HK,
MD5_BINARY(GR.VALUE) AS PAYMENT_TERM_HK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
