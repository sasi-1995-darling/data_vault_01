---- SRC LAYER ----
WITH
SRC_sml            as ( SELECT * FROM {{ ref('v_psa_stg_customer_site__ml_ebs') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER (PARTITION BY CUSTOMER_SITE_HK ORDER BY LOAD_DTS DESC) = 1 )

/*
SRC_sml            as ( SELECT * FROM STAGING.v_psa_stg_cust_site__ml_ebs )
*/
---- LOGIC LAYER ----

, LOGIC_sml as (
    SELECT
        CUSTOMER_SITE_HK
      , CUSTOMER_SITE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_sml
)
---- RENAME LAYER ----

, RENAME_sml as (
    SELECT
        CUSTOMER_SITE_HK
      , CUSTOMER_SITE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_sml
)
---- FILTER LAYER ----

, FILTER_sml as (
    SELECT *
    FROM RENAME_sml
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_sml
)

---- FINAL LAYER ----
SELECT
          CUSTOMER_SITE_HK
        , CUSTOMER_SITE_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.CUSTOMER_SITE_HK = JOIN_RESULT.CUSTOMER_SITE_HK
)
{% endif %}
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS CUSTOMER_SITE_HK,
GR.VALUE::text AS CUSTOMER_SITE_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
