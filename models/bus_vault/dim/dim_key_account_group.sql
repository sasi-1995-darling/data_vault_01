---- SRC LAYER ----
WITH
SRC_D              as ( SELECT KEY_ACCOUNT_GROUP_BK, KEY_ACCOUNT_GROUP_HK, LANGUAGE_KEY, CUSTOMER_GROUP, DESCRIPTION, REC_SRC, BKCC FROM {{ ref('pit_key_account_group') }} as SRC  )

/*
SRC_D              as ( SELECT * FROM BUS_VAULT.pit_key_account_group )
*/
---- LOGIC LAYER ----

, LOGIC_D as (
    SELECT
        KEY_ACCOUNT_GROUP_BK
      , KEY_ACCOUNT_GROUP_HK
      , LANGUAGE_KEY
      , CUSTOMER_GROUP
      , DESCRIPTION
      , REC_SRC
      , BKCC
    FROM SRC_D
)
---- RENAME LAYER ----

, RENAME_D as (
    SELECT
        KEY_ACCOUNT_GROUP_BK
      , KEY_ACCOUNT_GROUP_HK
      , LANGUAGE_KEY
      , CUSTOMER_GROUP
      , DESCRIPTION
      , REC_SRC
      , BKCC
    FROM LOGIC_D
)
---- FILTER LAYER ----

, FILTER_D as (
    SELECT *
    FROM RENAME_D
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_D
)

---- FINAL LAYER ----
SELECT
          KEY_ACCOUNT_GROUP_BK
        , KEY_ACCOUNT_GROUP_HK
        , LANGUAGE_KEY
        , CUSTOMER_GROUP
        , DESCRIPTION
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
