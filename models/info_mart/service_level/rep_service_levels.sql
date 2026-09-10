---- SRC LAYER ----
WITH
SRC_fact_srv       as ( SELECT CUMULATIVE_ORDER_QTY, CUSTOMER_HK, CUSTOMER_SALES_ATTRIBUTES_KEY, DELIVERED_QTY, DISTRIBUTION_CHANNEL, DISTRIBUTION_CHANNEL_SERVICE_TARGET, DIVISION, FILLED_ON_TIME_QTY, FISCAL_DATEKEY, GOODS_STORAGE_LOCATION, ITEM_HK, ITEM_NUMBER, LINE_FILLED_FLAG, LINE_ON_TIME_FLAG, LINE_QUANTITY_WAS_COMPLETELY_FILLED_FLAG, MISSED_ON_TIME_QTY, MISSED_QTY, NET_PRICE, NUMBER_OF_WORKING_DAYS, ORDERED_ON_TIME_QTY, ORDERED_QTY, PERFECT_ORDER_FLAG, PLANT, PROMISED_DELIVERY_ON_TIME_QTY, PROMISED_ORDER_ON_TIME_QTY, SALES_BASE_UOM, SALES_DOCUMENT, SALES_DOCUMENT_LINE_CATEGORY, SALES_DOCUMENT_LINE_NUMBER, SALES_ORGANIZATION, SERVICE_LEVELS_KEY, SERVICE_LEVEL_CODE, SERVICE_LEVEL_DESCRIPTION, SERVICE_LEVEL_TYPE_ID, SERVICE_LINE_RELEASED_FLAG, SHIPPED_QTY, SOLD_TO_CUSTOMER_ID FROM {{ ref('im_service_level_fact_service_levels') }} as SRC  ),
SRC_dim_date       as ( SELECT DATE, DATE_BK, EPOCH_DAY, EPOCH_MONTH, EPOCH_WEEK, FISCAL_445_CAL_DAY, FISCAL_445_CAL_MONTH, FISCAL_445_CAL_MONTH_YYYYMM, FISCAL_445_CAL_QUARTER, FISCAL_445_CAL_QUARTER_YYYYQQ, FISCAL_445_CAL_WEEK, FISCAL_445_CAL_WEEK_YYYYWW, FISCAL_445_CAL_YEAR, FISCAL_445_WORKING_DAY_FLAG, FISCAL_DAY_OF_YEAR, FISCAL_LAST_13_WEEKS_FLAG, FISCAL_LAST_3_MONTHS_FLAG, FISCAL_LAST_4_WEEKS_FLAG, FISCAL_LAST_MONTH_FLAG, FISCAL_LAST_WEEK_FLAG, FISCAL_ROLLING_52_WEEK_FLAG, FISCAL_YTD_FLAG, IS_COMPLETED_FISCAL_MONTH, IS_COMPLETED_FISCAL_WEEK, MONTH_NAME, MONTH_NAME_ABBR, MONTH_NUMBER_LEADING_ZERO, WEEKS_IN_MONTH FROM {{ ref('im_service_level_dim_date_fiscal_445') }} as SRC  ),
SRC_dim_item       as ( SELECT BASE_MATERIAL, BRAND, ITEM_ARCHITECTURE, ITEM_ARCHITECTURE_DETAIL, ITEM_CATEGORY, ITEM_CLASS, ITEM_FINISH, ITEM_ID, ITEM_PRICE_BAND, ITEM_PRODUCT_LINE, ITEM_PRODUCT_SEGMENT, ITEM_REPORTING_CATEGORY, ITEM_ROOM_AREA_DETAIL, ITEM_STATUS, ITEM_SUB_CATEGORY, ITEM_SUB_CLASS, ITEM_TITLE, ITEM_TYPE_CODE, PNS_PRICE_BAND FROM {{ ref('im_service_level_dim_item_fbin') }} as SRC  ),
SRC_dim_brand      as ( SELECT BRAND, BUSINESS_UNIT, SUB_BRAND_CODE, SUB_BRAND_NAME FROM {{ ref('im_service_level_dim_brand') }} as SRC  ),
SRC_dim_cust       as ( SELECT CITY, CUSTOMER_HK, CUSTOMER_NAME_1, POSTAL_CODE, REGION FROM {{ ref('im_service_level_dim_customer') }} as SRC  ),
SRC_dim_csls       as ( SELECT ACCOUNT_NAME, ACCOUNT_NUMBER, APO_FORECAST_ACCOUNT, APO_GROUP, BUYING_GROUP_ID, CUSTOMER_SALES_ATTRIBUTES_KEY, REPORTING_DISTRICT, SALES_GROUP, SALES_OFFICE FROM {{ ref('im_service_level_dim_customer_sales_attributes') }} as SRC  )

