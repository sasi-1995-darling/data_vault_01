---- SRC LAYER ----
WITH
SRC_SLR            as ( SELECT * FROM {{ ref('v_psa_stg_cust_grp_lu__lrsn_psft') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SLR            as ( SELECT * FROM STAGING.v_psa_stg_CUST_GRP_LU__LRSN_PSFT )
*/
---- LOGIC LAYER ----

, LOGIC_SLR as (
    SELECT
        CUST_GRP_BK
      , L_GRP_TYPE
      , L_GRP_CODE
      , SETID
      , DESCR
      , DESCR1
      , DATETIME_ADDED
      , LASTUPDDTTM
      , LAST_MAINT_OPRID
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SLR
)
---- RENAME LAYER ----

, RENAME_SLR as (
    SELECT
        CUST_GRP_BK
      , L_GRP_TYPE
      , L_GRP_CODE
      , SETID
      , DESCR
      , DESCR1
      , DATETIME_ADDED
      , LASTUPDDTTM
      , LAST_MAINT_OPRID
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SLR
)
---- FILTER LAYER ----

, FILTER_SLR as (
    SELECT *
    FROM RENAME_SLR
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SLR
)

---- FINAL LAYER ----
SELECT
          CUST_GRP_BK
        , L_GRP_TYPE
        , L_GRP_CODE
        , SETID
        , DESCR
        , DESCR1
        , DATETIME_ADDED
        , LASTUPDDTTM
        , LAST_MAINT_OPRID
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
    WHERE existing.CUST_GRP_BK = JOIN_RESULT.CUST_GRP_BK
    AND existing.HASH_DIFF = JOIN_RESULT.HASH_DIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by CUST_GRP_BK, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT     GR.VALUE as CUST_GRP_BK
    , null as L_GRP_TYPE
    , null as L_GRP_CODE
    , null as SETID
    , null as DESCR
    , null as DESCR1
    , null as DATETIME_ADDED
    , null as LASTUPDDTTM
    , null as LAST_MAINT_OPRID
    , null as _FIVETRAN_DELETED
    , null as _FIVETRAN_ID
    , null as _FIVETRAN_SYNCED
    , null as PSA_DELETE_IND
    , null as PSA_LOAD_DTS
, null as PSA_RECORD_SOURCE, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP  as  LOAD_DTS
	,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
	,''::BINARY as HASH_DIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}