---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('menards_ft_psa', 'menards_larson_pos') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM menards_ft_psa.menards_larson_pos )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        COLUMN_1                                                     as                                           STORE_BK
      , COLUMN_0                                                     as                                                DAY
      , COLUMN_1                                                     as                                           LOCATION
      , COLUMN_4                                                     as                                               ITEM
      , _LINE
      , _FILE
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , _MODIFIED
      , COLUMN_2                                                     as                               LOCATION_DESCRIPTION
      , COLUMN_3                                                     as                                             FAMILY
      , COLUMN_5                                                     as                                   ITEM_DESCRIPTION
      , COLUMN_6                                                     as                                 ITEM_DESCRIPTION_2
      , COLUMN_7                                                     as                                            METRICS
      , COLUMN_8                                                     as                                         UNIT_SALES
      , COLUMN_9                                                     as                                              SALES
      , COLUMN_10                                                    as                                             MARGIN
      , COLUMN_11                                                    as                                  MARGIN_PERCENTAGE
      , COLUMN_12                                                    as                                TOTAL_UNITS_ON_HAND
      , COLUMN_13                                                    as                                 TOTAL_COST_ON_HAND
      , COLUMN_14                                                    as                               TOTAL_UNITS_ON_ORDER
      , COLUMN_15                                                    as                                TOTAL_COST_ON_ORDER
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        STORE_BK
      , DAY
      , LOCATION
      , ITEM
      , _LINE
      , _FILE
      , LOAD_DTS
      , _MODIFIED
      , LOCATION_DESCRIPTION
      , FAMILY
      , ITEM_DESCRIPTION
      , ITEM_DESCRIPTION_2
      , METRICS
      , UNIT_SALES
      , SALES
      , MARGIN
      , MARGIN_PERCENTAGE
      , TOTAL_UNITS_ON_HAND
      , TOTAL_COST_ON_HAND
      , TOTAL_UNITS_ON_ORDER
      , TOTAL_COST_ON_ORDER
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'US.EXCEL.MENARDS.SALES_AND_INVENTORY_LARSON'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          STORE_BK
        , DAY
        , LOCATION
        , ITEM
        , _LINE
        , _FILE
        , LOAD_DTS
        , _MODIFIED
        , LOCATION_DESCRIPTION
        , FAMILY
        , ITEM_DESCRIPTION
        , ITEM_DESCRIPTION_2
        , METRICS
        , UNIT_SALES
        , SALES
        , MARGIN
        , MARGIN_PERCENTAGE
        , TOTAL_UNITS_ON_HAND
        , TOTAL_COST_ON_HAND
        , TOTAL_UNITS_ON_ORDER
        , TOTAL_COST_ON_ORDER
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(STORE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(LOCATION_DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(FAMILY::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_DESCRIPTION_2::text), '^^') 
            , '||', IFNULL(TRIM(METRICS::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_SALES::text), '^^') 
            , '||', IFNULL(TRIM(SALES::text), '^^') 
            , '||', IFNULL(TRIM(MARGIN::text), '^^') 
            , '||', IFNULL(TRIM(MARGIN_PERCENTAGE::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_UNITS_ON_HAND::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_COST_ON_HAND::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_UNITS_ON_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_COST_ON_ORDER::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
