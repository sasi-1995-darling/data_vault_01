---- SRC LAYER ----
WITH
SRC_b              as ( SELECT DISPO, DSNAM, DSTEL, EKGRP, ERNAM, GSBER, LOAD_DTS, MEMPF, PLANT_BK, PRCTR, USRKEY, USRTYP, ZZMSNAM FROM {{ ref('v_psa_stg_mrp_controller__winn_sap') }} as SRC  )

/*
SRC_b              as ( SELECT * FROM staging.V_PSA_STG_MRP_CONTROLLER__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        PLANT_BK
      , DISPO                                                        as                                  MRP_CONTROLLER_ID
      , DSNAM                                                        as                                MRP_CONTROLLER_NAME
      , DSTEL                                                        as                    MRP_CONTROLLER_TELEPHONE_NUMBER
      , EKGRP                                                        as                                PURCHASING_GROUP_ID
      , MEMPF                                                        as                                     RECIPIENT_NAME
      , GSBER                                                        as                                      BUSINESS_AREA
      , PRCTR                                                        as                                      PROFIT_CENTER
      , USRTYP                                                       as                                     RECIPIENT_TYPE
      , USRKEY                                                       as                                RECIPIENT_OBJECT_ID
      , ERNAM                                                        as                                    CREATED_BY_USER
      , ZZMSNAM                                                      as                        MICROSOFT_OUTLOOK_USER_NAME
      , LOAD_DTS
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        PLANT_BK
      , MRP_CONTROLLER_ID
      , MRP_CONTROLLER_NAME
      , MRP_CONTROLLER_TELEPHONE_NUMBER
      , PURCHASING_GROUP_ID
      , RECIPIENT_NAME
      , BUSINESS_AREA
      , PROFIT_CENTER
      , RECIPIENT_TYPE
      , RECIPIENT_OBJECT_ID
      , CREATED_BY_USER
      , MICROSOFT_OUTLOOK_USER_NAME
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
        , MRP_CONTROLLER_ID
        , MRP_CONTROLLER_NAME
        , MRP_CONTROLLER_TELEPHONE_NUMBER
        , PURCHASING_GROUP_ID
        , RECIPIENT_NAME
        , BUSINESS_AREA
        , PROFIT_CENTER
        , RECIPIENT_TYPE
        , RECIPIENT_OBJECT_ID
        , CREATED_BY_USER
        , MICROSOFT_OUTLOOK_USER_NAME
        , LOAD_DTS
FROM JOIN_RESULT