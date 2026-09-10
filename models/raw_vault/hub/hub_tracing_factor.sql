---- SRC LAYER ----
WITH
SRC_c           as ( SELECT * FROM {{ ref('v_psa_stg_statistical_key_figure_totals__winn_sap') }} as SRC
                       QUALIFY (ROW_NUMBER() OVER(PARTITION BY TRACKING_FACTOR_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_c           as ( SELECT * FROM staging.V_PSA_STG_CONTROLLING_LEDGER_ENTRY__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_c as (
    SELECT
        TRACKING_FACTOR_HK
      , TRACKING_FACTOR_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_c
)
---- RENAME LAYER ----

, RENAME_c as (
    SELECT
        TRACKING_FACTOR_HK
      , TRACKING_FACTOR_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_c
)
---- FILTER LAYER ----

, FILTER_c as (
    SELECT *
    FROM RENAME_c
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_c
)

---- FINAL LAYER ----
SELECT
          TRACKING_FACTOR_HK
        , TRACKING_FACTOR_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.TRACKING_FACTOR_HK = JOIN_RESULT.TRACKING_FACTOR_HK
)
{% endif %}

{% if not is_incremental() %}
 union all
 SELECT
   MD5_BINARY(GR.VALUE) AS TRACKING_FACTOR_HK
 , GR.VALUE AS TRACKING_FACTOR_BK
 , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
 , CONVERT_TIMEZONE('UTC','1900-01-01') AS LOAD_DTS
 , 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
 FROM
 TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
 {% endif %}