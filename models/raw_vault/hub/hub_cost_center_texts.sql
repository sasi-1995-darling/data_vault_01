---- SRC LAYER ----
WITH
SRC_c              as ( SELECT * FROM {{ ref('v_psa_stg_cost_center_texts__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COST_CENTER_TEXTS_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_c              as ( SELECT * FROM staging.V_PSA_STG_COST_CENTER_TEXTS__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_c as (
    SELECT
        COST_CENTER_TEXTS_HK
      , LANGUAGE_KEY_BK
      , CONTROLLING_AREA_BK
      , COST_CENTER_BK
      , VALID_TO_DATE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_c
)
---- RENAME LAYER ----

, RENAME_c as (
    SELECT
        COST_CENTER_TEXTS_HK
      , LANGUAGE_KEY_BK
      , CONTROLLING_AREA_BK
      , COST_CENTER_BK
      , VALID_TO_DATE_BK
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
          COST_CENTER_TEXTS_HK
        , LANGUAGE_KEY_BK
        , CONTROLLING_AREA_BK
        , COST_CENTER_BK
        , VALID_TO_DATE_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.COST_CENTER_TEXTS_HK= JOIN_RESULT.COST_CENTER_TEXTS_HK
)
{% endif %}

{% if not is_incremental() %}
 union all
 SELECT MD5_BINARY(GR.VALUE) COST_CENTER_TEXTS_HK
 , GR.VALUE AS LANGUAGE_KEY_BK
 , GR.VALUE AS CONTROLLING_AREA_BK
 , GR.VALUE AS COST_CENTER_BK
 , GR.VALUE AS VALID_TO_DATE_BK
 , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
 , CONVERT_TIMEZONE('UTC','1900-01-01') AS LOAD_DTS
 , 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
 FROM
 TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
 {% endif %}