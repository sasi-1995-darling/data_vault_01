---- SRC LAYER ----
WITH
SRC_s              as ( SELECT KEY_ACCOUNT_HK, KEY_ACCOUNT_BK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_key_account__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY KEY_ACCOUNT_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_s              as ( SELECT * FROM STAGING.V_PSA_STG_KEY_ACCOUNT__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        KEY_ACCOUNT_HK
      , KEY_ACCOUNT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_s
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        KEY_ACCOUNT_HK
      , KEY_ACCOUNT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_s
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
)

---- FINAL LAYER ----
SELECT
          KEY_ACCOUNT_HK
        , KEY_ACCOUNT_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.KEY_ACCOUNT_HK = JOIN_RESULT.KEY_ACCOUNT_HK
)
{% endif %}
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS KEY_ACCOUNT_HK,
GR.VALUE::text AS KEY_ACCOUNT_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
