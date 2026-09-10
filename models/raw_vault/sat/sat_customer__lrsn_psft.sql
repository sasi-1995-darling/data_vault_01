---- SRC LAYER ----
WITH
SRC_SCUSTLR        as ( SELECT * FROM {{ ref('v_psa_stg_customer__lrsn_psft') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SCUSTLR        as ( SELECT * FROM STAGING.v_psa_stg_customer__lrsn_psft )
*/
---- LOGIC LAYER ----

, LOGIC_SCUSTLR as (
    SELECT
        CUSTOMER_HK
      , CUST_ID
      , SETID
      , BUSINESS_UNIT
      , L_SHIP_TO_CUST_ID
      , CUST_STATUS
      , CUST_STATUS_DT
      , CUSTOMER_TYPE
      , CUST_NAME
      , SOLD_TO_FLG
      , SHIP_TO_FLG
      , BILL_TO_FLG
      , PHONE
      , FAX
      , SHIP_FROM_BU
      , ROUTE_CD
      , STORE_NUMBER
      , SUPPORT_TEAM_CD
      , L_TEAM_NAME
      , CORPORATE_CUST_ID
      , L_CORP_CUST_NAME
      , L_REGION
      , L_TAB
      , BILL_TO_CUST_ID
      , L_BILLTO_CUST_NAME
      , REGION_CD
      , SALES_PERSON
      , L_SPER_NAME
      , L_SLS_PERSN_STATUS
      , L_CROSS_DOCK
      , EMAILID
      , L_PB_EMAIL
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SCUSTLR
)
---- RENAME LAYER ----

, RENAME_SCUSTLR as (
    SELECT
        CUSTOMER_HK
      , CUST_ID
      , SETID
      , BUSINESS_UNIT
      , L_SHIP_TO_CUST_ID
      , CUST_STATUS
      , CUST_STATUS_DT
      , CUSTOMER_TYPE
      , CUST_NAME
      , SOLD_TO_FLG
      , SHIP_TO_FLG
      , BILL_TO_FLG
      , PHONE
      , FAX
      , SHIP_FROM_BU
      , ROUTE_CD
      , STORE_NUMBER
      , SUPPORT_TEAM_CD
      , L_TEAM_NAME
      , CORPORATE_CUST_ID
      , L_CORP_CUST_NAME
      , L_REGION
      , L_TAB
      , BILL_TO_CUST_ID
      , L_BILLTO_CUST_NAME
      , REGION_CD
      , SALES_PERSON
      , L_SPER_NAME
      , L_SLS_PERSN_STATUS
      , L_CROSS_DOCK
      , EMAILID
      , L_PB_EMAIL
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SCUSTLR
)
---- FILTER LAYER ----

, FILTER_SCUSTLR as (
    SELECT *
    FROM RENAME_SCUSTLR
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SCUSTLR
)

---- FINAL LAYER ----
SELECT
          CUSTOMER_HK
        , CUST_ID
        , SETID
        , BUSINESS_UNIT
        , L_SHIP_TO_CUST_ID
        , CUST_STATUS
        , CUST_STATUS_DT
        , CUSTOMER_TYPE
        , CUST_NAME
        , SOLD_TO_FLG
        , SHIP_TO_FLG
        , BILL_TO_FLG
        , PHONE
        , FAX
        , SHIP_FROM_BU
        , ROUTE_CD
        , STORE_NUMBER
        , SUPPORT_TEAM_CD
        , L_TEAM_NAME
        , CORPORATE_CUST_ID
        , L_CORP_CUST_NAME
        , L_REGION
        , L_TAB
        , BILL_TO_CUST_ID
        , L_BILLTO_CUST_NAME
        , REGION_CD
        , SALES_PERSON
        , L_SPER_NAME
        , L_SLS_PERSN_STATUS
        , L_CROSS_DOCK
        , EMAILID
        , L_PB_EMAIL
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
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by CUSTOMER_HK, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT   MD5_BINARY(GR.VALUE) AS CUSTOMER_HK
, GR.VALUE AS CUST_ID
    , null as SETID
    , null as BUSINESS_UNIT
    , null as L_SHIP_TO_CUST_ID
    , null as CUST_STATUS
    , null as CUST_STATUS_DT
    , null as CUSTOMER_TYPE
    , null as CUST_NAME
    , null as SOLD_TO_FLG
    , null as SHIP_TO_FLG
    , null as BILL_TO_FLG
    , null as PHONE
    , null as FAX
    , null as SHIP_FROM_BU
    , null as ROUTE_CD
    , null as STORE_NUMBER
    , null as SUPPORT_TEAM_CD
    , null as L_TEAM_NAME
    , null as CORPORATE_CUST_ID
    , null as L_CORP_CUST_NAME
    , null as L_REGION
    , null as L_TAB
    , null as BILL_TO_CUST_ID
    , null as L_BILLTO_CUST_NAME
    , null as REGION_CD
    , null as SALES_PERSON
    , null as L_SPER_NAME
    , null as L_SLS_PERSN_STATUS
    , null as L_CROSS_DOCK
    , null as EMAILID
    , null as L_PB_EMAIL
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