---- SRC LAYER ----
WITH
SRC_SITMLR         as ( SELECT * FROM {{ ref('v_psa_stg_item_prod__lrsn_psft') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SITMLR         as ( SELECT * FROM STAGING.v_psa_stg_item_prod__lrsn_psft )
*/
---- LOGIC LAYER ----

, LOGIC_SITMLR as (
    SELECT
        ITEM_HK
      , PRODUCT_ID
      , SETID
      , DESCR
      , PRODUCT_USE
      , MODEL_NBR
      , CATALOG_NBR
      , TAX_PRODUCT_NBR
      , TAX_TRANS_TYPE
      , TAX_TRANS_SUB_TYPE
      , PRODUCT_KIT_FLAG
      , EFF_STATUS
      , INV_ITEM_ID
      , DROP_SHIP_FLAG
      , COMM_FLAG
      , COMM_PCT
      , EOEP_MRGBASE_FLG
      , UPPER_MARGIN_PCT
      , LOWER_MARGIN_PCT
      , ADJUST_ALTCOST_PCT
      , ADJUST_ALTCOST_FLG
      , HOLD_UPDATE_SW
      , BUSINESS_UNIT_PC
      , PROJECT_ID
      , ACTIVITY_ID
      , COST_ELEMENT
      , EXPORT_LIC_REQ
      , FORECAST_ITEM_FLAG
      , RETURN_FLAG
      , DESCR254
      , CFG_KIT_FLAG
      , CFG_CODE_OPT
      , CP_TEMPLATE_ID
      , CP_TREE_DIST
      , PHYSICAL_NATURE
      , PRICE_KIT_FLAG
      , PROD_BRAND
      , PROD_CATEGORY
      , THIRD_PARTY_FLG
      , RENEWABLE
      , RENEWAL_ACTION
      , PRICING_STRUCTURE
      , PERCENTAGE
      , APPLIES_TO
      , REV_RECOG_METHOD
      , CA_BP_TMPL_ID
      , BP_DTL_TMPL_ID
      , RNW_TEMPLATE_ID
      , CA_AP_TMPL_ID
      , PROD_FIELD_C1_A
      , PROD_FIELD_C1_B
      , PROD_FIELD_C1_C
      , PROD_FIELD_C1_D
      , PROD_FIELD_C10_A
      , PROD_FIELD_C10_B
      , PROD_FIELD_C10_C
      , PROD_FIELD_C10_D
      , PROD_FIELD_C2
      , PROD_FIELD_C30_A
      , PROD_FIELD_C30_B
      , PROD_FIELD_C30_C
      , PROD_FIELD_C30_D
      , PROD_FIELD_C4
      , PROD_FIELD_C6
      , PROD_FIELD_C8
      , PROD_FIELD_N12_A
      , PROD_FIELD_N12_B
      , PROD_FIELD_N12_C
      , PROD_FIELD_N12_D
      , PROD_FIELD_N15_A
      , PROD_FIELD_N15_B
      , PROD_FIELD_N15_C
      , PROD_FIELD_N15_D
      , VAT_SVC_PERFRM_FLG
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
    FROM SRC_SITMLR
)
---- RENAME LAYER ----

, RENAME_SITMLR as (
    SELECT
        ITEM_HK
      , PRODUCT_ID
      , SETID
      , DESCR
      , PRODUCT_USE
      , MODEL_NBR
      , CATALOG_NBR
      , TAX_PRODUCT_NBR
      , TAX_TRANS_TYPE
      , TAX_TRANS_SUB_TYPE
      , PRODUCT_KIT_FLAG
      , EFF_STATUS
      , INV_ITEM_ID
      , DROP_SHIP_FLAG
      , COMM_FLAG
      , COMM_PCT
      , EOEP_MRGBASE_FLG
      , UPPER_MARGIN_PCT
      , LOWER_MARGIN_PCT
      , ADJUST_ALTCOST_PCT
      , ADJUST_ALTCOST_FLG
      , HOLD_UPDATE_SW
      , BUSINESS_UNIT_PC
      , PROJECT_ID
      , ACTIVITY_ID
      , COST_ELEMENT
      , EXPORT_LIC_REQ
      , FORECAST_ITEM_FLAG
      , RETURN_FLAG
      , DESCR254
      , CFG_KIT_FLAG
      , CFG_CODE_OPT
      , CP_TEMPLATE_ID
      , CP_TREE_DIST
      , PHYSICAL_NATURE
      , PRICE_KIT_FLAG
      , PROD_BRAND
      , PROD_CATEGORY
      , THIRD_PARTY_FLG
      , RENEWABLE
      , RENEWAL_ACTION
      , PRICING_STRUCTURE
      , PERCENTAGE
      , APPLIES_TO
      , REV_RECOG_METHOD
      , CA_BP_TMPL_ID
      , BP_DTL_TMPL_ID
      , RNW_TEMPLATE_ID
      , CA_AP_TMPL_ID
      , PROD_FIELD_C1_A
      , PROD_FIELD_C1_B
      , PROD_FIELD_C1_C
      , PROD_FIELD_C1_D
      , PROD_FIELD_C10_A
      , PROD_FIELD_C10_B
      , PROD_FIELD_C10_C
      , PROD_FIELD_C10_D
      , PROD_FIELD_C2
      , PROD_FIELD_C30_A
      , PROD_FIELD_C30_B
      , PROD_FIELD_C30_C
      , PROD_FIELD_C30_D
      , PROD_FIELD_C4
      , PROD_FIELD_C6
      , PROD_FIELD_C8
      , PROD_FIELD_N12_A
      , PROD_FIELD_N12_B
      , PROD_FIELD_N12_C
      , PROD_FIELD_N12_D
      , PROD_FIELD_N15_A
      , PROD_FIELD_N15_B
      , PROD_FIELD_N15_C
      , PROD_FIELD_N15_D
      , VAT_SVC_PERFRM_FLG
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
    FROM LOGIC_SITMLR
)
---- FILTER LAYER ----

, FILTER_SITMLR as (
    SELECT *
    FROM RENAME_SITMLR
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SITMLR
)

---- FINAL LAYER ----
SELECT
          ITEM_HK
        , PRODUCT_ID
        , SETID
        , DESCR
        , PRODUCT_USE
        , MODEL_NBR
        , CATALOG_NBR
        , TAX_PRODUCT_NBR
        , TAX_TRANS_TYPE
        , TAX_TRANS_SUB_TYPE
        , PRODUCT_KIT_FLAG
        , EFF_STATUS
        , INV_ITEM_ID
        , DROP_SHIP_FLAG
        , COMM_FLAG
        , COMM_PCT
        , EOEP_MRGBASE_FLG
        , UPPER_MARGIN_PCT
        , LOWER_MARGIN_PCT
        , ADJUST_ALTCOST_PCT
        , ADJUST_ALTCOST_FLG
        , HOLD_UPDATE_SW
        , BUSINESS_UNIT_PC
        , PROJECT_ID
        , ACTIVITY_ID
        , COST_ELEMENT
        , EXPORT_LIC_REQ
        , FORECAST_ITEM_FLAG
        , RETURN_FLAG
        , DESCR254
        , CFG_KIT_FLAG
        , CFG_CODE_OPT
        , CP_TEMPLATE_ID
        , CP_TREE_DIST
        , PHYSICAL_NATURE
        , PRICE_KIT_FLAG
        , PROD_BRAND
        , PROD_CATEGORY
        , THIRD_PARTY_FLG
        , RENEWABLE
        , RENEWAL_ACTION
        , PRICING_STRUCTURE
        , PERCENTAGE
        , APPLIES_TO
        , REV_RECOG_METHOD
        , CA_BP_TMPL_ID
        , BP_DTL_TMPL_ID
        , RNW_TEMPLATE_ID
        , CA_AP_TMPL_ID
        , PROD_FIELD_C1_A
        , PROD_FIELD_C1_B
        , PROD_FIELD_C1_C
        , PROD_FIELD_C1_D
        , PROD_FIELD_C10_A
        , PROD_FIELD_C10_B
        , PROD_FIELD_C10_C
        , PROD_FIELD_C10_D
        , PROD_FIELD_C2
        , PROD_FIELD_C30_A
        , PROD_FIELD_C30_B
        , PROD_FIELD_C30_C
        , PROD_FIELD_C30_D
        , PROD_FIELD_C4
        , PROD_FIELD_C6
        , PROD_FIELD_C8
        , PROD_FIELD_N12_A
        , PROD_FIELD_N12_B
        , PROD_FIELD_N12_C
        , PROD_FIELD_N12_D
        , PROD_FIELD_N15_A
        , PROD_FIELD_N15_B
        , PROD_FIELD_N15_C
        , PROD_FIELD_N15_D
        , VAT_SVC_PERFRM_FLG
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
    WHERE existing.ITEM_HK= JOIN_RESULT.ITEM_HK
  AND existing.SETID = JOIN_RESULT.SETID
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by ITEM_HK, SETID,HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        MD5_BINARY(GR.VALUE) AS ITEM_HK
       , GR.VALUE as PRODUCT_ID
    , GR.VALUE as SETID
    , null as DESCR
    , null as PRODUCT_USE
    , null as MODEL_NBR
    , null as CATALOG_NBR
    , null as TAX_PRODUCT_NBR
    , null as TAX_TRANS_TYPE
    , null as TAX_TRANS_SUB_TYPE
    , null as PRODUCT_KIT_FLAG
    , null as EFF_STATUS
    , null as INV_ITEM_ID
    , null as DROP_SHIP_FLAG
    , null as COMM_FLAG
    , null as COMM_PCT
    , null as EOEP_MRGBASE_FLG
    , null as UPPER_MARGIN_PCT
    , null as LOWER_MARGIN_PCT
    , null as ADJUST_ALTCOST_PCT
    , null as ADJUST_ALTCOST_FLG
    , null as HOLD_UPDATE_SW
    , null as BUSINESS_UNIT_PC
    , null as PROJECT_ID
    , null as ACTIVITY_ID
    , null as COST_ELEMENT
    , null as EXPORT_LIC_REQ
    , null as FORECAST_ITEM_FLAG
    , null as RETURN_FLAG
    , null as DESCR254
    , null as CFG_KIT_FLAG
    , null as CFG_CODE_OPT
    , null as CP_TEMPLATE_ID
    , null as CP_TREE_DIST
    , null as PHYSICAL_NATURE
    , null as PRICE_KIT_FLAG
    , null as PROD_BRAND
    , null as PROD_CATEGORY
    , null as THIRD_PARTY_FLG
    , null as RENEWABLE
    , null as RENEWAL_ACTION
    , null as PRICING_STRUCTURE
    , null as PERCENTAGE
    , null as APPLIES_TO
    , null as REV_RECOG_METHOD
    , null as CA_BP_TMPL_ID
    , null as BP_DTL_TMPL_ID
    , null as RNW_TEMPLATE_ID
    , null as CA_AP_TMPL_ID
    , null as PROD_FIELD_C1_A
    , null as PROD_FIELD_C1_B
    , null as PROD_FIELD_C1_C
    , null as PROD_FIELD_C1_D
    , null as PROD_FIELD_C10_A
    , null as PROD_FIELD_C10_B
    , null as PROD_FIELD_C10_C
    , null as PROD_FIELD_C10_D
    , null as PROD_FIELD_C2
    , null as PROD_FIELD_C30_A
    , null as PROD_FIELD_C30_B
    , null as PROD_FIELD_C30_C
    , null as PROD_FIELD_C30_D
    , null as PROD_FIELD_C4
    , null as PROD_FIELD_C6
    , null as PROD_FIELD_C8
    , null as PROD_FIELD_N12_A
    , null as PROD_FIELD_N12_B
    , null as PROD_FIELD_N12_C
    , null as PROD_FIELD_N12_D
    , null as PROD_FIELD_N15_A
    , null as PROD_FIELD_N15_B
    , null as PROD_FIELD_N15_C
    , null as PROD_FIELD_N15_D
    , null as VAT_SVC_PERFRM_FLG
    , null as DATETIME_ADDED
    , null as LASTUPDDTTM
    , null as LAST_MAINT_OPRID
, null as _FIVETRAN_DELETED
, null as _FIVETRAN_ID
, null as _FIVETRAN_SYNCED
, null as PSA_DELETE_IND
, null as PSA_LOAD_DTS
, null as PSA_RECORD_SOURCE
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP as LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASHDIFF
  FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}