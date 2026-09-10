---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('menards_ft_psa', 'menards_moen_sales_inventory') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM menards_ft_psa.menards_moen_sales_inventory )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        COLUMN_0::varchar                                            as                                           LOCATION
      , COLUMN_2                                                     as                                               ITEM
      , _LINE
      , _FILE
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , _MODIFIED
      , COLUMN_3                                                     as                                          ITEM_NAME
      , COLUMN_4                                                     as                                                SKU
      , COLUMN_6                                                     as                                         UNIT_SALES
      , COLUMN_7                                                     as                                       DOLLAR_SALES
      , COLUMN_8                                                     as                                      DOLLAR_MARGIN
      , COLUMN_9                                                     as                                     MARGIN_PERCENT
      , COLUMN_10                                                    as                                TOTAL_UNITS_ON_HAND
      , COLUMN_11                                                    as                          TOTAL_DOLLAR_COST_ON_HAND
      , COLUMN_12                                                    as                               TOTAL_UNITS_ON_ORDER
      , COLUMN_13                                                    as                         TOTAL_DOLLAR_COST_ON_ORDER
      , COLUMN_14                                                    as                        STORE_CURRENT_UNITS_ON_HAND
      , COLUMN_15                                                    as                          STORE_DOLLAR_COST_ON_HAND
      , COLUMN_16                                                    as                               STORE_UNITS_ON_ORDER
      , COLUMN_17                                                    as                         STORE_DOLLAR_COST_ON_ORDER
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
        LOCATION
      , ITEM
      , _LINE
      , _FILE
      , LOAD_DTS
      , _MODIFIED
      , ITEM_NAME
      , SKU
      , UNIT_SALES
      , DOLLAR_SALES
      , DOLLAR_MARGIN
      , MARGIN_PERCENT
      , TOTAL_UNITS_ON_HAND
      , TOTAL_DOLLAR_COST_ON_HAND
      , TOTAL_UNITS_ON_ORDER
      , TOTAL_DOLLAR_COST_ON_ORDER
      , STORE_CURRENT_UNITS_ON_HAND
      , STORE_DOLLAR_COST_ON_HAND
      , STORE_UNITS_ON_ORDER
      , STORE_DOLLAR_COST_ON_ORDER
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
    WHERE TRUE
/* The following qualify clause is required to pull the first row pushed to PSA based on these PK columns*/
qualify 1 = row_number()over (partition by  location, item, _line, _file, load_dts order by psa_load_dts)
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'US.EXCEL.MENARDS.MOEN_SALES_AND_INVENTORY_WEEKLY'
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
          LOCATION                                                     as STORE_BK
        , LOCATION
        , ITEM
        , _LINE
        , _FILE
        , LOAD_DTS
        , _MODIFIED
        , ITEM_NAME
        , SKU
        , UNIT_SALES
        , DOLLAR_SALES
        , DOLLAR_MARGIN
        , MARGIN_PERCENT
        , TOTAL_UNITS_ON_HAND
        , TOTAL_DOLLAR_COST_ON_HAND
        , TOTAL_UNITS_ON_ORDER
        , TOTAL_DOLLAR_COST_ON_ORDER
        , STORE_CURRENT_UNITS_ON_HAND
        , STORE_DOLLAR_COST_ON_HAND
        , STORE_UNITS_ON_ORDER
        , STORE_DOLLAR_COST_ON_ORDER
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LOCATION as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ITEM_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SKU::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_SALES::text), '^^') 
            , '||', IFNULL(TRIM(DOLLAR_SALES::text), '^^') 
            , '||', IFNULL(TRIM(DOLLAR_MARGIN::text), '^^') 
            , '||', IFNULL(TRIM(MARGIN_PERCENT::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_UNITS_ON_HAND::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_DOLLAR_COST_ON_HAND::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_UNITS_ON_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_DOLLAR_COST_ON_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(STORE_CURRENT_UNITS_ON_HAND::text), '^^') 
            , '||', IFNULL(TRIM(STORE_DOLLAR_COST_ON_HAND::text), '^^') 
            , '||', IFNULL(TRIM(STORE_UNITS_ON_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(STORE_DOLLAR_COST_ON_ORDER::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
