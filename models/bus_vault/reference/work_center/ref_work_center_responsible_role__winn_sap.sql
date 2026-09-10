---- SRC LAYER ----
WITH
SRC_b              as ( SELECT KTEXT, LOAD_DTS, MANDT, VERAN, WERKS FROM {{ ref('v_psa_stg_work_center_responsible_role__winn_sap') }} as SRC  )

/*
SRC_b              as ( SELECT * FROM staging.V_PSA_STG_WORK_CENTER_RESPONSIBLE_ROLE__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        MANDT                                                        as                                             CLIENT
      , VERAN                                                        as                            RESPONSIBLE_ROLE_PERSON
      , KTEXT                                                        as                              RESPONSIBLE_ROLE_TEXT
      , WERKS                                                        as                              PLANT
      , LOAD_DTS
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        CLIENT
      , RESPONSIBLE_ROLE_PERSON
      , RESPONSIBLE_ROLE_TEXT
      , PLANT
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
          CLIENT
        , RESPONSIBLE_ROLE_PERSON
        , RESPONSIBLE_ROLE_TEXT
        , PLANT
        , LOAD_DTS
FROM JOIN_RESULT
