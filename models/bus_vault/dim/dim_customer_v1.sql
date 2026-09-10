---- SRC LAYER ----
WITH
SRC_CUS            as ( SELECT * FROM {{ ref('pit_customer') }} as SRC  )

/*
SRC_CUS            as ( SELECT * FROM BUS_VAULT.pb_customer )
*/
---- LOGIC LAYER ----

, LOGIC_CUS as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , CUSTOMER_NAME_1
      , CUSTOMER_NAME_2
      , CITY
      , POSTAL_CODE
      , REGION
      , INDUSTRY_CODE
      , PRIMARY_ACCOUNT_NUMBER
      , CUSTOMER_ACCOUNT_GROUP
      , CUSTOMER_CLASSIFICATION
      , LEGAL_STATUS
      , TAX_TYPE
      , DUNS_NUMBER
      , IS_DELETED
      , REC_SRC
      , BKCC
    FROM SRC_CUS
)
---- RENAME LAYER ----

, RENAME_CUS as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , CUSTOMER_NAME_1
      , CUSTOMER_NAME_2
      , CITY
      , POSTAL_CODE
      , REGION
      , INDUSTRY_CODE
      , PRIMARY_ACCOUNT_NUMBER
      , CUSTOMER_ACCOUNT_GROUP
      , CUSTOMER_CLASSIFICATION
      , LEGAL_STATUS
      , TAX_TYPE
      , DUNS_NUMBER
      , IS_DELETED
      , REC_SRC
      , BKCC
    FROM LOGIC_CUS
)
---- FILTER LAYER ----

, FILTER_CUS as (
    SELECT *
    FROM RENAME_CUS
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_CUS
)

---- FINAL LAYER ----
SELECT
          CUSTOMER_HK
        , CUSTOMER_BK
        , CUSTOMER_NAME_1
        , CUSTOMER_NAME_2
        , CITY
        , POSTAL_CODE
        , REGION
        , INDUSTRY_CODE
        , PRIMARY_ACCOUNT_NUMBER
        , CUSTOMER_ACCOUNT_GROUP
        , CUSTOMER_CLASSIFICATION
        , LEGAL_STATUS
        , TAX_TYPE
        , DUNS_NUMBER
        , IS_DELETED
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
