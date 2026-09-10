---- SRC LAYER ----
WITH
SRC_SKFT         as ( SELECT * FROM {{ ref('v_psa_stg_statistical_key_figure_totals__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COST_VERSION_HK ORDER BY LOAD_DTS ))=1 ),
SRC_IP     as ( SELECT * FROM {{ ref('v_psa_stg_cost_total_for_internal_postings__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COST_VERSION_HK ORDER BY LOAD_DTS ))=1 ),
SRC_EP     as ( SELECT * FROM {{ ref('v_psa_stg_cost_totals_for_external_postings__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COST_VERSION_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_county         as ( SELECT * FROM STAGING.v_psa_stg_statistical_key_figure_totals__winn_sap )
, SRC_county_zip     as ( SELECT * FROM STAGING.v_psa_stg_county_zip__snfl_usps )
*/
---- LOGIC LAYER ----

, LOGIC_SKFT as (
    SELECT
        COST_VERSION_HK
      , COST_VERSION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_skft
)

, LOGIC_IP as (
    SELECT
        COST_VERSION_HK
      , COST_VERSION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_IP
)

, LOGIC_EP as (
    SELECT
        COST_VERSION_HK
      , COST_VERSION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_EP
)
---- RENAME LAYER ----

, RENAME_SKFT as (
    SELECT
        COST_VERSION_HK
      , COST_VERSION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SKFT
)

, RENAME_IP as (
    SELECT
        COST_VERSION_HK
      , COST_VERSION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_IP
)
, RENAME_EP as (
    SELECT
        COST_VERSION_HK
      , COST_VERSION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_EP
)
---- FILTER LAYER ----

, FILTER_SKFT as (
    SELECT *
    FROM RENAME_SKFT
)

, FILTER_IP as (
    SELECT *
    FROM RENAME_IP
    WHERE COST_VERSION_HK NOT IN (
        SELECT COST_VERSION_HK
        FROM FILTER_SKFT)
)
, FILTER_EP as (
    SELECT *
    FROM RENAME_EP
    WHERE COST_VERSION_HK NOT IN (
        SELECT COST_VERSION_HK
        FROM FILTER_IP)
    AND COST_VERSION_HK NOT IN (
        SELECT COST_VERSION_HK
        FROM FILTER_SKFT)
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SKFT
    UNION ALL
    SELECT * FROM FILTER_IP
    UNION ALL
    SELECT * FROM FILTER_EP
)

---- FINAL LAYER ----
SELECT
          COST_VERSION_HK
        , COST_VERSION_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.COST_VERSION_HK = JOIN_RESULT.COST_VERSION_HK
)
{% endif %}{% if not is_incremental() %} union all

SELECT MD5_BINARY(GR.VALUE)  COST_VERSION_HK
, GR.VALUE  AS COST_VERSION_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01')  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}