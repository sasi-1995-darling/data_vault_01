---- SRC LAYER ----
WITH
SRC_FF             as ( SELECT DEVICE_HK, ICD_DEVICE_HK, LOAD_DTS, PAIRED_DEVICE_HK, REC_SRC FROM {{ ref('v_psa_stg_flo_device_icd') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ICD_DEVICE_HK ORDER BY LOAD_DTS))=1 )

/*
SRC_FF             as ( SELECT * FROM STAGING.v_psa_stg_flo_device_icd )
*/
---- LOGIC LAYER ----

, LOGIC_FF as (
    SELECT
        ICD_DEVICE_HK
      , PAIRED_DEVICE_HK
      , DEVICE_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_FF
)
---- RENAME LAYER ----

, RENAME_FF as (
    SELECT
        ICD_DEVICE_HK
      , PAIRED_DEVICE_HK
      , DEVICE_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_FF
)
---- FILTER LAYER ----

, FILTER_FF as (
    SELECT *
    FROM RENAME_FF
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_FF
)

---- FINAL LAYER ----
SELECT
          ICD_DEVICE_HK
        , PAIRED_DEVICE_HK
        , DEVICE_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ICD_DEVICE_HK = JOIN_RESULT.ICD_DEVICE_HK
)
{% endif %}
--this is to consolidate records coming from 2 diff tables with the same bkcc
QUALIFY (ROW_NUMBER() OVER(PARTITION BY ICD_DEVICE_HK ORDER BY LOAD_DTS))=1
{% if not is_incremental() %}

union all
SELECT 
 MD5_BINARY(GR.VALUE) AS ICD_DEVICE_HK
, MD5_BINARY(GR.VALUE) AS DEVICE_HK
, MD5_BINARY(GR.VALUE) AS PAIRED_DEVICE_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}