---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_l_rep_cust') }} as SRC 
                        /* The following qualify clause is required to pick the latest change for a day when there are Intra day changes,
                            when Fivetran resync triggered by manual sync multiple times in a day(Resync Happens usually once per week currently). Ex. cust_id ='36196' */
                            qualify 1 = row_number() over(partition by cust_id, _fivetran_synced order by psa_load_dts desc) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM lrsn_psft_sysadm.ps_l_rep_cust )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        CUST_ID                                                      as                                        CUSTOMER_BK
      , SETID
      , BUSINESS_UNIT
      , L_SHIP_TO_CUST_ID
      , CUST_ID
      , CUST_STATUS
      , CUST_STATUS_DT
      , CUSTOMER_TYPE
      , CUST_NAME
      , SOLD_TO_FLG
      , SHIP_TO_FLG
      , BILL_TO_FLG
      , COUNTRY
      , ADDRESS1
      , ADDRESS2
      , CITY
      , STATE
      , POSTAL
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
        CUSTOMER_BK
      , SETID
      , BUSINESS_UNIT
      , L_SHIP_TO_CUST_ID
      , CUST_ID
      , CUST_STATUS
      , CUST_STATUS_DT
      , CUSTOMER_TYPE
      , CUST_NAME
      , SOLD_TO_FLG
      , SHIP_TO_FLG
      , BILL_TO_FLG
      , COUNTRY
      , ADDRESS1
      , ADDRESS2
      , CITY
      , STATE
      , POSTAL
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
    WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.REP_CUST'
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
          CUSTOMER_BK
        , SETID
        , BUSINESS_UNIT
        , L_SHIP_TO_CUST_ID
        , CUST_ID
        , CUST_STATUS
        , CUST_STATUS_DT
        , CUSTOMER_TYPE
        , CUST_NAME
        , SOLD_TO_FLG
        , SHIP_TO_FLG
        , BILL_TO_FLG
        , COUNTRY
        , ADDRESS1
        , ADDRESS2
        , CITY
        , STATE
        , POSTAL
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
        , BKCC
        , conditional_change_event(hash(* exclude(psa_load_dts, load_dts, _fivetran_id, _fivetran_synced))) over(partition by CUSTOMER_BK order by _fivetran_synced) as CCE
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SETID::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(L_SHIP_TO_CUST_ID::text), '^^') 
            , '||', IFNULL(TRIM(CUST_ID::text), '^^') 
            , '||', IFNULL(TRIM(CUST_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(CUST_STATUS_DT::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(CUST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SOLD_TO_FLG::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_FLG::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TO_FLG::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS1::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS2::text), '^^') 
            , '||', IFNULL(TRIM(CITY::text), '^^') 
            , '||', IFNULL(TRIM(STATE::text), '^^') 
            , '||', IFNULL(TRIM(POSTAL::text), '^^') 
            , '||', IFNULL(TRIM(PHONE::text), '^^') 
            , '||', IFNULL(TRIM(FAX::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_FROM_BU::text), '^^') 
            , '||', IFNULL(TRIM(ROUTE_CD::text), '^^') 
            , '||', IFNULL(TRIM(STORE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SUPPORT_TEAM_CD::text), '^^') 
            , '||', IFNULL(TRIM(L_TEAM_NAME::text), '^^') 
            , '||', IFNULL(TRIM(CORPORATE_CUST_ID::text), '^^') 
            , '||', IFNULL(TRIM(L_CORP_CUST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(L_REGION::text), '^^') 
            , '||', IFNULL(TRIM(L_TAB::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TO_CUST_ID::text), '^^') 
            , '||', IFNULL(TRIM(L_BILLTO_CUST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(REGION_CD::text), '^^') 
            , '||', IFNULL(TRIM(SALES_PERSON::text), '^^') 
            , '||', IFNULL(TRIM(L_SPER_NAME::text), '^^') 
            , '||', IFNULL(TRIM(L_SLS_PERSN_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(L_CROSS_DOCK::text), '^^') 
            , '||', IFNULL(TRIM(EMAILID::text), '^^') 
            , '||', IFNULL(TRIM(L_PB_EMAIL::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(CCE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