/*
SRC_fact_srv       as ( SELECT * FROM service_level.im_service_level_fact_service_levels )
SRC_dim_date       as ( SELECT * FROM service_level.im_service_level_dim_date_fiscal_445 )
SRC_dim_item       as ( SELECT * FROM service_level.im_service_level_dim_item_fbin )
SRC_dim_brand      as ( SELECT * FROM service_level.im_service_level_dim_brand )
SRC_dim_cust       as ( SELECT * FROM service_level.im_service_level_dim_customer_v1 )
SRC_dim_csls       as ( SELECT * FROM service_level.im_service_level_dim_customer_sales_attributes )
*/
---- LOGIC LAYER ----

, LOGIC_fact_srv as (
    SELECT
        SERVICE_LEVELS_KEY                                           as                                  SERVICE_LEVELS_ID
      , SERVICE_LEVEL_CODE
      , SERVICE_LEVEL_DESCRIPTION
      , SERVICE_LEVEL_TYPE_ID
      , SALES_DOCUMENT
      , SALES_DOCUMENT_LINE_NUMBER
      , SOLD_TO_CUSTOMER_ID                                          as                                        CUSTOMER_ID
      , ITEM_NUMBER
      , PLANT
      , GOODS_STORAGE_LOCATION
      , SALES_ORGANIZATION
      , DISTRIBUTION_CHANNEL
      , DIVISION
      , NET_PRICE
      , SALES_DOCUMENT_LINE_CATEGORY
      , CUMULATIVE_ORDER_QTY
      , DELIVERED_QTY
      , NUMBER_OF_WORKING_DAYS
      , LINE_ON_TIME_FLAG
      , LINE_FILLED_FLAG
      , SERVICE_LINE_RELEASED_FLAG
      , LINE_QUANTITY_WAS_COMPLETELY_FILLED_FLAG
      , SALES_BASE_UOM
      , PERFECT_ORDER_FLAG
      , DISTRIBUTION_CHANNEL_SERVICE_TARGET
      , ORDERED_ON_TIME_QTY
      , FILLED_ON_TIME_QTY
      , MISSED_ON_TIME_QTY
      , ORDERED_QTY
      , SHIPPED_QTY
      , MISSED_QTY
      , PROMISED_ORDER_ON_TIME_QTY
      , PROMISED_DELIVERY_ON_TIME_QTY
      , FISCAL_DATEKEY                                               as                            FACT_SRV_FISCAL_DATEKEY
      , ITEM_HK                                                      as                                   FACT_SRV_ITEM_HK
      , CUSTOMER_HK                                                  as                               FACT_SRV_CUSTOMER_HK
      , CUSTOMER_SALES_ATTRIBUTES_KEY                                as             FACT_SRV_CUSTOMER_SALES_ATTRIBUTES_KEY
    FROM SRC_fact_srv
)

, LOGIC_dim_date as (
    SELECT
        DATE                                                         as                               RECORD_CREATION_DATE
      , FISCAL_445_CAL_DAY
      , FISCAL_445_CAL_WEEK
      , FISCAL_445_CAL_MONTH
      , FISCAL_445_CAL_QUARTER
      , FISCAL_445_CAL_YEAR
      , FISCAL_445_CAL_QUARTER_YYYYQQ
      , FISCAL_445_CAL_MONTH_YYYYMM
      , FISCAL_445_CAL_WEEK_YYYYWW
      , FISCAL_445_WORKING_DAY_FLAG
      , IS_COMPLETED_FISCAL_MONTH
      , IS_COMPLETED_FISCAL_WEEK
      , FISCAL_LAST_WEEK_FLAG
      , FISCAL_LAST_4_WEEKS_FLAG
      , FISCAL_LAST_13_WEEKS_FLAG
      , FISCAL_LAST_MONTH_FLAG
      , FISCAL_LAST_3_MONTHS_FLAG
      , MONTH_NAME
      , MONTH_NAME_ABBR
      , EPOCH_DAY
      , EPOCH_WEEK
      , EPOCH_MONTH
      , WEEKS_IN_MONTH
      , MONTH_NUMBER_LEADING_ZERO
      , FISCAL_DAY_OF_YEAR
      , FISCAL_YTD_FLAG
      , FISCAL_ROLLING_52_WEEK_FLAG
      , DATE_BK                                                      as                                   DIM_DATE_DATE_BK
    FROM SRC_dim_date
)

