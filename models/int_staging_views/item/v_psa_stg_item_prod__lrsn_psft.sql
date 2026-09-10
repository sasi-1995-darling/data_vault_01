---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_prod_item') }} as SRC 
                        /* The following qualify clause is required to pick the latest change for a day when there are Intra day changes,
                            when Fivetran resync triggered by manual sync multiple times in a day(Resync Happens usually once per week currently). Ex. cust_id ='36196' */
                            qualify 1 = row_number() over(partition by PRODUCT_ID, _fivetran_synced order by psa_load_dts desc) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM lrsn_psft_sysadm.ps_prod_item )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        PRODUCT_ID                                                   as                                            ITEM_BK
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
        ITEM_BK
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
    WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.PS_PROD_ITEM'
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
          ITEM_BK
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
        , BKCC
        ,  '-2'                                                        as PLANT_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SETID::text), '^^') 
            , '||', IFNULL(TRIM(DESCR::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_USE::text), '^^') 
            , '||', IFNULL(TRIM(MODEL_NBR::text), '^^') 
            , '||', IFNULL(TRIM(CATALOG_NBR::text), '^^') 
            , '||', IFNULL(TRIM(TAX_PRODUCT_NBR::text), '^^') 
            , '||', IFNULL(TRIM(TAX_TRANS_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_TRANS_SUB_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_KIT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(EFF_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(INV_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(DROP_SHIP_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(COMM_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(COMM_PCT::text), '^^') 
            , '||', IFNULL(TRIM(EOEP_MRGBASE_FLG::text), '^^') 
            , '||', IFNULL(TRIM(UPPER_MARGIN_PCT::text), '^^') 
            , '||', IFNULL(TRIM(LOWER_MARGIN_PCT::text), '^^') 
            , '||', IFNULL(TRIM(ADJUST_ALTCOST_PCT::text), '^^') 
            , '||', IFNULL(TRIM(ADJUST_ALTCOST_FLG::text), '^^') 
            , '||', IFNULL(TRIM(HOLD_UPDATE_SW::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_PC::text), '^^') 
            , '||', IFNULL(TRIM(PROJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(ACTIVITY_ID::text), '^^') 
            , '||', IFNULL(TRIM(COST_ELEMENT::text), '^^') 
            , '||', IFNULL(TRIM(EXPORT_LIC_REQ::text), '^^') 
            , '||', IFNULL(TRIM(FORECAST_ITEM_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(RETURN_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(DESCR254::text), '^^') 
            , '||', IFNULL(TRIM(CFG_KIT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CFG_CODE_OPT::text), '^^') 
            , '||', IFNULL(TRIM(CP_TEMPLATE_ID::text), '^^') 
            , '||', IFNULL(TRIM(CP_TREE_DIST::text), '^^') 
            , '||', IFNULL(TRIM(PHYSICAL_NATURE::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_KIT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PROD_BRAND::text), '^^') 
            , '||', IFNULL(TRIM(PROD_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(THIRD_PARTY_FLG::text), '^^') 
            , '||', IFNULL(TRIM(RENEWABLE::text), '^^') 
            , '||', IFNULL(TRIM(RENEWAL_ACTION::text), '^^') 
            , '||', IFNULL(TRIM(PRICING_STRUCTURE::text), '^^') 
            , '||', IFNULL(TRIM(PERCENTAGE::text), '^^') 
            , '||', IFNULL(TRIM(APPLIES_TO::text), '^^') 
            , '||', IFNULL(TRIM(REV_RECOG_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(CA_BP_TMPL_ID::text), '^^') 
            , '||', IFNULL(TRIM(BP_DTL_TMPL_ID::text), '^^') 
            , '||', IFNULL(TRIM(RNW_TEMPLATE_ID::text), '^^') 
            , '||', IFNULL(TRIM(CA_AP_TMPL_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_C1_A::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_C1_B::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_C1_C::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_C1_D::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_C10_A::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_C10_B::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_C10_C::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_C10_D::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_C2::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_C30_A::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_C30_B::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_C30_C::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_C30_D::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_C4::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_C6::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_C8::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_N12_A::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_N12_B::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_N12_C::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_N12_D::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_N15_A::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_N15_B::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_N15_C::text), '^^') 
            , '||', IFNULL(TRIM(PROD_FIELD_N15_D::text), '^^') 
            , '||', IFNULL(TRIM(VAT_SVC_PERFRM_FLG::text), '^^') 
            , '||', IFNULL(TRIM(DATETIME_ADDED::text), '^^') 
            , '||', IFNULL(TRIM(LASTUPDDTTM::text), '^^') 
            , '||', IFNULL(TRIM(LAST_MAINT_OPRID::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
