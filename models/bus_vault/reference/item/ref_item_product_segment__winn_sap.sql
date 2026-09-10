---- SRC LAYER ----
WITH
SRC_zpsegt         as ( SELECT GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, LOAD_DTS, MANDT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REC_SRC, SPRAS, TXT30, ZZSEG FROM {{ ref('v_psa_stg_item_product_segment__winn_sap') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ZZSEG, SPRAS ORDER BY LOAD_DTS DESC) )

/*
SRC_zpsegt         as ( SELECT * FROM STAGING.v_psa_stg_item_product_segment__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_zpsegt as (
    SELECT
        MANDT                                                        as                                             CLIENT
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , ZZSEG                                                        as                                 PRODUCT_SEGMENT_ID
      , TXT30                                                        as                                    PRODUCT_SEGMENT
      , GLREQUEST
      , GLSOURCESYSTEM
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM SRC_zpsegt
)
---- RENAME LAYER ----

, RENAME_zpsegt as (
    SELECT
        CLIENT
      , LANGUAGE_KEY
      , PRODUCT_SEGMENT_ID
      , PRODUCT_SEGMENT
      , GLREQUEST
      , GLSOURCESYSTEM
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_zpsegt
)
---- FILTER LAYER ----

, FILTER_zpsegt as (
    SELECT *
    FROM RENAME_zpsegt
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_zpsegt
)

---- FINAL LAYER ----
SELECT
          CLIENT
        , LANGUAGE_KEY
        , PRODUCT_SEGMENT_ID
        , PRODUCT_SEGMENT
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
