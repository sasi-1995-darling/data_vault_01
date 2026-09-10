---- SRC LAYER ----
WITH
SRC_bom            as ( SELECT * FROM {{ ref('v_psa_stg_item_version__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_bom            as ( SELECT * FROM STAGING.V_PSA_STG_ITEM_VERSION__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_bom as (
    SELECT
        PLANT_ITEM_HK
      , MANDT
      , MATNR
      , WERKS
      , VERID
      , GLREQUEST
      , GLSOURCESYSTEM
      , BDATU
      , ADATU
      , STLAL
      , STLAN
      , PLNTY
      , PLNNR
      , ALNAL
      , BESKZ
      , SOBSL
      , LOSGR
      , MDV01
      , MDV02
      , TEXT1
      , EWAHR
      , VERTO
      , SERKZ
      , BSTMI
      , BSTMA
      , RGEKZ
      , ALORT
      , PLTYG
      , PLNNG
      , ALNAG
      , PLTYM
      , PLNNM
      , ALNAM
      , CSPLT
      , MATKO
      , ELPRO
      , PRVBE
      , PRFG_F
      , PRDAT
      , MKSP
      , PRFG_R
      , PRFG_G
      , PRFG_S
      , UCMAT
      , PPEGUID
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM SRC_bom
)
---- RENAME LAYER ----

, RENAME_bom as (
    SELECT
        PLANT_ITEM_HK
      , MANDT
      , MATNR
      , WERKS
      , VERID
      , GLREQUEST
      , GLSOURCESYSTEM
      , BDATU
      , ADATU
      , STLAL
      , STLAN
      , PLNTY
      , PLNNR
      , ALNAL
      , BESKZ
      , SOBSL
      , LOSGR
      , MDV01
      , MDV02
      , TEXT1
      , EWAHR
      , VERTO
      , SERKZ
      , BSTMI
      , BSTMA
      , RGEKZ
      , ALORT
      , PLTYG
      , PLNNG
      , ALNAG
      , PLTYM
      , PLNNM
      , ALNAM
      , CSPLT
      , MATKO
      , ELPRO
      , PRVBE
      , PRFG_F
      , PRDAT
      , MKSP
      , PRFG_R
      , PRFG_G
      , PRFG_S
      , UCMAT
      , PPEGUID
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM LOGIC_bom
)
---- FILTER LAYER ----

, FILTER_bom as (
    SELECT *
    FROM RENAME_bom
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_bom
)

---- FINAL LAYER ----
SELECT
          PLANT_ITEM_HK
        , MANDT
        , MATNR
        , WERKS
        , VERID
        , GLREQUEST
        , GLSOURCESYSTEM
        , BDATU
        , ADATU
        , STLAL
        , STLAN
        , PLNTY
        , PLNNR
        , ALNAL
        , BESKZ
        , SOBSL
        , LOSGR
        , MDV01
        , MDV02
        , TEXT1
        , EWAHR
        , VERTO
        , SERKZ
        , BSTMI
        , BSTMA
        , RGEKZ
        , ALORT
        , PLTYG
        , PLNNG
        , ALNAG
        , PLTYM
        , PLNNM
        , ALNAM
        , CSPLT
        , MATKO
        , ELPRO
        , PRVBE
        , PRFG_F
        , PRDAT
        , MKSP
        , PRFG_R
        , PRFG_G
        , PRFG_S
        , UCMAT
        , PPEGUID
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , HASHDIFF
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PLANT_ITEM_HK= JOIN_RESULT.PLANT_ITEM_HK  
AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}