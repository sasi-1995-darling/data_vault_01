---- SRC LAYER ----
WITH
SRC_SLR            as ( SELECT * FROM {{ ref('v_psa_stg_item_cat__lrsn_psft') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SLR            as ( SELECT * FROM STAGING.v_psa_stg_item_cat__LRSN_PSFT )
*/
---- LOGIC LAYER ----

, LOGIC_SLR as (
    SELECT
        ITEM_CAT_BK
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
      , HASHDIFF
    FROM SRC_SLR
)
---- RENAME LAYER ----

, RENAME_SLR as (
    SELECT
        ITEM_CAT_BK
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
          ITEM_CAT_BK
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
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ITEM_CAT_BK = JOIN_RESULT.ITEM_CAT_BK
    AND existing.HASH_DIFF = JOIN_RESULT.HASH_DIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by ITEM_CAT_BK, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT              GR.VALUE as ITEM_CAT_BK
    , null as CATEGORY_ID
    , null as EFFDT
    , null as SETID
    , null as CATEGORY_TYPE
    , null as CATEGORY_CD
    , null as DESCR60
    , null as DESCRSHORT
    , null as PROFILE_ID
    , null as NBR_OF_ITMS
    , null as LEAD_TIME
    , null as INSPECT_CD
    , null as INSPECT_UOM_TYPE
    , null as ROUTING_ID
    , null as REJECT_DAYS
    , null as ACCOUNT
    , null as ALTACCT
    , null as UNIT_PRC_TOL
    , null as PCT_UNIT_PRC_TOL
    , null as RECV_REQ
    , null as EXT_PRC_TOL
    , null as PCT_EXT_PRC_TOL
    , null as QTY_RECV_TOL_PCT
    , null as RJCT_OVER_TOL_FLAG
    , null as PRIMARY_BUYER
    , null as RECV_PARTIAL_FLG
    , null as CURRENCY_CD
    , null as PCT_UNDER_QTY
    , null as SRC_METHOD
    , null as LEAD_TIME_IMP
    , null as PRICE_IMP
    , null as SHIPTO_PR_IMP
    , null as VNDR_PR_IMP
    , null as HIST_END_DT
    , null as HIST_NBR_MTHS
    , null as HIST_START_DT
    , null as MERCH_AMT_CAT_TOT
    , null as HIST_START_MTH
    , null as UNIT_PRC_TOL_L
    , null as PCT_UNIT_PRC_TOL_L
    , null as EXT_PRC_TOL_L
    , null as PCT_EXT_PRC_TOL_L
    , null as SHIP_LATE_DAYS
    , null as CUM_SRC_RUN_LEVEL
    , null as EFF_STATUS
    , null as MARKETCODE
    , null as PHYSICAL_NATURE
    , null as VAT_SVC_PERFRM_FLG
    , null as ULTIMATE_USE_CD
    , null as WF_PRC_TOL_OVR
    , null as WF_PRC_TOL_UND
    , null as WF_PCT_PRC_TOL_OVR
    , null as WF_PCT_PRC_TOL_UND
    , null as RFQ_REQ_FLAG
    , null as COMMENTS_LONG
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