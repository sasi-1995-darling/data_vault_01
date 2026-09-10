---- SRC LAYER ----
WITH
SRC_R              as ( SELECT * FROM {{ ref('v_psa_stg_reservation_line__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_R              as ( SELECT * FROM STAGING.V_PSA_STG_RESERVATION_ITEM__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_R as (
    SELECT
        LNK_DEPENDENCY_RESERVATION_HK
      , MANDT
      , RSNUM
      , RSPOS
      , RSART
      , GLREQUEST
      , BDART
      , RSSTA
      , XLOEK
      , XWAOK
      , KZEAR
      , XFEHL
      , MATNR
      , WERKS
      , LGORT
      , PRVBE
      , CHARG
      , PLPLA
      , SOBKZ
      , BDTER
      , BDMNG
      , MEINS
      , SHKZG
      , FMENG
      , ENMNG
      , ENWRT
      , WAERS
      , ERFMG
      , ERFME
      , PLNUM
      , BANFN
      , BNFPO
      , AUFNR
      , BAUGR
      , SERNR
      , KDAUF
      , KDPOS
      , KDEIN
      , PROJN
      , BWART
      , SAKNR
      , GSBER
      , UMWRK
      , UMLGO
      , NAFKZ
      , NOMAT
      , NOMNG
      , POSTP
      , POSNR
      , ROMS1
      , ROMS2
      , ROMS3
      , ROMEI
      , ROMEN
      , SGTXT
      , LMENG
      , ROHPS
      , RFORM
      , ROANZ
      , FLMNG
      , STLTY
      , STLNR
      , STLKN
      , STPOZ
      , LTXSP
      , POTX1
      , POTX2
      , SANKA
      , ALPOS
      , EWAHR
      , AUSCH
      , AVOAU
      , NETAU
      , NLFZT
      , AENNR
      , UMREZ
      , UMREN
      , SORTF
      , SBTER
      , VERTI
      , SCHGT
      , UPSKZ
      , DBSKZ
      , TXTPS
      , DUMPS
      , BEIKZ
      , ERSKZ
      , AUFST
      , AUFWG
      , BAUST
      , BAUWG
      , AUFPS
      , EBELN
      , EBELP
      , EBELE
      , KNTTP
      , KZVBR
      , PSPEL
      , AUFPL
      , PLNFL
      , VORNR
      , APLZL
      , OBJNR
      , FLGAT
      , GPREIS
      , FPREIS
      , PEINH
      , RGEKZ
      , EKGRP
      , ROKME
      , ZUMEI
      , ZUMS1
      , ZUMS2
      , ZUMS3
      , ZUDIV
      , VMENG
      , PRREG
      , LIFZT
      , CUOBJ
      , KFPOS
      , REVLV
      , BERKZ
      , LGNUM
      , LGTYP
      , LGPLA
      , TBMNG
      , NPTXTKY
      , KBNKZ
      , KZKUP
      , AFPOS
      , NO_DISP
      , BDZTP
      , ESMNG
      , ALPGR
      , ALPRF
      , ALPST
      , KZAUS
      , NFEAG
      , NFPKZ
      , NFGRP
      , NFUML
      , ADRNR
      , CHOBJ
      , SPLKZ
      , SPLRV
      , KNUMH
      , WEMPF
      , ABLAD
      , HKMAT
      , HRKFT
      , VORAB
      , MATKL
      , FRUNV
      , CLAKZ
      , INPOS
      , WEBAZ
      , LIFNR
      , FLGEX
      , FUNCT
      , GPREIS_2
      , FPREIS_2
      , PEINH_2
      , INFNR
      , KZECH
      , KZMPF
      , STLAL
      , PBDNR
      , STVKN
      , KTOMA
      , VRPLA
      , KZBWS
      , NLFZV
      , NLFMV
      , TECHS
      , OBJTYPE
      , CH_PROC
      , FXPRU
      , UMSOK
      , VORAB_SM
      , FIPOS
      , FIPEX
      , FISTL
      , GEBER
      , GRANT_NBR
      , FKBER
      , PRIO_URG
      , PRIO_REQ
      , KBLNR
      , KBLPOS
      , BUDGET_PD
      , SC_OBJECT_ID
      , SC_ITM_NO
      , SGT_SCAT
      , SGT_RCAT
      , FMFGUS_KEY
      , ADVCODE
      , FSH_RALLOC_QTY
      , FSH_CRITICAL_COMP
      , FSH_CRITICAL_LEVEL
      , WTY_IND
      , R_PART_INDICATOR
      , WTYSC_CLMITEM
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_R
)
---- RENAME LAYER ----

, RENAME_R as (
    SELECT
        LNK_DEPENDENCY_RESERVATION_HK
      , MANDT
      , RSNUM
      , RSPOS
      , RSART
      , GLREQUEST
      , BDART
      , RSSTA
      , XLOEK
      , XWAOK
      , KZEAR
      , XFEHL
      , MATNR
      , WERKS
      , LGORT
      , PRVBE
      , CHARG
      , PLPLA
      , SOBKZ
      , BDTER
      , BDMNG
      , MEINS
      , SHKZG
      , FMENG
      , ENMNG
      , ENWRT
      , WAERS
      , ERFMG
      , ERFME
      , PLNUM
      , BANFN
      , BNFPO
      , AUFNR
      , BAUGR
      , SERNR
      , KDAUF
      , KDPOS
      , KDEIN
      , PROJN
      , BWART
      , SAKNR
      , GSBER
      , UMWRK
      , UMLGO
      , NAFKZ
      , NOMAT
      , NOMNG
      , POSTP
      , POSNR
      , ROMS1
      , ROMS2
      , ROMS3
      , ROMEI
      , ROMEN
      , SGTXT
      , LMENG
      , ROHPS
      , RFORM
      , ROANZ
      , FLMNG
      , STLTY
      , STLNR
      , STLKN
      , STPOZ
      , LTXSP
      , POTX1
      , POTX2
      , SANKA
      , ALPOS
      , EWAHR
      , AUSCH
      , AVOAU
      , NETAU
      , NLFZT
      , AENNR
      , UMREZ
      , UMREN
      , SORTF
      , SBTER
      , VERTI
      , SCHGT
      , UPSKZ
      , DBSKZ
      , TXTPS
      , DUMPS
      , BEIKZ
      , ERSKZ
      , AUFST
      , AUFWG
      , BAUST
      , BAUWG
      , AUFPS
      , EBELN
      , EBELP
      , EBELE
      , KNTTP
      , KZVBR
      , PSPEL
      , AUFPL
      , PLNFL
      , VORNR
      , APLZL
      , OBJNR
      , FLGAT
      , GPREIS
      , FPREIS
      , PEINH
      , RGEKZ
      , EKGRP
      , ROKME
      , ZUMEI
      , ZUMS1
      , ZUMS2
      , ZUMS3
      , ZUDIV
      , VMENG
      , PRREG
      , LIFZT
      , CUOBJ
      , KFPOS
      , REVLV
      , BERKZ
      , LGNUM
      , LGTYP
      , LGPLA
      , TBMNG
      , NPTXTKY
      , KBNKZ
      , KZKUP
      , AFPOS
      , NO_DISP
      , BDZTP
      , ESMNG
      , ALPGR
      , ALPRF
      , ALPST
      , KZAUS
      , NFEAG
      , NFPKZ
      , NFGRP
      , NFUML
      , ADRNR
      , CHOBJ
      , SPLKZ
      , SPLRV
      , KNUMH
      , WEMPF
      , ABLAD
      , HKMAT
      , HRKFT
      , VORAB
      , MATKL
      , FRUNV
      , CLAKZ
      , INPOS
      , WEBAZ
      , LIFNR
      , FLGEX
      , FUNCT
      , GPREIS_2
      , FPREIS_2
      , PEINH_2
      , INFNR
      , KZECH
      , KZMPF
      , STLAL
      , PBDNR
      , STVKN
      , KTOMA
      , VRPLA
      , KZBWS
      , NLFZV
      , NLFMV
      , TECHS
      , OBJTYPE
      , CH_PROC
      , FXPRU
      , UMSOK
      , VORAB_SM
      , FIPOS
      , FIPEX
      , FISTL
      , GEBER
      , GRANT_NBR
      , FKBER
      , PRIO_URG
      , PRIO_REQ
      , KBLNR
      , KBLPOS
      , BUDGET_PD
      , SC_OBJECT_ID
      , SC_ITM_NO
      , SGT_SCAT
      , SGT_RCAT
      , FMFGUS_KEY
      , ADVCODE
      , FSH_RALLOC_QTY
      , FSH_CRITICAL_COMP
      , FSH_CRITICAL_LEVEL
      , WTY_IND
      , R_PART_INDICATOR
      , WTYSC_CLMITEM
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_R
)
---- FILTER LAYER ----

, FILTER_R as (
    SELECT *
    FROM RENAME_R
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_R
)

---- FINAL LAYER ----
SELECT
          LNK_DEPENDENCY_RESERVATION_HK
        , MANDT
        , RSNUM
        , RSPOS
        , RSART
        , GLREQUEST
        , BDART
        , RSSTA
        , XLOEK
        , XWAOK
        , KZEAR
        , XFEHL
        , MATNR
        , WERKS
        , LGORT
        , PRVBE
        , CHARG
        , PLPLA
        , SOBKZ
        , BDTER
        , BDMNG
        , MEINS
        , SHKZG
        , FMENG
        , ENMNG
        , ENWRT
        , WAERS
        , ERFMG
        , ERFME
        , PLNUM
        , BANFN
        , BNFPO
        , AUFNR
        , BAUGR
        , SERNR
        , KDAUF
        , KDPOS
        , KDEIN
        , PROJN
        , BWART
        , SAKNR
        , GSBER
        , UMWRK
        , UMLGO
        , NAFKZ
        , NOMAT
        , NOMNG
        , POSTP
        , POSNR
        , ROMS1
        , ROMS2
        , ROMS3
        , ROMEI
        , ROMEN
        , SGTXT
        , LMENG
        , ROHPS
        , RFORM
        , ROANZ
        , FLMNG
        , STLTY
        , STLNR
        , STLKN
        , STPOZ
        , LTXSP
        , POTX1
        , POTX2
        , SANKA
        , ALPOS
        , EWAHR
        , AUSCH
        , AVOAU
        , NETAU
        , NLFZT
        , AENNR
        , UMREZ
        , UMREN
        , SORTF
        , SBTER
        , VERTI
        , SCHGT
        , UPSKZ
        , DBSKZ
        , TXTPS
        , DUMPS
        , BEIKZ
        , ERSKZ
        , AUFST
        , AUFWG
        , BAUST
        , BAUWG
        , AUFPS
        , EBELN
        , EBELP
        , EBELE
        , KNTTP
        , KZVBR
        , PSPEL
        , AUFPL
        , PLNFL
        , VORNR
        , APLZL
        , OBJNR
        , FLGAT
        , GPREIS
        , FPREIS
        , PEINH
        , RGEKZ
        , EKGRP
        , ROKME
        , ZUMEI
        , ZUMS1
        , ZUMS2
        , ZUMS3
        , ZUDIV
        , VMENG
        , PRREG
        , LIFZT
        , CUOBJ
        , KFPOS
        , REVLV
        , BERKZ
        , LGNUM
        , LGTYP
        , LGPLA
        , TBMNG
        , NPTXTKY
        , KBNKZ
        , KZKUP
        , AFPOS
        , NO_DISP
        , BDZTP
        , ESMNG
        , ALPGR
        , ALPRF
        , ALPST
        , KZAUS
        , NFEAG
        , NFPKZ
        , NFGRP
        , NFUML
        , ADRNR
        , CHOBJ
        , SPLKZ
        , SPLRV
        , KNUMH
        , WEMPF
        , ABLAD
        , HKMAT
        , HRKFT
        , VORAB
        , MATKL
        , FRUNV
        , CLAKZ
        , INPOS
        , WEBAZ
        , LIFNR
        , FLGEX
        , FUNCT
        , GPREIS_2
        , FPREIS_2
        , PEINH_2
        , INFNR
        , KZECH
        , KZMPF
        , STLAL
        , PBDNR
        , STVKN
        , KTOMA
        , VRPLA
        , KZBWS
        , NLFZV
        , NLFMV
        , TECHS
        , OBJTYPE
        , CH_PROC
        , FXPRU
        , UMSOK
        , VORAB_SM
        , FIPOS
        , FIPEX
        , FISTL
        , GEBER
        , GRANT_NBR
        , FKBER
        , PRIO_URG
        , PRIO_REQ
        , KBLNR
        , KBLPOS
        , BUDGET_PD
        , SC_OBJECT_ID
        , SC_ITM_NO
        , SGT_SCAT
        , SGT_RCAT
        , FMFGUS_KEY
        , ADVCODE
        , FSH_RALLOC_QTY
        , FSH_CRITICAL_COMP
        , FSH_CRITICAL_LEVEL
        , WTY_IND
        , R_PART_INDICATOR
        , WTYSC_CLMITEM
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
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
    WHERE existing.LNK_DEPENDENCY_RESERVATION_HK = JOIN_RESULT.LNK_DEPENDENCY_RESERVATION_HK  
   AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by LNK_DEPENDENCY_RESERVATION_HK, SC_OBJECT_ID, FMFGUS_KEY, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_DEPENDENCY_RESERVATION_HK,
NULL AS MANDT,
GR.VALUE::text AS RSNUM,
GR.VALUE::text AS RSPOS,
GR.VALUE::text AS RSART,
NULL AS GLREQUEST,
NULL AS BDART,
NULL AS RSSTA,
NULL AS XLOEK,
NULL AS XWAOK,
NULL AS KZEAR,
NULL AS XFEHL,
NULL AS MATNR,
NULL AS WERKS,
NULL AS LGORT,
NULL AS PRVBE,
NULL AS CHARG,
NULL AS PLPLA,
NULL AS SOBKZ,
NULL AS BDTER,
NULL AS BDMNG,
NULL AS MEINS,
NULL AS SHKZG,
NULL AS FMENG,
NULL AS ENMNG,
NULL AS ENWRT,
NULL AS WAERS,
NULL AS ERFMG,
NULL AS ERFME,
NULL AS PLNUM,
NULL AS BANFN,
NULL AS BNFPO,
NULL AS AUFNR,
NULL AS BAUGR,
NULL AS SERNR,
NULL AS KDAUF,
NULL AS KDPOS,
NULL AS KDEIN,
NULL AS PROJN,
NULL AS BWART,
NULL AS SAKNR,
NULL AS GSBER,
NULL AS UMWRK,
NULL AS UMLGO,
NULL AS NAFKZ,
NULL AS NOMAT,
NULL AS NOMNG,
NULL AS POSTP,
NULL AS POSNR,
NULL AS ROMS1,
NULL AS ROMS2,
NULL AS ROMS3,
NULL AS ROMEI,
NULL AS ROMEN,
NULL AS SGTXT,
NULL AS LMENG,
NULL AS ROHPS,
NULL AS RFORM,
NULL AS ROANZ,
NULL AS FLMNG,
NULL AS STLTY,
NULL AS STLNR,
NULL AS STLKN,
NULL AS STPOZ,
NULL AS LTXSP,
NULL AS POTX1,
NULL AS POTX2,
NULL AS SANKA,
NULL AS ALPOS,
NULL AS EWAHR,
NULL AS AUSCH,
NULL AS AVOAU,
NULL AS NETAU,
NULL AS NLFZT,
NULL AS AENNR,
NULL AS UMREZ,
NULL AS UMREN,
NULL AS SORTF,
NULL AS SBTER,
NULL AS VERTI,
NULL AS SCHGT,
NULL AS UPSKZ,
NULL AS DBSKZ,
NULL AS TXTPS,
NULL AS DUMPS,
NULL AS BEIKZ,
NULL AS ERSKZ,
NULL AS AUFST,
NULL AS AUFWG,
NULL AS BAUST,
NULL AS BAUWG,
NULL AS AUFPS,
NULL AS EBELN,
NULL AS EBELP,
NULL AS EBELE,
NULL AS KNTTP,
NULL AS KZVBR,
NULL AS PSPEL,
NULL AS AUFPL,
NULL AS PLNFL,
NULL AS VORNR,
NULL AS APLZL,
NULL AS OBJNR,
NULL AS FLGAT,
NULL AS GPREIS,
NULL AS FPREIS,
NULL AS PEINH,
NULL AS RGEKZ,
NULL AS EKGRP,
NULL AS ROKME,
NULL AS ZUMEI,
NULL AS ZUMS1,
NULL AS ZUMS2,
NULL AS ZUMS3,
NULL AS ZUDIV,
NULL AS VMENG,
NULL AS PRREG,
NULL AS LIFZT,
NULL AS CUOBJ,
NULL AS KFPOS,
NULL AS REVLV,
NULL AS BERKZ,
NULL AS LGNUM,
NULL AS LGTYP,
NULL AS LGPLA,
NULL AS TBMNG,
NULL AS NPTXTKY,
NULL AS KBNKZ,
NULL AS KZKUP,
NULL AS AFPOS,
NULL AS NO_DISP,
NULL AS BDZTP,
NULL AS ESMNG,
NULL AS ALPGR,
NULL AS ALPRF,
NULL AS ALPST,
NULL AS KZAUS,
NULL AS NFEAG,
NULL AS NFPKZ,
NULL AS NFGRP,
NULL AS NFUML,
NULL AS ADRNR,
NULL AS CHOBJ,
NULL AS SPLKZ,
NULL AS SPLRV,
NULL AS KNUMH,
NULL AS WEMPF,
NULL AS ABLAD,
NULL AS HKMAT,
NULL AS HRKFT,
NULL AS VORAB,
NULL AS MATKL,
NULL AS FRUNV,
NULL AS CLAKZ,
NULL AS INPOS,
NULL AS WEBAZ,
NULL AS LIFNR,
NULL AS FLGEX,
NULL AS FUNCT,
NULL AS GPREIS_2,
NULL AS FPREIS_2,
NULL AS PEINH_2,
NULL AS INFNR,
NULL AS KZECH,
NULL AS KZMPF,
NULL AS STLAL,
NULL AS PBDNR,
NULL AS STVKN,
NULL AS KTOMA,
NULL AS VRPLA,
NULL AS KZBWS,
NULL AS NLFZV,
NULL AS NLFMV,
NULL AS TECHS,
NULL AS OBJTYPE,
NULL AS CH_PROC,
NULL AS FXPRU,
NULL AS UMSOK,
NULL AS VORAB_SM,
NULL AS FIPOS,
NULL AS FIPEX,
NULL AS FISTL,
NULL AS GEBER,
NULL AS GRANT_NBR,
NULL AS FKBER,
NULL AS PRIO_URG,
NULL AS PRIO_REQ,
NULL AS KBLNR,
NULL AS KBLPOS,
NULL AS BUDGET_PD,
NULL AS SC_OBJECT_ID,
NULL AS SC_ITM_NO,
NULL AS SGT_SCAT,
NULL AS SGT_RCAT,
NULL AS FMFGUS_KEY,
NULL AS ADVCODE,
NULL AS FSH_RALLOC_QTY,
NULL AS FSH_CRITICAL_COMP,
NULL AS FSH_CRITICAL_LEVEL,
NULL AS WTY_IND,
NULL AS R_PART_INDICATOR,
NULL AS WTYSC_CLMITEM,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLSOURCESYSTEM,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}