, LOGIC_dim_item as (
    SELECT
        ITEM_TITLE                                                   as                                   ITEM_DESCRIPTION
      , ITEM_TYPE_CODE
      , ITEM_STATUS
      , BASE_MATERIAL
      , ITEM_CATEGORY
      , ITEM_SUB_CATEGORY
      , ITEM_CLASS
      , ITEM_SUB_CLASS
      , ITEM_ARCHITECTURE
      , ITEM_ARCHITECTURE_DETAIL
      , ITEM_FINISH
      , ITEM_PRICE_BAND
      , PNS_PRICE_BAND
      , ITEM_PRODUCT_LINE
      , ITEM_PRODUCT_SEGMENT
      , ITEM_REPORTING_CATEGORY
      , ITEM_ROOM_AREA_DETAIL
      , ITEM_ID                                                      as                                   DIM_ITEM_ITEM_HK
      , BRAND                                                        as                                     DIM_ITEM_BRAND
    FROM SRC_dim_item
)

, LOGIC_dim_brand as (
    SELECT
        BRAND
      , SUB_BRAND_NAME
      , BUSINESS_UNIT
      , SUB_BRAND_CODE                                               as                           DIM_BRAND_SUB_BRAND_CODE
    FROM SRC_dim_brand
)

, LOGIC_dim_cust as (
    SELECT
        CUSTOMER_NAME_1                                              as                                           CUSTOMER
      , REGION                                                       as                                     CUSTOMER_STATE
      , CITY                                                         as                                      CUSTOMER_CITY
      , POSTAL_CODE                                                  as                               CUSTOMER_POSTAL_CODE
      , CUSTOMER_HK                                                  as                               DIM_CUST_CUSTOMER_HK
    FROM SRC_dim_cust
)

, LOGIC_dim_csls as (
    SELECT
        ACCOUNT_NUMBER                                               as                            CUSTOMER_ACCOUNT_NUMBER
      , ACCOUNT_NAME                                                 as                              CUSTOMER_ACCOUNT_NAME
      , REPORTING_DISTRICT
      , SALES_GROUP
      , SALES_OFFICE
      , BUYING_GROUP_ID
      , APO_GROUP
      , APO_FORECAST_ACCOUNT
      , CUSTOMER_SALES_ATTRIBUTES_KEY                                as             DIM_CSLS_CUSTOMER_SALES_ATTRIBUTES_KEY
    FROM SRC_dim_csls
)
---- RENAME LAYER ----

, RENAME_fact_srv as (
    SELECT
        SERVICE_LEVELS_ID
      , SERVICE_LEVEL_CODE
      , SERVICE_LEVEL_DESCRIPTION
      , SERVICE_LEVEL_TYPE_ID
      , SALES_DOCUMENT
      , SALES_DOCUMENT_LINE_NUMBER
      , CUSTOMER_ID
      , ITEM_NUMBER
      , PLANT
      , GOODS_STORAGE_LOCATION
      , SALES_ORGANIZATION
      , DISTRIBUTION_CHANNEL
      , DIVISION
      , NET_PRICE
      , SALES_DOCUMENT_LINE_CATEGORY
      , CUMULATIVE_ORDER_QTY
      , DELIVERED_QTY
      , NUMBER_OF_WORKING_DAYS
      , LINE_ON_TIME_FLAG
      , LINE_FILLED_FLAG
      , SERVICE_LINE_RELEASED_FLAG
      , LINE_QUANTITY_WAS_COMPLETELY_FILLED_FLAG
      , SALES_BASE_UOM
      , PERFECT_ORDER_FLAG
      , DISTRIBUTION_CHANNEL_SERVICE_TARGET
      , ORDERED_ON_TIME_QTY
      , FILLED_ON_TIME_QTY
      , MISSED_ON_TIME_QTY
      , ORDERED_QTY
      , SHIPPED_QTY
      , MISSED_QTY
      , PROMISED_ORDER_ON_TIME_QTY
      , PROMISED_DELIVERY_ON_TIME_QTY
      , FACT_SRV_FISCAL_DATEKEY
      , FACT_SRV_ITEM_HK
      , FACT_SRV_CUSTOMER_HK
      , FACT_SRV_CUSTOMER_SALES_ATTRIBUTES_KEY
    FROM LOGIC_fact_srv
)

