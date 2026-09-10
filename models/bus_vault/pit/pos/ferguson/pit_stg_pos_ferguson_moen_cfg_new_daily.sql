{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_h              as ( SELECT store_hk, store_bk, rec_src, bkcc FROM {{ ref('hub_store') }} as SRC  ),
SRC_sat_sales_moen_cfg as ( SELECT _file, _line, year_month, date, transaction_type, sell_location_id, legacy_sell_location_id, sell_location_name, ship_location_zip, ship_location_city, ship_location_state, order_channel, build_com_order, customer_group, fei_product_code, fei_product_no, fei_product_description, vendor_code, shipped_qty, product_dest_city, product_dest_state, product_dest_zip_code, uom, load_dts, store_hk FROM {{ ref('sat_sales__moen_cfg_ferguson_new') }} as SRC 
                        qualify (row_number() over(partition by store_hk, _line, _file order by load_dts desc))=1 ),
SRC_ref_item_moen_cfg as ( SELECT moen_item_number, fei_product_number FROM {{ ref('ref_pos_item__ferguson_moen_xref') }} as SRC 
                        where psa_delete_ind = 'N'
                        qualify (row_number() over(partition by fei_product_number, moen_item_number, moen_key_account_number order by load_dts desc))=1 ),
SRC_ref_zip_moen_cfg as ( SELECT moen_customer_id, zip_code FROM {{ ref('ref_pos_customer_zip__ferguson_moen_xref') }} as SRC 
                        where psa_delete_ind = 'N'
                        qualify (row_number() over(partition by zip_code, moen_customer_id order by load_dts desc))=1 ),
SRC_ref_zip_moen_ship_cfg as ( SELECT moen_customer_id, zip_code FROM {{ ref('ref_pos_customer_zip__ferguson_moen_xref') }} as SRC 
                        where psa_delete_ind = 'N'
                        qualify (row_number() over(partition by zip_code, moen_customer_id order by load_dts desc))=1 )

/*
SRC_h              as ( SELECT * FROM raw_vault.hub_store )
SRC_sat_sales_moen_cfg as ( SELECT * FROM raw_vault.sat_sales__moen_cfg_ferguson_new )
SRC_ref_item_moen_cfg as ( SELECT * FROM bus_vault.ref_pos_item__ferguson_moen_xref )
SRC_ref_zip_moen_cfg as ( SELECT * FROM bus_vault.ref_pos_customer_zip__ferguson_moen_xref )
SRC_ref_zip_moen_ship_cfg as ( SELECT * FROM bus_vault.ref_pos_customer_zip__ferguson_moen_xref )
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

, LOGIC_sat_sales_moen_cfg as (
    SELECT
        _file
      , _line
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
      , store_hk                                                     as                        sat_sales_moen_cfg_store_hk
      , fei_product_code                                             as                sat_sales_moen_cfg_fei_product_code
      , product_dest_zip_code                                        as           sat_sales_moen_cfg_product_dest_zip_code
      , lpad(substring(case when position( '-',trim(ship_location_zip),1) > 0 then left(trim(ship_location_zip),position( '-',trim(ship_location_zip),1)-1) else trim(ship_location_zip) end,1,5),5,'0') as          sat_sales_moen_cfg_ship_location_zip_code
    FROM SRC_sat_sales_moen_cfg
)

, LOGIC_ref_item_moen_cfg as (
    SELECT
        moen_item_number                                             as                                        item_number
      , fei_product_number                                           as               ref_item_moen_cfg_fei_product_number
    FROM SRC_ref_item_moen_cfg
)

, LOGIC_ref_zip_moen_cfg as (
    SELECT
        moen_customer_id                                             as                                   ship_customer_id
      , zip_code                                                     as                          ref_zip_moen_cfg_zip_code
    FROM SRC_ref_zip_moen_cfg
)

, LOGIC_ref_zip_moen_ship_cfg as (
    SELECT
        moen_customer_id                                             as                                   dest_customer_id
      , zip_code                                                     as                     ref_zip_moen_ship_cfg_zip_code
    FROM SRC_ref_zip_moen_ship_cfg
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

, RENAME_sat_sales_moen_cfg as (
    SELECT
        _file
      , _line
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
      , sat_sales_moen_cfg_store_hk
      , sat_sales_moen_cfg_fei_product_code
      , sat_sales_moen_cfg_product_dest_zip_code
      , sat_sales_moen_cfg_ship_location_zip_code
    FROM LOGIC_sat_sales_moen_cfg
)

, RENAME_ref_zip_moen_cfg as (
    SELECT
        ship_customer_id
      , ref_zip_moen_cfg_zip_code
    FROM LOGIC_ref_zip_moen_cfg
)

, RENAME_ref_zip_moen_ship_cfg as (
    SELECT
        dest_customer_id
      , ref_zip_moen_ship_cfg_zip_code
    FROM LOGIC_ref_zip_moen_ship_cfg
)

, RENAME_ref_item_moen_cfg as (
    SELECT
        item_number
      , ref_item_moen_cfg_fei_product_number
    FROM LOGIC_ref_item_moen_cfg
)
---- FILTER LAYER ----

, FILTER_h as (
    SELECT *
    FROM RENAME_h
)

, FILTER_sat_sales_moen_cfg as (
    SELECT *
    FROM RENAME_sat_sales_moen_cfg
)

, FILTER_ref_item_moen_cfg as (
    SELECT *
    FROM RENAME_ref_item_moen_cfg
)

, FILTER_ref_zip_moen_cfg as (
    SELECT *
    FROM RENAME_ref_zip_moen_cfg
)

, FILTER_ref_zip_moen_ship_cfg as (
    SELECT *
    FROM RENAME_ref_zip_moen_ship_cfg
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_h
    INNER JOIN FILTER_sat_sales_moen_cfg
        ON FILTER_h.store_hk = sat_sales_moen_cfg_store_hk
    LEFT JOIN FILTER_ref_item_moen_cfg
        ON sat_sales_moen_cfg_fei_product_code = ref_item_moen_cfg_fei_product_number
    LEFT JOIN FILTER_ref_zip_moen_cfg
        ON sat_sales_moen_cfg_product_dest_zip_code = ref_zip_moen_cfg_zip_code
    LEFT JOIN FILTER_ref_zip_moen_ship_cfg
        ON sat_sales_moen_cfg_ship_location_zip_code = ref_zip_moen_ship_cfg_zip_code
)

---- FINAL LAYER ----
SELECT
           'FERGUSON'                                                  as REPORTING_CUSTOMER
        , STORE_HK
        , STORE_ID
        ,  'USFS'                                                      as SALES_ORGANIZATION
        ,  'WH'                                                        as DISTRIBUTION_CHANNEL
        ,  'FS'                                                        as CUSTOMER_DIVISION
        , _FILE
        , _LINE
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
        ,  'MOEN'                                                      as FILE_SOURCE
        ,  'MOEN'                                                      as BRAND
        , null                                                         as GROSS_DOLLARS
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
