{{ config(alias='rep_pos_weekly') }}
---- SRC LAYER ----
WITH
SRC_fpos           as ( SELECT BRAND, CONSUMER_DOLLARS, GROSS_DOLLARS, INV_CONSUMER_DOLLARS, INV_QTY, ITEM_ID, POS_QTY, REPORTING_CHANNEL, PRODUCT_DEST_ZIP, REPORTING_CUSTOMER, SKU, STORE_ID, TRANSACTION_DATEKEY FROM {{ ref('im_pos_fact_pos_weekly') }} as SRC  ),
SRC_ds             as ( SELECT ADDRESS1, CITY, POSTAL_CODE, REPORTING_CUSTOMER, STATE, STORE_ID, STORE_NAME FROM {{ ref('im_pos_dim_store') }} as SRC  ),
SRC_dif            as ( SELECT BASE_MATERIAL, ITEM_CATEGORY, ITEM_CLASS, ITEM_ID, ITEM_NUMBER, ITEM_STATUS, ITEM_SUB_CATEGORY, ITEM_SUB_CLASS, ITEM_TITLE, ITEM_TYPE_CODE, ITEM_PRODUCT_TYPE, ITEM_PRODUCT_LINE FROM {{ ref('im_pos_dim_item_fbin') }} as SRC  ),
SRC_ddf            as ( SELECT DATE, DATE_BK, FISCAL_445_CAL_DAY, FISCAL_445_CAL_MONTH, FISCAL_445_CAL_MONTH_YYYYMM, FISCAL_445_CAL_QUARTER, FISCAL_445_CAL_QUARTER_YYYYQQ, FISCAL_445_CAL_WEEK, FISCAL_445_CAL_WEEK_YYYYWW, FISCAL_445_CAL_YEAR, FISCAL_445_WORKING_DAY_FLAG,IS_COMPLETED_FISCAL_MONTH,IS_COMPLETED_FISCAL_WEEK,FISCAL_LAST_WEEK_FLAG,FISCAL_LAST_4_WEEKS_FLAG,FISCAL_LAST_13_WEEKS_FLAG,FISCAL_LAST_MONTH_FLAG,FISCAL_LAST_3_MONTHS_FLAG,MONTH_NAME,MONTH_NAME_ABBR,EPOCH_DAY,EPOCH_WEEK,EPOCH_MONTH,WEEKS_IN_MONTH,MONTH_NUMBER_LEADING_ZERO,FISCAL_DAY_OF_YEAR,FISCAL_YTD_FLAG,FISCAL_ROLLING_52_WEEK_FLAG,FISCAL_LAST_QUARTER_FLAG,FISCAL_LAST_12_MONTHS_FLAG,FISCAL_QTD_FLAG
 FROM {{ ref('im_pos_dim_date_fiscal_445') }} as SRC  ),
SRC_dpw            as ( SELECT ACTIVE_SKU_FLAG, BRAND, FISCAL_445_WEEK_END_DATE__YYYYMMDD, FISCAL_445_WEEK_START_DATE__YYYYMMDD, SKU, ITEM_KEY, REPORTING_CUSTOMER, STOCKED_STORE_FLAG, STORE_ID, TRANSACTION_DATEKEY FROM {{ ref('im_pos_dim_pog_weekly') }} as SRC  )

/*
SRC_fpos           as ( SELECT * FROM pos.im_pos_fact_pos_weekly )
, SRC_ds             as ( SELECT * FROM pos.im_pos_dim_store )
, SRC_dif            as ( SELECT * FROM pos.im_pos_dim_item_fbin )
, SRC_ddf            as ( SELECT * FROM pos.im_pos_dim_date_fiscal_445 )
, SRC_dpw            as ( SELECT * FROM pos.im_pos_dim_pog_weekly )
*/
---- LOGIC LAYER ----

, LOGIC_fpos as (
    SELECT
        REPORTING_CUSTOMER
      , REPORTING_CHANNEL
      , PRODUCT_DEST_ZIP    --added to bring in product destination zipcode for Ferguson POS data
      , SKU
      , POS_QTY
      , CONSUMER_DOLLARS
      , GROSS_DOLLARS
      , BRAND
      , INV_QTY
      , INV_CONSUMER_DOLLARS
      , STORE_ID                                                     as                                           store_id
      , ITEM_ID                                                      as                                            item_id
      , TRANSACTION_DATEKEY                                          as                                transaction_datekey
    FROM SRC_fpos
)

, LOGIC_ds as (
    SELECT
        STORE_NAME
      , ADDRESS1
      , CITY
      , STATE
      , POSTAL_CODE
      , STORE_ID                                                     as                                        ds_store_id
      , REPORTING_CUSTOMER                                           as                              ds_reporting_customer
    FROM SRC_ds
)

