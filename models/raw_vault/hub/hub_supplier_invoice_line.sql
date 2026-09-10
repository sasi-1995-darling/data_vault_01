---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT SUPPLIER_INVOICE_LINE_HK, INVOICE_ID_BK, INVOICE_LINE_BK, LOAD_DTS, BKCC, REC_SRC FROM {{ ref('v_psa_stg_supplier_invoice_line__fib_ocf') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_INVOICE_LINE_HK ORDER BY LOAD_DTS)) = 1 )

,
SRC_winnsap            as ( SELECT SUPPLIER_INVOICE_LINE_HK, INVOICE_ID_BK, INVOICE_LINE_BK, LOAD_DTS, BKCC, REC_SRC FROM {{ ref('v_psa_stg_supplier_invoice_line__winn_sap') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY INVOICE_ID_BK, INVOICE_LINE_BK, BKCC ORDER BY LOAD_DTS)) = 1
)

/*
SRC_SRC            as ( SELECT * FROM int_staging_views.v_psa_stg_supplier_invoice_line__fib_ocf )
*/
,
SRC_EMTKEBS        as ( SELECT SUPPLIER_INVOICE_LINE_HK, INVOICE_ID_BK, INVOICE_LINE_BK, LOAD_DTS, BKCC, REC_SRC FROM {{ ref('v_psa_stg_supplier_invoice_line__emtk_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_INVOICE_LINE_HK ORDER BY LOAD_DTS)) = 1 )

/*
SRC_EMTKEBS        as ( SELECT * FROM int_staging_views.v_psa_stg_supplier_invoice_line__emtk_ebs )
*/
,
SRC_MLEBS          as ( SELECT SUPPLIER_INVOICE_LINE_HK, INVOICE_ID_BK, INVOICE_LINE_BK, LOAD_DTS, BKCC, REC_SRC FROM {{ ref('v_psa_stg_supplier_invoice_line__ml_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_INVOICE_LINE_HK ORDER BY LOAD_DTS)) = 1 )

/*
SRC_MLEBS          as ( SELECT * FROM int_staging_views.v_psa_stg_supplier_invoice_line__ml_ebs )
*/---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        SUPPLIER_INVOICE_LINE_HK
      , INVOICE_ID_BK::text AS INVOICE_ID_BK
      , INVOICE_LINE_BK::text AS INVOICE_LINE_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_SRC
)

, LOGIC_EMTKEBS as (
    SELECT
        SUPPLIER_INVOICE_LINE_HK
      , INVOICE_ID_BK::text AS INVOICE_ID_BK
      , INVOICE_LINE_BK::text AS INVOICE_LINE_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_EMTKEBS
)

, LOGIC_MLEBS as (
    SELECT
        SUPPLIER_INVOICE_LINE_HK
      , INVOICE_ID_BK::text AS INVOICE_ID_BK
      , INVOICE_LINE_BK::text AS INVOICE_LINE_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_MLEBS
)


, LOGIC_winnsap as (
    SELECT
        SUPPLIER_INVOICE_LINE_HK
      , INVOICE_ID_BK::text AS INVOICE_ID_BK
      , INVOICE_LINE_BK::text AS INVOICE_LINE_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_winnsap
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
    SELECT * FROM LOGIC_winnsap
)

---- FINAL LAYER ----
SELECT
          SUPPLIER_INVOICE_LINE_HK
        , INVOICE_ID_BK
        , INVOICE_LINE_BK
        , LOAD_DTS
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} existing
    WHERE existing.SUPPLIER_INVOICE_LINE_HK = JOIN_RESULT.SUPPLIER_INVOICE_LINE_HK
)
{% endif %}
/* Safety dedup — matches production hub pattern */
qualify 1 = row_number() over (partition by INVOICE_ID_BK, INVOICE_LINE_BK, BKCC order by LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS SUPPLIER_INVOICE_LINE_HK,
GR.VALUE::text AS INVOICE_ID_BK,
GR.VALUE::text AS INVOICE_LINE_BK,
'1900-01-01T00:00:00'::TIMESTAMP_NTZ AS LOAD_DTS,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
