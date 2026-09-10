---- SRC LAYER ----
WITH
SRC_AR             as ( SELECT DEVICE_ACCOUNT_HK, FLO_USER_HK, LOAD_DTS, REC_SRC, ROLES, USER_ACCOUNT_HK FROM {{ ref('v_psa_stg_flo_user_account_role') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY USER_ACCOUNT_HK ORDER BY LOAD_DTS))=1 )

/*
SRC_AR             as ( SELECT * FROM STAGING.v_psa_stg_flo_user_account_role )
*/
---- LOGIC LAYER ----

, LOGIC_AR as (
    SELECT
        USER_ACCOUNT_HK
      , FLO_USER_HK
      , DEVICE_ACCOUNT_HK
      , ROLES
      , LOAD_DTS
      , REC_SRC
    FROM SRC_AR
)
---- RENAME LAYER ----

, RENAME_AR as (
    SELECT
        USER_ACCOUNT_HK
      , FLO_USER_HK
      , DEVICE_ACCOUNT_HK
      , ROLES
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_AR
)
---- FILTER LAYER ----

, FILTER_AR as (
    SELECT *
    FROM RENAME_AR
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_AR
)

---- FINAL LAYER ----
SELECT
          USER_ACCOUNT_HK
        , FLO_USER_HK
        , DEVICE_ACCOUNT_HK
        , ROLES
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.USER_ACCOUNT_HK = JOIN_RESULT.USER_ACCOUNT_HK
)
{% endif %}
--this is to consolidate records coming from 2 diff tables with the same bkcc
QUALIFY (ROW_NUMBER() OVER(PARTITION BY USER_ACCOUNT_HK ORDER BY LOAD_DTS))=1
{% if not is_incremental() %}

union all
SELECT 
 MD5_BINARY(GR.VALUE) AS USER_ACCOUNT_HK
, MD5_BINARY(GR.VALUE) AS FLO_USER_HK
, MD5_BINARY(GR.VALUE) AS DEVICE_ACCOUNT_HK
, null as ROLES
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}