, LOGIC_dif as (
    SELECT
        ITEM_NUMBER                                                  as                                               ITEM
      , BASE_MATERIAL
      , ITEM_TITLE                                                   as                                   ITEM_DESCRIPTION
      , ITEM_STATUS
      , ITEM_TYPE_CODE
      , ITEM_CATEGORY
      , ITEM_SUB_CATEGORY
      , ITEM_CLASS
      , ITEM_SUB_CLASS
      , ITEM_PRODUCT_TYPE
      , ITEM_ID                                                           as                                        dif_item_id
      , ITEM_PRODUCT_LINE 
    FROM SRC_dif
)

, LOGIC_ddf as (
    SELECT
        DATE                                                         as                                   TRANSACTION_DATE
      , FISCAL_445_CAL_MONTH_YYYYMM
      , FISCAL_445_CAL_QUARTER_YYYYQQ
      , FISCAL_445_CAL_WEEK_YYYYWW
      , FISCAL_445_CAL_DAY
      , FISCAL_445_CAL_MONTH
      , FISCAL_445_CAL_QUARTER
      , FISCAL_445_CAL_WEEK
      , FISCAL_445_CAL_YEAR
      , FISCAL_445_WORKING_DAY_FLAG
      , DATE_BK      as                                        ddf_date_bk    
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
      , FISCAL_LAST_QUARTER_FLAG
      , FISCAL_LAST_12_MONTHS_FLAG
      , FISCAL_QTD_FLAG

     FROM SRC_ddf         
)

, LOGIC_dpw as (
    SELECT
        STOCKED_STORE_FLAG
      , ACTIVE_SKU_FLAG
      , FISCAL_445_WEEK_START_DATE__YYYYMMDD
      , FISCAL_445_WEEK_END_DATE__YYYYMMDD
      , SKU                                                          as                                            dpw_sku
      , REPORTING_CUSTOMER                                           as                             dpw_reporting_customer
      , BRAND                                                        as                                          dpw_brand
      , ITEM_KEY                                                     as                                       dpw_item_key
      , STORE_ID                                                     as                                       dpw_store_id
      , TRANSACTION_DATEKEY                                          as                            dpw_transaction_datekey
    FROM SRC_dpw
)
---- RENAME LAYER ----

, RENAME_ddf as (
    SELECT
        TRANSACTION_DATE
      , FISCAL_445_CAL_MONTH_YYYYMM
      , FISCAL_445_CAL_QUARTER_YYYYQQ
      , FISCAL_445_CAL_WEEK_YYYYWW
      , FISCAL_445_CAL_DAY
      , FISCAL_445_CAL_MONTH
      , FISCAL_445_CAL_QUARTER
      , FISCAL_445_CAL_WEEK
      , FISCAL_445_CAL_YEAR
      , FISCAL_445_WORKING_DAY_FLAG
      , ddf_date_bk
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
       , FISCAL_LAST_QUARTER_FLAG
       , FISCAL_LAST_12_MONTHS_FLAG
       , FISCAL_QTD_FLAG
    FROM LOGIC_ddf
)

, RENAME_fpos as (
    SELECT
        REPORTING_CUSTOMER
      , REPORTING_CHANNEL
      , PRODUCT_DEST_ZIP
      , SKU
      , POS_QTY
      , CONSUMER_DOLLARS
      , GROSS_DOLLARS
      , BRAND
      , INV_QTY
      , INV_CONSUMER_DOLLARS
      , store_id
      , item_id
      , transaction_datekey
    FROM LOGIC_fpos
)

, RENAME_dif as (
    SELECT
        ITEM
      , BASE_MATERIAL
      , ITEM_DESCRIPTION
      , ITEM_STATUS
      , ITEM_TYPE_CODE
      , ITEM_CATEGORY
      , ITEM_SUB_CATEGORY
      , ITEM_CLASS
      , ITEM_SUB_CLASS
      , ITEM_PRODUCT_TYPE
      , dif_item_id
      , ITEM_PRODUCT_LINE
    FROM LOGIC_dif
)

, RENAME_ds as (
    SELECT
        STORE_NAME
      , ADDRESS1
      , CITY
      , STATE
      , POSTAL_CODE
      , ds_store_id
      , ds_reporting_customer
    FROM LOGIC_ds
)

, RENAME_dpw as (
    SELECT
        STOCKED_STORE_FLAG
      , ACTIVE_SKU_FLAG
      , FISCAL_445_WEEK_START_DATE__YYYYMMDD
      , FISCAL_445_WEEK_END_DATE__YYYYMMDD
      , dpw_reporting_customer
      , dpw_brand
      , dpw_item_key
      , dpw_sku
      , dpw_store_id
      , dpw_transaction_datekey
    FROM LOGIC_dpw
)
---- FILTER LAYER ----