, RENAME_dim_date as (
    SELECT
        RECORD_CREATION_DATE
      , FISCAL_445_CAL_DAY
      , FISCAL_445_CAL_WEEK
      , FISCAL_445_CAL_MONTH
      , FISCAL_445_CAL_QUARTER
      , FISCAL_445_CAL_YEAR
      , FISCAL_445_CAL_QUARTER_YYYYQQ
      , FISCAL_445_CAL_MONTH_YYYYMM
      , FISCAL_445_CAL_WEEK_YYYYWW
      , FISCAL_445_WORKING_DAY_FLAG
      , IS_COMPLETED_FISCAL_MONTH
      , IS_COMPLETED_FISCAL_WEEK
      , FISCAL_LAST_WEEK_FLAG
      , FISCAL_LAST_4_WEEKS_FLAG
      , FISCAL_LAST_13_WEEKS_FLAG
      , FISCAL_LAST_MONTH_FLAG
      , FISCAL_LAST_3_MONTHS_FLAG
      , MONTH_NAME
      , MONTH_NAME_ABBR
      , EPOCH_DAY
      , EPOCH_WEEK
      , EPOCH_MONTH
      , WEEKS_IN_MONTH
      , MONTH_NUMBER_LEADING_ZERO
      , FISCAL_DAY_OF_YEAR
      , FISCAL_YTD_FLAG
      , FISCAL_ROLLING_52_WEEK_FLAG
      , DIM_DATE_DATE_BK
    FROM LOGIC_dim_date
)

, RENAME_dim_cust as (
    SELECT
        CUSTOMER
      , CUSTOMER_STATE
      , CUSTOMER_CITY
      , CUSTOMER_POSTAL_CODE
      , DIM_CUST_CUSTOMER_HK
    FROM LOGIC_dim_cust
)

, RENAME_dim_csls as (
    SELECT
        CUSTOMER_ACCOUNT_NUMBER
      , CUSTOMER_ACCOUNT_NAME
      , REPORTING_DISTRICT
      , SALES_GROUP
      , SALES_OFFICE
      , BUYING_GROUP_ID
      , APO_GROUP
      , APO_FORECAST_ACCOUNT
      , DIM_CSLS_CUSTOMER_SALES_ATTRIBUTES_KEY
    FROM LOGIC_dim_csls
)

, RENAME_dim_item as (
    SELECT
        ITEM_DESCRIPTION
      , ITEM_TYPE_CODE
      , ITEM_STATUS
      , BASE_MATERIAL
      , ITEM_CATEGORY
      , ITEM_SUB_CATEGORY
      , ITEM_CLASS
      , ITEM_SUB_CLASS
      , ITEM_ARCHITECTURE
      , ITEM_ARCHITECTURE_DETAIL
      , ITEM_FINISH
      , ITEM_PRICE_BAND
      , PNS_PRICE_BAND
      , ITEM_PRODUCT_LINE
      , ITEM_PRODUCT_SEGMENT
      , ITEM_REPORTING_CATEGORY
      , ITEM_ROOM_AREA_DETAIL
      , DIM_ITEM_ITEM_HK
      , DIM_ITEM_BRAND
    FROM LOGIC_dim_item
)

, RENAME_dim_brand as (
    SELECT
        BRAND
      , SUB_BRAND_NAME
      , BUSINESS_UNIT
      , DIM_BRAND_SUB_BRAND_CODE
    FROM LOGIC_dim_brand
)
---- FILTER LAYER ----

, FILTER_fact_srv as (
    SELECT *
    FROM RENAME_fact_srv
)

, FILTER_dim_date as (
    SELECT *
    FROM RENAME_dim_date
)

, FILTER_dim_item as (
    SELECT *
    FROM RENAME_dim_item
)

, FILTER_dim_brand as (
    SELECT *
    FROM RENAME_dim_brand
)

, FILTER_dim_cust as (
    SELECT *
    FROM RENAME_dim_cust
)

, FILTER_dim_csls as (
    SELECT *
    FROM RENAME_dim_csls
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_fact_srv
    LEFT JOIN FILTER_dim_date
        ON FACT_SRV_FISCAL_DATEKEY = DIM_DATE_DATE_BK
    LEFT JOIN FILTER_dim_item
        ON FACT_SRV_ITEM_HK = DIM_ITEM_ITEM_HK
    LEFT JOIN FILTER_dim_brand
        ON DIM_ITEM_BRAND = DIM_BRAND_SUB_BRAND_CODE
    LEFT JOIN FILTER_dim_cust
        ON FACT_SRV_CUSTOMER_HK = DIM_CUST_CUSTOMER_HK
    LEFT JOIN FILTER_dim_csls
        ON FACT_SRV_CUSTOMER_SALES_ATTRIBUTES_KEY = DIM_CSLS_CUSTOMER_SALES_ATTRIBUTES_KEY
)

