---- SRC LAYER ----
WITH
SRC_IP     as ( SELECT * FROM {{ ref('v_psa_stg_cost_total_for_internal_postings__winn_sap') }} as SRC ),
SRC_EP     as ( SELECT * FROM {{ ref('v_psa_stg_cost_totals_for_external_postings__winn_sap') }} as SRC ),
SRC_CO     as ( SELECT * FROM {{ ref('v_psa_stg_origin_co_object__winn_sap') }} as SRC )

/*
SRC_IP        as ( SELECT * FROM STAGING.v_psa_stg_cost_total_for_internal_postings__winn_sap )
SRC_EP        as ( SELECT * FROM STAGING.v_psa_stg_cost_totals_for_external_postings__winn_sap )
SRC_CO       as ( SELECT * FROM STAGING.v_psa_stg_origin_co_object__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_IP as (
    SELECT
        ORIGIN_GROUP_HK
      , ORIGIN_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_IP
)

, LOGIC_EP as (
    SELECT
        ORIGIN_GROUP_HK
      , ORIGIN_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_EP
)
, LOGIC_CO as (
    SELECT
        ORIGIN_GROUP_HK
      , ORIGIN_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_CO
)
---- RENAME LAYER ----

, RENAME_IP as (
    SELECT
        ORIGIN_GROUP_HK
      , ORIGIN_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_IP
)
, RENAME_EP as (
    SELECT
        ORIGIN_GROUP_HK
      , ORIGIN_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_EP
)
, RENAME_CO as (
    SELECT
        ORIGIN_GROUP_HK
      , ORIGIN_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_CO
)
---- FILTER LAYER ----

, FILTER_IP as (
    SELECT *
    FROM RENAME_IP
)
, FILTER_EP as (
    SELECT *
    FROM RENAME_EP
)
, FILTER_CO as (
    SELECT *
    FROM RENAME_CO
    )
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_IP
    UNION ALL
    SELECT * FROM FILTER_EP
    UNION ALL
    SELECT * FROM FILTER_CO
)

---- FINAL LAYER ----
SELECT
        ORIGIN_GROUP_HK
      , ORIGIN_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ORIGIN_GROUP_HK = JOIN_RESULT.ORIGIN_GROUP_HK
)
{% endif %}
QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ORIGIN_GROUP_HK ORDER BY LOAD_DTS)
{% if not is_incremental() %} union all

SELECT MD5_BINARY(GR.VALUE)  ORIGIN_GROUP_HK
, GR.VALUE  AS ORIGIN_GROUP_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01')  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}