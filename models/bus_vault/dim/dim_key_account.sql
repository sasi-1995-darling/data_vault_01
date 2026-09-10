---- SRC LAYER ----
WITH
SRC_ka             as ( SELECT BKCC, CUSTOMER_GROUP1_DESCRIPTION, KEY_ACCOUNT_BK, KEY_ACCOUNT_HK, LANGUAGE_KEY, REC_SRC FROM {{ ref('pit_key_account') }} as SRC  )

/*
SRC_ka             as ( SELECT * FROM BUS_VAULT.pit_key_account )
*/
---- LOGIC LAYER ----

, LOGIC_ka as (
    SELECT
        KEY_ACCOUNT_HK
      , KEY_ACCOUNT_BK
      , CUSTOMER_GROUP1_DESCRIPTION                                  as                            KEY_ACCOUNT_DESCRIPTION
      , LANGUAGE_KEY                                                 as                                  LANGUAGE_CODE_SAP
      , BKCC
      , REC_SRC
    FROM SRC_ka
)
---- RENAME LAYER ----

, RENAME_ka as (
    SELECT
        KEY_ACCOUNT_HK
      , KEY_ACCOUNT_BK
      , KEY_ACCOUNT_DESCRIPTION
      , LANGUAGE_CODE_SAP
      , BKCC
      , REC_SRC
    FROM LOGIC_ka
)
---- FILTER LAYER ----

, FILTER_ka as (
    SELECT *
    FROM RENAME_ka
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_ka
)

---- FINAL LAYER ----
SELECT
          KEY_ACCOUNT_HK
        , KEY_ACCOUNT_BK
        , KEY_ACCOUNT_DESCRIPTION
        , LANGUAGE_CODE_SAP
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
