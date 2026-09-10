---- SRC LAYER ----
WITH
SRC_SCUSTGLR       as ( SELECT * FROM {{ ref('v_psa_stg_cust_cgrp__lrsn_psft') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SCUSTGLR       as ( SELECT * FROM STAGING.v_psa_stg_cust_cgrp__lrsn_psft )
*/
---- LOGIC LAYER ----

, LOGIC_SCUSTGLR as (
    SELECT
        CUSTOMER_HK
      , SETID
      , CUST_ID
      , CUST_GRP_TYPE
      , CUSTOMER_GROUP
      , DEFAULT_TAX_GRP
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
    FROM SRC_SCUSTGLR
)
---- RENAME LAYER ----

, RENAME_SCUSTGLR as (
    SELECT
        CUSTOMER_HK
      , SETID
      , CUST_ID
      , CUST_GRP_TYPE
      , CUSTOMER_GROUP
      , DEFAULT_TAX_GRP
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
    FROM LOGIC_SCUSTGLR
)
---- FILTER LAYER ----

, FILTER_SCUSTGLR as (
    SELECT *
    FROM RENAME_SCUSTGLR
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SCUSTGLR
)

---- FINAL LAYER ----
SELECT
          CUSTOMER_HK
        , SETID
        , CUST_ID
        , CUST_GRP_TYPE
        , CUSTOMER_GROUP
        , DEFAULT_TAX_GRP
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
    WHERE existing.CUSTOMER_HK = JOIN_RESULT.CUSTOMER_HK
	AND existing.CUST_GRP_TYPE = JOIN_RESULT.CUST_GRP_TYPE
	AND existing.CUSTOMER_GROUP = JOIN_RESULT.CUSTOMER_GROUP
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by CUSTOMER_HK,CUST_GRP_TYPE,CUSTOMER_GROUP, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT   MD5_BINARY(GR.VALUE) AS CUSTOMER_HK
    , null as SETID
    , GR.VALUE as CUST_ID
    , GR.VALUE as CUST_GRP_TYPE
    , GR.VALUE as CUSTOMER_GROUP
    , null as DEFAULT_TAX_GRP
, null as DATETIME_ADDED
, null as LASTUPDDTTM
, null as LAST_MAINT_OPRID
, null as _FIVETRAN_DELETED
, null as _FIVETRAN_ID
, null as _FIVETRAN_SYNCED
, null as PSA_DELETE_IND
, null as PSA_LOAD_DTS
, null as PSA_RECORD_SOURCE
    ,  CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP  as LOAD_DTS 
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASHDIFF	
  FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}