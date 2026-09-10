---- SRC LAYER ----
WITH
SRC_SSALLR         as ( SELECT * FROM {{ ref('v_psa_stg_salesman_info__lrsn_psft') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SSALLR         as ( SELECT * FROM STAGING.v_psa_stg_salesman_info__lrsn_psft )
*/
---- LOGIC LAYER ----

, LOGIC_SSALLR as (
    SELECT
        SALES_REP_HK
      , SALES_PERSON
      , REGION_CD
      , L_SPER_NAME
      , L_SMAN_MANAGER
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SSALLR
)
---- RENAME LAYER ----

, RENAME_SSALLR as (
    SELECT
        SALES_REP_HK
      , SALES_PERSON
      , REGION_CD
      , L_SPER_NAME
      , L_SMAN_MANAGER
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SSALLR
)
---- FILTER LAYER ----

, FILTER_SSALLR as (
    SELECT *
    FROM RENAME_SSALLR
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SSALLR
)

---- FINAL LAYER ----
SELECT
          SALES_REP_HK
        , SALES_PERSON
        , REGION_CD
        , L_SPER_NAME
        , L_SMAN_MANAGER
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.SALES_REP_HK = JOIN_RESULT.SALES_REP_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by SALES_REP_HK, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT          MD5_BINARY(GR.VALUE) AS SALES_REP_HK
, GR.VALUE AS SALES_PERSON
    , null as REGION_CD
    , null as L_SPER_NAME
    , null as L_SMAN_MANAGER
, null as _FIVETRAN_DELETED
, null as _FIVETRAN_ID
, null as _FIVETRAN_SYNCED
, null as PSA_DELETE_IND
, null as PSA_LOAD_DTS
, null as PSA_RECORD_SOURCE
    ,  CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP as LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASHDIFF


  FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}