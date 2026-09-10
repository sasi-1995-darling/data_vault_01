---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT * FROM {{ ref('v_psa_stg_cost_total_for_internal_postings__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.v_psa_stg_cost_total_for_internal_postings__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        COST_TOTAL_FOR_INTERNAL_POSTINGS_HK
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
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SWINN
)
---- RENAME LAYER ----

, RENAME_SWINN as (
    SELECT
        COST_TOTAL_FOR_INTERNAL_POSTINGS_HK
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
      , LOAD_DTS
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
          COST_TOTAL_FOR_INTERNAL_POSTINGS_HK
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
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.COST_TOTAL_FOR_INTERNAL_POSTINGS_HK= JOIN_RESULT.COST_TOTAL_FOR_INTERNAL_POSTINGS_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by COST_TOTAL_FOR_INTERNAL_POSTINGS_HK, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS COST_TOTAL_FOR_INTERNAL_POSTINGS_HK
    , NULL AS MANDT
, NULL AS LEDNR
, NULL AS OBJNR
, NULL AS GJAHR
, NULL AS WRTTP
, NULL AS VERSN
, NULL AS KSTAR
, NULL AS HRKFT
, NULL AS VRGNG
, NULL AS PAROB
, NULL AS USPOB
, NULL AS BEKNZ
, NULL AS TWAER
, NULL AS PERBL
, NULL AS GLREQUEST
, NULL AS MEINH
, NULL AS WTG001
, NULL AS WTG002
, NULL AS WTG003
, NULL AS WTG004
, NULL AS WTG005
, NULL AS WTG006
, NULL AS WTG007
, NULL AS WTG008
, NULL AS WTG009
, NULL AS WTG010
, NULL AS WTG011
, NULL AS WTG012
, NULL AS WTG013
, NULL AS WTG014
, NULL AS WTG015
, NULL AS WTG016
, NULL AS WOG001
, NULL AS WOG002
, NULL AS WOG003
, NULL AS WOG004
, NULL AS WOG005
, NULL AS WOG006
, NULL AS WOG007
, NULL AS WOG008
, NULL AS WOG009
, NULL AS WOG010
, NULL AS WOG011
, NULL AS WOG012
, NULL AS WOG013
, NULL AS WOG014
, NULL AS WOG015
, NULL AS WOG016
, NULL AS WKG001
, NULL AS WKG002
, NULL AS WKG003
, NULL AS WKG004
, NULL AS WKG005
, NULL AS WKG006
, NULL AS WKG007
, NULL AS WKG008
, NULL AS WKG009
, NULL AS WKG010
, NULL AS WKG011
, NULL AS WKG012
, NULL AS WKG013
, NULL AS WKG014
, NULL AS WKG015
, NULL AS WKG016
, NULL AS WKF001
, NULL AS WKF002
, NULL AS WKF003
, NULL AS WKF004
, NULL AS WKF005
, NULL AS WKF006
, NULL AS WKF007
, NULL AS WKF008
, NULL AS WKF009
, NULL AS WKF010
, NULL AS WKF011
, NULL AS WKF012
, NULL AS WKF013
, NULL AS WKF014
, NULL AS WKF015
, NULL AS WKF016
, NULL AS PAG001
, NULL AS PAG002
, NULL AS PAG003
, NULL AS PAG004
, NULL AS PAG005
, NULL AS PAG006
, NULL AS PAG007
, NULL AS PAG008
, NULL AS PAG009
, NULL AS PAG010
, NULL AS PAG011
, NULL AS PAG012
, NULL AS PAG013
, NULL AS PAG014
, NULL AS PAG015
, NULL AS PAG016
, NULL AS PAF001
, NULL AS PAF002
, NULL AS PAF003
, NULL AS PAF004
, NULL AS PAF005
, NULL AS PAF006
, NULL AS PAF007
, NULL AS PAF008
, NULL AS PAF009
, NULL AS PAF010
, NULL AS PAF011
, NULL AS PAF012
, NULL AS PAF013
, NULL AS PAF014
, NULL AS PAF015
, NULL AS PAF016
, NULL AS MEG001
, NULL AS MEG002
, NULL AS MEG003
, NULL AS MEG004
, NULL AS MEG005
, NULL AS MEG006
, NULL AS MEG007
, NULL AS MEG008
, NULL AS MEG009
, NULL AS MEG010
, NULL AS MEG011
, NULL AS MEG012
, NULL AS MEG013
, NULL AS MEG014
, NULL AS MEG015
, NULL AS MEG016
, NULL AS MEF001
, NULL AS MEF002
, NULL AS MEF003
, NULL AS MEF004
, NULL AS MEF005
, NULL AS MEF006
, NULL AS MEF007
, NULL AS MEF008
, NULL AS MEF009
, NULL AS MEF010
, NULL AS MEF011
, NULL AS MEF012
, NULL AS MEF013
, NULL AS MEF014
, NULL AS MEF015
, NULL AS MEF016
, NULL AS MUV001
, NULL AS MUV002
, NULL AS MUV003
, NULL AS MUV004
, NULL AS MUV005
, NULL AS MUV006
, NULL AS MUV007
, NULL AS MUV008
, NULL AS MUV009
, NULL AS MUV010
, NULL AS MUV011
, NULL AS MUV012
, NULL AS MUV013
, NULL AS MUV014
, NULL AS MUV015
, NULL AS MUV016
, NULL AS BELTP
, NULL AS TIMESTMP
, NULL AS BUKRS
, NULL AS FKBER
, NULL AS SEGMENT
, NULL AS GEBER
, NULL AS GRANT_NBR
, NULL AS BUDGET_PD
, NULL AS GLDELFLAG
, NULL AS GLSOURCESYSTEM
, NULL AS GLCHANGETIME
, NULL AS PSA_LOAD_DTS
, NULL AS PSA_RECORD_SOURCE
, NULL AS PSA_DELETE_IND
, CONVERT_TIMEZONE('UTC','1900-01-01')  as  LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASH_DIFF FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}