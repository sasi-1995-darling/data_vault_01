---- SRC LAYER ----
WITH
SRC_bsid           as ( SELECT * FROM {{ source('ml_ebs_bom', 'bom_structures_b') }} as SRC  ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_sitm           as ( SELECT * FROM {{ source('ml_ebs_inv', 'mtl_system_items_b') }} as SRC 
                        qualify 1 = row_number()over (partition by inventory_item_id, organization_id order by psa_load_dts )  ),
SRC_plnt           as ( SELECT * FROM {{ source('ml_ebs_inv', 'mtl_parameters') }} as SRC 
                        qualify 1 = row_number()over (partition by organization_id order by psa_load_dts )  )

/*
SRC_bsid           as ( SELECT * FROM ml_ebs_bom.bom_structures_b )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_sitm           as ( SELECT * FROM ml_ebs_inv.mtl_system_items_b )
, SRC_plnt           as ( SELECT * FROM ml_ebs_inv.mtl_parameters )
*/
---- LOGIC LAYER ----

, LOGIC_bsid as (
    SELECT
        to_char(BILL_SEQUENCE_ID)                                    as                                             BOM_BK
      , BILL_SEQUENCE_ID
      , IS_PREFERRED
      , PK1_VALUE
      , LAST_UPDATE_DATE
      , PROGRAM_ID
      , STRUCTURE_TYPE_ID
      , OBJ_NAME
      , ASSEMBLY_ITEM_ID
      , ORGANIZATION_ID
      , ALTERNATE_BOM_DESIGNATOR
      , PK5_VALUE
      , IMPLEMENTATION_DATE
      , PENDING_FROM_ECN
      , CREATED_BY
      , ATTRIBUTE3
      , LAST_UPDATED_BY
      , ATTRIBUTE2
      , COMMON_ASSEMBLY_ITEM_ID
      , ATTRIBUTE1
      , CREATION_DATE
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , PROGRAM_UPDATE_DATE
      , ATTRIBUTE4
      , EFFECTIVITY_CONTROL
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , TASK_ID
      , PK4_VALUE
      , SPECIFIC_ASSEMBLY_COMMENT
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , PK3_VALUE
      , ATTRIBUTE12
      , ATTRIBUTE11
      , REQUEST_ID
      , ORIGINAL_SYSTEM_REFERENCE
      , SOURCE_BILL_SEQUENCE_ID
      , NEXT_EXPLODE_DATE
      , COMMON_BILL_SEQUENCE_ID
      , PROJECT_ID
      , PK2_VALUE
      , COMMON_ORGANIZATION_ID
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE15
      , ASSEMBLY_TYPE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
    FROM SRC_bsid
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)

, LOGIC_sitm as (
    SELECT
        INVENTORY_ITEM_ID                                            as                             SITM_INVENTORY_ITEM_ID
      , ORGANIZATION_ID                                              as                               SITM_ORGANIZATION_ID
      , SEGMENT1
    FROM SRC_sitm
)

, LOGIC_plnt as (
    SELECT
        ORGANIZATION_CODE                                            as                                           PLANT_BK
      , ORGANIZATION_ID                                              as                               PLNT_ORGANIZATION_ID
    FROM SRC_plnt
)
---- RENAME LAYER ----

, RENAME_bsid as (
    SELECT
        BOM_BK
      , BILL_SEQUENCE_ID
      , IS_PREFERRED
      , PK1_VALUE
      , LAST_UPDATE_DATE
      , PROGRAM_ID
      , STRUCTURE_TYPE_ID
      , OBJ_NAME
      , ASSEMBLY_ITEM_ID
      , ORGANIZATION_ID
      , ALTERNATE_BOM_DESIGNATOR
      , PK5_VALUE
      , IMPLEMENTATION_DATE
      , PENDING_FROM_ECN
      , CREATED_BY
      , ATTRIBUTE3
      , LAST_UPDATED_BY
      , ATTRIBUTE2
      , COMMON_ASSEMBLY_ITEM_ID
      , ATTRIBUTE1
      , CREATION_DATE
      , ATTRIBUTE9
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , PROGRAM_UPDATE_DATE
      , ATTRIBUTE4
      , EFFECTIVITY_CONTROL
      , ATTRIBUTE_CATEGORY
      , PROGRAM_APPLICATION_ID
      , TASK_ID
      , PK4_VALUE
      , SPECIFIC_ASSEMBLY_COMMENT
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , PK3_VALUE
      , ATTRIBUTE12
      , ATTRIBUTE11
      , REQUEST_ID
      , ORIGINAL_SYSTEM_REFERENCE
      , SOURCE_BILL_SEQUENCE_ID
      , NEXT_EXPLODE_DATE
      , COMMON_BILL_SEQUENCE_ID
      , PROJECT_ID
      , PK2_VALUE
      , COMMON_ORGANIZATION_ID
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE15
      , ASSEMBLY_TYPE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_bsid
)

, RENAME_plnt as (
    SELECT
        PLANT_BK
      , PLNT_ORGANIZATION_ID
    FROM LOGIC_plnt
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)

, RENAME_sitm as (
    SELECT
        SITM_INVENTORY_ITEM_ID
      , SITM_ORGANIZATION_ID
      , SEGMENT1
    FROM LOGIC_sitm
)
---- FILTER LAYER ----

, FILTER_bsid as (
    SELECT *
    FROM RENAME_bsid
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.BOM_STRUCTURES_B'
)

, FILTER_sitm as (
    SELECT *
    FROM RENAME_sitm
)

, FILTER_plnt as (
    SELECT *
    FROM RENAME_plnt
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_bsid
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_sitm
        ON FILTER_bsid.assembly_item_id = sitm_inventory_item_id  AND organization_id = sitm_organization_id
    LEFT JOIN FILTER_plnt
        ON FILTER_bsid.organization_id = plnt_organization_id
)

---- FINAL LAYER ----
SELECT
          BOM_BK
        , BILL_SEQUENCE_ID
        , IS_PREFERRED
        , PK1_VALUE
        , LAST_UPDATE_DATE
        , PROGRAM_ID
        , STRUCTURE_TYPE_ID
        , OBJ_NAME
        , ASSEMBLY_ITEM_ID
        , ORGANIZATION_ID
        , ALTERNATE_BOM_DESIGNATOR
        , PK5_VALUE
        , IMPLEMENTATION_DATE
        , PENDING_FROM_ECN
        , CREATED_BY
        , ATTRIBUTE3
        , LAST_UPDATED_BY
        , ATTRIBUTE2
        , COMMON_ASSEMBLY_ITEM_ID
        , ATTRIBUTE1
        , CREATION_DATE
        , ATTRIBUTE9
        , ATTRIBUTE8
        , ATTRIBUTE7
        , ATTRIBUTE6
        , ATTRIBUTE5
        , PROGRAM_UPDATE_DATE
        , ATTRIBUTE4
        , EFFECTIVITY_CONTROL
        , ATTRIBUTE_CATEGORY
        , PROGRAM_APPLICATION_ID
        , TASK_ID
        , PK4_VALUE
        , SPECIFIC_ASSEMBLY_COMMENT
        , ATTRIBUTE10
        , ATTRIBUTE14
        , ATTRIBUTE13
        , PK3_VALUE
        , ATTRIBUTE12
        , ATTRIBUTE11
        , REQUEST_ID
        , ORIGINAL_SYSTEM_REFERENCE
        , SOURCE_BILL_SEQUENCE_ID
        , NEXT_EXPLODE_DATE
        , COMMON_BILL_SEQUENCE_ID
        , PROJECT_ID
        , PK2_VALUE
        , COMMON_ORGANIZATION_ID
        , LAST_UPDATE_LOGIN
        , ATTRIBUTE15
        , ASSEMBLY_TYPE
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , PLANT_BK
        , IFF(SEGMENT1 IS NULL, '-2', SEGMENT1)                        as ITEM_BK
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
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_BOM_PLANT_ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(IS_PREFERRED::text), '^^') 
            , '||', IFNULL(TRIM(PK1_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(STRUCTURE_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(OBJ_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ASSEMBLY_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ALTERNATE_BOM_DESIGNATOR::text), '^^') 
            , '||', IFNULL(TRIM(PK5_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENTATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PENDING_FROM_ECN::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(COMMON_ASSEMBLY_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(EFFECTIVITY_CONTROL::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(TASK_ID::text), '^^') 
            , '||', IFNULL(TRIM(PK4_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(SPECIFIC_ASSEMBLY_COMMENT::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(PK3_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_SYSTEM_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_BILL_SEQUENCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(NEXT_EXPLODE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(COMMON_BILL_SEQUENCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(PK2_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(COMMON_ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(ASSEMBLY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
