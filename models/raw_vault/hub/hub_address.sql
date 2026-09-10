---- SRC LAYER ----
WITH
SRC_s              as ( SELECT ADDRESS_BK, ADDRESS_HK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_address__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ADDRESS_BK ORDER BY LOAD_DTS ))=1 ),
SRC_WORK_LOCATION  as ( SELECT ADDRESS_BK, ADDRESS_HK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_work_center_location__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ADDRESS_BK ORDER BY LOAD_DTS ))=1 )

/*
SRC_s              as ( SELECT * FROM STAGING.V_PSA_STG_ADDRESS__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        ADDRESS_HK
      , ADDRESS_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_s
)

, LOGIC_WORK_LOCATION as (
    SELECT
        ADDRESS_HK
      , ADDRESS_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_WORK_LOCATION
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        ADDRESS_HK
      , ADDRESS_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_s
)

, RENAME_WORK_LOCATION as (
    SELECT
        ADDRESS_HK
      , ADDRESS_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_WORK_LOCATION
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

, FILTER_WORK_LOCATION as (
    SELECT *
    FROM RENAME_WORK_LOCATION
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
    UNION ALL
    SELECT *
    FROM FILTER_WORK_LOCATION
)

---- FINAL LAYER ----
SELECT
          ADDRESS_HK
        , ADDRESS_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ADDRESS_HK = JOIN_RESULT.ADDRESS_HK
)
{% endif %}
QUALIFY 1= ROW_NUMBER() OVER (PARTITION BY ADDRESS_HK ORDER BY LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS ADDRESS_HK,
GR.VALUE::text AS ADDRESS_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
