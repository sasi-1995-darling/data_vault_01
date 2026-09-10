---- SRC LAYER ----
WITH
SRC_R              as ( SELECT BKCC, LOAD_DTS, REC_SRC, STORAGE_TYPE_BK, STORAGE_TYPE_HK FROM {{ ref('v_psa_stg_reservation_line__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY STORAGE_TYPE_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_R              as ( SELECT * FROM STAGING.V_PSA_STG_RESERVATION_LINE__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_R as (
    SELECT
        STORAGE_TYPE_HK
      , STORAGE_TYPE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_R
)
---- RENAME LAYER ----

, RENAME_R as (
    SELECT
        STORAGE_TYPE_HK
      , STORAGE_TYPE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_R
)
---- FILTER LAYER ----

, FILTER_R as (
    SELECT *
    FROM RENAME_R
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_R
)

---- FINAL LAYER ----
SELECT
          STORAGE_TYPE_HK
        , STORAGE_TYPE_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.STORAGE_TYPE_HK = JOIN_RESULT.STORAGE_TYPE_HK
)
{% endif %}
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS STORAGE_TYPE_HK,
GR.VALUE::text AS STORAGE_TYPE_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
