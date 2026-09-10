---- SRC LAYER ----
WITH
SRC_b              as ( SELECT CLASS, IDALT, IDFEAT, IDFEAV, IDFHM, IDMST, IDOPR, IDPHAS, IDSEQ, IDSUB, LINESIZE, LOAD_DTS, OBJALT, OBJFEAT, OBJFEAV, OBJFHM, OBJMST, OBJOPR, OBJPHAS, OBJSEQ, OBJSUB, PLNAW FROM {{ ref('v_psa_stg_task_list_applications__winn_sap') }} as SRC  )

/*
SRC_b              as ( SELECT * FROM staging.V_PSA_STG_TASK_LIST_APPLICATIONS__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        PLNAW                                                        as                                     TASK_LIST_TYPE
      , OBJSUB                                                       as                               SUB_TASK_TEXT_OBJECT
      , IDSUB                                                        as                                   SUB_TASK_TEXT_ID
      , OBJALT                                                       as                            ALTERNATIVE_TEXT_OBJECT
      , IDALT                                                        as                          ALTERNATIVE_GROUP_TEXT_ID
      , OBJSEQ                                                       as                               SEQUENCE_TEXT_OBJECT
      , IDSEQ                                                        as                                   SEQUENCE_TEXT_ID
      , OBJOPR                                                       as                              OPERATION_TEXT_OBJECT
      , IDOPR                                                        as                                  OPERATION_TEXT_ID
      , OBJFHM                                                       as               PRODUCTION_RESOURCE_TOOL_TEXT_OBJECT
      , IDFHM                                                        as                    PRODUCTON_RESOURCE_TOOL_TEXT_ID
      , CLASS                                                        as                               OBJECT_GROUPING_TYPE
      , LINESIZE                                                     as                                         LINE_WIDTH
      , OBJPHAS                                                      as                                  PHASE_TEXT_OBJECT
      , IDPHAS                                                       as                                      PHASE_TEXT_ID
      , OBJFEAT                                                      as                    PROCESS_INSTRUCTION_TEXT_OBJECT
      , IDFEAT                                                       as                        PROCESS_INSTRUCTION_TEXT_ID
      , OBJMST                                                       as                              MILESTONE_TEXT_OBJECT
      , IDMST                                                        as                                  MILESTONE_TEXT_ID
      , OBJFEAV                                                      as                      PI_CHARACTERISTIC_TEXT_OBJECT
      , IDFEAV                                                       as                          PI_CHARACTERISTIC_TEXT_ID
      , LOAD_DTS
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        TASK_LIST_TYPE
      , SUB_TASK_TEXT_OBJECT
      , SUB_TASK_TEXT_ID
      , ALTERNATIVE_TEXT_OBJECT
      , ALTERNATIVE_GROUP_TEXT_ID
      , SEQUENCE_TEXT_OBJECT
      , SEQUENCE_TEXT_ID
      , OPERATION_TEXT_OBJECT
      , OPERATION_TEXT_ID
      , PRODUCTION_RESOURCE_TOOL_TEXT_OBJECT
      , PRODUCTON_RESOURCE_TOOL_TEXT_ID
      , OBJECT_GROUPING_TYPE
      , LINE_WIDTH
      , PHASE_TEXT_OBJECT
      , PHASE_TEXT_ID
      , PROCESS_INSTRUCTION_TEXT_OBJECT
      , PROCESS_INSTRUCTION_TEXT_ID
      , MILESTONE_TEXT_OBJECT
      , MILESTONE_TEXT_ID
      , PI_CHARACTERISTIC_TEXT_OBJECT
      , PI_CHARACTERISTIC_TEXT_ID
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
          TASK_LIST_TYPE
        , SUB_TASK_TEXT_OBJECT
        , SUB_TASK_TEXT_ID
        , ALTERNATIVE_TEXT_OBJECT
        , ALTERNATIVE_GROUP_TEXT_ID
        , SEQUENCE_TEXT_OBJECT
        , SEQUENCE_TEXT_ID
        , OPERATION_TEXT_OBJECT
        , OPERATION_TEXT_ID
        , PRODUCTION_RESOURCE_TOOL_TEXT_OBJECT
        , PRODUCTON_RESOURCE_TOOL_TEXT_ID
        , OBJECT_GROUPING_TYPE
        , LINE_WIDTH
        , PHASE_TEXT_OBJECT
        , PHASE_TEXT_ID
        , PROCESS_INSTRUCTION_TEXT_OBJECT
        , PROCESS_INSTRUCTION_TEXT_ID
        , MILESTONE_TEXT_OBJECT
        , MILESTONE_TEXT_ID
        , PI_CHARACTERISTIC_TEXT_OBJECT
        , PI_CHARACTERISTIC_TEXT_ID
        , LOAD_DTS
FROM JOIN_RESULT
