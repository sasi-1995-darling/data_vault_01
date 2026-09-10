---- SRC LAYER ----
WITH
SRC_LR             as ( SELECT DEVICE_LOCATION_HK, FLO_USER_HK, LOAD_DTS, REC_SRC, ROLES, USER_LOCATION_HK FROM {{ ref('v_psa_stg_flo_user_location_role') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY USER_LOCATION_HK ORDER BY LOAD_DTS))=1 )

/*
SRC_LR             as ( SELECT * FROM STAGING.v_psa_stg_flo_user_location_role )
*/
---- LOGIC LAYER ----

, LOGIC_LR as (
    SELECT
        USER_LOCATION_HK
      , FLO_USER_HK
      , DEVICE_LOCATION_HK
      , ROLES
      , LOAD_DTS
      , REC_SRC
    FROM SRC_LR
)
---- RENAME LAYER ----

, RENAME_LR as (
    SELECT
        USER_LOCATION_HK
      , FLO_USER_HK
      , DEVICE_LOCATION_HK
      , ROLES
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_LR
)
---- FILTER LAYER ----

, FILTER_LR as (
    SELECT *
    FROM RENAME_LR
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_LR
)

---- FINAL LAYER ----
SELECT
          USER_LOCATION_HK
        , FLO_USER_HK
        , DEVICE_LOCATION_HK
        , ROLES
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.USER_LOCATION_HK = JOIN_RESULT.USER_LOCATION_HK
)
{% endif %}
--this is to consolidate records coming from 2 diff tables with the same bkcc
QUALIFY (ROW_NUMBER() OVER(PARTITION BY USER_LOCATION_HK ORDER BY LOAD_DTS))=1
{% if not is_incremental() %}

union all
SELECT 
 MD5_BINARY(GR.VALUE) AS USER_LOCATION_HK
, MD5_BINARY(GR.VALUE) AS FLO_USER_HK
, MD5_BINARY(GR.VALUE) AS DEVICE_LOCATION_HK
, null as ROLES
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}