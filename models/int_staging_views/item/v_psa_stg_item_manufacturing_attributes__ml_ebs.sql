---- SRC LAYER ----
WITH
SRC_mcsi           as ( SELECT * FROM {{ source('ml_ebs_bolinf', 'mlc_system_items') }} as SRC
                        /*where multiple records exist pull the most recently updated at source*/
                        qualify 1 = row_number()over (partition by inventory_item_id order by psa_load_dts desc)  ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_sitm           as ( SELECT * FROM {{ source('ml_ebs_inv', 'mtl_system_items_b') }} as SRC 
                        qualify 1 = row_number()over (partition by inventory_item_id order by psa_load_dts )  )

/*
SRC_mcsi           as ( SELECT * FROM ml_ebs_bolinf.mlc_system_items )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_sitm           as ( SELECT * FROM ml_ebs_inv.mtl_system_items_b )
*/
---- LOGIC LAYER ----

, LOGIC_mcsi as (
    SELECT
        INVENTORY_ITEM_ID
      , ATTRIBUTE10
      , CUT_KEY_FLAG
      , ATTRIBUTE14
      , OVERRIDE_TC_AUTO_PRINT_FLAG
      , ATTRIBUTE13
      , HARMONIZATION_CODE
      , ATTRIBUTE12
      , ASSEMBLY_CHART_FORMAT
      , ATTRIBUTE11
      , BODY_ID
      , MASTER_KEY_FLAG
      , STAMPING_TYPE
      , CONTEXT
      , GENERATE_FLAG
      , SERIAL_NUMBER_FLAG
      , KEY_BLANK_ID
      , MFG_DESCRIPTION
      , COMB_TAG_FORMAT
      , SYSTEM_TYPE
      , CREATED_BY
      , ATTRIBUTE3
      , LAST_UPDATED_BY
      , HARMONIZATION_DESC
      , ATTRIBUTE2
      , ATTRIBUTE1
      , CYLINDER_ID
      , SERIAL_BASE_ID
      , BASE_PRODUCT
      , ATTRIBUTE9
      , LAST_UPDATE_LOGIN
      , WORKSHEET_FORMAT
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , ATTRIBUTE4
      , RESERVE_FLAG
      , NUMBER_MFG_UNITS
      , ATTRIBUTE15
      , CHART_FORMAT
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , CREATION_DATE
      , LAST_UPDATE_DATE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
    FROM SRC_mcsi
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
      , SEGMENT1
    FROM SRC_sitm
)
---- RENAME LAYER ----

, RENAME_mcsi as (
    SELECT
        INVENTORY_ITEM_ID
      , ATTRIBUTE10
      , CUT_KEY_FLAG
      , ATTRIBUTE14
      , OVERRIDE_TC_AUTO_PRINT_FLAG
      , ATTRIBUTE13
      , HARMONIZATION_CODE
      , ATTRIBUTE12
      , ASSEMBLY_CHART_FORMAT
      , ATTRIBUTE11
      , BODY_ID
      , MASTER_KEY_FLAG
      , STAMPING_TYPE
      , CONTEXT
      , GENERATE_FLAG
      , SERIAL_NUMBER_FLAG
      , KEY_BLANK_ID
      , MFG_DESCRIPTION
      , COMB_TAG_FORMAT
      , SYSTEM_TYPE
      , CREATED_BY
      , ATTRIBUTE3
      , LAST_UPDATED_BY
      , HARMONIZATION_DESC
      , ATTRIBUTE2
      , ATTRIBUTE1
      , CYLINDER_ID
      , SERIAL_BASE_ID
      , BASE_PRODUCT
      , ATTRIBUTE9
      , LAST_UPDATE_LOGIN
      , WORKSHEET_FORMAT
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , ATTRIBUTE4
      , RESERVE_FLAG
      , NUMBER_MFG_UNITS
      , ATTRIBUTE15
      , CHART_FORMAT
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , CREATION_DATE
      , LAST_UPDATE_DATE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_mcsi
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
      , SEGMENT1
    FROM LOGIC_sitm
)
---- FILTER LAYER ----

, FILTER_mcsi as (
    SELECT *
    FROM RENAME_mcsi
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.MLC_SYSTEM_ITEMS'
)

, FILTER_sitm as (
    SELECT *
    FROM RENAME_sitm
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_mcsi
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_sitm
        ON FILTER_mcsi.inventory_item_id = sitm_inventory_item_id
)

---- FINAL LAYER ----
SELECT
          IFF(SEGMENT1 IS NULL, '-1', SEGMENT1)                        as ITEM_BK
        , INVENTORY_ITEM_ID
        , ATTRIBUTE10
        , CUT_KEY_FLAG
        , ATTRIBUTE14
        , OVERRIDE_TC_AUTO_PRINT_FLAG
        , ATTRIBUTE13
        , HARMONIZATION_CODE
        , ATTRIBUTE12
        , ASSEMBLY_CHART_FORMAT
        , ATTRIBUTE11
        , BODY_ID
        , MASTER_KEY_FLAG
        , STAMPING_TYPE
        , CONTEXT
        , GENERATE_FLAG
        , SERIAL_NUMBER_FLAG
        , KEY_BLANK_ID
        , MFG_DESCRIPTION
        , COMB_TAG_FORMAT
        , SYSTEM_TYPE
        , CREATED_BY
        , ATTRIBUTE3
        , LAST_UPDATED_BY
        , HARMONIZATION_DESC
        , ATTRIBUTE2
        , ATTRIBUTE1
        , CYLINDER_ID
        , SERIAL_BASE_ID
        , BASE_PRODUCT
        , ATTRIBUTE9
        , LAST_UPDATE_LOGIN
        , WORKSHEET_FORMAT
        , ATTRIBUTE8
        , ATTRIBUTE7
        , ATTRIBUTE6
        , ATTRIBUTE5
        , ATTRIBUTE4
        , RESERVE_FLAG
        , NUMBER_MFG_UNITS
        , ATTRIBUTE15
        , CHART_FORMAT
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , CREATION_DATE
        , LAST_UPDATE_DATE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(CUT_KEY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(OVERRIDE_TC_AUTO_PRINT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(HARMONIZATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(ASSEMBLY_CHART_FORMAT::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(BODY_ID::text), '^^') 
            , '||', IFNULL(TRIM(MASTER_KEY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(STAMPING_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(CONTEXT::text), '^^') 
            , '||', IFNULL(TRIM(GENERATE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SERIAL_NUMBER_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(KEY_BLANK_ID::text), '^^') 
            , '||', IFNULL(TRIM(MFG_DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(COMB_TAG_FORMAT::text), '^^') 
            , '||', IFNULL(TRIM(SYSTEM_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(HARMONIZATION_DESC::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(CYLINDER_ID::text), '^^') 
            , '||', IFNULL(TRIM(SERIAL_BASE_ID::text), '^^') 
            , '||', IFNULL(TRIM(BASE_PRODUCT::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(WORKSHEET_FORMAT::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(RESERVE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(NUMBER_MFG_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(CHART_FORMAT::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
