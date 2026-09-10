---- SRC LAYER ----
WITH
SRC_zcmpfamt       as ( SELECT GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, LOAD_DTS, MANDT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REC_SRC, SPRAS, TXT30, ZZCPF FROM {{ ref('v_psa_stg_item_price_band__winn_sap') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ZZCPF, SPRAS ORDER BY LOAD_DTS DESC) )

/*
SRC_zcmpfamt       as ( SELECT * FROM STAGING.v_psa_stg_item_price_band__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_zcmpfamt as (
    SELECT
        MANDT                                                        as                                             CLIENT
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , ZZCPF                                                        as                                      PRICE_BAND_ID
      , TXT30                                                        as                                         PRICE_BAND
      , GLREQUEST
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM SRC_zcmpfamt
)
---- RENAME LAYER ----

, RENAME_zcmpfamt as (
    SELECT
        CLIENT
      , LANGUAGE_KEY
      , PRICE_BAND_ID
      , PRICE_BAND
      , GLREQUEST
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_zcmpfamt
)
---- FILTER LAYER ----

, FILTER_zcmpfamt as (
    SELECT *
    FROM RENAME_zcmpfamt
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_zcmpfamt
)

---- FINAL LAYER ----
SELECT
          CLIENT
        , LANGUAGE_KEY
        , PRICE_BAND_ID
        , PRICE_BAND
        , GLREQUEST
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
