---- SRC LAYER ----
WITH
SRC_PBFU           as ( SELECT ACCOUNT_ID, BKCC, DEVICE_ACCOUNT_BK, DEVICE_ACCOUNT_HK, EMAIL, EMAIL_HASH, FIVETRAN_DELETED, FIVETRAN_SYNCED, FLO_USER_BK, FLO_USER_HK, IS_ACTIVE, IS_IP_RESTRICTED, IS_SUPER_USER, IS_SYSTEM_USER, PASSWORD, REC_SRC, SOURCE, USER_ACCOUNT_HK, USER_ACCOUNT_ROLE, USER_ID FROM {{ ref('pb_stg_flo_user') }} as SRC 
                        qualify 1= row_number() over(partition by device_account_bk,flo_user_bk,bkcc,rec_src order by FIVETRAN_SYNCED DESC) )

/*
SRC_PBFU           as ( SELECT * FROM BUS_VAULT.PB_STG_FLO_USER )
*/
---- LOGIC LAYER ----

, LOGIC_PBFU as (
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
    FROM SRC_PBFU
)
---- RENAME LAYER ----

, RENAME_PBFU as (
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
    FROM LOGIC_PBFU
)
---- FILTER LAYER ----

, FILTER_PBFU as (
    SELECT *
    FROM RENAME_PBFU
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PBFU
)

---- FINAL LAYER ----
SELECT
              row_number() over(order by 1)                            as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PB_LOAD_DTS
        , USER_ACCOUNT_HK
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
