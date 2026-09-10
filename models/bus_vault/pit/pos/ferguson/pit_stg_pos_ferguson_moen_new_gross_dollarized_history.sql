{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_h              as ( SELECT store_hk, store_bk, rec_src, bkcc FROM {{ ref('hub_store') }} as SRC  ),
SRC_sat_sales_moen_hist as ( SELECT salesorg, distribution_channel, customer_division, _file, hashdiff, year_month, date, transaction_type, sell_location_id, legacy_sell_location_id, sell_location_name, ship_location_zip, ship_location_city, ship_location_state, order_channel, build_com_order, customer_group, fei_product_code, fei_product_no, fei_product_description, vendor_code, shipped_qty, product_dest_city, product_dest_state, product_dest_zip_code, uom, load_dts, ship_customer_id, dest_customer_id, sap_material_number, file_source, gross_dollars, store_hk FROM {{ ref('sat_sales__moen_ferguson_new_gross_dollars_history') }} as SRC 
                        where year_month < '202507'
                        or year_month = '202507'
                        and date(load_dts) = '2025-08-19'
                        and date(psa_load_dts) = '2025-08-22'
                        /*this filter is to include static historic gross dollarized ferguson pos data from psa and exclude duplicated records in July 2025 caused by PSA resync to capture missing data */ )

/*
SRC_h              as ( SELECT * FROM raw_vault.hub_store )
SRC_sat_sales_moen_hist as ( SELECT * FROM raw_vault.sat_sales__moen_ferguson_new_gross_dollars_history )
*/
---- LOGIC LAYER ----

, LOGIC_h as (
    SELECT
        store_hk
      , store_bk                                                     as                                           store_id
      , rec_src
      , bkcc
    FROM SRC_h
)

, LOGIC_sat_sales_moen_hist as (
    SELECT
        salesorg                                                     as                                 sales_organization
      , distribution_channel
      , customer_division
      , _file
      , hashdiff
      , year_month
      , date
      , transaction_type
      , sell_location_id
      , legacy_sell_location_id
      , sell_location_name
      , ship_location_zip
      , ship_location_city
      , ship_location_state
      , order_channel
      , build_com_order
      , customer_group
      , fei_product_code                                             as                                                sku
      , fei_product_no
      , fei_product_description
      , vendor_code
      , shipped_qty
      , product_dest_city
      , product_dest_state
      , product_dest_zip_code
      , uom
      , load_dts
      , ship_customer_id
      , dest_customer_id
      , sap_material_number                                          as                                        item_number
      , file_source
      , gross_dollars
      , store_hk                                                     as                       sat_sales_moen_hist_store_hk
    FROM SRC_sat_sales_moen_hist
)
---- RENAME LAYER ----

, RENAME_h as (
    SELECT
        store_hk
      , store_id
      , rec_src
      , bkcc
    FROM LOGIC_h
)

, RENAME_sat_sales_moen_hist as (
    SELECT
        sales_organization
      , distribution_channel
      , customer_division
      , _file
      , hashdiff
      , year_month
      , date
      , transaction_type
      , sell_location_id
      , legacy_sell_location_id
      , sell_location_name
      , ship_location_zip
      , ship_location_city
      , ship_location_state
      , order_channel
      , build_com_order
      , customer_group
      , sku
      , fei_product_no
      , fei_product_description
      , vendor_code
      , shipped_qty
      , product_dest_city
      , product_dest_state
      , product_dest_zip_code
      , uom
      , load_dts
      , ship_customer_id
      , dest_customer_id
      , item_number
      , file_source
      , gross_dollars
      , sat_sales_moen_hist_store_hk
    FROM LOGIC_sat_sales_moen_hist
)
---- FILTER LAYER ----

, FILTER_h as (
    SELECT *
    FROM RENAME_h
)

, FILTER_sat_sales_moen_hist as (
    SELECT *
    FROM RENAME_sat_sales_moen_hist
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_h
    INNER JOIN FILTER_sat_sales_moen_hist
        ON FILTER_h.store_hk = sat_sales_moen_hist_store_hk
)

---- FINAL LAYER ----
SELECT
           'FERGUSON'                                                  as REPORTING_CUSTOMER
        , STORE_HK
        , STORE_ID
        , SALES_ORGANIZATION
        , DISTRIBUTION_CHANNEL
        , CUSTOMER_DIVISION
        , _FILE
        , row_number() over (order by hashdiff)                        as _LINE
        , YEAR_MONTH
        , DATE
        , TRANSACTION_TYPE
        , SELL_LOCATION_ID
        , LEGACY_SELL_LOCATION_ID
        , SELL_LOCATION_NAME
        , SHIP_LOCATION_ZIP
        , SHIP_LOCATION_CITY
        , SHIP_LOCATION_STATE
        , ORDER_CHANNEL
        , BUILD_COM_ORDER
        , CUSTOMER_GROUP
        , SKU
        , FEI_PRODUCT_NO
        , FEI_PRODUCT_DESCRIPTION
        , VENDOR_CODE
        , SHIPPED_QTY
        , PRODUCT_DEST_CITY
        , PRODUCT_DEST_STATE
        , PRODUCT_DEST_ZIP_CODE
        , UOM
        , LOAD_DTS
        , SHIP_CUSTOMER_ID
        , DEST_CUSTOMER_ID
        , ITEM_NUMBER
        , FILE_SOURCE
        ,  'MOEN'                                                      as BRAND
        , GROSS_DOLLARS
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
