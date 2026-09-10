---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT * FROM {{ ref('v_psa_stg_cost_totals_for_external_postings__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.v_psa_stg_cost_totals_for_external_postings__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        COST_TOTALS_FOR_EXTERNAL_POSTINGS_HK
      , MANDT
      , LEDGER_HK
      , OBJECT_NUMBER_HK
      , FISCAL_PERIOD_HK
      , COST_VALUE_TYPE_HK
      , COST_VERSION_HK
      , COST_ELEMENT_HK
      , ORIGIN_GROUP_HK
      , COST_BUSINESS_TRANSACTION_TYPE_HK
      , LEGAL_ENTITY_HK
      , CURRENCY_HK
      , DEBIT_CREDIT_INDICATOR_HK
      , TRADING_PARTNER_BUSINESS_AREA_HK
      , LEDNR                                                      
      , OBJNR                                                      
      , GJAHR                                                    
      , WRTTP                                                      
      , VERSN                                                      
      , KSTAR                                                      
      , HRKFT                                                      
      , VRGNG                                                      
      , VBUND                                                      
      , PARGB                                                    
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
      , LOAD_DTS
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SWINN
)
---- RENAME LAYER ----

, RENAME_SWINN as (
    SELECT
        COST_TOTALS_FOR_EXTERNAL_POSTINGS_HK
      , MANDT
      , LEDGER_HK
      , OBJECT_NUMBER_HK
      , FISCAL_PERIOD_HK
      , COST_VALUE_TYPE_HK
      , COST_VERSION_HK
      , COST_ELEMENT_HK
      , ORIGIN_GROUP_HK
      , COST_BUSINESS_TRANSACTION_TYPE_HK
      , LEGAL_ENTITY_HK
      , CURRENCY_HK
      , DEBIT_CREDIT_INDICATOR_HK
      , TRADING_PARTNER_BUSINESS_AREA_HK
      , LEDNR                                                      
      , OBJNR                                                      
      , GJAHR                                                    
      , WRTTP                                                      
      , VERSN                                                      
      , KSTAR                                                      
      , HRKFT                                                      
      , VRGNG                                                      
      , VBUND                                                      
      , PARGB                                                    
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
      , LOAD_DTS
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_SWINN
)
---- FILTER LAYER ----

, FILTER_SWINN as (
    SELECT *
    FROM RENAME_SWINN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SWINN
)

---- FINAL LAYER ----
SELECT
          COST_TOTALS_FOR_EXTERNAL_POSTINGS_HK
        , MANDT
        , LEDGER_HK
        , OBJECT_NUMBER_HK
        , FISCAL_PERIOD_HK
        , COST_VALUE_TYPE_HK
        , COST_VERSION_HK
        , COST_ELEMENT_HK
        , ORIGIN_GROUP_HK
        , COST_BUSINESS_TRANSACTION_TYPE_HK
        , LEGAL_ENTITY_HK
        , CURRENCY_HK
        , DEBIT_CREDIT_INDICATOR_HK
        , TRADING_PARTNER_BUSINESS_AREA_HK
        , LEDNR                                                      
        , OBJNR                                                      
        , GJAHR                                                    
        , WRTTP                                                      
        , VERSN                                                      
        , KSTAR                                                      
        , HRKFT                                                      
        , VRGNG                                                      
        , VBUND                                                      
        , PARGB                                                    
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
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.COST_TOTALS_FOR_EXTERNAL_POSTINGS_HK= JOIN_RESULT.COST_TOTALS_FOR_EXTERNAL_POSTINGS_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by COST_TOTALS_FOR_EXTERNAL_POSTINGS_HK, HASHDIFF order by LOAD_DTS)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS COST_TOTALS_FOR_EXTERNAL_POSTINGS_HK,
  CAST(NULL AS STRING) AS MANDT
  ,MD5_BINARY(GR.VALUE) AS LEDGER_HK
  ,MD5_BINARY(GR.VALUE) AS OBJECT_NUMBER_HK
  ,MD5_BINARY(GR.VALUE) AS FISCAL_PERIOD_HK
  ,MD5_BINARY(GR.VALUE) AS COST_VALUE_TYPE_HK
  ,MD5_BINARY(GR.VALUE) AS COST_VERSION_HK
  ,MD5_BINARY(GR.VALUE) AS COST_ELEMENT_HK
  ,MD5_BINARY(GR.VALUE) AS ORIGIN_GROUP_HK
  ,MD5_BINARY(GR.VALUE) AS COST_BUSINESS_TRANSACTION_TYPE_HK
  ,MD5_BINARY(GR.VALUE) AS LEGAL_ENTITY_HK
  ,MD5_BINARY(GR.VALUE) AS CURRENCY_HK
  ,MD5_BINARY(GR.VALUE) AS DEBIT_CREDIT_INDICATOR_HK
  ,MD5_BINARY(GR.VALUE) AS TRADING_PARTNER_BUSINESS_AREA_HK
  ,CAST(NULL AS STRING) AS LEDNR
  ,CAST(NULL AS STRING) AS OBJNR
  ,CAST(NULL AS STRING) AS GJAHR
  ,CAST(NULL AS STRING) AS WRTTP
  ,CAST(NULL AS STRING) AS VERSN
  ,CAST(NULL AS STRING) AS KSTAR
  ,CAST(NULL AS STRING) AS HRKFT
  ,CAST(NULL AS STRING) AS VRGNG
  ,CAST(NULL AS STRING) AS VBUND
  ,CAST(NULL AS STRING) AS PARGB
  ,CAST(NULL AS STRING) AS BEKNZ
  ,CAST(NULL AS STRING) AS TWAER
  ,CAST(NULL AS STRING) AS PERBL
  ,CAST(NULL AS STRING) AS GLREQUEST,
  CAST(NULL AS STRING) AS MEINH,
  CAST(NULL AS STRING) AS WTG001,
  CAST(NULL AS STRING) AS WTG002,
  CAST(NULL AS STRING) AS WTG003,
  CAST(NULL AS STRING) AS WTG004,
  CAST(NULL AS STRING) AS WTG005,
  CAST(NULL AS STRING) AS WTG006,
  CAST(NULL AS STRING) AS WTG007,
  CAST(NULL AS STRING) AS WTG008,
  CAST(NULL AS STRING) AS WTG009,
  CAST(NULL AS STRING) AS WTG010,
  CAST(NULL AS STRING) AS WTG011,
  CAST(NULL AS STRING) AS WTG012,
  CAST(NULL AS STRING) AS WTG013,
  CAST(NULL AS STRING) AS WTG014,
  CAST(NULL AS STRING) AS WTG015,
  CAST(NULL AS STRING) AS WTG016,
  CAST(NULL AS STRING) AS WOG001,
  CAST(NULL AS STRING) AS WOG002,
  CAST(NULL AS STRING) AS WOG003,
  CAST(NULL AS STRING) AS WOG004,
  CAST(NULL AS STRING) AS WOG005,
  CAST(NULL AS STRING) AS WOG006,
  CAST(NULL AS STRING) AS WOG007,
  CAST(NULL AS STRING) AS WOG008,
  CAST(NULL AS STRING) AS WOG009,
  CAST(NULL AS STRING) AS WOG010,
  CAST(NULL AS STRING) AS WOG011,
  CAST(NULL AS STRING) AS WOG012,
  CAST(NULL AS STRING) AS WOG013,
  CAST(NULL AS STRING) AS WOG014,
  CAST(NULL AS STRING) AS WOG015,
  CAST(NULL AS STRING) AS WOG016,
  CAST(NULL AS STRING) AS WKG001,
  CAST(NULL AS STRING) AS WKG002,
  CAST(NULL AS STRING) AS WKG003,
  CAST(NULL AS STRING) AS WKG004,
  CAST(NULL AS STRING) AS WKG005,
  CAST(NULL AS STRING) AS WKG006,
  CAST(NULL AS STRING) AS WKG007,
  CAST(NULL AS STRING) AS WKG008,
  CAST(NULL AS STRING) AS WKG009,
  CAST(NULL AS STRING) AS WKG010,
  CAST(NULL AS STRING) AS WKG011,
  CAST(NULL AS STRING) AS WKG012,
  CAST(NULL AS STRING) AS WKG013,
  CAST(NULL AS STRING) AS WKG014,
  CAST(NULL AS STRING) AS WKG015,
  CAST(NULL AS STRING) AS WKG016,
  CAST(NULL AS STRING) AS WKF001,
  CAST(NULL AS STRING) AS WKF002,
  CAST(NULL AS STRING) AS WKF003,
  CAST(NULL AS STRING) AS WKF004,
  CAST(NULL AS STRING) AS WKF005,
  CAST(NULL AS STRING) AS WKF006,
  CAST(NULL AS STRING) AS WKF007,
  CAST(NULL AS STRING) AS WKF008,
  CAST(NULL AS STRING) AS WKF009,
  CAST(NULL AS STRING) AS WKF010,
  CAST(NULL AS STRING) AS WKF011,
  CAST(NULL AS STRING) AS WKF012,
  CAST(NULL AS STRING) AS WKF013,
  CAST(NULL AS STRING) AS WKF014,
  CAST(NULL AS STRING) AS WKF015,
  CAST(NULL AS STRING) AS WKF016,
  CAST(NULL AS STRING) AS PAG001,
  CAST(NULL AS STRING) AS PAG002,
  CAST(NULL AS STRING) AS PAG003,
  CAST(NULL AS STRING) AS PAG004,
  CAST(NULL AS STRING) AS PAG005,
  CAST(NULL AS STRING) AS PAG006,
  CAST(NULL AS STRING) AS PAG007,
  CAST(NULL AS STRING) AS PAG008,
  CAST(NULL AS STRING) AS PAG009,
  CAST(NULL AS STRING) AS PAG010,
  CAST(NULL AS STRING) AS PAG011,
  CAST(NULL AS STRING) AS PAG012,
  CAST(NULL AS STRING) AS PAG013,
  CAST(NULL AS STRING) AS PAG014,
  CAST(NULL AS STRING) AS PAG015,
  CAST(NULL AS STRING) AS PAG016,
  CAST(NULL AS STRING) AS MEG001,
  CAST(NULL AS STRING) AS MEG002,
  CAST(NULL AS STRING) AS MEG003,
  CAST(NULL AS STRING) AS MEG004,
  CAST(NULL AS STRING) AS MEG005,
  CAST(NULL AS STRING) AS MEG006,
  CAST(NULL AS STRING) AS MEG007,
  CAST(NULL AS STRING) AS MEG008,
  CAST(NULL AS STRING) AS MEG009,
  CAST(NULL AS STRING) AS MEG010,
  CAST(NULL AS STRING) AS MEG011,
  CAST(NULL AS STRING) AS MEG012,
  CAST(NULL AS STRING) AS MEG013,
  CAST(NULL AS STRING) AS MEG014,
  CAST(NULL AS STRING) AS MEG015,
  CAST(NULL AS STRING) AS MEG016,
  CAST(NULL AS STRING) AS MEF001,
  CAST(NULL AS STRING) AS MEF002,
  CAST(NULL AS STRING) AS MEF003,
  CAST(NULL AS STRING) AS MEF004,
  CAST(NULL AS STRING) AS MEF005,
  CAST(NULL AS STRING) AS MEF006,
  CAST(NULL AS STRING) AS MEF007,
  CAST(NULL AS STRING) AS MEF008,
  CAST(NULL AS STRING) AS MEF009,
  CAST(NULL AS STRING) AS MEF010,
  CAST(NULL AS STRING) AS MEF011,
  CAST(NULL AS STRING) AS MEF012,
  CAST(NULL AS STRING) AS MEF013,
  CAST(NULL AS STRING) AS MEF014,
  CAST(NULL AS STRING) AS MEF015,
  CAST(NULL AS STRING) AS MEF016,
  CAST(NULL AS STRING) AS MUV001,
  CAST(NULL AS STRING) AS MUV002,
  CAST(NULL AS STRING) AS MUV003,
  CAST(NULL AS STRING) AS MUV004,
  CAST(NULL AS STRING) AS MUV005,
  CAST(NULL AS STRING) AS MUV006,
  CAST(NULL AS STRING) AS MUV007,
  CAST(NULL AS STRING) AS MUV008,
  CAST(NULL AS STRING) AS MUV009,
  CAST(NULL AS STRING) AS MUV010,
  CAST(NULL AS STRING) AS MUV011,
  CAST(NULL AS STRING) AS MUV012,
  CAST(NULL AS STRING) AS MUV013,
  CAST(NULL AS STRING) AS MUV014,
  CAST(NULL AS STRING) AS MUV015,
  CAST(NULL AS STRING) AS MUV016,
  CAST(NULL AS STRING) AS BELTP,
  CAST(NULL AS STRING) AS TIMESTMP,
  CAST(NULL AS STRING) AS BUKRS,
  CAST(NULL AS STRING) AS FKBER,
  CAST(NULL AS STRING) AS SEGMENT,
  CAST(NULL AS STRING) AS GEBER,
  CAST(NULL AS STRING) AS GRANT_NBR,
  CAST(NULL AS STRING) AS BUDGET_PD,
  CAST(NULL AS STRING) AS GLDELFLAG,
  CAST(NULL AS STRING) AS GLSOURCESYSTEM,
  CAST(NULL AS STRING) AS GLCHANGETIME,
  CAST(NULL AS STRING) AS PSA_DELETE_IND
, CONVERT_TIMEZONE('UTC','1900-01-01')  as  LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASH_DIFF FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}