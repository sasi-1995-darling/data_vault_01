---- SRC LAYER ----
WITH
SRC_ctg            as ( SELECT * FROM {{ ref('v_psa_stg_ref_item_categories__ml_ebs') }} as SRC 
                        qualify 1= row_number()over(partition by inventory_item_id, category_set_id order by LOAD_DTS desc) )

/*
SRC_ctg            as ( SELECT * FROM staging.v_psa_stg_ref_item_categories__ml_ebs )
*/
---- LOGIC LAYER ----

, LOGIC_ctg as (
    SELECT
        INVENTORY_ITEM_ID
      , CATEGORY_SET_ID
      , ORGANIZATION_ID
      , CATEGORY_ID
      , CATEGORY_SET_NAME
      , SEGMENT1                                                     as                                    CATEGORY_VALUE1
      , SEGMENT2                                                     as                                    CATEGORY_VALUE2
      , SEGMENT3                                                     as                                    CATEGORY_VALUE3
      , SEGMENT4                                                     as                                    CATEGORY_VALUE4
      , ATTRIBUTE1                                                   as                                CATEGORY_ATTRIBUTE1
      , ATTRIBUTE2                                                   as                                CATEGORY_ATTRIBUTE2
      , ATTRIBUTE3                                                   as                                CATEGORY_ATTRIBUTE3
      , LAST_UPDATE_DATE
      , LOAD_DTS
    FROM SRC_ctg
)
---- RENAME LAYER ----

, RENAME_ctg as (
    SELECT
        INVENTORY_ITEM_ID
      , CATEGORY_SET_ID
      , ORGANIZATION_ID
      , CATEGORY_ID
      , CATEGORY_SET_NAME
      , CATEGORY_VALUE1
      , CATEGORY_VALUE2
      , CATEGORY_VALUE3
      , CATEGORY_VALUE4
      , CATEGORY_ATTRIBUTE1
      , CATEGORY_ATTRIBUTE2
      , CATEGORY_ATTRIBUTE3
      , LAST_UPDATE_DATE
      , LOAD_DTS
    FROM LOGIC_ctg
)
---- FILTER LAYER ----

, FILTER_ctg as (
    SELECT *
    FROM RENAME_ctg
    WHERE CATEGORY_SET_NAME <> 'Conversion'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_ctg
)

---- FINAL LAYER ----
SELECT
          INVENTORY_ITEM_ID
        , CATEGORY_SET_ID
        , ORGANIZATION_ID
        , CATEGORY_ID
        , CATEGORY_SET_NAME
        , CATEGORY_VALUE1
        , CATEGORY_VALUE2
        , CATEGORY_VALUE3
        , CATEGORY_VALUE4
        , CATEGORY_ATTRIBUTE1
        , CATEGORY_ATTRIBUTE2
        , CATEGORY_ATTRIBUTE3
        , LAST_UPDATE_DATE
        , LOAD_DTS
FROM JOIN_RESULT
