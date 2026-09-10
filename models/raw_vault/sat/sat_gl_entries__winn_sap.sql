---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT * FROM {{ ref('v_psa_stg_general_ledger_entries__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                          WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                          {% endif %} )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.V_PSA_STG_GENERAL_LEDGER_HEADER )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        GL_ENTRIES_HK
      , BUKRS
      , BELNR
      , GJAHR
      , BUZEI
      , GLREQUEST
      , BUZID
      , AUGDT
      , AUGCP
      , AUGBL
      , BSCHL
      , KOART
      , UMSKZ
      , UMSKS
      , ZUMSK
      , SHKZG
      , GSBER
      , PARGB
      , MWSKZ
      , QSSKZ
      , DMBTR
      , WRBTR
      , KZBTR
      , PSWBT
      , PSWSL
      , TXBHW
      , TXBFW
      , MWSTS
      , WMWST
      , HWBAS
      , FWBAS
      , HWZUZ
      , FWZUZ
      , SHZUZ
      , STEKZ
      , MWART
      , TXGRP
      , KTOSL
      , QSSHB
      , KURSR
      , GBETR
      , BDIFF
      , BDIF2
      , VALUT
      , ZUONR
      , SGTXT
      , ZINKZ
      , VBUND
      , BEWAR
      , ALTKT
      , VORGN
      , FDLEV
      , FDGRP
      , FDWBT
      , FDTAG
      , FKONT
      , KOKRS
      , KOSTL
      , PROJN
      , AUFNR
      , VBELN
      , VBEL2
      , POSN2
      , ETEN2
      , ANLN1
      , ANLN2
      , ANBWA
      , BZDAT
      , PERNR
      , XUMSW
      , XHRES
      , XKRES
      , XOPVW
      , XCPDD
      , XSKST
      , XSAUF
      , XSPRO
      , XSERG
      , XFAKT
      , XUMAN
      , XANET
      , XSKRL
      , XINVE
      , XPANZ
      , XAUTO
      , XNCOP
      , XZAHL
      , SAKNR
      , HKONT
      , KUNNR
      , LIFNR
      , FILKD
      , XBILK
      , GVTYP
      , HZUON
      , ZFBDT
      , ZTERM
      , ZBD1T
      , ZBD2T
      , ZBD3T
      , ZBD1P
      , ZBD2P
      , SKFBT
      , SKNTO
      , WSKTO
      , ZLSCH
      , ZLSPR
      , ZBFIX
      , HBKID
      , BVTYP
      , NEBTR
      , MWSK1
      , DMBT1
      , WRBT1
      , MWSK2
      , DMBT2
      , WRBT2
      , MWSK3
      , DMBT3
      , WRBT3
      , REBZG
      , REBZJ
      , REBZZ
      , REBZT
      , ZOLLT
      , ZOLLD
      , LZBKZ
      , LANDL
      , DIEKZ
      , SAMNR
      , ABPER
      , VRSKZ
      , VRSDT
      , DISBN
      , DISBJ
      , DISBZ
      , WVERW
      , ANFBN
      , ANFBJ
      , ANFBU
      , ANFAE
      , BLNBT
      , BLNKZ
      , BLNPZ
      , MSCHL
      , MANSP
      , MADAT
      , MANST
      , MABER
      , ESRNR
      , ESRRE
      , ESRPZ
      , KLIBT
      , QSZNR
      , QBSHB
      , QSFBT
      , NAVHW
      , NAVFW
      , MATNR
      , WERKS
      , MENGE
      , MEINS
      , ERFMG
      , ERFME
      , BPMNG
      , BPRME
      , EBELN
      , EBELP
      , ZEKKN
      , ELIKZ
      , VPRSV
      , PEINH
      , BWKEY
      , BWTAR
      , BUSTW
      , REWRT
      , REWWR
      , BONFB
      , BUALT
      , PSALT
      , NPREI
      , TBTKZ
      , SPGRP
      , SPGRM
      , SPGRT
      , SPGRG
      , SPGRV
      , SPGRQ
      , STCEG
      , EGBLD
      , EGLLD
      , RSTGR
      , RYACQ
      , RPACQ
      , RDIFF
      , RDIF2
      , PRCTR
      , XHKOM
      , VNAME
      , RECID
      , EGRUP
      , VPTNR
      , VERTT
      , VERTN
      , VBEWA
      , DEPOT
      , TXJCD
      , IMKEY
      , DABRZ
      , POPTS
      , FIPOS
      , KSTRG
      , NPLNR
      , AUFPL
      , APLZL
      , PROJK
      , PAOBJNR
      , PASUBNR
      , SPGRS
      , SPGRC
      , BTYPE
      , ETYPE
      , XEGDR
      , LNRAN
      , HRKFT
      , DMBE2
      , DMBE3
      , DMB21
      , DMB22
      , DMB23
      , DMB31
      , DMB32
      , DMB33
      , MWST2
      , MWST3
      , NAVH2
      , NAVH3
      , SKNT2
      , SKNT3
      , BDIF3
      , RDIF3
      , HWMET
      , GLUPM
      , XRAGL
      , UZAWE
      , LOKKT
      , FISTL
      , GEBER
      , STBUK
      , TXBH2
      , TXBH3
      , PPRCT
      , XREF1
      , XREF2
      , KBLNR
      , KBLPOS
      , STTAX
      , FKBER
      , OBZEI
      , XNEGP
      , RFZEI
      , CCBTC
      , KKBER
      , EMPFB
      , XREF3
      , DTWS1
      , DTWS2
      , DTWS3
      , DTWS4
      , GRICD
      , GRIRG
      , GITYP
      , XPYPR
      , KIDNO
      , ABSBT
      , IDXSP
      , LINFV
      , KONTT
      , KONTL
      , TXDAT
      , AGZEI
      , PYCUR
      , PYAMT
      , BUPLA
      , SECCO
      , LSTAR
      , CESSION_KZ
      , PRZNR
      , PPDIFF
      , PPDIF2
      , PPDIF3
      , PENLC1
      , PENLC2
      , PENLC3
      , PENFC
      , PENDAYS
      , PENRC
      , GRANT_NBR
      , SCTAX
      , FKBER_LONG
      , GMVKZ
      , SRTYPE
      , INTRENO
      , MEASURE
      , AUGGJ
      , PPA_EX_IND
      , DOCLN
      , SEGMENT
      , PSEGMENT
      , PFKBER
      , HKTID
      , KSTAR
      , XLGCLR
      , TAXPS
      , PAYS_PROV
      , PAYS_TRAN
      , MNDID
      , XFRGE_BSEG
      , SQUAN
      , RE_BUKRS
      , RE_ACCOUNT
      , PGEBER
      , PGRANT_NBR
      , BUDGET_PD
      , PBUDGET_PD
      , J_1TPBUPL
      , PEROP_BEG
      , PEROP_END
      , FASTPAY
      , IGNR_IVREF
      , FMFGUS_KEY
      , FMXDOCNR
      , FMXYEAR
      , FMXDOCLN
      , FMXZEKKN
      , PRODPER
      , RECRF
      , INWARD_NO
      , INWARD_DT
      , PYMTKEY
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , REC_SRC
      , BKCC
      , LOAD_DTS
      , HASHDIFF
    FROM SRC_SWINN
)
---- RENAME LAYER ----

, RENAME_SWINN as (
    SELECT
        GL_ENTRIES_HK
      , BUKRS
      , BELNR
      , GJAHR
      , BUZEI
      , GLREQUEST
      , BUZID
      , AUGDT
      , AUGCP
      , AUGBL
      , BSCHL
      , KOART
      , UMSKZ
      , UMSKS
      , ZUMSK
      , SHKZG
      , GSBER
      , PARGB
      , MWSKZ
      , QSSKZ
      , DMBTR
      , WRBTR
      , KZBTR
      , PSWBT
      , PSWSL
      , TXBHW
      , TXBFW
      , MWSTS
      , WMWST
      , HWBAS
      , FWBAS
      , HWZUZ
      , FWZUZ
      , SHZUZ
      , STEKZ
      , MWART
      , TXGRP
      , KTOSL
      , QSSHB
      , KURSR
      , GBETR
      , BDIFF
      , BDIF2
      , VALUT
      , ZUONR
      , SGTXT
      , ZINKZ
      , VBUND
      , BEWAR
      , ALTKT
      , VORGN
      , FDLEV
      , FDGRP
      , FDWBT
      , FDTAG
      , FKONT
      , KOKRS
      , KOSTL
      , PROJN
      , AUFNR
      , VBELN
      , VBEL2
      , POSN2
      , ETEN2
      , ANLN1
      , ANLN2
      , ANBWA
      , BZDAT
      , PERNR
      , XUMSW
      , XHRES
      , XKRES
      , XOPVW
      , XCPDD
      , XSKST
      , XSAUF
      , XSPRO
      , XSERG
      , XFAKT
      , XUMAN
      , XANET
      , XSKRL
      , XINVE
      , XPANZ
      , XAUTO
      , XNCOP
      , XZAHL
      , SAKNR
      , HKONT
      , KUNNR
      , LIFNR
      , FILKD
      , XBILK
      , GVTYP
      , HZUON
      , ZFBDT
      , ZTERM
      , ZBD1T
      , ZBD2T
      , ZBD3T
      , ZBD1P
      , ZBD2P
      , SKFBT
      , SKNTO
      , WSKTO
      , ZLSCH
      , ZLSPR
      , ZBFIX
      , HBKID
      , BVTYP
      , NEBTR
      , MWSK1
      , DMBT1
      , WRBT1
      , MWSK2
      , DMBT2
      , WRBT2
      , MWSK3
      , DMBT3
      , WRBT3
      , REBZG
      , REBZJ
      , REBZZ
      , REBZT
      , ZOLLT
      , ZOLLD
      , LZBKZ
      , LANDL
      , DIEKZ
      , SAMNR
      , ABPER
      , VRSKZ
      , VRSDT
      , DISBN
      , DISBJ
      , DISBZ
      , WVERW
      , ANFBN
      , ANFBJ
      , ANFBU
      , ANFAE
      , BLNBT
      , BLNKZ
      , BLNPZ
      , MSCHL
      , MANSP
      , MADAT
      , MANST
      , MABER
      , ESRNR
      , ESRRE
      , ESRPZ
      , KLIBT
      , QSZNR
      , QBSHB
      , QSFBT
      , NAVHW
      , NAVFW
      , MATNR
      , WERKS
      , MENGE
      , MEINS
      , ERFMG
      , ERFME
      , BPMNG
      , BPRME
      , EBELN
      , EBELP
      , ZEKKN
      , ELIKZ
      , VPRSV
      , PEINH
      , BWKEY
      , BWTAR
      , BUSTW
      , REWRT
      , REWWR
      , BONFB
      , BUALT
      , PSALT
      , NPREI
      , TBTKZ
      , SPGRP
      , SPGRM
      , SPGRT
      , SPGRG
      , SPGRV
      , SPGRQ
      , STCEG
      , EGBLD
      , EGLLD
      , RSTGR
      , RYACQ
      , RPACQ
      , RDIFF
      , RDIF2
      , PRCTR
      , XHKOM
      , VNAME
      , RECID
      , EGRUP
      , VPTNR
      , VERTT
      , VERTN
      , VBEWA
      , DEPOT
      , TXJCD
      , IMKEY
      , DABRZ
      , POPTS
      , FIPOS
      , KSTRG
      , NPLNR
      , AUFPL
      , APLZL
      , PROJK
      , PAOBJNR
      , PASUBNR
      , SPGRS
      , SPGRC
      , BTYPE
      , ETYPE
      , XEGDR
      , LNRAN
      , HRKFT
      , DMBE2
      , DMBE3
      , DMB21
      , DMB22
      , DMB23
      , DMB31
      , DMB32
      , DMB33
      , MWST2
      , MWST3
      , NAVH2
      , NAVH3
      , SKNT2
      , SKNT3
      , BDIF3
      , RDIF3
      , HWMET
      , GLUPM
      , XRAGL
      , UZAWE
      , LOKKT
      , FISTL
      , GEBER
      , STBUK
      , TXBH2
      , TXBH3
      , PPRCT
      , XREF1
      , XREF2
      , KBLNR
      , KBLPOS
      , STTAX
      , FKBER
      , OBZEI
      , XNEGP
      , RFZEI
      , CCBTC
      , KKBER
      , EMPFB
      , XREF3
      , DTWS1
      , DTWS2
      , DTWS3
      , DTWS4
      , GRICD
      , GRIRG
      , GITYP
      , XPYPR
      , KIDNO
      , ABSBT
      , IDXSP
      , LINFV
      , KONTT
      , KONTL
      , TXDAT
      , AGZEI
      , PYCUR
      , PYAMT
      , BUPLA
      , SECCO
      , LSTAR
      , CESSION_KZ
      , PRZNR
      , PPDIFF
      , PPDIF2
      , PPDIF3
      , PENLC1
      , PENLC2
      , PENLC3
      , PENFC
      , PENDAYS
      , PENRC
      , GRANT_NBR
      , SCTAX
      , FKBER_LONG
      , GMVKZ
      , SRTYPE
      , INTRENO
      , MEASURE
      , AUGGJ
      , PPA_EX_IND
      , DOCLN
      , SEGMENT
      , PSEGMENT
      , PFKBER
      , HKTID
      , KSTAR
      , XLGCLR
      , TAXPS
      , PAYS_PROV
      , PAYS_TRAN
      , MNDID
      , XFRGE_BSEG
      , SQUAN
      , RE_BUKRS
      , RE_ACCOUNT
      , PGEBER
      , PGRANT_NBR
      , BUDGET_PD
      , PBUDGET_PD
      , J_1TPBUPL
      , PEROP_BEG
      , PEROP_END
      , FASTPAY
      , IGNR_IVREF
      , FMFGUS_KEY
      , FMXDOCNR
      , FMXYEAR
      , FMXDOCLN
      , FMXZEKKN
      , PRODPER
      , RECRF
      , INWARD_NO
      , INWARD_DT
      , PYMTKEY
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , REC_SRC
      , BKCC
      , LOAD_DTS
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
          GL_ENTRIES_HK
        , BUKRS
        , BELNR
        , GJAHR
        , BUZEI
        , GLREQUEST
        , BUZID
        , AUGDT
        , AUGCP
        , AUGBL
        , BSCHL
        , KOART
        , UMSKZ
        , UMSKS
        , ZUMSK
        , SHKZG
        , GSBER
        , PARGB
        , MWSKZ
        , QSSKZ
        , DMBTR
        , WRBTR
        , KZBTR
        , PSWBT
        , PSWSL
        , TXBHW
        , TXBFW
        , MWSTS
        , WMWST
        , HWBAS
        , FWBAS
        , HWZUZ
        , FWZUZ
        , SHZUZ
        , STEKZ
        , MWART
        , TXGRP
        , KTOSL
        , QSSHB
        , KURSR
        , GBETR
        , BDIFF
        , BDIF2
        , VALUT
        , ZUONR
        , SGTXT
        , ZINKZ
        , VBUND
        , BEWAR
        , ALTKT
        , VORGN
        , FDLEV
        , FDGRP
        , FDWBT
        , FDTAG
        , FKONT
        , KOKRS
        , KOSTL
        , PROJN
        , AUFNR
        , VBELN
        , VBEL2
        , POSN2
        , ETEN2
        , ANLN1
        , ANLN2
        , ANBWA
        , BZDAT
        , PERNR
        , XUMSW
        , XHRES
        , XKRES
        , XOPVW
        , XCPDD
        , XSKST
        , XSAUF
        , XSPRO
        , XSERG
        , XFAKT
        , XUMAN
        , XANET
        , XSKRL
        , XINVE
        , XPANZ
        , XAUTO
        , XNCOP
        , XZAHL
        , SAKNR
        , HKONT
        , KUNNR
        , LIFNR
        , FILKD
        , XBILK
        , GVTYP
        , HZUON
        , ZFBDT
        , ZTERM
        , ZBD1T
        , ZBD2T
        , ZBD3T
        , ZBD1P
        , ZBD2P
        , SKFBT
        , SKNTO
        , WSKTO
        , ZLSCH
        , ZLSPR
        , ZBFIX
        , HBKID
        , BVTYP
        , NEBTR
        , MWSK1
        , DMBT1
        , WRBT1
        , MWSK2
        , DMBT2
        , WRBT2
        , MWSK3
        , DMBT3
        , WRBT3
        , REBZG
        , REBZJ
        , REBZZ
        , REBZT
        , ZOLLT
        , ZOLLD
        , LZBKZ
        , LANDL
        , DIEKZ
        , SAMNR
        , ABPER
        , VRSKZ
        , VRSDT
        , DISBN
        , DISBJ
        , DISBZ
        , WVERW
        , ANFBN
        , ANFBJ
        , ANFBU
        , ANFAE
        , BLNBT
        , BLNKZ
        , BLNPZ
        , MSCHL
        , MANSP
        , MADAT
        , MANST
        , MABER
        , ESRNR
        , ESRRE
        , ESRPZ
        , KLIBT
        , QSZNR
        , QBSHB
        , QSFBT
        , NAVHW
        , NAVFW
        , MATNR
        , WERKS
        , MENGE
        , MEINS
        , ERFMG
        , ERFME
        , BPMNG
        , BPRME
        , EBELN
        , EBELP
        , ZEKKN
        , ELIKZ
        , VPRSV
        , PEINH
        , BWKEY
        , BWTAR
        , BUSTW
        , REWRT
        , REWWR
        , BONFB
        , BUALT
        , PSALT
        , NPREI
        , TBTKZ
        , SPGRP
        , SPGRM
        , SPGRT
        , SPGRG
        , SPGRV
        , SPGRQ
        , STCEG
        , EGBLD
        , EGLLD
        , RSTGR
        , RYACQ
        , RPACQ
        , RDIFF
        , RDIF2
        , PRCTR
        , XHKOM
        , VNAME
        , RECID
        , EGRUP
        , VPTNR
        , VERTT
        , VERTN
        , VBEWA
        , DEPOT
        , TXJCD
        , IMKEY
        , DABRZ
        , POPTS
        , FIPOS
        , KSTRG
        , NPLNR
        , AUFPL
        , APLZL
        , PROJK
        , PAOBJNR
        , PASUBNR
        , SPGRS
        , SPGRC
        , BTYPE
        , ETYPE
        , XEGDR
        , LNRAN
        , HRKFT
        , DMBE2
        , DMBE3
        , DMB21
        , DMB22
        , DMB23
        , DMB31
        , DMB32
        , DMB33
        , MWST2
        , MWST3
        , NAVH2
        , NAVH3
        , SKNT2
        , SKNT3
        , BDIF3
        , RDIF3
        , HWMET
        , GLUPM
        , XRAGL
        , UZAWE
        , LOKKT
        , FISTL
        , GEBER
        , STBUK
        , TXBH2
        , TXBH3
        , PPRCT
        , XREF1
        , XREF2
        , KBLNR
        , KBLPOS
        , STTAX
        , FKBER
        , OBZEI
        , XNEGP
        , RFZEI
        , CCBTC
        , KKBER
        , EMPFB
        , XREF3
        , DTWS1
        , DTWS2
        , DTWS3
        , DTWS4
        , GRICD
        , GRIRG
        , GITYP
        , XPYPR
        , KIDNO
        , ABSBT
        , IDXSP
        , LINFV
        , KONTT
        , KONTL
        , TXDAT
        , AGZEI
        , PYCUR
        , PYAMT
        , BUPLA
        , SECCO
        , LSTAR
        , CESSION_KZ
        , PRZNR
        , PPDIFF
        , PPDIF2
        , PPDIF3
        , PENLC1
        , PENLC2
        , PENLC3
        , PENFC
        , PENDAYS
        , PENRC
        , GRANT_NBR
        , SCTAX
        , FKBER_LONG
        , GMVKZ
        , SRTYPE
        , INTRENO
        , MEASURE
        , AUGGJ
        , PPA_EX_IND
        , DOCLN
        , SEGMENT
        , PSEGMENT
        , PFKBER
        , HKTID
        , KSTAR
        , XLGCLR
        , TAXPS
        , PAYS_PROV
        , PAYS_TRAN
        , MNDID
        , XFRGE_BSEG
        , SQUAN
        , RE_BUKRS
        , RE_ACCOUNT
        , PGEBER
        , PGRANT_NBR
        , BUDGET_PD
        , PBUDGET_PD
        , J_1TPBUPL
        , PEROP_BEG
        , PEROP_END
        , FASTPAY
        , IGNR_IVREF
        , FMFGUS_KEY
        , FMXDOCNR
        , FMXYEAR
        , FMXDOCLN
        , FMXZEKKN
        , PRODPER
        , RECRF
        , INWARD_NO
        , INWARD_DT
        , PYMTKEY
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , REC_SRC
        , BKCC
        , LOAD_DTS
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
 WHERE NOT EXISTS (
  SELECT 1 
  FROM {{ this }} existing
  WHERE existing.GL_ENTRIES_HK= JOIN_RESULT.GL_ENTRIES_HK
  AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
 )
 {% endif %} 
 {% if not is_incremental() %}
 /* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
 qualify 1= row_number()over(partition by GL_ENTRIES_HK, HASHDIFF order by PSA_LOAD_DTS)
 
 union all
  SELECT MD5_BINARY(GR.VALUE) GL_ENTRIES_HK
, NULL AS BUKRS
, NULL AS BELNR
, NULL AS GJAHR
, NULL AS BUZEI
, NULL AS GLREQUEST
, NULL AS BUZID
, NULL AS AUGDT
, NULL AS AUGCP
, NULL AS AUGBL
, NULL AS BSCHL
, NULL AS KOART
, NULL AS UMSKZ
, NULL AS UMSKS
, NULL AS ZUMSK
, NULL AS SHKZG
, NULL AS GSBER
, NULL AS PARGB
, NULL AS MWSKZ
, NULL AS QSSKZ
, NULL AS DMBTR
, NULL AS WRBTR
, NULL AS KZBTR
, NULL AS PSWBT
, NULL AS PSWSL
, NULL AS TXBHW
, NULL AS TXBFW
, NULL AS MWSTS
, NULL AS WMWST
, NULL AS HWBAS
, NULL AS FWBAS
, NULL AS HWZUZ
, NULL AS FWZUZ
, NULL AS SHZUZ
, NULL AS STEKZ
, NULL AS MWART
, NULL AS TXGRP
, NULL AS KTOSL
, NULL AS QSSHB
, NULL AS KURSR
, NULL AS GBETR
, NULL AS BDIFF
, NULL AS BDIF2
, NULL AS VALUT
, NULL AS ZUONR
, NULL AS SGTXT
, NULL AS ZINKZ
, NULL AS VBUND
, NULL AS BEWAR
, NULL AS ALTKT
, NULL AS VORGN
, NULL AS FDLEV
, NULL AS FDGRP
, NULL AS FDWBT
, NULL AS FDTAG
, NULL AS FKONT
, NULL AS KOKRS
, NULL AS KOSTL
, NULL AS PROJN
, NULL AS AUFNR
, NULL AS VBELN
, NULL AS VBEL2
, NULL AS POSN2
, NULL AS ETEN2
, NULL AS ANLN1
, NULL AS ANLN2
, NULL AS ANBWA
, NULL AS BZDAT
, NULL AS PERNR
, NULL AS XUMSW
, NULL AS XHRES
, NULL AS XKRES
, NULL AS XOPVW
, NULL AS XCPDD
, NULL AS XSKST
, NULL AS XSAUF
, NULL AS XSPRO
, NULL AS XSERG
, NULL AS XFAKT
, NULL AS XUMAN
, NULL AS XANET
, NULL AS XSKRL
, NULL AS XINVE
, NULL AS XPANZ
, NULL AS XAUTO
, NULL AS XNCOP
, NULL AS XZAHL
, NULL AS SAKNR
, NULL AS HKONT
, NULL AS KUNNR
, NULL AS LIFNR
, NULL AS FILKD
, NULL AS XBILK
, NULL AS GVTYP
, NULL AS HZUON
, NULL AS ZFBDT
, NULL AS ZTERM
, NULL AS ZBD1T
, NULL AS ZBD2T
, NULL AS ZBD3T
, NULL AS ZBD1P
, NULL AS ZBD2P
, NULL AS SKFBT
, NULL AS SKNTO
, NULL AS WSKTO
, NULL AS ZLSCH
, NULL AS ZLSPR
, NULL AS ZBFIX
, NULL AS HBKID
, NULL AS BVTYP
, NULL AS NEBTR
, NULL AS MWSK1
, NULL AS DMBT1
, NULL AS WRBT1
, NULL AS MWSK2
, NULL AS DMBT2
, NULL AS WRBT2
, NULL AS MWSK3
, NULL AS DMBT3
, NULL AS WRBT3
, NULL AS REBZG
, NULL AS REBZJ
, NULL AS REBZZ
, NULL AS REBZT
, NULL AS ZOLLT
, NULL AS ZOLLD
, NULL AS LZBKZ
, NULL AS LANDL
, NULL AS DIEKZ
, NULL AS SAMNR
, NULL AS ABPER
, NULL AS VRSKZ
, NULL AS VRSDT
, NULL AS DISBN
, NULL AS DISBJ
, NULL AS DISBZ
, NULL AS WVERW
, NULL AS ANFBN
, NULL AS ANFBJ
, NULL AS ANFBU
, NULL AS ANFAE
, NULL AS BLNBT
, NULL AS BLNKZ
, NULL AS BLNPZ
, NULL AS MSCHL
, NULL AS MANSP
, NULL AS MADAT
, NULL AS MANST
, NULL AS MABER
, NULL AS ESRNR
, NULL AS ESRRE
, NULL AS ESRPZ
, NULL AS KLIBT
, NULL AS QSZNR
, NULL AS QBSHB
, NULL AS QSFBT
, NULL AS NAVHW
, NULL AS NAVFW
, NULL AS MATNR
, NULL AS WERKS
, NULL AS MENGE
, NULL AS MEINS
, NULL AS ERFMG
, NULL AS ERFME
, NULL AS BPMNG
, NULL AS BPRME
, NULL AS EBELN
, NULL AS EBELP
, NULL AS ZEKKN
, NULL AS ELIKZ
, NULL AS VPRSV
, NULL AS PEINH
, NULL AS BWKEY
, NULL AS BWTAR
, NULL AS BUSTW
, NULL AS REWRT
, NULL AS REWWR
, NULL AS BONFB
, NULL AS BUALT
, NULL AS PSALT
, NULL AS NPREI
, NULL AS TBTKZ
, NULL AS SPGRP
, NULL AS SPGRM
, NULL AS SPGRT
, NULL AS SPGRG
, NULL AS SPGRV
, NULL AS SPGRQ
, NULL AS STCEG
, NULL AS EGBLD
, NULL AS EGLLD
, NULL AS RSTGR
, NULL AS RYACQ
, NULL AS RPACQ
, NULL AS RDIFF
, NULL AS RDIF2
, NULL AS PRCTR
, NULL AS XHKOM
, NULL AS VNAME
, NULL AS RECID
, NULL AS EGRUP
, NULL AS VPTNR
, NULL AS VERTT
, NULL AS VERTN
, NULL AS VBEWA
, NULL AS DEPOT
, NULL AS TXJCD
, NULL AS IMKEY
, NULL AS DABRZ
, NULL AS POPTS
, NULL AS FIPOS
, NULL AS KSTRG
, NULL AS NPLNR
, NULL AS AUFPL
, NULL AS APLZL
, NULL AS PROJK
, NULL AS PAOBJNR
, NULL AS PASUBNR
, NULL AS SPGRS
, NULL AS SPGRC
, NULL AS BTYPE
, NULL AS ETYPE
, NULL AS XEGDR
, NULL AS LNRAN
, NULL AS HRKFT
, NULL AS DMBE2
, NULL AS DMBE3
, NULL AS DMB21
, NULL AS DMB22
, NULL AS DMB23
, NULL AS DMB31
, NULL AS DMB32
, NULL AS DMB33
, NULL AS MWST2
, NULL AS MWST3
, NULL AS NAVH2
, NULL AS NAVH3
, NULL AS SKNT2
, NULL AS SKNT3
, NULL AS BDIF3
, NULL AS RDIF3
, NULL AS HWMET
, NULL AS GLUPM
, NULL AS XRAGL
, NULL AS UZAWE
, NULL AS LOKKT
, NULL AS FISTL
, NULL AS GEBER
, NULL AS STBUK
, NULL AS TXBH2
, NULL AS TXBH3
, NULL AS PPRCT
, NULL AS XREF1
, NULL AS XREF2
, NULL AS KBLNR
, NULL AS KBLPOS
, NULL AS STTAX
, NULL AS FKBER
, NULL AS OBZEI
, NULL AS XNEGP
, NULL AS RFZEI
, NULL AS CCBTC
, NULL AS KKBER
, NULL AS EMPFB
, NULL AS XREF3
, NULL AS DTWS1
, NULL AS DTWS2
, NULL AS DTWS3
, NULL AS DTWS4
, NULL AS GRICD
, NULL AS GRIRG
, NULL AS GITYP
, NULL AS XPYPR
, NULL AS KIDNO
, NULL AS ABSBT
, NULL AS IDXSP
, NULL AS LINFV
, NULL AS KONTT
, NULL AS KONTL
, NULL AS TXDAT
, NULL AS AGZEI
, NULL AS PYCUR
, NULL AS PYAMT
, NULL AS BUPLA
, NULL AS SECCO
, NULL AS LSTAR
, NULL AS CESSION_KZ
, NULL AS PRZNR
, NULL AS PPDIFF
, NULL AS PPDIF2
, NULL AS PPDIF3
, NULL AS PENLC1
, NULL AS PENLC2
, NULL AS PENLC3
, NULL AS PENFC
, NULL AS PENDAYS
, NULL AS PENRC
, NULL AS GRANT_NBR
, NULL AS SCTAX
, NULL AS FKBER_LONG
, NULL AS GMVKZ
, NULL AS SRTYPE
, NULL AS INTRENO
, NULL AS MEASURE
, NULL AS AUGGJ
, NULL AS PPA_EX_IND
, NULL AS DOCLN
, NULL AS SEGMENT
, NULL AS PSEGMENT
, NULL AS PFKBER
, NULL AS HKTID
, NULL AS KSTAR
, NULL AS XLGCLR
, NULL AS TAXPS
, NULL AS PAYS_PROV
, NULL AS PAYS_TRAN
, NULL AS MNDID
, NULL AS XFRGE_BSEG
, NULL AS SQUAN
, NULL AS RE_BUKRS
, NULL AS RE_ACCOUNT
, NULL AS PGEBER
, NULL AS PGRANT_NBR
, NULL AS BUDGET_PD
, NULL AS PBUDGET_PD
, NULL AS J_1TPBUPL
, NULL AS PEROP_BEG
, NULL AS PEROP_END
, NULL AS FASTPAY
, NULL AS IGNR_IVREF
, NULL AS FMFGUS_KEY
, NULL AS FMXDOCNR
, NULL AS FMXYEAR
, NULL AS FMXDOCLN
, NULL AS FMXZEKKN
, NULL AS PRODPER
, NULL AS RECRF
, NULL AS INWARD_NO
, NULL AS INWARD_DT
, NULL AS PYMTKEY
, NULL AS GLDELFLAG
, NULL AS GLCHANGETIME
, NULL AS GLSOURCESYSTEM 
, 'N' AS PSA_DELETE_IND
, '1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS
, ''::BINARY as HASH_DIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
 {% endif %}