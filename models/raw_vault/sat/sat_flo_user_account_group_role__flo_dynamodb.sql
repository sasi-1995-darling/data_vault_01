---- SRC LAYER ----
WITH
SRC_FU             as ( SELECT * FROM {{ ref('v_psa_stg_flo_user_account_group_role') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_FU             as ( SELECT * FROM staging.v_psa_stg_flo_user_account_group_role )
*/
---- LOGIC LAYER ----

, LOGIC_FU as (
    SELECT
        FLO_USER_HK
      , LOAD_DTS
      , GROUP_ID
      , USER_ID
      , _FIVETRAN_SYNCED
      , ROLES
      , _FIVETRAN_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_FU
)
---- RENAME LAYER ----

, RENAME_FU as (
    SELECT
        FLO_USER_HK
      , LOAD_DTS
      , GROUP_ID
      , USER_ID
      , _FIVETRAN_SYNCED
      , ROLES
      , _FIVETRAN_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_FU
)
---- FILTER LAYER ----

, FILTER_FU as (
    SELECT *
    FROM RENAME_FU
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_FU
)

---- FINAL LAYER ----
SELECT
          FLO_USER_HK
        , LOAD_DTS
        , GROUP_ID
        , USER_ID
        , _FIVETRAN_SYNCED
        , ROLES
        , _FIVETRAN_DELETED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.FLO_USER_HK = JOIN_RESULT.FLO_USER_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 

{% if not is_incremental() %}
qualify 1= row_number()over(partition by FLO_USER_HK, HASHDIFF order by LOAD_DTS) 
union all
SELECT
MD5_BINARY(GR.VALUE) AS FLO_USER_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, GR.VALUE::TEXT  as USER_ID
, GR.VALUE::TEXT  as GROUP_ID
, null  as _FIVETRAN_SYNCED
,null as ROLES
,null as _FIVETRAN_DELETED
,null as PSA_LOAD_DTS
,null as PSA_RECORD_SOURCE
,null as PSA_DELETE_IND
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASH_DIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}