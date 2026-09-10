---- SRC LAYER ----
WITH
SRC_a              as ( SELECT AAUFG, ABLIPKZ, ADPSP, AEDAT, AENAM, AENNR, ANDAT, ANFKO, ANFKOKRS, ANLZU, ANNAM, ANZMA, ANZZL, ARBEH, ARBEI, ARBID, AUFAK, AUFKT, BMEIH, BMSCH, BMVRG, BUKRS, BZOFFB, BZOFFE, CAPOC, CKSELKZ, CLASSID, CN_WEIGHT, DAFKT, DATUV, DAUME, DAUMI, DAUNE, DAUNO, DDEHN, EBELN, EBELP, EBORT, EHOFFB, EHOFFE, EINSA, EINSE, EKGRP, EKORG, EQUNR, ERFSICHT, ESOKZ, EVGEW, FLG_CAPTXT, FLG_TSK_GROUP, FLIES, FRDLB, FRSP, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, INDET, INFNR, ISTKN, ISTNR, ISTPO, ISTRU, ISTTY, IUPOZ, KALID, KALKZ, KAPAR, KNOBJ, KRIT1, KTSCH, KZLGF, LAR01, LAR02, LAR03, LAR04, LAR05, LAR06, LARNT, LIFNR, LOANZ, LOART, LOEKZ, LOGRP, LTXA1, LTXA2, MANDT, MANU_PROC, MATKL, MDLID, MEINH, MES_OPERID, MES_STEPID, MINWE, MLSTN, NPRIO, NVADD, OBJTY, OFFSTB, OFFSTE, OPRID, PACKNO, PARKZ, PDEST, PEINH, PHFLG, PHSEQ, PLIFZ, PLNKN, PLNNR, PLNTY, PPRIO, PREIS, PRKST, PRZ01, PRZNT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSPNR, PVZKN, QKZPRFREI, QKZPRMENG, QKZPRZEIT, QKZTLSBEST, QKZZTMG1, QLKAPAR, QLOBJEKTID, QLOTYPE, QPART, QPPKTABS, QRASTEREH, QRASTERMNG, QRASTMENG, QRASTZEHT, QRASTZFAK, QUALF, RASCH, RFGRP, RFPNT, RFSCH, RSANZ, RSTRA, RUZUS, RWFAK, SAKTO, SLWID, SORTL, SPLIM, SPMUS, STEUS, SUBPLNAL, SUBPLNNR, SUBPLNTY, SUMNR, TAKT, TECHV, TPLNR, TXTSP, UAVO_AUFL, UEKAN, UEMUS, UMREN, UMREZ, USE04, USE05, USE06, USE07, USR00, USR01, USR02, USR03, USR04, USR05, USR06, USR07, USR08, USR09, USR10, USR11, VERDART, VERTL, VERTN, VGE01, VGE02, VGE03, VGE04, VGE05, VGE06, VGW01, VGW02, VGW03, VGW04, VGW05, VGW06, VINTV, VORNR, VPLAL, VPLFL, VPLNR, VPLTY, WAERS, WERKS, XEXCLTL, ZAEHL, ZCODE, ZEIER, ZEILM, ZEILP, ZEIMB, ZEIMU, ZEITM, ZEITN, ZEIWM, ZEIWN, ZERMA, ZGDAT, ZGR01, ZGR02, ZGR03, ZGR04, ZGR05, ZGR06, ZLMAX, ZLPRO, ZMERH, ZMINB, ZMINU, ZTMIN, ZTNOR, ZULNR, ZWMIN, ZWNOR FROM {{ source('sap_ecc_prd', 'z_plpo') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_plpo )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        MANDT
      , PLNTY
      , PLNNR
      , PLNKN
      , ZAEHL
      , GLREQUEST
      , DATUV
      , TECHV
      , AENNR
      , LOEKZ
      , PARKZ
      , ANDAT
      , ANNAM
      , AEDAT
      , AENAM
      , SUMNR
      , VORNR
      , STEUS
      , ARBID
      , OBJTY
      , WERKS
      , KTSCH
      , LTXA1
      , LTXA2
      , TXTSP
      , VPLTY
      , VPLNR
      , VPLAL
      , VPLFL
      , VINTV
      , MEINH
      , UMREN
      , UMREZ
      , BMSCH
      , ZMERH
      , ZEIER
      , LAR01
      , VGE01
      , VGW01
      , LAR02
      , VGE02
      , VGW02
      , LAR03
      , VGE03
      , VGW03
      , LAR04
      , VGE04
      , VGW04
      , LAR05
      , VGE05
      , VGW05
      , LAR06
      , VGE06
      , VGW06
      , ZERMA
      , ZGDAT
      , ZCODE
      , ZULNR
      , RSANZ
      , PDEST
      , LOANZ
      , LOART
      , QUALF
      , ANZMA
      , RFGRP
      , RFSCH
      , RASCH
      , AUFAK
      , LOGRP
      , UEMUS
      , UEKAN
      , FLIES
      , ZEIMU
      , ZMINU
      , MINWE
      , SPMUS
      , SPLIM
      , ZEIMB
      , ZMINB
      , ZEILM
      , ZLMAX
      , ZEILP
      , ZLPRO
      , ZEIWN
      , ZWNOR
      , ZEIWM
      , ZWMIN
      , ZEITN
      , ZTNOR
      , ZEITM
      , ZTMIN
      , ABLIPKZ
      , RSTRA
      , BZOFFB
      , OFFSTB
      , EHOFFB
      , BZOFFE
      , OFFSTE
      , EHOFFE
      , SORTL
      , LIFNR
      , PLIFZ
      , PREIS
      , PEINH
      , SAKTO
      , WAERS
      , INFNR
      , ESOKZ
      , EKORG
      , EKGRP
      , KZLGF
      , MATKL
      , DAUNO
      , DAUNE
      , DAUMI
      , DAUME
      , DDEHN
      , EINSA
      , EINSE
      , ARBEI
      , ARBEH
      , ANZZL
      , PRZNT
      , VERTL
      , MLSTN
      , PPRIO
      , BUKRS
      , SLWID
      , USR00
      , USR01
      , USR02
      , USR03
      , USR04
      , USE04
      , USR05
      , USE05
      , USR06
      , USE06
      , USR07
      , USE07
      , USR08
      , USR09
      , USR10
      , USR11
      , ANFKO
      , ANFKOKRS
      , KAPAR
      , INDET
      , LARNT
      , PRKST
      , QRASTERMNG
      , QRASTEREH
      , ANLZU
      , ISTRU
      , ISTTY
      , ISTNR
      , ISTKN
      , ISTPO
      , IUPOZ
      , EBORT
      , KALID
      , FRSP
      , VERTN
      , ZGR01
      , ZGR02
      , ZGR03
      , ZGR04
      , ZGR05
      , ZGR06
      , MDLID
      , RUZUS
      , BMEIH
      , BMVRG
      , CKSELKZ
      , KALKZ
      , NPRIO
      , PVZKN
      , PHFLG
      , PHSEQ
      , KNOBJ
      , ERFSICHT
      , PSPNR
      , QLOTYPE
      , QLOBJEKTID
      , QLKAPAR
      , QKZPRZEIT
      , QKZZTMG1
      , QKZPRMENG
      , QKZPRFREI
      , QRASTZEHT
      , QRASTZFAK
      , QRASTMENG
      , QPPKTABS
      , KRIT1
      , CLASSID
      , PACKNO
      , EBELN
      , EBELP
      , CAPOC
      , FLG_CAPTXT
      , CN_WEIGHT
      , QKZTLSBEST
      , AUFKT
      , DAFKT
      , RWFAK
      , AAUFG
      , VERDART
      , UAVO_AUFL
      , FRDLB
      , QPART
      , PRZ01
      , TAKT
      , OPRID
      , NVADD
      , EVGEW
      , RFPNT
      , FLG_TSK_GROUP
      , ADPSP
      , TPLNR
      , EQUNR
      , MES_OPERID
      , MES_STEPID
      , MANU_PROC
      , SUBPLNAL
      , SUBPLNNR
      , SUBPLNTY
      , XEXCLTL
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONCAT_WS('||', PLNTY, PLNNR, PLNKN)                         as                              TASKLIST_OPERATION_BK
      , IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,
            CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
            ))
        )                                                            as                                           LOAD_DTS
    FROM SRC_a
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        MANDT
      , PLNTY
      , PLNNR
      , PLNKN
      , ZAEHL
      , GLREQUEST
      , DATUV
      , TECHV
      , AENNR
      , LOEKZ
      , PARKZ
      , ANDAT
      , ANNAM
      , AEDAT
      , AENAM
      , SUMNR
      , VORNR
      , STEUS
      , ARBID
      , OBJTY
      , WERKS
      , KTSCH
      , LTXA1
      , LTXA2
      , TXTSP
      , VPLTY
      , VPLNR
      , VPLAL
      , VPLFL
      , VINTV
      , MEINH
      , UMREN
      , UMREZ
      , BMSCH
      , ZMERH
      , ZEIER
      , LAR01
      , VGE01
      , VGW01
      , LAR02
      , VGE02
      , VGW02
      , LAR03
      , VGE03
      , VGW03
      , LAR04
      , VGE04
      , VGW04
      , LAR05
      , VGE05
      , VGW05
      , LAR06
      , VGE06
      , VGW06
      , ZERMA
      , ZGDAT
      , ZCODE
      , ZULNR
      , RSANZ
      , PDEST
      , LOANZ
      , LOART
      , QUALF
      , ANZMA
      , RFGRP
      , RFSCH
      , RASCH
      , AUFAK
      , LOGRP
      , UEMUS
      , UEKAN
      , FLIES
      , ZEIMU
      , ZMINU
      , MINWE
      , SPMUS
      , SPLIM
      , ZEIMB
      , ZMINB
      , ZEILM
      , ZLMAX
      , ZEILP
      , ZLPRO
      , ZEIWN
      , ZWNOR
      , ZEIWM
      , ZWMIN
      , ZEITN
      , ZTNOR
      , ZEITM
      , ZTMIN
      , ABLIPKZ
      , RSTRA
      , BZOFFB
      , OFFSTB
      , EHOFFB
      , BZOFFE
      , OFFSTE
      , EHOFFE
      , SORTL
      , LIFNR
      , PLIFZ
      , PREIS
      , PEINH
      , SAKTO
      , WAERS
      , INFNR
      , ESOKZ
      , EKORG
      , EKGRP
      , KZLGF
      , MATKL
      , DAUNO
      , DAUNE
      , DAUMI
      , DAUME
      , DDEHN
      , EINSA
      , EINSE
      , ARBEI
      , ARBEH
      , ANZZL
      , PRZNT
      , VERTL
      , MLSTN
      , PPRIO
      , BUKRS
      , SLWID
      , USR00
      , USR01
      , USR02
      , USR03
      , USR04
      , USE04
      , USR05
      , USE05
      , USR06
      , USE06
      , USR07
      , USE07
      , USR08
      , USR09
      , USR10
      , USR11
      , ANFKO
      , ANFKOKRS
      , KAPAR
      , INDET
      , LARNT
      , PRKST
      , QRASTERMNG
      , QRASTEREH
      , ANLZU
      , ISTRU
      , ISTTY
      , ISTNR
      , ISTKN
      , ISTPO
      , IUPOZ
      , EBORT
      , KALID
      , FRSP
      , VERTN
      , ZGR01
      , ZGR02
      , ZGR03
      , ZGR04
      , ZGR05
      , ZGR06
      , MDLID
      , RUZUS
      , BMEIH
      , BMVRG
      , CKSELKZ
      , KALKZ
      , NPRIO
      , PVZKN
      , PHFLG
      , PHSEQ
      , KNOBJ
      , ERFSICHT
      , PSPNR
      , QLOTYPE
      , QLOBJEKTID
      , QLKAPAR
      , QKZPRZEIT
      , QKZZTMG1
      , QKZPRMENG
      , QKZPRFREI
      , QRASTZEHT
      , QRASTZFAK
      , QRASTMENG
      , QPPKTABS
      , KRIT1
      , CLASSID
      , PACKNO
      , EBELN
      , EBELP
      , CAPOC
      , FLG_CAPTXT
      , CN_WEIGHT
      , QKZTLSBEST
      , AUFKT
      , DAFKT
      , RWFAK
      , AAUFG
      , VERDART
      , UAVO_AUFL
      , FRDLB
      , QPART
      , PRZ01
      , TAKT
      , OPRID
      , NVADD
      , EVGEW
      , RFPNT
      , FLG_TSK_GROUP
      , ADPSP
      , TPLNR
      , EQUNR
      , MES_OPERID
      , MES_STEPID
      , MANU_PROC
      , SUBPLNAL
      , SUBPLNNR
      , SUBPLNTY
      , XEXCLTL
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , TASKLIST_OPERATION_BK
      , LOAD_DTS
    FROM LOGIC_a
)

, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_PLPO'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          MANDT
        , PLNTY
        , PLNNR
        , PLNKN
        , ZAEHL
        , GLREQUEST
        , DATUV
        , TECHV
        , AENNR
        , LOEKZ
        , PARKZ
        , ANDAT
        , ANNAM
        , AEDAT
        , AENAM
        , SUMNR
        , VORNR
        , STEUS
        , ARBID
        , OBJTY
        , WERKS
        , KTSCH
        , LTXA1
        , LTXA2
        , TXTSP
        , VPLTY
        , VPLNR
        , VPLAL
        , VPLFL
        , VINTV
        , MEINH
        , UMREN
        , UMREZ
        , BMSCH
        , ZMERH
        , ZEIER
        , LAR01
        , VGE01
        , VGW01
        , LAR02
        , VGE02
        , VGW02
        , LAR03
        , VGE03
        , VGW03
        , LAR04
        , VGE04
        , VGW04
        , LAR05
        , VGE05
        , VGW05
        , LAR06
        , VGE06
        , VGW06
        , ZERMA
        , ZGDAT
        , ZCODE
        , ZULNR
        , RSANZ
        , PDEST
        , LOANZ
        , LOART
        , QUALF
        , ANZMA
        , RFGRP
        , RFSCH
        , RASCH
        , AUFAK
        , LOGRP
        , UEMUS
        , UEKAN
        , FLIES
        , ZEIMU
        , ZMINU
        , MINWE
        , SPMUS
        , SPLIM
        , ZEIMB
        , ZMINB
        , ZEILM
        , ZLMAX
        , ZEILP
        , ZLPRO
        , ZEIWN
        , ZWNOR
        , ZEIWM
        , ZWMIN
        , ZEITN
        , ZTNOR
        , ZEITM
        , ZTMIN
        , ABLIPKZ
        , RSTRA
        , BZOFFB
        , OFFSTB
        , EHOFFB
        , BZOFFE
        , OFFSTE
        , EHOFFE
        , SORTL
        , LIFNR
        , PLIFZ
        , PREIS
        , PEINH
        , SAKTO
        , WAERS
        , INFNR
        , ESOKZ
        , EKORG
        , EKGRP
        , KZLGF
        , MATKL
        , DAUNO
        , DAUNE
        , DAUMI
        , DAUME
        , DDEHN
        , EINSA
        , EINSE
        , ARBEI
        , ARBEH
        , ANZZL
        , PRZNT
        , VERTL
        , MLSTN
        , PPRIO
        , BUKRS
        , SLWID
        , USR00
        , USR01
        , USR02
        , USR03
        , USR04
        , USE04
        , USR05
        , USE05
        , USR06
        , USE06
        , USR07
        , USE07
        , USR08
        , USR09
        , USR10
        , USR11
        , ANFKO
        , ANFKOKRS
        , KAPAR
        , INDET
        , LARNT
        , PRKST
        , QRASTERMNG
        , QRASTEREH
        , ANLZU
        , ISTRU
        , ISTTY
        , ISTNR
        , ISTKN
        , ISTPO
        , IUPOZ
        , EBORT
        , KALID
        , FRSP
        , VERTN
        , ZGR01
        , ZGR02
        , ZGR03
        , ZGR04
        , ZGR05
        , ZGR06
        , MDLID
        , RUZUS
        , BMEIH
        , BMVRG
        , CKSELKZ
        , KALKZ
        , NPRIO
        , PVZKN
        , PHFLG
        , PHSEQ
        , KNOBJ
        , ERFSICHT
        , PSPNR
        , QLOTYPE
        , QLOBJEKTID
        , QLKAPAR
        , QKZPRZEIT
        , QKZZTMG1
        , QKZPRMENG
        , QKZPRFREI
        , QRASTZEHT
        , QRASTZFAK
        , QRASTMENG
        , QPPKTABS
        , KRIT1
        , CLASSID
        , PACKNO
        , EBELN
        , EBELP
        , CAPOC
        , FLG_CAPTXT
        , CN_WEIGHT
        , QKZTLSBEST
        , AUFKT
        , DAFKT
        , RWFAK
        , AAUFG
        , VERDART
        , UAVO_AUFL
        , FRDLB
        , QPART
        , PRZ01
        , TAKT
        , OPRID
        , NVADD
        , EVGEW
        , RFPNT
        , FLG_TSK_GROUP
        , ADPSP
        , TPLNR
        , EQUNR
        , MES_OPERID
        , MES_STEPID
        , MANU_PROC
        , SUBPLNAL
        , SUBPLNNR
        , SUBPLNTY
        , XEXCLTL
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , TASKLIST_OPERATION_BK
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(TASKLIST_OPERATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as TASKLIST_OPERATION_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(ZAEHL::text), '^^') 
            , '||', IFNULL(TRIM(DATUV::text), '^^') 
            , '||', IFNULL(TRIM(TECHV::text), '^^') 
            , '||', IFNULL(TRIM(AENNR::text), '^^') 
            , '||', IFNULL(TRIM(LOEKZ::text), '^^') 
            , '||', IFNULL(TRIM(PARKZ::text), '^^') 
            , '||', IFNULL(TRIM(ANDAT::text), '^^') 
            , '||', IFNULL(TRIM(ANNAM::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(AENAM::text), '^^') 
            , '||', IFNULL(TRIM(SUMNR::text), '^^') 
            , '||', IFNULL(TRIM(VORNR::text), '^^') 
            , '||', IFNULL(TRIM(STEUS::text), '^^') 
            , '||', IFNULL(TRIM(ARBID::text), '^^') 
            , '||', IFNULL(TRIM(OBJTY::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(KTSCH::text), '^^') 
            , '||', IFNULL(TRIM(LTXA1::text), '^^') 
            , '||', IFNULL(TRIM(LTXA2::text), '^^') 
            , '||', IFNULL(TRIM(TXTSP::text), '^^') 
            , '||', IFNULL(TRIM(VPLTY::text), '^^') 
            , '||', IFNULL(TRIM(VPLNR::text), '^^') 
            , '||', IFNULL(TRIM(VPLAL::text), '^^') 
            , '||', IFNULL(TRIM(VPLFL::text), '^^') 
            , '||', IFNULL(TRIM(VINTV::text), '^^') 
            , '||', IFNULL(TRIM(MEINH::text), '^^') 
            , '||', IFNULL(TRIM(UMREN::text), '^^') 
            , '||', IFNULL(TRIM(UMREZ::text), '^^') 
            , '||', IFNULL(TRIM(BMSCH::text), '^^') 
            , '||', IFNULL(TRIM(ZMERH::text), '^^') 
            , '||', IFNULL(TRIM(ZEIER::text), '^^') 
            , '||', IFNULL(TRIM(LAR01::text), '^^') 
            , '||', IFNULL(TRIM(VGE01::text), '^^') 
            , '||', IFNULL(TRIM(VGW01::text), '^^') 
            , '||', IFNULL(TRIM(LAR02::text), '^^') 
            , '||', IFNULL(TRIM(VGE02::text), '^^') 
            , '||', IFNULL(TRIM(VGW02::text), '^^') 
            , '||', IFNULL(TRIM(LAR03::text), '^^') 
            , '||', IFNULL(TRIM(VGE03::text), '^^') 
            , '||', IFNULL(TRIM(VGW03::text), '^^') 
            , '||', IFNULL(TRIM(LAR04::text), '^^') 
            , '||', IFNULL(TRIM(VGE04::text), '^^') 
            , '||', IFNULL(TRIM(VGW04::text), '^^') 
            , '||', IFNULL(TRIM(LAR05::text), '^^') 
            , '||', IFNULL(TRIM(VGE05::text), '^^') 
            , '||', IFNULL(TRIM(VGW05::text), '^^') 
            , '||', IFNULL(TRIM(LAR06::text), '^^') 
            , '||', IFNULL(TRIM(VGE06::text), '^^') 
            , '||', IFNULL(TRIM(VGW06::text), '^^') 
            , '||', IFNULL(TRIM(ZERMA::text), '^^') 
            , '||', IFNULL(TRIM(ZGDAT::text), '^^') 
            , '||', IFNULL(TRIM(ZCODE::text), '^^') 
            , '||', IFNULL(TRIM(ZULNR::text), '^^') 
            , '||', IFNULL(TRIM(RSANZ::text), '^^') 
            , '||', IFNULL(TRIM(PDEST::text), '^^') 
            , '||', IFNULL(TRIM(LOANZ::text), '^^') 
            , '||', IFNULL(TRIM(LOART::text), '^^') 
            , '||', IFNULL(TRIM(QUALF::text), '^^') 
            , '||', IFNULL(TRIM(ANZMA::text), '^^') 
            , '||', IFNULL(TRIM(RFGRP::text), '^^') 
            , '||', IFNULL(TRIM(RFSCH::text), '^^') 
            , '||', IFNULL(TRIM(RASCH::text), '^^') 
            , '||', IFNULL(TRIM(AUFAK::text), '^^') 
            , '||', IFNULL(TRIM(LOGRP::text), '^^') 
            , '||', IFNULL(TRIM(UEMUS::text), '^^') 
            , '||', IFNULL(TRIM(UEKAN::text), '^^') 
            , '||', IFNULL(TRIM(FLIES::text), '^^') 
            , '||', IFNULL(TRIM(ZEIMU::text), '^^') 
            , '||', IFNULL(TRIM(ZMINU::text), '^^') 
            , '||', IFNULL(TRIM(MINWE::text), '^^') 
            , '||', IFNULL(TRIM(SPMUS::text), '^^') 
            , '||', IFNULL(TRIM(SPLIM::text), '^^') 
            , '||', IFNULL(TRIM(ZEIMB::text), '^^') 
            , '||', IFNULL(TRIM(ZMINB::text), '^^') 
            , '||', IFNULL(TRIM(ZEILM::text), '^^') 
            , '||', IFNULL(TRIM(ZLMAX::text), '^^') 
            , '||', IFNULL(TRIM(ZEILP::text), '^^') 
            , '||', IFNULL(TRIM(ZLPRO::text), '^^') 
            , '||', IFNULL(TRIM(ZEIWN::text), '^^') 
            , '||', IFNULL(TRIM(ZWNOR::text), '^^') 
            , '||', IFNULL(TRIM(ZEIWM::text), '^^') 
            , '||', IFNULL(TRIM(ZWMIN::text), '^^') 
            , '||', IFNULL(TRIM(ZEITN::text), '^^') 
            , '||', IFNULL(TRIM(ZTNOR::text), '^^') 
            , '||', IFNULL(TRIM(ZEITM::text), '^^') 
            , '||', IFNULL(TRIM(ZTMIN::text), '^^') 
            , '||', IFNULL(TRIM(ABLIPKZ::text), '^^') 
            , '||', IFNULL(TRIM(RSTRA::text), '^^') 
            , '||', IFNULL(TRIM(BZOFFB::text), '^^') 
            , '||', IFNULL(TRIM(OFFSTB::text), '^^') 
            , '||', IFNULL(TRIM(EHOFFB::text), '^^') 
            , '||', IFNULL(TRIM(BZOFFE::text), '^^') 
            , '||', IFNULL(TRIM(OFFSTE::text), '^^') 
            , '||', IFNULL(TRIM(EHOFFE::text), '^^') 
            , '||', IFNULL(TRIM(SORTL::text), '^^') 
            , '||', IFNULL(TRIM(LIFNR::text), '^^') 
            , '||', IFNULL(TRIM(PLIFZ::text), '^^') 
            , '||', IFNULL(TRIM(PREIS::text), '^^') 
            , '||', IFNULL(TRIM(PEINH::text), '^^') 
            , '||', IFNULL(TRIM(SAKTO::text), '^^') 
            , '||', IFNULL(TRIM(WAERS::text), '^^') 
            , '||', IFNULL(TRIM(INFNR::text), '^^') 
            , '||', IFNULL(TRIM(ESOKZ::text), '^^') 
            , '||', IFNULL(TRIM(EKORG::text), '^^') 
            , '||', IFNULL(TRIM(EKGRP::text), '^^') 
            , '||', IFNULL(TRIM(KZLGF::text), '^^') 
            , '||', IFNULL(TRIM(MATKL::text), '^^') 
            , '||', IFNULL(TRIM(DAUNO::text), '^^') 
            , '||', IFNULL(TRIM(DAUNE::text), '^^') 
            , '||', IFNULL(TRIM(DAUMI::text), '^^') 
            , '||', IFNULL(TRIM(DAUME::text), '^^') 
            , '||', IFNULL(TRIM(DDEHN::text), '^^') 
            , '||', IFNULL(TRIM(EINSA::text), '^^') 
            , '||', IFNULL(TRIM(EINSE::text), '^^') 
            , '||', IFNULL(TRIM(ARBEI::text), '^^') 
            , '||', IFNULL(TRIM(ARBEH::text), '^^') 
            , '||', IFNULL(TRIM(ANZZL::text), '^^') 
            , '||', IFNULL(TRIM(PRZNT::text), '^^') 
            , '||', IFNULL(TRIM(VERTL::text), '^^') 
            , '||', IFNULL(TRIM(MLSTN::text), '^^') 
            , '||', IFNULL(TRIM(PPRIO::text), '^^') 
            , '||', IFNULL(TRIM(BUKRS::text), '^^') 
            , '||', IFNULL(TRIM(SLWID::text), '^^') 
            , '||', IFNULL(TRIM(USR00::text), '^^') 
            , '||', IFNULL(TRIM(USR01::text), '^^') 
            , '||', IFNULL(TRIM(USR02::text), '^^') 
            , '||', IFNULL(TRIM(USR03::text), '^^') 
            , '||', IFNULL(TRIM(USR04::text), '^^') 
            , '||', IFNULL(TRIM(USE04::text), '^^') 
            , '||', IFNULL(TRIM(USR05::text), '^^') 
            , '||', IFNULL(TRIM(USE05::text), '^^') 
            , '||', IFNULL(TRIM(USR06::text), '^^') 
            , '||', IFNULL(TRIM(USE06::text), '^^') 
            , '||', IFNULL(TRIM(USR07::text), '^^') 
            , '||', IFNULL(TRIM(USE07::text), '^^') 
            , '||', IFNULL(TRIM(USR08::text), '^^') 
            , '||', IFNULL(TRIM(USR09::text), '^^') 
            , '||', IFNULL(TRIM(USR10::text), '^^') 
            , '||', IFNULL(TRIM(USR11::text), '^^') 
            , '||', IFNULL(TRIM(ANFKO::text), '^^') 
            , '||', IFNULL(TRIM(ANFKOKRS::text), '^^') 
            , '||', IFNULL(TRIM(KAPAR::text), '^^') 
            , '||', IFNULL(TRIM(INDET::text), '^^') 
            , '||', IFNULL(TRIM(LARNT::text), '^^') 
            , '||', IFNULL(TRIM(PRKST::text), '^^') 
            , '||', IFNULL(TRIM(QRASTERMNG::text), '^^') 
            , '||', IFNULL(TRIM(QRASTEREH::text), '^^') 
            , '||', IFNULL(TRIM(ANLZU::text), '^^') 
            , '||', IFNULL(TRIM(ISTRU::text), '^^') 
            , '||', IFNULL(TRIM(ISTTY::text), '^^') 
            , '||', IFNULL(TRIM(ISTNR::text), '^^') 
            , '||', IFNULL(TRIM(ISTKN::text), '^^') 
            , '||', IFNULL(TRIM(ISTPO::text), '^^') 
            , '||', IFNULL(TRIM(IUPOZ::text), '^^') 
            , '||', IFNULL(TRIM(EBORT::text), '^^') 
            , '||', IFNULL(TRIM(KALID::text), '^^') 
            , '||', IFNULL(TRIM(FRSP::text), '^^') 
            , '||', IFNULL(TRIM(VERTN::text), '^^') 
            , '||', IFNULL(TRIM(ZGR01::text), '^^') 
            , '||', IFNULL(TRIM(ZGR02::text), '^^') 
            , '||', IFNULL(TRIM(ZGR03::text), '^^') 
            , '||', IFNULL(TRIM(ZGR04::text), '^^') 
            , '||', IFNULL(TRIM(ZGR05::text), '^^') 
            , '||', IFNULL(TRIM(ZGR06::text), '^^') 
            , '||', IFNULL(TRIM(MDLID::text), '^^') 
            , '||', IFNULL(TRIM(RUZUS::text), '^^') 
            , '||', IFNULL(TRIM(BMEIH::text), '^^') 
            , '||', IFNULL(TRIM(BMVRG::text), '^^') 
            , '||', IFNULL(TRIM(CKSELKZ::text), '^^') 
            , '||', IFNULL(TRIM(KALKZ::text), '^^') 
            , '||', IFNULL(TRIM(NPRIO::text), '^^') 
            , '||', IFNULL(TRIM(PVZKN::text), '^^') 
            , '||', IFNULL(TRIM(PHFLG::text), '^^') 
            , '||', IFNULL(TRIM(PHSEQ::text), '^^') 
            , '||', IFNULL(TRIM(KNOBJ::text), '^^') 
            , '||', IFNULL(TRIM(ERFSICHT::text), '^^') 
            , '||', IFNULL(TRIM(PSPNR::text), '^^') 
            , '||', IFNULL(TRIM(QLOTYPE::text), '^^') 
            , '||', IFNULL(TRIM(QLOBJEKTID::text), '^^') 
            , '||', IFNULL(TRIM(QLKAPAR::text), '^^') 
            , '||', IFNULL(TRIM(QKZPRZEIT::text), '^^') 
            , '||', IFNULL(TRIM(QKZZTMG1::text), '^^') 
            , '||', IFNULL(TRIM(QKZPRMENG::text), '^^') 
            , '||', IFNULL(TRIM(QKZPRFREI::text), '^^') 
            , '||', IFNULL(TRIM(QRASTZEHT::text), '^^') 
            , '||', IFNULL(TRIM(QRASTZFAK::text), '^^') 
            , '||', IFNULL(TRIM(QRASTMENG::text), '^^') 
            , '||', IFNULL(TRIM(QPPKTABS::text), '^^') 
            , '||', IFNULL(TRIM(KRIT1::text), '^^') 
            , '||', IFNULL(TRIM(CLASSID::text), '^^') 
            , '||', IFNULL(TRIM(PACKNO::text), '^^') 
            , '||', IFNULL(TRIM(EBELN::text), '^^') 
            , '||', IFNULL(TRIM(EBELP::text), '^^') 
            , '||', IFNULL(TRIM(CAPOC::text), '^^') 
            , '||', IFNULL(TRIM(FLG_CAPTXT::text), '^^') 
            , '||', IFNULL(TRIM(CN_WEIGHT::text), '^^') 
            , '||', IFNULL(TRIM(QKZTLSBEST::text), '^^') 
            , '||', IFNULL(TRIM(AUFKT::text), '^^') 
            , '||', IFNULL(TRIM(DAFKT::text), '^^') 
            , '||', IFNULL(TRIM(RWFAK::text), '^^') 
            , '||', IFNULL(TRIM(AAUFG::text), '^^') 
            , '||', IFNULL(TRIM(VERDART::text), '^^') 
            , '||', IFNULL(TRIM(UAVO_AUFL::text), '^^') 
            , '||', IFNULL(TRIM(FRDLB::text), '^^') 
            , '||', IFNULL(TRIM(QPART::text), '^^') 
            , '||', IFNULL(TRIM(PRZ01::text), '^^') 
            , '||', IFNULL(TRIM(TAKT::text), '^^') 
            , '||', IFNULL(TRIM(OPRID::text), '^^') 
            , '||', IFNULL(TRIM(NVADD::text), '^^') 
            , '||', IFNULL(TRIM(EVGEW::text), '^^') 
            , '||', IFNULL(TRIM(RFPNT::text), '^^') 
            , '||', IFNULL(TRIM(FLG_TSK_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(ADPSP::text), '^^') 
            , '||', IFNULL(TRIM(TPLNR::text), '^^') 
            , '||', IFNULL(TRIM(EQUNR::text), '^^') 
            , '||', IFNULL(TRIM(MES_OPERID::text), '^^') 
            , '||', IFNULL(TRIM(MES_STEPID::text), '^^') 
            , '||', IFNULL(TRIM(MANU_PROC::text), '^^') 
            , '||', IFNULL(TRIM(SUBPLNAL::text), '^^') 
            , '||', IFNULL(TRIM(SUBPLNNR::text), '^^') 
            , '||', IFNULL(TRIM(SUBPLNTY::text), '^^') 
            , '||', IFNULL(TRIM(XEXCLTL::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
