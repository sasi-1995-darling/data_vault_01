---- SRC LAYER ----
WITH
SRC_SML            as ( SELECT BKCC, LEGAL_ENTITY_HK, LOAD_DTS, ORGANIZATION_ID, REC_SRC FROM {{ ref('v_psa_stg_legal_entity__ml_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LEGAL_ENTITY_HK ORDER BY LOAD_DTS ))=1 ),
SRC_SWINN          as ( SELECT BKCC, BUKRS, LEGAL_ENTITY_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_legal_entity__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LEGAL_ENTITY_HK ORDER BY LOAD_DTS ))=1 ),
SRC_SLR            as ( SELECT BKCC, LEGAL_ENTITY_BK, LEGAL_ENTITY_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_legal_entity__lrsn_psft') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LEGAL_ENTITY_HK ORDER BY LOAD_DTS ))=1 ),
SRC_SEMTK          as ( SELECT BKCC, LEGAL_ENTITY_BK, LEGAL_ENTITY_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_legal_entity__emtk_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LEGAL_ENTITY_HK ORDER BY LOAD_DTS ))=1 ),
SRC_LEL            as ( SELECT BKCC, LEGAL_ENTITY_BK, LEGAL_ENTITY_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_legal_entity_ledger__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LEGAL_ENTITY_HK ORDER BY LOAD_DTS ))=1 ),
SRC_SMDM           as ( SELECT BKCC, LEGAL_ENTITY_BK, LEGAL_ENTITY_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_supplier_site_org__mdm') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LEGAL_ENTITY_HK ORDER BY LOAD_DTS ))=1 ),
SRC_STTGP          as ( SELECT BKCC, LEGAL_ENTITY_BK, LEGAL_ENTITY_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_po_header__tt_gp') }} as SRC 
                        WHERE  CMPANYID != 0 and POTYPE = 1
                        QUALIFY (ROW_NUMBER()OVER (PARTITION BY LEGAL_ENTITY_HK ORDER BY PSA_LOAD_DTS DESC )) =  1  ),
SRC_STTE21         as ( SELECT BKCC, LEGAL_ENTITY_BK, LEGAL_ENTITY_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_legal_entity__tt_e21') }} as SRC 
                        QUALIFY (ROW_NUMBER()OVER (PARTITION BY LEGAL_ENTITY_HK ORDER BY PSA_LOAD_DTS DESC )) =  1  ),
SRC_SFIBOCF        as ( SELECT BKCC, LEGAL_ENTITY_BK, LEGAL_ENTITY_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_legal_entity__fib_ocf') }} as SRC 
                        QUALIFY (ROW_NUMBER()OVER (PARTITION BY LEGAL_ENTITY_HK ORDER BY PSA_LOAD_DTS DESC )) =  1  )

/*
SRC_SML            as ( SELECT * FROM STAGING.v_psa_stg_legal_entity__ml_ebs )
SRC_SWINN          as ( SELECT * FROM STAGING.v_psa_stg_legal_entity__winn_sap )
SRC_SLR            as ( SELECT * FROM STAGING.v_psa_stg_legal_entity__lrsn_psft )
SRC_SEMTK          as ( SELECT * FROM STAGING.v_psa_stg_legal_entity__emtk_ebs )
SRC_LEL            as ( SELECT * FROM STAGING.v_psa_stg_legal_entity_ledger__winn_sap )
SRC_SMDM           as ( SELECT * FROM STAGING.v_psa_stg_supplier_site_org__mdm )
SRC_STTGP          as ( SELECT * FROM STAGING.v_psa_stg_po_header__tt_gp )
SRC_STTE21         as ( SELECT * FROM STAGING.v_psa_stg_legal_entity__tt_e21 )
SRC_SFIBOCF        as ( SELECT * FROM STAGING.v_psa_stg_legal_entity__fib_ocf )
*/
---- LOGIC LAYER ----

, LOGIC_SML as (
    SELECT
        LEGAL_ENTITY_HK
      , ORGANIZATION_ID
      , ORGANIZATION_ID::TEXT                                        as                                    LEGAL_ENTITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SML
)

, LOGIC_SWINN as (
    SELECT
        LEGAL_ENTITY_HK
      , BUKRS                                                        as                                    LEGAL_ENTITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SWINN
)

, LOGIC_SLR as (
    SELECT
        LEGAL_ENTITY_HK
      , LEGAL_ENTITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SLR
)

, LOGIC_SEMTK as (
    SELECT
        LEGAL_ENTITY_HK
      , LEGAL_ENTITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SEMTK
)

, LOGIC_LEL as (
    SELECT
        LEGAL_ENTITY_HK
      , LEGAL_ENTITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_LEL
)

, LOGIC_SMDM as (
    SELECT
        LEGAL_ENTITY_HK
      , LEGAL_ENTITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SMDM
)

, LOGIC_STTGP as (
    SELECT
        LEGAL_ENTITY_HK
      , LEGAL_ENTITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_STTGP
)

, LOGIC_STTE21 as (
    SELECT
        LEGAL_ENTITY_HK
      , LEGAL_ENTITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_STTE21
)

, LOGIC_SFIBOCF as (
    SELECT
        LEGAL_ENTITY_HK
      , LEGAL_ENTITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SFIBOCF
)
---- RENAME LAYER ----

, RENAME_SML as (
    SELECT
        LEGAL_ENTITY_HK
      , LEGAL_ENTITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SML
)

, RENAME_SWINN as (
    SELECT
        LEGAL_ENTITY_HK
      , LEGAL_ENTITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SWINN
)

, RENAME_SLR as (
    SELECT
        LEGAL_ENTITY_HK
      , LEGAL_ENTITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SLR
)

, RENAME_SEMTK as (
    SELECT
        LEGAL_ENTITY_HK
      , LEGAL_ENTITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SEMTK
)

, RENAME_LEL as (
    SELECT
        LEGAL_ENTITY_HK
      , LEGAL_ENTITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_LEL
)

, RENAME_SMDM as (
    SELECT
        LEGAL_ENTITY_HK
      , LEGAL_ENTITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SMDM
)

, RENAME_STTGP as (
    SELECT
        LEGAL_ENTITY_HK
      , LEGAL_ENTITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_STTGP
)

, RENAME_STTE21 as (
    SELECT
        LEGAL_ENTITY_HK
      , LEGAL_ENTITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_STTE21
)

, RENAME_SFIBOCF as (
    SELECT
        LEGAL_ENTITY_HK
      , LEGAL_ENTITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SFIBOCF
)
---- FILTER LAYER ----

, FILTER_SML as (
    SELECT *
    FROM RENAME_SML
)

, FILTER_SWINN as (
    SELECT *
    FROM RENAME_SWINN
)

, FILTER_SLR as (
    SELECT *
    FROM RENAME_SLR
)

, FILTER_SEMTK as (
    SELECT *
    FROM RENAME_SEMTK
)

, FILTER_LEL as (
    SELECT *
    FROM RENAME_LEL
)

, FILTER_SMDM as (
    SELECT *
    FROM RENAME_SMDM
)

, FILTER_STTGP as (
    SELECT *
    FROM RENAME_STTGP
)

, FILTER_STTE21 as (
    SELECT *
    FROM RENAME_STTE21
)

, FILTER_SFIBOCF as (
    SELECT *
    FROM RENAME_SFIBOCF
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SML
    UNION ALL
    SELECT * FROM FILTER_SWINN
    UNION ALL
    SELECT * FROM FILTER_SLR
    UNION ALL
    SELECT * FROM FILTER_SEMTK
    UNION ALL
    SELECT * FROM FILTER_LEL
    UNION ALL
    SELECT * FROM FILTER_SMDM
    UNION ALL
    SELECT * FROM FILTER_STTGP
    UNION ALL
    SELECT * FROM FILTER_STTE21
    UNION ALL
    SELECT * FROM FILTER_SFIBOCF
)

---- FINAL LAYER ----
SELECT
          LEGAL_ENTITY_HK
        , LEGAL_ENTITY_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LEGAL_ENTITY_HK = JOIN_RESULT.LEGAL_ENTITY_HK
)
{% endif %}
QUALIFY 1= ROW_NUMBER() OVER (PARTITION BY LEGAL_ENTITY_HK ORDER BY LOAD_DTS)
{% if not is_incremental() %}
union all

SELECT MD5_BINARY(GR.VALUE)  LEGAL_ENTITY_HK
, GR.VALUE  AS LEGAL_ENTITY_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
