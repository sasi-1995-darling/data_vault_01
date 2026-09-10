---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ ref('v_psa_stg_po_receipt__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_a              as ( SELECT * FROM STAGING.v_psa_stg_po_receipt__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        LNK_PO_RECEIPT_HK
      , EBELN
      , EBELP
      , BELNR
      , BUZEI
      , MATNR
      , WERKS
      , MANDT
      , ZEKKN
      , VGABE
      , GJAHR
      , GLREQUEST
      , GLSOURCESYSTEM
      , BEWTP
      , BWART
      , BUDAT
      , MENGE
      , BPMNG
      , DMBTR
      , WRBTR
      , WAERS
      , AREWR
      , WESBS
      , BPWES
      , SHKZG
      , BWTAR
      , ELIKZ
      , XBLNR
      , LFGJA
      , LFBNR
      , LFPOS
      , GRUND
      , CPUDT
      , CPUTM
      , REEWR
      , EVERE
      , REFWR
      , XWSBR
      , ETENS
      , KNUMV
      , MWSKZ
      , LSMNG
      , LSMEH
      , EMATN
      , AREWW
      , HSWAE
      , BAMNG
      , CHARG
      , BLDAT
      , XWOFF
      , XUNPL
      , ERNAM
      , SRVPOS
      , PACKNO
      , INTROW
      , BEKKN
      , LEMIN
      , AREWB
      , REWRB
      , SAPRL
      , MENGE_POP
      , BPMNG_POP
      , DMBTR_POP
      , WRBTR_POP
      , WESBB
      , BPWEB
      , WEORA
      , AREWR_POP
      , KUDIF
      , RETAMT_FC
      , RETAMT_LC
      , RETAMTP_FC
      , RETAMTP_LC
      , XMACC
      , WKURS
      , INV_ITEM_ORIGIN
      , VBELN_ST
      , VBELP_ST
      , SGT_SCAT
      , ET_UPD
      , J_SC_DIE_COMP_F
      , FSH_SEASON_YEAR
      , FSH_SEASON
      , FSH_COLLECTION
      , FSH_THEME
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        LNK_PO_RECEIPT_HK
      , EBELN
      , EBELP
      , BELNR
      , BUZEI
      , MATNR
      , WERKS
      , MANDT
      , ZEKKN
      , VGABE
      , GJAHR
      , GLREQUEST
      , GLSOURCESYSTEM
      , BEWTP
      , BWART
      , BUDAT
      , MENGE
      , BPMNG
      , DMBTR
      , WRBTR
      , WAERS
      , AREWR
      , WESBS
      , BPWES
      , SHKZG
      , BWTAR
      , ELIKZ
      , XBLNR
      , LFGJA
      , LFBNR
      , LFPOS
      , GRUND
      , CPUDT
      , CPUTM
      , REEWR
      , EVERE
      , REFWR
      , XWSBR
      , ETENS
      , KNUMV
      , MWSKZ
      , LSMNG
      , LSMEH
      , EMATN
      , AREWW
      , HSWAE
      , BAMNG
      , CHARG
      , BLDAT
      , XWOFF
      , XUNPL
      , ERNAM
      , SRVPOS
      , PACKNO
      , INTROW
      , BEKKN
      , LEMIN
      , AREWB
      , REWRB
      , SAPRL
      , MENGE_POP
      , BPMNG_POP
      , DMBTR_POP
      , WRBTR_POP
      , WESBB
      , BPWEB
      , WEORA
      , AREWR_POP
      , KUDIF
      , RETAMT_FC
      , RETAMT_LC
      , RETAMTP_FC
      , RETAMTP_LC
      , XMACC
      , WKURS
      , INV_ITEM_ORIGIN
      , VBELN_ST
      , VBELP_ST
      , SGT_SCAT
      , ET_UPD
      , J_SC_DIE_COMP_F
      , FSH_SEASON_YEAR
      , FSH_SEASON
      , FSH_COLLECTION
      , FSH_THEME
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
      , BKCC
      , REC_SRC
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
          LNK_PO_RECEIPT_HK
        , EBELN
        , EBELP
        , BELNR
        , BUZEI
        , MATNR
        , WERKS
        , MANDT
        , ZEKKN
        , VGABE
        , GJAHR
        , GLREQUEST
        , GLSOURCESYSTEM
        , BEWTP
        , BWART
        , BUDAT
        , MENGE
        , BPMNG
        , DMBTR
        , WRBTR
        , WAERS
        , AREWR
        , WESBS
        , BPWES
        , SHKZG
        , BWTAR
        , ELIKZ
        , XBLNR
        , LFGJA
        , LFBNR
        , LFPOS
        , GRUND
        , CPUDT
        , CPUTM
        , REEWR
        , EVERE
        , REFWR
        , XWSBR
        , ETENS
        , KNUMV
        , MWSKZ
        , LSMNG
        , LSMEH
        , EMATN
        , AREWW
        , HSWAE
        , BAMNG
        , CHARG
        , BLDAT
        , XWOFF
        , XUNPL
        , ERNAM
        , SRVPOS
        , PACKNO
        , INTROW
        , BEKKN
        , LEMIN
        , AREWB
        , REWRB
        , SAPRL
        , MENGE_POP
        , BPMNG_POP
        , DMBTR_POP
        , WRBTR_POP
        , WESBB
        , BPWEB
        , WEORA
        , AREWR_POP
        , KUDIF
        , RETAMT_FC
        , RETAMT_LC
        , RETAMTP_FC
        , RETAMTP_LC
        , XMACC
        , WKURS
        , INV_ITEM_ORIGIN
        , VBELN_ST
        , VBELP_ST
        , SGT_SCAT
        , ET_UPD
        , J_SC_DIE_COMP_F
        , FSH_SEASON_YEAR
        , FSH_SEASON
        , FSH_COLLECTION
        , FSH_THEME
        , WRF_CHARSTC1
        , WRF_CHARSTC2
        , WRF_CHARSTC3
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , LOAD_DTS
        , BKCC
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_PO_RECEIPT_HK = JOIN_RESULT.LNK_PO_RECEIPT_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by LNK_PO_RECEIPT_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_PO_RECEIPT_HK,
GR.VALUE::text AS EBELN,
GR.VALUE::text AS EBELP,
GR.VALUE::text AS BELNR,
GR.VALUE::text AS BUZEI,
GR.VALUE::text AS MATNR,
GR.VALUE::text AS WERKS,
NULL AS MANDT,
NULL AS ZEKKN,
NULL AS VGABE,
NULL AS GJAHR,
NULL AS GLREQUEST,
NULL AS GLSOURCESYSTEM,
NULL AS BEWTP,
NULL AS BWART,
NULL AS BUDAT,
NULL AS MENGE,
NULL AS BPMNG,
NULL AS DMBTR,
NULL AS WRBTR,
NULL AS WAERS,
NULL AS AREWR,
NULL AS WESBS,
NULL AS BPWES,
NULL AS SHKZG,
NULL AS BWTAR,
NULL AS ELIKZ,
NULL AS XBLNR,
NULL AS LFGJA,
NULL AS LFBNR,
NULL AS LFPOS,
NULL AS GRUND,
NULL AS CPUDT,
NULL AS CPUTM,
NULL AS REEWR,
NULL AS EVERE,
NULL AS REFWR,
NULL AS XWSBR,
NULL AS ETENS,
NULL AS KNUMV,
NULL AS MWSKZ,
NULL AS LSMNG,
NULL AS LSMEH,
NULL AS EMATN,
NULL AS AREWW,
NULL AS HSWAE,
NULL AS BAMNG,
NULL AS CHARG,
NULL AS BLDAT,
NULL AS XWOFF,
NULL AS XUNPL,
NULL AS ERNAM,
NULL AS SRVPOS,
NULL AS PACKNO,
NULL AS INTROW,
NULL AS BEKKN,
NULL AS LEMIN,
NULL AS AREWB,
NULL AS REWRB,
NULL AS SAPRL,
NULL AS MENGE_POP,
NULL AS BPMNG_POP,
NULL AS DMBTR_POP,
NULL AS WRBTR_POP,
NULL AS WESBB,
NULL AS BPWEB,
NULL AS WEORA,
NULL AS AREWR_POP,
NULL AS KUDIF,
NULL AS RETAMT_FC,
NULL AS RETAMT_LC,
NULL AS RETAMTP_FC,
NULL AS RETAMTP_LC,
NULL AS XMACC,
NULL AS WKURS,
NULL AS INV_ITEM_ORIGIN,
NULL AS VBELN_ST,
NULL AS VBELP_ST,
NULL AS SGT_SCAT,
NULL AS ET_UPD,
NULL AS J_SC_DIE_COMP_F,
NULL AS FSH_SEASON_YEAR,
NULL AS FSH_SEASON,
NULL AS FSH_COLLECTION,
NULL AS FSH_THEME,
NULL AS WRF_CHARSTC1,
NULL AS WRF_CHARSTC2,
NULL AS WRF_CHARSTC3,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
