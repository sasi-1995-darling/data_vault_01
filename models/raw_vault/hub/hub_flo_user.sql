---- SRC LAYER ----
WITH
SRC_FU             as ( SELECT BKCC, FLO_USER_BK, FLO_USER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_flo_user') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY FLO_USER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_UAR            as ( SELECT BKCC, FLO_USER_BK, FLO_USER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_flo_user_account_role') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY FLO_USER_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_FU             as ( SELECT * FROM STAGING.v_psa_stg_flo_user )
SRC_UAR            as ( SELECT * FROM STAGING.v_psa_stg_flo_user_account_role )
*/
---- LOGIC LAYER ----

, LOGIC_FU as (
    SELECT
        FLO_USER_HK
      , FLO_USER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_FU
)

, LOGIC_UAR as (
    SELECT
        FLO_USER_HK
      , FLO_USER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_UAR
)
---- RENAME LAYER ----

, RENAME_FU as (
    SELECT
        FLO_USER_HK
      , FLO_USER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_FU
)

, RENAME_UAR as (
    SELECT
        FLO_USER_HK
      , FLO_USER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_UAR
)
---- FILTER LAYER ----

, FILTER_FU as (
    SELECT *
    FROM RENAME_FU
)

, FILTER_UAR as (
    SELECT *
    FROM RENAME_UAR
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_FU
    UNION
    SELECT * FROM FILTER_UAR
)

---- FINAL LAYER ----
SELECT
          FLO_USER_HK
        , FLO_USER_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.FLO_USER_HK = JOIN_RESULT.FLO_USER_HK
)
qualify 1= row_number() over(partition by FLO_USER_HK order by LOAD_DTS)
{% endif %}
{% if not is_incremental() %}
qualify 1= row_number() over(partition by FLO_USER_HK order by LOAD_DTS) 
union all


SELECT MD5_BINARY(GR.VALUE)  FLO_USER_HK
, GR.VALUE  AS FLO_USER_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}