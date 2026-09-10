---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_bseg') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_LE_SAP         as ( SELECT * FROM {{ ref('v_psa_stg_legal_entity__winn_sap') }} as SRC  ),
SRC_GLA_SAP        as ( SELECT * FROM {{ ref('v_psa_stg_gl_account__winn_sap') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_bseg )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_LE_SAP         as ( SELECT * FROM staging.v_psa_stg_legal_entity__winn_sap )
, SRC_GLA_SAP        as ( SELECT * FROM staging.v_psa_stg_gl_account__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        to_char(coalesce(BUKRS,'-1'))                                as                                    COMPANY_CODE_BK
      , to_char(coalesce(BELNR,'-1'))                                as                              ACCOUNTING_DOC_NUM_BK
      , to_char(coalesce(GJAHR,'-1'))                                as                                     FISCAL_YEAR_BK
      , to_char(coalesce(BUZEI,'-1'))                                as                           NUM_LI_ACCOUNTING_DOC_BK
      , to_char(coalesce(SAKNR,'-1'))                                as                                      GL_ACCOUNT_BK
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
        ))                                                           as                                           LOAD_DTS
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)

, LOGIC_LE_SAP as (
    SELECT
        BUKRS                                                        as                                           LE_BUKRS
    FROM SRC_LE_SAP
    QUALIFY ROW_NUMBER() OVER (PARTITION BY BUKRS ORDER BY PSA_LOAD_DTS) = 1
)

, LOGIC_GLA_SAP as (
    SELECT
        SAKNR                                                        as                                          GLA_SAKNR
    FROM SRC_GLA_SAP
    QUALIFY ROW_NUMBER() OVER (PARTITION BY SAKNR ORDER BY PSA_LOAD_DTS) = 1
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        COMPANY_CODE_BK
      , ACCOUNTING_DOC_NUM_BK
      , FISCAL_YEAR_BK
      , NUM_LI_ACCOUNTING_DOC_BK
      , GL_ACCOUNT_BK
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
      , LOAD_DTS
    FROM LOGIC_S
)

, RENAME_GLA_SAP as (
    SELECT
        GLA_SAKNR
    FROM LOGIC_GLA_SAP
)

, RENAME_LE_SAP as (
    SELECT
        LE_BUKRS
    FROM LOGIC_LE_SAP
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_BSEG'
)

, FILTER_LE_SAP as (
    SELECT *
    FROM RENAME_LE_SAP
)

, FILTER_GLA_SAP as (
    SELECT *
    FROM RENAME_GLA_SAP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
    INNER JOIN FILTER_LE_SAP
        ON FILTER_S.BUKRS = FILTER_LE_SAP.LE_BUKRS
    INNER JOIN FILTER_GLA_SAP
        ON FILTER_S.SAKNR = FILTER_GLA_SAP.GLA_SAKNR
)

