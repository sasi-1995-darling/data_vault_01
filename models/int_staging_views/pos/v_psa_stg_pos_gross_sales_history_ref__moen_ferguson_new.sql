---- SRC LAYER ----
WITH
SRC_ref            as ( SELECT SALESORG, DISTRIBUTION_CHANNEL, CUSTOMER_DIVISION, _FILE, YEAR_MONTH, DATE, TRANSACTION_TYPE, SELL_LOCATION_ID, LEGACY_SELL_LOCATION_ID, SELL_LOCATION_NAME, SHIP_LOCATION_ZIP, LEGACY_SHIP_LOCATION_ID, SHIP_LOCATION_NAME, SHIP_LOCATION_CITY, SHIP_LOCATION_STATE, ORDER_CHANNEL, BUILD_COM_ORDER, CUSTOMER_GROUP, FEI_PRODUCT_NO, FEI_PRODUCT_CODE, FEI_PRODUCT_DESCRIPTION, VENDOR_CODE, SHIPPED_QTY, PRODUCT_DEST_CITY, PRODUCT_DEST_STATE, PRODUCT_DEST_ZIP, UOM, _FIVETRAN_SYNCED, SHIP_CUSTOMER, DEST_CUSTOMER, SAP_MATERIAL_NUMBER, FILE_SOURCE, GROSS_DOLLARS, PM_SNAPSHOT_DATE, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND FROM {{ source('ferguson', 'ref_ferguson_moen_gross_price_new_structure') }} as SRC  ),
SRC_A              as ( SELECT REC_SRC, BKCC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_fbi            as ( SELECT ZIP, CITY, STATE, BRANCH_NAME, BRANCH FROM {{ source('ferguson', 'ff_ferguson_branch_index') }} as SRC  )

/*
SRC_ref            as ( SELECT * FROM ferguson.ref_ferguson_moen_gross_price_new_structure )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_fbi            as ( SELECT * FROM ferguson.ff_ferguson_branch_index )
*/
---- LOGIC LAYER ----

, LOGIC_ref as (
    SELECT
        SALESORG
      , DISTRIBUTION_CHANNEL
      , CUSTOMER_DIVISION
      , _FILE
      , YEAR_MONTH
      , DATE
      , TRANSACTION_TYPE
      , TO_NUMBER(SELL_LOCATION_ID)::VARCHAR                         as                                   SELL_LOCATION_ID
      , LEGACY_SELL_LOCATION_ID
      , SELL_LOCATION_NAME
      , SHIP_LOCATION_ZIP
      , LEGACY_SHIP_LOCATION_ID
      , SHIP_LOCATION_NAME
      , SHIP_LOCATION_CITY
      , SHIP_LOCATION_STATE
      , ORDER_CHANNEL
      , BUILD_COM_ORDER
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
      , _FIVETRAN_SYNCED
      , SHIP_CUSTOMER
      , LPAD(TRIM(SHIP_CUSTOMER), 10, 0)::varchar                    as                                   SHIP_CUSTOMER_ID
      , DEST_CUSTOMER
      , LPAD(TRIM(DEST_CUSTOMER), 10, 0)::varchar                    as                                   DEST_CUSTOMER_ID
      , SAP_MATERIAL_NUMBER
      , FILE_SOURCE
      , GROSS_DOLLARS
      , PM_SNAPSHOT_DATE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PM_SNAPSHOT_DATE)                    as                                           LOAD_DTS
    FROM SRC_ref
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)

, LOGIC_fbi as (
    SELECT
        lpad(substring(case when position( '-',trim(ZIP),1) > 0 then left(trim(ZIP),position( '-',trim(ZIP),1)-1) else trim(ZIP) end,1,5),5,'0') as                                                ZIP
      , UPPER(CITY)                                                  as                                               CITY
      , STATE
      , BRANCH_NAME
      , BRANCH::varchar                                              as                                             BRANCH
    FROM SRC_fbi
)
---- RENAME LAYER ----

