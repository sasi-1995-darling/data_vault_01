---- SRC LAYER ----
WITH
SRC_SOSAP          as ( SELECT * FROM {{ ref('v_psa_stg_order_header__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SOSAP          as ( SELECT * FROM STAGING.v_psa_stg_order_header__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_SOSAP as (
    SELECT
        ORDER_HEADER_HK
      , MANDT
      , VBELN
      , GLREQUEST
      , ERDAT
      , ERZET
      , ERNAM
      , ANGDT
      , BNDDT
      , AUDAT
      , VBTYP
      , TRVOG
      , AUART
      , AUGRU
      , GWLDT
      , SUBMI
      , LIFSK
      , FAKSK
      , NETWR
      , WAERK
      , VKORG
      , VTWEG
      , SPART
      , VKGRP
      , VKBUR
      , GSBER
      , GSKST
      , GUEBG
      , GUEEN
      , KNUMV
      , VDATU
      , VPRGR
      , AUTLF
      , VBKLA
      , VBKLT
      , KALSM
      , VSBED
      , FKARA
      , AWAHR
      , KTEXT
      , BSTNK
      , BSARK
      , BSTDK
      , BSTZD
      , IHREZ
      , BNAME
      , TELF1
      , MAHZA
      , MAHDT
      , KUNNR
      , KOSTL
      , STAFO
      , STWAE
      , AEDAT
      , KVGR1
      , KVGR2
      , KVGR3
      , KVGR4
      , KVGR5
      , KNUMA
      , KOKRS
      , PS_PSP_PNR
      , KURST
      , KKBER
      , KNKLI
      , GRUPP
      , SBGRP
      , CTLPC
      , CMWAE
      , CMFRE
      , CMNUP
      , CMNGV
      , AMTBL
      , HITYP_PR
      , ABRVW
      , ABDIS
      , VGBEL
      , OBJNR
      , BUKRS_VF
      , TAXK1
      , TAXK2
      , TAXK3
      , TAXK4
      , TAXK5
      , TAXK6
      , TAXK7
      , TAXK8
      , TAXK9
      , XBLNR
      , ZUONR
      , VGTYP
      , KALSM_CH
      , AGRZR
      , AUFNR
      , QMNUM
      , VBELN_GRP
      , SCHEME_GRP
      , ABRUF_PART
      , ABHOD
      , ABHOV
      , ABHOB
      , RPLNR
      , VZEIT
      , STCEG_L
      , LANDTX
      , XEGDR
      , ENQUEUE_GRP
      , DAT_FZAU
      , FMBDAT
      , VSNMR_V
      , HANDLE
      , PROLI
      , CONT_DG
      , CRM_GUID
      , UPD_TMSTMP
      , MSR_ID
      , TM_CTRL_KEY
      , HANDOVERLOC
      , _DATAAGING
      , PSM_BUDAT
      , FSH_KVGR6
      , FSH_KVGR7
      , FSH_KVGR8
      , FSH_KVGR9
      , FSH_KVGR10
      , FSH_REREG
      , FSH_CQ_CHECK
      , FSH_VRSN_STATUS
      , FSH_TRANSACTION
      , FSH_VAS_CG
      , FSH_CANDATE
      , FSH_SS
      , FSH_OS_STG_CHANGE
      , SWENR
      , SMENR
      , PHASE
      , MTLAUR
      , STAGE
      , HB_CONT_REASON
      , HB_EXPDATE
      , HB_RESDATE
      , MILL_APPL_ID
      , TAS
      , BETC
      , MOD_ALLOW
      , CANCEL_ALLOW
      , PAY_METHOD
      , BPN
      , REP_FREQ
      , LOGSYSB
      , KALCD
      , MULTI
      , SPPAYM
      , WTYSC_CLM_HDR
      , ZZKNUMAK
      , BZIRK
      , ZZRSD
      , ZZRCG
      , ZZORC
      , ZZBUILDER
      , ZZAUFNR
      , ZZCUSTTL
      , ZZJOBTYPE
      , ZZJOBNAME
      , ZZJOBCITY
      , ZZJOBREGION
      , ZZJOBCOUNTRY
      , ZZJOBPOSTCODE
      , ZZJOBUNITS
      , ZZJOBBUILDER
      , ZZJOBPLUMBER
      , ZZQUOTETYPE
      , ZZDRAFT
      , ZZOUTCOME
      , ZZOUTCOMEDT
      , ZZESTSTARTDT
      , ZZREVNUM
      , ZZCRMACTIVITY
      , ZZVIP
      , ZZVPA
      , ZZVALVESPER
      , ZZPROGRAM
      , ZZNATIONAL
      , ZZBLDPROGAMT
      , ZZLEADREF
      , ZZLEADSOURCE
      , ZZPROMOCODE
      , ZZCRMNUM
      , ZZ3RDPARTAXMPT
      , ZZRDI
      , ZZTMS
      , ZZCONSOLIDATE
      , ZZAPNTMNT
      , ZZSTRSHPDTE
      , ZZENDSHPDTE
      , ZZTMSEXE
      , ZZERR
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SOSAP
)
---- RENAME LAYER ----

, RENAME_SOSAP as (
    SELECT
        ORDER_HEADER_HK
      , MANDT
      , VBELN
      , GLREQUEST
      , ERDAT
      , ERZET
      , ERNAM
      , ANGDT
      , BNDDT
      , AUDAT
      , VBTYP
      , TRVOG
      , AUART
      , AUGRU
      , GWLDT
      , SUBMI
      , LIFSK
      , FAKSK
      , NETWR
      , WAERK
      , VKORG
      , VTWEG
      , SPART
      , VKGRP
      , VKBUR
      , GSBER
      , GSKST
      , GUEBG
      , GUEEN
      , KNUMV
      , VDATU
      , VPRGR
      , AUTLF
      , VBKLA
      , VBKLT
      , KALSM
      , VSBED
      , FKARA
      , AWAHR
      , KTEXT
      , BSTNK
      , BSARK
      , BSTDK
      , BSTZD
      , IHREZ
      , BNAME
      , TELF1
      , MAHZA
      , MAHDT
      , KUNNR
      , KOSTL
      , STAFO
      , STWAE
      , AEDAT
      , KVGR1
      , KVGR2
      , KVGR3
      , KVGR4
      , KVGR5
      , KNUMA
      , KOKRS
      , PS_PSP_PNR
      , KURST
      , KKBER
      , KNKLI
      , GRUPP
      , SBGRP
      , CTLPC
      , CMWAE
      , CMFRE
      , CMNUP
      , CMNGV
      , AMTBL
      , HITYP_PR
      , ABRVW
      , ABDIS
      , VGBEL
      , OBJNR
      , BUKRS_VF
      , TAXK1
      , TAXK2
      , TAXK3
      , TAXK4
      , TAXK5
      , TAXK6
      , TAXK7
      , TAXK8
      , TAXK9
      , XBLNR
      , ZUONR
      , VGTYP
      , KALSM_CH
      , AGRZR
      , AUFNR
      , QMNUM
      , VBELN_GRP
      , SCHEME_GRP
      , ABRUF_PART
      , ABHOD
      , ABHOV
      , ABHOB
      , RPLNR
      , VZEIT
      , STCEG_L
      , LANDTX
      , XEGDR
      , ENQUEUE_GRP
      , DAT_FZAU
      , FMBDAT
      , VSNMR_V
      , HANDLE
      , PROLI
      , CONT_DG
      , CRM_GUID
      , UPD_TMSTMP
      , MSR_ID
      , TM_CTRL_KEY
      , HANDOVERLOC
      , _DATAAGING
      , PSM_BUDAT
      , FSH_KVGR6
      , FSH_KVGR7
      , FSH_KVGR8
      , FSH_KVGR9
      , FSH_KVGR10
      , FSH_REREG
      , FSH_CQ_CHECK
      , FSH_VRSN_STATUS
      , FSH_TRANSACTION
      , FSH_VAS_CG
      , FSH_CANDATE
      , FSH_SS
      , FSH_OS_STG_CHANGE
      , SWENR
      , SMENR
      , PHASE
      , MTLAUR
      , STAGE
      , HB_CONT_REASON
      , HB_EXPDATE
      , HB_RESDATE
      , MILL_APPL_ID
      , TAS
      , BETC
      , MOD_ALLOW
      , CANCEL_ALLOW
      , PAY_METHOD
      , BPN
      , REP_FREQ
      , LOGSYSB
      , KALCD
      , MULTI
      , SPPAYM
      , WTYSC_CLM_HDR
      , ZZKNUMAK
      , BZIRK
      , ZZRSD
      , ZZRCG
      , ZZORC
      , ZZBUILDER
      , ZZAUFNR
      , ZZCUSTTL
      , ZZJOBTYPE
      , ZZJOBNAME
      , ZZJOBCITY
      , ZZJOBREGION
      , ZZJOBCOUNTRY
      , ZZJOBPOSTCODE
      , ZZJOBUNITS
      , ZZJOBBUILDER
      , ZZJOBPLUMBER
      , ZZQUOTETYPE
      , ZZDRAFT
      , ZZOUTCOME
      , ZZOUTCOMEDT
      , ZZESTSTARTDT
      , ZZREVNUM
      , ZZCRMACTIVITY
      , ZZVIP
      , ZZVPA
      , ZZVALVESPER
      , ZZPROGRAM
      , ZZNATIONAL
      , ZZBLDPROGAMT
      , ZZLEADREF
      , ZZLEADSOURCE
      , ZZPROMOCODE
      , ZZCRMNUM
      , ZZ3RDPARTAXMPT
      , ZZRDI
      , ZZTMS
      , ZZCONSOLIDATE
      , ZZAPNTMNT
      , ZZSTRSHPDTE
      , ZZENDSHPDTE
      , ZZTMSEXE
      , ZZERR
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_SOSAP
)
---- FILTER LAYER ----

, FILTER_SOSAP as (
    SELECT *
    FROM RENAME_SOSAP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SOSAP
)

---- FINAL LAYER ----
SELECT
          ORDER_HEADER_HK
        , MANDT
        , VBELN
        , GLREQUEST
        , ERDAT
        , ERZET
        , ERNAM
        , ANGDT
        , BNDDT
        , AUDAT
        , VBTYP
        , TRVOG
        , AUART
        , AUGRU
        , GWLDT
        , SUBMI
        , LIFSK
        , FAKSK
        , NETWR
        , WAERK
        , VKORG
        , VTWEG
        , SPART
        , VKGRP
        , VKBUR
        , GSBER
        , GSKST
        , GUEBG
        , GUEEN
        , KNUMV
        , VDATU
        , VPRGR
        , AUTLF
        , VBKLA
        , VBKLT
        , KALSM
        , VSBED
        , FKARA
        , AWAHR
        , KTEXT
        , BSTNK
        , BSARK
        , BSTDK
        , BSTZD
        , IHREZ
        , BNAME
        , TELF1
        , MAHZA
        , MAHDT
        , KUNNR
        , KOSTL
        , STAFO
        , STWAE
        , AEDAT
        , KVGR1
        , KVGR2
        , KVGR3
        , KVGR4
        , KVGR5
        , KNUMA
        , KOKRS
        , PS_PSP_PNR
        , KURST
        , KKBER
        , KNKLI
        , GRUPP
        , SBGRP
        , CTLPC
        , CMWAE
        , CMFRE
        , CMNUP
        , CMNGV
        , AMTBL
        , HITYP_PR
        , ABRVW
        , ABDIS
        , VGBEL
        , OBJNR
        , BUKRS_VF
        , TAXK1
        , TAXK2
        , TAXK3
        , TAXK4
        , TAXK5
        , TAXK6
        , TAXK7
        , TAXK8
        , TAXK9
        , XBLNR
        , ZUONR
        , VGTYP
        , KALSM_CH
        , AGRZR
        , AUFNR
        , QMNUM
        , VBELN_GRP
        , SCHEME_GRP
        , ABRUF_PART
        , ABHOD
        , ABHOV
        , ABHOB
        , RPLNR
        , VZEIT
        , STCEG_L
        , LANDTX
        , XEGDR
        , ENQUEUE_GRP
        , DAT_FZAU
        , FMBDAT
        , VSNMR_V
        , HANDLE
        , PROLI
        , CONT_DG
        , CRM_GUID
        , UPD_TMSTMP
        , MSR_ID
        , TM_CTRL_KEY
        , HANDOVERLOC
        , _DATAAGING
        , PSM_BUDAT
        , FSH_KVGR6
        , FSH_KVGR7
        , FSH_KVGR8
        , FSH_KVGR9
        , FSH_KVGR10
        , FSH_REREG
        , FSH_CQ_CHECK
        , FSH_VRSN_STATUS
        , FSH_TRANSACTION
        , FSH_VAS_CG
        , FSH_CANDATE
        , FSH_SS
        , FSH_OS_STG_CHANGE
        , SWENR
        , SMENR
        , PHASE
        , MTLAUR
        , STAGE
        , HB_CONT_REASON
        , HB_EXPDATE
        , HB_RESDATE
        , MILL_APPL_ID
        , TAS
        , BETC
        , MOD_ALLOW
        , CANCEL_ALLOW
        , PAY_METHOD
        , BPN
        , REP_FREQ
        , LOGSYSB
        , KALCD
        , MULTI
        , SPPAYM
        , WTYSC_CLM_HDR
        , ZZKNUMAK
        , BZIRK
        , ZZRSD
        , ZZRCG
        , ZZORC
        , ZZBUILDER
        , ZZAUFNR
        , ZZCUSTTL
        , ZZJOBTYPE
        , ZZJOBNAME
        , ZZJOBCITY
        , ZZJOBREGION
        , ZZJOBCOUNTRY
        , ZZJOBPOSTCODE
        , ZZJOBUNITS
        , ZZJOBBUILDER
        , ZZJOBPLUMBER
        , ZZQUOTETYPE
        , ZZDRAFT
        , ZZOUTCOME
        , ZZOUTCOMEDT
        , ZZESTSTARTDT
        , ZZREVNUM
        , ZZCRMACTIVITY
        , ZZVIP
        , ZZVPA
        , ZZVALVESPER
        , ZZPROGRAM
        , ZZNATIONAL
        , ZZBLDPROGAMT
        , ZZLEADREF
        , ZZLEADSOURCE
        , ZZPROMOCODE
        , ZZCRMNUM
        , ZZ3RDPARTAXMPT
        , ZZRDI
        , ZZTMS
        , ZZCONSOLIDATE
        , ZZAPNTMNT
        , ZZSTRSHPDTE
        , ZZENDSHPDTE
        , ZZTMSEXE
        , ZZERR
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
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
    WHERE existing.ORDER_HEADER_HK= JOIN_RESULT.ORDER_HEADER_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by ORDER_HEADER_HK, HASHDIFF order by LOAD_DTS)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS ORDER_HEADER_HK
, NULL AS  MANDT
, NULL AS  VBELN
, NULL AS  GLREQUEST
, NULL AS  ERDAT
, NULL AS  ERZET
, NULL AS  ERNAM
, NULL AS  ANGDT
, NULL AS  BNDDT
, NULL AS  AUDAT
, NULL AS  VBTYP
, NULL AS  TRVOG
, NULL AS  AUART
, NULL AS  AUGRU
, NULL AS  GWLDT
, NULL AS  SUBMI
, NULL AS  LIFSK
, NULL AS  FAKSK
, NULL AS  NETWR
, NULL AS  WAERK
, NULL AS  VKORG
, NULL AS  VTWEG
, NULL AS  SPART
, NULL AS  VKGRP
, NULL AS  VKBUR
, NULL AS  GSBER
, NULL AS  GSKST
, NULL AS  GUEBG
, NULL AS  GUEEN
, NULL AS  KNUMV
, NULL AS  VDATU
, NULL AS  VPRGR
, NULL AS  AUTLF
, NULL AS  VBKLA
, NULL AS  VBKLT
, NULL AS  KALSM
, NULL AS  VSBED
, NULL AS  FKARA
, NULL AS  AWAHR
, NULL AS  KTEXT
, NULL AS  BSTNK
, NULL AS  BSARK
, NULL AS  BSTDK
, NULL AS  BSTZD
, NULL AS  IHREZ
, NULL AS  BNAME
, NULL AS  TELF1
, NULL AS  MAHZA
, NULL AS  MAHDT
, NULL AS  KUNNR
, NULL AS  KOSTL
, NULL AS  STAFO
, NULL AS  STWAE
, NULL AS  AEDAT
, NULL AS  KVGR1
, NULL AS  KVGR2
, NULL AS  KVGR3
, NULL AS  KVGR4
, NULL AS  KVGR5
, NULL AS  KNUMA
, NULL AS  KOKRS
, NULL AS  PS_PSP_PNR
, NULL AS  KURST
, NULL AS  KKBER
, NULL AS  KNKLI
, NULL AS  GRUPP
, NULL AS  SBGRP
, NULL AS  CTLPC
, NULL AS  CMWAE
, NULL AS  CMFRE
, NULL AS  CMNUP
, NULL AS  CMNGV
, NULL AS  AMTBL
, NULL AS  HITYP_PR
, NULL AS  ABRVW
, NULL AS  ABDIS
, NULL AS  VGBEL
, NULL AS  OBJNR
, NULL AS  BUKRS_VF
, NULL AS  TAXK1
, NULL AS  TAXK2
, NULL AS  TAXK3
, NULL AS  TAXK4
, NULL AS  TAXK5
, NULL AS  TAXK6
, NULL AS  TAXK7
, NULL AS  TAXK8
, NULL AS  TAXK9
, NULL AS  XBLNR
, NULL AS  ZUONR
, NULL AS  VGTYP
, NULL AS  KALSM_CH
, NULL AS  AGRZR
, NULL AS  AUFNR
, NULL AS  QMNUM
, NULL AS  VBELN_GRP
, NULL AS  SCHEME_GRP
, NULL AS  ABRUF_PART
, NULL AS  ABHOD
, NULL AS  ABHOV
, NULL AS  ABHOB
, NULL AS  RPLNR
, NULL AS  VZEIT
, NULL AS  STCEG_L
, NULL AS  LANDTX
, NULL AS  XEGDR
, NULL AS  ENQUEUE_GRP
, NULL AS  DAT_FZAU
, NULL AS  FMBDAT
, NULL AS  VSNMR_V
, NULL AS  HANDLE
, NULL AS  PROLI
, NULL AS  CONT_DG
, NULL AS  CRM_GUID
, NULL AS  UPD_TMSTMP
, NULL AS  MSR_ID
, NULL AS  TM_CTRL_KEY
, NULL AS  HANDOVERLOC
, NULL AS  _DATAAGING
, NULL AS  PSM_BUDAT
, NULL AS  FSH_KVGR6
, NULL AS  FSH_KVGR7
, NULL AS  FSH_KVGR8
, NULL AS  FSH_KVGR9
, NULL AS  FSH_KVGR10
, NULL AS  FSH_REREG
, NULL AS  FSH_CQ_CHECK
, NULL AS  FSH_VRSN_STATUS
, NULL AS  FSH_TRANSACTION
, NULL AS  FSH_VAS_CG
, NULL AS  FSH_CANDATE
, NULL AS  FSH_SS
, NULL AS  FSH_OS_STG_CHANGE
, NULL AS  SWENR
, NULL AS  SMENR
, NULL AS  PHASE
, NULL AS  MTLAUR
, NULL AS  STAGE
, NULL AS  HB_CONT_REASON
, NULL AS  HB_EXPDATE
, NULL AS  HB_RESDATE
, NULL AS  MILL_APPL_ID
, NULL AS  TAS
, NULL AS  BETC
, NULL AS  MOD_ALLOW
, NULL AS  CANCEL_ALLOW
, NULL AS  PAY_METHOD
, NULL AS  BPN
, NULL AS  REP_FREQ
, NULL AS  LOGSYSB
, NULL AS  KALCD
, NULL AS  MULTI
, NULL AS  SPPAYM
, NULL AS  WTYSC_CLM_HDR
, NULL AS  ZZKNUMAK
, NULL AS  BZIRK
, NULL AS  ZZRSD
, NULL AS  ZZRCG
, NULL AS  ZZORC
, NULL AS  ZZBUILDER
, NULL AS  ZZAUFNR
, NULL AS  ZZCUSTTL
, NULL AS  ZZJOBTYPE
, NULL AS  ZZJOBNAME
, NULL AS  ZZJOBCITY
, NULL AS  ZZJOBREGION
, NULL AS  ZZJOBCOUNTRY
, NULL AS  ZZJOBPOSTCODE
, NULL AS  ZZJOBUNITS
, NULL AS  ZZJOBBUILDER
, NULL AS  ZZJOBPLUMBER
, NULL AS  ZZQUOTETYPE
, NULL AS  ZZDRAFT
, NULL AS  ZZOUTCOME
, NULL AS  ZZOUTCOMEDT
, NULL AS  ZZESTSTARTDT
, NULL AS  ZZREVNUM
, NULL AS  ZZCRMACTIVITY
, NULL AS  ZZVIP
, NULL AS  ZZVPA
, NULL AS  ZZVALVESPER
, NULL AS  ZZPROGRAM
, NULL AS  ZZNATIONAL
, NULL AS  ZZBLDPROGAMT
, NULL AS  ZZLEADREF
, NULL AS  ZZLEADSOURCE
, NULL AS  ZZPROMOCODE
, NULL AS  ZZCRMNUM
, NULL AS  ZZ3RDPARTAXMPT
, NULL AS  ZZRDI
, NULL AS  ZZTMS
, NULL AS  ZZCONSOLIDATE
, NULL AS  ZZAPNTMNT
, NULL AS  ZZSTRSHPDTE
, NULL AS  ZZENDSHPDTE
, NULL AS  ZZTMSEXE
, NULL AS  ZZERR
, NULL AS  GLDELFLAG
, NULL AS  GLCHANGETIME
, NULL AS  GLSOURCESYSTEM
, NULL AS PSA_DELETE_IND
, CONVERT_TIMEZONE('UTC','1900-01-01') as LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASHDIFF FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}