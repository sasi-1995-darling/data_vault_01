---- SRC LAYER ----
WITH
SRC_b              as ( SELECT FEVOR, LOAD_DTS, PLANT_BK, SFCPF, TXT FROM {{ ref('v_psa_stg_production_supervisor__winn_sap') }} as SRC  )

/*
SRC_b              as ( SELECT * FROM staging.V_PSA_STG_PRODUCTION_SUPERVISOR__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        PLANT_BK
      , FEVOR                                                        as                              PRODUCTION_SUPERVISOR
      , TXT                                                          as                         PRODUCTION_SUPERVISOR_TEXT
      , SFCPF                                                        as                       PRODUCTON_SCHEDULING_PROFILE
      , LOAD_DTS
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        PLANT_BK
      , PRODUCTION_SUPERVISOR
      , PRODUCTION_SUPERVISOR_TEXT
      , PRODUCTON_SCHEDULING_PROFILE
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
          PLANT_BK
        , PRODUCTION_SUPERVISOR
        , PRODUCTION_SUPERVISOR_TEXT
        , PRODUCTON_SCHEDULING_PROFILE
        , LOAD_DTS
FROM JOIN_RESULT