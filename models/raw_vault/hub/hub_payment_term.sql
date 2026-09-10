---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT BKCC, LOAD_DTS, PAYMENT_TERM_BK, PAYMENT_TERM_HK, REC_SRC FROM {{ ref('v_psa_stg_payment_terms__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PAYMENT_TERM_HK ORDER BY LOAD_DTS ))=1 ),
SRC_STXTWINN       as ( SELECT BKCC, LOAD_DTS, PAYMENT_TERM_BK, PAYMENT_TERM_HK, REC_SRC FROM {{ ref('v_psa_stg_payment_terms_text__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PAYMENT_TERM_HK ORDER BY LOAD_DTS ))=1 ),
SRC_SML            as ( SELECT BKCC, LOAD_DTS, PAYMENT_TERM_BK, PAYMENT_TERM_HK, REC_SRC FROM {{ ref('v_psa_stg_payment_terms_lines__ml_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PAYMENT_TERM_HK ORDER BY LOAD_DTS ))=1 ),
SRC_SEMTK          as ( SELECT BKCC, LOAD_DTS, PAYMENT_TERM_BK, PAYMENT_TERM_HK, REC_SRC FROM {{ ref('v_psa_stg_payment_terms_lines__emtk_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PAYMENT_TERM_HK ORDER BY LOAD_DTS ))=1 ),
SRC_SFIB           as ( SELECT BKCC, LOAD_DTS, PAYMENT_TERM_BK, PAYMENT_TERM_HK, REC_SRC FROM {{ ref('v_psa_stg_payment_terms_lines__fib_ocf') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PAYMENT_TERM_HK ORDER BY LOAD_DTS ))=1 ),
SRC_lrsnpsft       as ( SELECT BKCC, LOAD_DTS, PAYMENT_TERM_BK, PAYMENT_TERM_HK, REC_SRC FROM {{ ref('v_psa_stg_payment_terms_header__lrsn_psft') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PAYMENT_TERM_HK ORDER BY LOAD_DTS ))=1 )

,
SRC_tte21            as ( SELECT PAYMENT_TERM_HK, PAYMENT_TERM_BK, LOAD_DTS, BKCC, REC_SRC FROM {{ ref('v_psa_stg_payment_terms__tt_e21') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PAYMENT_TERM_BK, BKCC ORDER BY LOAD_DTS)) = 1
)

,
SRC_ttgp            as ( SELECT PAYMENT_TERM_HK, PAYMENT_TERM_BK, LOAD_DTS, BKCC, REC_SRC FROM {{ ref('v_psa_stg_payment_terms__tt_gp') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PAYMENT_TERM_BK, BKCC ORDER BY LOAD_DTS)) = 1
)

,
SRC_ttsuppe21       as ( SELECT PAYMENT_TERM_HK, PAYMENT_TERM_BK, LOAD_DTS, BKCC, REC_SRC FROM {{ ref('v_psa_stg_supplier__tt_e21') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PAYMENT_TERM_BK, BKCC ORDER BY LOAD_DTS)) = 1
)

/*
SRC_SWINN          as ( SELECT * FROM STAGING.v_psa_stg_payment_terms__winn_sap )
SRC_STXTWINN       as ( SELECT * FROM STAGING.v_psa_stg_payment_terms_text__winn_sap )
SRC_SML            as ( SELECT * FROM STAGING.v_psa_stg_payment_terms_lines__ml_ebs )
SRC_SEMTK          as ( SELECT * FROM STAGING.v_psa_stg_payment_terms_lines__emtk_ebs )
SRC_SFIB           as ( SELECT * FROM STAGING.v_psa_stg_payment_terms_lines__fib_ocf )
SRC_lrsnpsft       as ( SELECT * FROM int_staging_views.v_psa_stg_payment_terms_header__lrsn_psft )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        PAYMENT_TERM_HK
      , PAYMENT_TERM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SWINN
)

, LOGIC_STXTWINN as (
    SELECT
        PAYMENT_TERM_HK
      , PAYMENT_TERM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_STXTWINN
)

, LOGIC_SML as (
    SELECT
        PAYMENT_TERM_HK
      , PAYMENT_TERM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SML
)

, LOGIC_SEMTK as (
    SELECT
        PAYMENT_TERM_HK
      , PAYMENT_TERM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SEMTK
)

, LOGIC_SFIB as (
    SELECT
        PAYMENT_TERM_HK
      , PAYMENT_TERM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SFIB
)

, LOGIC_lrsnpsft as (
    SELECT
        PAYMENT_TERM_HK
      , PAYMENT_TERM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_lrsnpsft
)

, LOGIC_tte21 as (
    SELECT
        PAYMENT_TERM_HK
      , PAYMENT_TERM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_tte21
)

, LOGIC_ttgp as (
    SELECT
        PAYMENT_TERM_HK
      , PAYMENT_TERM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ttgp
)

, LOGIC_ttsuppe21 as (
    SELECT
        PAYMENT_TERM_HK
      , PAYMENT_TERM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ttsuppe21
)
---- RENAME LAYER ----

, RENAME_SWINN as (
    SELECT
        PAYMENT_TERM_HK
      , PAYMENT_TERM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SWINN
)

, RENAME_STXTWINN as (
    SELECT
        PAYMENT_TERM_HK
      , PAYMENT_TERM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_STXTWINN
)

, RENAME_SML as (
    SELECT
        PAYMENT_TERM_HK
      , PAYMENT_TERM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SML
)

, RENAME_SEMTK as (
    SELECT
        PAYMENT_TERM_HK
      , PAYMENT_TERM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SEMTK
)

, RENAME_SFIB as (
    SELECT
        PAYMENT_TERM_HK
      , PAYMENT_TERM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SFIB
)

, RENAME_lrsnpsft as (
    SELECT
        PAYMENT_TERM_HK
      , PAYMENT_TERM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_lrsnpsft
)

, RENAME_tte21 as (
    SELECT
        PAYMENT_TERM_HK
      , PAYMENT_TERM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_tte21
)

, RENAME_ttgp as (
    SELECT
        PAYMENT_TERM_HK
      , PAYMENT_TERM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ttgp
)

, RENAME_ttsuppe21 as (
    SELECT
        PAYMENT_TERM_HK
      , PAYMENT_TERM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ttsuppe21
)
---- FILTER LAYER ----

, FILTER_SWINN as (
    SELECT *
    FROM RENAME_SWINN
)

, FILTER_STXTWINN as (
    SELECT *
    FROM RENAME_STXTWINN
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

, FILTER_tte21 as (
    SELECT *
    FROM RENAME_tte21
)

, FILTER_ttgp as (
    SELECT *
    FROM RENAME_ttgp
)

, FILTER_ttsuppe21 as (
    SELECT *
    FROM RENAME_ttsuppe21
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SWINN
    UNION ALL
    SELECT * FROM FILTER_STXTWINN
    UNION ALL
    SELECT * FROM FILTER_SML
    UNION ALL
    SELECT * FROM FILTER_SEMTK
    UNION ALL
    SELECT * FROM FILTER_SFIB
    UNION ALL
    SELECT * FROM FILTER_lrsnpsft
    UNION ALL
    SELECT * FROM FILTER_tte21
    UNION ALL
    SELECT * FROM FILTER_ttgp
    UNION ALL
    SELECT * FROM FILTER_ttsuppe21
)

---- FINAL LAYER ----
SELECT
          PAYMENT_TERM_HK
        , PAYMENT_TERM_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PAYMENT_TERM_HK = JOIN_RESULT.PAYMENT_TERM_HK
)
{% endif %}
qualify 1= row_number() over(partition by PAYMENT_TERM_HK order by DECODE(REC_SRC, 'USOHNO.SAP.ECCPRD.Z_T052', 1, 'USOHMA.ORCL.E21PRD.APVNDTERM', 2, 'USOHNO.SAP.ECCPRD.Z_T052U', 10, 99) )
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PAYMENT_TERM_HK,
GR.VALUE::text AS PAYMENT_TERM_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
