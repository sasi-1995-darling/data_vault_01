---- SRC LAYER ----
WITH
SRC_SRC_H          as ( SELECT OBJECT_NUMBER_HK, PROFIT_CENTER_BK, VALID_DATE_BK, CONTROLLING_AREA_BK, REC_SRC, BKCC FROM {{ ref('hub_profit_center_master_data') }} as SRC  ),
SRC_SRC_SAT        as ( SELECT OBJECT_NUMBER_HK, MANDT, PRCTR, DATBI, KOKRS, DATAB, ERSDA, USNAM, MERKMAL, ABTEI, VERAK, VERAK_USER, WAERS, NPRCTR, LAND1, ANRED, NAME1, NAME2, NAME3, NAME4, ORT01, ORT02, STRAS, PFACH, PSTLZ, PSTL2, SPRAS, TELBX, TELF1, TELF2, TELFX, TELTX, TELX1, DATLT, DRNAM, KHINR, BUKRS, VNAME, RECID, ETYPE, TXJCD, REGIO, KVEWE, KAPPL, KALSM, LOGSYSTEM, LOCK_IND, PCA_TEMPLATE, SEGMENT, PSA_DELETE_IND, REC_SRC FROM {{ ref('sat_profit_center_master_data__winn_sap') }} as SRC  ),
SRC_SRC_REF        as ( SELECT LANGUAGE_KEY, PROFIT_CENTER, VALID_TO_DATE__YYYYMMDD, CONTROLLING_AREA, GENERAL_NAME, LONG_TEXT, SEARCH_TERM_FOR_MATCHCODE_SEARCH FROM {{ ref('ref_profit_center_master_data_texts') }} as SRC  )

/*
SRC_SRC_H          as ( SELECT * FROM RAW_VAULT.hub_profit_center_master_data )
SRC_SRC_SAT        as ( SELECT * FROM RAW_VAULT.sat_profit_center_master_data__winn_sap )
SRC_SRC_REF        as ( SELECT * FROM BUS_VAULT.ref_profit_center_master_data_texts )
*/
---- LOGIC LAYER ----

, LOGIC_SRC_H as (
    SELECT
        OBJECT_NUMBER_HK
      , PROFIT_CENTER_BK
      , VALID_DATE_BK
      , CONTROLLING_AREA_BK
      , REC_SRC
      , BKCC
    FROM SRC_SRC_H
)

, LOGIC_SRC_SAT as (
    SELECT
        OBJECT_NUMBER_HK                                             as                               SAT_OBJECT_NUMBER_HK
      , MANDT                                                        as                                             CLIENT
      , PRCTR                                                        as                                      PROFIT_CENTER
      , CAST(DATBI AS INTEGER)                                       as                            VALID_TO_DATE__YYYYMMDD
      , KOKRS                                                        as                                   CONTROLLING_AREA
      , CAST(DATAB AS INTEGER)                                       as                          VALID_FROM_DATE__YYYYMMDD
      , CAST(ERSDA AS INTEGER)                                       as                          CREATED_ON_DATE__YYYYMMDD
      , USNAM                                                        as                                         ENTERED_BY
      , MERKMAL                                                      as                     COPA_CHARACTERISTIC_FIELD_NAME
      , CASE
            WHEN ABTEI = 'Eilmination' THEN 'Elimination'
            WHEN ABTEI IN ('Admin', 'Administrati') THEN 'Administration'
            WHEN ABTEI = 'FINANCE' THEN 'Finance' 
            ELSE ABTEI 
        END                                                          as                                         DEPARTMENT
      , VERAK                                                        as                   PROFIT_CENTER_RESPONSIBLE_PERSON
      , VERAK_USER                                                   as                     PROFIT_CENTER_RESPONSIBLE_USER
      , WAERS                                                        as                                       CURRENCY_KEY
      , NPRCTR                                                       as                            SUCCESSOR_PROFIT_CENTER
      , LAND1                                                        as                                        COUNTRY_KEY
      , ANRED                                                        as                                              TITLE
      , NAME1                                                        as                                             NAME_1
      , NAME2                                                        as                                             NAME_2
      , NAME3                                                        as                                             NAME_3
      , NAME4                                                        as                                             NAME_4
      , ORT01                                                        as                                               CITY
      , ORT02                                                        as                                           DISTRICT
      , STRAS                                                        as                            HOUSE_NUMBER_AND_STREET
      , PFACH                                                        as                                             PO_BOX
      , PSTLZ                                                        as                                        POSTAL_CODE
      , PSTL2                                                        as                                 PO_BOX_POSTAL_CODE
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , TELBX                                                        as                                     TELEBOX_NUMBER
      , TELF1                                                        as                             FIRST_TELEPHONE_NUMBER
      , TELF2                                                        as                            SECOND_TELEPHONE_NUMBER
      , TELFX                                                        as                                         FAX_NUMBER
      , TELTX                                                        as                                     TELETEX_NUMBER
      , TELX1                                                        as                                       TELEX_NUMBER
      , DATLT                                                        as                         DATA_COMMUNICATION_LINE_NO
      , DRNAM                                                        as                         PROFIT_CENTER_PRINTER_NAME
      , KHINR                                                        as                                 PROFIT_CENTER_AREA
      , BUKRS                                                        as                                       COMPANY_CODE
      , VNAME                                                        as                                      JOINT_VENTURE
      , RECID                                                        as                                 RECOVERY_INDICATOR
      , ETYPE                                                        as                                        EQUITY_TYPE
      , TXJCD                                                        as                                   TAX_JURISDICTION
      , REGIO                                                        as                                             REGION
      , KVEWE                                                        as                              CONDITION_TABLE_USAGE
      , KAPPL                                                        as                                        APPLICATION
      , KALSM                                                        as                                          PROCEDURE
      , LOGSYSTEM                                                    as                                     LOGICAL_SYSTEM
      , LOCK_IND
      , PCA_TEMPLATE                                                 as           PROFIT_CENTERS_FORMULA_PLANNING_TEMPLATE
      , SEGMENT                                                      as                    SEGMENT_FOR_SEGMENTAL_REPORTING
      , PSA_DELETE_IND
    FROM SRC_SRC_SAT
)

