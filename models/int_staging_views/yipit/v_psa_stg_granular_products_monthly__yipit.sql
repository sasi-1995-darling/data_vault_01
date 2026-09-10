---- SRC LAYER ----
WITH
SRC_s              as ( SELECT * FROM {{ source('reference', 'yipit_granular_products_monthly_v3_paleturquoisebrook_view') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_s              as ( SELECT * FROM reference.yipit_granular_products_monthly_v3_paleturquoisebrook_view )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        MONTH
      , RETAILER
      , CHANNEL
      , SEGMENT
      , CATEGORY
      , SUB_CATEGORY
      , CLASS
      , SUB_CLASS
      , MANUFACTURER
      , BRAND
      , WEB_DESCRIPTION
      , SKU
      , UPC
      , MODEL_NUM
      , TSA_APPROVED
      , SOLID_VS_LAMINATED
      , SAFE_VOLUME
      , FINISHED
      , GLASS_TYPE
      , ACCESSORIES_INCLUDED
      , DECK_BOARD_LENGTH
      , MATERIAL
      , FINISH
      , CONNECTED_FLAG
      , GMV
      , SAMPLE_SIZE
      , ASP
      , UNIT_EST
      , STATE
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
    FROM SRC_s
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        MONTH
      , RETAILER
      , CHANNEL
      , SEGMENT
      , CATEGORY
      , SUB_CATEGORY
      , CLASS
      , SUB_CLASS
      , MANUFACTURER
      , BRAND
      , WEB_DESCRIPTION
      , SKU
      , UPC
      , MODEL_NUM
      , TSA_APPROVED
      , SOLID_VS_LAMINATED
      , SAFE_VOLUME
      , FINISHED
      , GLASS_TYPE
      , ACCESSORIES_INCLUDED
      , DECK_BOARD_LENGTH
      , MATERIAL
      , FINISH
      , CONNECTED_FLAG
      , GMV
      , SAMPLE_SIZE
      , ASP
      , UNIT_EST
      , STATE
      , LOAD_DTS
    FROM LOGIC_s
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'US.REFERENCE.YIPIT_GRANULAR_PRODUCTS_XREF'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          MONTH
        , RETAILER
        , CHANNEL
        , SEGMENT
        , CATEGORY
        , SUB_CATEGORY
        , CLASS
        , SUB_CLASS
        , MANUFACTURER
        , BRAND
        , WEB_DESCRIPTION
        , SKU
        , UPC
        , MODEL_NUM
        , TSA_APPROVED
        , SOLID_VS_LAMINATED
        , SAFE_VOLUME
        , FINISHED
        , GLASS_TYPE
        , ACCESSORIES_INCLUDED
        , DECK_BOARD_LENGTH
        , MATERIAL
        , FINISH
        , CONNECTED_FLAG
        , GMV
        , SAMPLE_SIZE
        , ASP
        , UNIT_EST
        , STATE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SKU as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SKU_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(MODEL_NUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as MODEL_NUM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(TSA_APPROVED::text), '^^') 
            , '||', IFNULL(TRIM(SOLID_VS_LAMINATED::text), '^^') 
            , '||', IFNULL(TRIM(SAFE_VOLUME::text), '^^') 
            , '||', IFNULL(TRIM(FINISHED::text), '^^') 
            , '||', IFNULL(TRIM(GLASS_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ACCESSORIES_INCLUDED::text), '^^') 
            , '||', IFNULL(TRIM(DECK_BOARD_LENGTH::text), '^^') 
            , '||', IFNULL(TRIM(MATERIAL::text), '^^') 
            , '||', IFNULL(TRIM(FINISH::text), '^^') 
            , '||', IFNULL(TRIM(CONNECTED_FLAG::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
