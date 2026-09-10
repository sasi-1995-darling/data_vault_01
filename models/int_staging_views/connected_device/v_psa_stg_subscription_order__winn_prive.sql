---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT CHARGED_AMOUNT, CREATED_AT, CURRENCY_CODE, DELIVERY_AMOUNT, EXTERNAL_ID, ID, IS_SKIPPED, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PURCHASE_DATE, STATUS, SUBSCRIBER_ID, SUBSCRIPTION_CHARGED_AMOUNT, TAX, TYPE, UPDATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('prive_moen', 'orders') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_OR             as ( SELECT ID, NAME FROM {{ source('shopify_moen', 'ORDER') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ID ORDER BY _FIVETRAN_SYNCED DESC) )

/*
SRC_D1             as ( SELECT * FROM PRIVE_MOEN.ORDERS )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_OR             as ( SELECT * FROM SHOPIFY_MOEN.ORDER )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        ID                                                           as                              SUBSCRIPTION_ORDER_BK
      , SUBSCRIBER_ID                                                as                                      SUBSCRIBER_BK
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , ID
      , _FIVETRAN_DELETED
      , SUBSCRIBER_ID
      , _FIVETRAN_SYNCED
      , CREATED_AT
      , EXTERNAL_ID
      , TAX
      , TYPE
      , DELIVERY_AMOUNT
      , CURRENCY_CODE
      , CHARGED_AMOUNT
      , UPDATED_AT
      , IS_SKIPPED
      , SUBSCRIPTION_CHARGED_AMOUNT
      , PURCHASE_DATE
      , STATUS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , TRY_CAST(REPLACE(EXTERNAL_ID, 'gid://shopify/Order/', '') AS NUMBER) as                                   SHOPIFY_ORDER_ID
    FROM SRC_D1
)

, LOGIC_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A1
)

, LOGIC_OR as (
    SELECT
        COALESCE(NAME, '-1')                                         as                                    ORDER_HEADER_BK
      , ID                                                           as                                              OR_ID
      , NAME                                                         as                                            OR_NAME
    FROM SRC_OR
)
---- RENAME LAYER ----

, RENAME_D1 as (
    SELECT
        SUBSCRIPTION_ORDER_BK
      , SUBSCRIBER_BK
      , LOAD_DTS
      , ID
      , _FIVETRAN_DELETED
      , SUBSCRIBER_ID
      , _FIVETRAN_SYNCED
      , CREATED_AT
      , EXTERNAL_ID
      , TAX
      , TYPE
      , DELIVERY_AMOUNT
      , CURRENCY_CODE
      , CHARGED_AMOUNT
      , UPDATED_AT
      , IS_SKIPPED
      , SUBSCRIPTION_CHARGED_AMOUNT
      , PURCHASE_DATE
      , STATUS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , SHOPIFY_ORDER_ID
    FROM LOGIC_D1
)

, RENAME_OR as (
    SELECT
        ORDER_HEADER_BK
      , OR_ID
      , OR_NAME
    FROM LOGIC_OR
)

, RENAME_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A1
)
---- FILTER LAYER ----

, FILTER_D1 as (
    SELECT *
    FROM RENAME_D1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'US.PRIVE_MOEN.ORDERS'
)

, FILTER_OR as (
    SELECT *
    FROM RENAME_OR
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_D1
    INNER JOIN FILTER_A1
        ON '1' = '1'
    LEFT JOIN FILTER_OR
        ON SHOPIFY_ORDER_ID = OR_ID
)

---- FINAL LAYER ----
SELECT
          SUBSCRIPTION_ORDER_BK
        , SUBSCRIBER_BK
        , ORDER_HEADER_BK
        , LOAD_DTS
        , ID
        , _FIVETRAN_DELETED
        , SUBSCRIBER_ID
        , _FIVETRAN_SYNCED
        , CREATED_AT
        , EXTERNAL_ID
        , TAX
        , TYPE
        , DELIVERY_AMOUNT
        , CURRENCY_CODE
        , CHARGED_AMOUNT
        , UPDATED_AT
        , IS_SKIPPED
        , SUBSCRIPTION_CHARGED_AMOUNT
        , PURCHASE_DATE
        , STATUS
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , SHOPIFY_ORDER_ID
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUBSCRIPTION_ORDER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SUBSCRIBER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUBSCRIBER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SUBSCRIBER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_SUBSCRIPTION_ORDER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(EXTERNAL_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX::text), '^^') 
            , '||', IFNULL(TRIM(TYPE::text), '^^') 
            , '||', IFNULL(TRIM(DELIVERY_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CHARGED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(IS_SKIPPED::text), '^^') 
            , '||', IFNULL(TRIM(SUBSCRIPTION_CHARGED_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
