---- SRC LAYER ----
WITH
SRC_FD             as ( SELECT BKCC, DEVICE_BK, DEVICE_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_flo_devices') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DEVICE_HK ORDER BY LOAD_DTS ))=1 ),
SRC_DT             as ( SELECT BKCC, DEVICE_BK, DEVICE_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_device_telemetry_flo_daily') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DEVICE_HK ORDER BY LOAD_DTS ))=1 ),
SRC_DI             as ( SELECT BKCC, DEVICE_BK, DEVICE_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_device_inventory') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DEVICE_HK ORDER BY LOAD_DTS ))=1 ),
SRC_FE             as ( SELECT BKCC, DEVICE_BK, DEVICE_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_flow_event_daily') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DEVICE_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_FD             as ( SELECT * FROM STAGING.v_psa_stg_flo_devices )
SRC_DT             as ( SELECT * FROM STAGING.v_psa_stg_device_telemetry_flo_daily )
SRC_DI             as ( SELECT * FROM STAGING.v_psa_stg_device_inventory )
SRC_FE             as ( SELECT * FROM STAGING.v_psa_stg_flow_event_daily )
*/
---- LOGIC LAYER ----

, LOGIC_FD as (
    SELECT
        DEVICE_HK
      , DEVICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_FD
)

, LOGIC_DT as (
    SELECT
        DEVICE_HK
      , DEVICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_DT
)

, LOGIC_DI as (
    SELECT
        DEVICE_HK
      , DEVICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_DI
)

, LOGIC_FE as (
    SELECT
        DEVICE_HK
      , DEVICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_FE
)
---- RENAME LAYER ----

, RENAME_FD as (
    SELECT
        DEVICE_HK
      , DEVICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_FD
)

, RENAME_DT as (
    SELECT
        DEVICE_HK
      , DEVICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_DT
)

, RENAME_DI as (
    SELECT
        DEVICE_HK
      , DEVICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_DI
)

, RENAME_FE as (
    SELECT
        DEVICE_HK
      , DEVICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_FE
)
---- FILTER LAYER ----

, FILTER_FD as (
    SELECT *
    FROM RENAME_FD
)

, FILTER_DT as (
    SELECT *
    FROM RENAME_DT
)

, FILTER_DI as (
    SELECT *
    FROM RENAME_DI
)

, FILTER_FE as (
    SELECT *
    FROM RENAME_FE
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_FD
    UNION ALL
    SELECT * FROM FILTER_DT
    UNION ALL
    SELECT * FROM FILTER_DI
    UNION ALL
    SELECT * FROM FILTER_FE
)

---- FINAL LAYER ----
SELECT
          DEVICE_HK
        , DEVICE_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.DEVICE_HK = JOIN_RESULT.DEVICE_HK
)
{% endif %}
QUALIFY (ROW_NUMBER() OVER(PARTITION BY DEVICE_HK ORDER BY LOAD_DTS ))=1
{% if not is_incremental() %}

union all

SELECT MD5_BINARY(GR.VALUE)  DEVICE_HK
, GR.VALUE  AS DEVICE_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}