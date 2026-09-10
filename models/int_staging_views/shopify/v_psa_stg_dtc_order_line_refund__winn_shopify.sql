---- SRC LAYER ----
WITH
SRC_s              as ( SELECT ID, LOCATION_ID, ORDER_LINE_ID, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, QUANTITY, REFUND_ID, RESTOCK_TYPE, 
                        SUBTOTAL, SUBTOTAL_SET, TOTAL_TAX, TOTAL_TAX_SET, _FIVETRAN_SYNCED
                        /* Syndicate delete filter: suppress truncate-reload artifact deletes (Y+N in same batch) */
                        , CASE WHEN PSA_DELETE_IND = 'Y'
                               AND COUNT_IF(PSA_DELETE_IND = 'N') OVER (PARTITION BY ORDER_LINE_ID, REFUND_ID, ID, PSA_LOAD_DTS) > 0
                               THEN TRUE ELSE FALSE END AS TRUNCATE_RELOAD_FLAG
                        FROM {{ source('shopify_moen', 'order_line_refund') }} as SRC 
                        /* The following qualify clause is required to pull the latest row synced by fivetran based on these PK columns, 
                        only the most recent record present in the source is needed*/
                        QUALIFY NOT TRUNCATE_RELOAD_FLAG
                            AND 1 = row_number() over(partition by order_line_id, refund_id, id order by _fivetran_synced desc)  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_ol             as ( SELECT ID, INDEX, ORDER_ID FROM {{ source('shopify_moen', 'order_line') }} as SRC 
                        /* The following qualify clause is required to pull the latest row synced by fivetran based on these PK columns, 
                        only the most recent record present in the source is needed*/
                        qualify 1 = row_number() over(partition by order_id, id order by _fivetran_synced desc)  ),
SRC_o              as ( SELECT ID, NAME FROM {{ source('shopify_moen', 'ORDER') }} as SRC 
                        /* The following qualify clause is required to pull the latest row synced by fivetran based on these PK columns, 
                        only the most recent record present in the source is needed*/
                        qualify 1 = row_number() over(partition by id order by _fivetran_synced desc)  )

/*
SRC_s              as ( SELECT * FROM shopify_moen.order_line_refund )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_ol             as ( SELECT * FROM shopify_moen.order_line )
SRC_o              as ( SELECT * FROM shopify_moen.ORDER )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        ID
      , LOCATION_ID
      , REFUND_ID
      , RESTOCK_TYPE
      , QUANTITY
      , SUBTOTAL
      , SUBTOTAL_SET
      , TOTAL_TAX
      , TOTAL_TAX_SET
      , ORDER_LINE_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_s
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)

, LOGIC_ol as (
    SELECT
        ID                                                           as                                              OL_ID
      , ORDER_ID                                                     as                                        OL_ORDER_ID
      , INDEX                                                        as                                           OL_INDEX
    FROM SRC_ol
)

, LOGIC_o as (
    SELECT
        ID                                                           as                                               O_ID
      , NAME                                                         as                                             O_NAME
    FROM SRC_o
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        ID
      , LOCATION_ID
      , REFUND_ID
      , RESTOCK_TYPE
      , QUANTITY
      , SUBTOTAL
      , SUBTOTAL_SET
      , TOTAL_TAX
      , TOTAL_TAX_SET
      , ORDER_LINE_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_s
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)

, RENAME_ol as (
    SELECT
        OL_ID
      , OL_ORDER_ID
      , OL_INDEX
    FROM LOGIC_ol
)

, RENAME_o as (
    SELECT
        O_ID
      , O_NAME
    FROM LOGIC_o
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'US.API.SHOPIFY_MOEN.ORDER_LINE_REFUND'
)

, FILTER_ol as (
    SELECT *
    FROM RENAME_ol
)

, FILTER_o as (
    SELECT *
    FROM RENAME_o
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_ol
        ON FILTER_s.ORDER_LINE_ID = OL_ID
    LEFT JOIN FILTER_o
        ON OL_ORDER_ID = O_ID
)

---- FINAL LAYER ----
SELECT
          ID
        , LOCATION_ID
        , REFUND_ID
        , RESTOCK_TYPE
        , QUANTITY
        , SUBTOTAL
        , SUBTOTAL_SET
        , TOTAL_TAX
        , TOTAL_TAX_SET
        , ORDER_LINE_ID
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , CONVERT_TIMEZONE('UTC',_FIVETRAN_SYNCED)                     as LOAD_DTS
        , REC_SRC
        , BKCC
        , CONCAT_WS('||', COALESCE(O_NAME, '-1'), COALESCE(OL_INDEX, '-1')) as ORDER_LINE_BK
        , COALESCE(O_NAME, '-1')                                       as ORDER_HEADER_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ORDER_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_ORDER_LINE_HK
        -- Track delete-indicator flip sequence so true delete would not prevent the resurrection from going to sats/lsats.
        , CONDITIONAL_CHANGE_EVENT(PSA_DELETE_IND) OVER(PARTITION BY ORDER_LINE_ID, REFUND_ID, ID ORDER BY _FIVETRAN_SYNCED, PSA_LOAD_DTS) AS CCE
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ID::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(REFUND_ID::text), '^^') 
            , '||', IFNULL(TRIM(RESTOCK_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(SUBTOTAL::text), '^^') 
            , '||', IFNULL(TRIM(SUBTOTAL_SET::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_TAX::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_TAX_SET::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(CCE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
