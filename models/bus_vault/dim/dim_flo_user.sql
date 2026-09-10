---- SRC LAYER ----
WITH
SRC_PB             as ( SELECT BKCC, DEVICE_ACCOUNT_BK, FLO_USER_BK, IS_ACTIVE, IS_SUPER_USER, IS_SYSTEM_USER, REC_SRC, SOURCE FROM {{ ref('pb_flo_user') }} as SRC  )

/*
SRC_PB             as ( SELECT * FROM BUS_VAULT.PB_FLO_USER )
*/
---- LOGIC LAYER ----

, LOGIC_PB as (
    SELECT
        DEVICE_ACCOUNT_BK
      , FLO_USER_BK
      , BKCC
      , REC_SRC
      , IS_SYSTEM_USER
      , IS_SUPER_USER
      , IS_ACTIVE
      , SOURCE
    FROM SRC_PB
)
---- RENAME LAYER ----

, RENAME_PB as (
    SELECT
        DEVICE_ACCOUNT_BK
      , FLO_USER_BK
      , BKCC
      , REC_SRC
      , IS_SYSTEM_USER
      , IS_SUPER_USER
      , IS_ACTIVE
      , SOURCE
    FROM LOGIC_PB
)
---- FILTER LAYER ----

, FILTER_PB as (
    SELECT *
    FROM RENAME_PB
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PB
)

---- FINAL LAYER ----
SELECT
          DEVICE_ACCOUNT_BK
        , FLO_USER_BK
        , BKCC
        , REC_SRC
        , IS_SYSTEM_USER
        , IS_SUPER_USER
        , IS_ACTIVE
        , SOURCE
FROM JOIN_RESULT
