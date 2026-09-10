---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT CREATED_AT, ID, NOTE, ORDER_ID, PROCESSED_AT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, RESTOCK, TOTAL_DUTIES_SET, USER_ID, _FIVETRAN_SYNCED
                        /* Syndicate delete filter: suppress truncate-reload artifact deletes (Y+N in same batch) */
                        , CASE WHEN PSA_DELETE_IND = 'Y'
                             AND COUNT_IF(PSA_DELETE_IND = 'N') OVER (PARTITION BY ID, _FIVETRAN_SYNCED) > 0
                               THEN TRUE ELSE FALSE END AS TRUNCATE_RELOAD_FLAG
                        FROM {{ source('shopify_moen', 'refund') }} as SRC
                        QUALIFY NOT TRUNCATE_RELOAD_FLAG  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_OR             as ( SELECT ID, NAME FROM {{ source('shopify_moen', 'ORDER') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ID ORDER BY _FIVETRAN_SYNCED DESC) )

/*
SRC_D1             as ( SELECT * FROM SHOPIFY_MOEN.REFUND )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_OR             as ( SELECT * FROM SHOPIFY_MOEN.ORDER )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        TO_CHAR(ID)                                                  as                                          REFUND_BK
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , ID
      , CREATED_AT
      , PROCESSED_AT
      , NOTE
      , RESTOCK
      , USER_ID
      , ORDER_ID
      , TOTAL_DUTIES_SET
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
        COALESCE(NAME, '-1')                                         as                                    ORDER_HEADER_BK
      , ID                                                           as                                              OR_ID
      , NAME                                                         as                                            OR_NAME
    FROM SRC_OR
)
---- RENAME LAYER ----

, RENAME_D1 as (
    SELECT
        REFUND_BK
      , LOAD_DTS
      , ID
      , CREATED_AT
      , PROCESSED_AT
      , NOTE
      , RESTOCK
      , USER_ID
      , ORDER_ID
      , TOTAL_DUTIES_SET
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
    WHERE rec_src = 'US.SHOPIFY_MOEN.REFUND'
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
          REFUND_BK
        , ORDER_HEADER_BK
        , LOAD_DTS
        , ID
        , CREATED_AT
        , PROCESSED_AT
        , NOTE
        , RESTOCK
        , USER_ID
        , ORDER_ID
        , TOTAL_DUTIES_SET
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as REFUND_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_ORDER_REFUND_HK
        -- Track delete-indicator flip sequence so true delete would not prevent the resurrection from going to sats/lsats.
        , CONDITIONAL_CHANGE_EVENT(PSA_DELETE_IND) OVER(PARTITION BY ID ORDER BY _FIVETRAN_SYNCED, PSA_LOAD_DTS) AS CCE
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(PROCESSED_AT::text), '^^') 
            , '||', IFNULL(TRIM(NOTE::text), '^^') 
            , '||', IFNULL(TRIM(RESTOCK::text), '^^') 
            , '||', IFNULL(TRIM(USER_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_ID::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_DUTIES_SET::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(CCE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
