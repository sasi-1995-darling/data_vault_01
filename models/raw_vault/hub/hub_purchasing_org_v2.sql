---- SRC LAYER ----
WITH
SRC_porg           as ( SELECT BKCC, LOAD_DTS, PURCHASING_ORG_BK, PURCHASING_ORG_HK, REC_SRC FROM {{ ref('v_psa_stg_purchasing_org__winn_sap_v2') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PURCHASING_ORG_HK ORDER BY LOAD_DTS ))=1 ),
SRC_sp             as ( SELECT BKCC, LOAD_DTS, PURCHASING_ORG_BK, PURCHASING_ORG_HK, REC_SRC FROM {{ ref('v_psa_stg_supplier_purchasing_org__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PURCHASING_ORG_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_porg           as ( SELECT * FROM staging.v_psa_stg_purchasing_org__winn_sap_v2 )
SRC_sp             as ( SELECT * FROM staging.v_psa_stg_supplier_purchasing_org__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_porg as (
    SELECT
        PURCHASING_ORG_HK
      , PURCHASING_ORG_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_porg
)

, LOGIC_sp as (
    SELECT
        PURCHASING_ORG_HK
      , PURCHASING_ORG_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_sp
)
---- RENAME LAYER ----

, RENAME_porg as (
    SELECT
        PURCHASING_ORG_HK
      , PURCHASING_ORG_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_porg
)

, RENAME_sp as (
    SELECT
        PURCHASING_ORG_HK
      , PURCHASING_ORG_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_sp
)
---- FILTER LAYER ----

, FILTER_porg as (
    SELECT *
    FROM RENAME_porg
)

, FILTER_sp as (
    SELECT *
    FROM RENAME_sp
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_porg
    UNION ALL
    SELECT * FROM FILTER_sp
)

---- FINAL LAYER ----
SELECT
          PURCHASING_ORG_HK
        , PURCHASING_ORG_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PURCHASING_ORG_HK = JOIN_RESULT.PURCHASING_ORG_HK
)
{% endif %}                                                                            
qualify 1= row_number() over(partition by PURCHASING_ORG_HK order by DECODE(REC_SRC, 'USOHNO.SAP.ECCPRD.Z_T024E', 1, 'USOHNO.SAP.ECCPRD.Z_LFM1', 10, 2) )

{% if not is_incremental() %}
union all
SELECT 
MD5_BINARY(GR.VALUE) AS PURCHASING_ORG_HK,
GR.VALUE::text AS PURCHASING_ORG_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