, LOGIC_SRC_REF as (
    SELECT
        LANGUAGE_KEY                                                 as                                   REF_LANGUAGE_KEY
      , PROFIT_CENTER                                                as                                  REF_PROFIT_CENTER
      , VALID_TO_DATE__YYYYMMDD                                      as                        REF_VALID_TO_DATE__YYYYMMDD
      , CONTROLLING_AREA                                             as                               REF_CONTROLLING_AREA
      , GENERAL_NAME
      , LONG_TEXT
      , SEARCH_TERM_FOR_MATCHCODE_SEARCH
    FROM SRC_SRC_REF
)
---- RENAME LAYER ----

, RENAME_SRC_H as (
    SELECT
        OBJECT_NUMBER_HK
      , PROFIT_CENTER_BK
      , VALID_DATE_BK
      , CONTROLLING_AREA_BK
      , REC_SRC
      , BKCC
    FROM LOGIC_SRC_H
)

, RENAME_SRC_SAT as (
    SELECT
        SAT_OBJECT_NUMBER_HK
      , CLIENT
      , PROFIT_CENTER
      , VALID_TO_DATE__YYYYMMDD
      , CONTROLLING_AREA
      , VALID_FROM_DATE__YYYYMMDD
      , CREATED_ON_DATE__YYYYMMDD
      , ENTERED_BY
      , COPA_CHARACTERISTIC_FIELD_NAME
      , DEPARTMENT
      , PROFIT_CENTER_RESPONSIBLE_PERSON
      , PROFIT_CENTER_RESPONSIBLE_USER
      , CURRENCY_KEY
      , SUCCESSOR_PROFIT_CENTER
      , COUNTRY_KEY
      , TITLE
      , NAME_1
      , NAME_2
      , NAME_3
      , NAME_4
      , CITY
      , DISTRICT
      , HOUSE_NUMBER_AND_STREET
      , PO_BOX
      , POSTAL_CODE
      , PO_BOX_POSTAL_CODE
      , LANGUAGE_KEY
      , TELEBOX_NUMBER
      , FIRST_TELEPHONE_NUMBER
      , SECOND_TELEPHONE_NUMBER
      , FAX_NUMBER
      , TELETEX_NUMBER
      , TELEX_NUMBER
      , DATA_COMMUNICATION_LINE_NO
      , PROFIT_CENTER_PRINTER_NAME
      , PROFIT_CENTER_AREA
      , COMPANY_CODE
      , JOINT_VENTURE
      , RECOVERY_INDICATOR
      , EQUITY_TYPE
      , TAX_JURISDICTION
      , REGION
      , CONDITION_TABLE_USAGE
      , APPLICATION
      , PROCEDURE
      , LOGICAL_SYSTEM
      , LOCK_IND
      , PROFIT_CENTERS_FORMULA_PLANNING_TEMPLATE
      , SEGMENT_FOR_SEGMENTAL_REPORTING
      , PSA_DELETE_IND
    FROM LOGIC_SRC_SAT
)

