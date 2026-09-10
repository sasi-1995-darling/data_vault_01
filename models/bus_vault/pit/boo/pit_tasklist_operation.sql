---- SRC LAYER ----
WITH
SRC_HT             as ( SELECT BKCC, REC_SRC, TASKLIST_OPERATION_BK, TASKLIST_OPERATION_HK FROM {{ ref('hub_tasklist_operation') }} as SRC  ),
SRC_MT             as ( SELECT AENNR, BMSCH, DATUV, LAR01, LOEKZ, PLNKN, PLNNR, PLNTY, PSA_DELETE_IND, STEUS, TASKLIST_OPERATION_HK, VGW01, VGW02, VORNR, 
                               LTXA1, VPLTY, VPLNR, VPLAL 
                        FROM {{ ref('sat_tasklist_operation__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by TASKLIST_OPERATION_HK order by LOAD_DTS DESC) )

---- LOGIC LAYER ----

, LOGIC_HT as (
    SELECT
        CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                     PIT_LOAD_DTS
      , BKCC
      , 'PIT_TASKLIST_OPERATION'                                       as                                      PIT_REC_SRC
      , REC_SRC
      , TASKLIST_OPERATION_BK
      , TASKLIST_OPERATION_HK
    FROM SRC_HT
)

, LOGIC_MT as (
    SELECT
        TASKLIST_OPERATION_HK                                        as                          MT_TASKLIST_OPERATION_HK
      , PLNTY                                                        as                                     TASKLIST_TYPE
      , PLNNR                                                        as                                TASKLIST_GROUP_KEY
      , PLNKN                                                        as                          INTERNAL_OPERATION_NUMBER
      , VORNR                                                        as                                   OPERATION_NUMBER
      , LTXA1                                                        as                              OPERATION_DESCRIPTION -- Added
      , STEUS                                                        as                                        CONTROL_KEY
      , LOEKZ                                                        as                                 DELETION_INDICATOR
      , VGW01                                                        as                                         SETUP_TIME
      , VGW02                                                        as                                     STANDARD_VALUE
      , BMSCH                                                        as                                      BASE_QUANTITY
      , LAR01                                                        as                                      ACTIVITY_TYPE
      , DATUV::INTEGER                                                       as                         VALID_FROM_DATE__YYYYMMDD
      , AENNR                                                        as                                     CHANGE_NUMBER
      , VPLTY                                                        as                                 REF_TASKLIST_TYPE -- Added
      , VPLNR                                                        as                                REF_TASKLIST_GROUP -- Added
      , VPLAL                                                        as                                 REF_GROUP_COUNTER -- Added
      , PSA_DELETE_IND                                               as                           SAT_WINN_PSA_DELETE_IND
    FROM SRC_MT
)
---- RENAME LAYER ----

, RENAME_HT as (
    SELECT
        PIT_LOAD_DTS
      , BKCC
      , PIT_REC_SRC
      , REC_SRC
      , TASKLIST_OPERATION_BK
      , TASKLIST_OPERATION_HK
    FROM LOGIC_HT
)

, RENAME_MT as (
    SELECT
        MT_TASKLIST_OPERATION_HK
      , TASKLIST_TYPE
      , TASKLIST_GROUP_KEY
      , INTERNAL_OPERATION_NUMBER
      , OPERATION_NUMBER
      , OPERATION_DESCRIPTION 
      , CONTROL_KEY
      , DELETION_INDICATOR
      , SETUP_TIME
      , STANDARD_VALUE
      , BASE_QUANTITY
      , ACTIVITY_TYPE
      , VALID_FROM_DATE__YYYYMMDD
      , CHANGE_NUMBER
      , REF_TASKLIST_TYPE 
      , REF_TASKLIST_GROUP 
      , REF_GROUP_COUNTER
      , SAT_WINN_PSA_DELETE_IND
    FROM LOGIC_MT
)
---- FILTER LAYER ----

, FILTER_HT as (
    SELECT *
    FROM RENAME_HT
)

, FILTER_MT as (
    SELECT *
    FROM RENAME_MT
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HT
    INNER JOIN FILTER_MT
        ON FILTER_HT.TASKLIST_OPERATION_HK = MT_TASKLIST_OPERATION_HK
)

---- FINAL LAYER ----
SELECT
          row_number() over(order by 1)                                as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , PIT_LOAD_DTS
        , BKCC
        , PIT_REC_SRC
        , REC_SRC
        , TASKLIST_OPERATION_BK
        , TASKLIST_OPERATION_HK
        , TASKLIST_TYPE
        , TASKLIST_GROUP_KEY
        , INTERNAL_OPERATION_NUMBER
        , OPERATION_NUMBER
        , OPERATION_DESCRIPTION 
        , CONTROL_KEY
        , DELETION_INDICATOR
        , SETUP_TIME
        , STANDARD_VALUE
        , BASE_QUANTITY
        , ACTIVITY_TYPE
        , VALID_FROM_DATE__YYYYMMDD
        , CHANGE_NUMBER
        , REF_TASKLIST_TYPE 
        , REF_TASKLIST_GROUP 
        , REF_GROUP_COUNTER 
        , SAT_WINN_PSA_DELETE_IND
FROM JOIN_RESULT