---- SRC LAYER ----
WITH
SRC_zplint         as ( SELECT GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, LOAD_DTS, MANDT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REC_SRC, SPRAS, TXT30, ZZLIN FROM {{ ref('v_psa_stg_item_product_line__winn_sap') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ZZLIN, SPRAS ORDER BY LOAD_DTS DESC) )

/*
SRC_zplint         as ( SELECT * FROM STAGING.v_psa_stg_item_product_line__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_zplint as (
    SELECT
        MANDT                                                        as                                             CLIENT
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , ZZLIN                                                        as                                    PRODUCT_LINE_ID
      , TXT30                                                        as                                       PRODUCT_LINE
      , GLREQUEST
      , GLSOURCESYSTEM
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM SRC_zplint
)
---- RENAME LAYER ----

, RENAME_zplint as (
    SELECT
        CLIENT
      , LANGUAGE_KEY
      , PRODUCT_LINE_ID
      , PRODUCT_LINE
      , GLREQUEST
      , GLSOURCESYSTEM
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_zplint
)
---- FILTER LAYER ----

, FILTER_zplint as (
    SELECT *
    FROM RENAME_zplint
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_zplint
)

---- FINAL LAYER ----
SELECT
          CLIENT
        , LANGUAGE_KEY
        , PRODUCT_LINE_ID
        , PRODUCT_LINE
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
