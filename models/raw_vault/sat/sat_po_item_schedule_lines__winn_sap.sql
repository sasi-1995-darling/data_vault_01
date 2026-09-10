---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ ref('v_psa_stg_po_item_schedule_lines__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_a              as ( SELECT * FROM staging.v_psa_stg_po_item_schedule_lines__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        PO_ITEM_HK
      , EBELN
      , EBELP
      , ETENR
      , MANDT
      , EINDT
      , SLFDT
      , LPEIN
      , MENGE
      , AMENG
      , WEMNG
      , WAMNG
      , UZEIT
      , BANFN
      , BNFPO
      , ESTKZ
      , QUNUM
      , QUPOS
      , MAHNZ
      , BEDAT
      , RSNUM
      , SERNR
      , FIXKZ
      , GLMNG
      , DABMG
      , CHARG
      , LICHA
      , CHKOM
      , VERID
      , ABART
      , MNG02
      , DAT01
      , ALTDT
      , AULWE
      , MBDAT
      , MBUHR
      , LDDAT
      , LDUHR
      , TDDAT
      , TDUHR
      , WADAT
      , WAUHR
      , ELDAT
      , ELUHR
      , ANZSN
      , NODISP
      , GEO_ROUTE
      , ROUTE_GTS
      , GTS_IND
      , TSP
      , CD_LOCNO
      , CD_LOCTYPE
      , HANDOVERDATE
      , HANDOVERTIME
      , FSH_RALLOC_QTY
      , FSH_SALLOC_QTY
      , FSH_OS_ID
      , KEY_ID
      , OTB_VALUE
      , OTB_CURR
      , OTB_RES_VALUE
      , OTB_SPEC_VALUE
      , SPR_RSN_PROFILE
      , BUDG_TYPE
      , OTB_STATUS
      , OTB_REASON
      , CHECK_TYPE
      , DL_ID
      , HANDOVER_DATE
      , NO_SCEM
      , DNG_DATE
      , DNG_TIME
      , CNCL_ANCMNT_DONE
      , DATESHIFT_NUMBER
      , ZZSHPDT
      , ZZOVERRIDE
      , ZZFREIGHT
      , ZZCOST
      , ZZASN
      , GLREQUEST
      , GLSOURCESYSTEM
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        PO_ITEM_HK
      , EBELN
      , EBELP
      , ETENR
      , MANDT
      , EINDT
      , SLFDT
      , LPEIN
      , MENGE
      , AMENG
      , WEMNG
      , WAMNG
      , UZEIT
      , BANFN
      , BNFPO
      , ESTKZ
      , QUNUM
      , QUPOS
      , MAHNZ
      , BEDAT
      , RSNUM
      , SERNR
      , FIXKZ
      , GLMNG
      , DABMG
      , CHARG
      , LICHA
      , CHKOM
      , VERID
      , ABART
      , MNG02
      , DAT01
      , ALTDT
      , AULWE
      , MBDAT
      , MBUHR
      , LDDAT
      , LDUHR
      , TDDAT
      , TDUHR
      , WADAT
      , WAUHR
      , ELDAT
      , ELUHR
      , ANZSN
      , NODISP
      , GEO_ROUTE
      , ROUTE_GTS
      , GTS_IND
      , TSP
      , CD_LOCNO
      , CD_LOCTYPE
      , HANDOVERDATE
      , HANDOVERTIME
      , FSH_RALLOC_QTY
      , FSH_SALLOC_QTY
      , FSH_OS_ID
      , KEY_ID
      , OTB_VALUE
      , OTB_CURR
      , OTB_RES_VALUE
      , OTB_SPEC_VALUE
      , SPR_RSN_PROFILE
      , BUDG_TYPE
      , OTB_STATUS
      , OTB_REASON
      , CHECK_TYPE
      , DL_ID
      , HANDOVER_DATE
      , NO_SCEM
      , DNG_DATE
      , DNG_TIME
      , CNCL_ANCMNT_DONE
      , DATESHIFT_NUMBER
      , ZZSHPDT
      , ZZOVERRIDE
      , ZZFREIGHT
      , ZZCOST
      , ZZASN
      , GLREQUEST
      , GLSOURCESYSTEM
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
)

