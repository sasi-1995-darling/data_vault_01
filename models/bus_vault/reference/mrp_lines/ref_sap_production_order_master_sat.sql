---- SRC LAYER ----
WITH
SRC_b              as ( SELECT * FROM {{ ref('v_psa_stg_production_order_master__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_b              as ( SELECT * FROM STAGING.V_PSA_STG_PRODUCTION_ORDER_MASTER__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        PRODUCTION_ORDER_BK
      , MANDT                                                        as                                             CLIENT
      , AUFNR                                                        as                                       ORDER_NUMBER
      , AUART                                                        as                                         ORDER_TYPE
      , AUTYP                                                        as                                     ORDER_CATEGORY
      , REFNR                                                        as                             REFERENCE_ORDER_NUMBER
      , ERNAM                                                        as                                         ENTERED_BY
      , ERDAT                                                        as                                         CREATED_ON
      , AENAM                                                        as                                    LAST_CHANGED_BY
      , AEDAT                                                        as                       CHANGE_DATE_FOR_ORDER_MASTER
      , KTEXT                                                        as                                        DESCRIPTION
      , LTEXT                                                        as                                   LONG_TEXT_EXISTS
      , BUKRS                                                        as                                       COMPANY_CODE
      , WERKS                                                        as                                              PLANT
      , GSBER                                                        as                                      BUSINESS_AREA
      , KOKRS                                                        as                                   CONTROLLING_AREA
      , CCKEY                                                        as                                 COST_COLLECTOR_KEY
      , KOSTV                                                        as                            RESPONSIBLE_COST_CENTER
      , STORT                                                        as                                           LOCATION
      , SOWRK                                                        as                                     LOCATION_PLANT
      , ASTKZ                                                        as                   IDENTIFIER_FOR_STATISTICAL_ORDER
      , WAERS                                                        as                                     ORDER_CURRENCY
      , ASTNR                                                        as                                       ORDER_STATUS
      , STDAT                                                        as                         DATE_OF_LAST_STATUS_CHANGE
      , ESTNR                                                        as                              STATUS_REACHED_SO_FAR
      , PHAS0                                                        as                                PHASE_ORDER_CREATED
      , PHAS1                                                        as                               PHASE_ORDER_RELEASED
      , PHAS2                                                        as                              PHASE_ORDER_COMPLETED
      , PHAS3                                                        as                                 PHASE_ORDER_CLOSED
      , PDAT1                                                        as                               PLANNED_RELEASE_DATE
      , PDAT2                                                        as                            PLANNED_COMPLETION_DATE
      , PDAT3                                                        as                               PLANNED_CLOSING_DATE
      , IDAT1                                                        as                                       RELEASE_DATE
      , IDAT2                                                        as                          TECHNICAL_COMPLETION_DATE
      , IDAT3                                                        as                                         CLOSE_DATE
      , OBJID                                                        as                                          OBJECT_ID
      , VOGRP                                                        as                   GROUP_OF_DISALLOWED_TRANSACTIONS
      , LOEKZ                                                        as                                      DELETION_FLAG
      , PLGKZ                                                        as            IDENTIFIER_FOR_PLANNING_WITH_LINE_ITEMS
      , KVEWE                                                        as                       USAGE_OF_THE_CONDITION_TABLE
      , KAPPL                                                        as                                        APPLICATION
      , KALSM                                                        as                                      COSTING_SHEET
      , ZSCHL                                                        as                                       OVERHEAD_KEY
      , ABKRS                                                        as                                   PROCESSING_GROUP
      , KSTAR                                                        as                            SETTLEMENT_COST_ELEMENT
      , KOSTL                                                        as                   COST_CENTER_FOR_BASIC_SETTLEMENT
      , SAKNR                                                        as                   GL_ACCOUNT_FOR_BASIC_SETTLEMENT
      , SETNM                                                        as                                     ALLOCATION_SET
      , CYCLE                                                        as     COST_CENTER_TO_WHICH_COSTS_ARE_ACTUALLY_POSTED
      , SDATE                                                        as                                         START_DATE
      , SEQNR                                                        as                                    SEQUENCE_NUMBER
      , USER0                                                        as                                          APPLICANT
      , USER1                                                        as                         APPLICANT_TELEPHONE_NUMBER
      , USER2                                                        as                                 PERSON_RESPONSIBLE
      , USER3                                                        as               TELEPHONE_NUMBER_OF_PERSON_IN_CHARGE
      , USER4                                                        as                     ESTIMATED_TOTAL_COSTS_OF_ORDER
      , USER5                                                        as                                   APPLICATION_DATE
      , USER6                                                        as                                         DEPARTMENT
      , USER7                                                        as                                         WORK_START
      , USER8                                                        as                                        END_OF_WORK
      , USER9                                                        as                  IDENTIFIER_FOR_WORK_PERMIT_ISSUED
      , OBJNR                                                        as                                      OBJECT_NUMBER
      , PRCTR                                                        as                                      PROFIT_CENTER
      , PSPEL                                                        as                   WORK_BREAKDOWN_STRUCTURE_ELEMENT
      , AWSLS                                                        as                                       VARIANCE_KEY
      , ABGSL                                                        as                               RESULTS_ANALYSIS_KEY
      , TXJCD                                                        as                                   TAX_JURISDICTION
      , FUNC_AREA                                                    as                                    FUNCTIONAL_AREA
      , SCOPE                                                        as                                       OBJECT_CLASS
      , PLINT                                                        as                  INDICATOR_FOR_INTEGRATED_PLANNING
      , KDAUF                                                        as                                 SALES_ORDER_NUMBER
      , KDPOS                                                        as                         ITEM_NUMBER_IN_SALES_ORDER
      , AUFEX                                                        as                              EXTERNAL_ORDER_NUMBER
      , IVPRO                                                        as                         INVESTMENT_MEASURE_PROFILE
      , LOGSYSTEM                                                    as                                     LOGICAL_SYSTEM
      , FLG_MLTPS                                                    as                          ORDER_WITH_MULTIPLE_ITEMS
      , ABUKR                                                        as                            REQUESTING_COMPANY_CODE
      , AKSTL                                                        as                             REQUESTING_COST_CENTER
      , SIZECL                                                       as                        SCALE_OF_INVESTMENT_OBJECTS
      , IZWEK                                                        as                              REASON_FOR_INVESTMENT
      , UMWKZ                                                        as                REASON_FOR_ENVIRONMENTAL_INVESTMENT
      , KSTEMPF                                                      as                    INDICATOR_DIRECT_COST_COLLECTOR
      , ZSCHM                                                        as                         INTEREST_PROFILE_FOR_ORDER
      , PKOSA                                                        as              COST_COLLECTOR_FOR_PRODUCTION_PROCESS
      , ANFAUFNR                                                     as                                   REQUESTING_ORDER
      , PROCNR                                                       as                                 PRODUCTION_PROCESS
      , PROTY                                                        as                                   PROCESS_CATEGORY
      , RSORD                                                        as                      REFURBISHMENT_ORDER_INDICATOR
      , BEMOT                                                        as                               ACCOUNTING_INDICATOR
      , ADRNRA                                                       as                                     ADDRESS_NUMBER
      , ERFZEIT                                                      as                                       TIME_CREATED
      , AEZEIT                                                       as                                         CHANGED_AT
      , CSTG_VRNT                                                    as                                    COSTING_VARIANT
      , COSTESTNR                                                    as                               COST_ESTIMATE_NUMBER
      , VERAA_USER                                                   as           PERSON_RESPONSIBLE_FOR_CO_INTERNAL_ORDER
      , ZZ_FUND_TYPE                                                 as          FUND_TYPE
      , ZZ_USE_COST                                                  as   USE_COST_FOR_SHOWROOM_FUNDS
      , ZZ_O8_REF                                                    as  O8_REFERENCE_FIELD
      , ZZ_O8_COLOR                                                  as O8_DDMRP_COLOR_CODE
      , ZZ_O8_BUFFER                                                 as O8_BUFFER_PENETRATION_LEVEL
      , VNAME                                                        as                                      JOINT_VENTURE
      , RECID                                                        as                                 RECOVERY_INDICATOR
      , ETYPE                                                        as                                        EQUITY_TYPE
      , OTYPE                                                        as                          JOINT_VENTURE_OBJECT_TYPE
      , JV_JIBCL                                                     as                                     JIB_JIBE_CLASS
      , JV_JIBSA                                                     as                                JIB_JIBE_SUBCLASS_A
      , JV_OCO                                                       as                            JV_ORIGINAL_COST_OBJECT
      , "/CUM/INDCU"                                                  as              CU_ORDER_IS_USED_FOR_COMPATIBLE_UNITS
      , "/CUM/CMNUM"                                                   as                     CU_CONSTRUCTION_MEASURE_NUMBER
      , "/CUM/AUEST"                                                   as               CU_AUTOMATIC_COPY_OF_ESTIMATED_COSTS
      , "/CUM/DESNUM"                                                  as                                   CU_DESIGN_NUMBER
      , VAPLZ                                                        as             MAIN_WORK_CENTER_FOR_MAINTENANCE_TASKS
      , WAWRK                                                        as             PLANT_ASSOCIATED_WITH_MAIN_WORK_CENTER
      , FERC_IND                                                     as                               REGULATORY_INDICATOR
      , CLAIM_CONTROL                                                as                   CLAIM_CREATION_CONTROL_INDICATOR
      , UPDATE_NEEDED                                                as           CLAIM_INCONSISTENCY_WITH_ORDER_INDICATOR
      , UPDATE_CONTROL                                               as      CLAIM_UPDATE_TRIGGER_POINT_FROM_SERVICE_ORDER
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        PRODUCTION_ORDER_BK
      , CLIENT
      , ORDER_NUMBER
      , ORDER_TYPE
      , ORDER_CATEGORY
      , REFERENCE_ORDER_NUMBER
      , ENTERED_BY
      , CREATED_ON
      , LAST_CHANGED_BY
      , CHANGE_DATE_FOR_ORDER_MASTER
      , DESCRIPTION
      , LONG_TEXT_EXISTS
      , COMPANY_CODE
      , PLANT
      , BUSINESS_AREA
      , CONTROLLING_AREA
      , COST_COLLECTOR_KEY
      , RESPONSIBLE_COST_CENTER
      , LOCATION
      , LOCATION_PLANT
      , IDENTIFIER_FOR_STATISTICAL_ORDER
      , ORDER_CURRENCY
      , ORDER_STATUS
      , DATE_OF_LAST_STATUS_CHANGE
      , STATUS_REACHED_SO_FAR
      , PHASE_ORDER_CREATED
      , PHASE_ORDER_RELEASED
      , PHASE_ORDER_COMPLETED
      , PHASE_ORDER_CLOSED
      , PLANNED_RELEASE_DATE
      , PLANNED_COMPLETION_DATE
      , PLANNED_CLOSING_DATE
      , RELEASE_DATE
      , TECHNICAL_COMPLETION_DATE
      , CLOSE_DATE
      , OBJECT_ID
      , GROUP_OF_DISALLOWED_TRANSACTIONS
      , DELETION_FLAG
      , IDENTIFIER_FOR_PLANNING_WITH_LINE_ITEMS
      , USAGE_OF_THE_CONDITION_TABLE
      , APPLICATION
      , COSTING_SHEET
      , OVERHEAD_KEY
      , PROCESSING_GROUP
      , SETTLEMENT_COST_ELEMENT
      , COST_CENTER_FOR_BASIC_SETTLEMENT
      , GL_ACCOUNT_FOR_BASIC_SETTLEMENT
      , ALLOCATION_SET
      , COST_CENTER_TO_WHICH_COSTS_ARE_ACTUALLY_POSTED
      , START_DATE
      , SEQUENCE_NUMBER
      , APPLICANT
      , APPLICANT_TELEPHONE_NUMBER
      , PERSON_RESPONSIBLE
      , TELEPHONE_NUMBER_OF_PERSON_IN_CHARGE
      , ESTIMATED_TOTAL_COSTS_OF_ORDER
      , APPLICATION_DATE
      , DEPARTMENT
      , WORK_START
      , END_OF_WORK
      , IDENTIFIER_FOR_WORK_PERMIT_ISSUED
      , OBJECT_NUMBER
      , PROFIT_CENTER
      , WORK_BREAKDOWN_STRUCTURE_ELEMENT
      , VARIANCE_KEY
      , RESULTS_ANALYSIS_KEY
      , TAX_JURISDICTION
      , FUNCTIONAL_AREA
      , OBJECT_CLASS
      , INDICATOR_FOR_INTEGRATED_PLANNING
      , SALES_ORDER_NUMBER
      , ITEM_NUMBER_IN_SALES_ORDER
      , EXTERNAL_ORDER_NUMBER
      , INVESTMENT_MEASURE_PROFILE
      , LOGICAL_SYSTEM
      , ORDER_WITH_MULTIPLE_ITEMS
      , REQUESTING_COMPANY_CODE
      , REQUESTING_COST_CENTER
      , SCALE_OF_INVESTMENT_OBJECTS
      , REASON_FOR_INVESTMENT
      , REASON_FOR_ENVIRONMENTAL_INVESTMENT
      , INDICATOR_DIRECT_COST_COLLECTOR
      , INTEREST_PROFILE_FOR_ORDER
      , COST_COLLECTOR_FOR_PRODUCTION_PROCESS
      , REQUESTING_ORDER
      , PRODUCTION_PROCESS
      , PROCESS_CATEGORY
      , REFURBISHMENT_ORDER_INDICATOR
      , ACCOUNTING_INDICATOR
      , ADDRESS_NUMBER
      , TIME_CREATED
      , CHANGED_AT
      , COSTING_VARIANT
      , COST_ESTIMATE_NUMBER
      , PERSON_RESPONSIBLE_FOR_CO_INTERNAL_ORDER
      , FUND_TYPE
      , USE_COST_FOR_SHOWROOM_FUNDS
      , O8_REFERENCE_FIELD
      , O8_DDMRP_COLOR_CODE
      , O8_BUFFER_PENETRATION_LEVEL
      , JOINT_VENTURE
      , RECOVERY_INDICATOR
      , EQUITY_TYPE
      , JOINT_VENTURE_OBJECT_TYPE
      , JIB_JIBE_CLASS
      , JIB_JIBE_SUBCLASS_A
      , JV_ORIGINAL_COST_OBJECT
      , CU_ORDER_IS_USED_FOR_COMPATIBLE_UNITS
      , CU_CONSTRUCTION_MEASURE_NUMBER
      , CU_AUTOMATIC_COPY_OF_ESTIMATED_COSTS
      , CU_DESIGN_NUMBER
      , MAIN_WORK_CENTER_FOR_MAINTENANCE_TASKS
      , PLANT_ASSOCIATED_WITH_MAIN_WORK_CENTER
      , REGULATORY_INDICATOR
      , CLAIM_CREATION_CONTROL_INDICATOR
      , CLAIM_INCONSISTENCY_WITH_ORDER_INDICATOR
      , CLAIM_UPDATE_TRIGGER_POINT_FROM_SERVICE_ORDER
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
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
          PRODUCTION_ORDER_BK
        , CLIENT
        , ORDER_NUMBER
        , ORDER_TYPE
        , ORDER_CATEGORY
        , REFERENCE_ORDER_NUMBER
        , ENTERED_BY
        , CREATED_ON
        , LAST_CHANGED_BY
        , CHANGE_DATE_FOR_ORDER_MASTER
        , DESCRIPTION
        , LONG_TEXT_EXISTS
        , COMPANY_CODE
        , PLANT
        , BUSINESS_AREA
        , CONTROLLING_AREA
        , COST_COLLECTOR_KEY
        , RESPONSIBLE_COST_CENTER
        , LOCATION
        , LOCATION_PLANT
        , IDENTIFIER_FOR_STATISTICAL_ORDER
        , ORDER_CURRENCY
        , ORDER_STATUS
        , DATE_OF_LAST_STATUS_CHANGE
        , STATUS_REACHED_SO_FAR
        , PHASE_ORDER_CREATED
        , PHASE_ORDER_RELEASED
        , PHASE_ORDER_COMPLETED
        , PHASE_ORDER_CLOSED
        , PLANNED_RELEASE_DATE
        , PLANNED_COMPLETION_DATE
        , PLANNED_CLOSING_DATE
        , RELEASE_DATE
        , TECHNICAL_COMPLETION_DATE
        , CLOSE_DATE
        , OBJECT_ID
        , GROUP_OF_DISALLOWED_TRANSACTIONS
        , DELETION_FLAG
        , IDENTIFIER_FOR_PLANNING_WITH_LINE_ITEMS
        , USAGE_OF_THE_CONDITION_TABLE
        , APPLICATION
        , COSTING_SHEET
        , OVERHEAD_KEY
        , PROCESSING_GROUP
        , SETTLEMENT_COST_ELEMENT
        , COST_CENTER_FOR_BASIC_SETTLEMENT
        , GL_ACCOUNT_FOR_BASIC_SETTLEMENT
        , ALLOCATION_SET
        , COST_CENTER_TO_WHICH_COSTS_ARE_ACTUALLY_POSTED
        , START_DATE
        , SEQUENCE_NUMBER
        , APPLICANT
        , APPLICANT_TELEPHONE_NUMBER
        , PERSON_RESPONSIBLE
        , TELEPHONE_NUMBER_OF_PERSON_IN_CHARGE
        , ESTIMATED_TOTAL_COSTS_OF_ORDER
        , APPLICATION_DATE
        , DEPARTMENT
        , WORK_START
        , END_OF_WORK
        , IDENTIFIER_FOR_WORK_PERMIT_ISSUED
        , OBJECT_NUMBER
        , PROFIT_CENTER
        , WORK_BREAKDOWN_STRUCTURE_ELEMENT
        , VARIANCE_KEY
        , RESULTS_ANALYSIS_KEY
        , TAX_JURISDICTION
        , FUNCTIONAL_AREA
        , OBJECT_CLASS
        , INDICATOR_FOR_INTEGRATED_PLANNING
        , SALES_ORDER_NUMBER
        , ITEM_NUMBER_IN_SALES_ORDER
        , EXTERNAL_ORDER_NUMBER
        , INVESTMENT_MEASURE_PROFILE
        , LOGICAL_SYSTEM
        , ORDER_WITH_MULTIPLE_ITEMS
        , REQUESTING_COMPANY_CODE
        , REQUESTING_COST_CENTER
        , SCALE_OF_INVESTMENT_OBJECTS
        , REASON_FOR_INVESTMENT
        , REASON_FOR_ENVIRONMENTAL_INVESTMENT
        , INDICATOR_DIRECT_COST_COLLECTOR
        , INTEREST_PROFILE_FOR_ORDER
        , COST_COLLECTOR_FOR_PRODUCTION_PROCESS
        , REQUESTING_ORDER
        , PRODUCTION_PROCESS
        , PROCESS_CATEGORY
        , REFURBISHMENT_ORDER_INDICATOR
        , ACCOUNTING_INDICATOR
        , ADDRESS_NUMBER
        , TIME_CREATED
        , CHANGED_AT
        , COSTING_VARIANT
        , COST_ESTIMATE_NUMBER
        , PERSON_RESPONSIBLE_FOR_CO_INTERNAL_ORDER
        , FUND_TYPE
        , USE_COST_FOR_SHOWROOM_FUNDS
        , O8_REFERENCE_FIELD
        , O8_DDMRP_COLOR_CODE
        , O8_BUFFER_PENETRATION_LEVEL
        , JOINT_VENTURE
        , RECOVERY_INDICATOR
        , EQUITY_TYPE
        , JOINT_VENTURE_OBJECT_TYPE
        , JIB_JIBE_CLASS
        , JIB_JIBE_SUBCLASS_A
        , JV_ORIGINAL_COST_OBJECT
        , CU_ORDER_IS_USED_FOR_COMPATIBLE_UNITS
        , CU_CONSTRUCTION_MEASURE_NUMBER
        , CU_AUTOMATIC_COPY_OF_ESTIMATED_COSTS
        , CU_DESIGN_NUMBER
        , MAIN_WORK_CENTER_FOR_MAINTENANCE_TASKS
        , PLANT_ASSOCIATED_WITH_MAIN_WORK_CENTER
        , REGULATORY_INDICATOR
        , CLAIM_CREATION_CONTROL_INDICATOR
        , CLAIM_INCONSISTENCY_WITH_ORDER_INDICATOR
        , CLAIM_UPDATE_TRIGGER_POINT_FROM_SERVICE_ORDER
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , HASHDIFF
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PRODUCTION_ORDER_BK = JOIN_RESULT.PRODUCTION_ORDER_BK  
   AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by PRODUCTION_ORDER_BK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
GR.VALUE::text AS PRODUCTION_ORDER_BK,
NULL AS CLIENT,
NULL AS ORDER_NUMBER,
NULL AS ORDER_TYPE,
NULL AS ORDER_CATEGORY,
NULL AS REFERENCE_ORDER_NUMBER,
NULL AS ENTERED_BY,
NULL AS CREATED_ON,
NULL AS LAST_CHANGED_BY,
NULL AS CHANGE_DATE_FOR_ORDER_MASTER,
NULL AS DESCRIPTION,
NULL AS LONG_TEXT_EXISTS,
NULL AS COMPANY_CODE,
NULL AS PLANT,
NULL AS BUSINESS_AREA,
NULL AS CONTROLLING_AREA,
NULL AS COST_COLLECTOR_KEY,
NULL AS RESPONSIBLE_COST_CENTER,
NULL AS LOCATION,
NULL AS LOCATION_PLANT,
NULL AS IDENTIFIER_FOR_STATISTICAL_ORDER,
NULL AS ORDER_CURRENCY,
NULL AS ORDER_STATUS,
NULL AS DATE_OF_LAST_STATUS_CHANGE,
NULL AS STATUS_REACHED_SO_FAR,
NULL AS PHASE_ORDER_CREATED,
NULL AS PHASE_ORDER_RELEASED,
NULL AS PHASE_ORDER_COMPLETED,
NULL AS PHASE_ORDER_CLOSED,
NULL AS PLANNED_RELEASE_DATE,
NULL AS PLANNED_COMPLETION_DATE,
NULL AS PLANNED_CLOSING_DATE,
NULL AS RELEASE_DATE,
NULL AS TECHNICAL_COMPLETION_DATE,
NULL AS CLOSE_DATE,
NULL AS OBJECT_ID,
NULL AS GROUP_OF_DISALLOWED_TRANSACTIONS,
NULL AS DELETION_FLAG,
NULL AS IDENTIFIER_FOR_PLANNING_WITH_LINE_ITEMS,
NULL AS USAGE_OF_THE_CONDITION_TABLE,
NULL AS APPLICATION,
NULL AS COSTING_SHEET,
NULL AS OVERHEAD_KEY,
NULL AS PROCESSING_GROUP,
NULL AS SETTLEMENT_COST_ELEMENT,
NULL AS COST_CENTER_FOR_BASIC_SETTLEMENT,
NULL AS GL_ACCOUNT_FOR_BASIC_SETTLEMENT,
NULL AS ALLOCATION_SET,
NULL AS COST_CENTER_TO_WHICH_COSTS_ARE_ACTUALLY_POSTED,
NULL AS START_DATE,
NULL AS SEQUENCE_NUMBER,
NULL AS APPLICANT,
NULL AS APPLICANT_TELEPHONE_NUMBER,
NULL AS PERSON_RESPONSIBLE,
NULL AS TELEPHONE_NUMBER_OF_PERSON_IN_CHARGE,
NULL AS ESTIMATED_TOTAL_COSTS_OF_ORDER,
NULL AS APPLICATION_DATE,
NULL AS DEPARTMENT,
NULL AS WORK_START,
NULL AS END_OF_WORK,
NULL AS IDENTIFIER_FOR_WORK_PERMIT_ISSUED,
NULL AS OBJECT_NUMBER,
NULL AS PROFIT_CENTER,
NULL AS WORK_BREAKDOWN_STRUCTURE_ELEMENT,
NULL AS VARIANCE_KEY,
NULL AS RESULTS_ANALYSIS_KEY,
NULL AS TAX_JURISDICTION,
NULL AS FUNCTIONAL_AREA,
NULL AS OBJECT_CLASS,
NULL AS INDICATOR_FOR_INTEGRATED_PLANNING,
NULL AS SALES_ORDER_NUMBER,
NULL AS ITEM_NUMBER_IN_SALES_ORDER,
NULL AS EXTERNAL_ORDER_NUMBER,
NULL AS INVESTMENT_MEASURE_PROFILE,
NULL AS LOGICAL_SYSTEM,
NULL AS ORDER_WITH_MULTIPLE_ITEMS,
NULL AS REQUESTING_COMPANY_CODE,
NULL AS REQUESTING_COST_CENTER,
NULL AS SCALE_OF_INVESTMENT_OBJECTS,
NULL AS REASON_FOR_INVESTMENT,
NULL AS REASON_FOR_ENVIRONMENTAL_INVESTMENT,
NULL AS INDICATOR_DIRECT_COST_COLLECTOR,
NULL AS INTEREST_PROFILE_FOR_ORDER,
NULL AS COST_COLLECTOR_FOR_PRODUCTION_PROCESS,
NULL AS REQUESTING_ORDER,
NULL AS PRODUCTION_PROCESS,
NULL AS PROCESS_CATEGORY,
NULL AS REFURBISHMENT_ORDER_INDICATOR,
NULL AS ACCOUNTING_INDICATOR,
NULL AS ADDRESS_NUMBER,
NULL AS TIME_CREATED,
NULL AS CHANGED_AT,
NULL AS COSTING_VARIANT,
NULL AS COST_ESTIMATE_NUMBER,
NULL AS PERSON_RESPONSIBLE_FOR_CO_INTERNAL_ORDER,
NULL AS FUND_TYPE,
NULL AS USE_COST_FOR_SHOWROOM_FUNDS,
NULL AS O8_REFERENCE_FIELD,
NULL AS O8_DDMRP_COLOR_CODE,
NULL AS O8_BUFFER_PENETRATION_LEVEL,
NULL AS JOINT_VENTURE,
NULL AS RECOVERY_INDICATOR,
NULL AS EQUITY_TYPE,
NULL AS JOINT_VENTURE_OBJECT_TYPE,
NULL AS JIB_JIBE_CLASS,
NULL AS JIB_JIBE_SUBCLASS_A,
NULL AS JV_ORIGINAL_COST_OBJECT,
NULL AS CU_ORDER_IS_USED_FOR_COMPATIBLE_UNITS,
NULL AS CU_CONSTRUCTION_MEASURE_NUMBER,
NULL AS CU_AUTOMATIC_COPY_OF_ESTIMATED_COSTS,
NULL AS CU_DESIGN_NUMBER,
NULL AS MAIN_WORK_CENTER_FOR_MAINTENANCE_TASKS,
NULL AS PLANT_ASSOCIATED_WITH_MAIN_WORK_CENTER,
NULL AS REGULATORY_INDICATOR,
NULL AS CLAIM_CREATION_CONTROL_INDICATOR,
NULL AS CLAIM_INCONSISTENCY_WITH_ORDER_INDICATOR,
NULL AS CLAIM_UPDATE_TRIGGER_POINT_FROM_SERVICE_ORDER,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
''::BINARY AS HASHDIFF,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}