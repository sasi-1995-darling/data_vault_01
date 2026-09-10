---- SRC LAYER ----
WITH
SRC_HP             as ( SELECT * FROM {{ ref('hub_product_v2') }} as SRC  ),
SRC_CPP            as ( SELECT * FROM {{ ref('sat_customer_product__profitero') }} as SRC 
                        qualify 1= row_number() over(partition by PRODUCT_HK order by UPDATED_AT DESC) ),
SRC_LPB            as ( SELECT * FROM {{ ref('lnk_product_brand') }} as SRC  ),
SRC_SBP            as ( SELECT * FROM {{ ref('sat_brand__profitero') }} as SRC 
                        WHERE NAME LIKE ANY ('%Master Lock%','%SentrySafe%')
                        qualify 1= row_number() over(partition by BRAND_HK order by UPDATED_AT DESC) )

/*
SRC_HP             as ( SELECT * FROM raw_vault.HUB_PRODUCT_V2 )
, SRC_CPP            as ( SELECT * FROM raw_vault.SAT_CUSTOMER_PRODUCT__PROFITERO )
, SRC_LPB            as ( SELECT * FROM raw_vault.LNK_PRODUCT_BRAND )
, SRC_SBP            as ( SELECT * FROM raw_vault.SAT_BRAND__PROFITERO )
*/
---- LOGIC LAYER ----

, LOGIC_HP as (
    SELECT
        PRODUCT_HK                                                   as                                      HP_PRODUCT_HK
      , PRODUCT_BK                                                   as                                             SRC_ID
    FROM SRC_HP
)

, LOGIC_CPP as (
    SELECT
        PRODUCT_HK                                                   as                                     CPP_PRODUCT_HK
      , PSA_LOAD_DTS
      , regexp_replace(MODEL,'[^[:ascii:]]')                         as                                              MODEL
      , NAME                                                         as                                       PRODUCT_NAME
      , 'PROFITERO'                                                  as                                      SENTIMENT_SRC
    FROM SRC_CPP
)

, LOGIC_LPB as (
    SELECT
        PRODUCT_HK                                                   as                                     LPB_PRODUCT_HK
      , BRAND_HK                                                     as                                       LPB_BRAND_HK
    FROM SRC_LPB
)

, LOGIC_SBP as (
    SELECT
        BRAND_HK                                                     as                                       SBP_BRAND_HK
    FROM SRC_SBP
)
---- RENAME LAYER ----

, RENAME_HP as (
    SELECT
        HP_PRODUCT_HK
      , SRC_ID
    FROM LOGIC_HP
)

, RENAME_CPP as (
    SELECT
        CPP_PRODUCT_HK
      , PSA_LOAD_DTS
      , MODEL
      , PRODUCT_NAME
      , SENTIMENT_SRC
    FROM LOGIC_CPP
)

, RENAME_LPB as (
    SELECT
        LPB_PRODUCT_HK
      , LPB_BRAND_HK
    FROM LOGIC_LPB
)

, RENAME_SBP as (
    SELECT
        SBP_BRAND_HK
    FROM LOGIC_SBP
)
---- FILTER LAYER ----

, FILTER_HP as (
    SELECT *
    FROM RENAME_HP
)

, FILTER_CPP as (
    SELECT *
    FROM RENAME_CPP
)

, FILTER_LPB as (
    SELECT *
    FROM RENAME_LPB
)

, FILTER_SBP as (
    SELECT *
    FROM RENAME_SBP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HP
    INNER JOIN FILTER_CPP
        ON HP_PRODUCT_HK = CPP_PRODUCT_HK
    INNER JOIN FILTER_LPB
        ON HP_PRODUCT_HK = LPB_PRODUCT_HK
    INNER JOIN FILTER_SBP
        ON LPB_BRAND_HK = SBP_BRAND_HK
)

---- FINAL LAYER ----
SELECT
          PSA_LOAD_DTS
        , MODEL
        , PRODUCT_NAME
        , SENTIMENT_SRC
        , SRC_ID
        , CASE WHEN PRODUCT_NAME LIKE '%Lock Box%' THEN 'Lock Box'
     WHEN PRODUCT_NAME LIKE '%Safe%' THEN 'Safe'
     WHEN PRODUCT_NAME LIKE '%Padlock%' THEN 'Padlock'
ELSE
     'Lock'
END as LEVEL_1
        , CASE WHEN keyword = 'Digital' THEN 'Digital'
ELSE 'Smart' END as PREFIX
        , Prefix || ' ' || LEVEL_1                                     as LEVEL_2
        , 'Y'                                                          as CONNECTED_FLAG
        , ''                                                           as PRODUCT_FAMILY
        , LEVEL_1                                                      as ROOM_AREA
        , LEVEL_2                                                      as CONNECTED_PRODUCTS_CLASS
        , KEYRANK
FROM JOIN_RESULT
INNER JOIN
    (
     SELECT 'Smart' as KEYWORD, 2 as keyrank UNION
     SELECT 'Biometric' as KEYWORD, 2 as keyrank UNION
     SELECT 'Bluetooth' as KEYWORD, 2 as keyrank UNION
     SELECT 'Digital' as KEYWORD, 1 as keyrank UNION
     SELECT 'Software' as KEYWORD, 2 as keyrank
    ) keywords
    ON PRODUCT_NAME LIKE '%' || keywords.keyword || '%'
GROUP BY ALL
qualify 1= row_number() over(partition by MODEL, SRC_ID order by keyrank)