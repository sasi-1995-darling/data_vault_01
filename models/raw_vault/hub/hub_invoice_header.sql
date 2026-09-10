---- SRC LAYER ----
WITH
SRC_SBIHLR         as ( SELECT BKCC, INVOICE_BK, INVOICE_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_bi_hdr__lrsn_psft') }} as SRC  ),
SRC_SBILNLR        as ( SELECT BKCC, INVOICE_BK, INVOICE_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_bi_line__lrsn_psft') }} as SRC  ),
SRC_SINVML         as ( SELECT BKCC, INVOICE_BK, INVOICE_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_invoice_header__ml_ebs') }} as SRC  ),
SRC_SPAYML         as ( SELECT BKCC, INVOICE_BK, INVOICE_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_payment_schedule__ml_ebs') }} as SRC  ),
SRC_SINVWSAP       as ( SELECT BKCC, SALES_INVOICE_BK, SALES_INVOICE_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_sales_invoice__winn_sap') }} as SRC  ),
SRC_SINVLML        as ( SELECT BKCC, INVOICE_BK, INVOICE_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_invoice_line__ml_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY INVOICE_BK ORDER BY _FIVETRAN_SYNCED ))=1 ),
SRC_SINVFB         as ( SELECT BKCC, INVOICE_BK, INVOICE_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_invoice_header__fib_ocf') }} as SRC  ),
SRC_SPAYFB         as ( SELECT BKCC, INVOICE_BK, INVOICE_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_payment_schedule__fib_ocf') }} as SRC  ),
SRC_HOFRSALES      as ( SELECT BKCC, INVOICE_BK, INVOICE_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_legacy_hofrus_sales__hofr_ecl') }} as SRC  ),
SRC_SINVLNFB       as ( SELECT BKCC, INVOICE_BK, INVOICE_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_invoice_line__fib_ocf') }} as SRC  ),
SRC_SINVLNWINN    as ( SELECT BKCC, SALES_INVOICE_BK, SALES_INVOICE_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_sales_invoice_line__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SALES_INVOICE_BK ORDER BY LOAD_DTS ))=1 ),
SRC_SADJML         as ( SELECT BKCC, INVOICE_BK, INVOICE_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_adjustments__ml_ebs') }} as SRC  )

/*
SRC_SBIHLR         as ( SELECT * FROM STAGING.v_psa_stg_bi_hdr__lrsn_psft )
SRC_SBILNLR        as ( SELECT * FROM STAGING.v_psa_stg_bi_line__lrsn_psft )
SRC_SINVML         as ( SELECT * FROM STAGING.v_psa_stg_invoice_header__ml_ebs )
SRC_SPAYML         as ( SELECT * FROM STAGING.v_psa_stg_payment_schedule__ml_ebs )
SRC_SINVLML        as ( SELECT * FROM STAGING.v_psa_stg_invoice_line__ml_ebs )
SRC_SINVFB         as ( SELECT * FROM STAGING.v_psa_stg_invoice_header__fib_ocf )
SRC_SPAYFB         as ( SELECT * FROM STAGING.v_psa_stg_payment_schedule__fib_ocf )
SRC_HOFRSALES      as ( SELECT * FROM STAGING.v_psa_stg_legacy_hofrus_sales__hofr_ecl )
SRC_SINVLNFB       as ( SELECT * FROM STAGING.v_psa_stg_invoice_line__fib_ocf )
SRC_SINVLNWINN     as ( SELECT * FROM STAGING.v_psa_stg_sales_invoice_line__winn_sap )
SRC_SADJML         as ( SELECT * FROM STAGING.v_psa_stg_adjustments__ml_ebs )
*/
---- LOGIC LAYER ----

, LOGIC_SBIHLR as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SBIHLR
)

, LOGIC_SBILNLR as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SBILNLR
)

, LOGIC_SINVML as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SINVML
)

, LOGIC_SPAYML as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPAYML
)

, LOGIC_SINVWSAP as (
    SELECT
        SALES_INVOICE_HK AS INVOICE_HK
      , SALES_INVOICE_BK AS INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SINVWSAP
)

, LOGIC_SINVLML as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SINVLML
)

, LOGIC_SINVFB as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SINVFB
)

