---- SRC LAYER ----
WITH
SRC_s              as ( SELECT * FROM {{ ref('v_psa_stg_logistics_shipment_stage__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_s              as ( SELECT * FROM STAGING.v_psa_stg_logistics_shipment_stage__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        MANDT
      , TKNUM
      , TSNUM
      , GLREQUEST
      , TSTYP
      , TSRFO
      , ELUPD
      , ERNAM
      , ERDAT
      , ERZET
      , AENAM
      , AEDAT
      , AEZET
      , ROUTE
      , VSART
      , INCO1
      , LAUFK
      , ADRNA
      , KNOTA
      , VSTEL
      , LSTEL
      , WERKA
      , LGORTA
      , KUNNA
      , LIFNA
      , BELAD
      , ADRNZ
      , KNOTZ
      , VSTEZ
      , LSTEZ
      , WERKZ
      , LGORTZ
      , KUNNZ
      , LIFNZ
      , ABLAD
      , DPTBG
      , UPTBG
      , DATBG
      , UATBG
      , DPTEN
      , UPTEN
      , DATEN
      , UATEN
      , TDLNR
      , DISTZ
      , MEDST
      , FAHZT
      , GESZT
      , MEIZT
      , LGNUMA
      , TORA
      , ADRKNZA
      , KUNABLA
      , LGNUMZ
      , TORZ
      , ADRKNZZ
      , KUNABLZ
      , GESZTD
      , FAHZTD
      , GESZTDA
      , FAHZTDA
      , SDABW
      , FRKRL
      , SKALSM
      , FBSTA
      , ARSTA
      , STAFO
      , CONT_DG
      , WARZTD
      , WARZTDA
      , ABLAND1
      , ABPSTLZ
      , ABORT01
      , EDLAND1
      , EDPSTLZ
      , EDORT01
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , LOGISTICS_SHIPMENT_HK                                        
      , LOAD_DTS
      , HASHDIFF
    FROM SRC_s
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        MANDT
      , TKNUM
      , TSNUM
      , GLREQUEST
      , TSTYP
      , TSRFO
      , ELUPD
      , ERNAM
      , ERDAT
      , ERZET
      , AENAM
      , AEDAT
      , AEZET
      , ROUTE
      , VSART
      , INCO1
      , LAUFK
      , ADRNA
      , KNOTA
      , VSTEL
      , LSTEL
      , WERKA
      , LGORTA
      , KUNNA
      , LIFNA
      , BELAD
      , ADRNZ
      , KNOTZ
      , VSTEZ
      , LSTEZ
      , WERKZ
      , LGORTZ
      , KUNNZ
      , LIFNZ
      , ABLAD
      , DPTBG
      , UPTBG
      , DATBG
      , UATBG
      , DPTEN
      , UPTEN
      , DATEN
      , UATEN
      , TDLNR
      , DISTZ
      , MEDST
      , FAHZT
      , GESZT
      , MEIZT
      , LGNUMA
      , TORA
      , ADRKNZA
      , KUNABLA
      , LGNUMZ
      , TORZ
      , ADRKNZZ
      , KUNABLZ
      , GESZTD
      , FAHZTD
      , GESZTDA
      , FAHZTDA
      , SDABW
      , FRKRL
      , SKALSM
      , FBSTA
      , ARSTA
      , STAFO
      , CONT_DG
      , WARZTD
      , WARZTDA
      , ABLAND1
      , ABPSTLZ
      , ABORT01
      , EDLAND1
      , EDPSTLZ
      , EDORT01
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , LOGISTICS_SHIPMENT_HK
      , LOAD_DTS
      , HASHDIFF
    FROM LOGIC_s
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
)

---- FINAL LAYER ----
SELECT
          MANDT
        , TKNUM
        , TSNUM
        , GLREQUEST
        , TSTYP
        , TSRFO
        , ELUPD
        , ERNAM
        , ERDAT
        , ERZET
        , AENAM
        , AEDAT
        , AEZET
        , ROUTE
        , VSART
        , INCO1
        , LAUFK
        , ADRNA
        , KNOTA
        , VSTEL
        , LSTEL
        , WERKA
        , LGORTA
        , KUNNA
        , LIFNA
        , BELAD
        , ADRNZ
        , KNOTZ
        , VSTEZ
        , LSTEZ
        , WERKZ
        , LGORTZ
        , KUNNZ
        , LIFNZ
        , ABLAD
        , DPTBG
        , UPTBG
        , DATBG
        , UATBG
        , DPTEN
        , UPTEN
        , DATEN
        , UATEN
        , TDLNR
        , DISTZ
        , MEDST
        , FAHZT
        , GESZT
        , MEIZT
        , LGNUMA
        , TORA
        , ADRKNZA
        , KUNABLA
        , LGNUMZ
        , TORZ
        , ADRKNZZ
        , KUNABLZ
        , GESZTD
        , FAHZTD
        , GESZTDA
        , FAHZTDA
        , SDABW
        , FRKRL
        , SKALSM
        , FBSTA
        , ARSTA
        , STAFO
        , CONT_DG
        , WARZTD
        , WARZTDA
        , ABLAND1
        , ABPSTLZ
        , ABORT01
        , EDLAND1
        , EDPSTLZ
        , EDORT01
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , LOGISTICS_SHIPMENT_HK
        , LOAD_DTS
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
 WHERE NOT EXISTS (
  SELECT 1 
  FROM {{ this }} existing
  WHERE existing.LOGISTICS_SHIPMENT_HK = JOIN_RESULT.LOGISTICS_SHIPMENT_HK AND  existing.TSNUM = JOIN_RESULT.TSNUM AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
 )
 {% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by LOGISTICS_SHIPMENT_HK, TSNUM, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
NULL AS MANDT,
NULL AS TKNUM,
GR.VALUE AS TSNUM,
NULL AS GLREQUEST,
NULL AS TSTYP,
NULL AS TSRFO,
NULL AS ELUPD,
NULL AS ERNAM,
NULL AS ERDAT,
NULL AS ERZET,
NULL AS AENAM,
NULL AS AEDAT,
NULL AS AEZET,
NULL AS ROUTE,
NULL AS VSART,
NULL AS INCO1,
NULL AS LAUFK,
NULL AS ADRNA,
NULL AS KNOTA,
NULL AS VSTEL,
NULL AS LSTEL,
NULL AS WERKA,
NULL AS LGORTA,
NULL AS KUNNA,
NULL AS LIFNA,
NULL AS BELAD,
NULL AS ADRNZ,
NULL AS KNOTZ,
NULL AS VSTEZ,
NULL AS LSTEZ,
NULL AS WERKZ,
NULL AS LGORTZ,
NULL AS KUNNZ,
NULL AS LIFNZ,
NULL AS ABLAD,
NULL AS DPTBG,
NULL AS UPTBG,
NULL AS DATBG,
NULL AS UATBG,
NULL AS DPTEN,
NULL AS UPTEN,
NULL AS DATEN,
NULL AS UATEN,
NULL AS TDLNR,
NULL AS DISTZ,
NULL AS MEDST,
NULL AS FAHZT,
NULL AS GESZT,
NULL AS MEIZT,
NULL AS LGNUMA,
NULL AS TORA,
NULL AS ADRKNZA,
NULL AS KUNABLA,
NULL AS LGNUMZ,
NULL AS TORZ,
NULL AS ADRKNZZ,
NULL AS KUNABLZ,
NULL AS GESZTD,
NULL AS FAHZTD,
NULL AS GESZTDA,
NULL AS FAHZTDA,
NULL AS SDABW,
NULL AS FRKRL,
NULL AS SKALSM,
NULL AS FBSTA,
NULL AS ARSTA,
NULL AS STAFO,
NULL AS CONT_DG,
NULL AS WARZTD,
NULL AS WARZTDA,
NULL AS ABLAND1,
NULL AS ABPSTLZ,
NULL AS ABORT01,
NULL AS EDLAND1,
NULL AS EDPSTLZ,
NULL AS EDORT01,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLSOURCESYSTEM,
NULL AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
NULL AS PSA_DELETE_IND,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
MD5_BINARY(GR.VALUE) AS SHIPMENT_HK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
