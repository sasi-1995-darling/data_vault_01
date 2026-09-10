---- SRC LAYER ----
WITH
SRC_gp             as ( SELECT LOAD_DTS, LTEXT, SPRAS, VGART FROM {{ ref('v_psa_stg_goods_movement_event_type_text__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by VGART, SPRAS order by LOAD_DTS desc) )

/*
SRC_gp             as ( SELECT * FROM staging.v_psa_stg_goods_movement_event_type_text__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_gp as (
    SELECT
        SPRAS                                                        as                                       LANGUAGE_KEY
      , VGART                                                        as                           MOVEMENT_EVENT_TYPE_CODE
      , LTEXT                                                        as                           MOVEMENT_EVENT_TYPE_TEXT
      , LOAD_DTS
    FROM SRC_gp
)
---- RENAME LAYER ----

, RENAME_gp as (
    SELECT
        LANGUAGE_KEY
      , MOVEMENT_EVENT_TYPE_CODE
      , MOVEMENT_EVENT_TYPE_TEXT
      , LOAD_DTS
    FROM LOGIC_gp
)
---- FILTER LAYER ----

, FILTER_gp as (
    SELECT *
    FROM RENAME_gp
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_gp
)

---- FINAL LAYER ----
SELECT
          LANGUAGE_KEY
        , MOVEMENT_EVENT_TYPE_CODE
        , MOVEMENT_EVENT_TYPE_TEXT
        , LOAD_DTS
FROM JOIN_RESULT
