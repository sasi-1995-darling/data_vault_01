{{
  config(
    materialized = 'incremental',
    unique_key='COST_TOTALS_FOR_POSTINGS_HK',
    incremental_strategy= 'merge'
  )
}}

---- SRC LAYER ----
-- Introduced POSTING_TYPE to differentiate between external & internal postings --
WITH
-- External Postings Sources
SRC_L_EXTERNAL          as ( SELECT COST_TOTALS_FOR_EXTERNAL_POSTINGS_HK, OBJECT_NUMBER_HK , COST_ELEMENT_HK, COST_VALUE_TYPE_HK, COST_VERSION_HK, ORIGIN_GROUP_HK, LEDGER_HK, REC_SRC 
                            FROM {{ ref('lnk_cost_totals_for_external_postings') }} as SRC ),
SRC_SAT_EXTERNAL        as ( SELECT COST_TOTALS_FOR_EXTERNAL_POSTINGS_HK, LEDNR, OBJNR , GJAHR , WRTTP , VERSN , KSTAR , HRKFT , VRGNG , VBUND , PARGB , BEKNZ , TWAER , PERBL, MEINH, BUKRS, FKBER, SEGMENT, GEBER, GRANT_NBR, WTG001, WTG002, WTG003, WTG004, WTG005, WTG006, WTG007, WTG008, WTG009, WTG010, WTG011, WTG012, WOG001, WOG002, WOG003, WOG004, WOG005, WOG006, WOG007, WOG008, WOG009, WOG010, WOG011, WOG012, WKG001, WKG002, WKG003, WKG004, WKG005, WKG006, WKG007, WKG008, WKG009, WKG010, WKG011, WKG012, WKF001, WKF002, WKF003, WKF004, WKF005, WKF006, WKF007, WKF008, WKF009, WKF010, WKF011, WKF012, PAG001, PAG002, PAG003, PAG004, PAG005, PAG006, PAG007, PAG008, PAG009, PAG010, PAG011, PAG012, MEG001, MEG002, MEG003, MEG004, MEG005, MEG006, MEG007, MEG008, MEG009, MEG010, MEG011, MEG012, MEF001, MEF002, MEF003, MEF004, MEF005, MEF006, MEF007, MEF008, MEF009, MEF010, MEF011, MEF012, MUV001, MUV002, MUV003, MUV004, MUV005, MUV006, MUV007, MUV008, MUV009, MUV010, MUV011, MUV012, BKCC, PSA_DELETE_IND
                           FROM {{ ref('sat_cost_totals_for_external_postings__winn_sap') }}
                           QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY COST_TOTALS_FOR_EXTERNAL_POSTINGS_HK ORDER BY LOAD_DTS DESC) ),
-- Internal Postings Sources
SRC_L_INTERNAL          as ( SELECT COST_TOTAL_FOR_INTERNAL_POSTINGS_HK, OBJECT_NUMBER_HK , COST_ELEMENT_HK, COST_VALUE_TYPE_HK, COST_VERSION_HK, ORIGIN_GROUP_HK, LEDGER_HK, REC_SRC 
                            FROM {{ ref('lnk_cost_total_for_internal_postings') }} as SRC),
