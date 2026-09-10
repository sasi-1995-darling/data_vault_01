---- SRC LAYER ----
WITH
SRC_HYD            as ( SELECT BKCC, LOAD_DTS, REC_SRC, SMART_DEVICE_BK, SMART_DEVICE_HK FROM {{ ref('v_psa_stg_smart_device_hyd_shadow') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SMART_DEVICE_HK ORDER BY LOAD_DTS ))=1 ),
SRC_NAB            as ( SELECT BKCC, LOAD_DTS, REC_SRC, SMART_DEVICE_BK, SMART_DEVICE_HK FROM {{ ref('v_psa_stg_smart_device_nab_shadow') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SMART_DEVICE_HK ORDER BY LOAD_DTS ))=1 ),
SRC_VAK            as ( SELECT BKCC, LOAD_DTS, REC_SRC, SMART_DEVICE_BK, SMART_DEVICE_HK FROM {{ ref('v_psa_stg_smart_device_vak_shadow') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SMART_DEVICE_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_HYD            as ( SELECT * FROM STAGING.v_psa_stg_smart_device_hyd_shadow )
SRC_NAB            as ( SELECT * FROM STAGING.v_psa_stg_smart_device_nab_shadow )
SRC_VAK            as ( SELECT * FROM STAGING.v_psa_stg_smart_device_vak_shadow )
*/
---- LOGIC LAYER ----

, LOGIC_HYD as (
    SELECT
        SMART_DEVICE_HK
      , SMART_DEVICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_HYD
)

, LOGIC_NAB as (
    SELECT
        SMART_DEVICE_HK
      , SMART_DEVICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_NAB
)

, LOGIC_VAK as (
    SELECT
        SMART_DEVICE_HK
      , SMART_DEVICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_VAK
)
---- RENAME LAYER ----

, RENAME_HYD as (
    SELECT
        SMART_DEVICE_HK
      , SMART_DEVICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_HYD
)

, RENAME_NAB as (
    SELECT
        SMART_DEVICE_HK
      , SMART_DEVICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_NAB
)

, RENAME_VAK as (
    SELECT
        SMART_DEVICE_HK
      , SMART_DEVICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_VAK
)
---- FILTER LAYER ----

, FILTER_HYD as (
    SELECT *
    FROM RENAME_HYD
)

, FILTER_NAB as (
    SELECT *
    FROM RENAME_NAB
)

, FILTER_VAK as (
    SELECT *
    FROM RENAME_VAK
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_HYD
    UNION all
    SELECT * FROM FILTER_NAB
    UNION all
    SELECT * FROM FILTER_VAK
)

---- FINAL LAYER ----
SELECT
          SMART_DEVICE_HK
        , SMART_DEVICE_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.SMART_DEVICE_HK = JOIN_RESULT.SMART_DEVICE_HK
)
{% endif %}
qualify 1= row_number() over(partition by SMART_DEVICE_HK order by LOAD_DTS) 
{% if not is_incremental() %}

union all

SELECT MD5_BINARY(GR.VALUE)  as SMART_DEVICE_HK
, GR.VALUE  AS SMART_DEVICE_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}