---- FINAL LAYER ----
SELECT
          COMPANY_CODE_BK
        , ACCOUNTING_DOC_NUM_BK
        , FISCAL_YEAR_BK
        , NUM_LI_ACCOUNTING_DOC_BK
        , GL_ACCOUNT_BK
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
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COMPANY_CODE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ACCOUNTING_DOC_NUM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(FISCAL_YEAR_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(NUM_LI_ACCOUNTING_DOC_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as GL_ENTRIES_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(COMPANY_CODE_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(ACCOUNTING_DOC_NUM_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(FISCAL_YEAR_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                  GENERAL_LEDGER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(COMPANY_CODE_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                    COMPANY_CODE_HK
       , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(GL_ACCOUNT_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))  as                                      GL_ACCOUNT_HK
       , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(LE_BUKRS as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                    LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(COMPANY_CODE_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(ACCOUNTING_DOC_NUM_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(FISCAL_YEAR_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(NUM_LI_ACCOUNTING_DOC_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(LE_BUKRS as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(GLA_SAKNR as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                       GL_ENTRIES_HEADER_ACCOUNT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(BUKRS::text), '^^') 
            , '||', IFNULL(TRIM(BELNR::text), '^^') 
            , '||', IFNULL(TRIM(GJAHR::text), '^^') 
            , '||', IFNULL(TRIM(BUZEI::text), '^^') 
            , '||', IFNULL(TRIM(BUZID::text), '^^') 
            , '||', IFNULL(TRIM(AUGDT::text), '^^') 
            , '||', IFNULL(TRIM(AUGCP::text), '^^') 
            , '||', IFNULL(TRIM(AUGBL::text), '^^') 
            , '||', IFNULL(TRIM(BSCHL::text), '^^') 
            , '||', IFNULL(TRIM(KOART::text), '^^') 
            , '||', IFNULL(TRIM(UMSKZ::text), '^^') 
            , '||', IFNULL(TRIM(UMSKS::text), '^^') 
            , '||', IFNULL(TRIM(ZUMSK::text), '^^') 
            , '||', IFNULL(TRIM(SHKZG::text), '^^') 
            , '||', IFNULL(TRIM(GSBER::text), '^^') 
            , '||', IFNULL(TRIM(PARGB::text), '^^') 
            , '||', IFNULL(TRIM(MWSKZ::text), '^^') 
            , '||', IFNULL(TRIM(QSSKZ::text), '^^') 
            , '||', IFNULL(TRIM(DMBTR::text), '^^') 
            , '||', IFNULL(TRIM(WRBTR::text), '^^') 
            , '||', IFNULL(TRIM(KZBTR::text), '^^') 
            , '||', IFNULL(TRIM(PSWBT::text), '^^') 
            , '||', IFNULL(TRIM(PSWSL::text), '^^') 
            , '||', IFNULL(TRIM(TXBHW::text), '^^') 
            , '||', IFNULL(TRIM(TXBFW::text), '^^') 
            , '||', IFNULL(TRIM(MWSTS::text), '^^') 
            , '||', IFNULL(TRIM(WMWST::text), '^^') 
            , '||', IFNULL(TRIM(HWBAS::text), '^^') 
            , '||', IFNULL(TRIM(FWBAS::text), '^^') 
            , '||', IFNULL(TRIM(HWZUZ::text), '^^') 
            , '||', IFNULL(TRIM(FWZUZ::text), '^^') 
            , '||', IFNULL(TRIM(SHZUZ::text), '^^') 
            , '||', IFNULL(TRIM(STEKZ::text), '^^') 
            , '||', IFNULL(TRIM(MWART::text), '^^') 
            , '||', IFNULL(TRIM(TXGRP::text), '^^') 
            , '||', IFNULL(TRIM(KTOSL::text), '^^') 
            , '||', IFNULL(TRIM(QSSHB::text), '^^') 
            , '||', IFNULL(TRIM(KURSR::text), '^^') 
            , '||', IFNULL(TRIM(GBETR::text), '^^') 
            , '||', IFNULL(TRIM(BDIFF::text), '^^') 
            , '||', IFNULL(TRIM(BDIF2::text), '^^') 
            , '||', IFNULL(TRIM(VALUT::text), '^^') 
            , '||', IFNULL(TRIM(ZUONR::text), '^^') 
            , '||', IFNULL(TRIM(SGTXT::text), '^^') 
            , '||', IFNULL(TRIM(ZINKZ::text), '^^') 
            , '||', IFNULL(TRIM(VBUND::text), '^^') 
            , '||', IFNULL(TRIM(BEWAR::text), '^^') 
            , '||', IFNULL(TRIM(ALTKT::text), '^^') 
            , '||', IFNULL(TRIM(VORGN::text), '^^') 
            , '||', IFNULL(TRIM(FDLEV::text), '^^') 
            , '||', IFNULL(TRIM(FDGRP::text), '^^') 
            , '||', IFNULL(TRIM(FDWBT::text), '^^') 
            , '||', IFNULL(TRIM(FDTAG::text), '^^') 
            , '||', IFNULL(TRIM(FKONT::text), '^^') 
            , '||', IFNULL(TRIM(KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(KOSTL::text), '^^') 
            , '||', IFNULL(TRIM(PROJN::text), '^^') 
            , '||', IFNULL(TRIM(AUFNR::text), '^^') 
            , '||', IFNULL(TRIM(VBELN::text), '^^') 
            , '||', IFNULL(TRIM(VBEL2::text), '^^') 
            , '||', IFNULL(TRIM(POSN2::text), '^^') 
            , '||', IFNULL(TRIM(ETEN2::text), '^^') 
            , '||', IFNULL(TRIM(ANLN1::text), '^^') 
            , '||', IFNULL(TRIM(ANLN2::text), '^^') 
            , '||', IFNULL(TRIM(ANBWA::text), '^^') 
            , '||', IFNULL(TRIM(BZDAT::text), '^^') 
            , '||', IFNULL(TRIM(PERNR::text), '^^') 
            , '||', IFNULL(TRIM(XUMSW::text), '^^') 
            , '||', IFNULL(TRIM(XHRES::text), '^^') 
            , '||', IFNULL(TRIM(XKRES::text), '^^') 
            , '||', IFNULL(TRIM(XOPVW::text), '^^') 
            , '||', IFNULL(TRIM(XCPDD::text), '^^') 
            , '||', IFNULL(TRIM(XSKST::text), '^^') 
            , '||', IFNULL(TRIM(XSAUF::text), '^^') 
            , '||', IFNULL(TRIM(XSPRO::text), '^^') 
            , '||', IFNULL(TRIM(XSERG::text), '^^') 
            , '||', IFNULL(TRIM(XFAKT::text), '^^') 
            , '||', IFNULL(TRIM(XUMAN::text), '^^') 
            , '||', IFNULL(TRIM(XANET::text), '^^') 
            , '||', IFNULL(TRIM(XSKRL::text), '^^') 
            , '||', IFNULL(TRIM(XINVE::text), '^^') 
            , '||', IFNULL(TRIM(XPANZ::text), '^^') 
            , '||', IFNULL(TRIM(XAUTO::text), '^^') 
            , '||', IFNULL(TRIM(XNCOP::text), '^^') 
            , '||', IFNULL(TRIM(XZAHL::text), '^^') 
            , '||', IFNULL(TRIM(SAKNR::text), '^^') 
            , '||', IFNULL(TRIM(HKONT::text), '^^') 
            , '||', IFNULL(TRIM(KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(LIFNR::text), '^^') 
            , '||', IFNULL(TRIM(FILKD::text), '^^') 
            , '||', IFNULL(TRIM(XBILK::text), '^^') 
            , '||', IFNULL(TRIM(GVTYP::text), '^^') 
            , '||', IFNULL(TRIM(HZUON::text), '^^') 
            , '||', IFNULL(TRIM(ZFBDT::text), '^^') 
            , '||', IFNULL(TRIM(ZTERM::text), '^^') 
            , '||', IFNULL(TRIM(ZBD1T::text), '^^') 
            , '||', IFNULL(TRIM(ZBD2T::text), '^^') 
            , '||', IFNULL(TRIM(ZBD3T::text), '^^') 
            , '||', IFNULL(TRIM(ZBD1P::text), '^^') 
            , '||', IFNULL(TRIM(ZBD2P::text), '^^') 
            , '||', IFNULL(TRIM(SKFBT::text), '^^') 
            , '||', IFNULL(TRIM(SKNTO::text), '^^') 
            , '||', IFNULL(TRIM(WSKTO::text), '^^') 
            , '||', IFNULL(TRIM(ZLSCH::text), '^^') 
            , '||', IFNULL(TRIM(ZLSPR::text), '^^') 
            , '||', IFNULL(TRIM(ZBFIX::text), '^^') 
            , '||', IFNULL(TRIM(HBKID::text), '^^') 
            , '||', IFNULL(TRIM(BVTYP::text), '^^') 
            , '||', IFNULL(TRIM(NEBTR::text), '^^') 
            , '||', IFNULL(TRIM(MWSK1::text), '^^') 
            , '||', IFNULL(TRIM(DMBT1::text), '^^') 
            , '||', IFNULL(TRIM(WRBT1::text), '^^') 
            , '||', IFNULL(TRIM(MWSK2::text), '^^') 
            , '||', IFNULL(TRIM(DMBT2::text), '^^') 
            , '||', IFNULL(TRIM(WRBT2::text), '^^') 
            , '||', IFNULL(TRIM(MWSK3::text), '^^') 
            , '||', IFNULL(TRIM(DMBT3::text), '^^') 
            , '||', IFNULL(TRIM(WRBT3::text), '^^') 
            , '||', IFNULL(TRIM(REBZG::text), '^^') 
            , '||', IFNULL(TRIM(REBZJ::text), '^^') 
            , '||', IFNULL(TRIM(REBZZ::text), '^^') 
            , '||', IFNULL(TRIM(REBZT::text), '^^') 
            , '||', IFNULL(TRIM(ZOLLT::text), '^^') 
            , '||', IFNULL(TRIM(ZOLLD::text), '^^') 
            , '||', IFNULL(TRIM(LZBKZ::text), '^^') 
            , '||', IFNULL(TRIM(LANDL::text), '^^') 
            , '||', IFNULL(TRIM(DIEKZ::text), '^^') 
            , '||', IFNULL(TRIM(SAMNR::text), '^^') 
            , '||', IFNULL(TRIM(ABPER::text), '^^') 
            , '||', IFNULL(TRIM(VRSKZ::text), '^^') 
            , '||', IFNULL(TRIM(VRSDT::text), '^^') 
            , '||', IFNULL(TRIM(DISBN::text), '^^') 
            , '||', IFNULL(TRIM(DISBJ::text), '^^') 
            , '||', IFNULL(TRIM(DISBZ::text), '^^') 
            , '||', IFNULL(TRIM(WVERW::text), '^^') 
            , '||', IFNULL(TRIM(ANFBN::text), '^^') 
            , '||', IFNULL(TRIM(ANFBJ::text), '^^') 
            , '||', IFNULL(TRIM(ANFBU::text), '^^') 
            , '||', IFNULL(TRIM(ANFAE::text), '^^') 
            , '||', IFNULL(TRIM(BLNBT::text), '^^') 
            , '||', IFNULL(TRIM(BLNKZ::text), '^^') 
            , '||', IFNULL(TRIM(BLNPZ::text), '^^') 
            , '||', IFNULL(TRIM(MSCHL::text), '^^') 
            , '||', IFNULL(TRIM(MANSP::text), '^^') 
            , '||', IFNULL(TRIM(MADAT::text), '^^') 
            , '||', IFNULL(TRIM(MANST::text), '^^') 
            , '||', IFNULL(TRIM(MABER::text), '^^') 
            , '||', IFNULL(TRIM(ESRNR::text), '^^') 
            , '||', IFNULL(TRIM(ESRRE::text), '^^') 
            , '||', IFNULL(TRIM(ESRPZ::text), '^^') 
            , '||', IFNULL(TRIM(KLIBT::text), '^^') 
            , '||', IFNULL(TRIM(QSZNR::text), '^^') 
            , '||', IFNULL(TRIM(QBSHB::text), '^^') 
            , '||', IFNULL(TRIM(QSFBT::text), '^^') 
            , '||', IFNULL(TRIM(NAVHW::text), '^^') 
            , '||', IFNULL(TRIM(NAVFW::text), '^^') 
            , '||', IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(MENGE::text), '^^') 
            , '||', IFNULL(TRIM(MEINS::text), '^^') 
            , '||', IFNULL(TRIM(ERFMG::text), '^^') 
            , '||', IFNULL(TRIM(ERFME::text), '^^') 
            , '||', IFNULL(TRIM(BPMNG::text), '^^') 
            , '||', IFNULL(TRIM(BPRME::text), '^^') 
            , '||', IFNULL(TRIM(EBELN::text), '^^') 
            , '||', IFNULL(TRIM(EBELP::text), '^^') 
            , '||', IFNULL(TRIM(ZEKKN::text), '^^') 
            , '||', IFNULL(TRIM(ELIKZ::text), '^^') 
            , '||', IFNULL(TRIM(VPRSV::text), '^^') 
            , '||', IFNULL(TRIM(PEINH::text), '^^') 
            , '||', IFNULL(TRIM(BWKEY::text), '^^') 
            , '||', IFNULL(TRIM(BWTAR::text), '^^') 
            , '||', IFNULL(TRIM(BUSTW::text), '^^') 
            , '||', IFNULL(TRIM(REWRT::text), '^^') 
            , '||', IFNULL(TRIM(REWWR::text), '^^') 
            , '||', IFNULL(TRIM(BONFB::text), '^^') 
            , '||', IFNULL(TRIM(BUALT::text), '^^') 
            , '||', IFNULL(TRIM(PSALT::text), '^^') 
            , '||', IFNULL(TRIM(NPREI::text), '^^') 
            , '||', IFNULL(TRIM(TBTKZ::text), '^^') 
            , '||', IFNULL(TRIM(SPGRP::text), '^^') 
            , '||', IFNULL(TRIM(SPGRM::text), '^^') 
            , '||', IFNULL(TRIM(SPGRT::text), '^^') 
            , '||', IFNULL(TRIM(SPGRG::text), '^^') 
            , '||', IFNULL(TRIM(SPGRV::text), '^^') 
            , '||', IFNULL(TRIM(SPGRQ::text), '^^') 
            , '||', IFNULL(TRIM(STCEG::text), '^^') 
            , '||', IFNULL(TRIM(EGBLD::text), '^^') 
            , '||', IFNULL(TRIM(EGLLD::text), '^^') 
            , '||', IFNULL(TRIM(RSTGR::text), '^^') 
            , '||', IFNULL(TRIM(RYACQ::text), '^^') 
            , '||', IFNULL(TRIM(RPACQ::text), '^^') 
            , '||', IFNULL(TRIM(RDIFF::text), '^^') 
            , '||', IFNULL(TRIM(RDIF2::text), '^^') 
            , '||', IFNULL(TRIM(PRCTR::text), '^^') 
            , '||', IFNULL(TRIM(XHKOM::text), '^^') 
            , '||', IFNULL(TRIM(VNAME::text), '^^') 
            , '||', IFNULL(TRIM(RECID::text), '^^') 
            , '||', IFNULL(TRIM(EGRUP::text), '^^') 
            , '||', IFNULL(TRIM(VPTNR::text), '^^') 
            , '||', IFNULL(TRIM(VERTT::text), '^^') 
            , '||', IFNULL(TRIM(VERTN::text), '^^') 
            , '||', IFNULL(TRIM(VBEWA::text), '^^') 
            , '||', IFNULL(TRIM(DEPOT::text), '^^') 
            , '||', IFNULL(TRIM(TXJCD::text), '^^') 
            , '||', IFNULL(TRIM(IMKEY::text), '^^') 
            , '||', IFNULL(TRIM(DABRZ::text), '^^') 
            , '||', IFNULL(TRIM(POPTS::text), '^^') 
            , '||', IFNULL(TRIM(FIPOS::text), '^^') 
            , '||', IFNULL(TRIM(KSTRG::text), '^^') 
            , '||', IFNULL(TRIM(NPLNR::text), '^^') 
            , '||', IFNULL(TRIM(AUFPL::text), '^^') 
            , '||', IFNULL(TRIM(APLZL::text), '^^') 
            , '||', IFNULL(TRIM(PROJK::text), '^^') 
            , '||', IFNULL(TRIM(PAOBJNR::text), '^^') 
            , '||', IFNULL(TRIM(PASUBNR::text), '^^') 
            , '||', IFNULL(TRIM(SPGRS::text), '^^') 
            , '||', IFNULL(TRIM(SPGRC::text), '^^') 
            , '||', IFNULL(TRIM(BTYPE::text), '^^') 
            , '||', IFNULL(TRIM(ETYPE::text), '^^') 
            , '||', IFNULL(TRIM(XEGDR::text), '^^') 
            , '||', IFNULL(TRIM(LNRAN::text), '^^') 
            , '||', IFNULL(TRIM(HRKFT::text), '^^') 
            , '||', IFNULL(TRIM(DMBE2::text), '^^') 
            , '||', IFNULL(TRIM(DMBE3::text), '^^') 
            , '||', IFNULL(TRIM(DMB21::text), '^^') 
            , '||', IFNULL(TRIM(DMB22::text), '^^') 
            , '||', IFNULL(TRIM(DMB23::text), '^^') 
            , '||', IFNULL(TRIM(DMB31::text), '^^') 
            , '||', IFNULL(TRIM(DMB32::text), '^^') 
            , '||', IFNULL(TRIM(DMB33::text), '^^') 
            , '||', IFNULL(TRIM(MWST2::text), '^^') 
            , '||', IFNULL(TRIM(MWST3::text), '^^') 
            , '||', IFNULL(TRIM(NAVH2::text), '^^') 
            , '||', IFNULL(TRIM(NAVH3::text), '^^') 
            , '||', IFNULL(TRIM(SKNT2::text), '^^') 
            , '||', IFNULL(TRIM(SKNT3::text), '^^') 
            , '||', IFNULL(TRIM(BDIF3::text), '^^') 
            , '||', IFNULL(TRIM(RDIF3::text), '^^') 
            , '||', IFNULL(TRIM(HWMET::text), '^^') 
            , '||', IFNULL(TRIM(GLUPM::text), '^^') 
            , '||', IFNULL(TRIM(XRAGL::text), '^^') 
            , '||', IFNULL(TRIM(UZAWE::text), '^^') 
            , '||', IFNULL(TRIM(LOKKT::text), '^^') 
            , '||', IFNULL(TRIM(FISTL::text), '^^') 
            , '||', IFNULL(TRIM(GEBER::text), '^^') 
            , '||', IFNULL(TRIM(STBUK::text), '^^') 
            , '||', IFNULL(TRIM(TXBH2::text), '^^') 
            , '||', IFNULL(TRIM(TXBH3::text), '^^') 
            , '||', IFNULL(TRIM(PPRCT::text), '^^') 
            , '||', IFNULL(TRIM(XREF1::text), '^^') 
            , '||', IFNULL(TRIM(XREF2::text), '^^') 
            , '||', IFNULL(TRIM(KBLNR::text), '^^') 
            , '||', IFNULL(TRIM(KBLPOS::text), '^^') 
            , '||', IFNULL(TRIM(STTAX::text), '^^') 
            , '||', IFNULL(TRIM(FKBER::text), '^^') 
            , '||', IFNULL(TRIM(OBZEI::text), '^^') 
            , '||', IFNULL(TRIM(XNEGP::text), '^^') 
            , '||', IFNULL(TRIM(RFZEI::text), '^^') 
            , '||', IFNULL(TRIM(CCBTC::text), '^^') 
            , '||', IFNULL(TRIM(KKBER::text), '^^') 
            , '||', IFNULL(TRIM(EMPFB::text), '^^') 
            , '||', IFNULL(TRIM(XREF3::text), '^^') 
            , '||', IFNULL(TRIM(DTWS1::text), '^^') 
            , '||', IFNULL(TRIM(DTWS2::text), '^^') 
            , '||', IFNULL(TRIM(DTWS3::text), '^^') 
            , '||', IFNULL(TRIM(DTWS4::text), '^^') 
            , '||', IFNULL(TRIM(GRICD::text), '^^') 
            , '||', IFNULL(TRIM(GRIRG::text), '^^') 
            , '||', IFNULL(TRIM(GITYP::text), '^^') 
            , '||', IFNULL(TRIM(XPYPR::text), '^^') 
            , '||', IFNULL(TRIM(KIDNO::text), '^^') 
            , '||', IFNULL(TRIM(ABSBT::text), '^^') 
            , '||', IFNULL(TRIM(IDXSP::text), '^^') 
            , '||', IFNULL(TRIM(LINFV::text), '^^') 
            , '||', IFNULL(TRIM(KONTT::text), '^^') 
            , '||', IFNULL(TRIM(KONTL::text), '^^') 
            , '||', IFNULL(TRIM(TXDAT::text), '^^') 
            , '||', IFNULL(TRIM(AGZEI::text), '^^') 
            , '||', IFNULL(TRIM(PYCUR::text), '^^') 
            , '||', IFNULL(TRIM(PYAMT::text), '^^') 
            , '||', IFNULL(TRIM(BUPLA::text), '^^') 
            , '||', IFNULL(TRIM(SECCO::text), '^^') 
            , '||', IFNULL(TRIM(LSTAR::text), '^^') 
            , '||', IFNULL(TRIM(CESSION_KZ::text), '^^') 
            , '||', IFNULL(TRIM(PRZNR::text), '^^') 
            , '||', IFNULL(TRIM(PPDIFF::text), '^^') 
            , '||', IFNULL(TRIM(PPDIF2::text), '^^') 
            , '||', IFNULL(TRIM(PPDIF3::text), '^^') 
            , '||', IFNULL(TRIM(PENLC1::text), '^^') 
            , '||', IFNULL(TRIM(PENLC2::text), '^^') 
            , '||', IFNULL(TRIM(PENLC3::text), '^^') 
            , '||', IFNULL(TRIM(PENFC::text), '^^') 
            , '||', IFNULL(TRIM(PENDAYS::text), '^^') 
            , '||', IFNULL(TRIM(PENRC::text), '^^') 
            , '||', IFNULL(TRIM(GRANT_NBR::text), '^^') 
            , '||', IFNULL(TRIM(SCTAX::text), '^^') 
            , '||', IFNULL(TRIM(FKBER_LONG::text), '^^') 
            , '||', IFNULL(TRIM(GMVKZ::text), '^^') 
            , '||', IFNULL(TRIM(SRTYPE::text), '^^') 
            , '||', IFNULL(TRIM(INTRENO::text), '^^') 
            , '||', IFNULL(TRIM(MEASURE::text), '^^') 
            , '||', IFNULL(TRIM(AUGGJ::text), '^^') 
            , '||', IFNULL(TRIM(PPA_EX_IND::text), '^^') 
            , '||', IFNULL(TRIM(DOCLN::text), '^^') 
            , '||', IFNULL(TRIM(SEGMENT::text), '^^') 
            , '||', IFNULL(TRIM(PSEGMENT::text), '^^') 
            , '||', IFNULL(TRIM(PFKBER::text), '^^') 
            , '||', IFNULL(TRIM(HKTID::text), '^^') 
            , '||', IFNULL(TRIM(KSTAR::text), '^^') 
            , '||', IFNULL(TRIM(XLGCLR::text), '^^') 
            , '||', IFNULL(TRIM(TAXPS::text), '^^') 
            , '||', IFNULL(TRIM(PAYS_PROV::text), '^^') 
            , '||', IFNULL(TRIM(PAYS_TRAN::text), '^^') 
            , '||', IFNULL(TRIM(MNDID::text), '^^') 
            , '||', IFNULL(TRIM(XFRGE_BSEG::text), '^^') 
            , '||', IFNULL(TRIM(SQUAN::text), '^^') 
            , '||', IFNULL(TRIM(RE_BUKRS::text), '^^') 
            , '||', IFNULL(TRIM(RE_ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PGEBER::text), '^^') 
            , '||', IFNULL(TRIM(PGRANT_NBR::text), '^^') 
            , '||', IFNULL(TRIM(BUDGET_PD::text), '^^') 
            , '||', IFNULL(TRIM(PBUDGET_PD::text), '^^') 
            , '||', IFNULL(TRIM(J_1TPBUPL::text), '^^') 
            , '||', IFNULL(TRIM(PEROP_BEG::text), '^^') 
            , '||', IFNULL(TRIM(PEROP_END::text), '^^') 
            , '||', IFNULL(TRIM(FASTPAY::text), '^^') 
            , '||', IFNULL(TRIM(IGNR_IVREF::text), '^^') 
            , '||', IFNULL(TRIM(FMFGUS_KEY::text), '^^') 
            , '||', IFNULL(TRIM(FMXDOCNR::text), '^^') 
            , '||', IFNULL(TRIM(FMXYEAR::text), '^^') 
            , '||', IFNULL(TRIM(FMXDOCLN::text), '^^') 
            , '||', IFNULL(TRIM(FMXZEKKN::text), '^^') 
            , '||', IFNULL(TRIM(PRODPER::text), '^^') 
            , '||', IFNULL(TRIM(RECRF::text), '^^') 
            , '||', IFNULL(TRIM(INWARD_NO::text), '^^') 
            , '||', IFNULL(TRIM(INWARD_DT::text), '^^') 
            , '||', IFNULL(TRIM(PYMTKEY::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
