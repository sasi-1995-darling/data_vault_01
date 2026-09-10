---- SRC LAYER ----
WITH
SRC_PP             as ( SELECT BKCC, BRAND_ID, CONNECTED_FLAG, CONNECTED_PRODUCTS_CLASS, CUSTOMER_PRODUCT_ID, EAN, FIRE_RESISTANT_ATTR, LEVEL_1, LEVEL_2, MAP_PRICE, MODEL, PRODUCT_BK, PRODUCT_FAMILY, PRODUCT_HK, PRODUCT_NAME, REC_SRC, ROOM_AREA, RPC, SENTIMENT_SRC, SMART_ATTR, SRC_ID, UPC FROM {{ ref('pit_stg_product__profitero') }} as SRC  ),
SRC_PA             as ( SELECT BKCC, BRAND_ID, CONNECTED_FLAG, CONNECTED_PRODUCTS_CLASS, CUSTOMER_PRODUCT_ID, EAN, FIRE_RESISTANT_ATTR, LEVEL_1, LEVEL_2, MAP_PRICE, MODEL, PRODUCT_BK, PRODUCT_HK, PRODUCT_NAME, REC_SRC, ROOM_AREA, RPC, SENTIMENT_SRC, SMART_ATTR, SRC_ID, UPC FROM {{ ref('pit_stg_product__appbot') }} as SRC  ),
SRC_PD             as ( SELECT BKCC, BRAND_ID, CONNECTED_FLAG, CONNECTED_PRODUCTS_CLASS, CUSTOMER_PRODUCT_ID, EAN, FIRE_RESISTANT_ATTR, LEVEL_1, LEVEL_2, MAP_PRICE, MODEL, PRODUCT_BK, PRODUCT_HK, PRODUCT_NAME, REC_SRC, ROOM_AREA, RPC, SENTIMENT_SRC, SMART_ATTR, SRC_ID, UPC FROM {{ ref('pit_stg_product__delighted') }} as SRC  ),
SRC_PDY            as ( SELECT BKCC, BRAND_ID, CONNECTED_FLAG, CONNECTED_PRODUCTS_CLASS, CUSTOMER_PRODUCT_ID, EAN, FIRE_RESISTANT_ATTR, LEVEL_1, LEVEL_2, MAP_PRICE, MODEL, PRODUCT_BK, PRODUCT_FAMILY, PRODUCT_HK, PRODUCT_NAME, REC_SRC, ROOM_AREA, RPC, SENTIMENT_SRC, SMART_ATTR, SRC_ID, UPC FROM {{ ref('pit_stg_product__delighted_yale') }} as SRC  ),
SRC_PBV            as ( SELECT BKCC, BRAND_ID, CONNECTED_FLAG, CONNECTED_PRODUCTS_CLASS, CUSTOMER_PRODUCT_ID, EAN, FIRE_RESISTANT_ATTR, LEVEL_1, LEVEL_2, MAP_PRICE, MODEL, PRODUCT_BK, PRODUCT_HK, PRODUCT_NAME, REC_SRC, ROOM_AREA, RPC, SENTIMENT_SRC, SMART_ATTR, SRC_ID, UPC FROM {{ ref('pit_stg_product__bazaarvoice') }} as SRC  ),
SRC_PBVY           as ( SELECT BKCC, BRAND_ID, CONNECTED_FLAG, CONNECTED_PRODUCTS_CLASS, CUSTOMER_PRODUCT_ID, EAN, FIRE_RESISTANT_ATTR, LEVEL_1, LEVEL_2, MAP_PRICE, MODEL, PRODUCT_BK, PRODUCT_FAMILY, PRODUCT_HK, PRODUCT_NAME, REC_SRC, ROOM_AREA, RPC, SENTIMENT_SRC, SMART_ATTR, SRC_ID, UPC FROM {{ ref('pit_stg_product__bazaarvoice_yale') }} as SRC  ),
SRC_PPS            as ( SELECT BKCC, BRAND_ID, CONNECTED_FLAG, CONNECTED_PRODUCTS_CLASS, CUSTOMER_PRODUCT_ID, EAN, FIRE_RESISTANT_ATTR, LEVEL_1, LEVEL_2, MAP_PRICE, MODEL, PRODUCT_BK, PRODUCT_FAMILY, PRODUCT_HK, PRODUCT_NAME, REC_SRC, ROOM_AREA, RPC, SENTIMENT_SRC, SMART_ATTR, SRC_ID, UPC FROM {{ ref('pit_stg_product__profitero_share') }} as SRC  ),
SRC_PSY            as ( SELECT BKCC, BRAND_ID, CONNECTED_FLAG, CONNECTED_PRODUCTS_CLASS, CUSTOMER_PRODUCT_ID, EAN, FIRE_RESISTANT_ATTR, LEVEL_1, LEVEL_2, MAP_PRICE, MODEL, PRODUCT_BK, PRODUCT_FAMILY, PRODUCT_HK, PRODUCT_NAME, REC_SRC, ROOM_AREA, RPC, SENTIMENT_SRC, SMART_ATTR, SRC_ID, UPC FROM {{ ref('pit_stg_product__simplesat_yale') }} as SRC  )

