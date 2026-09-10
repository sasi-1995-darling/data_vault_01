---- SRC LAYER ----
WITH
SRC_TVV2T          as ( SELECT BKCC, KEY_ACCOUNT_GROUP_BK, KEY_ACCOUNT_GROUP_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_key_account_group__winn_sap') }} as SRC  ),
SRC_PROMOXREF      as ( SELECT KEY_ACCOUNT_GROUP_HK, LOAD_DTS, REC_SRC, RETAILER_BKCC, RETAILER_KEY_ACCOUNT_GROUP_BK FROM {{ ref('v_psa_stg_retailer_key_account_group_xref__promo_rgm') }} as SRC  ),
SRC_WINNPROMO      as ( SELECT ERP_BKCC, KEY_ACCOUNT_GROUP_BK, KEY_ACCOUNT_GROUP_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_consolidated_promo_flow_input__winn_rgm') }} as SRC  )

/*
SRC_TVV2T          as ( SELECT * FROM STAGING.v_psa_stg_key_account_group__winn_sap )
SRC_PROMOXREF      as ( SELECT * FROM STAGING.v_psa_stg_retailer_key_account_group_xref__promo_rgm )
SRC_WINNPROMO      as ( SELECT * FROM STAGING.v_psa_stg_consolidated_promo_flow_input__winn_rgm )
*/
---- LOGIC LAYER ----

, LOGIC_TVV2T as (
    SELECT
        KEY_ACCOUNT_GROUP_HK
      , KEY_ACCOUNT_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_TVV2T
)

, LOGIC_PROMOXREF as (
    SELECT
        KEY_ACCOUNT_GROUP_HK
      , RETAILER_KEY_ACCOUNT_GROUP_BK                                as                               KEY_ACCOUNT_GROUP_BK
      , RETAILER_BKCC                                                as                                               BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PROMOXREF
)

, LOGIC_WINNPROMO as (
    SELECT
        KEY_ACCOUNT_GROUP_HK
      , KEY_ACCOUNT_GROUP_BK
      , ERP_BKCC                                                     as                                               BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_WINNPROMO
)
---- RENAME LAYER ----

, RENAME_TVV2T as (
    SELECT
        KEY_ACCOUNT_GROUP_HK
      , KEY_ACCOUNT_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_TVV2T
)

, RENAME_PROMOXREF as (
    SELECT
        KEY_ACCOUNT_GROUP_HK
      , KEY_ACCOUNT_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PROMOXREF
)

, RENAME_WINNPROMO as (
    SELECT
        KEY_ACCOUNT_GROUP_HK
      , KEY_ACCOUNT_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_WINNPROMO
)
---- FILTER LAYER ----

, FILTER_TVV2T as (
    SELECT *
    FROM RENAME_TVV2T
)

, FILTER_PROMOXREF as (
    SELECT *
    FROM RENAME_PROMOXREF
)

, FILTER_WINNPROMO as (
    SELECT *
    FROM RENAME_WINNPROMO
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_TVV2T
    UNION ALL
    SELECT * FROM FILTER_PROMOXREF
    UNION ALL
    SELECT * FROM FILTER_WINNPROMO
)

---- FINAL LAYER ----
SELECT
          KEY_ACCOUNT_GROUP_HK
        , KEY_ACCOUNT_GROUP_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.KEY_ACCOUNT_GROUP_HK = JOIN_RESULT.KEY_ACCOUNT_GROUP_HK
)
{% endif %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per BKs and BKCC. */
qualify 1 = row_number() over (partition by KEY_ACCOUNT_GROUP_BK, BKCC order by LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS KEY_ACCOUNT_GROUP_HK,
GR.VALUE::text AS KEY_ACCOUNT_GROUP_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
