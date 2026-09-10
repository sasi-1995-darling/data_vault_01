---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('tt_e21prd_e21trubis', 'arsalesman') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM tt_e21prd_e21trubis.arsalesman )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        SLS_REP                                                      as                                       SALES_REP_BK
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
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        SALES_REP_BK
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
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHMA.ORCL.E21PRD.ARSALESMAN'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          SALES_REP_BK
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
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SLS_REP as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SALES_REP_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ZIP::text), '^^') 
            , '||', IFNULL(TRIM(CEXP_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(PHONE::text), '^^') 
            , '||', IFNULL(TRIM(STATE::text), '^^') 
            , '||', IFNULL(TRIM(USER_ID::text), '^^') 
            , '||', IFNULL(TRIM(END_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SLS_NAME::text), '^^') 
            , '||', IFNULL(TRIM(CNTRY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ACCT_PREFIX::text), '^^') 
            , '||', IFNULL(TRIM(COMM_PLAN::text), '^^') 
            , '||', IFNULL(TRIM(CACR_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS1::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS3::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS2::text), '^^') 
            , '||', IFNULL(TRIM(SLS_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(BRANCH::text), '^^') 
            , '||', IFNULL(TRIM(SLS_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(REP_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REGION::text), '^^') 
            , '||', IFNULL(TRIM(CITY::text), '^^') 
            , '||', IFNULL(TRIM(INTERNET_ADDR::text), '^^') 
            , '||', IFNULL(TRIM(FAX::text), '^^') 
            , '||', IFNULL(TRIM(VEND_CODE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
