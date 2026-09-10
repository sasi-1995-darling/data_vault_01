{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HB             as ( SELECT * FROM {{ ref('hub_product_v2') }} as SRC  ),
SRC_RBA            as ( SELECT * FROM {{ ref('ref_brand_appbot') }} as SRC  ),
SRC_RB             as ( SELECT * FROM {{ ref('ref_brand') }} as SRC  )

/*
SRC_HB             as ( SELECT * FROM raw_vault.hub_product_v2 )
, SRC_RBA            as ( SELECT * FROM bus_vault.ref_brand_appbot )
, SRC_RB             as ( SELECT * FROM bus_vault.ref_brand )
*/
---- LOGIC LAYER ----

, LOGIC_HB as (
    SELECT
        BKCC
      , REC_SRC
      , '0'                                                          as                                                 ID
      , PRODUCT_BK
    FROM SRC_HB
)

, LOGIC_RBA as (
    SELECT
        APPBOT_PRODUCT
      , brand                                                        as                                          rba_brand
    FROM SRC_RBA
)

, LOGIC_RB as (
    SELECT
        SYSTEM_BRAND
      , BUSINESS_UNIT
      , CASE WHEN COMPETITOR = TRUE THEN 'Y' ELSE 'N' END            as                                     COMPETITOR_IND
      , SYSTEM_BRAND                                                 as                                           BRAND_BK
      , BRAND                                                        as                                          FULL_NAME
      , BRAND                                                        as                                              OWNER
      , BRAND
      , SUB_BRAND                                                    as                                           SUBBRAND
      , ''                                                           as                                        SUBSUBBRAND
    FROM SRC_RB
)
---- RENAME LAYER ----

, RENAME_HB as (
    SELECT
        BKCC
      , REC_SRC
      , ID
      , PRODUCT_BK
    FROM LOGIC_HB
)

, RENAME_RB as (
    SELECT
        SYSTEM_BRAND
      , BUSINESS_UNIT
      , COMPETITOR_IND
      , BRAND_BK
      , FULL_NAME
      , OWNER
      , BRAND
      , SUBBRAND
      , SUBSUBBRAND
    FROM LOGIC_RB
)

, RENAME_RBA as (
    SELECT
        APPBOT_PRODUCT
      , rba_brand
    FROM LOGIC_RBA
)
---- FILTER LAYER ----

, FILTER_HB as (
    SELECT *
    FROM RENAME_HB
)

, FILTER_RBA as (
    SELECT *
    FROM RENAME_RBA
)

, FILTER_RB as (
    SELECT *
    FROM RENAME_RB
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HB
    INNER JOIN FILTER_RBA
        ON PRODUCT_BK = APPBOT_PRODUCT
    INNER JOIN FILTER_RB
        ON UPPER(rba_brand) = UPPER(SYSTEM_BRAND)
)

---- FINAL LAYER ----
SELECT
              row_number() over(order by 1)                            as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PIT_LOAD_DTS
        , BKCC
        , REC_SRC
        , ID
        , SYSTEM_BRAND
        , BUSINESS_UNIT
        , COMPETITOR_IND
        , BRAND_BK
        , FULL_NAME
        , OWNER
        , BRAND
        , SUBBRAND
        , SUBSUBBRAND
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BRAND_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as BRAND_HK
FROM JOIN_RESULT
