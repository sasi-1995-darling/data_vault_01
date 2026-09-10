---- SRC LAYER ----
WITH
SRC_c              as ( SELECT BKCC, CONTROLLING_AREA_BK, CONTROLLING_AREA_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_controlling_ledger_entry__winn_sap') }} as SRC
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CONTROLLING_AREA_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_d              as ( SELECT BKCC, CONTROLLING_AREA_BK, CONTROLLING_AREA_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_controlling_header__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CONTROLLING_AREA_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_e              as ( SELECT BKCC, CONTROLLING_AREA_BK, CONTROLLING_AREA_HK, LOAD_DTS, PSA_RECORD_SOURCE FROM {{ ref('v_psa_stg_controlling_area__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CONTROLLING_AREA_BK ORDER BY GLCHANGETIME ))=1 ),                        
SRC_CE1NEW4        as ( SELECT BKCC, CONTROLLING_AREA_BK, CONTROLLING_AREA_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_copa_sales__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CONTROLLING_AREA_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_AZCOPA         as ( SELECT BKCC, CONTROLLING_AREA_BK, CONTROLLING_AREA_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_copa_sales_history__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CONTROLLING_AREA_BK ORDER BY ZEXTRACTDATE ))=1 )

/*
SRC_c              as ( SELECT * FROM STAGING.v_psa_stg_controlling_ledger_entry__winn_sap )
SRC_d              as ( SELECT * FROM STAGING.v_psa_stg_controlling_area__winn_sap )
SRC_CE1NEW4        as ( SELECT * FROM STAGING.v_psa_stg_copa_sales__winn_sap )
SRC_AZCOPA         as ( SELECT * FROM STAGING.v_psa_stg_copa_sales_history__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_c as (
    SELECT
        CONTROLLING_AREA_HK
      , CONTROLLING_AREA_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_c
)

, LOGIC_d as (
    SELECT
        CONTROLLING_AREA_HK
      , CONTROLLING_AREA_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_d
)

, LOGIC_e as (
    SELECT
        CONTROLLING_AREA_HK
      , CONTROLLING_AREA_BK
      , BKCC
      , LOAD_DTS
      , PSA_RECORD_SOURCE
    FROM SRC_e
)

, LOGIC_CE1NEW4 as (
    SELECT
        CONTROLLING_AREA_HK
      , CONTROLLING_AREA_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_CE1NEW4
)

, LOGIC_AZCOPA as (
    SELECT
        CONTROLLING_AREA_HK
      , CONTROLLING_AREA_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_AZCOPA
)
---- RENAME LAYER ----

, RENAME_c as (
    SELECT
        CONTROLLING_AREA_HK
      , CONTROLLING_AREA_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_c
)

, RENAME_d as (
    SELECT
        CONTROLLING_AREA_HK
      , CONTROLLING_AREA_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_d
)

, RENAME_e as (
    SELECT
        CONTROLLING_AREA_HK
      , CONTROLLING_AREA_BK
      , BKCC
      , LOAD_DTS
      , PSA_RECORD_SOURCE  as REC_SRC
    FROM LOGIC_e
)
, RENAME_CE1NEW4 as (
    SELECT
        CONTROLLING_AREA_HK
      , CONTROLLING_AREA_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_CE1NEW4
)

, RENAME_AZCOPA as (
    SELECT
        CONTROLLING_AREA_HK
      , CONTROLLING_AREA_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_AZCOPA
)
---- FILTER LAYER ----

, FILTER_c as (
    SELECT *
    FROM RENAME_c
)

, FILTER_d as (
    SELECT *
    FROM RENAME_d
)

, FILTER_e as (
    SELECT *
    FROM RENAME_e
)
, FILTER_CE1NEW4 as (
    SELECT *
    FROM RENAME_CE1NEW4
)

, FILTER_AZCOPA as (
    SELECT *
    FROM RENAME_AZCOPA
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_c
    UNION ALL
    SELECT * FROM FILTER_d
    UNION ALL
    SELECT * FROM FILTER_e
    UNION ALL
    SELECT * FROM FILTER_CE1NEW4
    UNION ALL
    SELECT * FROM FILTER_AZCOPA
)

---- FINAL LAYER ----
SELECT
          CONTROLLING_AREA_HK
        , CONTROLLING_AREA_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.CONTROLLING_AREA_HK = JOIN_RESULT.CONTROLLING_AREA_HK
)
{% endif %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per BKs and BKCC. */
qualify 1 = row_number() over (partition by CONTROLLING_AREA_BK, BKCC order by LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS CONTROLLING_AREA_HK,
GR.VALUE::text AS CONTROLLING_AREA_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01') AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
