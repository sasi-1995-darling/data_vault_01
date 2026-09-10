---- SRC LAYER ----
WITH
SRC_FD             as ( SELECT BKCC, LOAD_DTS, PAIRED_DEVICE_BK, PAIRED_DEVICE_HK, REC_SRC FROM {{ ref('v_psa_stg_flo_device_icd') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PAIRED_DEVICE_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_FD             as ( SELECT * FROM STAGING.v_psa_stg_flo_device_icd )
*/
---- LOGIC LAYER ----

, LOGIC_FD as (
    SELECT
        PAIRED_DEVICE_HK
      , PAIRED_DEVICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_FD
)
---- RENAME LAYER ----

, RENAME_FD as (
    SELECT
        PAIRED_DEVICE_HK
      , PAIRED_DEVICE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_FD
)
---- FILTER LAYER ----

, FILTER_FD as (
    SELECT *
    FROM RENAME_FD
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_FD
)

---- FINAL LAYER ----
SELECT
          PAIRED_DEVICE_HK
        , PAIRED_DEVICE_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PAIRED_DEVICE_HK = JOIN_RESULT.PAIRED_DEVICE_HK
)
{% endif %}
{% if not is_incremental() %}

union all

SELECT MD5_BINARY(GR.VALUE)  PAIRED_DEVICE_HK
, GR.VALUE  AS PAIRED_DEVICE_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}