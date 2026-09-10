---- SRC LAYER ----
WITH
SRC_eina           as ( SELECT * FROM {{ ref('v_psa_stg_purchasing_records__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PURCHASING_RECORD_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_eina           as ( SELECT * FROM staging.v_psa_stg_purchasing_records__winn )
*/
---- LOGIC LAYER ----

, LOGIC_eina as (
    SELECT
        PURCHASING_RECORD_HK
      , PURCHASING_RECORD_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_eina
)
---- RENAME LAYER ----

, RENAME_eina as (
    SELECT
        PURCHASING_RECORD_HK
      , PURCHASING_RECORD_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_eina
)
---- FILTER LAYER ----

, FILTER_eina as (
    SELECT *
    FROM RENAME_eina
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_eina
)

---- FINAL LAYER ----
SELECT
          PURCHASING_RECORD_HK
        , PURCHASING_RECORD_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PURCHASING_RECORD_HK = JOIN_RESULT.PURCHASING_RECORD_HK 
)
{% endif %} 
{% if not is_incremental() %}

union all
SELECT
         MD5_BINARY(GR.VALUE) AS PURCHASING_RECORD_HK
, GR.VALUE AS PURCHASING_INFO_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, '1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

    {% endif %}