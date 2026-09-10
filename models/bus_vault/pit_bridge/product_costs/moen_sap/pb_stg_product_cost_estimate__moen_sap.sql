{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HPC            as ( SELECT BKCC, ITEM_BK, PLANT_BK, PRODUCT_COST_ESTIMATE_HK, REC_SRC FROM {{ ref('hub_product_cost_estimate') }} as SRC  ),
SRC_CEH            as ( SELECT AFAKT, ALDAT, ASL, AUFPL, AUFZA, AUSID, AUSSS, BALTKZ, BAPI_CREATED, BDATJ, BEDAT, BESKZ, BIDAM, BIDAT, BTYP, BWDAT, BWKEY, BWSMR, BWTAR, BWVAR, BWVAR_BA, BZOBJ, CFXPR, CMF_NR, CPUDM, CPUDT, CPUTIME, CSPLIT, CUOBJ, CUOBJID, DISST, ELEHK, ELEHKNS, ERFMA, ERFNM, ERZKA, FEH_ANZ, FEH_K_ANZ, FEH_STA, FREIDAT, FREIG, FREIUSR, FWAER_KPF, FXPRU, GSBER, HWAER, ITEM_HK, KADAM, KADAT, KADKY, KALADAT, KALAID, KALKA, KALNR, KALNR_BA, KALSM, KALST, KKZMA, KLVAR, KOKRS, KOSGR, KURST, KZKUP, KZROH, KZWSO, LOAD_DTS, LOEKZ, LOSAU, LOSGR, MATNR, MAXMSG, MEINH_WS, MEINS, MGTYP, MISCH_VERH, MKALK, MLMAA, OBJNR, OCS_COUNT, OTYP, PART_VRSN, PLANT_HK, PLMNG, PLNAL, PLNCT, PLNNR, PLNTY, PLSCN, POPER, POSNR, PRCTR, PRODUCT_COST_ESTIMATE_HK, PROZESS, PR_VERID, PSPNR, REFID, SAPRL, SBDKZ, SGT_SCAT, SOBES, SOBSL, SOBWT, SODIR, SODUM, SOWRK, STALT, STCNT, STKOZ, STLAN, STNUM, SUBSTRAT, SUMZIFFR, TECHS, TEMPLATE, TOPKA, TPVAR, TYPE, UEBID, VBELN, VERID, VOCNT, VORMDAT, VORMUSR, WRKLT, ZAEHL, ZIFFR, ZSCHL FROM {{ ref('msat_product_cost_estimate_header__moen_sap') }} as SRC 
                        qualify row_number() over(partition by MATNR,BZOBJ,KALNR,BWVAR,KKZMA,KADKY order by LOAD_DTS desc)=1 ),
SRC_CEC            as ( SELECT BWVAR, BZOBJ, DIPA, KADKY, KALNR, KEART, KKZMA, KKZMM, KKZST, KST001, KST002, KST003, KST004, KST005, KST006, KST007, KST008, KST009, KST010, KST011, KST012, KST013, KST014, KST015, KST016, KST017, KST018, KST019, KST020, KST021, KST022, KST023, KST024, KST025, KST026, KST027, KST028, KST029, KST030, KST031, KST032, KST033, KST034, KST035, KST036, KST037, KST038, KST039, KST040, LOAD_DTS, LOSFX, MANDT, PATNR, PRODUCT_COST_ESTIMATE_HK, TVERS FROM {{ ref('sat_product_cost_estimate_component__moen_sap') }} as SRC 
                        qualify row_number() over(partition by MANDT,BZOBJ,KALNR,KALKA,KADKY,TVERS,BWVAR,KKZMA,PATNR,KEART,LOSFX,KKZST,KKZMM order by LOAD_DTS desc)=1 )

/*
SRC_HPC            as ( SELECT * FROM raw_vault.hub_product_cost_estimate )
SRC_CEH            as ( SELECT * FROM raw_vault.msat_product_cost_estimate_header__moen_sap )
SRC_CEC            as ( SELECT * FROM raw_vault.sat_product_cost_estimate_component__moen_sap )
*/
---- LOGIC LAYER ----

, LOGIC_HPC as (
    SELECT
        PRODUCT_COST_ESTIMATE_HK
      , ITEM_BK
      , PLANT_BK
      , REC_SRC
      , BKCC
    FROM SRC_HPC
)

, LOGIC_CEH as (
    SELECT
        MATNR                                                        as                                          CEH_MATNR
      , BZOBJ                                                        as                                          CEH_BZOBJ
      , KALNR                                                        as                                          CEH_KALNR
      , BWVAR                                                        as                                          CEH_BWVAR
      , KKZMA                                                        as                                          CEH_KKZMA
      , KADKY                                                        as                                          CEH_KADKY
      , LOAD_DTS                                                     as                                       CEH_LOAD_DTS
      , PRODUCT_COST_ESTIMATE_HK                                     as                       CEH_PRODUCT_COST_ESTIMATE_HK
      , ITEM_HK
      , PLANT_HK
      , AFAKT                                                        as                               APPORTIONMENT_FACTOR
      , ALDAT
      , TRY_TO_NUMBER(ALDAT)                                         as                  QUANTITY_STRUCTURE_DATE__YYYYMMDD
      , ASL                                                          as                                    CE_OF_ORDER_BOM
      , AUFPL                                                        as                       ROUTING_NUMBER_OF_OPERATIONS
      , AUFZA                                                        as                                      OVERHEAD_TYPE
      , AUSID                                                        as                  ASSEMBLY_OPERATION_SCRAP_INCLUDED
      , AUSSS                                                        as                          ASSEMBLY_SCRAP_IN_PERCENT
      , BALTKZ                                                       as                     CE_FOR_PROCUREMENT_ALTERNATIVE
      , BAPI_CREATED                                                 as                               CE_GENERATED_BY_BAPI
      , BDATJ                                                        as                                        FISCAL_YEAR
      , BEDAT
      , TRY_TO_NUMBER(BEDAT)                                         as                        REQUIREMENTS_DATE__YYYYMMDD
      , BESKZ                                                        as                                   PROCUREMENT_TYPE
      , BIDAM
      , TRY_TO_NUMBER(BIDAM)                                         as                 COSTING_ADDITIVE_TO_DATE__YYYYMMDD
      , BIDAT
      , TRY_TO_NUMBER(BIDAT)                                         as                          COSTING_TO_DATE__YYYYMMDD
      , BTYP                                                         as                                   PROCESS_CATEGORY
      , BWDAT
      , TRY_TO_NUMBER(BWDAT)                                         as                           VALUATION_DATE__YYYYMMDD
      , BWKEY                                                        as                                     VALUATION_AREA
      , BWSMR                                                        as               VALUATION_STRATEGY_FOR_RAW_MATERIALS
      , BWTAR                                                        as                                     VALUATION_TYPE
      , BWVAR_BA                                                     as                  VALUATION_VARIANT_FOR_PROCUREMENT
      , CFXPR                                                        as                CE_CONTAINS_FIXED_PRICE_CO_PRODUCTS
      , CMF_NR                                                       as                            ERROR_MANAGEMENT_NUMBER
      , CPUDM
      , TRY_TO_NUMBER(CPUDM)                                         as                   ADDITIVE_CE_SAVED_DATE__YYYYMMDD
      , CPUDT
      , TRY_TO_NUMBER(CPUDT)                                         as               COST_ESTIMATE_CREATED_DATE__YYYYMMDD
      , CPUTIME                                                      as                         SYSTEM_OF_CE_CREATION_TIME
      , CSPLIT                                                       as                            APPORTIONMENT_STRUCTURE
      , CUOBJ                                                        as                   CONFIGURATION_INTERNAL_OBJECT_NO
      , CUOBJID                                                      as                     CONFIGURABLE_OBJECTS_INDICATOR
      , DISST                                                        as                                     LOW_LEVEL_CODE
      , ELEHK                                                        as                           COST_COMPONENT_STRUCTURE
      , ELEHKNS                                                      as                       COST_COMPONENT_STRUCTURE_AUX
      , ERFMA                                                        as                        USER_ADDITIVE_COST_ESTIMATE
      , ERFNM                                                        as                                     COSTED_BY_USER
      , ERZKA                                                        as                       CREATED_WITH_PRODUCT_COSTING
      , FEH_ANZ                                                      as         NUMBER_OF_SYSTEM_MESSAGES_DURING_SELECTION
      , FEH_K_ANZ                                                    as           NUMBER_OF_SYSTEM_MESSAGES_DURING_COSTING
      , FEH_STA                                                      as                                     COSTING_STATUS
      , FREIDAT
      , TRY_TO_NUMBER(FREIDAT)                                       as               COST_ESTIMATE_RELEASE_DATE__YYYYMMDD
      , FREIG                                                        as                  RELEASE_OF_STANDARD_COST_ESTIMATE
      , FREIUSR                                                      as                    USER_WHO_RELEASED_COST_ESTIMATE
      , FWAER_KPF                                                    as                                       CURRENCY_KEY
      , FXPRU                                                        as                             FIXED_PRICE_CO_PRODUCT
      , GSBER                                                        as                                      BUSINESS_AREA
      , HWAER                                                        as                                     LOCAL_CURRENCY
      , KADAM
      , TRY_TO_NUMBER(KADAM)                                         as                    COSTING_ADDITIVE_DATE__YYYYMMDD
      , KADAT
      , TRY_TO_NUMBER(KADAT)                                         as                        COSTING_FROM_DATE__YYYYMMDD
      , KALADAT
      , TRY_TO_NUMBER(KALADAT)                                       as                         COSTING_RUN_DATE__YYYYMMDD
      , KALAID                                                       as                                NAME_OF_COSTING_RUN
      , KALKA                                                        as                                       COSTING_TYPE
      , KALNR_BA                                                     as              CE_NUMBER_FOR_PROCUREMENT_ALTERNATIVE
      , KALSM                                                        as                         COSTING_SHEET_FOR_OVERHEAD
      , KALST                                                        as                                      COSTING_LEVEL
      , KLVAR                                                        as                                    COSTING_VARIANT
      , KOKRS                                                        as                                   CONTROLLING_AREA
      , KOSGR                                                        as                                     OVERHEAD_GROUP
      , KURST                                                        as                                 EXCHANGE_RATE_TYPE
      , KZKUP                                                        as                         MATERIAL_CAN_BE_CO_PRODUCT
      , KZROH                                                        as                       MATERIAL_COMPONENT_INDICATOR
      , KZWSO                                                        as                             UNITS_OF_MEASURE_USAGE
      , LOEKZ                                                        as                                 DELETION_INDICATOR
      , LOSAU                                                        as                           LOT_SIZE_INCLUDING_SCRAP
      , LOSGR                                                        as                       LOT_SIZE_FOR_PRODUCT_COSTING
      , MAXMSG                                                       as                               HIGHEST_MESSAGE_TYPE
      , MEINH_WS                                                     as                     BATCH_SPECIFIC_UNIT_OF_MEASURE
      , MEINS                                                        as                               BASE_UNIT_OF_MEASURE
      , MGTYP                                                        as                            QUANTITY_STRUCTURE_TYPE
      , MISCH_VERH                                                   as                     MIXING_RATIO_FOR_MIXED_COSTING
      , MKALK                                                        as                            MIXED_COSTING_INDICATOR
      , MLMAA                                                        as                          MATERIAL_LEDGER_ACTIVATED
      , OBJNR                                                        as                                      OBJECT_NUMBER
      , OCS_COUNT                                                    as                                  OCS_MESSAGES_SENT
      , OTYP                                                         as                                        OBJECT_TYPE
      , PART_VRSN                                                    as                                    PARTNER_VERSION
      , PLMNG                                                        as                           PRODUCTION_PLAN_QUANTITY
      , PLNAL                                                        as                                      GROUP_COUNTER
      , PLNCT                                                        as                           INTERNAL_COUNTER_ROUTING
      , PLNNR                                                        as                                    TASK_LIST_GROUP
      , PLNTY                                                        as                                     TASK_LIST_TYPE
      , PLSCN                                                        as                                  PLANNING_SCENARIO
      , POPER                                                        as                                     POSTING_PERIOD
      , POSNR                                                        as                         ITEM_NUMBER_IN_SD_DOCUMENT
      , PR_VERID                                                     as                          PRODUCTION_VERSION_COSTED
      , PRCTR                                                        as                                      PROFIT_CENTER
      , PROZESS                                                      as                         PROCESS_CO_PRODUCT_COSTING
      , PSPNR                                                        as                                        WBS_ELEMENT
      , REFID                                                        as                                  REFERENCE_VARIANT
      , SAPRL                                                        as                                        SAP_RELEASE
      , SBDKZ                                                        as                   DEPENDENT_REQUIREMENTS_INDICATOR
      , SGT_SCAT                                                     as                                      STOCK_SEGMENT
      , SOBES                                                        as                           SPECIAL_PROCUREMENT_TYPE
      , SOBSL                                                        as                            SPECIAL_PROCUREMENT_KEY
      , SOBWT                                                        as             VALUATION_TYPE_FOR_SPECIAL_PROCUREMENT
      , SODIR                                                        as                        DIRECT_PRODUCTION_INDICATOR
      , SODUM                                                        as                             PHANTOM_ITEM_INDICATOR
      , SOWRK                                                        as                          SPECIAL_PROCUREMENT_PLANT
      , STALT                                                        as                                    ALTERNATIVE_BOM
      , STCNT                                                        as                               INTERNAL_COUNTER_BOM
      , STKOZ                                                        as                       INTERNAL_COUNTER_FOR_COSTING
      , STLAN                                                        as                                          BOM_USAGE
      , STNUM                                                        as                                   BILL_OF_MATERIAL
      , SUBSTRAT                                                     as                 SUBSTRATEGY_FOR_MATERIAL_VALUATION
      , SUMZIFFR                                                     as                         SUM_OF_EQUIVALENCE_NUMBERS
      , TECHS                                                        as                                  PARAMETER_VARIANT
      , TEMPLATE
      , TOPKA                                                        as                             TOP_COST_ESTIMATE_FLAG
      , TPVAR                                                        as                             TRANSFER_PRICE_VARIANT
      , TYPE                                                         as                           CONFIGURED_MATERIAL_TYPE
      , UEBID                                                        as                                   TRANSFER_CONTROL
      , VBELN                                                        as             SALES_AND_DISTRIBUTION_DOCUMENT_NUMBER
      , VERID                                                        as                                 PRODUCTION_VERSION
      , VOCNT                                                        as                  COUNTER_FOR_MARKING_COST_ESTIMATE
      , VORMDAT
      , TRY_TO_NUMBER(VORMDAT)                                       as                COST_ESTIMATE_MARKED_DATE__YYYYMMDD
      , VORMUSR                                                      as                      USER_WHO_MARKED_COST_ESTIMATE
      , WRKLT                                                        as                                      PLANT_VARIANT
      , ZAEHL                                                        as                                   INTERNAL_COUNTER
      , ZIFFR                                                        as                                 EQUIVALENCE_NUMBER
      , ZSCHL                                                        as                                       OVERHEAD_KEY
      , (left(FISCAL_YEAR,4)||'-'||right(POSTING_PERIOD,2)||'-01')::DATE as                                      FISCAL_PERIOD
    FROM SRC_CEH
)

, LOGIC_CEC as (
    SELECT
        LOAD_DTS
      , MANDT                                                        as                                             CLIENT
      , BZOBJ                                                        as                                          CEC_BZOBJ
      , KALNR                                                        as                                          CEC_KALNR
      , BWVAR                                                        as                                          CEC_BWVAR
      , KKZMA                                                        as                                          CEC_KKZMA
      , KADKY                                                        as                                          CEC_KADKY
      , PRODUCT_COST_ESTIMATE_HK                                     as                       CEC_PRODUCT_COST_ESTIMATE_HK
      , BWVAR                                                        as                                  VALUATION_VARIANT
      , BZOBJ                                                        as                                   REFERENCE_OBJECT
      , DIPA                                                         as                      DIRECT_PARTNER_CHARACTERISTIC
      , KADKY
      , TRY_TO_NUMBER(KADKY)                                         as                             COSTING_DATE__YYYYMMDD
      , KALNR                                                        as                               COST_ESTIMATE_NUMBER
      , KEART                                                        as                       TYPE_OF_COST_COMPONENT_SPLIT
      , KKZMA                                                        as                             COSTS_ENTERED_MANUALLY
      , KKZMM                                                        as                     INDICATOR_COSTS_ENTERED_MANUAL
      , KKZST                                                        as                        INDICATOR_LOWER_LEVEL_COSTS
      , KST001                                                       as                          COST_COMPONENT_AMOUNT_001
      , KST002                                                       as                          COST_COMPONENT_AMOUNT_002
      , KST003                                                       as                          COST_COMPONENT_AMOUNT_003
      , KST004                                                       as                          COST_COMPONENT_AMOUNT_004
      , KST005                                                       as                          COST_COMPONENT_AMOUNT_005
      , KST006                                                       as                          COST_COMPONENT_AMOUNT_006
      , KST007                                                       as                          COST_COMPONENT_AMOUNT_007
      , KST008                                                       as                          COST_COMPONENT_AMOUNT_008
      , KST009                                                       as                          COST_COMPONENT_AMOUNT_009
      , KST010                                                       as                          COST_COMPONENT_AMOUNT_010
      , KST011                                                       as                          COST_COMPONENT_AMOUNT_011
      , KST012                                                       as                          COST_COMPONENT_AMOUNT_012
      , KST013                                                       as                          COST_COMPONENT_AMOUNT_013
      , KST014                                                       as                          COST_COMPONENT_AMOUNT_014
      , KST015                                                       as                          COST_COMPONENT_AMOUNT_015
      , KST016                                                       as                          COST_COMPONENT_AMOUNT_016
      , KST017                                                       as                          COST_COMPONENT_AMOUNT_017
      , KST018                                                       as                          COST_COMPONENT_AMOUNT_018
      , KST019                                                       as                          COST_COMPONENT_AMOUNT_019
      , KST020                                                       as                          COST_COMPONENT_AMOUNT_020
      , KST021                                                       as                          COST_COMPONENT_AMOUNT_021
      , KST022                                                       as                          COST_COMPONENT_AMOUNT_022
      , KST023                                                       as                          COST_COMPONENT_AMOUNT_023
      , KST024                                                       as                          COST_COMPONENT_AMOUNT_024
      , KST025                                                       as                          COST_COMPONENT_AMOUNT_025
      , KST026                                                       as                          COST_COMPONENT_AMOUNT_026
      , KST027                                                       as                          COST_COMPONENT_AMOUNT_027
      , KST028                                                       as                          COST_COMPONENT_AMOUNT_028
      , KST029                                                       as                          COST_COMPONENT_AMOUNT_029
      , KST030                                                       as                          COST_COMPONENT_AMOUNT_030
      , KST031                                                       as                          COST_COMPONENT_AMOUNT_031
      , KST032                                                       as                          COST_COMPONENT_AMOUNT_032
      , KST033                                                       as                          COST_COMPONENT_AMOUNT_033
      , KST034                                                       as                          COST_COMPONENT_AMOUNT_034
      , KST035                                                       as                          COST_COMPONENT_AMOUNT_035
      , KST036                                                       as                          COST_COMPONENT_AMOUNT_036
      , KST037                                                       as                          COST_COMPONENT_AMOUNT_037
      , KST038                                                       as                          COST_COMPONENT_AMOUNT_038
      , KST039                                                       as                          COST_COMPONENT_AMOUNT_039
      , KST040                                                       as                          COST_COMPONENT_AMOUNT_040
      , LOSFX                                                        as                       LINK_FIELD_FOR_CURRENCY_TYPE
      , PATNR                                                        as                                     PARTNER_NUMBER
      , TVERS                                                        as                                    COSTING_VERSION
    FROM SRC_CEC
)
---- RENAME LAYER ----

, RENAME_CEH as (
    SELECT
        CEH_MATNR
      , CEH_BZOBJ
      , CEH_KALNR
      , CEH_BWVAR
      , CEH_KKZMA
      , CEH_KADKY
      , CEH_LOAD_DTS
      , CEH_PRODUCT_COST_ESTIMATE_HK
      , ITEM_HK
      , PLANT_HK
      , APPORTIONMENT_FACTOR
      , ALDAT
      , QUANTITY_STRUCTURE_DATE__YYYYMMDD
      , CE_OF_ORDER_BOM
      , ROUTING_NUMBER_OF_OPERATIONS
      , OVERHEAD_TYPE
      , ASSEMBLY_OPERATION_SCRAP_INCLUDED
      , ASSEMBLY_SCRAP_IN_PERCENT
      , CE_FOR_PROCUREMENT_ALTERNATIVE
      , CE_GENERATED_BY_BAPI
      , FISCAL_YEAR
      , BEDAT
      , REQUIREMENTS_DATE__YYYYMMDD
      , PROCUREMENT_TYPE
      , BIDAM
      , COSTING_ADDITIVE_TO_DATE__YYYYMMDD
      , BIDAT
      , COSTING_TO_DATE__YYYYMMDD
      , PROCESS_CATEGORY
      , BWDAT
      , VALUATION_DATE__YYYYMMDD
      , VALUATION_AREA
      , VALUATION_STRATEGY_FOR_RAW_MATERIALS
      , VALUATION_TYPE
      , VALUATION_VARIANT_FOR_PROCUREMENT
      , CE_CONTAINS_FIXED_PRICE_CO_PRODUCTS
      , ERROR_MANAGEMENT_NUMBER
      , CPUDM
      , ADDITIVE_CE_SAVED_DATE__YYYYMMDD
      , CPUDT
      , COST_ESTIMATE_CREATED_DATE__YYYYMMDD
      , SYSTEM_OF_CE_CREATION_TIME
      , APPORTIONMENT_STRUCTURE
      , CONFIGURATION_INTERNAL_OBJECT_NO
      , CONFIGURABLE_OBJECTS_INDICATOR
      , LOW_LEVEL_CODE
      , COST_COMPONENT_STRUCTURE
      , COST_COMPONENT_STRUCTURE_AUX
      , USER_ADDITIVE_COST_ESTIMATE
      , COSTED_BY_USER
      , CREATED_WITH_PRODUCT_COSTING
      , NUMBER_OF_SYSTEM_MESSAGES_DURING_SELECTION
      , NUMBER_OF_SYSTEM_MESSAGES_DURING_COSTING
      , COSTING_STATUS
      , FREIDAT
      , COST_ESTIMATE_RELEASE_DATE__YYYYMMDD
      , RELEASE_OF_STANDARD_COST_ESTIMATE
      , USER_WHO_RELEASED_COST_ESTIMATE
      , CURRENCY_KEY
      , FIXED_PRICE_CO_PRODUCT
      , BUSINESS_AREA
      , LOCAL_CURRENCY
      , KADAM
      , COSTING_ADDITIVE_DATE__YYYYMMDD
      , KADAT
      , COSTING_FROM_DATE__YYYYMMDD
      , KALADAT
      , COSTING_RUN_DATE__YYYYMMDD
      , NAME_OF_COSTING_RUN
      , COSTING_TYPE
      , CE_NUMBER_FOR_PROCUREMENT_ALTERNATIVE
      , COSTING_SHEET_FOR_OVERHEAD
      , COSTING_LEVEL
      , COSTING_VARIANT
      , CONTROLLING_AREA
      , OVERHEAD_GROUP
      , EXCHANGE_RATE_TYPE
      , MATERIAL_CAN_BE_CO_PRODUCT
      , MATERIAL_COMPONENT_INDICATOR
      , UNITS_OF_MEASURE_USAGE
      , DELETION_INDICATOR
      , LOT_SIZE_INCLUDING_SCRAP
      , LOT_SIZE_FOR_PRODUCT_COSTING
      , HIGHEST_MESSAGE_TYPE
      , BATCH_SPECIFIC_UNIT_OF_MEASURE
      , BASE_UNIT_OF_MEASURE
      , QUANTITY_STRUCTURE_TYPE
      , MIXING_RATIO_FOR_MIXED_COSTING
      , MIXED_COSTING_INDICATOR
      , MATERIAL_LEDGER_ACTIVATED
      , OBJECT_NUMBER
      , OCS_MESSAGES_SENT
      , OBJECT_TYPE
      , PARTNER_VERSION
      , PRODUCTION_PLAN_QUANTITY
      , GROUP_COUNTER
      , INTERNAL_COUNTER_ROUTING
      , TASK_LIST_GROUP
      , TASK_LIST_TYPE
      , PLANNING_SCENARIO
      , POSTING_PERIOD
      , ITEM_NUMBER_IN_SD_DOCUMENT
      , PRODUCTION_VERSION_COSTED
      , PROFIT_CENTER
      , PROCESS_CO_PRODUCT_COSTING
      , WBS_ELEMENT
      , REFERENCE_VARIANT
      , SAP_RELEASE
      , DEPENDENT_REQUIREMENTS_INDICATOR
      , STOCK_SEGMENT
      , SPECIAL_PROCUREMENT_TYPE
      , SPECIAL_PROCUREMENT_KEY
      , VALUATION_TYPE_FOR_SPECIAL_PROCUREMENT
      , DIRECT_PRODUCTION_INDICATOR
      , PHANTOM_ITEM_INDICATOR
      , SPECIAL_PROCUREMENT_PLANT
      , ALTERNATIVE_BOM
      , INTERNAL_COUNTER_BOM
      , INTERNAL_COUNTER_FOR_COSTING
      , BOM_USAGE
      , BILL_OF_MATERIAL
      , SUBSTRATEGY_FOR_MATERIAL_VALUATION
      , SUM_OF_EQUIVALENCE_NUMBERS
      , PARAMETER_VARIANT
      , TEMPLATE
      , TOP_COST_ESTIMATE_FLAG
      , TRANSFER_PRICE_VARIANT
      , CONFIGURED_MATERIAL_TYPE
      , TRANSFER_CONTROL
      , SALES_AND_DISTRIBUTION_DOCUMENT_NUMBER
      , PRODUCTION_VERSION
      , COUNTER_FOR_MARKING_COST_ESTIMATE
      , VORMDAT
      , COST_ESTIMATE_MARKED_DATE__YYYYMMDD
      , USER_WHO_MARKED_COST_ESTIMATE
      , PLANT_VARIANT
      , INTERNAL_COUNTER
      , EQUIVALENCE_NUMBER
      , OVERHEAD_KEY
      , FISCAL_PERIOD
    FROM LOGIC_CEH
)

, RENAME_CEC as (
    SELECT
        LOAD_DTS
      , CLIENT
      , CEC_BZOBJ
      , CEC_KALNR
      , CEC_BWVAR
      , CEC_KKZMA
      , CEC_KADKY
      , CEC_PRODUCT_COST_ESTIMATE_HK
      , VALUATION_VARIANT
      , REFERENCE_OBJECT
      , DIRECT_PARTNER_CHARACTERISTIC
      , KADKY
      , COSTING_DATE__YYYYMMDD
      , COST_ESTIMATE_NUMBER
      , TYPE_OF_COST_COMPONENT_SPLIT
      , COSTS_ENTERED_MANUALLY
      , INDICATOR_COSTS_ENTERED_MANUAL
      , INDICATOR_LOWER_LEVEL_COSTS
      , COST_COMPONENT_AMOUNT_001
      , COST_COMPONENT_AMOUNT_002
      , COST_COMPONENT_AMOUNT_003
      , COST_COMPONENT_AMOUNT_004
      , COST_COMPONENT_AMOUNT_005
      , COST_COMPONENT_AMOUNT_006
      , COST_COMPONENT_AMOUNT_007
      , COST_COMPONENT_AMOUNT_008
      , COST_COMPONENT_AMOUNT_009
      , COST_COMPONENT_AMOUNT_010
      , COST_COMPONENT_AMOUNT_011
      , COST_COMPONENT_AMOUNT_012
      , COST_COMPONENT_AMOUNT_013
      , COST_COMPONENT_AMOUNT_014
      , COST_COMPONENT_AMOUNT_015
      , COST_COMPONENT_AMOUNT_016
      , COST_COMPONENT_AMOUNT_017
      , COST_COMPONENT_AMOUNT_018
      , COST_COMPONENT_AMOUNT_019
      , COST_COMPONENT_AMOUNT_020
      , COST_COMPONENT_AMOUNT_021
      , COST_COMPONENT_AMOUNT_022
      , COST_COMPONENT_AMOUNT_023
      , COST_COMPONENT_AMOUNT_024
      , COST_COMPONENT_AMOUNT_025
      , COST_COMPONENT_AMOUNT_026
      , COST_COMPONENT_AMOUNT_027
      , COST_COMPONENT_AMOUNT_028
      , COST_COMPONENT_AMOUNT_029
      , COST_COMPONENT_AMOUNT_030
      , COST_COMPONENT_AMOUNT_031
      , COST_COMPONENT_AMOUNT_032
      , COST_COMPONENT_AMOUNT_033
      , COST_COMPONENT_AMOUNT_034
      , COST_COMPONENT_AMOUNT_035
      , COST_COMPONENT_AMOUNT_036
      , COST_COMPONENT_AMOUNT_037
      , COST_COMPONENT_AMOUNT_038
      , COST_COMPONENT_AMOUNT_039
      , COST_COMPONENT_AMOUNT_040
      , LINK_FIELD_FOR_CURRENCY_TYPE
      , PARTNER_NUMBER
      , COSTING_VERSION
    FROM LOGIC_CEC
)

, RENAME_HPC as (
    SELECT
        PRODUCT_COST_ESTIMATE_HK
      , ITEM_BK
      , PLANT_BK
      , REC_SRC
      , BKCC
    FROM LOGIC_HPC
)
---- FILTER LAYER ----

, FILTER_HPC as (
    SELECT *
    FROM RENAME_HPC
)

, FILTER_CEH as (
    SELECT *
    FROM RENAME_CEH
)

, FILTER_CEC as (
    SELECT *
    FROM RENAME_CEC
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HPC
    INNER JOIN FILTER_CEH
        ON product_cost_estimate_hk = CEH_product_cost_estimate_hk
    LEFT JOIN FILTER_CEC
        ON CEH_product_cost_estimate_hk = CEC_product_cost_estimate_hk
and 
CEH_BZOBJ =CEC_bzobj
and
CEH_kalnr=CEC_kalnr
and 
CEH_bwvar=CEC_bwvar
and
CEH_kkzma=CEC_kkzma
and
CEH_kadky=CEC_kadky
)

---- FINAL LAYER ----
SELECT
          CLIENT
        , PRODUCT_COST_ESTIMATE_HK
        , ITEM_HK
        , ITEM_BK
        , PLANT_HK
        , PLANT_BK
        , APPORTIONMENT_FACTOR
        , QUANTITY_STRUCTURE_DATE__YYYYMMDD
        , CE_OF_ORDER_BOM
        , ROUTING_NUMBER_OF_OPERATIONS
        , OVERHEAD_TYPE
        , ASSEMBLY_OPERATION_SCRAP_INCLUDED
        , ASSEMBLY_SCRAP_IN_PERCENT
        , CE_FOR_PROCUREMENT_ALTERNATIVE
        , CE_GENERATED_BY_BAPI
        , FISCAL_YEAR
        , REQUIREMENTS_DATE__YYYYMMDD
        , PROCUREMENT_TYPE
        , COSTING_ADDITIVE_TO_DATE__YYYYMMDD
        , COSTING_TO_DATE__YYYYMMDD
        , PROCESS_CATEGORY
        , VALUATION_DATE__YYYYMMDD
        , VALUATION_AREA
        , VALUATION_STRATEGY_FOR_RAW_MATERIALS
        , VALUATION_TYPE
        , VALUATION_VARIANT
        , VALUATION_VARIANT_FOR_PROCUREMENT
        , REFERENCE_OBJECT
        , CE_CONTAINS_FIXED_PRICE_CO_PRODUCTS
        , ERROR_MANAGEMENT_NUMBER
        , ADDITIVE_CE_SAVED_DATE__YYYYMMDD
        , COST_ESTIMATE_CREATED_DATE__YYYYMMDD
        , SYSTEM_OF_CE_CREATION_TIME
        , APPORTIONMENT_STRUCTURE
        , CONFIGURATION_INTERNAL_OBJECT_NO
        , CONFIGURABLE_OBJECTS_INDICATOR
        , DIRECT_PARTNER_CHARACTERISTIC
        , LOW_LEVEL_CODE
        , COST_COMPONENT_STRUCTURE
        , COST_COMPONENT_STRUCTURE_AUX
        , USER_ADDITIVE_COST_ESTIMATE
        , COSTED_BY_USER
        , CREATED_WITH_PRODUCT_COSTING
        , NUMBER_OF_SYSTEM_MESSAGES_DURING_SELECTION
        , NUMBER_OF_SYSTEM_MESSAGES_DURING_COSTING
        , COSTING_STATUS
        , COST_ESTIMATE_RELEASE_DATE__YYYYMMDD
        , RELEASE_OF_STANDARD_COST_ESTIMATE
        , USER_WHO_RELEASED_COST_ESTIMATE
        , CURRENCY_KEY
        , FIXED_PRICE_CO_PRODUCT
        , BUSINESS_AREA
        , LOCAL_CURRENCY
        , COSTING_ADDITIVE_DATE__YYYYMMDD
        , COSTING_FROM_DATE__YYYYMMDD
        , COSTING_DATE__YYYYMMDD
        , COSTING_RUN_DATE__YYYYMMDD
        , NAME_OF_COSTING_RUN
        , COSTING_TYPE
        , COST_ESTIMATE_NUMBER
        , CE_NUMBER_FOR_PROCUREMENT_ALTERNATIVE
        , COSTING_SHEET_FOR_OVERHEAD
        , COSTING_LEVEL
        , TYPE_OF_COST_COMPONENT_SPLIT
        , COSTS_ENTERED_MANUALLY
        , INDICATOR_COSTS_ENTERED_MANUAL
        , INDICATOR_LOWER_LEVEL_COSTS
        , COSTING_VARIANT
        , CONTROLLING_AREA
        , OVERHEAD_GROUP
        , COST_COMPONENT_AMOUNT_001
        , COST_COMPONENT_AMOUNT_002
        , COST_COMPONENT_AMOUNT_003
        , COST_COMPONENT_AMOUNT_004
        , COST_COMPONENT_AMOUNT_005
        , COST_COMPONENT_AMOUNT_006
        , COST_COMPONENT_AMOUNT_007
        , COST_COMPONENT_AMOUNT_008
        , COST_COMPONENT_AMOUNT_009
        , COST_COMPONENT_AMOUNT_010
        , COST_COMPONENT_AMOUNT_011
        , COST_COMPONENT_AMOUNT_012
        , COST_COMPONENT_AMOUNT_013
        , COST_COMPONENT_AMOUNT_014
        , COST_COMPONENT_AMOUNT_015
        , COST_COMPONENT_AMOUNT_016
        , COST_COMPONENT_AMOUNT_017
        , COST_COMPONENT_AMOUNT_018
        , COST_COMPONENT_AMOUNT_019
        , COST_COMPONENT_AMOUNT_020
        , COST_COMPONENT_AMOUNT_021
        , COST_COMPONENT_AMOUNT_022
        , COST_COMPONENT_AMOUNT_023
        , COST_COMPONENT_AMOUNT_024
        , COST_COMPONENT_AMOUNT_025
        , COST_COMPONENT_AMOUNT_026
        , COST_COMPONENT_AMOUNT_027
        , COST_COMPONENT_AMOUNT_028
        , COST_COMPONENT_AMOUNT_029
        , COST_COMPONENT_AMOUNT_030
        , COST_COMPONENT_AMOUNT_031
        , COST_COMPONENT_AMOUNT_032
        , COST_COMPONENT_AMOUNT_033
        , COST_COMPONENT_AMOUNT_034
        , COST_COMPONENT_AMOUNT_035
        , COST_COMPONENT_AMOUNT_036
        , COST_COMPONENT_AMOUNT_037
        , COST_COMPONENT_AMOUNT_038
        , COST_COMPONENT_AMOUNT_039
        , COST_COMPONENT_AMOUNT_040
        , EXCHANGE_RATE_TYPE
        , MATERIAL_CAN_BE_CO_PRODUCT
        , MATERIAL_COMPONENT_INDICATOR
        , UNITS_OF_MEASURE_USAGE
        , DELETION_INDICATOR
        , LOT_SIZE_INCLUDING_SCRAP
        , LINK_FIELD_FOR_CURRENCY_TYPE
        , LOT_SIZE_FOR_PRODUCT_COSTING
        , HIGHEST_MESSAGE_TYPE
        , BATCH_SPECIFIC_UNIT_OF_MEASURE
        , BASE_UNIT_OF_MEASURE
        , QUANTITY_STRUCTURE_TYPE
        , MIXING_RATIO_FOR_MIXED_COSTING
        , MIXED_COSTING_INDICATOR
        , MATERIAL_LEDGER_ACTIVATED
        , OBJECT_NUMBER
        , OCS_MESSAGES_SENT
        , OBJECT_TYPE
        , PARTNER_VERSION
        , PARTNER_NUMBER
        , PRODUCTION_PLAN_QUANTITY
        , GROUP_COUNTER
        , INTERNAL_COUNTER_ROUTING
        , TASK_LIST_GROUP
        , TASK_LIST_TYPE
        , PLANNING_SCENARIO
        , POSTING_PERIOD
        , ITEM_NUMBER_IN_SD_DOCUMENT
        , PRODUCTION_VERSION_COSTED
        , PROFIT_CENTER
        , PROCESS_CO_PRODUCT_COSTING
        , WBS_ELEMENT
        , REFERENCE_VARIANT
        , SAP_RELEASE
        , DEPENDENT_REQUIREMENTS_INDICATOR
        , STOCK_SEGMENT
        , SPECIAL_PROCUREMENT_TYPE
        , SPECIAL_PROCUREMENT_KEY
        , VALUATION_TYPE_FOR_SPECIAL_PROCUREMENT
        , DIRECT_PRODUCTION_INDICATOR
        , PHANTOM_ITEM_INDICATOR
        , SPECIAL_PROCUREMENT_PLANT
        , ALTERNATIVE_BOM
        , INTERNAL_COUNTER_BOM
        , INTERNAL_COUNTER_FOR_COSTING
        , BOM_USAGE
        , BILL_OF_MATERIAL
        , SUBSTRATEGY_FOR_MATERIAL_VALUATION
        , SUM_OF_EQUIVALENCE_NUMBERS
        , PARAMETER_VARIANT
        , TEMPLATE
        , TOP_COST_ESTIMATE_FLAG
        , TRANSFER_PRICE_VARIANT
        , COSTING_VERSION
        , CONFIGURED_MATERIAL_TYPE
        , TRANSFER_CONTROL
        , SALES_AND_DISTRIBUTION_DOCUMENT_NUMBER
        , PRODUCTION_VERSION
        , COUNTER_FOR_MARKING_COST_ESTIMATE
        , COST_ESTIMATE_MARKED_DATE__YYYYMMDD
        , USER_WHO_MARKED_COST_ESTIMATE
        , PLANT_VARIANT
        , INTERNAL_COUNTER
        , EQUIVALENCE_NUMBER
        , OVERHEAD_KEY
        , FISCAL_PERIOD
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
