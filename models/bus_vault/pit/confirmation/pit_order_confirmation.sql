---- SRC LAYER ----
WITH
SRC_HC             as ( SELECT BKCC, CONFIRMATION_NUMBER_BK, CONFIRMATION_COUNTER_BK, ORDER_CONFIRMATION_HK, REC_SRC FROM {{ ref('hub_order_confirmation') }} as SRC  ),
SRC_SC             as ( SELECT APLFL, APLZL, ARBID, AUERU, AUFNR, AUFPL, BUDAT, KAPID, LEARR, LMNGA, LTXA1, MYEAR, ORDER_CONFIRMATION_HK, PSA_DELETE_IND, RMZHL, SATZA, SUMNR, VORNR, WABLNR, WEBLNR, WERKS, XMNGA, ISDD, ISDZ, IEDD, IEDZ FROM {{ ref('sat_order_confirmation__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by ORDER_CONFIRMATION_HK order by LOAD_DTS DESC) )

/*
SRC_HC             as ( SELECT * FROM RAW_VAULT.HUB_ORDER_CONFIRMATION )
SRC_SC             as ( SELECT * FROM RAW_VAULT.SAT_ORDER_CONFIRMATION__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_HC as (
    SELECT
        BKCC
      , CONFIRMATION_NUMBER_BK
      , CONFIRMATION_COUNTER_BK
      , ORDER_CONFIRMATION_HK
      , REC_SRC
    FROM SRC_HC
)

, LOGIC_SC as (
    SELECT
        ORDER_CONFIRMATION_HK                                        as                           SC_ORDER_CONFIRMATION_HK
      , RMZHL                                                        as                               CONFIRMATION_COUNTER
      , AUFNR                                                        as                            PRODUCTION_ORDER_NUMBER
      , ARBID                                                        as                             CONFIRMATION_OBJECT_ID
      , KAPID                                                        as                                        CAPACITY_ID
      , BUDAT                                                        as                                       POSTING_DATE
      , WERKS                                                        as                                              PLANT
      , LMNGA                                                        as                              YIELD_TO_BE_CONFIRMED
      , XMNGA                                                        as                              SCRAP_TO_BE_CONFIRMED
      , LTXA1                                                        as                                  CONFIRMATION_TEXT
      , LEARR                                                        as                                      ACTIVITY_TYPE
      , WABLNR                                                       as                           MATERIAL_DOCUMENT_NUMBER
      , WEBLNR                                                       as                            MATERIAL_DOCUMENT_ERROR
      , MYEAR                                                        as                             MATERIAL_DOCUMENT_YEAR
      , AUERU                                                        as                         PARTIAL_FINAL_CONFIRMATION
      , AUFPL                                                        as                                     ROUTING_NUMBER
      , APLZL                                                        as                                    GENERAL_COUNTER
      , APLFL                                                        as                                    SEQUENCE_NUMBER
      , VORNR                                                        as                          OPERATION_ACTIVITY_NUMBER
      , SUMNR                                                        as                            NODE_OF_SUPER_OPERATION
      , SATZA                                                        as                       RECORD_TYPE_FOR_CONFIRMATION
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
      , ISDD as CONFIRMED_START_DATE_OF_EXECUTION
      , NULLIF(TRIM(ISDZ), '') as CONFIRMED_START_TIME_OF_EXECUTION
      , IEDD as CONFIRMED_FINISH_DATE_OF_EXECUTION
      , NULLIF(TRIM(IEDZ), '') as CONFIRMED_FINISH_TIME_OF_EXECUTION   
    FROM SRC_SC
)
---- RENAME LAYER ----

, RENAME_HC as (
    SELECT
        BKCC
      , CONFIRMATION_NUMBER_BK
      , CONFIRMATION_COUNTER_BK
      , ORDER_CONFIRMATION_HK
      , REC_SRC
    FROM LOGIC_HC
)

, RENAME_SC as (
    SELECT
        SC_ORDER_CONFIRMATION_HK
      , CONFIRMATION_COUNTER
      , PRODUCTION_ORDER_NUMBER
      , CONFIRMATION_OBJECT_ID
      , CAPACITY_ID
      , POSTING_DATE
      , PLANT
      , YIELD_TO_BE_CONFIRMED
      , SCRAP_TO_BE_CONFIRMED
      , CONFIRMATION_TEXT
      , ACTIVITY_TYPE
      , MATERIAL_DOCUMENT_NUMBER
      , MATERIAL_DOCUMENT_ERROR
      , MATERIAL_DOCUMENT_YEAR
      , PARTIAL_FINAL_CONFIRMATION
      , ROUTING_NUMBER
      , GENERAL_COUNTER
      , SEQUENCE_NUMBER
      , OPERATION_ACTIVITY_NUMBER
      , NODE_OF_SUPER_OPERATION
      , RECORD_TYPE_FOR_CONFIRMATION
      , SAT_WINN_PSA_DELETE_IND
      , CONFIRMED_START_DATE_OF_EXECUTION
      , CONFIRMED_START_TIME_OF_EXECUTION
      , CONFIRMED_FINISH_DATE_OF_EXECUTION
      , CONFIRMED_FINISH_TIME_OF_EXECUTION
    FROM LOGIC_SC
)
---- FILTER LAYER ----

, FILTER_HC as (
    SELECT *
    FROM RENAME_HC
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'
)

, FILTER_SC as (
    SELECT *
    FROM RENAME_SC
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HC
    INNER JOIN FILTER_SC
        ON FILTER_HC.ORDER_CONFIRMATION_HK = FILTER_SC.SC_ORDER_CONFIRMATION_HK
)

---- FINAL LAYER ----
SELECT
          row_number() over(order by 1)                                as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
        , BKCC
        ,'PIT_ORDER_CONFIRMATION'                                     as                                        PIT_REC_SRC
        , CONFIRMATION_NUMBER_BK
        , CONFIRMATION_COUNTER_BK
        , ORDER_CONFIRMATION_HK
        , REC_SRC
        , CONFIRMATION_COUNTER
        , PRODUCTION_ORDER_NUMBER
        , CONFIRMATION_OBJECT_ID
        , CAPACITY_ID
        , POSTING_DATE::INTEGER AS POSTING_DATE__YYYYMMDD
        , CONFIRMED_START_DATE_OF_EXECUTION::INTEGER as CONFIRMED_START_DATE_OF_EXECUTION__YYYYMMDD
        , CONFIRMED_START_TIME_OF_EXECUTION::INTEGER as CONFIRMED_START_TIME_OF_EXECUTION__HHMMSS
        , CONFIRMED_FINISH_DATE_OF_EXECUTION::INTEGER as CONFIRMED_FINISH_DATE_OF_EXECUTION__YYYYMMDD
        , CONFIRMED_FINISH_TIME_OF_EXECUTION::INTEGER as CONFIRMED_FINISH_TIME_OF_EXECUTION__HHMMSS
        , PLANT
        , YIELD_TO_BE_CONFIRMED
        , SCRAP_TO_BE_CONFIRMED
        , CONFIRMATION_TEXT
        , ACTIVITY_TYPE
        , MATERIAL_DOCUMENT_NUMBER
        , MATERIAL_DOCUMENT_ERROR
        , MATERIAL_DOCUMENT_YEAR
        , PARTIAL_FINAL_CONFIRMATION
        , ROUTING_NUMBER
        , GENERAL_COUNTER
        , SEQUENCE_NUMBER
        , OPERATION_ACTIVITY_NUMBER
        , NODE_OF_SUPER_OPERATION
        , RECORD_TYPE_FOR_CONFIRMATION
        , CASE  WHEN BKCC = 'Hiding_Tiger' THEN SAT_WINN_PSA_DELETE_IND
           END as IS_DELETED
FROM JOIN_RESULT