, RENAME_ref as (
    SELECT
        SALESORG
      , DISTRIBUTION_CHANNEL
      , CUSTOMER_DIVISION
      , _FILE
      , YEAR_MONTH
      , DATE
      , TRANSACTION_TYPE
      , SELL_LOCATION_ID
      , LEGACY_SELL_LOCATION_ID
      , SELL_LOCATION_NAME
      , SHIP_LOCATION_ZIP
      , LEGACY_SHIP_LOCATION_ID
      , SHIP_LOCATION_NAME
      , SHIP_LOCATION_CITY
      , SHIP_LOCATION_STATE
      , ORDER_CHANNEL
      , BUILD_COM_ORDER
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
      , _FIVETRAN_SYNCED
      , SHIP_CUSTOMER
      , SHIP_CUSTOMER_ID
      , DEST_CUSTOMER
      , DEST_CUSTOMER_ID
      , SAP_MATERIAL_NUMBER
      , FILE_SOURCE
      , GROSS_DOLLARS
      , PM_SNAPSHOT_DATE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_ref
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)

, RENAME_fbi as (
    SELECT
        ZIP
      , CITY
      , STATE
      , BRANCH_NAME
      , BRANCH
    FROM LOGIC_fbi
)
---- FILTER LAYER ----

, FILTER_ref as (
    SELECT *
    FROM RENAME_ref
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'FBIN.SILVER.FERGUSON.FERGUSON_MOEN_GROSS_PRICE_NEW_STRUCTURE'
)

, FILTER_fbi as (
    SELECT *
    FROM RENAME_fbi
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_ref
    INNER JOIN FILTER_A
        ON '1' = '1'
    LEFT JOIN FILTER_fbi
        ON FILTER_ref.product_dest_zip_code = zip AND file_source = 'GROVE' AND product_dest_state = state AND product_dest_city = city AND branch_name ilike '%grove supply%'
)

---- FINAL LAYER ----
SELECT
          coalesce(nullif(trim(SELL_LOCATION_ID),''),BRANCH, 'GROVE_HISTORIC') as STORE_BK
        , SALESORG
        , DISTRIBUTION_CHANNEL
        , CUSTOMER_DIVISION
        , _FILE
        , YEAR_MONTH
        , DATE
        , TRANSACTION_TYPE
        , SELL_LOCATION_ID
        , LEGACY_SELL_LOCATION_ID
        , SELL_LOCATION_NAME
        , SHIP_LOCATION_ZIP
        , LEGACY_SHIP_LOCATION_ID
        , SHIP_LOCATION_NAME
        , SHIP_LOCATION_CITY
        , SHIP_LOCATION_STATE
        , ORDER_CHANNEL
        , BUILD_COM_ORDER
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
        , _FIVETRAN_SYNCED
        , SHIP_CUSTOMER
        , SHIP_CUSTOMER_ID
        , DEST_CUSTOMER
        , DEST_CUSTOMER_ID
        , SAP_MATERIAL_NUMBER
        , FILE_SOURCE
        , GROSS_DOLLARS
        , PM_SNAPSHOT_DATE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , ROW_NUMBER() OVER ( PARTITION BY _FIVETRAN_SYNCED::DATE ORDER BY HASH(*) ) as UNIQUE_ROW_NUM
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(STORE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SALESORG::text), '^^') 
            , '||', IFNULL(TRIM(DISTRIBUTION_CHANNEL::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_DIVISION::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SELL_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(LEGACY_SELL_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(SELL_LOCATION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_LOCATION_ZIP::text), '^^') 
            , '||', IFNULL(TRIM(LEGACY_SHIP_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_LOCATION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_LOCATION_CITY::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_LOCATION_STATE::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_CHANNEL::text), '^^') 
            , '||', IFNULL(TRIM(BUILD_COM_ORDER::text), '^^') 
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
            , '||', IFNULL(TRIM(SHIP_CUSTOMER::text), '^^') 
            , '||', IFNULL(TRIM(DEST_CUSTOMER::text), '^^') 
            , '||', IFNULL(TRIM(SAP_MATERIAL_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(FILE_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(GROSS_DOLLARS::text), '^^') 
            , '||', IFNULL(TRIM(PM_SNAPSHOT_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LOAD_DTS::text), '^^') 
            , '||', IFNULL(TRIM(UNIQUE_ROW_NUM::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
