---- SRC LAYER ----
WITH
SRC_zpdtpt         as ( SELECT GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, LOAD_DTS, MANDT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REC_SRC, SPRAS, TXT30, ZZDTP FROM {{ ref('v_psa_stg_item_product_type__winn_sap') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ZZDTP, SPRAS ORDER BY LOAD_DTS DESC) )

/*
SRC_zpdtpt         as ( SELECT * FROM STAGING.v_psa_stg_item_product_type__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_zpdtpt as (
    SELECT
        MANDT                                                        as                                             CLIENT
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , ZZDTP                                                        as                                    PRODUCT_TYPE_ID
      , TXT30                                                        as                                       PRODUCT_TYPE
      , GLREQUEST
      , GLSOURCESYSTEM
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM SRC_zpdtpt
)
---- RENAME LAYER ----

, RENAME_zpdtpt as (
    SELECT
        CLIENT
      , LANGUAGE_KEY
      , PRODUCT_TYPE_ID
      , PRODUCT_TYPE
      , GLREQUEST
      , GLSOURCESYSTEM
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_zpdtpt
)
---- FILTER LAYER ----

, FILTER_zpdtpt as (
    SELECT *
    FROM RENAME_zpdtpt
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_zpdtpt
)

---- FINAL LAYER ----
SELECT
          CLIENT
        , LANGUAGE_KEY
        , PRODUCT_TYPE_ID
        , PRODUCT_TYPE
        , GLREQUEST
        , GLSOURCESYSTEM
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT