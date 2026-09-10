---- SRC LAYER ----
WITH
SRC_DA             as ( SELECT BKCC, DEVICE_ACCOUNT_BK, DEVICE_ACCOUNT_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_flo_device_account') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DEVICE_ACCOUNT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_UAR            as ( SELECT BKCC, DEVICE_ACCOUNT_BK, DEVICE_ACCOUNT_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_flo_user_account_role') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DEVICE_ACCOUNT_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_DA             as ( SELECT * FROM STAGING.v_psa_stg_flo_device_account )
SRC_UAR            as ( SELECT * FROM STAGING.v_psa_stg_flo_user_account_role )
*/
---- LOGIC LAYER ----

, LOGIC_DA as (
    SELECT
        DEVICE_ACCOUNT_HK
      , DEVICE_ACCOUNT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_DA
)

, LOGIC_UAR as (
    SELECT
        DEVICE_ACCOUNT_HK
      , DEVICE_ACCOUNT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_UAR
)
---- RENAME LAYER ----

, RENAME_DA as (
    SELECT
        DEVICE_ACCOUNT_HK
      , DEVICE_ACCOUNT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_DA
)

, RENAME_UAR as (
    SELECT
        DEVICE_ACCOUNT_HK
      , DEVICE_ACCOUNT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_UAR
)
---- FILTER LAYER ----

, FILTER_DA as (
    SELECT *
    FROM RENAME_DA
)

, FILTER_UAR as (
    SELECT *
    FROM RENAME_UAR
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_DA
    UNION ALL
    SELECT * FROM FILTER_UAR
)

---- FINAL LAYER ----
SELECT
          DEVICE_ACCOUNT_HK
        , DEVICE_ACCOUNT_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.DEVICE_ACCOUNT_HK = JOIN_RESULT.DEVICE_ACCOUNT_HK
)
qualify 1= row_number()over(partition by DEVICE_ACCOUNT_HK order by LOAD_DTS) 
{% endif %}
{% if not is_incremental() %}
qualify 1= row_number()over(partition by DEVICE_ACCOUNT_HK order by LOAD_DTS) 
union all


SELECT MD5_BINARY(GR.VALUE)  DEVICE_ACCOUNT_HK
, GR.VALUE  AS DEVICE_ACCOUNT_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}