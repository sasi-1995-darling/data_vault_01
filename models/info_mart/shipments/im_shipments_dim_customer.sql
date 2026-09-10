{{ config(alias='dim_customer_v1') }}
---- SRC LAYER ----
WITH
SRC_dim_cust       as ( SELECT BKCC, CITY, CUSTOMER_ACCOUNT_GROUP, CUSTOMER_BK, CUSTOMER_CLASSIFICATION, CUSTOMER_HK, CUSTOMER_NAME_1, CUSTOMER_NAME_2, DUNS_NUMBER, INDUSTRY_CODE, IS_DELETED, LEGAL_STATUS, POSTAL_CODE, PRIMARY_ACCOUNT_NUMBER, REC_SRC, REGION, TAX_TYPE FROM {{ ref('dim_customer_v1') }} as SRC  )

/*
SRC_dim_cust       as ( SELECT * FROM bus_vault.dim_customer_v1 )
*/
---- LOGIC LAYER ----

, LOGIC_dim_cust as (
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
    FROM SRC_dim_cust
)
---- RENAME LAYER ----

, RENAME_dim_cust as (
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
    FROM LOGIC_dim_cust
)
---- FILTER LAYER ----

, FILTER_dim_cust as (
    SELECT *
    FROM RENAME_dim_cust
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_dim_cust
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