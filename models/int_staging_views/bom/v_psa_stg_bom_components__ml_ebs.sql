---- SRC LAYER ----
WITH
SRC_bcid           as ( SELECT * FROM {{ source('ml_ebs_bom', 'bom_components_b') }} as SRC  ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_sitm           as ( SELECT * FROM {{ source('ml_ebs_inv', 'mtl_system_items_b') }} as SRC 
                        where organization_id = 1
                        qualify 1 = row_number()over (partition by inventory_item_id order by psa_load_dts )  )

/*
SRC_bcid           as ( SELECT * FROM ml_ebs_bom.bom_components_b )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_sitm           as ( SELECT * FROM ml_ebs_inv.mtl_system_items_b )
*/
---- LOGIC LAYER ----

, LOGIC_bcid as (
    SELECT
        to_char(BILL_SEQUENCE_ID)                                    as                                             BOM_BK
      , BILL_SEQUENCE_ID
      , UNIT_PRICE
      , PK1_VALUE
      , PROGRAM_ID
      , TO_END_ITEM_REV_ID
      , PARENT_BILL_SEQ_ID
      , TO_END_ITEM_MINOR_REV_ID
      , IMPLEMENTATION_DATE
      , WIP_SUPPLY_TYPE
      , ATTRIBUTE3
      , ATTRIBUTE2
      , ATTRIBUTE1
      , PLANNING_FACTOR
      , TO_OBJECT_REVISION_ID
      , COMPONENT_ITEM_ID
      , COMPONENT_QUANTITY
      , TO_STRUCTURE_REVISION_CODE
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , CHANGE_NOTICE
      , ATTRIBUTE5
      , ACD_TYPE
      , ATTRIBUTE4
      , COST_FACTOR
      , VENDOR_ID
      , MUTUALLY_EXCLUSIVE_OPTIONS
      , TO_MINOR_REVISION_ID
      , SUPPLY_SUBINVENTORY
      , PK4_VALUE
      , FROM_OBJECT_REVISION_ID
      , ATTRIBUTE10
      , FROM_END_ITEM_STRC_REV_ID
      , ATTRIBUTE14
      , ATTRIBUTE13
      , COMPONENT_REMARKS
      , ATTRIBUTE12
      , ATTRIBUTE11
      , BASIS_TYPE
      , CHECK_ATP
      , DELETE_GROUP_NAME
      , ORIGINAL_SYSTEM_REFERENCE
      , COMPONENT_ITEM_REVISION_ID
      , FROM_BILL_REVISION_ID
      , COMPONENT_SEQUENCE_ID
      , REQUIRED_TO_SHIP
      , ENFORCE_INT_REQUIREMENTS
      , REVISED_ITEM_SEQUENCE_ID
      , OPERATION_SEQ_NUM
      , MODEL_COMP_SEQ_ID
      , COMPONENT_YIELD_FACTOR
      , OLD_COMPONENT_SEQUENCE_ID
      , ATTRIBUTE15
      , REQUIRED_FOR_REVENUE
      , HIGH_QUANTITY
      , EFFECTIVITY_DATE
      , INCLUDE_IN_COST_ROLLUP
      , OVERLAPPING_CHANGES
      , LAST_UPDATE_DATE
      , OBJ_NAME
      , LOW_QUANTITY
      , SO_BASIS
      , OPTIONAL
      , PK5_VALUE
      , DG_DESCRIPTION
      , AUTO_REQUEST_MATERIAL
      , OPTIONAL_ON_MODEL
      , CREATED_BY
      , INCLUDE_ON_BILL_DOCS
      , LAST_UPDATED_BY
      , FROM_END_ITEM_MINOR_REV_ID
      , FROM_END_ITEM_UNIT_NUMBER
      , SUGGESTED_VENDOR_NAME
      , SHIPPING_ALLOWED
      , CREATION_DATE
      , QUANTITY_RELATED
      , PROGRAM_UPDATE_DATE
      , COMPONENT_MINOR_REVISION_ID
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , PICK_COMPONENTS
      , FROM_MINOR_REVISION_ID
      , INHERIT_FLAG
      , FROM_END_ITEM_REV_ID
      , TO_END_ITEM_STRC_REV_ID
      , INCLUDE_ON_SHIP_DOCS
      , PK3_VALUE
      , TO_BILL_REVISION_ID
      , REQUEST_ID
      , PLAN_LEVEL
      , OPERATION_LEAD_TIME_PERCENT
      , ITEM_NUM
      , DISABLE_DATE
      , FROM_STRUCTURE_REVISION_CODE
      , COMMON_COMPONENT_SEQUENCE_ID
      , SUPPLY_LOCATOR_ID
      , PK2_VALUE
      , TO_END_ITEM_UNIT_NUMBER
      , BOM_ITEM_TYPE
      , ECO_FOR_PRODUCTION
      , LAST_UPDATE_LOGIN
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
    FROM SRC_bcid
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)

, LOGIC_sitm as (
    SELECT
        SEGMENT1                                                     as                                            ITEM_BK
      , INVENTORY_ITEM_ID                                            as                             SITM_INVENTORY_ITEM_ID
    FROM SRC_sitm
)
---- RENAME LAYER ----

, RENAME_bcid as (
    SELECT
        BOM_BK
      , BILL_SEQUENCE_ID
      , UNIT_PRICE
      , PK1_VALUE
      , PROGRAM_ID
      , TO_END_ITEM_REV_ID
      , PARENT_BILL_SEQ_ID
      , TO_END_ITEM_MINOR_REV_ID
      , IMPLEMENTATION_DATE
      , WIP_SUPPLY_TYPE
      , ATTRIBUTE3
      , ATTRIBUTE2
      , ATTRIBUTE1
      , PLANNING_FACTOR
      , TO_OBJECT_REVISION_ID
      , COMPONENT_ITEM_ID
      , COMPONENT_QUANTITY
      , TO_STRUCTURE_REVISION_CODE
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , CHANGE_NOTICE
      , ATTRIBUTE5
      , ACD_TYPE
      , ATTRIBUTE4
      , COST_FACTOR
      , VENDOR_ID
      , MUTUALLY_EXCLUSIVE_OPTIONS
      , TO_MINOR_REVISION_ID
      , SUPPLY_SUBINVENTORY
      , PK4_VALUE
      , FROM_OBJECT_REVISION_ID
      , ATTRIBUTE10
      , FROM_END_ITEM_STRC_REV_ID
      , ATTRIBUTE14
      , ATTRIBUTE13
      , COMPONENT_REMARKS
      , ATTRIBUTE12
      , ATTRIBUTE11
      , BASIS_TYPE
      , CHECK_ATP
      , DELETE_GROUP_NAME
      , ORIGINAL_SYSTEM_REFERENCE
      , COMPONENT_ITEM_REVISION_ID
      , FROM_BILL_REVISION_ID
      , COMPONENT_SEQUENCE_ID
      , REQUIRED_TO_SHIP
      , ENFORCE_INT_REQUIREMENTS
      , REVISED_ITEM_SEQUENCE_ID
      , OPERATION_SEQ_NUM
      , MODEL_COMP_SEQ_ID
      , COMPONENT_YIELD_FACTOR
      , OLD_COMPONENT_SEQUENCE_ID
      , ATTRIBUTE15
      , REQUIRED_FOR_REVENUE
      , HIGH_QUANTITY
      , EFFECTIVITY_DATE
      , INCLUDE_IN_COST_ROLLUP
      , OVERLAPPING_CHANGES
      , LAST_UPDATE_DATE
      , OBJ_NAME
      , LOW_QUANTITY
      , SO_BASIS
      , OPTIONAL
      , PK5_VALUE
      , DG_DESCRIPTION
      , AUTO_REQUEST_MATERIAL
      , OPTIONAL_ON_MODEL
      , CREATED_BY
      , INCLUDE_ON_BILL_DOCS
      , LAST_UPDATED_BY
      , FROM_END_ITEM_MINOR_REV_ID
      , FROM_END_ITEM_UNIT_NUMBER
      , SUGGESTED_VENDOR_NAME
      , SHIPPING_ALLOWED
      , CREATION_DATE
      , QUANTITY_RELATED
      , PROGRAM_UPDATE_DATE
      , COMPONENT_MINOR_REVISION_ID
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , PICK_COMPONENTS
      , FROM_MINOR_REVISION_ID
      , INHERIT_FLAG
      , FROM_END_ITEM_REV_ID
      , TO_END_ITEM_STRC_REV_ID
      , INCLUDE_ON_SHIP_DOCS
      , PK3_VALUE
      , TO_BILL_REVISION_ID
      , REQUEST_ID
      , PLAN_LEVEL
      , OPERATION_LEAD_TIME_PERCENT
      , ITEM_NUM
      , DISABLE_DATE
      , FROM_STRUCTURE_REVISION_CODE
      , COMMON_COMPONENT_SEQUENCE_ID
      , SUPPLY_LOCATOR_ID
      , PK2_VALUE
      , TO_END_ITEM_UNIT_NUMBER
      , BOM_ITEM_TYPE
      , ECO_FOR_PRODUCTION
      , LAST_UPDATE_LOGIN
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_bcid
)

, RENAME_sitm as (
    SELECT
        ITEM_BK
      , SITM_INVENTORY_ITEM_ID
    FROM LOGIC_sitm
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_bcid as (
    SELECT *
    FROM RENAME_bcid
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.BOM_COMPONENTS_B'
)

, FILTER_sitm as (
    SELECT *
    FROM RENAME_sitm
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_bcid
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_sitm
        ON FILTER_bcid.component_item_id = sitm_inventory_item_id
)

---- FINAL LAYER ----
SELECT
          BOM_BK
        , BILL_SEQUENCE_ID
        , UNIT_PRICE
        , PK1_VALUE
        , PROGRAM_ID
        , TO_END_ITEM_REV_ID
        , PARENT_BILL_SEQ_ID
        , TO_END_ITEM_MINOR_REV_ID
        , IMPLEMENTATION_DATE
        , WIP_SUPPLY_TYPE
        , ATTRIBUTE3
        , ATTRIBUTE2
        , ATTRIBUTE1
        , PLANNING_FACTOR
        , TO_OBJECT_REVISION_ID
        , COMPONENT_ITEM_ID
        , COMPONENT_QUANTITY
        , TO_STRUCTURE_REVISION_CODE
        , ATTRIBUTE9
        , ATTRIBUTE8
        , ATTRIBUTE7
        , ATTRIBUTE6
        , CHANGE_NOTICE
        , ATTRIBUTE5
        , ACD_TYPE
        , ATTRIBUTE4
        , COST_FACTOR
        , VENDOR_ID
        , MUTUALLY_EXCLUSIVE_OPTIONS
        , TO_MINOR_REVISION_ID
        , SUPPLY_SUBINVENTORY
        , PK4_VALUE
        , FROM_OBJECT_REVISION_ID
        , ATTRIBUTE10
        , FROM_END_ITEM_STRC_REV_ID
        , ATTRIBUTE14
        , ATTRIBUTE13
        , COMPONENT_REMARKS
        , ATTRIBUTE12
        , ATTRIBUTE11
        , BASIS_TYPE
        , CHECK_ATP
        , DELETE_GROUP_NAME
        , ORIGINAL_SYSTEM_REFERENCE
        , COMPONENT_ITEM_REVISION_ID
        , FROM_BILL_REVISION_ID
        , COMPONENT_SEQUENCE_ID
        , REQUIRED_TO_SHIP
        , ENFORCE_INT_REQUIREMENTS
        , REVISED_ITEM_SEQUENCE_ID
        , OPERATION_SEQ_NUM
        , MODEL_COMP_SEQ_ID
        , COMPONENT_YIELD_FACTOR
        , OLD_COMPONENT_SEQUENCE_ID
        , ATTRIBUTE15
        , REQUIRED_FOR_REVENUE
        , HIGH_QUANTITY
        , EFFECTIVITY_DATE
        , INCLUDE_IN_COST_ROLLUP
        , OVERLAPPING_CHANGES
        , LAST_UPDATE_DATE
        , OBJ_NAME
        , LOW_QUANTITY
        , SO_BASIS
        , OPTIONAL
        , PK5_VALUE
        , DG_DESCRIPTION
        , AUTO_REQUEST_MATERIAL
        , OPTIONAL_ON_MODEL
        , CREATED_BY
        , INCLUDE_ON_BILL_DOCS
        , LAST_UPDATED_BY
        , FROM_END_ITEM_MINOR_REV_ID
        , FROM_END_ITEM_UNIT_NUMBER
        , SUGGESTED_VENDOR_NAME
        , SHIPPING_ALLOWED
        , CREATION_DATE
        , QUANTITY_RELATED
        , PROGRAM_UPDATE_DATE
        , COMPONENT_MINOR_REVISION_ID
        , ATTRIBUTE_CATEGORY
        , PROGRAM_APPLICATION_ID
        , PICK_COMPONENTS
        , FROM_MINOR_REVISION_ID
        , INHERIT_FLAG
        , FROM_END_ITEM_REV_ID
        , TO_END_ITEM_STRC_REV_ID
        , INCLUDE_ON_SHIP_DOCS
        , PK3_VALUE
        , TO_BILL_REVISION_ID
        , REQUEST_ID
        , PLAN_LEVEL
        , OPERATION_LEAD_TIME_PERCENT
        , ITEM_NUM
        , DISABLE_DATE
        , FROM_STRUCTURE_REVISION_CODE
        , COMMON_COMPONENT_SEQUENCE_ID
        , SUPPLY_LOCATOR_ID
        , PK2_VALUE
        , TO_END_ITEM_UNIT_NUMBER
        , BOM_ITEM_TYPE
        , ECO_FOR_PRODUCTION
        , LAST_UPDATE_LOGIN
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , ITEM_BK
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as BOM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_BOM_ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(BILL_SEQUENCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(PK1_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(TO_END_ITEM_REV_ID::text), '^^') 
            , '||', IFNULL(TRIM(PARENT_BILL_SEQ_ID::text), '^^') 
            , '||', IFNULL(TRIM(TO_END_ITEM_MINOR_REV_ID::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENTATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(WIP_SUPPLY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(PLANNING_FACTOR::text), '^^') 
            , '||', IFNULL(TRIM(TO_OBJECT_REVISION_ID::text), '^^') 
            , '||', IFNULL(TRIM(COMPONENT_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(COMPONENT_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(TO_STRUCTURE_REVISION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(CHANGE_NOTICE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(ACD_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(COST_FACTOR::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(MUTUALLY_EXCLUSIVE_OPTIONS::text), '^^') 
            , '||', IFNULL(TRIM(TO_MINOR_REVISION_ID::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLY_SUBINVENTORY::text), '^^') 
            , '||', IFNULL(TRIM(PK4_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(FROM_OBJECT_REVISION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(FROM_END_ITEM_STRC_REV_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(COMPONENT_REMARKS::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(BASIS_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(CHECK_ATP::text), '^^') 
            , '||', IFNULL(TRIM(DELETE_GROUP_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_SYSTEM_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(COMPONENT_ITEM_REVISION_ID::text), '^^') 
            , '||', IFNULL(TRIM(FROM_BILL_REVISION_ID::text), '^^') 
            , '||', IFNULL(TRIM(REQUIRED_TO_SHIP::text), '^^') 
            , '||', IFNULL(TRIM(ENFORCE_INT_REQUIREMENTS::text), '^^') 
            , '||', IFNULL(TRIM(REVISED_ITEM_SEQUENCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(OPERATION_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(MODEL_COMP_SEQ_ID::text), '^^') 
            , '||', IFNULL(TRIM(COMPONENT_YIELD_FACTOR::text), '^^') 
            , '||', IFNULL(TRIM(OLD_COMPONENT_SEQUENCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(REQUIRED_FOR_REVENUE::text), '^^') 
            , '||', IFNULL(TRIM(HIGH_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(EFFECTIVITY_DATE::text), '^^') 
            , '||', IFNULL(TRIM(INCLUDE_IN_COST_ROLLUP::text), '^^') 
            , '||', IFNULL(TRIM(OVERLAPPING_CHANGES::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(OBJ_NAME::text), '^^') 
            , '||', IFNULL(TRIM(LOW_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(SO_BASIS::text), '^^') 
            , '||', IFNULL(TRIM(OPTIONAL::text), '^^') 
            , '||', IFNULL(TRIM(PK5_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(DG_DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_REQUEST_MATERIAL::text), '^^') 
            , '||', IFNULL(TRIM(OPTIONAL_ON_MODEL::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(INCLUDE_ON_BILL_DOCS::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(FROM_END_ITEM_MINOR_REV_ID::text), '^^') 
            , '||', IFNULL(TRIM(FROM_END_ITEM_UNIT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SUGGESTED_VENDOR_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPING_ALLOWED::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_RELATED::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(COMPONENT_MINOR_REVISION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PICK_COMPONENTS::text), '^^') 
            , '||', IFNULL(TRIM(FROM_MINOR_REVISION_ID::text), '^^') 
            , '||', IFNULL(TRIM(INHERIT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(FROM_END_ITEM_REV_ID::text), '^^') 
            , '||', IFNULL(TRIM(TO_END_ITEM_STRC_REV_ID::text), '^^') 
            , '||', IFNULL(TRIM(INCLUDE_ON_SHIP_DOCS::text), '^^') 
            , '||', IFNULL(TRIM(PK3_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(TO_BILL_REVISION_ID::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(PLAN_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(OPERATION_LEAD_TIME_PERCENT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_NUM::text), '^^') 
            , '||', IFNULL(TRIM(DISABLE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(FROM_STRUCTURE_REVISION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(COMMON_COMPONENT_SEQUENCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLY_LOCATOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(PK2_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(TO_END_ITEM_UNIT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(BOM_ITEM_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ECO_FOR_PRODUCTION::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
