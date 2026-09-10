---- SRC LAYER ----
WITH
SRC_S              as ( SELECT _FILE, _MODIFIED, _FIVETRAN_SYNCED, YEAR_MONTH, DATE, TRANSACTION_TYPE, SELL_LOCATION_ID, LEGACY_SELL_LOCATION_ID, SELL_LOCATION_NAME, SHIP_LOCATION_ID, LEGACY_SHIP_LOCATION_ID, SHIP_LOCATION_NAME, SHIP_LOCATION_CITY, SHIP_LOCATION_STATE, SHIP_LOCATION_ZIP, ORDER_CHANNEL, FULFILLMENT_CHANNEL, SOURCE_SYSTEM, CUSTOMER_TYPE, CUSTOMER_GROUP, FEI_PRODUCT_NO, FEI_PRODUCT_CODE, FEI_PRODUCT_DESCRIPTION, VENDOR_CODE, SHIPPED_QTY, PRODUCT_DEST_CITY, PRODUCT_DEST_STATE, PRODUCT_DEST_ZIP, UOM, BUILD_COM_ORDER, INVOICE, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND, _LINE FROM {{ source('ferguson', 'moen_m_3_a_new_cfg') }} as SRC  ),
SRC_A              as ( SELECT REC_SRC, BKCC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM ferguson.moen_m_3_a_new_cfg )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        coalesce(nullif(trim(SELL_LOCATION_ID),''),'-1')             as                                           STORE_BK
      , _FILE
      , _MODIFIED
      , _FIVETRAN_SYNCED
      , YEAR_MONTH
      , DATE
      , TRANSACTION_TYPE
      , SELL_LOCATION_ID
      , LEGACY_SELL_LOCATION_ID
      , SELL_LOCATION_NAME
      , SHIP_LOCATION_ID
      , LEGACY_SHIP_LOCATION_ID
      , SHIP_LOCATION_NAME
      , SHIP_LOCATION_CITY
      , SHIP_LOCATION_STATE
      , SHIP_LOCATION_ZIP
      , ORDER_CHANNEL
      , FULFILLMENT_CHANNEL
      , SOURCE_SYSTEM
      , CUSTOMER_TYPE
      , CUSTOMER_GROUP
      , FEI_PRODUCT_NO
      , FEI_PRODUCT_CODE
      , FEI_PRODUCT_DESCRIPTION
      , VENDOR_CODE
      , SHIPPED_QTY
      , PRODUCT_DEST_CITY
      , PRODUCT_DEST_STATE
      , PRODUCT_DEST_ZIP
      , lpad(substring(case when position( '-',trim(PRODUCT_DEST_ZIP),1) > 0 then left(trim(PRODUCT_DEST_ZIP),position( '-',trim(PRODUCT_DEST_ZIP),1)-1) else trim(PRODUCT_DEST_ZIP) end,1,5),5,'0') as                              PRODUCT_DEST_ZIP_CODE
      , UOM
      , BUILD_COM_ORDER
      , INVOICE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , _LINE
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        STORE_BK
      , _FILE
      , _MODIFIED
      , _FIVETRAN_SYNCED
      , YEAR_MONTH
      , DATE
      , TRANSACTION_TYPE
      , SELL_LOCATION_ID
      , LEGACY_SELL_LOCATION_ID
      , SELL_LOCATION_NAME
      , SHIP_LOCATION_ID
      , LEGACY_SHIP_LOCATION_ID
      , SHIP_LOCATION_NAME
      , SHIP_LOCATION_CITY
      , SHIP_LOCATION_STATE
      , SHIP_LOCATION_ZIP
      , ORDER_CHANNEL
      , FULFILLMENT_CHANNEL
      , SOURCE_SYSTEM
      , CUSTOMER_TYPE
      , CUSTOMER_GROUP
      , FEI_PRODUCT_NO
      , FEI_PRODUCT_CODE
      , FEI_PRODUCT_DESCRIPTION
      , VENDOR_CODE
      , SHIPPED_QTY
      , PRODUCT_DEST_CITY
      , PRODUCT_DEST_STATE
      , PRODUCT_DEST_ZIP
      , PRODUCT_DEST_ZIP_CODE
      , UOM
      , BUILD_COM_ORDER
      , INVOICE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , _LINE
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'US.EXCEL.FERGUSON.MOEN_M_3_A_NEW_CFG'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          STORE_BK
        , _LINE::varchar                                               as _LINE
        , _FILE
        , _MODIFIED
        , _FIVETRAN_SYNCED
        , YEAR_MONTH
        , DATE
        , TRANSACTION_TYPE
        , SELL_LOCATION_ID
        , LEGACY_SELL_LOCATION_ID
        , SELL_LOCATION_NAME
        , SHIP_LOCATION_ID
        , LEGACY_SHIP_LOCATION_ID
        , SHIP_LOCATION_NAME
        , SHIP_LOCATION_CITY
        , SHIP_LOCATION_STATE
        , SHIP_LOCATION_ZIP
        , ORDER_CHANNEL
        , FULFILLMENT_CHANNEL
        , SOURCE_SYSTEM
        , CUSTOMER_TYPE
        , CUSTOMER_GROUP
        , FEI_PRODUCT_NO
        , FEI_PRODUCT_CODE
        , FEI_PRODUCT_DESCRIPTION
        , VENDOR_CODE
        , SHIPPED_QTY
        , PRODUCT_DEST_CITY
        , PRODUCT_DEST_STATE
        , PRODUCT_DEST_ZIP
        , PRODUCT_DEST_ZIP_CODE
        , UOM
        , BUILD_COM_ORDER
        , INVOICE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as LOAD_DTS
        , REC_SRC
        , BKCC
        , coalesce(nullif(trim(SELL_LOCATION_ID),''),'-1')             as SELLING_STORE_BK
        , coalesce(nullif(trim(SHIP_LOCATION_ID),''),'-1')             as SHIPPING_STORE_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(STORE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SELLING_STORE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SELLING_STORE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SHIPPING_STORE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SHIPPING_STORE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SELLING_STORE_HK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SHIPPING_STORE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SELLING_SHIPPING_STORE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(_MODIFIED::text), '^^') 
            , '||', IFNULL(TRIM(YEAR_MONTH::text), '^^') 
            , '||', IFNULL(TRIM(DATE::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SELL_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(LEGACY_SELL_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(SELL_LOCATION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(LEGACY_SHIP_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_LOCATION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_LOCATION_CITY::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_LOCATION_STATE::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_LOCATION_ZIP::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_CHANNEL::text), '^^') 
            , '||', IFNULL(TRIM(FULFILLMENT_CHANNEL::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_SYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(FEI_PRODUCT_NO::text), '^^') 
            , '||', IFNULL(TRIM(FEI_PRODUCT_CODE::text), '^^') 
            , '||', IFNULL(TRIM(FEI_PRODUCT_DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPED_QTY::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_DEST_CITY::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_DEST_STATE::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_DEST_ZIP::text), '^^') 
            , '||', IFNULL(TRIM(UOM::text), '^^') 
            , '||', IFNULL(TRIM(BUILD_COM_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
