---- SRC LAYER ----
WITH
SRC_b              as ( SELECT * FROM {{ ref('v_psa_stg_planned_order_type__winn_sap') }} as SRC  
                        qualify 1= row_number() over(partition by  DOMVALUE_L order by LOAD_DTS desc))
/*
SRC_b              as ( SELECT * FROM staging.V_PSA_STG_PLANNED_ORDER_TYPE__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        DOMVALUE_L                                                   as                            PLANNED_ORDER_TYPE_CODE -- Planed Order Type code
      , DDLANGUAGE                                                   as                                       LANGUAGE_KEY
      , DDTEXT                                                       as                                 PLANNED_ORDER_TEXT -- Holds Descriptive Text For Planned Order Type
      , LOAD_DTS
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        PLANNED_ORDER_TYPE_CODE
      , LANGUAGE_KEY
      , PLANNED_ORDER_TEXT
      , LOAD_DTS
    FROM LOGIC_b
)
---- FILTER LAYER ----

, FILTER_b as (
    SELECT *
    FROM RENAME_b
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_b
)

---- FINAL LAYER ----
SELECT
          PLANNED_ORDER_TYPE_CODE
        , LANGUAGE_KEY
        , PLANNED_ORDER_TEXT
        , LOAD_DTS
FROM JOIN_RESULT
