---- SRC LAYER ----
WITH
SRC_R              as ( SELECT RESERVATION_HK, RESERVATION_BK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_reservation_header__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY RESERVATION_HK ORDER BY LOAD_DTS ))=1 ),
SRC_L              as ( SELECT RESERVATION_HK, RESERVATION_BK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_reservation_line__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY RESERVATION_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PROD_ORDER     as ( SELECT RESERVATION_HK, RESERVATION_BK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_production_order_header__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY RESERVATION_BK ORDER BY LOAD_DTS ))=1 )
/*
SRC_R              as ( SELECT * FROM STAGING.V_PSA_STG_RESERVATION_HEADER__WINN_SAP )
SRC_PROD_ORDER     as ( SELECT * FROM STAGING.v_psa_stg_production_order_header__winn_sap )
*/

---- LOGIC LAYER ----

, LOGIC_R as (
    SELECT
        RESERVATION_HK
      , RESERVATION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_R
)

, LOGIC_L as (
    SELECT
        RESERVATION_HK
      , RESERVATION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_L
)

, LOGIC_PROD_ORDER as (
    SELECT
        RESERVATION_HK
      , RESERVATION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PROD_ORDER
)
---- RENAME LAYER ----

, RENAME_R as (
    SELECT
        RESERVATION_HK
      , RESERVATION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_R
)

, RENAME_L as (
    SELECT
        RESERVATION_HK
      , RESERVATION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_L
)

, RENAME_PROD_ORDER as (
    SELECT
        RESERVATION_HK
      , RESERVATION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PROD_ORDER
)
---- FILTER LAYER ----

, FILTER_R as (
    SELECT *
    FROM RENAME_R
)

, FILTER_L as (
    SELECT *
    FROM RENAME_L
)

, FILTER_PROD_ORDER as (
    SELECT *
    FROM RENAME_PROD_ORDER
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_R
    UNION ALL
    SELECT * 
    FROM FILTER_L
    UNION ALL
    SELECT * 
    FROM FILTER_PROD_ORDER
)

---- FINAL LAYER ----
SELECT
          RESERVATION_HK
        , RESERVATION_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.RESERVATION_HK = JOIN_RESULT.RESERVATION_HK
)
{% endif %}
QUALIFY 1= ROW_NUMBER() OVER (PARTITION BY RESERVATION_HK ORDER BY LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS RESERVATION_HK,
GR.VALUE::text AS RESERVATION_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}