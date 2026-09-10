---- SRC LAYER ----
WITH
SRC_zrmareat       as ( SELECT GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, LOAD_DTS, MANDT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REC_SRC, SPRAS, TXT30, ZZRMAREA FROM {{ ref('v_psa_stg_item_room_area_detail__winn_sap') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ZZRMAREA, SPRAS ORDER BY LOAD_DTS DESC) )

/*
SRC_zrmareat       as ( SELECT * FROM STAGING.v_psa_stg_item_room_area_detail__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_zrmareat as (
    SELECT
        MANDT                                                        as                                             CLIENT
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , ZZRMAREA                                                     as                                       ROOM_AREA_ID
      , TXT30                                                        as                                   ROOM_AREA_DETAIL
      , GLREQUEST
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM SRC_zrmareat
)
---- RENAME LAYER ----

, RENAME_zrmareat as (
    SELECT
        CLIENT
      , LANGUAGE_KEY
      , ROOM_AREA_ID
      , ROOM_AREA_DETAIL
      , GLREQUEST
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_zrmareat
)
---- FILTER LAYER ----

, FILTER_zrmareat as (
    SELECT *
    FROM RENAME_zrmareat
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_zrmareat
)

---- FINAL LAYER ----
SELECT
          CLIENT
        , LANGUAGE_KEY
        , ROOM_AREA_ID
        , ROOM_AREA_DETAIL
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
