---- SRC LAYER ----
WITH
SRC_s              as ( SELECT AMOUNT, AMOUNT_SET, ID, KIND, ORDER_ID, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REASON, REFUND_ID, TAX_AMOUNT, 
                        TAX_AMOUNT_SET, _FIVETRAN_SYNCED FROM {{ source('shopify_moen', 'order_adjustment') }} as SRC 
                        /* The following qualify clause is required to pull the latest row synced by fivetran based on these PK columns, 
                        only the most recent record present in the source is needed*/
                        qualify 1 = row_number() over(partition by id, order_id, refund_id order by _fivetran_synced desc)  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_o              as ( SELECT ID, NAME FROM {{ source('shopify_moen', 'ORDER') }} as SRC 
                        /* The following qualify clause is required to pull the latest row synced by fivetran based on these PK columns, 
                        only the most recent record present in the source is needed*/
                        qualify 1 = row_number() over(partition by id order by _fivetran_synced desc)  )

/*
SRC_s              as ( SELECT * FROM shopify_moen.order_adjustment )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_o              as ( SELECT * FROM shopify_moen.ORDER )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        ID
      , ORDER_ID
      , REFUND_ID
      , AMOUNT
      , TAX_AMOUNT
      , KIND
      , REASON
      , AMOUNT_SET
      , TAX_AMOUNT_SET
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
      , ORDER_ID
      , REFUND_ID
      , AMOUNT
      , TAX_AMOUNT
      , KIND
      , REASON
      , AMOUNT_SET
      , TAX_AMOUNT_SET
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
    WHERE rec_src = 'US.API.SHOPIFY_MOEN.ORDER_ADJUSTMENT'
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
    LEFT JOIN FILTER_o
        ON FILTER_s.ORDER_ID = O_ID
)

---- FINAL LAYER ----
SELECT
          ID
        , ORDER_ID
        , REFUND_ID
        , AMOUNT
        , TAX_AMOUNT
        , KIND
        , REASON
        , AMOUNT_SET
        , TAX_AMOUNT_SET
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , CONVERT_TIMEZONE('UTC', IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,_FIVETRAN_SYNCED)) as LOAD_DTS
        , REC_SRC
        , BKCC
        , COALESCE(O_NAME, '-1')                                       as ORDER_HEADER_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_HEADER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ID::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_ID::text), '^^') 
            , '||', IFNULL(TRIM(REFUND_ID::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TAX_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(KIND::text), '^^') 
            , '||', IFNULL(TRIM(REASON::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT_SET::text), '^^') 
            , '||', IFNULL(TRIM(TAX_AMOUNT_SET::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
