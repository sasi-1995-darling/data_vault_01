---- SRC LAYER ----
WITH
SRC_mp             as ( SELECT * FROM {{ ref('v_psa_stg_flat_file_connected_products_classification_for_sentiment_moen_physical') }} as SRC 
                        WHERE  PSA_DELETE_IND = 'N'
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY BASE_MATERIAL_NUMBER, SRC_ID ORDER BY _LINE, PSA_LOAD_DTS DESC) ),
SRC_yc             as ( SELECT * FROM {{ ref('v_psa_stg_flat_file_connected_products_classification_for_sentiment_yale_combined') }} as SRC 
                        WHERE  PSA_DELETE_IND = 'N'
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY MODEL, SRC_ID ORDER BY _LINE, PSA_LOAD_DTS DESC) ),
SRC_tmlc           as ( SELECT * FROM {{ ref('ref_product_profitero_tmlc') }} as SRC  )

/*
SRC_mp             as ( SELECT * FROM staging.v_psa_stg_flat_file_connected_products_classification_for_sentiment_moen_physical )
, SRC_yc             as ( SELECT * FROM staging.v_psa_stg_flat_file_connected_products_classification_for_sentiment_yale_combined )
, SRC_tmlc           as ( SELECT * FROM bus_vault.ref_product_profitero_tmlc )
*/
---- LOGIC LAYER ----

, LOGIC_mp as (
    SELECT
        'PROFITERO'                                                  as                                      SENTIMENT_SRC
      , SRC_ID
      , CONNECTED_PRODUCTS_CLASS
      , ROOM_AREA
      , CONNECTED_FLAG
      , PSA_LOAD_DTS
      , ''                                                           as                                     PRODUCT_FAMILY
    FROM SRC_mp
)

, LOGIC_yc as (
    SELECT
        'PROFITERO'                                                  as                                      SENTIMENT_SRC
      , SRC_ID
      , PRODUCT_CATEGORY                                             as                           CONNECTED_PRODUCTS_CLASS
      , PRODUCT_AREA                                                 as                                          ROOM_AREA
      , CONNECTED_FLAG
      , PSA_LOAD_DTS
      , PRODUCT_FAMILY
    FROM SRC_yc
)

, LOGIC_tmlc as (
    SELECT
        'PROFITERO'                                                  as                                      SENTIMENT_SRC
      , SRC_ID
      , CONNECTED_PRODUCTS_CLASS
      , ROOM_AREA
      , CONNECTED_FLAG
      , PSA_LOAD_DTS
      , ''                                                           as                                     PRODUCT_FAMILY
    FROM SRC_tmlc
)
---- RENAME LAYER ----

, RENAME_mp as (
    SELECT
        SENTIMENT_SRC
      , SRC_ID
      , CONNECTED_PRODUCTS_CLASS
      , ROOM_AREA
      , CONNECTED_FLAG
      , PSA_LOAD_DTS
      , PRODUCT_FAMILY
    FROM LOGIC_mp
)

, RENAME_yc as (
    SELECT
        SENTIMENT_SRC
      , SRC_ID
      , CONNECTED_PRODUCTS_CLASS
      , ROOM_AREA
      , CONNECTED_FLAG
      , PSA_LOAD_DTS
      , PRODUCT_FAMILY
    FROM LOGIC_yc
)

, RENAME_tmlc as (
    SELECT
        SENTIMENT_SRC
      , SRC_ID
      , CONNECTED_PRODUCTS_CLASS
      , ROOM_AREA
      , CONNECTED_FLAG
      , PSA_LOAD_DTS
      , PRODUCT_FAMILY
    FROM LOGIC_tmlc
)
---- FILTER LAYER ----

, FILTER_mp as (
    SELECT *
    FROM RENAME_mp
)

, FILTER_yc as (
    SELECT *
    FROM RENAME_yc
)

, FILTER_tmlc as (
    SELECT *
    FROM RENAME_tmlc
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_mp
    UNION
    SELECT * FROM FILTER_yc
    UNION
    SELECT * FROM FILTER_tmlc
)

---- FINAL LAYER ----
SELECT
          SENTIMENT_SRC
        , SRC_ID
        , CONNECTED_PRODUCTS_CLASS
        , ROOM_AREA
        , CONNECTED_FLAG
        , PSA_LOAD_DTS
        , PRODUCT_FAMILY
FROM JOIN_RESULT
QUALIFY (ROW_NUMBER() OVER(PARTITION BY sentiment_src, src_id  order by psa_load_dts))=1