SRC_SAT_INTERNAL        as ( SELECT COST_TOTAL_FOR_INTERNAL_POSTINGS_HK, LEDNR, OBJNR, GJAHR, WRTTP, VERSN, KSTAR, HRKFT, VRGNG, PAROB, USPOB, BEKNZ, TWAER, PERBL, MEINH, BUKRS, FKBER, SEGMENT, GEBER, GRANT_NBR, WTG001, WTG002, WTG003, WTG004, WTG005, WTG006, WTG007, WTG008, WTG009, WTG010, WTG011, WTG012, WOG001, WOG002, WOG003, WOG004, WOG005, WOG006, WOG007, WOG008, WOG009, WOG010, WOG011, WOG012, WKG001, WKG002, WKG003, WKG004, WKG005, WKG006, WKG007, WKG008, WKG009, WKG010, WKG011, WKG012, WKF001, WKF002, WKF003, WKF004, WKF005, WKF006, WKF007, WKF008, WKF009, WKF010, WKF011, WKF012, PAG001, PAG002, PAG003, PAG004, PAG005, PAG006, PAG007, PAG008, PAG009, PAG010, PAG011, PAG012, MEG001, MEG002, MEG003, MEG004, MEG005, MEG006, MEG007, MEG008, MEG009, MEG010, MEG011, MEG012, MEF001, MEF002, MEF003, MEF004, MEF005, MEF006, MEF007, MEF008, MEF009, MEF010, MEF011, MEF012, MUV001, MUV002, MUV003, MUV004, MUV005, MUV006, MUV007, MUV008, MUV009, MUV010, MUV011, MUV012, BKCC, PSA_DELETE_IND
                           FROM {{ ref('lsat_cost_total_for_internal_postings__winn_sap') }}
                           QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY COST_TOTAL_FOR_INTERNAL_POSTINGS_HK ORDER BY LOAD_DTS DESC) ),
SRC_Hco            		as ( SELECT  OBJECT_NUMBER_HK, REC_SRC      FROM {{ ref('hub_cost_object') }} as SRC  ),
SRC_Hcvt           		as ( SELECT  COST_VALUE_TYPE_HK, REC_SRC  FROM {{ ref('hub_cost_value_type') }} as SRC  ),
SRC_Hcv            		as ( SELECT  COST_VERSION_HK, REC_SRC     FROM {{ ref('hub_cost_version') }} as SRC  ),
SRC_Hog            		as ( SELECT  ORIGIN_GROUP_HK, REC_SRC     FROM {{ ref('hub_origin_group') }} as SRC  ),
SRC_Hce            		as ( SELECT  COST_ELEMENT_HK, REC_SRC     FROM {{ ref('hub_cost_element') }} as SRC  ),
SRC_Hl             		as ( SELECT  LEDGER_HK, REC_SRC           FROM {{ ref('hub_ledger') }} as SRC  )

---- LOGIC LAYER ----

