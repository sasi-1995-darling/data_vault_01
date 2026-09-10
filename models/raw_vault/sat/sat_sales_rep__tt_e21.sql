---- SRC LAYER ----
WITH
SRC_SSALTT         as ( SELECT * FROM {{ ref('v_psa_stg_arsalesman__tt_e21') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SSALTT         as ( SELECT * FROM STAGING.v_psa_stg_arsalesman_tt_e21 )
*/
---- LOGIC LAYER ----

, LOGIC_SSALTT as (
    SELECT
        SALES_REP_HK
      , SLS_REP
      , ZIP
      , CEXP_ACCT
      , PHONE
      , STATE
      , USER_ID
      , END_DATE
      , SLS_NAME
      , CNTRY_CODE
      , ACCT_PREFIX
      , COMM_PLAN
      , CACR_ACCT
      , ADDRESS1
      , ADDRESS3
      , ADDRESS2
      , SLS_TYPE
      , BRANCH
      , SLS_GROUP
      , REP_TYPE
      , START_DATE
      , REGION
      , CITY
      , INTERNET_ADDR
      , FAX
      , VEND_CODE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SSALTT
)
---- RENAME LAYER ----

, RENAME_SSALTT as (
    SELECT
        SALES_REP_HK
      , SLS_REP
      , ZIP
      , CEXP_ACCT
      , PHONE
      , STATE
      , USER_ID
      , END_DATE
      , SLS_NAME
      , CNTRY_CODE
      , ACCT_PREFIX
      , COMM_PLAN
      , CACR_ACCT
      , ADDRESS1
      , ADDRESS3
      , ADDRESS2
      , SLS_TYPE
      , BRANCH
      , SLS_GROUP
      , REP_TYPE
      , START_DATE
      , REGION
      , CITY
      , INTERNET_ADDR
      , FAX
      , VEND_CODE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SSALTT
)
---- FILTER LAYER ----

, FILTER_SSALTT as (
    SELECT *
    FROM RENAME_SSALTT
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SSALTT
)

---- FINAL LAYER ----
SELECT
          SALES_REP_HK
        , SLS_REP
        , ZIP
        , CEXP_ACCT
        , PHONE
        , STATE
        , USER_ID
        , END_DATE
        , SLS_NAME
        , CNTRY_CODE
        , ACCT_PREFIX
        , COMM_PLAN
        , CACR_ACCT
        , ADDRESS1
        , ADDRESS3
        , ADDRESS2
        , SLS_TYPE
        , BRANCH
        , SLS_GROUP
        , REP_TYPE
        , START_DATE
        , REGION
        , CITY
        , INTERNET_ADDR
        , FAX
        , VEND_CODE
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
    SELECT           MD5_BINARY(GR.VALUE) AS SALES_REP_HK
    , GR.VALUE as SLS_REP
    , null as ZIP
    , null as CEXP_ACCT
    , null as PHONE
    , null as STATE
    , null as USER_ID
    , null as END_DATE
    , null as SLS_NAME
    , null as CNTRY_CODE
    , null as ACCT_PREFIX
    , null as COMM_PLAN
    , null as CACR_ACCT
    , null as ADDRESS1
    , null as ADDRESS3
    , null as ADDRESS2
    , null as SLS_TYPE
    , null as BRANCH
    , null as SLS_GROUP
    , null as REP_TYPE
    , null as START_DATE
    , null as REGION
    , null as CITY
    , null as INTERNET_ADDR
    , null as FAX
    , null as VEND_CODE
, null as _FIVETRAN_DELETED
, null as _FIVETRAN_ID
, null as _FIVETRAN_SYNCED
, null as PSA_DELETE_IND
, null as PSA_LOAD_DTS
, null as PSA_RECORD_SOURCE
 , CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP  as LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASH_DIFF
  FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}