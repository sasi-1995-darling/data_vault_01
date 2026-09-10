---- SRC LAYER ----
WITH
SRC_HP             as ( SELECT BKCC, 'PIT_PRODUCTION_ORDER', PRODUCTION_ORDER_BK, PRODUCTION_ORDER_HK, REC_SRC FROM {{ ref('hub_production_order') }} as SRC  ),
SRC_SP             as ( SELECT AUFLD, AUFPL, DISPO, FEVOR, FHORI, GMEIN, PAENR, PLNAL, PLNAW, PLNBEZ, PLNNR, PLNTY, PRODUCTION_ORDER_HK, PSA_DELETE_IND, PVERW, RSNUM, SAENR, STLAL, STLAN, STLNR, STLST, STLTY, TERKZ FROM {{ ref('sat_production_order__winn_sap') }} as SRC WHERE PVERW = '1'
                        qualify 1= row_number() over(partition by PRODUCTION_ORDER_HK order by LOAD_DTS DESC) )

/*
SRC_HP             as ( SELECT * FROM RAW_VAULT.HUB_PRODUCTION_ORDER )
SRC_SP             as ( SELECT * FROM RAW_VAULT.SAT_PRODUCTION_ORDER__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_HP as (
    SELECT
        CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , BKCC
      , 'PIT_PRODUCTION_ORDER'                                       as                                        PIT_REC_SRC
      , PRODUCTION_ORDER_BK
      , PRODUCTION_ORDER_HK
      , REC_SRC
    FROM SRC_HP
)

, LOGIC_SP as (
    SELECT
        PRODUCTION_ORDER_HK                                          as                             SP_PRODUCTION_ORDER_HK
      , RSNUM                                                        as                                     RESERVATION_ID
      , GMEIN                                                       as                                           BASE_UOM
      , PLNBEZ                                                       as                                           MATERIAL
      , PLNTY                                                        as                                     TASK_LIST_TYPE
      , PLNNR                                                        as                                    TASK_LIST_GROUP
      , PLNAW                                                        as                                      TASK_LIST_APP
      , PLNAL                                                        as                                      GROUP_COUNTER
      , PVERW                                                        as                                    TASK_LIST_USAGE
      , AUFLD                                                        as                             ROUTING_EXPLOSION_DATE
      , PAENR                                                        as                                PAENR_CHANGE_NUMBER
      , STLTY                                                        as                                       BOM_CATEGORY
      , STLST                                                        as                                         BOM_STATUS
      , STLNR                                                        as                                   BILL_OF_MATERIAL
      , SAENR                                                        as                                SAENR_CHANGE_NUMBER
      , STLAL                                                        as                                      ALTERNATE_BOM
      , STLAN                                                        as                                          BOM_USAGE
      , DISPO                                                        as                                     MRP_CONTROLLER
      , AUFPL                                                        as          ROUTING_NUMBER_OF_OPERATIONS_IN_THE_ORDER
      , FEVOR                                                        as                              PRODUCTION_SUPERVISOR
      , FHORI                                                        as                    SCHEDULING_MARGIN_KEY_FOR_FLOAT
      , TERKZ                                                        as                                    SCHEDULING_TYPE
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
    FROM SRC_SP
)
---- RENAME LAYER ----

, RENAME_HP as (
    SELECT
        PIT_LOAD_DTS
      , BKCC
      , PIT_REC_SRC
      , PRODUCTION_ORDER_BK
      , PRODUCTION_ORDER_HK
      , REC_SRC
    FROM LOGIC_HP
)

, RENAME_SP as (
    SELECT
        SP_PRODUCTION_ORDER_HK
      , RESERVATION_ID
      , BASE_UOM
      , MATERIAL
      , TASK_LIST_TYPE
      , TASK_LIST_GROUP
      , TASK_LIST_APP
      , GROUP_COUNTER
      , TASK_LIST_USAGE
      , ROUTING_EXPLOSION_DATE
      , PAENR_CHANGE_NUMBER
      , BOM_CATEGORY
      , BOM_STATUS
      , BILL_OF_MATERIAL
      , SAENR_CHANGE_NUMBER
      , ALTERNATE_BOM
      , BOM_USAGE
      , MRP_CONTROLLER
      , ROUTING_NUMBER_OF_OPERATIONS_IN_THE_ORDER
      , PRODUCTION_SUPERVISOR
      , SCHEDULING_MARGIN_KEY_FOR_FLOAT
      , SCHEDULING_TYPE
      , SAT_WINN_PSA_DELETE_IND
    FROM LOGIC_SP
)
---- FILTER LAYER ----

, FILTER_HP as (
    SELECT *
    FROM RENAME_HP
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'
)

, FILTER_SP as (
    SELECT *
    FROM RENAME_SP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HP
    INNER JOIN FILTER_SP
        ON FILTER_HP.PRODUCTION_ORDER_HK = FILTER_SP.SP_PRODUCTION_ORDER_HK
)

---- FINAL LAYER ----
SELECT
          row_number() over(order by 1)                                as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , PIT_LOAD_DTS
        , BKCC
        , PIT_REC_SRC
        , PRODUCTION_ORDER_BK
        , PRODUCTION_ORDER_HK
        , RESERVATION_ID
        , BASE_UOM
        , MATERIAL
        , TASK_LIST_TYPE
        , TASK_LIST_GROUP
        , TASK_LIST_APP
        , GROUP_COUNTER
        , TASK_LIST_USAGE
        , ROUTING_EXPLOSION_DATE :: INTEGER AS ROUTING_EXPLOSION_DATE__YYYYMMDD
        , PAENR_CHANGE_NUMBER
        , BOM_CATEGORY
        , BOM_STATUS
        , BILL_OF_MATERIAL
        , SAENR_CHANGE_NUMBER
        , ALTERNATE_BOM
        , BOM_USAGE
        , MRP_CONTROLLER
        , ROUTING_NUMBER_OF_OPERATIONS_IN_THE_ORDER
        , PRODUCTION_SUPERVISOR
        , SCHEDULING_MARGIN_KEY_FOR_FLOAT
        , SCHEDULING_TYPE
        , REC_SRC
        , CASE BKCC WHEN 'Hiding_Tiger' THEN SAT_WINN_PSA_DELETE_IND
    END as IS_DELETED
FROM JOIN_RESULT