, LOGIC_L_EXTERNAL AS (
    SELECT 
        'PB_ACCOUNT_BALANCE' AS PB_REC_SRC
      , CURRENT_DATE AS SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP) AS PB_LOAD_DTS
      , COST_TOTALS_FOR_EXTERNAL_POSTINGS_HK
      , OBJECT_NUMBER_HK 
      , COST_ELEMENT_HK
      , COST_VALUE_TYPE_HK
      , COST_VERSION_HK
      , ORIGIN_GROUP_HK
      , LEDGER_HK
      , REC_SRC
    FROM SRC_L_EXTERNAL
)
, LOGIC_L_INTERNAL AS (
    SELECT 
        'PB_ACCOUNT_BALANCE' AS PB_REC_SRC
      , CURRENT_DATE AS SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP) AS PB_LOAD_DTS
      , COST_TOTAL_FOR_INTERNAL_POSTINGS_HK
      , OBJECT_NUMBER_HK
      , COST_ELEMENT_HK
      , COST_VALUE_TYPE_HK
      , COST_VERSION_HK
      , ORIGIN_GROUP_HK
      , LEDGER_HK
      , REC_SRC
    FROM SRC_L_INTERNAL
)
, LOGIC_SAT_EXTERNAL AS (
    SELECT 
        COST_TOTALS_FOR_EXTERNAL_POSTINGS_HK                                                                         AS SAT_WINN__COST_TOTALS_FOR_POSTINGS_HK
        , 'EXTERNAL'                                                                                                    AS POSTING_TYPE
        , LEDNR																											AS LEDGER
        , OBJNR   																										AS OBJECT_NUMBER                      
        , CAST(GJAHR AS INTEGER)																                        AS FISCAL_YEAR__YYYY                    
        , WRTTP   																										AS COST_VALUE_TYPE                    
        , VERSN   																										AS COST_VERSION                      
        , KSTAR   																										AS COST_ELEMENT                      
        , TRIM(HRKFT)   																								AS ORIGIN_GROUP                      
        , VRGNG   																										AS COST_BUSINESS_TRANSACTION_TYPE                      
        , VBUND   																										AS LEGAL_ENTITY                      
        , PARGB   																										AS TRADING_PARTNER_BUSINESS_AREA                     
        , BEKNZ   																										AS DEBIT_CREDIT_INDICATOR                      
        , TWAER   																										AS CURRENCY                      
        , PERBL																		    								AS PERIOD_BLOCK		
        , NULL                                                                                                           AS PARTNER_OBJECT
        , NULL                                                                                                           AS ORIGIN_OBJECT
        , MEINH                                                                                                          AS BASE_UNIT_OF_MEASURE
        , BUKRS                                                                                                          AS COMPANY_CODE
        , FKBER                                                                                                          AS FUNCTIONAL_AREA
        , SEGMENT
        , GEBER                                                                                                          AS FUND
        , GRANT_NBR
        , WTG001                                                                                                         
        , WTG002  
        , WTG003
        , WTG004
        , WTG005
        , WTG006
        , WTG007
        , WTG008
        , WTG009
        , WTG010
        , WTG011
        , WTG012                                                                                                       
        , WOG001
        , WOG002  
        , WOG003
        , WOG004
        , WOG005
        , WOG006
        , WOG007
        , WOG008
        , WOG009
        , WOG010
        , WOG011
        , WOG012
        , WKG001
        , WKG002
        , WKG003
        , WKG004
        , WKG005
        , WKG006
        , WKG007
        , WKG008
        , WKG009
        , WKG010
        , WKG011
        , WKG012
        , WKF001 
        , WKF002
        , WKF003 
        , WKF004
        , WKF005
        , WKF006
        , WKF007
        , WKF008
        , WKF009
        , WKF010
        , WKF011
        , WKF012
        , PAG001
        , PAG002
        , PAG003
        , PAG004
        , PAG005
        , PAG006
        , PAG007
        , PAG008
        , PAG009
        , PAG010
        , PAG011
        , PAG012
        , MEG001
        , MEG002
        , MEG003
        , MEG004
        , MEG005
        , MEG006
        , MEG007
        , MEG008
        , MEG009
        , MEG010
        , MEG011
        , MEG012
        , MEF001
        , MEF002
        , MEF003
        , MEF004
        , MEF005
        , MEF006
        , MEF007
        , MEF008
        , MEF009
        , MEF010
        , MEF011
        , MEF012
        , MUV001
        , MUV002
        , MUV003
        , MUV004
        , MUV005
        , MUV006
        , MUV007
        , MUV008
        , MUV009
        , MUV010
        , MUV011
        , MUV012
        , BKCC
        , PSA_DELETE_IND
    FROM SRC_SAT_EXTERNAL
)
, LOGIC_SAT_INTERNAL AS (
    SELECT 
        COST_TOTAL_FOR_INTERNAL_POSTINGS_HK                                                                          AS SAT_WINN__COST_TOTALS_FOR_POSTINGS_HK
        , 'INTERNAL'                                                                                                     AS POSTING_TYPE
        , LEDNR                                                                                                          AS LEDGER
        , OBJNR                                                                                                          AS OBJECT_NUMBER
        , CAST(GJAHR AS INTEGER)                                                                                         AS FISCAL_YEAR__YYYY
        , WRTTP                                                                                                          AS COST_VALUE_TYPE
        , VERSN                                                                                                          AS COST_VERSION
        , KSTAR                                                                                                          AS COST_ELEMENT
        , TRIM(HRKFT)                                                                                                    AS ORIGIN_GROUP
        , VRGNG                                                                                                          AS COST_BUSINESS_TRANSACTION_TYPE
        , NULL                                                                                                           AS LEGAL_ENTITY
        , NULL                                                                                                           AS TRADING_PARTNER_BUSINESS_AREA
        , BEKNZ                                                                                                          AS DEBIT_CREDIT_INDICATOR
        , TWAER                                                                                                          AS CURRENCY
        , PERBL                                                                                                          AS PERIOD_BLOCK
        , PAROB                                                                                                          AS PARTNER_OBJECT
        , USPOB                                                                                                          AS ORIGIN_OBJECT	
        , MEINH                                                                                                          AS BASE_UNIT_OF_MEASURE                                     
        , BUKRS                                                                                                          AS COMPANY_CODE
        , FKBER                                                                                                          AS FUNCTIONAL_AREA
        , SEGMENT
        , GEBER                                                                                                          AS FUND
        , GRANT_NBR
		, WTG001                                                                                                         
        , WTG002
        , WTG003
        , WTG004
        , WTG005
        , WTG006
        , WTG007
        , WTG008
        , WTG009
        , WTG010
        , WTG011
        , WTG012                                                                                                       
        , WOG001
        , WOG002  
        , WOG003
        , WOG004
        , WOG005
        , WOG006
        , WOG007
        , WOG008
        , WOG009
        , WOG010
        , WOG011
        , WOG012
        , WKG001
        , WKG002
        , WKG003
        , WKG004
        , WKG005
        , WKG006
        , WKG007
        , WKG008
        , WKG009
        , WKG010
        , WKG011
        , WKG012
        , WKF001 
        , WKF002
        , WKF003 
        , WKF004
        , WKF005
        , WKF006
        , WKF007
        , WKF008
        , WKF009
        , WKF010
        , WKF011
        , WKF012
        , PAG001
        , PAG002
        , PAG003
        , PAG004
        , PAG005
        , PAG006
        , PAG007
        , PAG008
        , PAG009
        , PAG010
        , PAG011
        , PAG012
        , MEG001
        , MEG002
        , MEG003
        , MEG004
        , MEG005
        , MEG006
        , MEG007
        , MEG008
        , MEG009
        , MEG010
        , MEG011
        , MEG012
        , MEF001
        , MEF002
        , MEF003
        , MEF004
        , MEF005
        , MEF006
        , MEF007
        , MEF008
        , MEF009
        , MEF010
        , MEF011
        , MEF012
        , MUV001
        , MUV002
        , MUV003
        , MUV004
        , MUV005
        , MUV006
        , MUV007
        , MUV008
        , MUV009
        , MUV010
        , MUV011
        , MUV012
        , BKCC
        , PSA_DELETE_IND
    FROM SRC_SAT_INTERNAL
)
, LOGIC_Hco as (
    SELECT
        OBJECT_NUMBER_HK
    FROM SRC_Hco
)
, LOGIC_Hcvt as (
    SELECT
        COST_VALUE_TYPE_HK
    FROM SRC_Hcvt
)
, LOGIC_Hcv as (
    SELECT
        COST_VERSION_HK
	FROM SRC_Hcv
)
, LOGIC_Hog as (
    SELECT
        ORIGIN_GROUP_HK
	FROM SRC_Hog
)
, LOGIC_Hce as (
    SELECT
       COST_ELEMENT_HK
    FROM SRC_Hce
)
, LOGIC_Hl as (
    SELECT
       LEDGER_HK
    FROM SRC_Hl
)