/*
SRC_PP             as ( SELECT * FROM bus_vault.pit_stg_product__profitero )
SRC_PA             as ( SELECT * FROM bus_vault.pit_stg_product__appbot )
SRC_PD             as ( SELECT * FROM bus_vault.pit_stg_product__delighted )
SRC_PDY            as ( SELECT * FROM bus_vault.pit_stg_product__delighted_yale )
SRC_PBV            as ( SELECT * FROM bus_vault.pit_stg_product__bazaarvoice )
SRC_PBVY           as ( SELECT * FROM bus_vault.pit_stg_product__bazaarvoice_yale )
SRC_PPS            as ( SELECT * FROM bus_vault.pit_stg_product__profitero_share )
SRC_PSY            as ( SELECT * FROM bus_vault.pit_stg_product__simplesat_yale )
*/
---- LOGIC LAYER ----

, LOGIC_PP as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , MODEL
      , BKCC
      , REC_SRC
      , PRODUCT_NAME
      , BRAND_ID
      , CUSTOMER_PRODUCT_ID
      , LEVEL_1
      , LEVEL_2
      , CONNECTED_FLAG
      , PRODUCT_FAMILY
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SRC_ID
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
      , 2 AS SRC_PRIORITY   -- old profitero: loses to share on PRODUCT_HK+BKCC collision
    FROM SRC_PP
)

, LOGIC_PA as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , MODEL
      , BKCC
      , REC_SRC
      , PRODUCT_NAME
      , BRAND_ID
      , CUSTOMER_PRODUCT_ID
      , LEVEL_1
      , LEVEL_2
      , CONNECTED_FLAG
      , ''                                                           as                                     PRODUCT_FAMILY
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SRC_ID
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
      , 1 AS SRC_PRIORITY   -- appbot: no overlap with share, treated as preferred
    FROM SRC_PA
)

, LOGIC_PD as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , MODEL
      , BKCC
      , REC_SRC
      , PRODUCT_NAME
      , BRAND_ID
      , CUSTOMER_PRODUCT_ID
      , LEVEL_1
      , LEVEL_2
      , CONNECTED_FLAG
      , ''                                                           as                                     PRODUCT_FAMILY
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SRC_ID
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
      , 1 AS SRC_PRIORITY   -- delighted: no overlap with share
    FROM SRC_PD
)

, LOGIC_PDY as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , MODEL
      , BKCC
      , REC_SRC
      , PRODUCT_NAME
      , BRAND_ID
      , CUSTOMER_PRODUCT_ID
      , LEVEL_1
      , LEVEL_2
      , CONNECTED_FLAG
      , PRODUCT_FAMILY
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SRC_ID
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
      , 1 AS SRC_PRIORITY   -- delighted_yale: no overlap with share
    FROM SRC_PDY
)

