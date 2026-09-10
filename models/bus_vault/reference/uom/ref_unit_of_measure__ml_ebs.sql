---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ ref('v_psa_stg_unit_of_measure__ml_ebs') }} as SRC )

/*
SRC_SRC            as ( SELECT * FROM int_staging_views.uom.v_psa_stg_unit_of_measure__ml_ebs )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        UOM_CODE
      , UNIT_OF_MEASURE
      , UOM_CLASS
      , BASE_UOM_FLAG
      , DESCRIPTION
      , UNIT_OF_MEASURE_TL
      , LANGUAGE
      , SOURCE_LANG
      , CREATED_BY
      , CREATION_DATE
      , LAST_UPDATED_BY
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
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
        , DESCRIPTION
        , UNIT_OF_MEASURE_TL
        , LANGUAGE
        , SOURCE_LANG
        , CREATED_BY
        , CREATION_DATE
        , LAST_UPDATED_BY
        , LAST_UPDATE_DATE
        , LAST_UPDATE_LOGIN
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
FROM JOIN_RESULT