---- RENAME & FILTER LAYERS ----
, RENAME_L_EXTERNAL AS (
    SELECT 
        PB_REC_SRC
      , SNAPSHOTDATE
      , PB_LOAD_DTS
      , COST_TOTALS_FOR_EXTERNAL_POSTINGS_HK                                                         AS COST_TOTALS_FOR_POSTINGS_HK
      , OBJECT_NUMBER_HK 
      , COST_ELEMENT_HK
      , COST_VALUE_TYPE_HK
      , COST_VERSION_HK
      , ORIGIN_GROUP_HK
      , LEDGER_HK
      , REC_SRC
    FROM LOGIC_L_EXTERNAL
)
, RENAME_L_INTERNAL AS (
    SELECT 
        PB_REC_SRC
      , SNAPSHOTDATE
      , PB_LOAD_DTS
      , COST_TOTAL_FOR_INTERNAL_POSTINGS_HK                                                         AS COST_TOTALS_FOR_POSTINGS_HK
      , OBJECT_NUMBER_HK 
      , COST_ELEMENT_HK
      , COST_VALUE_TYPE_HK
      , COST_VERSION_HK
      , ORIGIN_GROUP_HK
      , LEDGER_HK
      , REC_SRC
    FROM LOGIC_L_INTERNAL
)
, RENAME_SAT_EXTERNAL AS (
    SELECT *
    FROM LOGIC_SAT_EXTERNAL
)
, RENAME_SAT_INTERNAL AS (
    SELECT *
    FROM LOGIC_SAT_INTERNAL
)
, RENAME_Hl as (
    SELECT
        LEDGER_HK															AS Hl_LEDGER_HK
    FROM LOGIC_Hl
)
, RENAME_Hco as (
    SELECT
        OBJECT_NUMBER_HK													AS Hco_OBJECT_NUMBER_HK														
    FROM LOGIC_Hco
)
, RENAME_Hcvt as (
    SELECT
        COST_VALUE_TYPE_HK													AS Hcvt_COST_VALUE_TYPE_HK
    FROM LOGIC_Hcvt
)
, RENAME_Hcv as (
    SELECT
        COST_VERSION_HK														AS Hcv_COST_VERSION_HK
    FROM LOGIC_Hcv
)
, RENAME_Hce as (
    SELECT
        COST_ELEMENT_HK														AS Hce_COST_ELEMENT_HK
    FROM LOGIC_Hce
)
, RENAME_Hog as (
    SELECT
        ORIGIN_GROUP_HK														AS Hog_ORIGIN_GROUP_HK
    FROM LOGIC_Hog
)

