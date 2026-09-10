---- SRC LAYER ----
WITH
SRC_HUB            as ( SELECT ENTITY_HK, ENTITY_BK, BKCC, REC_SRC FROM {{ ref('hub_entity') }} as SRC  ),
SRC_SAT            as ( SELECT ENTITY_HK, MANDT, RCOMP, GLREQUEST, NAME1, CNTRY, NAME2, LANGU, STRET, POBOX, PSTLC, CITY, CURR, MODCP, GLSIP, RESTA, RFORM, ZWEIG, MCOMP, MCLNT, LCCOMP, STRT2, INDPO, GLDELFLAG, GLSOURCESYSTEM, GLCHANGETIME, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND 
                        FROM {{ ref('sat_entity__winn_sap') }} as SRC
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY ENTITY_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_HUB            as ( SELECT * FROM RAW_VAULT.hub_entity )
SRC_SAT            as ( SELECT * FROM RAW_VAULT.sat_entity__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_HUB as (
    SELECT
        ENTITY_HK
      , ENTITY_BK
      , BKCC
      , REC_SRC
    FROM SRC_HUB
)

, LOGIC_SAT as (
    SELECT
        ENTITY_HK                                                    as                                      SAT_ENTITY_HK
      , MANDT                                                        as                                             CLIENT
      , RCOMP                                                        as                                            COMPANY
      , GLREQUEST                                                    as                                       GLUE_REQUEST
      , NAME1                                                        as                                       COMPANY_NAME
      , CNTRY                                                        as                                 COUNTRY_OF_COMPANY
      , NAME2                                                        as                                     COMPANY_NAME_2
      , LANGU                                                        as                                       LANGUAGE_KEY
      , STRET                                                        as                             COMPANY_STREET_ADDRESS
      , POBOX                                                        as                            COMPANY_POST_OFFICE_BOX
      , PSTLC                                                        as                            GLOBAL_COMPANY_ZIP_CODE
      , CITY                                                         as                                       COMPANY_CITY
      , CURR                                                         as                                     LOCAL_CURRENCY
      , MODCP                                                        as                       GLOBAL_COMPANY_GROUPING_CODE
      , GLSIP                                                        as                                   WRITE_LINE_ITEMS
      , RESTA                                                        as                            LEGAL_STATUS_OF_COMPANY
      , RFORM                                                        as                              LEGAL_FORM_OF_COMPANY
      , ZWEIG                                                        as                                  INDUSTRIAL_SECTOR
      , MCOMP                                                        as                           MASTER_DATA_COMPANY_CODE
      , MCLNT                                                        as                                 MASTER_DATA_CLIENT
      , LCCOMP                                                       as                    CONSOLIDATION_COMPANY_INDICATOR
      , STRT2                                                        as                           COMPANY_STREET_ADDRESS_2
      , INDPO                                                        as                                READ_PURCHASE_ORDER
      , PSA_DELETE_IND
    FROM SRC_SAT
)
---- RENAME LAYER ----

, RENAME_HUB as (
    SELECT
        ENTITY_HK
      , ENTITY_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_HUB
)

, RENAME_SAT as (
    SELECT
        SAT_ENTITY_HK
      , CLIENT
      , COMPANY
      , GLUE_REQUEST
      , COMPANY_NAME
      , COUNTRY_OF_COMPANY
      , COMPANY_NAME_2
      , LANGUAGE_KEY
      , COMPANY_STREET_ADDRESS
      , COMPANY_POST_OFFICE_BOX
      , GLOBAL_COMPANY_ZIP_CODE
      , COMPANY_CITY
      , LOCAL_CURRENCY
      , GLOBAL_COMPANY_GROUPING_CODE
      , WRITE_LINE_ITEMS
      , LEGAL_STATUS_OF_COMPANY
      , LEGAL_FORM_OF_COMPANY
      , INDUSTRIAL_SECTOR
      , MASTER_DATA_COMPANY_CODE
      , MASTER_DATA_CLIENT
      , CONSOLIDATION_COMPANY_INDICATOR
      , COMPANY_STREET_ADDRESS_2
      , READ_PURCHASE_ORDER
      , PSA_DELETE_IND
    FROM LOGIC_SAT
)
---- FILTER LAYER ----

, FILTER_HUB as (
    SELECT *
    FROM RENAME_HUB
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_SAT as (
    SELECT *
    FROM RENAME_SAT
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HUB
    LEFT JOIN FILTER_SAT
        ON FILTER_HUB.ENTITY_HK = FILTER_SAT.SAT_ENTITY_HK
)

---- FINAL LAYER ----
SELECT
          'PIT_ENTITY'                                                 as PIT_REC_SRC
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PIT_LOAD_DTS
        , ENTITY_HK
        , ENTITY_BK
        , BKCC
        , REC_SRC
        , CLIENT
        , COMPANY
        , GLUE_REQUEST
        , COMPANY_NAME
        , COUNTRY_OF_COMPANY
        , COMPANY_NAME_2
        , LANGUAGE_KEY
        , COMPANY_STREET_ADDRESS
        , COMPANY_POST_OFFICE_BOX
        , GLOBAL_COMPANY_ZIP_CODE
        , COMPANY_CITY
        , LOCAL_CURRENCY
        , GLOBAL_COMPANY_GROUPING_CODE
        , WRITE_LINE_ITEMS
        , LEGAL_STATUS_OF_COMPANY
        , LEGAL_FORM_OF_COMPANY
        , INDUSTRIAL_SECTOR
        , MASTER_DATA_COMPANY_CODE
        , MASTER_DATA_CLIENT
        , CONSOLIDATION_COMPANY_INDICATOR
        , COMPANY_STREET_ADDRESS_2
        , READ_PURCHASE_ORDER
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND
          END as IS_DELETED
FROM JOIN_RESULT