---- FINAL LAYER ----
SELECT
          PO_ITEM_HK
        , EBELN
        , EBELP
        , ETENR
        , MANDT
        , EINDT
        , SLFDT
        , LPEIN
        , MENGE
        , AMENG
        , WEMNG
        , WAMNG
        , UZEIT
        , BANFN
        , BNFPO
        , ESTKZ
        , QUNUM
        , QUPOS
        , MAHNZ
        , BEDAT
        , RSNUM
        , SERNR
        , FIXKZ
        , GLMNG
        , DABMG
        , CHARG
        , LICHA
        , CHKOM
        , VERID
        , ABART
        , MNG02
        , DAT01
        , ALTDT
        , AULWE
        , MBDAT
        , MBUHR
        , LDDAT
        , LDUHR
        , TDDAT
        , TDUHR
        , WADAT
        , WAUHR
        , ELDAT
        , ELUHR
        , ANZSN
        , NODISP
        , GEO_ROUTE
        , ROUTE_GTS
        , GTS_IND
        , TSP
        , CD_LOCNO
        , CD_LOCTYPE
        , HANDOVERDATE
        , HANDOVERTIME
        , FSH_RALLOC_QTY
        , FSH_SALLOC_QTY
        , FSH_OS_ID
        , KEY_ID
        , OTB_VALUE
        , OTB_CURR
        , OTB_RES_VALUE
        , OTB_SPEC_VALUE
        , SPR_RSN_PROFILE
        , BUDG_TYPE
        , OTB_STATUS
        , OTB_REASON
        , CHECK_TYPE
        , DL_ID
        , HANDOVER_DATE
        , NO_SCEM
        , DNG_DATE
        , DNG_TIME
        , CNCL_ANCMNT_DONE
        , DATESHIFT_NUMBER
        , ZZSHPDT
        , ZZOVERRIDE
        , ZZFREIGHT
        , ZZCOST
        , ZZASN
        , GLREQUEST
        , GLSOURCESYSTEM
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PO_ITEM_HK = JOIN_RESULT.PO_ITEM_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by PO_ITEM_HK, ETENR, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PO_ITEM_HK,
GR.VALUE::text AS EBELN,
GR.VALUE::text AS EBELP,
GR.VALUE::text AS ETENR,
NULL AS MANDT,
NULL AS EINDT,
NULL AS SLFDT,
NULL AS LPEIN,
NULL AS MENGE,
NULL AS AMENG,
NULL AS WEMNG,
NULL AS WAMNG,
NULL AS UZEIT,
NULL AS BANFN,
NULL AS BNFPO,
NULL AS ESTKZ,
NULL AS QUNUM,
NULL AS QUPOS,
NULL AS MAHNZ,
NULL AS BEDAT,
NULL AS RSNUM,
NULL AS SERNR,
NULL AS FIXKZ,
NULL AS GLMNG,
NULL AS DABMG,
NULL AS CHARG,
NULL AS LICHA,
NULL AS CHKOM,
NULL AS VERID,
NULL AS ABART,
NULL AS MNG02,
NULL AS DAT01,
NULL AS ALTDT,
NULL AS AULWE,
NULL AS MBDAT,
NULL AS MBUHR,
NULL AS LDDAT,
NULL AS LDUHR,
NULL AS TDDAT,
NULL AS TDUHR,
NULL AS WADAT,
NULL AS WAUHR,
NULL AS ELDAT,
NULL AS ELUHR,
NULL AS ANZSN,
NULL AS NODISP,
NULL AS GEO_ROUTE,
NULL AS ROUTE_GTS,
NULL AS GTS_IND,
NULL AS TSP,
NULL AS CD_LOCNO,
NULL AS CD_LOCTYPE,
NULL AS HANDOVERDATE,
NULL AS HANDOVERTIME,
NULL AS FSH_RALLOC_QTY,
NULL AS FSH_SALLOC_QTY,
NULL AS FSH_OS_ID,
NULL AS KEY_ID,
NULL AS OTB_VALUE,
NULL AS OTB_CURR,
NULL AS OTB_RES_VALUE,
NULL AS OTB_SPEC_VALUE,
NULL AS SPR_RSN_PROFILE,
NULL AS BUDG_TYPE,
NULL AS OTB_STATUS,
NULL AS OTB_REASON,
NULL AS CHECK_TYPE,
NULL AS DL_ID,
NULL AS HANDOVER_DATE,
NULL AS NO_SCEM,
NULL AS DNG_DATE,
NULL AS DNG_TIME,
NULL AS CNCL_ANCMNT_DONE,
NULL AS DATESHIFT_NUMBER,
NULL AS ZZSHPDT,
NULL AS ZZOVERRIDE,
NULL AS ZZFREIGHT,
NULL AS ZZCOST,
NULL AS ZZASN,
NULL AS GLREQUEST,
NULL AS GLSOURCESYSTEM,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
'N' AS PSA_DELETE_IND,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