, RENAME_SRC_REF as (
    SELECT
        REF_LANGUAGE_KEY
      , REF_PROFIT_CENTER
      , REF_VALID_TO_DATE__YYYYMMDD
      , REF_CONTROLLING_AREA
      , GENERAL_NAME
      , LONG_TEXT
      , SEARCH_TERM_FOR_MATCHCODE_SEARCH
    FROM LOGIC_SRC_REF
)
---- FILTER LAYER ----

, FILTER_SRC_H as (
    SELECT *
    FROM RENAME_SRC_H
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_SRC_SAT as (
    SELECT *
    FROM RENAME_SRC_SAT
)

, FILTER_SRC_REF as (
    SELECT *
    FROM RENAME_SRC_REF
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SRC_H
    LEFT JOIN FILTER_SRC_SAT
        ON FILTER_SRC_H.OBJECT_NUMBER_HK = FILTER_SRC_SAT.SAT_OBJECT_NUMBER_HK
    LEFT JOIN FILTER_SRC_REF
        ON FILTER_SRC_SAT.LANGUAGE_KEY = FILTER_SRC_REF.REF_LANGUAGE_KEY
        AND FILTER_SRC_H.PROFIT_CENTER_BK = FILTER_SRC_REF.REF_PROFIT_CENTER
        AND FILTER_SRC_H.VALID_DATE_BK = FILTER_SRC_REF.REF_VALID_TO_DATE__YYYYMMDD
        AND FILTER_SRC_H.CONTROLLING_AREA_BK = FILTER_SRC_REF.REF_CONTROLLING_AREA
)

---- FINAL LAYER ----
SELECT
          'PIT_PROFIT_CENTER'                                          as PIT_REC_SRC
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PIT_LOAD_DTS
        , OBJECT_NUMBER_HK
        , REC_SRC
        , BKCC
        , CLIENT
        , PROFIT_CENTER
        , VALID_TO_DATE__YYYYMMDD
        , CONTROLLING_AREA
        , VALID_FROM_DATE__YYYYMMDD
        , CREATED_ON_DATE__YYYYMMDD
        , ENTERED_BY
        , COPA_CHARACTERISTIC_FIELD_NAME
        , DEPARTMENT
        , PROFIT_CENTER_RESPONSIBLE_PERSON
        , PROFIT_CENTER_RESPONSIBLE_USER
        , CURRENCY_KEY
        , SUCCESSOR_PROFIT_CENTER
        , COUNTRY_KEY
        , TITLE
        , NAME_1
        , NAME_2
        , NAME_3
        , NAME_4
        , CITY
        , DISTRICT
        , HOUSE_NUMBER_AND_STREET
        , PO_BOX
        , POSTAL_CODE
        , PO_BOX_POSTAL_CODE
        , LANGUAGE_KEY
        , TELEBOX_NUMBER
        , FIRST_TELEPHONE_NUMBER
        , SECOND_TELEPHONE_NUMBER
        , FAX_NUMBER
        , TELETEX_NUMBER
        , TELEX_NUMBER
        , DATA_COMMUNICATION_LINE_NO
        , PROFIT_CENTER_PRINTER_NAME
        , PROFIT_CENTER_AREA
        , COMPANY_CODE
        , JOINT_VENTURE
        , RECOVERY_INDICATOR
        , EQUITY_TYPE
        , TAX_JURISDICTION
        , REGION
        , CONDITION_TABLE_USAGE
        , APPLICATION
        , PROCEDURE
        , LOGICAL_SYSTEM
        , LOCK_IND
        , PROFIT_CENTERS_FORMULA_PLANNING_TEMPLATE
        , SEGMENT_FOR_SEGMENTAL_REPORTING
        , GENERAL_NAME
        , LONG_TEXT
        , SEARCH_TERM_FOR_MATCHCODE_SEARCH
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND END        as IS_DELETED
FROM JOIN_RESULT