---- FILTER LAYER ----
, FILTER_L_EXTERNAL AS (
    SELECT *
    FROM RENAME_L_EXTERNAL
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'                            /* This filter is to exclude the ghost records */
)
, FILTER_L_INTERNAL AS (
    SELECT *
    FROM RENAME_L_INTERNAL
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'                            /* This filter is to exclude the ghost records */
)
, FILTER_SAT_EXTERNAL AS (
    SELECT *
    FROM RENAME_SAT_EXTERNAL
)
, FILTER_SAT_INTERNAL AS (
    SELECT *
    FROM RENAME_SAT_INTERNAL
)
, FILTER_Hco as (
    SELECT *
    FROM RENAME_Hco    
)
, FILTER_Hcvt as (
    SELECT *
    FROM RENAME_Hcvt
)
, FILTER_Hcv as (
    SELECT *
    FROM RENAME_Hcv   
)
, FILTER_Hog as (
    SELECT *
    FROM RENAME_Hog 
)
, FILTER_Hce as (
    SELECT *
    FROM RENAME_Hce  
)
, FILTER_Hl as (
    SELECT *
    FROM RENAME_Hl  
)


---- JOIN & UNION LAYER ----
, JOIN_EXTERNAL as (
    SELECT *
    FROM FILTER_L_EXTERNAL LE
	LEFT JOIN FILTER_Hco Hco ON LE.OBJECT_NUMBER_HK = Hco.Hco_OBJECT_NUMBER_HK
	LEFT JOIN FILTER_Hcvt Hcvt ON LE.COST_VALUE_TYPE_HK = Hcvt.Hcvt_COST_VALUE_TYPE_HK
    LEFT JOIN FILTER_Hcv Hcv ON LE.COST_VERSION_HK = Hcv.Hcv_COST_VERSION_HK
    LEFT JOIN FILTER_Hog Hog ON LE.ORIGIN_GROUP_HK = Hog.Hog_ORIGIN_GROUP_HK
    LEFT JOIN FILTER_Hce Hce ON LE.COST_ELEMENT_HK = Hce.Hce_COST_ELEMENT_HK
    LEFT JOIN FILTER_Hl Hl ON LE.LEDGER_HK = Hl.Hl_LEDGER_HK
    LEFT JOIN FILTER_SAT_EXTERNAL ON LE.COST_TOTALS_FOR_POSTINGS_HK = FILTER_SAT_EXTERNAL.SAT_WINN__COST_TOTALS_FOR_POSTINGS_HK
)
, JOIN_INTERNAL as (
    SELECT *
    FROM FILTER_L_INTERNAL LI 
	LEFT JOIN FILTER_Hco Hco ON LI.OBJECT_NUMBER_HK = Hco.Hco_OBJECT_NUMBER_HK
	LEFT JOIN FILTER_Hcvt Hcvt ON LI.COST_VALUE_TYPE_HK = Hcvt.Hcvt_COST_VALUE_TYPE_HK
    LEFT JOIN FILTER_Hcv Hcv ON LI.COST_VERSION_HK = Hcv.Hcv_COST_VERSION_HK
    LEFT JOIN FILTER_Hog Hog ON LI.ORIGIN_GROUP_HK = Hog.Hog_ORIGIN_GROUP_HK
    LEFT JOIN FILTER_Hce Hce ON LI.COST_ELEMENT_HK = Hce.Hce_COST_ELEMENT_HK
    LEFT JOIN FILTER_Hl Hl ON LI.LEDGER_HK = Hl.Hl_LEDGER_HK
    LEFT JOIN FILTER_SAT_INTERNAL  ON LI.COST_TOTALS_FOR_POSTINGS_HK = FILTER_SAT_INTERNAL.SAT_WINN__COST_TOTALS_FOR_POSTINGS_HK
)
, UNION_ALL_RESULTS as (
    SELECT * FROM JOIN_EXTERNAL
    UNION ALL
    SELECT * FROM JOIN_INTERNAL
)

