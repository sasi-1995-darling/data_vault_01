---- SRC LAYER ----
WITH
SRC_HU             as ( SELECT * FROM {{ ref('hub_uom') }} as SRC  ),
SRC_SU             as ( SELECT * FROM {{ ref('sat_uom__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by UOM_HK order by LOAD_DTS DESC) ),
SRC_MU             as ( SELECT * FROM {{ ref('msat_uom_name__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by UOM_HK order by LOAD_DTS DESC) )

/*
SRC_HU             as ( SELECT * FROM RAW_VAULT.HUB_UOM )
, SRC_SU             as ( SELECT * FROM RAW_VAULT.SAT_UOM__WINN_SAP )
, SRC_MU             as ( SELECT * FROM RAW_VAULT.MSAT_UOM_NAME__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_HU as (
    SELECT
        CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , BKCC
      , 'PIT_UOM'                                                      as                                        PIT_REC_SRC
      , UOM_BK
      , UOM_HK
    FROM SRC_HU
)

, LOGIC_SU as (
    SELECT
        UOM_HK                                                       as                                          SU_UOM_HK
      , MSEHI                                                        as                               UNIT_OF_MEASURE_CODE
      , MANDT                                                        as                                        CLIENT_CODE
      , DECAN                                                        as                                   DISPLAY_DECIMALS
      , DIMID                                                        as                                     DIMENSION_CODE
      , ZAEHL                                                        as                               CONVERSION_NUMERATOR
      , ANDEC                                                        as                                  DECIMAL_PRECISION
      , NENNR                                                        as                             CONVERSION_DENOMINATOR
      , ADDKO                                                        as                                  ADDITIVE_CONSTANT
      , EXPON                                                        as                                    BASE10_EXPONENT
      , ISOCODE                                                      as                                      ISO_UNIT_CODE
      , GLSOURCESYSTEM                                               as                                 SOURCE_SYSTEM_NAME
      , GLCHANGETIME                                                 as                              GLUE_CHANGE_TIMESTAMP
    FROM SRC_SU
)

, LOGIC_MU as (
    SELECT
        UOM_HK                                                       as                                          MU_UOM_HK
      , SPRAS                                                        as                                      LANGUAGE_CODE
      , MSEHT                                                        as                                  SHORT_DESCRIPTION
      , MSEHL                                                        as                                   LONG_DESCRIPTION
    FROM SRC_MU
)
---- RENAME LAYER ----

, RENAME_HU as (
    SELECT
        SNAPSHOTDATE
      , PIT_LOAD_DTS
      , BKCC
      , PIT_REC_SRC
      , UOM_BK
      , UOM_HK
    FROM LOGIC_HU
)

, RENAME_SU as (
    SELECT
        SU_UOM_HK
      , UNIT_OF_MEASURE_CODE
      , CLIENT_CODE
      , DISPLAY_DECIMALS
      , DIMENSION_CODE
      , CONVERSION_NUMERATOR
      , DECIMAL_PRECISION
      , CONVERSION_DENOMINATOR
      , ADDITIVE_CONSTANT
      , BASE10_EXPONENT
      , ISO_UNIT_CODE
      , SOURCE_SYSTEM_NAME
      , GLUE_CHANGE_TIMESTAMP
    FROM LOGIC_SU
)

, RENAME_MU as (
    SELECT
        MU_UOM_HK
      , LANGUAGE_CODE
      , SHORT_DESCRIPTION
      , LONG_DESCRIPTION
    FROM LOGIC_MU
)
---- FILTER LAYER ----

, FILTER_HU as (
    SELECT *
    FROM RENAME_HU
)

, FILTER_SU as (
    SELECT *
    FROM RENAME_SU
)

, FILTER_MU as (
    SELECT *
    FROM RENAME_MU
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HU
    INNER JOIN FILTER_SU
        ON FILTER_HU.UOM_HK = FILTER_SU.SU_UOM_HK
    LEFT JOIN FILTER_MU
        ON FILTER_SU.SU_UOM_HK = FILTER_MU.MU_UOM_HK
)

---- FINAL LAYER ----
SELECT
          row_number() over(order by 1)                                as SEQ_ID
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , BKCC
        , PIT_REC_SRC
        , UOM_BK
        , UOM_HK
        , UNIT_OF_MEASURE_CODE
        , CLIENT_CODE
        , DISPLAY_DECIMALS
        , DIMENSION_CODE
        , CONVERSION_NUMERATOR
        , DECIMAL_PRECISION
        , CONVERSION_DENOMINATOR
        , ADDITIVE_CONSTANT
        , BASE10_EXPONENT
        , ISO_UNIT_CODE
        , SOURCE_SYSTEM_NAME
        , GLUE_CHANGE_TIMESTAMP
        , LANGUAGE_CODE
        , SHORT_DESCRIPTION
        , LONG_DESCRIPTION
FROM JOIN_RESULT
