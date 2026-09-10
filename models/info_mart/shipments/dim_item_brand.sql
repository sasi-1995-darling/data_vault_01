---- SRC LAYER ----
WITH
SRC_difb           as ( SELECT BASE_MATERIAL, BRAND, FORECAST_BASE_MATERIAL, ITEM_ARCHITECTURE, ITEM_ARCHITECTURE_DETAIL, ITEM_BASE_UOM, 
                        ITEM_CATEGORY, ITEM_CLASS, ITEM_FINISH, ITEM_ID, ITEM_NUMBER, ITEM_PRICE_BAND, ITEM_PRODUCT_LINE, ITEM_PRODUCT_SEGMENT, 
                        ITEM_REPORTING_CATEGORY, ITEM_ROOM_AREA_DETAIL, ITEM_STATUS, ITEM_SUB_CATEGORY, ITEM_SUB_CLASS, ITEM_TYPE_CODE, 
                        PNS_PRICE_BAND, ULTIMATE_ITEM_SUPPLY_SOURCE, ITEM_TITLE, ITEM_PRODUCT_TYPE FROM {{ ref('dim_item_fbin') }} as SRC  ),
SRC_dbr            as ( SELECT BRAND, BUSINESS_UNIT, SUB_BRAND_CODE, SUB_BRAND_NAME FROM {{ ref('dim_brand') }} as SRC  )

/*
SRC_difb           as ( SELECT * FROM bus_vault.dim_item_fbin )
SRC_dbr            as ( SELECT * FROM bus_vault.dim_brand )
*/
---- LOGIC LAYER ----

, LOGIC_difb as (
    SELECT
        ITEM_ID
      , ITEM_STATUS
      , ITEM_SUB_CATEGORY
      , FORECAST_BASE_MATERIAL
      , ULTIMATE_ITEM_SUPPLY_SOURCE
      , ITEM_BASE_UOM
      , ITEM_ARCHITECTURE
      , ITEM_ARCHITECTURE_DETAIL
      , ITEM_FINISH
      , ITEM_PRICE_BAND
      , PNS_PRICE_BAND
      , ITEM_PRODUCT_LINE
      , ITEM_PRODUCT_SEGMENT
      , ITEM_REPORTING_CATEGORY
      , ITEM_ROOM_AREA_DETAIL
      , BRAND                                                        as                                         DIFB_BRAND
      , ITEM_NUMBER                                                  as                                   DIFB_ITEM_NUMBER
      , BASE_MATERIAL                                                as                                 DIFB_BASE_MATERIAL
      , ITEM_TYPE_CODE                                               as                                DIFB_ITEM_TYPE_CODE
      , ITEM_CATEGORY                                                as                                 DIFB_ITEM_CATEGORY
      , ITEM_CLASS                                                   as                                    DIFB_ITEM_CLASS
      , ITEM_SUB_CLASS                                               as                                DIFB_ITEM_SUB_CLASS
      , ITEM_TITLE                                                   as                                   ITEM_DESCRIPTION
      , ITEM_PRODUCT_TYPE
    FROM SRC_difb
)

, LOGIC_dbr as (
    SELECT
        SUB_BRAND_NAME                                               as                                 DBR_SUB_BRAND_NAME
      , BRAND                                                        as                                          DBR_BRAND
      , BUSINESS_UNIT                                                as                                  DBR_BUSINESS_UNIT
      , SUB_BRAND_CODE                                               as                                 DBR_SUB_BRAND_CODE
    FROM SRC_dbr
)
---- RENAME LAYER ----

, RENAME_difb as (
    SELECT
        ITEM_ID
      , ITEM_STATUS
      , ITEM_SUB_CATEGORY
      , FORECAST_BASE_MATERIAL
      , ULTIMATE_ITEM_SUPPLY_SOURCE
      , ITEM_BASE_UOM
      , ITEM_ARCHITECTURE
      , ITEM_ARCHITECTURE_DETAIL
      , ITEM_FINISH
      , ITEM_PRICE_BAND
      , PNS_PRICE_BAND
      , ITEM_PRODUCT_LINE
      , ITEM_PRODUCT_SEGMENT
      , ITEM_REPORTING_CATEGORY
      , ITEM_ROOM_AREA_DETAIL
      , DIFB_BRAND
      , DIFB_ITEM_NUMBER
      , DIFB_BASE_MATERIAL
      , DIFB_ITEM_TYPE_CODE
      , DIFB_ITEM_CATEGORY
      , DIFB_ITEM_CLASS
      , DIFB_ITEM_SUB_CLASS
      , ITEM_DESCRIPTION
      , ITEM_PRODUCT_TYPE
    FROM LOGIC_difb
)

, RENAME_dbr as (
    SELECT
        DBR_SUB_BRAND_NAME
      , DBR_BRAND
      , DBR_BUSINESS_UNIT
      , DBR_SUB_BRAND_CODE
    FROM LOGIC_dbr
)
---- FILTER LAYER ----

, FILTER_difb as (
    SELECT *
    FROM RENAME_difb
)

, FILTER_dbr as (
    SELECT *
    FROM RENAME_dbr
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_difb
    LEFT JOIN FILTER_dbr
        ON DIFB_BRAND = UPPER(DBR_SUB_BRAND_CODE)
)

---- FINAL LAYER ----
SELECT
          ITEM_ID
        , DIFB_ITEM_NUMBER::varchar(100)                               as ITEM_NUMBER
        , DIFB_BASE_MATERIAL::varchar(250)                             as BASE_MATERIAL
        , DIFB_ITEM_TYPE_CODE::varchar(100)                            as ITEM_TYPE_CODE
        , ITEM_STATUS
        , DIFB_ITEM_CATEGORY::varchar(100)                             as ITEM_CATEGORY
        , ITEM_SUB_CATEGORY
        , DIFB_ITEM_CLASS::varchar(100)                                as ITEM_CLASS
        , DIFB_ITEM_SUB_CLASS::varchar(100)                            as ITEM_SUB_CLASS
        , UPPER(DBR_SUB_BRAND_NAME)::varchar(100)                      as SUB_BRAND_NAME
        , UPPER(DBR_BRAND)::varchar(100)                               as BRAND
        , UPPER(DBR_BUSINESS_UNIT)::varchar(100)                       as BUSINESS_UNIT
        , FORECAST_BASE_MATERIAL
        , ULTIMATE_ITEM_SUPPLY_SOURCE
        , ITEM_BASE_UOM
        , ITEM_ARCHITECTURE
        , ITEM_ARCHITECTURE_DETAIL
        , ITEM_FINISH
        , ITEM_PRICE_BAND
        , PNS_PRICE_BAND
        , ITEM_PRODUCT_LINE
        , ITEM_PRODUCT_SEGMENT
        , ITEM_REPORTING_CATEGORY
        , ITEM_ROOM_AREA_DETAIL
        , UPPER(TRIM(ITEM_DESCRIPTION))                                as ITEM_DESCRIPTION
        , ITEM_PRODUCT_TYPE
FROM JOIN_RESULT
