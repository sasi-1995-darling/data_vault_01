---- SRC LAYER ----
WITH
SRC_itm_ctg        as ( SELECT * FROM {{ source('ml_ebs_inv', 'mtl_item_categories') }} as SRC  ),
SRC_ctg_set        as ( SELECT * FROM {{ source('ml_ebs_inv', 'mtl_category_sets_b') }} as SRC 
                        /* this filter control_level =1 to set the item categories globally as defined on Master Org. The control Level =2 is for Plant Specific.*/
                         where control_level =1
                        qualify 1= row_number() over (partition by category_set_id order by _fivetran_synced desc,psa_load_dts desc) ),
SRC_ctg_desc       as ( SELECT * FROM {{ source('ml_ebs_inv', 'mtl_category_sets_tl') }} as SRC 
                        where language = 'US'
                        qualify 1= row_number() over (partition by category_set_id order by _fivetran_synced desc,psa_load_dts desc) ),
SRC_ctg_val        as ( SELECT * FROM {{ source('ml_ebs_inv', 'mtl_categories_b') }} as SRC 
                        qualify 1= row_number() over (partition by category_id order by _fivetran_synced desc,psa_load_dts desc) )

/*
SRC_itm_ctg        as ( SELECT * FROM ml_ebs_inv.mtl_item_categories )
, SRC_ctg_set        as ( SELECT * FROM ml_ebs_inv.mtl_category_sets_b )
, SRC_ctg_desc       as ( SELECT * FROM ml_ebs_inv.mtl_category_sets_tl )
, SRC_ctg_val        as ( SELECT * FROM ml_ebs_inv.mtl_categories_b )
*/
---- LOGIC LAYER ----

, LOGIC_itm_ctg as (
    SELECT
        INVENTORY_ITEM_ID
      , CATEGORY_SET_ID
      , ORGANIZATION_ID
      , CATEGORY_ID
      , LAST_UPDATE_DATE
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_itm_ctg
)

, LOGIC_ctg_set as (
    SELECT
        CATEGORY_SET_ID                                              as                            CTG_SET_CATEGORY_SET_ID
    FROM SRC_ctg_set
)

, LOGIC_ctg_desc as (
    SELECT
        CATEGORY_SET_NAME
      , CATEGORY_SET_ID                                              as                           CTG_DESC_CATEGORY_SET_ID
    FROM SRC_ctg_desc
)

, LOGIC_ctg_val as (
    SELECT
        SEGMENT1
      , SEGMENT2
      , SEGMENT3
      , SEGMENT4
      , ATTRIBUTE1
      , ATTRIBUTE2
      , ATTRIBUTE3
      , CATEGORY_ID                                                  as                                CTG_VAL_CATEGORY_ID
    FROM SRC_ctg_val
)
---- RENAME LAYER ----

, RENAME_itm_ctg as (
    SELECT
        INVENTORY_ITEM_ID
      , CATEGORY_SET_ID
      , ORGANIZATION_ID
      , CATEGORY_ID
      , LAST_UPDATE_DATE
      , LOAD_DTS
    FROM LOGIC_itm_ctg
)

, RENAME_ctg_desc as (
    SELECT
        CATEGORY_SET_NAME
      , CTG_DESC_CATEGORY_SET_ID
    FROM LOGIC_ctg_desc
)

, RENAME_ctg_val as (
    SELECT
        SEGMENT1
      , SEGMENT2
      , SEGMENT3
      , SEGMENT4
      , ATTRIBUTE1
      , ATTRIBUTE2
      , ATTRIBUTE3
      , CTG_VAL_CATEGORY_ID
    FROM LOGIC_ctg_val
)

, RENAME_ctg_set as (
    SELECT
        CTG_SET_CATEGORY_SET_ID
    FROM LOGIC_ctg_set
)
---- FILTER LAYER ----

, FILTER_itm_ctg as (
    SELECT *
    FROM RENAME_itm_ctg
    WHERE ORGANIZATION_ID =1
)

, FILTER_ctg_set as (
    SELECT *
    FROM RENAME_ctg_set
)

, FILTER_ctg_desc as (
    SELECT *
    FROM RENAME_ctg_desc
)

, FILTER_ctg_val as (
    SELECT *
    FROM RENAME_ctg_val
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_itm_ctg
    INNER JOIN FILTER_ctg_set
        ON FILTER_itm_ctg.category_set_id = ctg_set_category_set_id
    INNER JOIN FILTER_ctg_desc
        ON FILTER_itm_ctg.category_set_id = ctg_desc_category_set_id
    INNER JOIN FILTER_ctg_val
        ON FILTER_itm_ctg.category_id = ctg_val_category_id
)

---- FINAL LAYER ----
SELECT
          INVENTORY_ITEM_ID
        , CATEGORY_SET_ID
        , ORGANIZATION_ID
        , CATEGORY_ID
        , CATEGORY_SET_NAME
        , SEGMENT1
        , SEGMENT2
        , SEGMENT3
        , SEGMENT4
        , ATTRIBUTE1
        , ATTRIBUTE2
        , ATTRIBUTE3
        , LAST_UPDATE_DATE
        , LOAD_DTS
FROM JOIN_RESULT
