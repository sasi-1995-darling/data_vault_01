---- SRC LAYER ----
WITH
SRC_sml            as ( SELECT LNK_PO_HEADER_SUPPLIER_SITE_HK, LOAD_DTS, PO_HEADER_HK, REC_SRC, SUPPLIER_HK, SUPPLIER_SITE_HK FROM {{ ref('v_psa_stg_po_header__ml_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PO_HEADER_SUPPLIER_SITE_HK ORDER BY LOAD_DTS ))=1 ),
SRC_semtk          as ( SELECT LNK_PO_HEADER_SUPPLIER_SITE_HK, LOAD_DTS, PO_HEADER_HK, REC_SRC, SUPPLIER_HK, SUPPLIER_SITE_HK FROM {{ ref('v_psa_stg_po_header__emtk_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PO_HEADER_SUPPLIER_SITE_HK ORDER BY LOAD_DTS ))=1 ),
SRC_sfib           as ( SELECT LNK_PO_HEADER_SUPPLIER_SITE_HK, LOAD_DTS, PO_HEADER_HK, REC_SRC, SUPPLIER_HK, SUPPLIER_SITE_HK FROM {{ ref('v_psa_stg_po_header__fib_ocf') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PO_HEADER_SUPPLIER_SITE_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_sml            as ( SELECT * FROM STAGING.v_psa_stg_po_header__ml_ebs )
SRC_semtk          as ( SELECT * FROM STAGING.v_psa_stg_po_header__emtk_ebs )
SRC_sfib           as ( SELECT * FROM STAGING.v_psa_stg_po_header__fib_ocf )
*/
---- LOGIC LAYER ----

, LOGIC_sml as (
    SELECT
        LNK_PO_HEADER_SUPPLIER_SITE_HK
      , PO_HEADER_HK
      , SUPPLIER_HK
      , SUPPLIER_SITE_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_sml
)

, LOGIC_semtk as (
    SELECT
        LNK_PO_HEADER_SUPPLIER_SITE_HK
      , PO_HEADER_HK
      , SUPPLIER_HK
      , SUPPLIER_SITE_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_semtk
)

, LOGIC_sfib as (
    SELECT
        LNK_PO_HEADER_SUPPLIER_SITE_HK
      , PO_HEADER_HK
      , SUPPLIER_HK
      , SUPPLIER_SITE_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_sfib
)
---- RENAME LAYER ----

, RENAME_sml as (
    SELECT
        LNK_PO_HEADER_SUPPLIER_SITE_HK
      , PO_HEADER_HK
      , SUPPLIER_HK
      , SUPPLIER_SITE_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_sml
)

, RENAME_semtk as (
    SELECT
        LNK_PO_HEADER_SUPPLIER_SITE_HK
      , PO_HEADER_HK
      , SUPPLIER_HK
      , SUPPLIER_SITE_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_semtk
)

, RENAME_sfib as (
    SELECT
        LNK_PO_HEADER_SUPPLIER_SITE_HK
      , PO_HEADER_HK
      , SUPPLIER_HK
      , SUPPLIER_SITE_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_sfib
)
---- FILTER LAYER ----

, FILTER_sml as (
    SELECT *
    FROM RENAME_sml
)

, FILTER_semtk as (
    SELECT *
    FROM RENAME_semtk
)

, FILTER_sfib as (
    SELECT *
    FROM RENAME_sfib
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_sml
    UNION ALL
    SELECT * FROM FILTER_semtk
    UNION ALL
    SELECT * FROM FILTER_sfib
)

---- FINAL LAYER ----
SELECT
          LNK_PO_HEADER_SUPPLIER_SITE_HK
        , PO_HEADER_HK
        , SUPPLIER_HK
        , SUPPLIER_SITE_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_PO_HEADER_SUPPLIER_SITE_HK = JOIN_RESULT.LNK_PO_HEADER_SUPPLIER_SITE_HK )
{% endif %}
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_PO_HEADER_SUPPLIER_SITE_HK,
MD5_BINARY(GR.VALUE) AS PO_HEADER_HK,
MD5_BINARY(GR.VALUE) AS SUPPLIER_HK,
MD5_BINARY(GR.VALUE) AS SUPPLIER_SITE_HK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
