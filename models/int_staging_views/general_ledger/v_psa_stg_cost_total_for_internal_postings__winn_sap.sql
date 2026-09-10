---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_coss') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_coss )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
      MANDT
      , LEDNR
      , OBJNR
      , GJAHR
      , WRTTP
      , VERSN
      , KSTAR
      , HRKFT
      , VRGNG
      , PAROB
      , USPOB
      , BEKNZ
      , TWAER
      , PERBL
      , GLREQUEST
      , MEINH
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
      , WTG013
      , WTG014
      , WTG015
      , WTG016
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
      , WOG013
      , WOG014
      , WOG015
      , WOG016
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
      , WKG013
      , WKG014
      , WKG015
      , WKG016
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
      , WKF013
      , WKF014
      , WKF015
      , WKF016
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
      , PAG013
      , PAG014
      , PAG015
      , PAG016
      , PAF001
      , PAF002
      , PAF003
      , PAF004
      , PAF005
      , PAF006
      , PAF007
      , PAF008
      , PAF009
      , PAF010
      , PAF011
      , PAF012
      , PAF013
      , PAF014
      , PAF015
      , PAF016
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
      , MEG013
      , MEG014
      , MEG015
      , MEG016
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
      , MEF013
      , MEF014
      , MEF015
      , MEF016
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
      , MUV013
      , MUV014
      , MUV015
      , MUV016
      , BELTP
      , TIMESTMP
      , BUKRS
      , FKBER
      , SEGMENT
      , GEBER
      , GRANT_NBR
      , BUDGET_PD
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', IFF(
          PSA_DELETE_IND = 'Y', 
          PSA_LOAD_DTS,  
          TO_TIMESTAMP(
              SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
              SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
              SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
              SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
              REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
              'YYYYMMDD HH24:MI:SS.FF9'
              )
              ))   as                                    LOAD_DTS
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
       coalesce(nullif(trim(MANDT), ''), '-1')                               as                                          CLIENT_BK
      , coalesce(nullif(trim(LEDNR), ''), '-1')                              as                                          LEDGER_BK
      , coalesce(nullif(trim(OBJNR), ''), '-1')                              as                                   OBJECT_NUMBER_BK
      , coalesce(nullif(trim(GJAHR), ''), '-1')                              as                                     FISCAL_YEAR_BK
      , coalesce(nullif(trim(WRTTP), ''), '-1')                              as                                 COST_VALUE_TYPE_BK
      , coalesce(nullif(trim(VERSN), ''), '-1')                              as                                    COST_VERSION_BK
      , coalesce(nullif(trim(KSTAR), ''), '-1')                              as                                    COST_ELEMENT_BK
      , coalesce(nullif(trim(VRGNG), ''), '-1')                              as                           COST_TRANSACTION_TYPE_BK
      , coalesce(nullif(trim(PAROB), ''), '-1')                              as                                  PARTNER_OBJECT_BK
      , coalesce(nullif(trim(USPOB), ''), '-1')                              as                                   SOURCE_OBJECT_BK
      , coalesce(nullif(trim(BEKNZ), ''), '-1')                              as                          DEBIT_CREDIT_INDICATOR_BK
      , coalesce(nullif(trim(TWAER), ''), '-1')                              as                            TRANSACTION_CURRENCY_BK
      , coalesce(nullif(trim(PERBL), ''), '-1')                              as                                    PERIOD_BLOCK_BK
      , coalesce(nullif(trim(HRKFT), ''), '-1')                              as                                    ORIGIN_GROUP_BK   
      , LOAD_DTS
      , MANDT
      , LEDNR
      , OBJNR
      , GJAHR
      , WRTTP
      , VERSN
      , KSTAR
      , HRKFT
      , VRGNG
      , PAROB
      , USPOB
      , BEKNZ
      , TWAER
      , PERBL
      , GLREQUEST
      , MEINH
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
      , WTG013
      , WTG014
      , WTG015
      , WTG016
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
      , WOG013
      , WOG014
      , WOG015
      , WOG016
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
      , WKG013
      , WKG014
      , WKG015
      , WKG016
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
      , WKF013
      , WKF014
      , WKF015
      , WKF016
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
      , PAG013
      , PAG014
      , PAG015
      , PAG016
      , PAF001
      , PAF002
      , PAF003
      , PAF004
      , PAF005
      , PAF006
      , PAF007
      , PAF008
      , PAF009
      , PAF010
      , PAF011
      , PAF012
      , PAF013
      , PAF014
      , PAF015
      , PAF016
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
      , MEG013
      , MEG014
      , MEG015
      , MEG016
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
      , MEF013
      , MEF014
      , MEF015
      , MEF016
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
      , MUV013
      , MUV014
      , MUV015
      , MUV016
      , BELTP
      , TIMESTMP
      , BUKRS
      , FKBER
      , SEGMENT
      , GEBER
      , GRANT_NBR
      , BUDGET_PD
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_COSS'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
         CLIENT_BK
        , LEDGER_BK
        , OBJECT_NUMBER_BK
        , FISCAL_YEAR_BK
        , COST_VALUE_TYPE_BK
        , COST_VERSION_BK
        , COST_ELEMENT_BK
        , COST_TRANSACTION_TYPE_BK
        , PARTNER_OBJECT_BK
        , SOURCE_OBJECT_BK
        , DEBIT_CREDIT_INDICATOR_BK
        , TRANSACTION_CURRENCY_BK
        , PERIOD_BLOCK_BK
        , ORIGIN_GROUP_BK
        , LOAD_DTS
        , MANDT
        , LEDNR
        , OBJNR
        , GJAHR
        , WRTTP
        , VERSN
        , KSTAR
        , HRKFT
        , VRGNG
        , PAROB
        , USPOB
        , BEKNZ
        , TWAER
        , PERBL
        , GLREQUEST
        , MEINH
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
        , WTG013
        , WTG014
        , WTG015
        , WTG016
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
        , WOG013
        , WOG014
        , WOG015
        , WOG016
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
        , WKG013
        , WKG014
        , WKG015
        , WKG016
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
        , WKF013
        , WKF014
        , WKF015
        , WKF016
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
        , PAG013
        , PAG014
        , PAG015
        , PAG016
        , PAF001
        , PAF002
        , PAF003
        , PAF004
        , PAF005
        , PAF006
        , PAF007
        , PAF008
        , PAF009
        , PAF010
        , PAF011
        , PAF012
        , PAF013
        , PAF014
        , PAF015
        , PAF016
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
        , MEG013
        , MEG014
        , MEG015
        , MEG016
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
        , MEF013
        , MEF014
        , MEF015
        , MEF016
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
        , MUV013
        , MUV014
        , MUV015
        , MUV016
        , BELTP
        , TIMESTMP
        , BUKRS
        , FKBER
        , SEGMENT
        , GEBER
        , GRANT_NBR
        , BUDGET_PD
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(CLIENT_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(LEDGER_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(OBJECT_NUMBER_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(FISCAL_YEAR_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(COST_VALUE_TYPE_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(COST_VERSION_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(COST_ELEMENT_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(COST_TRANSACTION_TYPE_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(PARTNER_OBJECT_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(SOURCE_OBJECT_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(DEBIT_CREDIT_INDICATOR_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(TRANSACTION_CURRENCY_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(PERIOD_BLOCK_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(ORIGIN_GROUP_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                COST_TOTAL_FOR_INTERNAL_POSTINGS_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(OBJECT_NUMBER_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                     OBJECT_NUMBER_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(COST_ELEMENT_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                    COST_ELEMENT_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(FISCAL_YEAR_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(PERIOD_BLOCK_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                   FISCAL_PERIOD_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(COST_VALUE_TYPE_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                  COST_VALUE_TYPE_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(COST_VERSION_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                    COST_VERSION_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(COST_TRANSACTION_TYPE_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                           COST_TRANSACTION_TYPE_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(ORIGIN_GROUP_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                    ORIGIN_GROUP_HK        
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(LEDGER_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                        LEDGER_HK        
        
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(LEDNR::text), '^^') 
            , '||', IFNULL(TRIM(OBJNR::text), '^^') 
            , '||', IFNULL(TRIM(GJAHR::text), '^^') 
            , '||', IFNULL(TRIM(WRTTP::text), '^^') 
            , '||', IFNULL(TRIM(VERSN::text), '^^') 
            , '||', IFNULL(TRIM(KSTAR::text), '^^') 
            , '||', IFNULL(TRIM(HRKFT::text), '^^') 
            , '||', IFNULL(TRIM(VRGNG::text), '^^') 
            , '||', IFNULL(TRIM(PAROB::text), '^^') 
            , '||', IFNULL(TRIM(USPOB::text), '^^') 
            , '||', IFNULL(TRIM(BEKNZ::text), '^^') 
            , '||', IFNULL(TRIM(TWAER::text), '^^') 
            , '||', IFNULL(TRIM(PERBL::text), '^^') 
            , '||', IFNULL(TRIM(MEINH::text), '^^') 
            , '||', IFNULL(TRIM(WTG001::text), '^^') 
            , '||', IFNULL(TRIM(WTG002::text), '^^') 
            , '||', IFNULL(TRIM(WTG003::text), '^^') 
            , '||', IFNULL(TRIM(WTG004::text), '^^') 
            , '||', IFNULL(TRIM(WTG005::text), '^^') 
            , '||', IFNULL(TRIM(WTG006::text), '^^') 
            , '||', IFNULL(TRIM(WTG007::text), '^^') 
            , '||', IFNULL(TRIM(WTG008::text), '^^') 
            , '||', IFNULL(TRIM(WTG009::text), '^^') 
            , '||', IFNULL(TRIM(WTG010::text), '^^') 
            , '||', IFNULL(TRIM(WTG011::text), '^^') 
            , '||', IFNULL(TRIM(WTG012::text), '^^') 
            , '||', IFNULL(TRIM(WTG013::text), '^^') 
            , '||', IFNULL(TRIM(WTG014::text), '^^') 
            , '||', IFNULL(TRIM(WTG015::text), '^^') 
            , '||', IFNULL(TRIM(WTG016::text), '^^') 
            , '||', IFNULL(TRIM(WOG001::text), '^^') 
            , '||', IFNULL(TRIM(WOG002::text), '^^') 
            , '||', IFNULL(TRIM(WOG003::text), '^^') 
            , '||', IFNULL(TRIM(WOG004::text), '^^') 
            , '||', IFNULL(TRIM(WOG005::text), '^^') 
            , '||', IFNULL(TRIM(WOG006::text), '^^') 
            , '||', IFNULL(TRIM(WOG007::text), '^^') 
            , '||', IFNULL(TRIM(WOG008::text), '^^') 
            , '||', IFNULL(TRIM(WOG009::text), '^^') 
            , '||', IFNULL(TRIM(WOG010::text), '^^') 
            , '||', IFNULL(TRIM(WOG011::text), '^^') 
            , '||', IFNULL(TRIM(WOG012::text), '^^') 
            , '||', IFNULL(TRIM(WOG013::text), '^^') 
            , '||', IFNULL(TRIM(WOG014::text), '^^') 
            , '||', IFNULL(TRIM(WOG015::text), '^^') 
            , '||', IFNULL(TRIM(WOG016::text), '^^') 
            , '||', IFNULL(TRIM(WKG001::text), '^^') 
            , '||', IFNULL(TRIM(WKG002::text), '^^') 
            , '||', IFNULL(TRIM(WKG003::text), '^^') 
            , '||', IFNULL(TRIM(WKG004::text), '^^') 
            , '||', IFNULL(TRIM(WKG005::text), '^^') 
            , '||', IFNULL(TRIM(WKG006::text), '^^') 
            , '||', IFNULL(TRIM(WKG007::text), '^^') 
            , '||', IFNULL(TRIM(WKG008::text), '^^') 
            , '||', IFNULL(TRIM(WKG009::text), '^^') 
            , '||', IFNULL(TRIM(WKG010::text), '^^') 
            , '||', IFNULL(TRIM(WKG011::text), '^^') 
            , '||', IFNULL(TRIM(WKG012::text), '^^') 
            , '||', IFNULL(TRIM(WKG013::text), '^^') 
            , '||', IFNULL(TRIM(WKG014::text), '^^') 
            , '||', IFNULL(TRIM(WKG015::text), '^^') 
            , '||', IFNULL(TRIM(WKG016::text), '^^') 
            , '||', IFNULL(TRIM(WKF001::text), '^^') 
            , '||', IFNULL(TRIM(WKF002::text), '^^') 
            , '||', IFNULL(TRIM(WKF003::text), '^^') 
            , '||', IFNULL(TRIM(WKF004::text), '^^') 
            , '||', IFNULL(TRIM(WKF005::text), '^^') 
            , '||', IFNULL(TRIM(WKF006::text), '^^') 
            , '||', IFNULL(TRIM(WKF007::text), '^^') 
            , '||', IFNULL(TRIM(WKF008::text), '^^') 
            , '||', IFNULL(TRIM(WKF009::text), '^^') 
            , '||', IFNULL(TRIM(WKF010::text), '^^') 
            , '||', IFNULL(TRIM(WKF011::text), '^^') 
            , '||', IFNULL(TRIM(WKF012::text), '^^') 
            , '||', IFNULL(TRIM(WKF013::text), '^^') 
            , '||', IFNULL(TRIM(WKF014::text), '^^') 
            , '||', IFNULL(TRIM(WKF015::text), '^^') 
            , '||', IFNULL(TRIM(WKF016::text), '^^') 
            , '||', IFNULL(TRIM(PAG001::text), '^^') 
            , '||', IFNULL(TRIM(PAG002::text), '^^') 
            , '||', IFNULL(TRIM(PAG003::text), '^^') 
            , '||', IFNULL(TRIM(PAG004::text), '^^') 
            , '||', IFNULL(TRIM(PAG005::text), '^^') 
            , '||', IFNULL(TRIM(PAG006::text), '^^') 
            , '||', IFNULL(TRIM(PAG007::text), '^^') 
            , '||', IFNULL(TRIM(PAG008::text), '^^') 
            , '||', IFNULL(TRIM(PAG009::text), '^^') 
            , '||', IFNULL(TRIM(PAG010::text), '^^') 
            , '||', IFNULL(TRIM(PAG011::text), '^^') 
            , '||', IFNULL(TRIM(PAG012::text), '^^') 
            , '||', IFNULL(TRIM(PAG013::text), '^^') 
            , '||', IFNULL(TRIM(PAG014::text), '^^') 
            , '||', IFNULL(TRIM(PAG015::text), '^^') 
            , '||', IFNULL(TRIM(PAG016::text), '^^') 
            , '||', IFNULL(TRIM(PAF001::text), '^^') 
            , '||', IFNULL(TRIM(PAF002::text), '^^') 
            , '||', IFNULL(TRIM(PAF003::text), '^^') 
            , '||', IFNULL(TRIM(PAF004::text), '^^') 
            , '||', IFNULL(TRIM(PAF005::text), '^^') 
            , '||', IFNULL(TRIM(PAF006::text), '^^') 
            , '||', IFNULL(TRIM(PAF007::text), '^^') 
            , '||', IFNULL(TRIM(PAF008::text), '^^') 
            , '||', IFNULL(TRIM(PAF009::text), '^^') 
            , '||', IFNULL(TRIM(PAF010::text), '^^') 
            , '||', IFNULL(TRIM(PAF011::text), '^^') 
            , '||', IFNULL(TRIM(PAF012::text), '^^') 
            , '||', IFNULL(TRIM(PAF013::text), '^^') 
            , '||', IFNULL(TRIM(PAF014::text), '^^') 
            , '||', IFNULL(TRIM(PAF015::text), '^^') 
            , '||', IFNULL(TRIM(PAF016::text), '^^') 
            , '||', IFNULL(TRIM(MEG001::text), '^^') 
            , '||', IFNULL(TRIM(MEG002::text), '^^') 
            , '||', IFNULL(TRIM(MEG003::text), '^^') 
            , '||', IFNULL(TRIM(MEG004::text), '^^') 
            , '||', IFNULL(TRIM(MEG005::text), '^^') 
            , '||', IFNULL(TRIM(MEG006::text), '^^') 
            , '||', IFNULL(TRIM(MEG007::text), '^^') 
            , '||', IFNULL(TRIM(MEG008::text), '^^') 
            , '||', IFNULL(TRIM(MEG009::text), '^^') 
            , '||', IFNULL(TRIM(MEG010::text), '^^') 
            , '||', IFNULL(TRIM(MEG011::text), '^^') 
            , '||', IFNULL(TRIM(MEG012::text), '^^') 
            , '||', IFNULL(TRIM(MEG013::text), '^^') 
            , '||', IFNULL(TRIM(MEG014::text), '^^') 
            , '||', IFNULL(TRIM(MEG015::text), '^^') 
            , '||', IFNULL(TRIM(MEG016::text), '^^') 
            , '||', IFNULL(TRIM(MEF001::text), '^^') 
            , '||', IFNULL(TRIM(MEF002::text), '^^') 
            , '||', IFNULL(TRIM(MEF003::text), '^^') 
            , '||', IFNULL(TRIM(MEF004::text), '^^') 
            , '||', IFNULL(TRIM(MEF005::text), '^^') 
            , '||', IFNULL(TRIM(MEF006::text), '^^') 
            , '||', IFNULL(TRIM(MEF007::text), '^^') 
            , '||', IFNULL(TRIM(MEF008::text), '^^') 
            , '||', IFNULL(TRIM(MEF009::text), '^^') 
            , '||', IFNULL(TRIM(MEF010::text), '^^') 
            , '||', IFNULL(TRIM(MEF011::text), '^^') 
            , '||', IFNULL(TRIM(MEF012::text), '^^') 
            , '||', IFNULL(TRIM(MEF013::text), '^^') 
            , '||', IFNULL(TRIM(MEF014::text), '^^') 
            , '||', IFNULL(TRIM(MEF015::text), '^^') 
            , '||', IFNULL(TRIM(MEF016::text), '^^') 
            , '||', IFNULL(TRIM(MUV001::text), '^^') 
            , '||', IFNULL(TRIM(MUV002::text), '^^') 
            , '||', IFNULL(TRIM(MUV003::text), '^^') 
            , '||', IFNULL(TRIM(MUV004::text), '^^') 
            , '||', IFNULL(TRIM(MUV005::text), '^^') 
            , '||', IFNULL(TRIM(MUV006::text), '^^') 
            , '||', IFNULL(TRIM(MUV007::text), '^^') 
            , '||', IFNULL(TRIM(MUV008::text), '^^') 
            , '||', IFNULL(TRIM(MUV009::text), '^^') 
            , '||', IFNULL(TRIM(MUV010::text), '^^') 
            , '||', IFNULL(TRIM(MUV011::text), '^^') 
            , '||', IFNULL(TRIM(MUV012::text), '^^') 
            , '||', IFNULL(TRIM(MUV013::text), '^^') 
            , '||', IFNULL(TRIM(MUV014::text), '^^') 
            , '||', IFNULL(TRIM(MUV015::text), '^^') 
            , '||', IFNULL(TRIM(MUV016::text), '^^') 
            , '||', IFNULL(TRIM(BELTP::text), '^^') 
            , '||', IFNULL(TRIM(TIMESTMP::text), '^^') 
            , '||', IFNULL(TRIM(BUKRS::text), '^^') 
            , '||', IFNULL(TRIM(FKBER::text), '^^') 
            , '||', IFNULL(TRIM(SEGMENT::text), '^^') 
            , '||', IFNULL(TRIM(GEBER::text), '^^') 
            , '||', IFNULL(TRIM(GRANT_NBR::text), '^^') 
            , '||', IFNULL(TRIM(BUDGET_PD::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
