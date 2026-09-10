---- SRC LAYER ----
WITH
SRC_VBEP           as ( SELECT * FROM {{ ref('v_psa_stg_sales_order_item_scheduled_shipping__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %} )

/*
SRC_VBEP           as ( SELECT * FROM STAGING.v_psa_stg_sales_order_item_scheduled_shipping__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_VBEP as (
    SELECT
        SO_ITEM_LHK
      , MANDT
      , VBELN
      , POSNR
      , ETENR
      , GLREQUEST
      , ETTYP
      , LFREL
      , EDATU
      , EZEIT
      , WMENG
      , BMENG
      , VRKME
      , LMENG
      , MEINS
      , BDDAT
      , BDDAT_DT
      , BDART
      , PLART
      , VBELE
      , POSNE
      , ETENE
      , RSDAT
      , RSDAT_DT
      , IDNNR
      , BANFN
      , BSART
      , BSTYP
      , WEPOS
      , REPOS
      , LRGDT
      , PRGRS
      , TDDAT
      , MBDAT
      , MBDAT_DT
      , LDDAT
      , LDDAT_DT
      , WADAT
      , WADAT_DT
      , CMENG
      , LIFSP
      , GRSTR
      , ABART
      , ABRUF
      , ROMS1
      , ROMS2
      , ROMS3
      , ROMEI
      , RFORM
      , UMVKZ
      , UMVKN
      , VERFP
      , BWART
      , BNFPO
      , ETART
      , AUFNR
      , PLNUM
      , SERNR
      , AESKD
      , ABGES
      , MBUHR
      , TDUHR
      , LDUHR
      , WAUHR
      , AULWE
      , HANDOVERDATE
      , HANDOVERTIME
      , _DATAAGING
      , FSH_RALLOC_QTY
      , FSH_OS_ID
      , FSH_PQR_RC
      , MBDAT_DRS
      , ZZRSD
      , ZZMAD
      , ZZREC
      , ZZORV
      , ZZRST
      , ZZPDT
      , ZZPDTCNT
      , ZZOPDT
      , ZZCRSDCODE
      , ZZKUNWE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PAYER_PARVW
      , BILLTO_PARVW
      , SHIPTO_PARVW
      , SOLDTO_PARVW
      , INSURANCE_PARVW
      , PAYER_KUNNR
      , BILLTO_KUNNR
      , SHIPTO_KUNNR
      , SOLDTO_KUNNR
      , INSURANCE_KUNNR
      , VBAP_MATNR
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_VBEP
)
---- RENAME LAYER ----

, RENAME_VBEP as (
    SELECT
        SO_ITEM_LHK
      , MANDT
      , VBELN
      , POSNR
      , ETENR
      , GLREQUEST
      , ETTYP
      , LFREL
      , EDATU
      , EZEIT
      , WMENG
      , BMENG
      , VRKME
      , LMENG
      , MEINS
      , BDDAT
      , BDDAT_DT
      , BDART
      , PLART
      , VBELE
      , POSNE
      , ETENE
      , RSDAT
      , RSDAT_DT
      , IDNNR
      , BANFN
      , BSART
      , BSTYP
      , WEPOS
      , REPOS
      , LRGDT
      , PRGRS
      , TDDAT
      , MBDAT
      , MBDAT_DT
      , LDDAT
      , LDDAT_DT
      , WADAT
      , WADAT_DT
      , CMENG
      , LIFSP
      , GRSTR
      , ABART
      , ABRUF
      , ROMS1
      , ROMS2
      , ROMS3
      , ROMEI
      , RFORM
      , UMVKZ
      , UMVKN
      , VERFP
      , BWART
      , BNFPO
      , ETART
      , AUFNR
      , PLNUM
      , SERNR
      , AESKD
      , ABGES
      , MBUHR
      , TDUHR
      , LDUHR
      , WAUHR
      , AULWE
      , HANDOVERDATE
      , HANDOVERTIME
      , _DATAAGING
      , FSH_RALLOC_QTY
      , FSH_OS_ID
      , FSH_PQR_RC
      , MBDAT_DRS
      , ZZRSD
      , ZZMAD
      , ZZREC
      , ZZORV
      , ZZRST
      , ZZPDT
      , ZZPDTCNT
      , ZZOPDT
      , ZZCRSDCODE
      , ZZKUNWE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PAYER_PARVW
      , BILLTO_PARVW
      , SHIPTO_PARVW
      , SOLDTO_PARVW
      , INSURANCE_PARVW
      , PAYER_KUNNR
      , BILLTO_KUNNR
      , SHIPTO_KUNNR
      , SOLDTO_KUNNR
      , INSURANCE_KUNNR
      , VBAP_MATNR
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_VBEP
)
---- FILTER LAYER ----

, FILTER_VBEP as (
    SELECT *
    FROM RENAME_VBEP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_VBEP
)

---- FINAL LAYER ----
SELECT
          SO_ITEM_LHK
        , MANDT
        , VBELN
        , POSNR
        , ETENR
        , GLREQUEST
        , ETTYP
        , LFREL
        , EDATU
        , EZEIT
        , WMENG
        , BMENG
        , VRKME
        , LMENG
        , MEINS
        , BDDAT
        , BDDAT_DT
        , BDART
        , PLART
        , VBELE
        , POSNE
        , ETENE
        , RSDAT
        , RSDAT_DT
        , IDNNR
        , BANFN
        , BSART
        , BSTYP
        , WEPOS
        , REPOS
        , LRGDT
        , PRGRS
        , TDDAT
        , MBDAT
        , MBDAT_DT
        , LDDAT
        , LDDAT_DT
        , WADAT
        , WADAT_DT
        , CMENG
        , LIFSP
        , GRSTR
        , ABART
        , ABRUF
        , ROMS1
        , ROMS2
        , ROMS3
        , ROMEI
        , RFORM
        , UMVKZ
        , UMVKN
        , VERFP
        , BWART
        , BNFPO
        , ETART
        , AUFNR
        , PLNUM
        , SERNR
        , AESKD
        , ABGES
        , MBUHR
        , TDUHR
        , LDUHR
        , WAUHR
        , AULWE
        , HANDOVERDATE
        , HANDOVERTIME
        , _DATAAGING
        , FSH_RALLOC_QTY
        , FSH_OS_ID
        , FSH_PQR_RC
        , MBDAT_DRS
        , ZZRSD
        , ZZMAD
        , ZZREC
        , ZZORV
        , ZZRST
        , ZZPDT
        , ZZPDTCNT
        , ZZOPDT
        , ZZCRSDCODE
        , ZZKUNWE
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PAYER_PARVW
        , BILLTO_PARVW
        , SHIPTO_PARVW
        , SOLDTO_PARVW
        , INSURANCE_PARVW
        , PAYER_KUNNR
        , BILLTO_KUNNR
        , SHIPTO_KUNNR
        , SOLDTO_KUNNR
        , INSURANCE_KUNNR
        , VBAP_MATNR
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.SO_ITEM_LHK = JOIN_RESULT.SO_ITEM_LHK
    AND   existing.VBELN = JOIN_RESULT.VBELN
    AND   existing.POSNR = JOIN_RESULT.POSNR
    AND   existing.ETENR = JOIN_RESULT.ETENR
    AND   existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by SO_ITEM_LHK, VBELN, POSNR, ETENR, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS SO_ITEM_LHK,
NULL AS MANDT,
GR.VALUE::text AS VBELN,
GR.VALUE::text AS POSNR,
GR.VALUE::text AS ETENR,
NULL AS GLREQUEST,
NULL AS ETTYP,
NULL AS LFREL,
NULL AS EDATU,
NULL AS EZEIT,
NULL AS WMENG,
NULL AS BMENG,
NULL AS VRKME,
NULL AS LMENG,
NULL AS MEINS,
NULL AS BDDAT,
NULL AS BDDAT_DT,
NULL AS BDART,
NULL AS PLART,
NULL AS VBELE,
NULL AS POSNE,
NULL AS ETENE,
NULL AS RSDAT,
NULL AS RSDAT_DT,
NULL AS IDNNR,
NULL AS BANFN,
NULL AS BSART,
NULL AS BSTYP,
NULL AS WEPOS,
NULL AS REPOS,
NULL AS LRGDT,
NULL AS PRGRS,
NULL AS TDDAT,
NULL AS MBDAT,
NULL AS MBDAT_DT,
NULL AS LDDAT,
NULL AS LDDAT_DT,
NULL AS WADAT,
NULL AS WADAT_DT,
NULL AS CMENG,
NULL AS LIFSP,
NULL AS GRSTR,
NULL AS ABART,
NULL AS ABRUF,
NULL AS ROMS1,
NULL AS ROMS2,
NULL AS ROMS3,
NULL AS ROMEI,
NULL AS RFORM,
NULL AS UMVKZ,
NULL AS UMVKN,
NULL AS VERFP,
NULL AS BWART,
NULL AS BNFPO,
NULL AS ETART,
NULL AS AUFNR,
NULL AS PLNUM,
NULL AS SERNR,
NULL AS AESKD,
NULL AS ABGES,
NULL AS MBUHR,
NULL AS TDUHR,
NULL AS LDUHR,
NULL AS WAUHR,
NULL AS AULWE,
NULL AS HANDOVERDATE,
NULL AS HANDOVERTIME,
NULL AS _DATAAGING,
NULL AS FSH_RALLOC_QTY,
NULL AS FSH_OS_ID,
NULL AS FSH_PQR_RC,
NULL AS MBDAT_DRS,
NULL AS ZZRSD,
NULL AS ZZMAD,
NULL AS ZZREC,
NULL AS ZZORV,
NULL AS ZZRST,
NULL AS ZZPDT,
NULL AS ZZPDTCNT,
NULL AS ZZOPDT,
NULL AS ZZCRSDCODE,
NULL AS ZZKUNWE,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLSOURCESYSTEM,
NULL AS PAYER_PARVW,
NULL AS BILLTO_PARVW,
NULL AS SHIPTO_PARVW,
NULL AS SOLDTO_PARVW,
NULL AS INSURANCE_PARVW,
GR.VALUE::text AS PAYER_KUNNR,
GR.VALUE::text AS BILLTO_KUNNR,
GR.VALUE::text AS SHIPTO_KUNNR,
GR.VALUE::text AS SOLDTO_KUNNR,
GR.VALUE::text AS INSURANCE_KUNNR,
GR.VALUE::text AS VBAP_MATNR,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
