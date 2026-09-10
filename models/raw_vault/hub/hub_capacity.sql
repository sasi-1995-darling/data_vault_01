
---- SRC LAYER ----
WITH
SRC_s              as ( SELECT CAPACITY_HK, CAPACITY_BK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_capacity_header__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CAPACITY_BK ORDER BY LOAD_DTS ))=1 ),

SRC_d              as ( SELECT CAPACITY_HK, CAPACITY_BK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_capacity_description__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CAPACITY_BK ORDER BY LOAD_DTS ))=1 ),

SRC_a              as ( SELECT CAPACITY_HK, CAPACITY_BK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_capacity_availability_interval__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CAPACITY_BK ORDER BY LOAD_DTS ))=1 ),

SRC_capacity       as ( SELECT CAPACITY_HK, CAPACITY_BK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_work_center_capacity_allocation__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CAPACITY_BK ORDER BY LOAD_DTS ))=1 ),

SRC_order_confirmation as ( SELECT CAPACITY_HK, CAPACITY_BK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_order_confirmation__winn_sap') }} as SRC 
                            QUALIFY (ROW_NUMBER() OVER(PARTITION BY CAPACITY_BK ORDER BY LOAD_DTS ))=1 )

/*
SRC_s              as ( SELECT * FROM STAGING.v_psa_stg_capacity_header__winn_sap )
SRC_d              as ( SELECT * FROM STAGING.v_psa_stg_capacity_description__winn_sap )
SRC_a              as ( SELECT * FROM STAGING.v_psa_stg_capacity_availability_interval__winn_sap )
SRC_capacity       as ( SELECT * FROM STAGING.v_psa_stg_work_center_capacity_allocation__winn_sap )
SRC_order_confirmation as ( SELECT * FROM STAGING.v_psa_stg_order_confirmation__winn_sap )
*/

---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        CAPACITY_HK
      , CAPACITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_s
)

, LOGIC_d as (
    SELECT
        CAPACITY_HK
      , CAPACITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_d
)

, LOGIC_a as (
    SELECT
        CAPACITY_HK
      , CAPACITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_a
)

, LOGIC_capacity as (
    SELECT
        CAPACITY_HK
      , CAPACITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_capacity
)

, LOGIC_order_confirmation as (
    SELECT
        CAPACITY_HK
      , CAPACITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_order_confirmation
)

---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        CAPACITY_HK
      , CAPACITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_s
)

, RENAME_d as (
    SELECT
        CAPACITY_HK
      , CAPACITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_d
)

, RENAME_a as (
    SELECT
        CAPACITY_HK
      , CAPACITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_a
)

, RENAME_capacity as (
    SELECT
        CAPACITY_HK
      , CAPACITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_capacity
)

, RENAME_order_confirmation as (
    SELECT
        CAPACITY_HK
      , CAPACITY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_order_confirmation
)

---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

, FILTER_d as (
    SELECT *
    FROM RENAME_d
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_capacity as (
    SELECT *
    FROM RENAME_capacity
)

, FILTER_order_confirmation as (
    SELECT *
    FROM RENAME_order_confirmation
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
    UNION ALL
    SELECT *
    FROM FILTER_d
    UNION ALL
    SELECT *
    FROM FILTER_a
    UNION ALL
    SELECT *
    FROM FILTER_capacity
    UNION ALL
    SELECT *
    FROM FILTER_order_confirmation
)

---- FINAL LAYER ----
SELECT
          CAPACITY_HK
        , CAPACITY_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.CAPACITY_HK = JOIN_RESULT.CAPACITY_HK
)
{% endif %}
QUALIFY 1= ROW_NUMBER() OVER (PARTITION BY CAPACITY_HK ORDER BY LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS CAPACITY_HK,
GR.VALUE::text AS CAPACITY_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}