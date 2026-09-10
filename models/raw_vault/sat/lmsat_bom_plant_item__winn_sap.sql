---- SRC LAYER ----
WITH
SRC_bom            as ( SELECT * FROM {{ ref('v_psa_stg_bom_plant_item__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_bom            as ( SELECT * FROM STAGING.V_PSA_STG_BOM_PLANT_ITEM__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_bom as (
    SELECT
        LNK_BOM_PLANT_ITEM_HK
      , MANDT
      , MATNR
      , WERKS
      , STLAN
      , STLNR
      , STLAL
      , GLREQUEST
      , LOSVN
      , LOSBS
      , ANDAT
      , ANNAM
      , AEDAT
      , AENAM
      , CSLTY
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
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
        LNK_BOM_PLANT_ITEM_HK
      , MANDT
      , MATNR
      , WERKS
      , STLAN
      , STLNR
      , STLAL
      , GLREQUEST
      , LOSVN
      , LOSBS
      , ANDAT
      , ANNAM
      , AEDAT
      , AENAM
      , CSLTY
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
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
          LNK_BOM_PLANT_ITEM_HK
        , MANDT
        , MATNR
        , WERKS
        , STLAN
        , STLNR
        , STLAL
        , GLREQUEST
        , LOSVN
        , LOSBS
        , ANDAT
        , ANNAM
        , AEDAT
        , AENAM
        , CSLTY
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
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
    WHERE existing.LNK_BOM_PLANT_ITEM_HK = JOIN_RESULT.LNK_BOM_PLANT_ITEM_HK  
AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}