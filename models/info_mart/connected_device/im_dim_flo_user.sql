{{ config(alias='dim_flo_user') }}
---- SRC LAYER ----
WITH
SRC_DDF            as ( SELECT BKCC, DEVICE_ACCOUNT_BK, FLO_USER_BK, IS_ACTIVE, IS_SUPER_USER, IS_SYSTEM_USER, REC_SRC, SOURCE FROM {{ ref('dim_flo_user') }} as SRC  )

/*
SRC_DDF            as ( SELECT * FROM BUS_VAULT.DIM_FLO_USER )
*/
---- LOGIC LAYER ----

, LOGIC_DDF as (
    SELECT
        DEVICE_ACCOUNT_BK
      , FLO_USER_BK
      , BKCC
      , REC_SRC
      , IS_SYSTEM_USER
      , IS_SUPER_USER
      , IS_ACTIVE
      , SOURCE
    FROM SRC_DDF
)
---- RENAME LAYER ----

, RENAME_DDF as (
    SELECT
        DEVICE_ACCOUNT_BK
      , FLO_USER_BK
      , BKCC
      , REC_SRC
      , IS_SYSTEM_USER
      , IS_SUPER_USER
      , IS_ACTIVE
      , SOURCE
    FROM LOGIC_DDF
)
---- FILTER LAYER ----

, FILTER_DDF as (
    SELECT *
    FROM RENAME_DDF
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_DDF
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
