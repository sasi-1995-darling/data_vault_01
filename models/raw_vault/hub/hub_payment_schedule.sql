---- SRC LAYER ----
WITH
SRC_SPAYML         as ( SELECT * FROM {{ ref('v_psa_stg_payment_schedule__ml_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PAYMENT_SCHEDULE_HK ORDER BY LOAD_DTS ))=1 ),
SRC_SPAYFB         as ( SELECT * FROM {{ ref('v_psa_stg_payment_schedule__fib_ocf') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PAYMENT_SCHEDULE_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_SPAYML         as ( SELECT * FROM STAGING.v_psa_stg_payment_schedule__ml_ebs )
, SRC_SPAYFB         as ( SELECT * FROM STAGING.v_psa_stg_payment_schedule__fib_ocf )
*/
---- LOGIC LAYER ----

, LOGIC_SPAYML as (
    SELECT
        PAYMENT_SCHEDULE_HK
      , PAYMENT_SCHEDULE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPAYML
)

, LOGIC_SPAYFB as (
    SELECT
        PAYMENT_SCHEDULE_HK
      , PAYMENT_SCHEDULE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPAYFB
)
---- RENAME LAYER ----

, RENAME_SPAYML as (
    SELECT
        PAYMENT_SCHEDULE_HK
      , PAYMENT_SCHEDULE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPAYML
)

, RENAME_SPAYFB as (
    SELECT
        PAYMENT_SCHEDULE_HK
      , PAYMENT_SCHEDULE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPAYFB
)
---- FILTER LAYER ----

, FILTER_SPAYML as (
    SELECT *
    FROM RENAME_SPAYML
)

, FILTER_SPAYFB as (
    SELECT *
    FROM RENAME_SPAYFB
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SPAYML
    UNION ALL
    SELECT * FROM FILTER_SPAYFB
)

---- FINAL LAYER ----
SELECT
          PAYMENT_SCHEDULE_HK
        , PAYMENT_SCHEDULE_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PAYMENT_SCHEDULE_HK = JOIN_RESULT.PAYMENT_SCHEDULE_HK
)
{% endif %}
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PAYMENT_SCHEDULE_HK,
GR.VALUE::text AS PAYMENT_SCHEDULE_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
