---- SRC LAYER ----
WITH
SRC_LNKKNVV        as ( SELECT CUSTOMER_HK, DISTRIBUTION_CHANNEL_HK, DIVISION_HK, LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK, REC_SRC, SALES_ORGANIZATION_HK FROM {{ ref('lnk_customer_sales_organization_distribution_channel_division') }} as SRC  ),
SRC_HBCUST         as ( SELECT BKCC, CUSTOMER_BK, CUSTOMER_HK FROM {{ ref('hub_customer_v1') }} as SRC  ),
SRC_HBSLO          as ( SELECT SALES_ORGANIZATION_BK, SALES_ORGANIZATION_HK FROM {{ ref('hub_sales_organization') }} as SRC  ),
SRC_HBDST          as ( SELECT DISTRIBUTION_CHANNEL_BK, DISTRIBUTION_CHANNEL_HK FROM {{ ref('hub_distribution_channel') }} as SRC  ),
SRC_HBDIV          as ( SELECT DIVISION_BK, DIVISION_HK FROM {{ ref('hub_division') }} as SRC  ),
SRC_LSATKNVV       as ( SELECT BZIRK, KONDA, KVGR1, KVGR2, KVGR3, KVGR4, KVGR5, LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK, VKBUR, VKGRP, ZZACCT, ZZACCTNAME, ZZAPO_PRICE_ACCT, ZZGROUP_APO, ZZTEA FROM {{ ref('lsat_customer_sales_organization_distribution_channel_division__winn_sap') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATCUST        as ( SELECT CUSTOMER_HK, NAME1 FROM {{ ref('sat_customer__winn_sap') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY CUSTOMER_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATSLO         as ( SELECT SALES_ORGANIZATION_HK, VTEXT FROM {{ ref('sat_sales_organization__winn_sap') }} as SRC 
                        WHERE SPRAS = 'E'
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY SALES_ORGANIZATION_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATDST         as ( SELECT DISTRIBUTION_CHANNEL_HK, VTEXT FROM {{ ref('sat_distribution_channel__winn_sap') }} as SRC 
                        WHERE SPRAS = 'E'
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY DISTRIBUTION_CHANNEL_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATDIV         as ( SELECT DIVISION_HK, VTEXT FROM {{ ref('sat_division__winn_sap') }} as SRC 
                        WHERE SPRAS = 'E'
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY DIVISION_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_LNKKNVV        as ( SELECT * FROM raw_vault.LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION )
SRC_HBCUST         as ( SELECT * FROM raw_vault.HUB_CUSTOMER_V1 )
SRC_HBSLO          as ( SELECT * FROM raw_vault.HUB_SALES_ORGANIZATION )
SRC_HBDST          as ( SELECT * FROM raw_vault.HUB_DISTRIBUTION_CHANNEL )
SRC_HBDIV          as ( SELECT * FROM raw_vault.HUB_DIVISION )
SRC_LSATKNVV       as ( SELECT * FROM raw_vault.LSAT_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION__WINN_SAP )
SRC_SATCUST        as ( SELECT * FROM raw_vault.SAT_CUSTOMER__WINN_SAP )
SRC_SATSLO         as ( SELECT * FROM raw_vault.SAT_SALES_ORGANIZATION__WINN_SAP )
SRC_SATDST         as ( SELECT * FROM raw_vault.SAT_DISTRIBUTION_CHANNEL__WINN_SAP )
SRC_SATDIV         as ( SELECT * FROM raw_vault.SAT_DIVISION__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_LNKKNVV as (
    SELECT
        LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK
      , LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK as                      CUSTOMER_SALES_ATTRIBUTES_KEY
      , CUSTOMER_HK
      , SALES_ORGANIZATION_HK
      , DISTRIBUTION_CHANNEL_HK
      , DIVISION_HK
      , REC_SRC
    FROM SRC_LNKKNVV
)

, LOGIC_HBCUST as (
    SELECT
        CUSTOMER_BK
      , BKCC
      , CUSTOMER_HK                                                  as                                 HBCUST_CUSTOMER_HK
    FROM SRC_HBCUST
)

, LOGIC_HBSLO as (
    SELECT
        SALES_ORGANIZATION_BK
      , SALES_ORGANIZATION_HK                                        as                        HBSLO_SALES_ORGANIZATION_HK
    FROM SRC_HBSLO
)

, LOGIC_HBDST as (
    SELECT
        DISTRIBUTION_CHANNEL_BK
      , DISTRIBUTION_CHANNEL_HK                                      as                      HBDST_DISTRIBUTION_CHANNEL_HK
    FROM SRC_HBDST
)

, LOGIC_HBDIV as (
    SELECT
        DIVISION_BK
      , DIVISION_HK                                                  as                                  HBDIV_DIVISION_HK
    FROM SRC_HBDIV
)

, LOGIC_LSATKNVV as (
    SELECT
        ZZACCT                                                       as                                     ACCOUNT_NUMBER
      , ZZACCTNAME                                                   as                                       ACCOUNT_NAME
      , BZIRK                                                        as                                 REPORTING_DISTRICT
      , VKGRP                                                        as                                        SALES_GROUP
      , VKBUR                                                        as                                       SALES_OFFICE
      , KONDA                                                        as                             CUSTOMER_PRICE_ACCOUNT
      , KVGR1                                                        as                                        KEY_ACCOUNT
      , KVGR2                                                        as                                  GROUP_KEY_ACCOUNT
      , KVGR3                                                        as                                    BUYING_GROUP_ID
      , ZZGROUP_APO                                                  as                                          APO_GROUP
      , ZZAPO_PRICE_ACCT                                             as                               APO_FORECAST_ACCOUNT
      , KVGR4                                                        as                                 CUSTOMER_LEAD_DAYS
      , ZZTEA                                                        as                                          TEAM_CODE
      , LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK as LSATKNVV_LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK
      , KVGR5                                                        as                                     LSATKNVV_KVGR5
    FROM SRC_LSATKNVV
)

, LOGIC_SATCUST as (
    SELECT
        NAME1                                                        as                                           CUSTOMER
      , CUSTOMER_HK                                                  as                                SATCUST_CUSTOMER_HK
    FROM SRC_SATCUST
)

, LOGIC_SATSLO as (
    SELECT
        VTEXT                                                        as                                 SALES_ORGANIZATION
      , SALES_ORGANIZATION_HK                                        as                       SATSLO_SALES_ORGANIZATION_HK
    FROM SRC_SATSLO
)

, LOGIC_SATDST as (
    SELECT
        VTEXT                                                        as                               DISTRIBUTION_CHANNEL
      , DISTRIBUTION_CHANNEL_HK                                      as                     SATDST_DISTRIBUTION_CHANNEL_HK
    FROM SRC_SATDST
)

, LOGIC_SATDIV as (
    SELECT
        VTEXT                                                        as                                           DIVISION
      , DIVISION_HK                                                  as                                 SATDIV_DIVISION_HK
    FROM SRC_SATDIV
)
---- RENAME LAYER ----

, RENAME_LNKKNVV as (
    SELECT
        LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK
      , CUSTOMER_SALES_ATTRIBUTES_KEY
      , CUSTOMER_HK
      , SALES_ORGANIZATION_HK
      , DISTRIBUTION_CHANNEL_HK
      , DIVISION_HK
      , REC_SRC
    FROM LOGIC_LNKKNVV
)

, RENAME_HBCUST as (
    SELECT
        CUSTOMER_BK
      , BKCC
      , HBCUST_CUSTOMER_HK
    FROM LOGIC_HBCUST
)

, RENAME_SATCUST as (
    SELECT
        CUSTOMER
      , SATCUST_CUSTOMER_HK
    FROM LOGIC_SATCUST
)

, RENAME_HBSLO as (
    SELECT
        SALES_ORGANIZATION_BK
      , HBSLO_SALES_ORGANIZATION_HK
    FROM LOGIC_HBSLO
)

, RENAME_SATSLO as (
    SELECT
        SALES_ORGANIZATION
      , SATSLO_SALES_ORGANIZATION_HK
    FROM LOGIC_SATSLO
)

, RENAME_HBDST as (
    SELECT
        DISTRIBUTION_CHANNEL_BK
      , HBDST_DISTRIBUTION_CHANNEL_HK
    FROM LOGIC_HBDST
)

, RENAME_SATDST as (
    SELECT
        DISTRIBUTION_CHANNEL
      , SATDST_DISTRIBUTION_CHANNEL_HK
    FROM LOGIC_SATDST
)

, RENAME_HBDIV as (
    SELECT
        DIVISION_BK
      , HBDIV_DIVISION_HK
    FROM LOGIC_HBDIV
)

, RENAME_SATDIV as (
    SELECT
        DIVISION
      , SATDIV_DIVISION_HK
    FROM LOGIC_SATDIV
)

, RENAME_LSATKNVV as (
    SELECT
        ACCOUNT_NUMBER
      , ACCOUNT_NAME
      , REPORTING_DISTRICT
      , SALES_GROUP
      , SALES_OFFICE
      , CUSTOMER_PRICE_ACCOUNT
      , KEY_ACCOUNT
      , GROUP_KEY_ACCOUNT
      , BUYING_GROUP_ID
      , APO_GROUP
      , APO_FORECAST_ACCOUNT
      , CUSTOMER_LEAD_DAYS
      , TEAM_CODE
      , LSATKNVV_LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK
      , LSATKNVV_KVGR5
    FROM LOGIC_LSATKNVV
)
---- FILTER LAYER ----

, FILTER_LNKKNVV as (
    SELECT *
    FROM RENAME_LNKKNVV
)

, FILTER_HBCUST as (
    SELECT *
    FROM RENAME_HBCUST
)

, FILTER_HBSLO as (
    SELECT *
    FROM RENAME_HBSLO
)

, FILTER_HBDST as (
    SELECT *
    FROM RENAME_HBDST
)

, FILTER_HBDIV as (
    SELECT *
    FROM RENAME_HBDIV
)

, FILTER_LSATKNVV as (
    SELECT *
    FROM RENAME_LSATKNVV
)

, FILTER_SATCUST as (
    SELECT *
    FROM RENAME_SATCUST
)

, FILTER_SATSLO as (
    SELECT *
    FROM RENAME_SATSLO
)

, FILTER_SATDST as (
    SELECT *
    FROM RENAME_SATDST
)

, FILTER_SATDIV as (
    SELECT *
    FROM RENAME_SATDIV
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LNKKNVV
    INNER JOIN FILTER_HBCUST
        ON CUSTOMER_HK = HBCUST_CUSTOMER_HK
    INNER JOIN FILTER_HBSLO
        ON SALES_ORGANIZATION_HK = HBSLO_SALES_ORGANIZATION_HK
    INNER JOIN FILTER_HBDST
        ON DISTRIBUTION_CHANNEL_HK = HBDST_DISTRIBUTION_CHANNEL_HK
    INNER JOIN FILTER_HBDIV
        ON DIVISION_HK = HBDIV_DIVISION_HK
    INNER JOIN FILTER_LSATKNVV
        ON LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK = LSATKNVV_LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK
    LEFT JOIN FILTER_SATCUST
        ON HBCUST_CUSTOMER_HK = SATCUST_CUSTOMER_HK
    LEFT JOIN FILTER_SATSLO
        ON HBSLO_SALES_ORGANIZATION_HK = SATSLO_SALES_ORGANIZATION_HK
    LEFT JOIN FILTER_SATDST
        ON HBDST_DISTRIBUTION_CHANNEL_HK = SATDST_DISTRIBUTION_CHANNEL_HK
    LEFT JOIN FILTER_SATDIV
        ON HBDIV_DIVISION_HK = SATDIV_DIVISION_HK
)

---- FINAL LAYER ----
SELECT
          RANDOM()                                                     as SEQ_ID
        ,  'PB_CUSTOMER_SALES_ATTRIBUTES'                              as PB_REC_SRC
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PB_LOAD_DTS
        , CUSTOMER_SALES_ATTRIBUTES_KEY
        , CUSTOMER_HK
        , CUSTOMER_BK
        , CUSTOMER
        , SALES_ORGANIZATION_HK
        , SALES_ORGANIZATION_BK
        , SALES_ORGANIZATION
        , DISTRIBUTION_CHANNEL_HK
        , DISTRIBUTION_CHANNEL_BK
        , DISTRIBUTION_CHANNEL
        , DIVISION_HK
        , DIVISION_BK
        , DIVISION
        , ACCOUNT_NUMBER
        , ACCOUNT_NAME
        , REPORTING_DISTRICT
        , SALES_GROUP
        , SALES_OFFICE
        , CUSTOMER_PRICE_ACCOUNT
        , KEY_ACCOUNT
        , GROUP_KEY_ACCOUNT
        , BUYING_GROUP_ID
        , APO_GROUP
        , APO_FORECAST_ACCOUNT
        , CUSTOMER_LEAD_DAYS
        , CASE LSATKNVV_KVGR5
            WHEN 'YES' THEN 'Y' ELSE 'N'
END as CUSTOMER_EARLY_SHIP_FLAG
        , TEAM_CODE
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