, LOGIC_SPAYFB  as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPAYFB 
)

, LOGIC_HOFRSALES as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_HOFRSALES
)

, LOGIC_SINVLNFB as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SINVLNFB
)

, LOGIC_SINVLNWINN as (
    SELECT
        SALES_INVOICE_HK AS INVOICE_HK
      , SALES_INVOICE_BK AS INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SINVLNWINN
)

, LOGIC_SADJML as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SADJML
)
---- RENAME LAYER ----

, RENAME_SBIHLR as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SBIHLR
)

, RENAME_SBILNLR as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SBILNLR
)

, RENAME_SINVML as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SINVML
)

, RENAME_SPAYML as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPAYML
)

, RENAME_SINVLML as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SINVLML
)

, RENAME_SINVFB as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SINVFB
)

, RENAME_SINVWSAP as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SINVWSAP
)

, RENAME_SPAYFB  as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPAYFB 
)

, RENAME_HOFRSALES as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_HOFRSALES
)

, RENAME_SINVLNFB as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SINVLNFB
)

, RENAME_SINVLNWINN as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SINVLNWINN
)

, RENAME_SADJML as (
    SELECT
        INVOICE_HK
      , INVOICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SADJML
)
---- FILTER LAYER ----

, FILTER_SBIHLR as (
    SELECT *
    FROM RENAME_SBIHLR
)

, FILTER_SBILNLR as (
    SELECT *
    FROM RENAME_SBILNLR
)

, FILTER_SINVML as (
    SELECT *
    FROM RENAME_SINVML
)

, FILTER_SPAYML as (
    SELECT *
    FROM RENAME_SPAYML
)

, FILTER_SINVLML as (
    SELECT *
    FROM RENAME_SINVLML
)

, FILTER_SINVFB as (
    SELECT *
    FROM RENAME_SINVFB
)

, FILTER_SINVWSAP as (
    SELECT *
    FROM RENAME_SINVWSAP
)

, FILTER_SPAYFB  as (
    SELECT *
    FROM RENAME_SPAYFB 
)

, FILTER_HOFRSALES as (
    SELECT *
    FROM RENAME_HOFRSALES
)

, FILTER_SINVLNFB as (
    SELECT *
    FROM RENAME_SINVLNFB
)

, FILTER_SINVLNWINN as (
    SELECT *
    FROM RENAME_SINVLNWINN
)

, FILTER_SADJML as (
    SELECT *
    FROM RENAME_SADJML
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SBIHLR
    UNION ALL
    SELECT * FROM FILTER_SBILNLR
    UNION ALL
    SELECT * FROM FILTER_SINVML
    UNION ALL
    SELECT * FROM FILTER_SPAYML
    UNION ALL
    SELECT * FROM FILTER_SINVLML
    UNION ALL
    SELECT * FROM FILTER_SINVFB
    UNION ALL
    SELECT * FROM FILTER_SINVWSAP
    UNION ALL
    SELECT * FROM FILTER_SPAYFB 
    UNION ALL
    SELECT * FROM FILTER_HOFRSALES
    UNION ALL
    SELECT * FROM FILTER_SINVLNFB
    UNION ALL
    SELECT * FROM FILTER_SINVLNWINN
    UNION ALL
    SELECT * FROM FILTER_SADJML
)

---- FINAL LAYER ----
SELECT
          INVOICE_HK
        , INVOICE_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.INVOICE_HK = JOIN_RESULT.INVOICE_HK
)
{% endif %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per BKs and BKCC. */
qualify 1 = row_number() over (partition by INVOICE_BK, BKCC order by LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS INVOICE_HK,
GR.VALUE::text AS INVOICE_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
