---- SRC LAYER ----
WITH
SRC_uom            as ( SELECT * FROM {{ ref('v_psa_stg_uom_conversions__emtk_ebs') }} as SRC  )

/*
SRC_uom              as ( SELECT * FROM v_psa_stg_uom_conversions__emtk_ebs )
*/
---- LOGIC LAYER ----

, LOGIC_uom as (
    SELECT
        _FIVETRAN_ID
      , UNIT_OF_MEASURE
      , UOM_CODE
      , UOM_CLASS
      , INVENTORY_ITEM_ID
      , CONVERSION_RATE
      , DEFAULT_CONVERSION_FLAG
      , LAST_UPDATE_DATE
      , LAST_UPDATED_BY
      , CREATION_DATE
      , CREATED_BY
      , LAST_UPDATE_LOGIN
      , PROGRAM_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM SRC_uom
)
---- RENAME LAYER ----

, RENAME_uom as (
    SELECT
        _FIVETRAN_ID
      , UNIT_OF_MEASURE
      , UOM_CODE
      , UOM_CLASS
      , INVENTORY_ITEM_ID
      , CONVERSION_RATE
      , DEFAULT_CONVERSION_FLAG
      , LAST_UPDATE_DATE
      , LAST_UPDATED_BY
      , CREATION_DATE
      , CREATED_BY
      , LAST_UPDATE_LOGIN
      , PROGRAM_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_uom
)
---- FILTER LAYER ----

, FILTER_uom as (
    SELECT *
    FROM RENAME_uom
)
---- JOIN LAYER ----

, JOIN_RESULT as (
    SELECT *
    FROM FILTER_uom
)
---- FINAL LAYER ----

SELECT
          _FIVETRAN_ID
        , UNIT_OF_MEASURE
        , UOM_CODE
        , UOM_CLASS
        , INVENTORY_ITEM_ID
        , CONVERSION_RATE
        , DEFAULT_CONVERSION_FLAG
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , CREATION_DATE
        , CREATED_BY
        , LAST_UPDATE_LOGIN
        , PROGRAM_UPDATE_DATE
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
FROM JOIN_RESULT