-- FINAL LAYER ----
SELECT
      PB_REC_SRC
    , SNAPSHOTDATE
    , PB_LOAD_DTS
    , COST_TOTALS_FOR_POSTINGS_HK 
    , POSTING_TYPE
	, LEDGER_HK
	, OBJECT_NUMBER_HK
	, COST_VALUE_TYPE_HK
	, COST_VERSION_HK
	, COST_ELEMENT_HK
	, ORIGIN_GROUP_HK
    , LEDGER
    , OBJECT_NUMBER
    , COALESCE(FISCAL_YEAR__YYYY, 1900)                                         AS                                  FISCAL_YEAR__YYYY
    , COST_VALUE_TYPE
    , COST_VERSION
    , COST_ELEMENT
    , ORIGIN_GROUP
    , COST_BUSINESS_TRANSACTION_TYPE
    , LEGAL_ENTITY
    , TRADING_PARTNER_BUSINESS_AREA
    , PARTNER_OBJECT
    , ORIGIN_OBJECT
    , DEBIT_CREDIT_INDICATOR
    , CURRENCY
    , PERIOD_BLOCK
    , BASE_UNIT_OF_MEASURE
    , COMPANY_CODE
    , FUNCTIONAL_AREA
    , SEGMENT
    , FUND
    , GRANT_NBR
    , (COALESCE(FISCAL_YEAR__YYYY, 1900) || F.VALUE:MO::VARCHAR)::INTEGER       AS                               FISCAL_MONTH__YYYYMM
    , F.VALUE:WTG::NUMBER(23,4)                                                 AS                   TOTAL_VALUE_TRANSACTION_CURRENCY
	, F.VALUE:WOG::NUMBER(23,4)                                                 AS                           TOTAL_VALUE_OBJ_CURRENCY
	, F.VALUE:WKG::NUMBER(23,4)                                                 AS              TOTAL_VALUE_CONTROLLING_AREA_CURRENCY
	, F.VALUE:WKF::NUMBER(23,4)                                                 AS              FIXED_VALUE_CONTROLLING_AREA_CURRENCY
	, F.VALUE:PAG::NUMBER(23,4)                                                 AS              TOTAL_PRICE_VARIANCE_CO_AREA_CURRENCY
	, F.VALUE:MEG::NUMBER(15,4)                                                 AS                                          TOTAL_QTY
	, F.VALUE:MEF::NUMBER(15,4)                                                 AS                                          FIXED_QTY
    , CASE WHEN NULLIF(F.VALUE:MUV, '') = 'X' THEN 'YES' ELSE 'NO' END          AS                                     QTY_INCOMPLETE
    , BKCC
    , REC_SRC
    , CASE WHEN BKCC = 'Hiding_Tiger' THEN PSA_DELETE_IND END as IS_DELETED
