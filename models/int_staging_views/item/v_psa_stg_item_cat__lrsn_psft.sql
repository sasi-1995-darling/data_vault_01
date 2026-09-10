---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_itm_cat_tbl') }} as SRC 
                        /* The following qualify clause is required to pick the latest change for a day when there are Intra day changes,
                            when Fivetran resync triggered by manual sync multiple times in a day(Resync Happens usually once per week currently). Ex. cust_id ='36196' */
                            qualify 1 = row_number() over(partition by  CATEGORY_ID, EFFDT, _fivetran_synced order by psa_load_dts desc) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM lrsn_psft_sysadm.ps_itm_cat_tbl )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        CATEGORY_ID
      , EFFDT
      , SETID
      , CATEGORY_TYPE
      , CATEGORY_CD
      , DESCR60
      , DESCRSHORT
      , PROFILE_ID
      , NBR_OF_ITMS
      , LEAD_TIME
      , INSPECT_CD
      , INSPECT_UOM_TYPE
      , ROUTING_ID
      , REJECT_DAYS
      , ACCOUNT
      , ALTACCT
      , UNIT_PRC_TOL
      , PCT_UNIT_PRC_TOL
      , RECV_REQ
      , EXT_PRC_TOL
      , PCT_EXT_PRC_TOL
      , QTY_RECV_TOL_PCT
      , RJCT_OVER_TOL_FLAG
      , PRIMARY_BUYER
      , RECV_PARTIAL_FLG
      , CURRENCY_CD
      , PCT_UNDER_QTY
      , SRC_METHOD
      , LEAD_TIME_IMP
      , PRICE_IMP
      , SHIPTO_PR_IMP
      , VNDR_PR_IMP
      , HIST_END_DT
      , HIST_NBR_MTHS
      , HIST_START_DT
      , MERCH_AMT_CAT_TOT
      , HIST_START_MTH
      , UNIT_PRC_TOL_L
      , PCT_UNIT_PRC_TOL_L
      , EXT_PRC_TOL_L
      , PCT_EXT_PRC_TOL_L
      , SHIP_LATE_DAYS
      , CUM_SRC_RUN_LEVEL
      , EFF_STATUS
      , MARKETCODE
      , PHYSICAL_NATURE
      , VAT_SVC_PERFRM_FLG
      , ULTIMATE_USE_CD
      , WF_PRC_TOL_OVR
      , WF_PRC_TOL_UND
      , WF_PCT_PRC_TOL_OVR
      , WF_PCT_PRC_TOL_UND
      , RFQ_REQ_FLAG
      , COMMENTS_LONG
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
        CATEGORY_ID
      , EFFDT
      , SETID
      , CATEGORY_TYPE
      , CATEGORY_CD
      , DESCR60
      , DESCRSHORT
      , PROFILE_ID
      , NBR_OF_ITMS
      , LEAD_TIME
      , INSPECT_CD
      , INSPECT_UOM_TYPE
      , ROUTING_ID
      , REJECT_DAYS
      , ACCOUNT
      , ALTACCT
      , UNIT_PRC_TOL
      , PCT_UNIT_PRC_TOL
      , RECV_REQ
      , EXT_PRC_TOL
      , PCT_EXT_PRC_TOL
      , QTY_RECV_TOL_PCT
      , RJCT_OVER_TOL_FLAG
      , PRIMARY_BUYER
      , RECV_PARTIAL_FLG
      , CURRENCY_CD
      , PCT_UNDER_QTY
      , SRC_METHOD
      , LEAD_TIME_IMP
      , PRICE_IMP
      , SHIPTO_PR_IMP
      , VNDR_PR_IMP
      , HIST_END_DT
      , HIST_NBR_MTHS
      , HIST_START_DT
      , MERCH_AMT_CAT_TOT
      , HIST_START_MTH
      , UNIT_PRC_TOL_L
      , PCT_UNIT_PRC_TOL_L
      , EXT_PRC_TOL_L
      , PCT_EXT_PRC_TOL_L
      , SHIP_LATE_DAYS
      , CUM_SRC_RUN_LEVEL
      , EFF_STATUS
      , MARKETCODE
      , PHYSICAL_NATURE
      , VAT_SVC_PERFRM_FLG
      , ULTIMATE_USE_CD
      , WF_PRC_TOL_OVR
      , WF_PRC_TOL_UND
      , WF_PCT_PRC_TOL_OVR
      , WF_PCT_PRC_TOL_UND
      , RFQ_REQ_FLAG
      , COMMENTS_LONG
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
    WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.PS_ITM_CAT_TBL'
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
          CONCAT (CATEGORY_ID, '||',EFFDT)                             as ITEM_CAT_BK
        , CATEGORY_ID
        , EFFDT
        , SETID
        , CATEGORY_TYPE
        , CATEGORY_CD
        , DESCR60
        , DESCRSHORT
        , PROFILE_ID
        , NBR_OF_ITMS
        , LEAD_TIME
        , INSPECT_CD
        , INSPECT_UOM_TYPE
        , ROUTING_ID
        , REJECT_DAYS
        , ACCOUNT
        , ALTACCT
        , UNIT_PRC_TOL
        , PCT_UNIT_PRC_TOL
        , RECV_REQ
        , EXT_PRC_TOL
        , PCT_EXT_PRC_TOL
        , QTY_RECV_TOL_PCT
        , RJCT_OVER_TOL_FLAG
        , PRIMARY_BUYER
        , RECV_PARTIAL_FLG
        , CURRENCY_CD
        , PCT_UNDER_QTY
        , SRC_METHOD
        , LEAD_TIME_IMP
        , PRICE_IMP
        , SHIPTO_PR_IMP
        , VNDR_PR_IMP
        , HIST_END_DT
        , HIST_NBR_MTHS
        , HIST_START_DT
        , MERCH_AMT_CAT_TOT
        , HIST_START_MTH
        , UNIT_PRC_TOL_L
        , PCT_UNIT_PRC_TOL_L
        , EXT_PRC_TOL_L
        , PCT_EXT_PRC_TOL_L
        , SHIP_LATE_DAYS
        , CUM_SRC_RUN_LEVEL
        , EFF_STATUS
        , MARKETCODE
        , PHYSICAL_NATURE
        , VAT_SVC_PERFRM_FLG
        , ULTIMATE_USE_CD
        , WF_PRC_TOL_OVR
        , WF_PRC_TOL_UND
        , WF_PCT_PRC_TOL_OVR
        , WF_PCT_PRC_TOL_UND
        , RFQ_REQ_FLAG
        , COMMENTS_LONG
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SETID::text), '^^') 
            , '||', IFNULL(TRIM(CATEGORY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(CATEGORY_CD::text), '^^') 
            , '||', IFNULL(TRIM(DESCR60::text), '^^') 
            , '||', IFNULL(TRIM(DESCRSHORT::text), '^^') 
            , '||', IFNULL(TRIM(PROFILE_ID::text), '^^') 
            , '||', IFNULL(TRIM(NBR_OF_ITMS::text), '^^') 
            , '||', IFNULL(TRIM(LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(INSPECT_CD::text), '^^') 
            , '||', IFNULL(TRIM(INSPECT_UOM_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ROUTING_ID::text), '^^') 
            , '||', IFNULL(TRIM(REJECT_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ALTACCT::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_PRC_TOL::text), '^^') 
            , '||', IFNULL(TRIM(PCT_UNIT_PRC_TOL::text), '^^') 
            , '||', IFNULL(TRIM(RECV_REQ::text), '^^') 
            , '||', IFNULL(TRIM(EXT_PRC_TOL::text), '^^') 
            , '||', IFNULL(TRIM(PCT_EXT_PRC_TOL::text), '^^') 
            , '||', IFNULL(TRIM(QTY_RECV_TOL_PCT::text), '^^') 
            , '||', IFNULL(TRIM(RJCT_OVER_TOL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_BUYER::text), '^^') 
            , '||', IFNULL(TRIM(RECV_PARTIAL_FLG::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY_CD::text), '^^') 
            , '||', IFNULL(TRIM(PCT_UNDER_QTY::text), '^^') 
            , '||', IFNULL(TRIM(SRC_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(LEAD_TIME_IMP::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_IMP::text), '^^') 
            , '||', IFNULL(TRIM(SHIPTO_PR_IMP::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_PR_IMP::text), '^^') 
            , '||', IFNULL(TRIM(HIST_END_DT::text), '^^') 
            , '||', IFNULL(TRIM(HIST_NBR_MTHS::text), '^^') 
            , '||', IFNULL(TRIM(HIST_START_DT::text), '^^') 
            , '||', IFNULL(TRIM(MERCH_AMT_CAT_TOT::text), '^^') 
            , '||', IFNULL(TRIM(HIST_START_MTH::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_PRC_TOL_L::text), '^^') 
            , '||', IFNULL(TRIM(PCT_UNIT_PRC_TOL_L::text), '^^') 
            , '||', IFNULL(TRIM(EXT_PRC_TOL_L::text), '^^') 
            , '||', IFNULL(TRIM(PCT_EXT_PRC_TOL_L::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_LATE_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(CUM_SRC_RUN_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(EFF_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(MARKETCODE::text), '^^') 
            , '||', IFNULL(TRIM(PHYSICAL_NATURE::text), '^^') 
            , '||', IFNULL(TRIM(VAT_SVC_PERFRM_FLG::text), '^^') 
            , '||', IFNULL(TRIM(ULTIMATE_USE_CD::text), '^^') 
            , '||', IFNULL(TRIM(WF_PRC_TOL_OVR::text), '^^') 
            , '||', IFNULL(TRIM(WF_PRC_TOL_UND::text), '^^') 
            , '||', IFNULL(TRIM(WF_PCT_PRC_TOL_OVR::text), '^^') 
            , '||', IFNULL(TRIM(WF_PCT_PRC_TOL_UND::text), '^^') 
            , '||', IFNULL(TRIM(RFQ_REQ_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(COMMENTS_LONG::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
