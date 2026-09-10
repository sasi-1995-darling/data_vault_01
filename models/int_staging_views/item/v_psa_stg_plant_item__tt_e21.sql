---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('tt_e21prd_e21trubis', 'whsprmstr') }} as SRC 
                        /* The following qualify clause is required to pick the latest change for driving keys that create duplicate hash-keys due to leading and lagging spaces within the field Ex. PART_CODE ='CW12MSBASE' */
                        qualify 1= row_number() over(partition by trim(part_code), cost_ctr, _fivetran_synced order by  _fivetran_synced desc, length(part_code)) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM tt_e21prd_e21trubis.whsprmstr )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        PART_CODE                                                    as                                            ITEM_BK
      , COST_CTR
      , PART_CODE
      , PART_TYPE
      , LAST_COST
      , PART_STATUS
      , KIT_FLAG
      , TAXABLE
      , ADD_USER
      , ALT_PART4
      , ALT_PART3
      , MIN_INV
      , MIN_BATCH_SZ
      , ALT_PART2
      , ALT_PART1
      , MFG_LEAD_TIME
      , YTD_SALES_DOL
      , ADD_DATE
      , OE_MSG_ID
      , PLATFORM_TYPE
      , LONG_DESC9
      , LONG_DESC8
      , REINFORMIX_DAYS
      , LONG_DESC5
      , STD_BURDEN
      , LONG_DESC4
      , PRIC_TYPE
      , LONG_DESC7
      , LONG_DESC6
      , YTD_PUR_DOL
      , LCHFLD2
      , RPTUOM
      , LCHFLD1
      , PART_WT
      , LCHFLD4
      , LCHFLD3
      , FREIGHT_CLASS
      , STATUS_DATE
      , CSRUN
      , LCHFLD5
      , YTD_SALES_UNIT
      , PART_COST_BURDEN
      , SIM_COST
      , PART_DTYPE
      , STD_FIXED_BURDEN
      , PACK_HEIGHT
      , STD_MATL
      , DIR_SHIP_FLAG
      , MODEL_PKG_NUMB
      , WAVE_PICK
      , MRP_INCLUDE
      , GROS_WT
      , SIM_COST_LABOR
      , COST_NO4
      , COST_NO3
      , INACT_RSN_CODE
      , COST_NO6
      , COST_NO5
      , PART_LENGTH
      , SPEC_SHEET
      , SIM_VARIABLE_BURDEN
      , LOT_GROUP
      , USAGE
      , MFG_PRIOR
      , VERSION_NUMBER
      , LYR_SALES_UNIT
      , FIXED_BURDEN
      , YTD_PUR_UNIT
      , SIM_COST_MATL
      , BAG_PLT
      , COMMODITY_CODE
      , SW_LICENSE_CODE
      , PART_WIDTH
      , PART_DDATE
      , BUYER_CODE
      , LONG_DESC1
      , SIM_FIXED_BURDEN
      , ACCUM_MATL
      , LONG_DESC3
      , LONG_DESC2
      , LYR_PUR_DOL
      , PART_COST
      , REP_PART
      , UPDATE_USER
      , SER_ON_SHIP
      , SIM_COST_BURDEN
      , STD_LABOR
      , RESP_BSN_UNIT
      , PALLET_WGT
      , PART_PRICE
      , SETUPDATE
      , PART_SUBGRP2
      , PART_SUBGRP3
      , PALLET_TYPE
      , COST_NO2
      , COST_NO1
      , ACCUM_STD_BURDEN
      , ACCUM_STD_LABOR
      , STD_COST
      , MAX_INV
      , WARRANTY_CODE
      , LYR_PUR_UNIT
      , LEAD_DAYS
      , MAX_WO_SZ
      , LOT_REQ
      , UPDATE_DATE
      , PUOM
      , DTFLD1
      , NUMFLD1
      , NUMFLD2
      , SPEC_DOCID
      , NUMFLD3
      , DTFLD4
      , NUMFLD4
      , PACK_WEIGHT
      , CATCH_WT
      , NUMFLD5
      , DTFLD5
      , DTFLD2
      , DTFLD3
      , WARRANTY_DAYS
      , DOWNGRADE_GRP
      , LANGUAGE_CODE
      , ASSEMBLED
      , AUTO_HOLD
      , SCHED_GRP
      , RETEST_DAYS
      , TAX_CATEGORY
      , SERVICE
      , SHIPUOM
      , ECOM_INCL
      , ACCUM_SIM_LABOR
      , ROYALTY_CODE
      , CORE_INDICATOR
      , MSG_ID
      , SELLABLE
      , PART_DESC
      , INSTALL_INST
      , PART_COST_LABOR
      , LYR_SALES_DOL
      , SPECIAL_QUOTE
      , ACCUM_LABOR
      , ACCUM_SIM_MATL
      , INST_DOCID
      , SETUPUSER
      , MTO_FLAG
      , BATCH_SIZE
      , MAKE_BUY
      , SAFETY_STOCK
      , SCHFLD1
      , PART_SUBGRP
      , SCHFLD3
      , SCHFLD2
      , ACCUM_SIM_BURDEN
      , WIN
      , SCHFLD5
      , PACK_WIDTH
      , SCHFLD4
      , SERIALIZED
      , PACK_LENGTH
      , CONFIG_GRP
      , DOC_IMAGE_NUMB
      , PREF_FLG
      , MAX_WO_PDAY
      , MFG_UOM
      , PALLET_STACK
      , CYCLE_TIME
      , MEDIA_CODE
      , CYCLE_GRP
      , SETUP_CHRG_FLAG
      , PART_HEIGHT
      , PROD_MSG_ID
      , LONG_DESC10
      , TECH_LEVEL
      , VARIABLE_BURDEN
      , ORDUOM
      , SALE_TYPE
      , ACCUM_BURDEN
      , UOM
      , INVCTL_GRP
      , PART_GRP
      , BAG_WGT
      , ACCUM_STD_MATL
      , DOC_IMAGE_FOLDER
      , SHELF_LIFE
      , DOC_IMAGE_PAGE
      , STD_VARIABLE_BURDEN
      , YTD_PUR_STD
      , STORAGE_TYPE
      , COST_MATL
      , COST_METH
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
      , COST_CTR                                                     as                                           PLANT_BK
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
      , COST_CTR
      , PART_CODE
      , PART_TYPE
      , LAST_COST
      , PART_STATUS
      , KIT_FLAG
      , TAXABLE
      , ADD_USER
      , ALT_PART4
      , ALT_PART3
      , MIN_INV
      , MIN_BATCH_SZ
      , ALT_PART2
      , ALT_PART1
      , MFG_LEAD_TIME
      , YTD_SALES_DOL
      , ADD_DATE
      , OE_MSG_ID
      , PLATFORM_TYPE
      , LONG_DESC9
      , LONG_DESC8
      , REINFORMIX_DAYS
      , LONG_DESC5
      , STD_BURDEN
      , LONG_DESC4
      , PRIC_TYPE
      , LONG_DESC7
      , LONG_DESC6
      , YTD_PUR_DOL
      , LCHFLD2
      , RPTUOM
      , LCHFLD1
      , PART_WT
      , LCHFLD4
      , LCHFLD3
      , FREIGHT_CLASS
      , STATUS_DATE
      , CSRUN
      , LCHFLD5
      , YTD_SALES_UNIT
      , PART_COST_BURDEN
      , SIM_COST
      , PART_DTYPE
      , STD_FIXED_BURDEN
      , PACK_HEIGHT
      , STD_MATL
      , DIR_SHIP_FLAG
      , MODEL_PKG_NUMB
      , WAVE_PICK
      , MRP_INCLUDE
      , GROS_WT
      , SIM_COST_LABOR
      , COST_NO4
      , COST_NO3
      , INACT_RSN_CODE
      , COST_NO6
      , COST_NO5
      , PART_LENGTH
      , SPEC_SHEET
      , SIM_VARIABLE_BURDEN
      , LOT_GROUP
      , USAGE
      , MFG_PRIOR
      , VERSION_NUMBER
      , LYR_SALES_UNIT
      , FIXED_BURDEN
      , YTD_PUR_UNIT
      , SIM_COST_MATL
      , BAG_PLT
      , COMMODITY_CODE
      , SW_LICENSE_CODE
      , PART_WIDTH
      , PART_DDATE
      , BUYER_CODE
      , LONG_DESC1
      , SIM_FIXED_BURDEN
      , ACCUM_MATL
      , LONG_DESC3
      , LONG_DESC2
      , LYR_PUR_DOL
      , PART_COST
      , REP_PART
      , UPDATE_USER
      , SER_ON_SHIP
      , SIM_COST_BURDEN
      , STD_LABOR
      , RESP_BSN_UNIT
      , PALLET_WGT
      , PART_PRICE
      , SETUPDATE
      , PART_SUBGRP2
      , PART_SUBGRP3
      , PALLET_TYPE
      , COST_NO2
      , COST_NO1
      , ACCUM_STD_BURDEN
      , ACCUM_STD_LABOR
      , STD_COST
      , MAX_INV
      , WARRANTY_CODE
      , LYR_PUR_UNIT
      , LEAD_DAYS
      , MAX_WO_SZ
      , LOT_REQ
      , UPDATE_DATE
      , PUOM
      , DTFLD1
      , NUMFLD1
      , NUMFLD2
      , SPEC_DOCID
      , NUMFLD3
      , DTFLD4
      , NUMFLD4
      , PACK_WEIGHT
      , CATCH_WT
      , NUMFLD5
      , DTFLD5
      , DTFLD2
      , DTFLD3
      , WARRANTY_DAYS
      , DOWNGRADE_GRP
      , LANGUAGE_CODE
      , ASSEMBLED
      , AUTO_HOLD
      , SCHED_GRP
      , RETEST_DAYS
      , TAX_CATEGORY
      , SERVICE
      , SHIPUOM
      , ECOM_INCL
      , ACCUM_SIM_LABOR
      , ROYALTY_CODE
      , CORE_INDICATOR
      , MSG_ID
      , SELLABLE
      , PART_DESC
      , INSTALL_INST
      , PART_COST_LABOR
      , LYR_SALES_DOL
      , SPECIAL_QUOTE
      , ACCUM_LABOR
      , ACCUM_SIM_MATL
      , INST_DOCID
      , SETUPUSER
      , MTO_FLAG
      , BATCH_SIZE
      , MAKE_BUY
      , SAFETY_STOCK
      , SCHFLD1
      , PART_SUBGRP
      , SCHFLD3
      , SCHFLD2
      , ACCUM_SIM_BURDEN
      , WIN
      , SCHFLD5
      , PACK_WIDTH
      , SCHFLD4
      , SERIALIZED
      , PACK_LENGTH
      , CONFIG_GRP
      , DOC_IMAGE_NUMB
      , PREF_FLG
      , MAX_WO_PDAY
      , MFG_UOM
      , PALLET_STACK
      , CYCLE_TIME
      , MEDIA_CODE
      , CYCLE_GRP
      , SETUP_CHRG_FLAG
      , PART_HEIGHT
      , PROD_MSG_ID
      , LONG_DESC10
      , TECH_LEVEL
      , VARIABLE_BURDEN
      , ORDUOM
      , SALE_TYPE
      , ACCUM_BURDEN
      , UOM
      , INVCTL_GRP
      , PART_GRP
      , BAG_WGT
      , ACCUM_STD_MATL
      , DOC_IMAGE_FOLDER
      , SHELF_LIFE
      , DOC_IMAGE_PAGE
      , STD_VARIABLE_BURDEN
      , YTD_PUR_STD
      , STORAGE_TYPE
      , COST_MATL
      , COST_METH
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , PLANT_BK
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
    WHERE rec_src = 'USOHMA.ORCL.E21PRD.WHSPRMSTR'
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
        , COST_CTR
        , PART_CODE
        , PART_TYPE
        , LAST_COST
        , PART_STATUS
        , KIT_FLAG
        , TAXABLE
        , ADD_USER
        , ALT_PART4
        , ALT_PART3
        , MIN_INV
        , MIN_BATCH_SZ
        , ALT_PART2
        , ALT_PART1
        , MFG_LEAD_TIME
        , YTD_SALES_DOL
        , ADD_DATE
        , OE_MSG_ID
        , PLATFORM_TYPE
        , LONG_DESC9
        , LONG_DESC8
        , REINFORMIX_DAYS
        , LONG_DESC5
        , STD_BURDEN
        , LONG_DESC4
        , PRIC_TYPE
        , LONG_DESC7
        , LONG_DESC6
        , YTD_PUR_DOL
        , LCHFLD2
        , RPTUOM
        , LCHFLD1
        , PART_WT
        , LCHFLD4
        , LCHFLD3
        , FREIGHT_CLASS
        , STATUS_DATE
        , CSRUN
        , LCHFLD5
        , YTD_SALES_UNIT
        , PART_COST_BURDEN
        , SIM_COST
        , PART_DTYPE
        , STD_FIXED_BURDEN
        , PACK_HEIGHT
        , STD_MATL
        , DIR_SHIP_FLAG
        , MODEL_PKG_NUMB
        , WAVE_PICK
        , MRP_INCLUDE
        , GROS_WT
        , SIM_COST_LABOR
        , COST_NO4
        , COST_NO3
        , INACT_RSN_CODE
        , COST_NO6
        , COST_NO5
        , PART_LENGTH
        , SPEC_SHEET
        , SIM_VARIABLE_BURDEN
        , LOT_GROUP
        , USAGE
        , MFG_PRIOR
        , VERSION_NUMBER
        , LYR_SALES_UNIT
        , FIXED_BURDEN
        , YTD_PUR_UNIT
        , SIM_COST_MATL
        , BAG_PLT
        , COMMODITY_CODE
        , SW_LICENSE_CODE
        , PART_WIDTH
        , PART_DDATE
        , BUYER_CODE
        , LONG_DESC1
        , SIM_FIXED_BURDEN
        , ACCUM_MATL
        , LONG_DESC3
        , LONG_DESC2
        , LYR_PUR_DOL
        , PART_COST
        , REP_PART
        , UPDATE_USER
        , SER_ON_SHIP
        , SIM_COST_BURDEN
        , STD_LABOR
        , RESP_BSN_UNIT
        , PALLET_WGT
        , PART_PRICE
        , SETUPDATE
        , PART_SUBGRP2
        , PART_SUBGRP3
        , PALLET_TYPE
        , COST_NO2
        , COST_NO1
        , ACCUM_STD_BURDEN
        , ACCUM_STD_LABOR
        , STD_COST
        , MAX_INV
        , WARRANTY_CODE
        , LYR_PUR_UNIT
        , LEAD_DAYS
        , MAX_WO_SZ
        , LOT_REQ
        , UPDATE_DATE
        , PUOM
        , DTFLD1
        , NUMFLD1
        , NUMFLD2
        , SPEC_DOCID
        , NUMFLD3
        , DTFLD4
        , NUMFLD4
        , PACK_WEIGHT
        , CATCH_WT
        , NUMFLD5
        , DTFLD5
        , DTFLD2
        , DTFLD3
        , WARRANTY_DAYS
        , DOWNGRADE_GRP
        , LANGUAGE_CODE
        , ASSEMBLED
        , AUTO_HOLD
        , SCHED_GRP
        , RETEST_DAYS
        , TAX_CATEGORY
        , SERVICE
        , SHIPUOM
        , ECOM_INCL
        , ACCUM_SIM_LABOR
        , ROYALTY_CODE
        , CORE_INDICATOR
        , MSG_ID
        , SELLABLE
        , PART_DESC
        , INSTALL_INST
        , PART_COST_LABOR
        , LYR_SALES_DOL
        , SPECIAL_QUOTE
        , ACCUM_LABOR
        , ACCUM_SIM_MATL
        , INST_DOCID
        , SETUPUSER
        , MTO_FLAG
        , BATCH_SIZE
        , MAKE_BUY
        , SAFETY_STOCK
        , SCHFLD1
        , PART_SUBGRP
        , SCHFLD3
        , SCHFLD2
        , ACCUM_SIM_BURDEN
        , WIN
        , SCHFLD5
        , PACK_WIDTH
        , SCHFLD4
        , SERIALIZED
        , PACK_LENGTH
        , CONFIG_GRP
        , DOC_IMAGE_NUMB
        , PREF_FLG
        , MAX_WO_PDAY
        , MFG_UOM
        , PALLET_STACK
        , CYCLE_TIME
        , MEDIA_CODE
        , CYCLE_GRP
        , SETUP_CHRG_FLAG
        , PART_HEIGHT
        , PROD_MSG_ID
        , LONG_DESC10
        , TECH_LEVEL
        , VARIABLE_BURDEN
        , ORDUOM
        , SALE_TYPE
        , ACCUM_BURDEN
        , UOM
        , INVCTL_GRP
        , PART_GRP
        , BAG_WGT
        , ACCUM_STD_MATL
        , DOC_IMAGE_FOLDER
        , SHELF_LIFE
        , DOC_IMAGE_PAGE
        , STD_VARIABLE_BURDEN
        , YTD_PUR_STD
        , STORAGE_TYPE
        , COST_MATL
        , COST_METH
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , _FIVETRAN_ID
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , PLANT_BK
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
              IFNULL(TRIM(COST_CTR::text), '^^') 
            , '||', IFNULL(TRIM(PART_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PART_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_COST::text), '^^') 
            , '||', IFNULL(TRIM(PART_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(KIT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(TAXABLE::text), '^^') 
            , '||', IFNULL(TRIM(ADD_USER::text), '^^') 
            , '||', IFNULL(TRIM(ALT_PART4::text), '^^') 
            , '||', IFNULL(TRIM(ALT_PART3::text), '^^') 
            , '||', IFNULL(TRIM(MIN_INV::text), '^^') 
            , '||', IFNULL(TRIM(MIN_BATCH_SZ::text), '^^') 
            , '||', IFNULL(TRIM(ALT_PART2::text), '^^') 
            , '||', IFNULL(TRIM(ALT_PART1::text), '^^') 
            , '||', IFNULL(TRIM(MFG_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(YTD_SALES_DOL::text), '^^') 
            , '||', IFNULL(TRIM(ADD_DATE::text), '^^') 
            , '||', IFNULL(TRIM(OE_MSG_ID::text), '^^') 
            , '||', IFNULL(TRIM(PLATFORM_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(LONG_DESC9::text), '^^') 
            , '||', IFNULL(TRIM(LONG_DESC8::text), '^^') 
            , '||', IFNULL(TRIM(REINFORMIX_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(LONG_DESC5::text), '^^') 
            , '||', IFNULL(TRIM(STD_BURDEN::text), '^^') 
            , '||', IFNULL(TRIM(LONG_DESC4::text), '^^') 
            , '||', IFNULL(TRIM(PRIC_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(LONG_DESC7::text), '^^') 
            , '||', IFNULL(TRIM(LONG_DESC6::text), '^^') 
            , '||', IFNULL(TRIM(YTD_PUR_DOL::text), '^^') 
            , '||', IFNULL(TRIM(LCHFLD2::text), '^^') 
            , '||', IFNULL(TRIM(RPTUOM::text), '^^') 
            , '||', IFNULL(TRIM(LCHFLD1::text), '^^') 
            , '||', IFNULL(TRIM(PART_WT::text), '^^') 
            , '||', IFNULL(TRIM(LCHFLD4::text), '^^') 
            , '||', IFNULL(TRIM(LCHFLD3::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(STATUS_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CSRUN::text), '^^') 
            , '||', IFNULL(TRIM(LCHFLD5::text), '^^') 
            , '||', IFNULL(TRIM(YTD_SALES_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(PART_COST_BURDEN::text), '^^') 
            , '||', IFNULL(TRIM(SIM_COST::text), '^^') 
            , '||', IFNULL(TRIM(PART_DTYPE::text), '^^') 
            , '||', IFNULL(TRIM(STD_FIXED_BURDEN::text), '^^') 
            , '||', IFNULL(TRIM(PACK_HEIGHT::text), '^^') 
            , '||', IFNULL(TRIM(STD_MATL::text), '^^') 
            , '||', IFNULL(TRIM(DIR_SHIP_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(MODEL_PKG_NUMB::text), '^^') 
            , '||', IFNULL(TRIM(WAVE_PICK::text), '^^') 
            , '||', IFNULL(TRIM(MRP_INCLUDE::text), '^^') 
            , '||', IFNULL(TRIM(GROS_WT::text), '^^') 
            , '||', IFNULL(TRIM(SIM_COST_LABOR::text), '^^') 
            , '||', IFNULL(TRIM(COST_NO4::text), '^^') 
            , '||', IFNULL(TRIM(COST_NO3::text), '^^') 
            , '||', IFNULL(TRIM(INACT_RSN_CODE::text), '^^') 
            , '||', IFNULL(TRIM(COST_NO6::text), '^^') 
            , '||', IFNULL(TRIM(COST_NO5::text), '^^') 
            , '||', IFNULL(TRIM(PART_LENGTH::text), '^^') 
            , '||', IFNULL(TRIM(SPEC_SHEET::text), '^^') 
            , '||', IFNULL(TRIM(SIM_VARIABLE_BURDEN::text), '^^') 
            , '||', IFNULL(TRIM(LOT_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(USAGE::text), '^^') 
            , '||', IFNULL(TRIM(MFG_PRIOR::text), '^^') 
            , '||', IFNULL(TRIM(VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(LYR_SALES_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(FIXED_BURDEN::text), '^^') 
            , '||', IFNULL(TRIM(YTD_PUR_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(SIM_COST_MATL::text), '^^') 
            , '||', IFNULL(TRIM(BAG_PLT::text), '^^') 
            , '||', IFNULL(TRIM(COMMODITY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SW_LICENSE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PART_WIDTH::text), '^^') 
            , '||', IFNULL(TRIM(PART_DDATE::text), '^^') 
            , '||', IFNULL(TRIM(BUYER_CODE::text), '^^') 
            , '||', IFNULL(TRIM(LONG_DESC1::text), '^^') 
            , '||', IFNULL(TRIM(SIM_FIXED_BURDEN::text), '^^') 
            , '||', IFNULL(TRIM(ACCUM_MATL::text), '^^') 
            , '||', IFNULL(TRIM(LONG_DESC3::text), '^^') 
            , '||', IFNULL(TRIM(LONG_DESC2::text), '^^') 
            , '||', IFNULL(TRIM(LYR_PUR_DOL::text), '^^') 
            , '||', IFNULL(TRIM(PART_COST::text), '^^') 
            , '||', IFNULL(TRIM(REP_PART::text), '^^') 
            , '||', IFNULL(TRIM(UPDATE_USER::text), '^^') 
            , '||', IFNULL(TRIM(SER_ON_SHIP::text), '^^') 
            , '||', IFNULL(TRIM(SIM_COST_BURDEN::text), '^^') 
            , '||', IFNULL(TRIM(STD_LABOR::text), '^^') 
            , '||', IFNULL(TRIM(RESP_BSN_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(PALLET_WGT::text), '^^') 
            , '||', IFNULL(TRIM(PART_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(SETUPDATE::text), '^^') 
            , '||', IFNULL(TRIM(PART_SUBGRP2::text), '^^') 
            , '||', IFNULL(TRIM(PART_SUBGRP3::text), '^^') 
            , '||', IFNULL(TRIM(PALLET_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(COST_NO2::text), '^^') 
            , '||', IFNULL(TRIM(COST_NO1::text), '^^') 
            , '||', IFNULL(TRIM(ACCUM_STD_BURDEN::text), '^^') 
            , '||', IFNULL(TRIM(ACCUM_STD_LABOR::text), '^^') 
            , '||', IFNULL(TRIM(STD_COST::text), '^^') 
            , '||', IFNULL(TRIM(MAX_INV::text), '^^') 
            , '||', IFNULL(TRIM(WARRANTY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(LYR_PUR_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(LEAD_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(MAX_WO_SZ::text), '^^') 
            , '||', IFNULL(TRIM(LOT_REQ::text), '^^') 
            , '||', IFNULL(TRIM(UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PUOM::text), '^^') 
            , '||', IFNULL(TRIM(DTFLD1::text), '^^') 
            , '||', IFNULL(TRIM(NUMFLD1::text), '^^') 
            , '||', IFNULL(TRIM(NUMFLD2::text), '^^') 
            , '||', IFNULL(TRIM(SPEC_DOCID::text), '^^') 
            , '||', IFNULL(TRIM(NUMFLD3::text), '^^') 
            , '||', IFNULL(TRIM(DTFLD4::text), '^^') 
            , '||', IFNULL(TRIM(NUMFLD4::text), '^^') 
            , '||', IFNULL(TRIM(PACK_WEIGHT::text), '^^') 
            , '||', IFNULL(TRIM(CATCH_WT::text), '^^') 
            , '||', IFNULL(TRIM(NUMFLD5::text), '^^') 
            , '||', IFNULL(TRIM(DTFLD5::text), '^^') 
            , '||', IFNULL(TRIM(DTFLD2::text), '^^') 
            , '||', IFNULL(TRIM(DTFLD3::text), '^^') 
            , '||', IFNULL(TRIM(WARRANTY_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(DOWNGRADE_GRP::text), '^^') 
            , '||', IFNULL(TRIM(LANGUAGE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ASSEMBLED::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_HOLD::text), '^^') 
            , '||', IFNULL(TRIM(SCHED_GRP::text), '^^') 
            , '||', IFNULL(TRIM(RETEST_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(SERVICE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPUOM::text), '^^') 
            , '||', IFNULL(TRIM(ECOM_INCL::text), '^^') 
            , '||', IFNULL(TRIM(ACCUM_SIM_LABOR::text), '^^') 
            , '||', IFNULL(TRIM(ROYALTY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CORE_INDICATOR::text), '^^') 
            , '||', IFNULL(TRIM(MSG_ID::text), '^^') 
            , '||', IFNULL(TRIM(SELLABLE::text), '^^') 
            , '||', IFNULL(TRIM(PART_DESC::text), '^^') 
            , '||', IFNULL(TRIM(INSTALL_INST::text), '^^') 
            , '||', IFNULL(TRIM(PART_COST_LABOR::text), '^^') 
            , '||', IFNULL(TRIM(LYR_SALES_DOL::text), '^^') 
            , '||', IFNULL(TRIM(SPECIAL_QUOTE::text), '^^') 
            , '||', IFNULL(TRIM(ACCUM_LABOR::text), '^^') 
            , '||', IFNULL(TRIM(ACCUM_SIM_MATL::text), '^^') 
            , '||', IFNULL(TRIM(INST_DOCID::text), '^^') 
            , '||', IFNULL(TRIM(SETUPUSER::text), '^^') 
            , '||', IFNULL(TRIM(MTO_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(BATCH_SIZE::text), '^^') 
            , '||', IFNULL(TRIM(MAKE_BUY::text), '^^') 
            , '||', IFNULL(TRIM(SAFETY_STOCK::text), '^^') 
            , '||', IFNULL(TRIM(SCHFLD1::text), '^^') 
            , '||', IFNULL(TRIM(PART_SUBGRP::text), '^^') 
            , '||', IFNULL(TRIM(SCHFLD3::text), '^^') 
            , '||', IFNULL(TRIM(SCHFLD2::text), '^^') 
            , '||', IFNULL(TRIM(ACCUM_SIM_BURDEN::text), '^^') 
            , '||', IFNULL(TRIM(WIN::text), '^^') 
            , '||', IFNULL(TRIM(SCHFLD5::text), '^^') 
            , '||', IFNULL(TRIM(PACK_WIDTH::text), '^^') 
            , '||', IFNULL(TRIM(SCHFLD4::text), '^^') 
            , '||', IFNULL(TRIM(SERIALIZED::text), '^^') 
            , '||', IFNULL(TRIM(PACK_LENGTH::text), '^^') 
            , '||', IFNULL(TRIM(CONFIG_GRP::text), '^^') 
            , '||', IFNULL(TRIM(DOC_IMAGE_NUMB::text), '^^') 
            , '||', IFNULL(TRIM(PREF_FLG::text), '^^') 
            , '||', IFNULL(TRIM(MAX_WO_PDAY::text), '^^') 
            , '||', IFNULL(TRIM(MFG_UOM::text), '^^') 
            , '||', IFNULL(TRIM(PALLET_STACK::text), '^^') 
            , '||', IFNULL(TRIM(CYCLE_TIME::text), '^^') 
            , '||', IFNULL(TRIM(MEDIA_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CYCLE_GRP::text), '^^') 
            , '||', IFNULL(TRIM(SETUP_CHRG_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PART_HEIGHT::text), '^^') 
            , '||', IFNULL(TRIM(PROD_MSG_ID::text), '^^') 
            , '||', IFNULL(TRIM(LONG_DESC10::text), '^^') 
            , '||', IFNULL(TRIM(TECH_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(VARIABLE_BURDEN::text), '^^') 
            , '||', IFNULL(TRIM(ORDUOM::text), '^^') 
            , '||', IFNULL(TRIM(SALE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ACCUM_BURDEN::text), '^^') 
            , '||', IFNULL(TRIM(UOM::text), '^^') 
            , '||', IFNULL(TRIM(INVCTL_GRP::text), '^^') 
            , '||', IFNULL(TRIM(PART_GRP::text), '^^') 
            , '||', IFNULL(TRIM(BAG_WGT::text), '^^') 
            , '||', IFNULL(TRIM(ACCUM_STD_MATL::text), '^^') 
            , '||', IFNULL(TRIM(DOC_IMAGE_FOLDER::text), '^^') 
            , '||', IFNULL(TRIM(SHELF_LIFE::text), '^^') 
            , '||', IFNULL(TRIM(DOC_IMAGE_PAGE::text), '^^') 
            , '||', IFNULL(TRIM(STD_VARIABLE_BURDEN::text), '^^') 
            , '||', IFNULL(TRIM(YTD_PUR_STD::text), '^^') 
            , '||', IFNULL(TRIM(STORAGE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(COST_MATL::text), '^^') 
            , '||', IFNULL(TRIM(COST_METH::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
