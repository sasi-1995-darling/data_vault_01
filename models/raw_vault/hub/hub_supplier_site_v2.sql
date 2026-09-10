---- SRC LAYER ----
WITH
SRC_SMDM           as ( SELECT BKCC, LOAD_DTS, REC_SRC, SUPPLIER_BK, SUPPLIER_SITE_BK, SUPPLIER_SITE_HK FROM {{ ref('v_psa_stg_supplier_site__mdm') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_SITE_HK ORDER BY LOAD_DTS ))=1 ),
SRC_SML            as ( SELECT BKCC, LOAD_DTS, REC_SRC, SUPPLIER_BK, SUPPLIER_SITE_BK, SUPPLIER_SITE_HK FROM {{ ref('v_psa_stg_supplier_site__ml_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_SITE_HK ORDER BY LOAD_DTS ))=1 ),
SRC_SEMTK          as ( SELECT BKCC, LOAD_DTS, REC_SRC, SUPPLIER_BK, SUPPLIER_SITE_BK, SUPPLIER_SITE_HK FROM {{ ref('v_psa_stg_supplier_site__emtk_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_SITE_HK ORDER BY LOAD_DTS ))=1 ),
SRC_SFIB           as ( SELECT BKCC, LOAD_DTS, REC_SRC, SUPPLIER_BK, SUPPLIER_SITE_BK, SUPPLIER_SITE_HK FROM {{ ref('v_psa_stg_supplier_site__fib_ocf') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_SITE_HK ORDER BY LOAD_DTS ))=1 )
,SRC_lrsnpsft            as ( SELECT BKCC, LOAD_DTS, REC_SRC, SUPPLIER_BK, SUPPLIER_SITE_BK, SUPPLIER_SITE_HK FROM {{ ref('v_psa_stg_supplier_site__lrsn_psft') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY VENDOR_ID, VNDR_LOC, BKCC ORDER BY _FIVETRAN_SYNCED)) = 1
)

/*
SRC_SMDM           as ( SELECT * FROM STAGING.v_psa_stg_supplier_site__mdm )
SRC_SML            as ( SELECT * FROM STAGING.v_psa_stg_supplier_site__ml_ebs )
SRC_SEMTK          as ( SELECT * FROM STAGING.v_psa_stg_supplier_site__emtk_ebs )
SRC_SFIB           as ( SELECT * FROM STAGING.v_psa_stg_supplier_site__fib_ocf )
*/
---- LOGIC LAYER ----

, LOGIC_SMDM as (
    SELECT
        SUPPLIER_SITE_HK
      , SUPPLIER_BK
      , SUPPLIER_SITE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SMDM
)

, LOGIC_SML as (
    SELECT
        SUPPLIER_SITE_HK
      , SUPPLIER_BK
      , SUPPLIER_SITE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SML
)

, LOGIC_SEMTK as (
    SELECT
        SUPPLIER_SITE_HK
      , SUPPLIER_BK
      , SUPPLIER_SITE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SEMTK
)

, LOGIC_SFIB as (
    SELECT
        SUPPLIER_SITE_HK
      , SUPPLIER_BK
      , SUPPLIER_SITE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SFIB
)

, LOGIC_lrsnpsft as (
    SELECT
        SUPPLIER_SITE_HK
      , SUPPLIER_BK
      , SUPPLIER_SITE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_lrsnpsft
)
---- RENAME LAYER ----

, RENAME_SMDM as (
    SELECT
        SUPPLIER_SITE_HK
      , SUPPLIER_BK
      , SUPPLIER_SITE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SMDM
)

, RENAME_SML as (
    SELECT
        SUPPLIER_SITE_HK
      , SUPPLIER_BK
      , SUPPLIER_SITE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SML
)

, RENAME_SEMTK as (
    SELECT
        SUPPLIER_SITE_HK
      , SUPPLIER_BK
      , SUPPLIER_SITE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SEMTK
)

, RENAME_SFIB as (
    SELECT
        SUPPLIER_SITE_HK
      , SUPPLIER_BK
      , SUPPLIER_SITE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SFIB
)

, RENAME_lrsnpsft as (
    SELECT
        SUPPLIER_SITE_HK
      , SUPPLIER_BK
      , SUPPLIER_SITE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_lrsnpsft
)
---- FILTER LAYER ----

, FILTER_SMDM as (
    SELECT *
    FROM RENAME_SMDM
)

, FILTER_SML as (
    SELECT *
    FROM RENAME_SML
)

, FILTER_SEMTK as (
    SELECT *
    FROM RENAME_SEMTK
)

, FILTER_SFIB as (
    SELECT *
    FROM RENAME_SFIB
)

, FILTER_lrsnpsft as (
    SELECT *
    FROM RENAME_lrsnpsft
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SMDM
    UNION ALL
    SELECT * FROM FILTER_SML
    UNION ALL
    SELECT * FROM FILTER_SEMTK
    UNION ALL
    SELECT * FROM FILTER_SFIB
    UNION ALL
    SELECT * FROM FILTER_lrsnpsft
)

---- FINAL LAYER ----
SELECT
          SUPPLIER_SITE_HK
        , SUPPLIER_BK
        , SUPPLIER_SITE_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.SUPPLIER_SITE_HK = JOIN_RESULT.SUPPLIER_SITE_HK
)
{% endif %}
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS SUPPLIER_SITE_HK,
GR.VALUE::text AS SUPPLIER_BK,
GR.VALUE::text AS SUPPLIER_SITE_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