---- FINAL LAYER ----
SELECT
          SERVICE_LEVELS_ID
        , SERVICE_LEVEL_CODE
        , SERVICE_LEVEL_DESCRIPTION
        , SERVICE_LEVEL_TYPE_ID
        , SALES_DOCUMENT
        , SALES_DOCUMENT_LINE_NUMBER
        , RECORD_CREATION_DATE
        , CUSTOMER_ID
        , CUSTOMER
        , CUSTOMER_ACCOUNT_NUMBER
        , CUSTOMER_ACCOUNT_NAME
        , REPORTING_DISTRICT
        , SALES_GROUP
        , SALES_OFFICE
        , BUYING_GROUP_ID
        , APO_GROUP
        , APO_FORECAST_ACCOUNT
        , CUSTOMER_STATE
        , CUSTOMER_CITY
        , CUSTOMER_POSTAL_CODE
        , ITEM_NUMBER
        , ITEM_DESCRIPTION
        , ITEM_TYPE_CODE
        , ITEM_STATUS
        , BASE_MATERIAL
        , BRAND
        , SUB_BRAND_NAME
        , BUSINESS_UNIT
        , ITEM_CATEGORY
        , ITEM_SUB_CATEGORY
        , ITEM_CLASS
        , ITEM_SUB_CLASS
        , ITEM_ARCHITECTURE
        , ITEM_ARCHITECTURE_DETAIL
        , ITEM_FINISH
        , ITEM_PRICE_BAND
        , PNS_PRICE_BAND
        , ITEM_PRODUCT_LINE
        , ITEM_PRODUCT_SEGMENT
        , ITEM_REPORTING_CATEGORY
        , ITEM_ROOM_AREA_DETAIL
        , PLANT
        , GOODS_STORAGE_LOCATION
        , SALES_ORGANIZATION
        , DISTRIBUTION_CHANNEL
        , DIVISION
        , NET_PRICE
        , SALES_DOCUMENT_LINE_CATEGORY
        , CUMULATIVE_ORDER_QTY
        , DELIVERED_QTY
        , NUMBER_OF_WORKING_DAYS
        , LINE_ON_TIME_FLAG
        , LINE_FILLED_FLAG
        , SERVICE_LINE_RELEASED_FLAG
        , LINE_QUANTITY_WAS_COMPLETELY_FILLED_FLAG
        , SALES_BASE_UOM
        , PERFECT_ORDER_FLAG
        , DISTRIBUTION_CHANNEL_SERVICE_TARGET
        , ORDERED_ON_TIME_QTY
        , FILLED_ON_TIME_QTY
        , MISSED_ON_TIME_QTY
        , ORDERED_QTY
        , SHIPPED_QTY
        , MISSED_QTY
        , PROMISED_ORDER_ON_TIME_QTY
        , PROMISED_DELIVERY_ON_TIME_QTY
        , FISCAL_445_CAL_DAY
        , FISCAL_445_CAL_WEEK
        , FISCAL_445_CAL_MONTH
        , FISCAL_445_CAL_QUARTER
        , FISCAL_445_CAL_YEAR
        , FISCAL_445_CAL_QUARTER_YYYYQQ
        , FISCAL_445_CAL_MONTH_YYYYMM
        , FISCAL_445_CAL_WEEK_YYYYWW
        , FISCAL_445_WORKING_DAY_FLAG
        , IS_COMPLETED_FISCAL_MONTH
        , IS_COMPLETED_FISCAL_WEEK
        , FISCAL_LAST_WEEK_FLAG
        , FISCAL_LAST_4_WEEKS_FLAG
        , FISCAL_LAST_13_WEEKS_FLAG
        , FISCAL_LAST_MONTH_FLAG
        , FISCAL_LAST_3_MONTHS_FLAG
        , MONTH_NAME
        , MONTH_NAME_ABBR
        , EPOCH_DAY
        , EPOCH_WEEK
        , EPOCH_MONTH
        , WEEKS_IN_MONTH
        , MONTH_NUMBER_LEADING_ZERO
        , FISCAL_DAY_OF_YEAR
        , FISCAL_YTD_FLAG
        , FISCAL_ROLLING_52_WEEK_FLAG
FROM JOIN_RESULT
