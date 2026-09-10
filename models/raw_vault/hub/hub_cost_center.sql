---- SRC LAYER ----
WITH
SRC_CSKS           as ( SELECT BKCC, COST_CENTER_BK, COST_CENTER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_cost_center_master_data__winn_sap') }} as SRC  ),
SRC_CE1NEW4        as ( SELECT BKCC, COST_CENTER_BK, COST_CENTER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_copa_sales__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COST_CENTER_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_AZCOPA         as ( SELECT BKCC, COST_CENTER_BK, COST_CENTER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_copa_sales_history__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COST_CENTER_BK ORDER BY ZEXTRACTDATE ))=1 ),
SRC_ORDER_CONFIRMATION as ( SELECT BKCC, COST_CENTER_BK, COST_CENTER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_order_confirmation__winn_sap') }} as SRC 
                            QUALIFY (ROW_NUMBER() OVER(PARTITION BY COST_CENTER_BK ORDER BY LOAD_DTS ))=1 ),
SRC_ILOA           as ( SELECT BKCC, COST_CENTER_BK, COST_CENTER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_location_assignment__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COST_CENTER_BK ORDER BY LOAD_DTS ))=1 )

/*
SRC_CSKS           as ( SELECT * FROM STAGING.v_psa_stg_cost_center_master_data__winn_sap )
SRC_CE1NEW4        as ( SELECT * FROM STAGING.v_psa_stg_copa_sales__winn_sap )
SRC_AZCOPA         as ( SELECT * FROM STAGING.v_psa_stg_copa_sales_history__winn_sap )
SRC_ORDER_CONFIRMATION as ( SELECT * FROM STAGING.v_psa_stg_order_confirmation__winn_sap )
SRC_ILOA           as ( SELECT * FROM STAGING.v_psa_stg_location_assignment__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_CSKS as (
    SELECT
        COST_CENTER_HK
      , COST_CENTER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_CSKS
)

, LOGIC_CE1NEW4 as (
    SELECT
        COST_CENTER_HK
      , COST_CENTER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_CE1NEW4
)

, LOGIC_AZCOPA as (
    SELECT
        COST_CENTER_HK
      , COST_CENTER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_AZCOPA
)

, LOGIC_ORDER_CONFIRMATION as (
    SELECT
        COST_CENTER_HK
      , COST_CENTER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ORDER_CONFIRMATION
)

, LOGIC_ILOA as (
    SELECT
        COST_CENTER_HK
      , COST_CENTER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ILOA
)
---- RENAME LAYER ----

, RENAME_CSKS as (
    SELECT
        COST_CENTER_HK
      , COST_CENTER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_CSKS
)

, RENAME_CE1NEW4 as (
    SELECT
        COST_CENTER_HK
      , COST_CENTER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_CE1NEW4
)

, RENAME_AZCOPA as (
    SELECT
        COST_CENTER_HK
      , COST_CENTER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_AZCOPA
)

, RENAME_ORDER_CONFIRMATION as (
    SELECT
        COST_CENTER_HK
      , COST_CENTER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ORDER_CONFIRMATION
)

, RENAME_ILOA as (
    SELECT
        COST_CENTER_HK
      , COST_CENTER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ILOA
)
---- FILTER LAYER ----

, FILTER_CSKS as (
    SELECT *
    FROM RENAME_CSKS
)

, FILTER_CE1NEW4 as (
    SELECT *
    FROM RENAME_CE1NEW4
)

, FILTER_AZCOPA as (
    SELECT *
    FROM RENAME_AZCOPA
)

, FILTER_ORDER_CONFIRMATION as (
    SELECT *
    FROM RENAME_ORDER_CONFIRMATION
)

, FILTER_ILOA as (
    SELECT *
    FROM RENAME_ILOA
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_CSKS
    UNION ALL
    SELECT * FROM FILTER_CE1NEW4
    UNION ALL
    SELECT * FROM FILTER_AZCOPA
    UNION ALL
    SELECT * FROM FILTER_ORDER_CONFIRMATION
    UNION ALL
    SELECT * FROM FILTER_ILOA
)

---- FINAL LAYER ----
SELECT
          COST_CENTER_HK
        , COST_CENTER_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.COST_CENTER_HK = JOIN_RESULT.COST_CENTER_HK
)
{% endif %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per BKs and BKCC. */
QUALIFY 1= ROW_NUMBER() OVER (PARTITION BY COST_CENTER_HK ORDER BY LOAD_DTS)
{% if not is_incremental() %}
union all
SELECT 
MD5_BINARY(GR.VALUE) AS COST_CENTER_HK,
GR.VALUE::text AS COST_CENTER_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}