, LOGIC_PBV as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , MODEL
      , BKCC
      , REC_SRC
      , PRODUCT_NAME
      , BRAND_ID
      , CUSTOMER_PRODUCT_ID
      , LEVEL_1
      , LEVEL_2
      , CONNECTED_FLAG
      , ''                                                           as                                     PRODUCT_FAMILY
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SRC_ID
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
      , 1 AS SRC_PRIORITY   -- bazaarvoice: no overlap with share
    FROM SRC_PBV
)

, LOGIC_PBVY as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , MODEL
      , BKCC
      , REC_SRC
      , PRODUCT_NAME
      , BRAND_ID
      , CUSTOMER_PRODUCT_ID
      , LEVEL_1
      , LEVEL_2
      , CONNECTED_FLAG
      , PRODUCT_FAMILY
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SRC_ID
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
      , 1 AS SRC_PRIORITY   -- bazaarvoice_yale: no overlap with share
    FROM SRC_PBVY
)

, LOGIC_PPS as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , MODEL
      , BKCC
      , REC_SRC
      , PRODUCT_NAME
      , BRAND_ID
      , CUSTOMER_PRODUCT_ID
      , LEVEL_1
      , LEVEL_2
      , CONNECTED_FLAG
      , PRODUCT_FAMILY
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SRC_ID
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
      , 1 AS SRC_PRIORITY  -- profitero_share: preferred over old profitero on collision
    FROM SRC_PPS
)

, LOGIC_PSY as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , MODEL
      , BKCC
      , REC_SRC
      , PRODUCT_NAME
      , BRAND_ID
      , CUSTOMER_PRODUCT_ID
      , LEVEL_1
      , LEVEL_2
      , CONNECTED_FLAG
      , PRODUCT_FAMILY
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SRC_ID
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
      , 1 AS SRC_PRIORITY   -- simplesat_yale: no overlap with share
    FROM SRC_PSY
)
---- RENAME LAYER ----

, RENAME_PP as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , MODEL
      , BKCC
      , REC_SRC
      , PRODUCT_NAME
      , BRAND_ID
      , CUSTOMER_PRODUCT_ID
      , LEVEL_1
      , LEVEL_2
      , CONNECTED_FLAG
      , PRODUCT_FAMILY
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SRC_ID
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
      , SRC_PRIORITY
    FROM LOGIC_PP
)

, RENAME_PA as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , MODEL
      , BKCC
      , REC_SRC
      , PRODUCT_NAME
      , BRAND_ID
      , CUSTOMER_PRODUCT_ID
      , LEVEL_1
      , LEVEL_2
      , CONNECTED_FLAG
      , PRODUCT_FAMILY
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SRC_ID
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
      , SRC_PRIORITY
    FROM LOGIC_PA
)

, RENAME_PD as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , MODEL
      , BKCC
      , REC_SRC
      , PRODUCT_NAME
      , BRAND_ID
      , CUSTOMER_PRODUCT_ID
      , LEVEL_1
      , LEVEL_2
      , CONNECTED_FLAG
      , PRODUCT_FAMILY
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SRC_ID
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
      , SRC_PRIORITY
    FROM LOGIC_PD
)

, RENAME_PDY as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , MODEL
      , BKCC
      , REC_SRC
      , PRODUCT_NAME
      , BRAND_ID
      , CUSTOMER_PRODUCT_ID
      , LEVEL_1
      , LEVEL_2
      , CONNECTED_FLAG
      , PRODUCT_FAMILY
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SRC_ID
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
      , SRC_PRIORITY
    FROM LOGIC_PDY
)

, RENAME_PBV as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , MODEL
      , BKCC
      , REC_SRC
      , PRODUCT_NAME
      , BRAND_ID
      , CUSTOMER_PRODUCT_ID
      , LEVEL_1
      , LEVEL_2
      , CONNECTED_FLAG
      , PRODUCT_FAMILY
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SRC_ID
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
      , SRC_PRIORITY
    FROM LOGIC_PBV
)

