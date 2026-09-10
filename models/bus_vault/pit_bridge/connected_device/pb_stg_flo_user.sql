{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_LUA            as ( SELECT DEVICE_ACCOUNT_HK, FLO_USER_HK, REC_SRC, ROLES, USER_ACCOUNT_HK FROM {{ ref('lnk_user_account_role') }} as SRC  ),
SRC_HD             as ( SELECT DEVICE_ACCOUNT_BK, DEVICE_ACCOUNT_HK FROM {{ ref('hub_device_account') }} as SRC  ),
SRC_HU             as ( SELECT BKCC, FLO_USER_BK, FLO_USER_HK FROM {{ ref('hub_flo_user') }} as SRC  ),
SRC_SFU            as ( SELECT ACCOUNT_ID, EMAIL, EMAIL_HASH, FLO_USER_HK, ID, IS_ACTIVE, IS_SUPER_USER, IS_SYSTEM_USER, PASSWORD, SOURCE, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, _IS_IP_RESTRICTED FROM {{ ref('sat_flo_user_details__flo_dynamodb') }} as SRC 
                        qualify 1= row_number() over(partition by FLO_USER_HK order by LOAD_DTS DESC) ),
SRC_SFP            as ( SELECT FLO_USER_HK FROM {{ ref('sat_flo_user_profile__flo_dynamodb') }} as SRC 
                        qualify 1= row_number() over(partition by FLO_USER_HK order by LOAD_DTS DESC) ),
SRC_RP             as ( SELECT PATTERN FROM {{ ref('ref_test_email_patterns_for_flo_dynamo') }} as SRC  )

/*
SRC_LUA            as ( SELECT * FROM raw_vault.LNK_USER_ACCOUNT_ROLE )
SRC_HD             as ( SELECT * FROM raw_vault.HUB_DEVICE_ACCOUNT )
SRC_HU             as ( SELECT * FROM raw_vault.HUB_FLO_USER )
SRC_SFU            as ( SELECT * FROM raw_vault.SAT_FLO_USER_DETAILS__FLO_DYNAMODB )
SRC_SFP            as ( SELECT * FROM raw_vault.SAT_FLO_USER_PROFILE__FLO_DYNAMODB )
SRC_RP             as ( SELECT * FROM bus_vault.ref_test_email_patterns_for_flo_dynamo )
*/
---- LOGIC LAYER ----

, LOGIC_LUA as (
    SELECT
        USER_ACCOUNT_HK
      , DEVICE_ACCOUNT_HK
      , FLO_USER_HK
      , ROLES                                                        as                                  USER_ACCOUNT_ROLE
      , REC_SRC
      , '1'                                                          as                                     LUA_JOIN_FIELD
    FROM SRC_LUA
)

, LOGIC_HD as (
    SELECT
        DEVICE_ACCOUNT_HK                                            as                               HD_DEVICE_ACCOUNT_HK
      , DEVICE_ACCOUNT_BK
    FROM SRC_HD
)

, LOGIC_HU as (
    SELECT
        FLO_USER_HK                                                  as                                     HU_FLO_USER_HK
      , FLO_USER_BK
      , BKCC
    FROM SRC_HU
)

, LOGIC_SFU as (
    SELECT
        FLO_USER_HK                                                  as                                    SFU_FLO_USER_HK
      , ID                                                           as                                            USER_ID
      , _FIVETRAN_SYNCED                                             as                                    FIVETRAN_SYNCED
      , PASSWORD
      , IS_ACTIVE
      , CASE
            WHEN SOURCE = 'web' THEN 'Web'
            WHEN SOURCE = 'mobile' THEN 'Mobile'
            WHEN SOURCE = 'moen' THEN 'Moen'
            WHEN SOURCE IS NULL THEN ''
            ELSE SOURCE
        END                                                          as                                             SOURCE
      , EMAIL
      , EMAIL_HASH
      , IS_SYSTEM_USER
      , ACCOUNT_ID
      , IS_SUPER_USER
      , _IS_IP_RESTRICTED                                            as                                   IS_IP_RESTRICTED
      , _FIVETRAN_DELETED                                            as                                   FIVETRAN_DELETED
      , SOURCE                                                       as                                         RAW_SOURCE
    FROM SRC_SFU
)

, LOGIC_SFP as (
    SELECT
        FLO_USER_HK                                                  as                                    SFP_FLO_USER_HK
    FROM SRC_SFP
)

, LOGIC_RP as (
    SELECT
        '1'                                                          as                                      RP_JOIN_FIELD
      , PATTERN
    FROM SRC_RP
)
---- RENAME LAYER ----

, RENAME_LUA as (
    SELECT
        USER_ACCOUNT_HK
      , DEVICE_ACCOUNT_HK
      , FLO_USER_HK
      , USER_ACCOUNT_ROLE
      , REC_SRC
      , LUA_JOIN_FIELD
    FROM LOGIC_LUA
)

, RENAME_HD as (
    SELECT
        HD_DEVICE_ACCOUNT_HK
      , DEVICE_ACCOUNT_BK
    FROM LOGIC_HD
)

, RENAME_HU as (
    SELECT
        HU_FLO_USER_HK
      , FLO_USER_BK
      , BKCC
    FROM LOGIC_HU
)

, RENAME_SFU as (
    SELECT
        SFU_FLO_USER_HK
      , USER_ID
      , FIVETRAN_SYNCED
      , PASSWORD
      , IS_ACTIVE
      , SOURCE
      , EMAIL
      , EMAIL_HASH
      , IS_SYSTEM_USER
      , ACCOUNT_ID
      , IS_SUPER_USER
      , IS_IP_RESTRICTED
      , FIVETRAN_DELETED
      , RAW_SOURCE
    FROM LOGIC_SFU
)

, RENAME_SFP as (
    SELECT
        SFP_FLO_USER_HK
    FROM LOGIC_SFP
)

, RENAME_RP as (
    SELECT
        RP_JOIN_FIELD
      , PATTERN
    FROM LOGIC_RP
)
---- FILTER LAYER ----

, FILTER_LUA as (
    SELECT *
    FROM RENAME_LUA
)

, FILTER_HD as (
    SELECT *
    FROM RENAME_HD
)

, FILTER_HU as (
    SELECT *
    FROM RENAME_HU
)

, FILTER_SFU as (
    SELECT *
    FROM RENAME_SFU
)

, FILTER_SFP as (
    SELECT *
    FROM RENAME_SFP
)

, FILTER_RP as (
    SELECT *
    FROM RENAME_RP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LUA
    LEFT JOIN FILTER_HD
        ON DEVICE_ACCOUNT_HK = HD_DEVICE_ACCOUNT_HK
    LEFT JOIN FILTER_HU
        ON FLO_USER_HK = HU_FLO_USER_HK
    LEFT JOIN FILTER_SFU
        ON FLO_USER_HK = SFU_FLO_USER_HK
    LEFT JOIN FILTER_SFP
        ON FLO_USER_HK = SFP_FLO_USER_HK
    LEFT JOIN FILTER_RP
        ON LUA_JOIN_FIELD = RP_JOIN_FIELD AND lower(email) like '%' || pattern || '%'
)

---- FINAL LAYER ----
SELECT
          USER_ACCOUNT_HK
        , DEVICE_ACCOUNT_HK
        , FLO_USER_HK
        , USER_ACCOUNT_ROLE
        , DEVICE_ACCOUNT_BK
        , FLO_USER_BK
        , BKCC
        , REC_SRC
        , USER_ID
        , FIVETRAN_SYNCED
        , PASSWORD
        , IS_ACTIVE
        , SOURCE
        , EMAIL
        , EMAIL_HASH
        , IS_SYSTEM_USER
        , ACCOUNT_ID
        , IS_SUPER_USER
        , IS_IP_RESTRICTED
        , FIVETRAN_DELETED
FROM JOIN_RESULT
WHERE PATTERN IS NULL