FROM UNION_ALL_RESULTS,
LATERAL FLATTEN(input => ARRAY_CONSTRUCT(
    OBJECT_CONSTRUCT('MO', '01', 'WTG', WTG001, 'WOG', WOG001, 'WKG', WKG001, 'WKF', WKF001, 'PAG', PAG001, 'MEG', MEG001, 'MEF', MEF001, 'MUV', MUV001 ),
    OBJECT_CONSTRUCT('MO', '02', 'WTG', WTG002, 'WOG', WOG002, 'WKG', WKG002, 'WKF', WKF002, 'PAG', PAG002, 'MEG', MEG002, 'MEF', MEF002, 'MUV', MUV002 ),
    OBJECT_CONSTRUCT('MO', '03', 'WTG', WTG003, 'WOG', WOG003, 'WKG', WKG003, 'WKF', WKF003, 'PAG', PAG003, 'MEG', MEG003, 'MEF', MEF003, 'MUV', MUV003 ),
    OBJECT_CONSTRUCT('MO', '04', 'WTG', WTG004, 'WOG', WOG004, 'WKG', WKG004, 'WKF', WKF004, 'PAG', PAG004, 'MEG', MEG004, 'MEF', MEF004, 'MUV', MUV004 ),
    OBJECT_CONSTRUCT('MO', '05', 'WTG', WTG005, 'WOG', WOG005, 'WKG', WKG005, 'WKF', WKF005, 'PAG', PAG005, 'MEG', MEG005, 'MEF', MEF005, 'MUV', MUV005 ),
    OBJECT_CONSTRUCT('MO', '06', 'WTG', WTG006, 'WOG', WOG006, 'WKG', WKG006, 'WKF', WKF006, 'PAG', PAG006, 'MEG', MEG006, 'MEF', MEF006, 'MUV', MUV006 ),
    OBJECT_CONSTRUCT('MO', '07', 'WTG', WTG007, 'WOG', WOG007, 'WKG', WKG007, 'WKF', WKF007, 'PAG', PAG007, 'MEG', MEG007, 'MEF', MEF007, 'MUV', MUV007 ),
    OBJECT_CONSTRUCT('MO', '08', 'WTG', WTG008, 'WOG', WOG008, 'WKG', WKG008, 'WKF', WKF008, 'PAG', PAG008, 'MEG', MEG008, 'MEF', MEF008, 'MUV', MUV008 ),
    OBJECT_CONSTRUCT('MO', '09', 'WTG', WTG009, 'WOG', WOG009, 'WKG', WKG009, 'WKF', WKF009, 'PAG', PAG009, 'MEG', MEG009, 'MEF', MEF009, 'MUV', MUV009 ),
    OBJECT_CONSTRUCT('MO', '10', 'WTG', WTG010, 'WOG', WOG010, 'WKG', WKG010, 'WKF', WKF010, 'PAG', PAG010, 'MEG', MEG010, 'MEF', MEF010, 'MUV', MUV010 ),
    OBJECT_CONSTRUCT('MO', '11', 'WTG', WTG011, 'WOG', WOG011, 'WKG', WKG011, 'WKF', WKF011, 'PAG', PAG011, 'MEG', MEG011, 'MEF', MEF011, 'MUV', MUV011 ),
    OBJECT_CONSTRUCT('MO', '12', 'WTG', WTG012, 'WOG', WOG012, 'WKG', WKG012, 'WKF', WKF012, 'PAG', PAG012, 'MEG', MEG012, 'MEF', MEF012, 'MUV', MUV012 )
)) f
{% if is_incremental() %}
    WHERE COST_TOTALS_FOR_POSTINGS_HK NOT IN (
        SELECT COST_TOTALS_FOR_POSTINGS_HK 
        FROM {{ this }}
    )
    AND PERIOD_BLOCK >= DATE_TRUNC('day', CURRENT_DATE() - 60)
{% endif %}