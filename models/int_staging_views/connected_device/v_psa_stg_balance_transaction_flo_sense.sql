---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT AMOUNT, AVAILABLE_ON, CONNECTED_ACCOUNT_ID, CREATED, CURRENCY, DESCRIPTION, EXCHANGE_RATE, FEE, ID, NET, PAYOUT_ID, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REPORTING_CATEGORY, SOURCE, STATUS, TYPE, _FIVETRAN_SYNCED FROM {{ source('stripe_flosense', 'balance_transaction') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM stripe_flosense.balance_transaction )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        ID                                                           as                                     TRANSACTION_BK
      , CONNECTED_ACCOUNT_ID
      , AMOUNT
      , AVAILABLE_ON
      , CREATED
      , CURRENCY
      , DESCRIPTION
      , EXCHANGE_RATE
      , FEE
      , NET
      , SOURCE
      , STATUS
      , TYPE
      , REPORTING_CATEGORY
      , _FIVETRAN_SYNCED                                             as                                    FIVETRAN_SYNCED
      , PAYOUT_ID
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
---- RENAME LAYER ----

, RENAME_D1 as (
    SELECT
        TRANSACTION_BK
      , CONNECTED_ACCOUNT_ID
      , AMOUNT
      , AVAILABLE_ON
      , CREATED
      , CURRENCY
      , DESCRIPTION
      , EXCHANGE_RATE
      , FEE
      , NET
      , SOURCE
      , STATUS
      , TYPE
      , REPORTING_CATEGORY
      , FIVETRAN_SYNCED
      , PAYOUT_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_D1
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
    WHERE rec_src = 'US.STRIPE_FLOSENSE.BALANCE_TRANSACTION'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_D1
    INNER JOIN FILTER_A1
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          TRANSACTION_BK
        , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as LOAD_DTS
        , CONNECTED_ACCOUNT_ID
        , AMOUNT
        , AVAILABLE_ON
        , CREATED
        , CURRENCY
        , DESCRIPTION
        , EXCHANGE_RATE
        , FEE
        , NET
        , SOURCE
        , STATUS
        , TYPE
        , REPORTING_CATEGORY
        , FIVETRAN_SYNCED
        , PAYOUT_ID
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(TRANSACTION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as TRANSACTION_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(CONNECTED_ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(AVAILABLE_ON::text), '^^') 
            , '||', IFNULL(TRIM(CREATED::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(EXCHANGE_RATE::text), '^^') 
            , '||', IFNULL(TRIM(FEE::text), '^^') 
            , '||', IFNULL(TRIM(NET::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
            , '||', IFNULL(TRIM(TYPE::text), '^^') 
            , '||', IFNULL(TRIM(REPORTING_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(PAYOUT_ID::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
