---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('tt_e21prd_e21trubis', 'partmstr') }} as SRC 
                        /* The following qualify clause is required to pick the latest change 
                        for driving keys that create duplicate hash-keys due to leading and lagging spaces within the field Ex. PART_CODE ='CW12MSBASE' */
                         qualify 1= row_number() over(partition by trim(part_code), _fivetran_synced order by  _fivetran_synced desc, length(part_code)) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM tt_e21prd_e21trubis.partmstr )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        coalesce(nullif(trim(PART_CODE), ''), '-1')                  as                                            ITEM_BK
      , PART_CODE
      , PART_TYPE
      , LAST_COST
      , PART_STATUS
      , KIT_FLAG
      , TAXABLE
      , ADD_USER
      , ALT_PART4
      , MIN_INV
      , ALT_PART3
      , MIN_BATCH_SZ
      , ALT_PART2
      , ALT_PART1
      , YTD_SALES_DOL
      , MFG_LEAD_TIME
      , ADD_DATE
      , PLATFORM_TYPE
      , STD_BURDEN
      , PRIC_TYPE
      , LCHFLD2
      , LCHFLD1
      , LCHFLD4
      , LCHFLD3
      , FREIGHT_CLASS
      , CSRUN
      , LCHFLD5
      , YTD_SALES_UNIT
      , SIM_COST
      , PART_DTYPE
      , DIR_SHIP_FLAG
      , MODEL_PKG_NUMB
      , WAVE_PICK
      , SIM_COST_LABOR
      , COST_NO4
      , PART_SEGMENT
      , COST_NO3
      , COST_NO6
      , COST_NO5
      , SPEC_SHEET
      , PART_LENGTH
      , VERSION_NUMBER
      , YTD_PUR_UNIT
      , COMMODITY_CODE
      , SW_LICENSE_CODE
      , REP_PART
      , UPDATE_USER
      , SER_ON_SHIP
      , SIM_COST_BURDEN
      , PALLET_WGT
      , PART_SUBGRP2
      , PALLET_TYPE
      , PART_SUBGRP3
      , COST_NO2
      , COST_NO1
      , STD_COST
      , LEAD_DAYS
      , MAX_WO_SZ
      , UPDATE_DATE
      , PUOM
      , DTFLD1
      , DTFLD4
      , CATCH_WT
      , DTFLD5
      , DTFLD2
      , DTFLD3
      , LANGUAGE_CODE
      , ASSEMBLED
      , SHIPUOM
      , MSG_ID
      , ROYALTY_CODE
      , PART_DESC
      , SPECIAL_QUOTE
      , LYR_SALES_DOL
      , ACCUM_SIM_MATL
      , SETUPUSER
      , BATCH_SIZE
      , SCHFLD1
      , SAFETY_STOCK
      , SCHFLD3
      , SCHFLD2
      , PACK_WIDTH
      , SCHFLD5
      , SCHFLD4
      , SERIALIZED
      , CONFIG_GRP
      , PALLET_STACK
      , CYCLE_TIME
      , CYCLE_GRP
      , PART_HEIGHT
      , ACCUM_BURDEN
      , UOM
      , INVCTL_GRP
      , BAG_WGT
      , DOC_IMAGE_PAGE
      , COST_METH
      , PLAN_PART_SGRP3
      , PLAN_PART_SGRP2
      , OE_MSG_ID
      , LONG_DESC9
      , LONG_DESC8
      , LONG_DESC5
      , LONG_DESC4
      , LONG_DESC7
      , YTD_PUR_DOL
      , LONG_DESC6
      , PART_WT
      , RPTUOM
      , UPC_FLAG
      , STATUS_DATE
      , NPR_LAUNCH_TYPE_CORP
      , TT_DIMENSION
      , PART_COST_BURDEN
      , PACK_HEIGHT
      , STD_MATL
      , TT_SHAPE
      , MRP_INCLUDE
      , GROS_WT
      , INACT_RSN_CODE
      , LOT_GROUP
      , USAGE
      , LYR_SALES_UNIT
      , SIM_COST_MATL
      , BAG_PLT
      , PART_WIDTH
      , BUYER_CODE
      , PART_DDATE
      , LONG_DESC1
      , ACCUM_MATL
      , LONG_DESC3
      , LONG_DESC2
      , LYR_PUR_DOL
      , PART_COST
      , STD_LABOR
      , CONFIG_REL
      , RESP_BSN_UNIT
      , SETUPDATE
      , PART_PRICE
      , ACCUM_STD_BURDEN
      , MAX_INV
      , ACCUM_STD_LABOR
      , LYR_PUR_UNIT
      , WARRANTY_CODE
      , LOT_REQ
      , NUMFLD1
      , NUMFLD2
      , SPEC_DOCID
      , NUMFLD3
      , PACK_WEIGHT
      , NUMFLD4
      , NUMFLD5
      , PLAN_PART_SGRP
      , WARRANTY_DAYS
      , DOWNGRADE_GRP
      , AUTO_HOLD
      , SCHED_GRP
      , RETEST_DAYS
      , TAX_CATEGORY
      , SERVICE
      , TT_COLOR
      , ECOM_INCL
      , ACCUM_SIM_LABOR
      , CORE_INDICATOR
      , SELLABLE
      , UPC_CODE
      , INSTALL_INST
      , PART_COST_LABOR
      , ACCUM_LABOR
      , INST_DOCID
      , MTO_FLAG
      , MAKE_BUY
      , BASE_PART_FLAG
      , PART_SUBGRP
      , ACCUM_SIM_BURDEN
      , WIN
      , PACK_LENGTH
      , PREF_FLG
      , DOC_IMAGE_NUMB
      , MFG_UOM
      , MAX_WO_PDAY
      , MEDIA_CODE
      , CONFIG_PART
      , SETUP_CHRG_FLAG
      , PROD_MSG_ID
      , LONG_DESC10
      , NPR_RELEASE_DATE_CORP
      , PLAN_PART_GRP
      , TECH_LEVEL
      , ORDUOM
      , SALE_TYPE
      , PART_GRP
      , ACCUM_STD_MATL
      , SHELF_LIFE
      , DOC_IMAGE_FOLDER
      , YTD_PUR_STD
      , STORAGE_TYPE
      , COST_MATL
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
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
      , PART_CODE
      , PART_TYPE
      , LAST_COST
      , PART_STATUS
      , KIT_FLAG
      , TAXABLE
      , ADD_USER
      , ALT_PART4
      , MIN_INV
      , ALT_PART3
      , MIN_BATCH_SZ
      , ALT_PART2
      , ALT_PART1
      , YTD_SALES_DOL
      , MFG_LEAD_TIME
      , ADD_DATE
      , PLATFORM_TYPE
      , STD_BURDEN
      , PRIC_TYPE
      , LCHFLD2
      , LCHFLD1
      , LCHFLD4
      , LCHFLD3
      , FREIGHT_CLASS
      , CSRUN
      , LCHFLD5
      , YTD_SALES_UNIT
      , SIM_COST
      , PART_DTYPE
      , DIR_SHIP_FLAG
      , MODEL_PKG_NUMB
      , WAVE_PICK
      , SIM_COST_LABOR
      , COST_NO4
      , PART_SEGMENT
      , COST_NO3
      , COST_NO6
      , COST_NO5
      , SPEC_SHEET
      , PART_LENGTH
      , VERSION_NUMBER
      , YTD_PUR_UNIT
      , COMMODITY_CODE
      , SW_LICENSE_CODE
      , REP_PART
      , UPDATE_USER
      , SER_ON_SHIP
      , SIM_COST_BURDEN
      , PALLET_WGT
      , PART_SUBGRP2
      , PALLET_TYPE
      , PART_SUBGRP3
      , COST_NO2
      , COST_NO1
      , STD_COST
      , LEAD_DAYS
      , MAX_WO_SZ
      , UPDATE_DATE
      , PUOM
      , DTFLD1
      , DTFLD4
      , CATCH_WT
      , DTFLD5
      , DTFLD2
      , DTFLD3
      , LANGUAGE_CODE
      , ASSEMBLED
      , SHIPUOM
      , MSG_ID
      , ROYALTY_CODE
      , PART_DESC
      , SPECIAL_QUOTE
      , LYR_SALES_DOL
      , ACCUM_SIM_MATL
      , SETUPUSER
      , BATCH_SIZE
      , SCHFLD1
      , SAFETY_STOCK
      , SCHFLD3
      , SCHFLD2
      , PACK_WIDTH
      , SCHFLD5
      , SCHFLD4
      , SERIALIZED
      , CONFIG_GRP
      , PALLET_STACK
      , CYCLE_TIME
      , CYCLE_GRP
      , PART_HEIGHT
      , ACCUM_BURDEN
      , UOM
      , INVCTL_GRP
      , BAG_WGT
      , DOC_IMAGE_PAGE
      , COST_METH
      , PLAN_PART_SGRP3
      , PLAN_PART_SGRP2
      , OE_MSG_ID
      , LONG_DESC9
      , LONG_DESC8
      , LONG_DESC5
      , LONG_DESC4
      , LONG_DESC7
      , YTD_PUR_DOL
      , LONG_DESC6
      , PART_WT
      , RPTUOM
      , UPC_FLAG
      , STATUS_DATE
      , NPR_LAUNCH_TYPE_CORP
      , TT_DIMENSION
      , PART_COST_BURDEN
      , PACK_HEIGHT
      , STD_MATL
      , TT_SHAPE
      , MRP_INCLUDE
      , GROS_WT
      , INACT_RSN_CODE
      , LOT_GROUP
      , USAGE
      , LYR_SALES_UNIT
      , SIM_COST_MATL
      , BAG_PLT
      , PART_WIDTH
      , BUYER_CODE
      , PART_DDATE
      , LONG_DESC1
      , ACCUM_MATL
      , LONG_DESC3
      , LONG_DESC2
      , LYR_PUR_DOL
      , PART_COST
      , STD_LABOR
      , CONFIG_REL
      , RESP_BSN_UNIT
      , SETUPDATE
      , PART_PRICE
      , ACCUM_STD_BURDEN
      , MAX_INV
      , ACCUM_STD_LABOR
      , LYR_PUR_UNIT
      , WARRANTY_CODE
      , LOT_REQ
      , NUMFLD1
      , NUMFLD2
      , SPEC_DOCID
      , NUMFLD3
      , PACK_WEIGHT
      , NUMFLD4
      , NUMFLD5
      , PLAN_PART_SGRP
      , WARRANTY_DAYS
      , DOWNGRADE_GRP
      , AUTO_HOLD
      , SCHED_GRP
      , RETEST_DAYS
      , TAX_CATEGORY
      , SERVICE
      , TT_COLOR
      , ECOM_INCL
      , ACCUM_SIM_LABOR
      , CORE_INDICATOR
      , SELLABLE
      , UPC_CODE
      , INSTALL_INST
      , PART_COST_LABOR
      , ACCUM_LABOR
      , INST_DOCID
      , MTO_FLAG
      , MAKE_BUY
      , BASE_PART_FLAG
      , PART_SUBGRP
      , ACCUM_SIM_BURDEN
      , WIN
      , PACK_LENGTH
      , PREF_FLG
      , DOC_IMAGE_NUMB
      , MFG_UOM
      , MAX_WO_PDAY
      , MEDIA_CODE
      , CONFIG_PART
      , SETUP_CHRG_FLAG
      , PROD_MSG_ID
      , LONG_DESC10
      , NPR_RELEASE_DATE_CORP
      , PLAN_PART_GRP
      , TECH_LEVEL
      , ORDUOM
      , SALE_TYPE
      , PART_GRP
      , ACCUM_STD_MATL
      , SHELF_LIFE
      , DOC_IMAGE_FOLDER
      , YTD_PUR_STD
      , STORAGE_TYPE
      , COST_MATL
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
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
    WHERE rec_src = 'USOHMA.ORCL.E21PRD.PARTMSTR'
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
        , PART_CODE
        , PART_TYPE
        , LAST_COST
        , PART_STATUS
        , KIT_FLAG
        , TAXABLE
        , ADD_USER
        , ALT_PART4
        , MIN_INV
        , ALT_PART3
        , MIN_BATCH_SZ
        , ALT_PART2
        , ALT_PART1
        , YTD_SALES_DOL
        , MFG_LEAD_TIME
        , ADD_DATE
        , PLATFORM_TYPE
        , STD_BURDEN
        , PRIC_TYPE
        , LCHFLD2
        , LCHFLD1
        , LCHFLD4
        , LCHFLD3
        , FREIGHT_CLASS
        , CSRUN
        , LCHFLD5
        , YTD_SALES_UNIT
        , SIM_COST
        , PART_DTYPE
        , DIR_SHIP_FLAG
        , MODEL_PKG_NUMB
        , WAVE_PICK
        , SIM_COST_LABOR
        , COST_NO4
        , PART_SEGMENT
        , COST_NO3
        , COST_NO6
        , COST_NO5
        , SPEC_SHEET
        , PART_LENGTH
        , VERSION_NUMBER
        , YTD_PUR_UNIT
        , COMMODITY_CODE
        , SW_LICENSE_CODE
        , REP_PART
        , UPDATE_USER
        , SER_ON_SHIP
        , SIM_COST_BURDEN
        , PALLET_WGT
        , PART_SUBGRP2
        , PALLET_TYPE
        , PART_SUBGRP3
        , COST_NO2
        , COST_NO1
        , STD_COST
        , LEAD_DAYS
        , MAX_WO_SZ
        , UPDATE_DATE
        , PUOM
        , DTFLD1
        , DTFLD4
        , CATCH_WT
        , DTFLD5
        , DTFLD2
        , DTFLD3
        , LANGUAGE_CODE
        , ASSEMBLED
        , SHIPUOM
        , MSG_ID
        , ROYALTY_CODE
        , PART_DESC
        , SPECIAL_QUOTE
        , LYR_SALES_DOL
        , ACCUM_SIM_MATL
        , SETUPUSER
        , BATCH_SIZE
        , SCHFLD1
        , SAFETY_STOCK
        , SCHFLD3
        , SCHFLD2
        , PACK_WIDTH
        , SCHFLD5
        , SCHFLD4
        , SERIALIZED
        , CONFIG_GRP
        , PALLET_STACK
        , CYCLE_TIME
        , CYCLE_GRP
        , PART_HEIGHT
        , ACCUM_BURDEN
        , UOM
        , INVCTL_GRP
        , BAG_WGT
        , DOC_IMAGE_PAGE
        , COST_METH
        , PLAN_PART_SGRP3
        , PLAN_PART_SGRP2
        , OE_MSG_ID
        , LONG_DESC9
        , LONG_DESC8
        , LONG_DESC5
        , LONG_DESC4
        , LONG_DESC7
        , YTD_PUR_DOL
        , LONG_DESC6
        , PART_WT
        , RPTUOM
        , UPC_FLAG
        , STATUS_DATE
        , NPR_LAUNCH_TYPE_CORP
        , TT_DIMENSION
        , PART_COST_BURDEN
        , PACK_HEIGHT
        , STD_MATL
        , TT_SHAPE
        , MRP_INCLUDE
        , GROS_WT
        , INACT_RSN_CODE
        , LOT_GROUP
        , USAGE
        , LYR_SALES_UNIT
        , SIM_COST_MATL
        , BAG_PLT
        , PART_WIDTH
        , BUYER_CODE
        , PART_DDATE
        , LONG_DESC1
        , ACCUM_MATL
        , LONG_DESC3
        , LONG_DESC2
        , LYR_PUR_DOL
        , PART_COST
        , STD_LABOR
        , CONFIG_REL
        , RESP_BSN_UNIT
        , SETUPDATE
        , PART_PRICE
        , ACCUM_STD_BURDEN
        , MAX_INV
        , ACCUM_STD_LABOR
        , LYR_PUR_UNIT
        , WARRANTY_CODE
        , LOT_REQ
        , NUMFLD1
        , NUMFLD2
        , SPEC_DOCID
        , NUMFLD3
        , PACK_WEIGHT
        , NUMFLD4
        , NUMFLD5
        , PLAN_PART_SGRP
        , WARRANTY_DAYS
        , DOWNGRADE_GRP
        , AUTO_HOLD
        , SCHED_GRP
        , RETEST_DAYS
        , TAX_CATEGORY
        , SERVICE
        , TT_COLOR
        , ECOM_INCL
        , ACCUM_SIM_LABOR
        , CORE_INDICATOR
        , SELLABLE
        , UPC_CODE
        , INSTALL_INST
        , PART_COST_LABOR
        , ACCUM_LABOR
        , INST_DOCID
        , MTO_FLAG
        , MAKE_BUY
        , BASE_PART_FLAG
        , PART_SUBGRP
        , ACCUM_SIM_BURDEN
        , WIN
        , PACK_LENGTH
        , PREF_FLG
        , DOC_IMAGE_NUMB
        , MFG_UOM
        , MAX_WO_PDAY
        , MEDIA_CODE
        , CONFIG_PART
        , SETUP_CHRG_FLAG
        , PROD_MSG_ID
        , LONG_DESC10
        , NPR_RELEASE_DATE_CORP
        , PLAN_PART_GRP
        , TECH_LEVEL
        , ORDUOM
        , SALE_TYPE
        , PART_GRP
        , ACCUM_STD_MATL
        , SHELF_LIFE
        , DOC_IMAGE_FOLDER
        , YTD_PUR_STD
        , STORAGE_TYPE
        , COST_MATL
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , _FIVETRAN_ID
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
              IFNULL(TRIM(PART_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_COST::text), '^^') 
            , '||', IFNULL(TRIM(PART_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(KIT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(TAXABLE::text), '^^') 
            , '||', IFNULL(TRIM(ADD_USER::text), '^^') 
            , '||', IFNULL(TRIM(ALT_PART4::text), '^^') 
            , '||', IFNULL(TRIM(MIN_INV::text), '^^') 
            , '||', IFNULL(TRIM(ALT_PART3::text), '^^') 
            , '||', IFNULL(TRIM(MIN_BATCH_SZ::text), '^^') 
            , '||', IFNULL(TRIM(ALT_PART2::text), '^^') 
            , '||', IFNULL(TRIM(ALT_PART1::text), '^^') 
            , '||', IFNULL(TRIM(YTD_SALES_DOL::text), '^^') 
            , '||', IFNULL(TRIM(MFG_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(ADD_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PLATFORM_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(STD_BURDEN::text), '^^') 
            , '||', IFNULL(TRIM(PRIC_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(LCHFLD2::text), '^^') 
            , '||', IFNULL(TRIM(LCHFLD1::text), '^^') 
            , '||', IFNULL(TRIM(LCHFLD4::text), '^^') 
            , '||', IFNULL(TRIM(LCHFLD3::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(CSRUN::text), '^^') 
            , '||', IFNULL(TRIM(LCHFLD5::text), '^^') 
            , '||', IFNULL(TRIM(YTD_SALES_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(SIM_COST::text), '^^') 
            , '||', IFNULL(TRIM(PART_DTYPE::text), '^^') 
            , '||', IFNULL(TRIM(DIR_SHIP_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(MODEL_PKG_NUMB::text), '^^') 
            , '||', IFNULL(TRIM(WAVE_PICK::text), '^^') 
            , '||', IFNULL(TRIM(SIM_COST_LABOR::text), '^^') 
            , '||', IFNULL(TRIM(COST_NO4::text), '^^') 
            , '||', IFNULL(TRIM(PART_SEGMENT::text), '^^') 
            , '||', IFNULL(TRIM(COST_NO3::text), '^^') 
            , '||', IFNULL(TRIM(COST_NO6::text), '^^') 
            , '||', IFNULL(TRIM(COST_NO5::text), '^^') 
            , '||', IFNULL(TRIM(SPEC_SHEET::text), '^^') 
            , '||', IFNULL(TRIM(PART_LENGTH::text), '^^') 
            , '||', IFNULL(TRIM(VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(YTD_PUR_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(COMMODITY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SW_LICENSE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(REP_PART::text), '^^') 
            , '||', IFNULL(TRIM(UPDATE_USER::text), '^^') 
            , '||', IFNULL(TRIM(SER_ON_SHIP::text), '^^') 
            , '||', IFNULL(TRIM(SIM_COST_BURDEN::text), '^^') 
            , '||', IFNULL(TRIM(PALLET_WGT::text), '^^') 
            , '||', IFNULL(TRIM(PART_SUBGRP2::text), '^^') 
            , '||', IFNULL(TRIM(PALLET_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PART_SUBGRP3::text), '^^') 
            , '||', IFNULL(TRIM(COST_NO2::text), '^^') 
            , '||', IFNULL(TRIM(COST_NO1::text), '^^') 
            , '||', IFNULL(TRIM(STD_COST::text), '^^') 
            , '||', IFNULL(TRIM(LEAD_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(MAX_WO_SZ::text), '^^') 
            , '||', IFNULL(TRIM(UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PUOM::text), '^^') 
            , '||', IFNULL(TRIM(DTFLD1::text), '^^') 
            , '||', IFNULL(TRIM(DTFLD4::text), '^^') 
            , '||', IFNULL(TRIM(CATCH_WT::text), '^^') 
            , '||', IFNULL(TRIM(DTFLD5::text), '^^') 
            , '||', IFNULL(TRIM(DTFLD2::text), '^^') 
            , '||', IFNULL(TRIM(DTFLD3::text), '^^') 
            , '||', IFNULL(TRIM(LANGUAGE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ASSEMBLED::text), '^^') 
            , '||', IFNULL(TRIM(SHIPUOM::text), '^^') 
            , '||', IFNULL(TRIM(MSG_ID::text), '^^') 
            , '||', IFNULL(TRIM(ROYALTY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PART_DESC::text), '^^') 
            , '||', IFNULL(TRIM(SPECIAL_QUOTE::text), '^^') 
            , '||', IFNULL(TRIM(LYR_SALES_DOL::text), '^^') 
            , '||', IFNULL(TRIM(ACCUM_SIM_MATL::text), '^^') 
            , '||', IFNULL(TRIM(SETUPUSER::text), '^^') 
            , '||', IFNULL(TRIM(BATCH_SIZE::text), '^^') 
            , '||', IFNULL(TRIM(SCHFLD1::text), '^^') 
            , '||', IFNULL(TRIM(SAFETY_STOCK::text), '^^') 
            , '||', IFNULL(TRIM(SCHFLD3::text), '^^') 
            , '||', IFNULL(TRIM(SCHFLD2::text), '^^') 
            , '||', IFNULL(TRIM(PACK_WIDTH::text), '^^') 
            , '||', IFNULL(TRIM(SCHFLD5::text), '^^') 
            , '||', IFNULL(TRIM(SCHFLD4::text), '^^') 
            , '||', IFNULL(TRIM(SERIALIZED::text), '^^') 
            , '||', IFNULL(TRIM(CONFIG_GRP::text), '^^') 
            , '||', IFNULL(TRIM(PALLET_STACK::text), '^^') 
            , '||', IFNULL(TRIM(CYCLE_TIME::text), '^^') 
            , '||', IFNULL(TRIM(CYCLE_GRP::text), '^^') 
            , '||', IFNULL(TRIM(PART_HEIGHT::text), '^^') 
            , '||', IFNULL(TRIM(ACCUM_BURDEN::text), '^^') 
            , '||', IFNULL(TRIM(UOM::text), '^^') 
            , '||', IFNULL(TRIM(INVCTL_GRP::text), '^^') 
            , '||', IFNULL(TRIM(BAG_WGT::text), '^^') 
            , '||', IFNULL(TRIM(DOC_IMAGE_PAGE::text), '^^') 
            , '||', IFNULL(TRIM(COST_METH::text), '^^') 
            , '||', IFNULL(TRIM(PLAN_PART_SGRP3::text), '^^') 
            , '||', IFNULL(TRIM(PLAN_PART_SGRP2::text), '^^') 
            , '||', IFNULL(TRIM(OE_MSG_ID::text), '^^') 
            , '||', IFNULL(TRIM(LONG_DESC9::text), '^^') 
            , '||', IFNULL(TRIM(LONG_DESC8::text), '^^') 
            , '||', IFNULL(TRIM(LONG_DESC5::text), '^^') 
            , '||', IFNULL(TRIM(LONG_DESC4::text), '^^') 
            , '||', IFNULL(TRIM(LONG_DESC7::text), '^^') 
            , '||', IFNULL(TRIM(YTD_PUR_DOL::text), '^^') 
            , '||', IFNULL(TRIM(LONG_DESC6::text), '^^') 
            , '||', IFNULL(TRIM(PART_WT::text), '^^') 
            , '||', IFNULL(TRIM(RPTUOM::text), '^^') 
            , '||', IFNULL(TRIM(UPC_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(STATUS_DATE::text), '^^') 
            , '||', IFNULL(TRIM(NPR_LAUNCH_TYPE_CORP::text), '^^') 
            , '||', IFNULL(TRIM(TT_DIMENSION::text), '^^') 
            , '||', IFNULL(TRIM(PART_COST_BURDEN::text), '^^') 
            , '||', IFNULL(TRIM(PACK_HEIGHT::text), '^^') 
            , '||', IFNULL(TRIM(STD_MATL::text), '^^') 
            , '||', IFNULL(TRIM(TT_SHAPE::text), '^^') 
            , '||', IFNULL(TRIM(MRP_INCLUDE::text), '^^') 
            , '||', IFNULL(TRIM(GROS_WT::text), '^^') 
            , '||', IFNULL(TRIM(INACT_RSN_CODE::text), '^^') 
            , '||', IFNULL(TRIM(LOT_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(USAGE::text), '^^') 
            , '||', IFNULL(TRIM(LYR_SALES_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(SIM_COST_MATL::text), '^^') 
            , '||', IFNULL(TRIM(BAG_PLT::text), '^^') 
            , '||', IFNULL(TRIM(PART_WIDTH::text), '^^') 
            , '||', IFNULL(TRIM(BUYER_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PART_DDATE::text), '^^') 
            , '||', IFNULL(TRIM(LONG_DESC1::text), '^^') 
            , '||', IFNULL(TRIM(ACCUM_MATL::text), '^^') 
            , '||', IFNULL(TRIM(LONG_DESC3::text), '^^') 
            , '||', IFNULL(TRIM(LONG_DESC2::text), '^^') 
            , '||', IFNULL(TRIM(LYR_PUR_DOL::text), '^^') 
            , '||', IFNULL(TRIM(PART_COST::text), '^^') 
            , '||', IFNULL(TRIM(STD_LABOR::text), '^^') 
            , '||', IFNULL(TRIM(CONFIG_REL::text), '^^') 
            , '||', IFNULL(TRIM(RESP_BSN_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(SETUPDATE::text), '^^') 
            , '||', IFNULL(TRIM(PART_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(ACCUM_STD_BURDEN::text), '^^') 
            , '||', IFNULL(TRIM(MAX_INV::text), '^^') 
            , '||', IFNULL(TRIM(ACCUM_STD_LABOR::text), '^^') 
            , '||', IFNULL(TRIM(LYR_PUR_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(WARRANTY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(LOT_REQ::text), '^^') 
            , '||', IFNULL(TRIM(NUMFLD1::text), '^^') 
            , '||', IFNULL(TRIM(NUMFLD2::text), '^^') 
            , '||', IFNULL(TRIM(SPEC_DOCID::text), '^^') 
            , '||', IFNULL(TRIM(NUMFLD3::text), '^^') 
            , '||', IFNULL(TRIM(PACK_WEIGHT::text), '^^') 
            , '||', IFNULL(TRIM(NUMFLD4::text), '^^') 
            , '||', IFNULL(TRIM(NUMFLD5::text), '^^') 
            , '||', IFNULL(TRIM(PLAN_PART_SGRP::text), '^^') 
            , '||', IFNULL(TRIM(WARRANTY_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(DOWNGRADE_GRP::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_HOLD::text), '^^') 
            , '||', IFNULL(TRIM(SCHED_GRP::text), '^^') 
            , '||', IFNULL(TRIM(RETEST_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(SERVICE::text), '^^') 
            , '||', IFNULL(TRIM(TT_COLOR::text), '^^') 
            , '||', IFNULL(TRIM(ECOM_INCL::text), '^^') 
            , '||', IFNULL(TRIM(ACCUM_SIM_LABOR::text), '^^') 
            , '||', IFNULL(TRIM(CORE_INDICATOR::text), '^^') 
            , '||', IFNULL(TRIM(SELLABLE::text), '^^') 
            , '||', IFNULL(TRIM(UPC_CODE::text), '^^') 
            , '||', IFNULL(TRIM(INSTALL_INST::text), '^^') 
            , '||', IFNULL(TRIM(PART_COST_LABOR::text), '^^') 
            , '||', IFNULL(TRIM(ACCUM_LABOR::text), '^^') 
            , '||', IFNULL(TRIM(INST_DOCID::text), '^^') 
            , '||', IFNULL(TRIM(MTO_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(MAKE_BUY::text), '^^') 
            , '||', IFNULL(TRIM(BASE_PART_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PART_SUBGRP::text), '^^') 
            , '||', IFNULL(TRIM(ACCUM_SIM_BURDEN::text), '^^') 
            , '||', IFNULL(TRIM(WIN::text), '^^') 
            , '||', IFNULL(TRIM(PACK_LENGTH::text), '^^') 
            , '||', IFNULL(TRIM(PREF_FLG::text), '^^') 
            , '||', IFNULL(TRIM(DOC_IMAGE_NUMB::text), '^^') 
            , '||', IFNULL(TRIM(MFG_UOM::text), '^^') 
            , '||', IFNULL(TRIM(MAX_WO_PDAY::text), '^^') 
            , '||', IFNULL(TRIM(MEDIA_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CONFIG_PART::text), '^^') 
            , '||', IFNULL(TRIM(SETUP_CHRG_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PROD_MSG_ID::text), '^^') 
            , '||', IFNULL(TRIM(LONG_DESC10::text), '^^') 
            , '||', IFNULL(TRIM(NPR_RELEASE_DATE_CORP::text), '^^') 
            , '||', IFNULL(TRIM(PLAN_PART_GRP::text), '^^') 
            , '||', IFNULL(TRIM(TECH_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(ORDUOM::text), '^^') 
            , '||', IFNULL(TRIM(SALE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PART_GRP::text), '^^') 
            , '||', IFNULL(TRIM(ACCUM_STD_MATL::text), '^^') 
            , '||', IFNULL(TRIM(SHELF_LIFE::text), '^^') 
            , '||', IFNULL(TRIM(DOC_IMAGE_FOLDER::text), '^^') 
            , '||', IFNULL(TRIM(YTD_PUR_STD::text), '^^') 
            , '||', IFNULL(TRIM(STORAGE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(COST_MATL::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