, FILTER_fpos as (
    SELECT *
    FROM RENAME_fpos
)

, FILTER_ds as (
    SELECT *
    FROM RENAME_ds
)

, FILTER_dif as (
    SELECT *
    FROM RENAME_dif
)

, FILTER_ddf as (
    SELECT *
    FROM RENAME_ddf
)

, FILTER_dpw as (
    SELECT *
    FROM RENAME_dpw
)

, FULL_OUTER_JOIN_fpos_dpw as (
    SELECT
        COALESCE(fpos.REPORTING_CUSTOMER, dpw.dpw_reporting_customer)       as  REPORTING_CUSTOMER
        , fpos.REPORTING_CHANNEL                                            as  REPORTING_CHANNEL
        , fpos.PRODUCT_DEST_ZIP                                             as  PRODUCT_DEST_ZIP
        , COALESCE(fpos.SKU, dpw.dpw_sku)                                   as  SKU
        , fpos.POS_QTY                                                      as  POS_QTY
        , fpos.CONSUMER_DOLLARS                                             as  CONSUMER_DOLLARS
        , fpos.GROSS_DOLLARS                                                as  GROSS_DOLLARS
        , COALESCE(fpos.BRAND, dpw.dpw_brand)                               as  BRAND
        , fpos.INV_QTY                                                      as  INV_QTY
        , fpos.INV_CONSUMER_DOLLARS                                         as  INV_CONSUMER_DOLLARS
        , COALESCE(fpos.STORE_ID, dpw.dpw_store_id)                         as  STORE_ID
        , COALESCE(fpos.ITEM_ID, dpw.dpw_item_key)                          as  ITEM_ID
        , COALESCE(fpos.TRANSACTION_DATEKEY, dpw.dpw_transaction_datekey)   as  TRANSACTION_DATEKEY
        , dpw.ACTIVE_SKU_FLAG                                               as  ACTIVE_SKU_FLAG
        , COALESCE(dpw.STOCKED_STORE_FLAG, 0)                               as  STOCKED_STORE_FLAG
    FROM FILTER_fpos as fpos
    FULL OUTER JOIN FILTER_dpw as dpw
        ON fpos.REPORTING_CUSTOMER = dpw.dpw_reporting_customer
        AND fpos.BRAND = dpw.dpw_brand
        AND fpos.SKU = dpw.dpw_sku
        AND fpos.STORE_ID = dpw.dpw_store_id
        AND fpos.TRANSACTION_DATEKEY = dpw.dpw_transaction_datekey
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FULL_OUTER_JOIN_fpos_dpw as fpos_dpw
    LEFT JOIN FILTER_ds
        ON fpos_dpw.store_id = ds_store_id  AND fpos_dpw.reporting_customer  = ds_reporting_customer
    LEFT JOIN FILTER_dif
        ON fpos_dpw.item_id = dif_item_id
    LEFT JOIN FILTER_ddf
        ON fpos_dpw.transaction_datekey = ddf_date_bk
)

---- FINAL LAYER ----
SELECT
          TRANSACTION_DATE
        , REPORTING_CUSTOMER
        , REPORTING_CHANNEL
        , ITEM
        , SKU
        , BASE_MATERIAL
        , STORE_ID                                                     as LOCATION_ID
        , POS_QTY
        , CONSUMER_DOLLARS
        , GROSS_DOLLARS
        , BRAND
        , STORE_NAME
        , ADDRESS1
        , CITY
        , STATE
        , POSTAL_CODE
        , PRODUCT_DEST_ZIP
        , INV_QTY
        , INV_CONSUMER_DOLLARS
        , STOCKED_STORE_FLAG
        , ACTIVE_SKU_FLAG
        , ITEM_DESCRIPTION
        , ITEM_STATUS
        , ITEM_TYPE_CODE
        , ITEM_CATEGORY
        , ITEM_SUB_CATEGORY
        , ITEM_CLASS
        , ITEM_SUB_CLASS
        , ITEM_PRODUCT_TYPE
        , ITEM_PRODUCT_LINE
        , FISCAL_445_CAL_MONTH_YYYYMM
        , FISCAL_445_CAL_QUARTER_YYYYQQ
        , FISCAL_445_CAL_WEEK_YYYYWW
        , FISCAL_445_CAL_DAY
        , FISCAL_445_CAL_MONTH
        , FISCAL_445_CAL_QUARTER
        , FISCAL_445_CAL_WEEK
        , FISCAL_445_CAL_YEAR
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
       , FISCAL_LAST_QUARTER_FLAG
      , FISCAL_LAST_12_MONTHS_FLAG
      , FISCAL_QTD_FLAG
FROM JOIN_RESULT