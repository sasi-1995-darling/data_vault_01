---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT CREATED_AT, ID, LOCATION_ID, NAME, ORDER_ID, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, RECEIPT_AUTHORIZATION, SERVICE, SHIPMENT_STATUS, STATUS, TRACKING_COMPANY, TRACKING_NUMBER, TRACKING_NUMBERS, TRACKING_URLS, UPDATED_AT, _FIVETRAN_SYNCED
                        /* Syndicate delete filter: suppress truncate-reload artifact deletes (Y+N in same batch) */
                        , CASE WHEN PSA_DELETE_IND = 'Y'
                             AND COUNT_IF(PSA_DELETE_IND = 'N') OVER (PARTITION BY ID, _FIVETRAN_SYNCED) > 0
                               THEN TRUE ELSE FALSE END AS TRUNCATE_RELOAD_FLAG
                        FROM {{ source('shopify_moen', 'fulfillment') }} as SRC
                        QUALIFY NOT TRUNCATE_RELOAD_FLAG  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_OR             as ( SELECT ID, NAME FROM {{ source('shopify_moen', 'ORDER') }} as SRC  
                        qualify row_number() over (partition by ID order by _fivetran_synced desc) = 1
                        )

/*
SRC_D1             as ( SELECT * FROM SHOPIFY_MOEN.FULFILLMENT )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_OR             as ( SELECT * FROM SHOPIFY_MOEN.ORDER )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        TO_CHAR(ID)                                                  as                                     FULFILLMENT_BK
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , ID
      , ORDER_ID
      , LOCATION_ID
      , CREATED_AT
      , UPDATED_AT
      , STATUS
      , SERVICE
      , TRACKING_COMPANY
      , TRACKING_NUMBER
      , SHIPMENT_STATUS
      , TRACKING_NUMBERS
      , TRACKING_URLS
      , NAME
      , RECEIPT_AUTHORIZATION
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
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
        COALESCE(NAME, '-1')                                      as                                    ORDER_HEADER_BK
      , ID                                                           as                                              OR_ID
      , NAME                                                         as                                            OR_NAME
    FROM SRC_OR
)
---- RENAME LAYER ----

, RENAME_D1 as (
    SELECT
        FULFILLMENT_BK
      , LOAD_DTS
      , ID
      , ORDER_ID
      , LOCATION_ID
      , CREATED_AT
      , UPDATED_AT
      , STATUS
      , SERVICE
      , TRACKING_COMPANY
      , TRACKING_NUMBER
      , SHIPMENT_STATUS
      , TRACKING_NUMBERS
      , TRACKING_URLS
      , NAME
      , RECEIPT_AUTHORIZATION
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
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
    WHERE rec_src = 'US.SHOPIFY_MOEN.FULFILLMENT'
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
        ON ORDER_ID = OR_ID
)

---- FINAL LAYER ----
SELECT
          FULFILLMENT_BK
        , ORDER_HEADER_BK
        , LOAD_DTS
        , ID
        , ORDER_ID
        , LOCATION_ID
        , CREATED_AT
        , UPDATED_AT
        , STATUS
        , SERVICE
        , TRACKING_COMPANY
        , TRACKING_NUMBER
        , SHIPMENT_STATUS
        , TRACKING_NUMBERS
        , TRACKING_URLS
        , NAME
        , RECEIPT_AUTHORIZATION
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as FULFILLMENT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_ORDER_FULFILLMENT_HK
        -- Track delete-indicator flip sequence so true delete would not prevent the resurrection from going to sats/lsats.
        , CONDITIONAL_CHANGE_EVENT(PSA_DELETE_IND) OVER(PARTITION BY ID ORDER BY _FIVETRAN_SYNCED, PSA_LOAD_DTS) AS CCE
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
            , '||', IFNULL(TRIM(SERVICE::text), '^^') 
            , '||', IFNULL(TRIM(TRACKING_COMPANY::text), '^^') 
            , '||', IFNULL(TRIM(TRACKING_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SHIPMENT_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(TRACKING_NUMBERS::text), '^^') 
            , '||', IFNULL(TRIM(TRACKING_URLS::text), '^^') 
            , '||', IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_AUTHORIZATION::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(CCE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
