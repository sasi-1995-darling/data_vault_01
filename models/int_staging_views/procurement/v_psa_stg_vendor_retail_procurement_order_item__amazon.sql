---- SRC LAYER ----
WITH
SRC_a              as ( SELECT AMAZON_PRODUCT_IDENTIFIER, AMOUNT, IS_BACK_ORDER_ALLOWED, ITEM_SEQUENCE_NUMBER, LIST_PRICE_AMOUNT, LIST_PRICE_CURRENCY_CODE, NET_COST_AMOUNT, NET_COST_CURRENCY_CODE, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PURCHASE_ORDER_NUMBER, UNIT_OF_MEASURE, UNIT_SIZE, VENDOR_PRODUCT_IDENTIFIER, _FIVETRAN_SYNCED FROM {{ source('amazon_sp_ft_moen_inc', 'vendor_retail_procurement_order_item') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM amazon_sp_ft_moen_inc.vendor_retail_procurement_order_item )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        ITEM_SEQUENCE_NUMBER
      , PURCHASE_ORDER_NUMBER
      , AMAZON_PRODUCT_IDENTIFIER
      , VENDOR_PRODUCT_IDENTIFIER
      , AMOUNT
      , UNIT_OF_MEASURE
      , UNIT_SIZE
      , IS_BACK_ORDER_ALLOWED
      , NET_COST_CURRENCY_CODE
      , NET_COST_AMOUNT
      , LIST_PRICE_CURRENCY_CODE
      , LIST_PRICE_AMOUNT
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , IFF(
        PSA_DELETE_IND = 'Y',
        PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC',_FIVETRAN_SYNCED)) as LOAD_DTS
      , COALESCE(NULLIF(UPPER(TRIM(PURCHASE_ORDER_NUMBER)), ''), '-1') as VENDOR_ORDER_BK
      , COALESCE(NULLIF(UPPER(TRIM(ITEM_SEQUENCE_NUMBER)), ''), '-1') as VENDOR_ORDER_LINE_BK
    FROM SRC_a
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        ITEM_SEQUENCE_NUMBER
      , PURCHASE_ORDER_NUMBER
      , AMAZON_PRODUCT_IDENTIFIER
      , VENDOR_PRODUCT_IDENTIFIER
      , AMOUNT
      , UNIT_OF_MEASURE
      , UNIT_SIZE
      , IS_BACK_ORDER_ALLOWED
      , NET_COST_CURRENCY_CODE
      , NET_COST_AMOUNT
      , LIST_PRICE_CURRENCY_CODE
      , LIST_PRICE_AMOUNT
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , VENDOR_ORDER_BK
      , VENDOR_ORDER_LINE_BK
    FROM LOGIC_a
)

, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'US.API_FT.AMAZON_VC.VENDOR_RETAIL_PROCUREMENT_ORDER_ITEM'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          ITEM_SEQUENCE_NUMBER
        , PURCHASE_ORDER_NUMBER
        , AMAZON_PRODUCT_IDENTIFIER
        , VENDOR_PRODUCT_IDENTIFIER
        , AMOUNT
        , UNIT_OF_MEASURE
        , UNIT_SIZE
        , IS_BACK_ORDER_ALLOWED
        , NET_COST_CURRENCY_CODE
        , NET_COST_AMOUNT
        , LIST_PRICE_CURRENCY_CODE
        , LIST_PRICE_AMOUNT
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , VENDOR_ORDER_BK              
        , VENDOR_ORDER_LINE_BK         
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(VENDOR_ORDER_BK), ''), '^^'),
          COALESCE(NULLIF(TRIM(VENDOR_ORDER_LINE_BK), ''), '^^'),
          COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as VENDOR_ORDER_ITEM_HK
        
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
            IFNULL(TRIM(AMAZON_PRODUCT_IDENTIFIER::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_PRODUCT_IDENTIFIER::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_OF_MEASURE::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_SIZE::text), '^^') 
            , '||', IFNULL(TRIM(IS_BACK_ORDER_ALLOWED::text), '^^') 
            , '||', IFNULL(TRIM(NET_COST_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(NET_COST_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(LIST_PRICE_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(LIST_PRICE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PSA_LOAD_DTS::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
