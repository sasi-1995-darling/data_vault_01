---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ ref('v_psa_stg_tasklist_operation__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_a              as ( SELECT * FROM STAGING.V_PSA_STG_TASKLIST_OPERATION__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        TASKLIST_OPERATION_HK
      , MANDT
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
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        TASKLIST_OPERATION_HK
      , MANDT
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
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
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
          TASKLIST_OPERATION_HK
        , MANDT
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
        , LOAD_DTS
        , HASHDIFF
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.TASKLIST_OPERATION_HK = JOIN_RESULT.TASKLIST_OPERATION_HK 
AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by TASKLIST_OPERATION_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS TASKLIST_OPERATION_HK,
NULL AS MANDT,
GR.VALUE::text AS PLNTY,
GR.VALUE::text AS PLNNR,
GR.VALUE::text AS PLNKN,
GR.VALUE::text AS ZAEHL,
NULL AS GLREQUEST,
NULL AS DATUV,
NULL AS TECHV,
NULL AS AENNR,
NULL AS LOEKZ,
NULL AS PARKZ,
NULL AS ANDAT,
NULL AS ANNAM,
NULL AS AEDAT,
NULL AS AENAM,
NULL AS SUMNR,
NULL AS VORNR,
NULL AS STEUS,
NULL AS ARBID,
NULL AS OBJTY,
NULL AS WERKS,
NULL AS KTSCH,
NULL AS LTXA1,
NULL AS LTXA2,
NULL AS TXTSP,
NULL AS VPLTY,
NULL AS VPLNR,
NULL AS VPLAL,
NULL AS VPLFL,
NULL AS VINTV,
NULL AS MEINH,
NULL AS UMREN,
NULL AS UMREZ,
NULL AS BMSCH,
NULL AS ZMERH,
NULL AS ZEIER,
NULL AS LAR01,
NULL AS VGE01,
NULL AS VGW01,
NULL AS LAR02,
NULL AS VGE02,
NULL AS VGW02,
NULL AS LAR03,
NULL AS VGE03,
NULL AS VGW03,
NULL AS LAR04,
NULL AS VGE04,
NULL AS VGW04,
NULL AS LAR05,
NULL AS VGE05,
NULL AS VGW05,
NULL AS LAR06,
NULL AS VGE06,
NULL AS VGW06,
NULL AS ZERMA,
NULL AS ZGDAT,
NULL AS ZCODE,
NULL AS ZULNR,
NULL AS RSANZ,
NULL AS PDEST,
NULL AS LOANZ,
NULL AS LOART,
NULL AS QUALF,
NULL AS ANZMA,
NULL AS RFGRP,
NULL AS RFSCH,
NULL AS RASCH,
NULL AS AUFAK,
NULL AS LOGRP,
NULL AS UEMUS,
NULL AS UEKAN,
NULL AS FLIES,
NULL AS ZEIMU,
NULL AS ZMINU,
NULL AS MINWE,
NULL AS SPMUS,
NULL AS SPLIM,
NULL AS ZEIMB,
NULL AS ZMINB,
NULL AS ZEILM,
NULL AS ZLMAX,
NULL AS ZEILP,
NULL AS ZLPRO,
NULL AS ZEIWN,
NULL AS ZWNOR,
NULL AS ZEIWM,
NULL AS ZWMIN,
NULL AS ZEITN,
NULL AS ZTNOR,
NULL AS ZEITM,
NULL AS ZTMIN,
NULL AS ABLIPKZ,
NULL AS RSTRA,
NULL AS BZOFFB,
NULL AS OFFSTB,
NULL AS EHOFFB,
NULL AS BZOFFE,
NULL AS OFFSTE,
NULL AS EHOFFE,
NULL AS SORTL,
NULL AS LIFNR,
NULL AS PLIFZ,
NULL AS PREIS,
NULL AS PEINH,
NULL AS SAKTO,
NULL AS WAERS,
NULL AS INFNR,
NULL AS ESOKZ,
NULL AS EKORG,
NULL AS EKGRP,
NULL AS KZLGF,
NULL AS MATKL,
NULL AS DAUNO,
NULL AS DAUNE,
NULL AS DAUMI,
NULL AS DAUME,
NULL AS DDEHN,
NULL AS EINSA,
NULL AS EINSE,
NULL AS ARBEI,
NULL AS ARBEH,
NULL AS ANZZL,
NULL AS PRZNT,
NULL AS VERTL,
NULL AS MLSTN,
NULL AS PPRIO,
NULL AS BUKRS,
NULL AS SLWID,
NULL AS USR00,
NULL AS USR01,
NULL AS USR02,
NULL AS USR03,
NULL AS USR04,
NULL AS USE04,
NULL AS USR05,
NULL AS USE05,
NULL AS USR06,
NULL AS USE06,
NULL AS USR07,
NULL AS USE07,
NULL AS USR08,
NULL AS USR09,
NULL AS USR10,
NULL AS USR11,
NULL AS ANFKO,
NULL AS ANFKOKRS,
NULL AS KAPAR,
NULL AS INDET,
NULL AS LARNT,
NULL AS PRKST,
NULL AS QRASTERMNG,
NULL AS QRASTEREH,
NULL AS ANLZU,
NULL AS ISTRU,
NULL AS ISTTY,
NULL AS ISTNR,
NULL AS ISTKN,
NULL AS ISTPO,
NULL AS IUPOZ,
NULL AS EBORT,
NULL AS KALID,
NULL AS FRSP,
NULL AS VERTN,
NULL AS ZGR01,
NULL AS ZGR02,
NULL AS ZGR03,
NULL AS ZGR04,
NULL AS ZGR05,
NULL AS ZGR06,
NULL AS MDLID,
NULL AS RUZUS,
NULL AS BMEIH,
NULL AS BMVRG,
NULL AS CKSELKZ,
NULL AS KALKZ,
NULL AS NPRIO,
NULL AS PVZKN,
NULL AS PHFLG,
NULL AS PHSEQ,
NULL AS KNOBJ,
NULL AS ERFSICHT,
NULL AS PSPNR,
NULL AS QLOTYPE,
NULL AS QLOBJEKTID,
NULL AS QLKAPAR,
NULL AS QKZPRZEIT,
NULL AS QKZZTMG1,
NULL AS QKZPRMENG,
NULL AS QKZPRFREI,
NULL AS QRASTZEHT,
NULL AS QRASTZFAK,
NULL AS QRASTMENG,
NULL AS QPPKTABS,
NULL AS KRIT1,
NULL AS CLASSID,
NULL AS PACKNO,
NULL AS EBELN,
NULL AS EBELP,
NULL AS CAPOC,
NULL AS FLG_CAPTXT,
NULL AS CN_WEIGHT,
NULL AS QKZTLSBEST,
NULL AS AUFKT,
NULL AS DAFKT,
NULL AS RWFAK,
NULL AS AAUFG,
NULL AS VERDART,
NULL AS UAVO_AUFL,
NULL AS FRDLB,
NULL AS QPART,
NULL AS PRZ01,
NULL AS TAKT,
NULL AS OPRID,
NULL AS NVADD,
NULL AS EVGEW,
NULL AS RFPNT,
NULL AS FLG_TSK_GROUP,
NULL AS ADPSP,
NULL AS TPLNR,
NULL AS EQUNR,
NULL AS MES_OPERID,
NULL AS MES_STEPID,
NULL AS MANU_PROC,
NULL AS SUBPLNAL,
NULL AS SUBPLNNR,
NULL AS SUBPLNTY,
NULL AS XEXCLTL,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLSOURCESYSTEM,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
''::BINARY AS HASHDIFF,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