, RENAME_PBVY as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , MODEL
      , BKCC
      , REC_SRC
      , PRODUCT_NAME
      , BRAND_ID
      , CUSTOMER_PRODUCT_ID
      , LEVEL_1
      , LEVEL_2
      , CONNECTED_FLAG
      , PRODUCT_FAMILY
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SRC_ID
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
      , SRC_PRIORITY
    FROM LOGIC_PBVY
)

, RENAME_PPS as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , MODEL
      , BKCC
      , REC_SRC
      , PRODUCT_NAME
      , BRAND_ID
      , CUSTOMER_PRODUCT_ID
      , LEVEL_1
      , LEVEL_2
      , CONNECTED_FLAG
      , PRODUCT_FAMILY
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SRC_ID
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
      , SRC_PRIORITY
    FROM LOGIC_PPS
)

, RENAME_PSY as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , MODEL
      , BKCC
      , REC_SRC
      , PRODUCT_NAME
      , BRAND_ID
      , CUSTOMER_PRODUCT_ID
      , LEVEL_1
      , LEVEL_2
      , CONNECTED_FLAG
      , PRODUCT_FAMILY
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SRC_ID
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
      , SRC_PRIORITY
    FROM LOGIC_PSY
)
---- FILTER LAYER ----

, FILTER_PP as (
    SELECT *
    FROM RENAME_PP
)

, FILTER_PA as (
    SELECT *
    FROM RENAME_PA
)

, FILTER_PD as (
    SELECT *
    FROM RENAME_PD
)

, FILTER_PDY as (
    SELECT *
    FROM RENAME_PDY
)

, FILTER_PBV as (
    SELECT *
    FROM RENAME_PBV
)

, FILTER_PBVY as (
    SELECT *
    FROM RENAME_PBVY
)

, FILTER_PPS as (
    SELECT *
    FROM RENAME_PPS
)

, FILTER_PSY as (
    SELECT *
    FROM RENAME_PSY
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PP
    UNION ALL
    SELECT * FROM FILTER_PA
    UNION ALL
    SELECT * FROM FILTER_PD
    UNION ALL
    SELECT * FROM FILTER_PDY
    UNION ALL
    SELECT * FROM FILTER_PBV
    UNION ALL
    SELECT * FROM FILTER_PBVY
    UNION ALL
    SELECT * FROM FILTER_PPS
    UNION ALL
    SELECT * FROM FILTER_PSY
)

---- FINAL LAYER ----
SELECT
              row_number() over(order by 1)                            as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PIT_LOAD_DTS
        , PRODUCT_HK
        , PRODUCT_BK
        , MODEL
        , BKCC
        , REC_SRC
        , PRODUCT_NAME
        , BRAND_ID
        , COALESCE(RPC,'')                                             as RPC
        , COALESCE(EAN,'')                                             as EAN
        , COALESCE(UPC,'')                                             as UPC
        , COALESCE(MAP_PRICE,0)                                        as MAP_PRICE
        , COALESCE(SENTIMENT_SRC,'')                                   as SENTIMENT_SRC
        , COALESCE(SRC_ID,'')                                          as SRC_ID
        , COALESCE(ROOM_AREA,'')                                       as ROOM_AREA
        , COALESCE(CONNECTED_PRODUCTS_CLASS,'')                        as CONNECTED_PRODUCTS_CLASS
        , COALESCE(FIRE_RESISTANT_ATTR,'')                             as FIRE_RESISTANT_ATTR
        , COALESCE(SMART_ATTR,'FALSE')                                 as SMART_ATTR
        , CUSTOMER_PRODUCT_ID
        , LEVEL_1
        , LEVEL_2
        , CONNECTED_FLAG
        , PRODUCT_FAMILY
FROM JOIN_RESULT
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY PRODUCT_HK, BKCC
    ORDER BY SRC_PRIORITY ASC
) = 1