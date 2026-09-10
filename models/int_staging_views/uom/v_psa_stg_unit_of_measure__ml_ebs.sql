---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('ml_ebs_inv', 'mtl_units_of_measure_tl') }} as SRC  )
/*
SRC_SRC            as ( SELECT * FROM ml_ebs_inv.mtl_units_of_measure_tl )

*/
---- LOGIC LAYER ----
, LOGIC_SRC as (
    SELECT
        UOM_CODE
      , UNIT_OF_MEASURE
      , UOM_CLASS
      , BASE_UOM_FLAG
      , LAST_UPDATE_DATE
      , LAST_UPDATED_BY
      , CREATION_DATE
      , CREATED_BY
      , LAST_UPDATE_LOGIN
      , DISABLE_DATE
      , DESCRIPTION
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE1
      , ATTRIBUTE2
      , ATTRIBUTE3
      , ATTRIBUTE4
      , ATTRIBUTE5
      , ATTRIBUTE6
      , ATTRIBUTE7
      , ATTRIBUTE8
      , ATTRIBUTE9
      , ATTRIBUTE10
      , ATTRIBUTE11
      , ATTRIBUTE12
      , ATTRIBUTE13
      , ATTRIBUTE14
      , ATTRIBUTE15
      , REQUEST_ID
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , UNIT_OF_MEASURE_TL
      , LANGUAGE
      , SOURCE_LANG
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_SRC
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
)

---- FINAL LAYER ----
    SELECT
          UOM_CODE
        , UNIT_OF_MEASURE
        , UOM_CLASS
        , BASE_UOM_FLAG
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , CREATION_DATE
        , CREATED_BY
        , LAST_UPDATE_LOGIN
        , DISABLE_DATE
        , DESCRIPTION
        , ATTRIBUTE_CATEGORY
        , ATTRIBUTE1
        , ATTRIBUTE2
        , ATTRIBUTE3
        , ATTRIBUTE4
        , ATTRIBUTE5
        , ATTRIBUTE6
        , ATTRIBUTE7
        , ATTRIBUTE8
        , ATTRIBUTE9
        , ATTRIBUTE10
        , ATTRIBUTE11
        , ATTRIBUTE12
        , ATTRIBUTE13
        , ATTRIBUTE14
        , ATTRIBUTE15
        , REQUEST_ID
        , PROGRAM_APPLICATION_ID
        , PROGRAM_ID
        , PROGRAM_UPDATE_DATE
        , UNIT_OF_MEASURE_TL
        , LANGUAGE
        , SOURCE_LANG
        , _FIVETRAN_ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS   
FROM JOIN_RESULT
