---- SRC LAYER ----
WITH
SRC_P              as ( SELECT    SALES_ORGANIZATION_HK
                                , SALES_ORGANIZATION_BK
                                , LANGUAGE_KEY
                                , SALES_ORGANIZATION
                                , SALES_ORGANIZATION_NAME
                                , REC_SRC
                                , IS_DELETED
                                , BKCC 
                        FROM {{ ref('pit_sales_organization') }} as SRC  )

/*
SRC_P              as ( SELECT * FROM RAW_VAULT.PIT_SALES_ORGANIZATION )
*/
---- LOGIC LAYER ----

, LOGIC_P as (
    SELECT
      SALES_ORGANIZATION_HK
    , SALES_ORGANIZATION_BK
    , LANGUAGE_KEY
    , SALES_ORGANIZATION
    , SALES_ORGANIZATION_NAME
    , REC_SRC
    , IS_DELETED
    , BKCC
    FROM SRC_P
)
---- RENAME LAYER ----

, RENAME_P as (
    SELECT
      SALES_ORGANIZATION_HK
    , SALES_ORGANIZATION_BK
    , LANGUAGE_KEY
    , SALES_ORGANIZATION
    , SALES_ORGANIZATION_NAME
    , REC_SRC
    , IS_DELETED
    , BKCC
    FROM LOGIC_P
)
---- FILTER LAYER ----

, FILTER_P as (
    SELECT *
    FROM RENAME_P
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_P
)

---- FINAL LAYER ----
SELECT
      SALES_ORGANIZATION_HK
    , SALES_ORGANIZATION_BK
    , LANGUAGE_KEY
    , SALES_ORGANIZATION
    , SALES_ORGANIZATION_NAME
    , REC_SRC
    , IS_DELETED
    , BKCC
FROM JOIN_RESULT