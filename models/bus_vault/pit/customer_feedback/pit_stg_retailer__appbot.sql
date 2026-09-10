{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HR             as ( SELECT * FROM {{ ref('hub_retailer') }} as SRC 
                        WHERE RETAILER_BK IN ('iOS','Google Play') ),
SRC_SR             as ( SELECT * FROM {{ ref('sat_retailer__appbot') }} as SRC 
                        qualify 1= row_number() over(partition by RETAILER_HK order by PSA_LOAD_DTS DESC) )

/*
SRC_HR             as ( SELECT * FROM RAW_VAULT.HUB_RETAILER )
, SRC_SR             as ( SELECT * FROM RAW_VAULT.SAT_RETAILER__APPBOT )
*/
---- LOGIC LAYER ----

, LOGIC_HR as (
    SELECT
        CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , RETAILER_HK
      , RETAILER_BK
      , BKCC
      , REC_SRC
    FROM SRC_HR
)

, LOGIC_SR as (
    SELECT
        RETAILER_HK                                                  as                                     SR_RETAILER_HK
      , STORE_ID                                                     as                                                 ID
      , ''                                                           as                                            COUNTRY
      , ''                                                           as                                              ALIAS
    FROM SRC_SR
)
---- RENAME LAYER ----

, RENAME_HR as (
    SELECT
        PIT_LOAD_DTS
      , RETAILER_HK
      , RETAILER_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_HR
)

, RENAME_SR as (
    SELECT
        SR_RETAILER_HK
      , ID
      , COUNTRY
      , ALIAS
    FROM LOGIC_SR
)
---- FILTER LAYER ----

, FILTER_HR as (
    SELECT *
    FROM RENAME_HR
)

, FILTER_SR as (
    SELECT *
    FROM RENAME_SR
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HR
    INNER JOIN FILTER_SR
        ON FILTER_HR.RETAILER_HK = SR_RETAILER_HK
)

---- FINAL LAYER ----
SELECT
              row_number() over(order by 1)                            as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , PIT_LOAD_DTS
        , RETAILER_HK
        , RETAILER_BK
        , BKCC
        , REC_SRC
        , ID
        , COUNTRY
        , ALIAS
FROM JOIN_RESULT
