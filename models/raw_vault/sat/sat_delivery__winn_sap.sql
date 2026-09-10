---- SRC LAYER ----
WITH
SRC_b              as ( SELECT * FROM {{ ref('v_psa_stg_delivery_header__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_b              as ( SELECT * FROM STAGING.V_PSA_STG_DELIVERY__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        DELIVERY_HK
      , MANDT
      , VBELN
      , GLREQUEST
      , ERNAM
      , ERZET
      , ERDAT
      , BZIRK
      , VSTEL
      , VKORG
      , LFART
      , AUTLF
      , KZAZU
      , WADAT
      , LDDAT
      , TDDAT
      , LFDAT
      , KODAT
      , ABLAD
      , INCO1
      , INCO2
      , EXPKZ
      , ROUTE
      , FAKSK
      , LIFSK
      , VBTYP
      , KNFAK
      , TPQUA
      , TPGRP
      , LPRIO
      , VSBED
      , KUNNR
      , KUNAG
      , KDGRP
      , STZKL
      , STZZU
      , BTGEW
      , NTGEW
      , GEWEI
      , VOLUM
      , VOLEH
      , ANZPK
      , BEROT
      , LFUHR
      , GRULG
      , LSTEL
      , TRAGR
      , FKARV
      , FKDAT
      , PERFK
      , ROUTA
      , STAFO
      , KALSM
      , KNUMV
      , WAERK
      , VKBUR
      , VBEAK
      , ZUKRL
      , VERUR
      , COMMN
      , STWAE
      , STCUR
      , EXNUM
      , AENAM
      , AEDAT
      , LGNUM
      , LISPL
      , VKOIV
      , VTWIV
      , SPAIV
      , FKAIV
      , PIOIV
      , FKDIV
      , KUNIV
      , KKBER
      , KNKLI
      , GRUPP
      , SBGRP
      , CTLPC
      , CMWAE
      , AMTBL
      , BOLNR
      , LIFNR
      , TRATY
      , TRAID
      , CMFRE
      , CMNGV
      , XABLN
      , BLDAT
      , WADAT_IST
      , TRSPG
      , TPSID
      , LIFEX
      , TERNR
      , KALSM_CH
      , KLIEF
      , KALSP
      , KNUMP
      , NETWR
      , AULWE
      , WERKS
      , LCNUM
      , ABSSC
      , KOUHR
      , TDUHR
      , LDUHR
      , WAUHR
      , LGTOR
      , LGBZO
      , AKWAE
      , AKKUR
      , AKPRZ
      , PROLI
      , XBLNR
      , HANDLE
      , TSEGFL
      , TSEGTP
      , TZONIS
      , TZONRC
      , CONT_DG
      , VERURSYS
      , KZWAB
      , VLSTK
      , TCODE
      , VSART
      , TRMTYP
      , SDABW
      , VBUND
      , XWOFF
      , DIRTA
      , PRVBE
      , FOLAR
      , PODAT
      , POTIM
      , VGANZ
      , IMWRK
      , SPE_LOEKZ
      , SPE_LOC_SEQ
      , SPE_ACC_APP_STS
      , SPE_SHP_INF_STS
      , SPE_RET_CANC
      , SPE_WAUHR_IST
      , SPE_WAZONE_IST
      , SPE_REV_VLSTK
      , SPE_LE_SCENARIO
      , SPE_ORIG_SYS
      , SPE_CHNG_SYS
      , SPE_GEOROUTE
      , SPE_GEOROUTEIND
      , SPE_CARRIER_IND
      , SPE_GTS_REL
      , SPE_GTS_RT_CDE
      , SPE_REL_TMSTMP
      , SPE_UNIT_SYSTEM
      , SPE_INV_BFR_GI
      , SPE_QI_STATUS
      , SPE_RED_IND
      , SAKES
      , SPE_LIFEX_TYPE
      , SPE_TTYPE
      , SPE_PRO_NUMBER
      , LOC_GUID
      , SPE_BILLING_IND
      , PRINTER_PROFILE
      , MSR_ACTIVE
      , PRTNR
      , STGE_LOC_CHANGE
      , TM_CTRL_KEY
      , DLV_SPLIT_INITIA
      , DLV_VERSION
      , HANDOVERLOC
      , HANDOVERDATE
      , HANDOVERTIME
      , HANDOVERTZONE
      , INCOV
      , INCO2_L
      , INCO3_L
      , BEV1_LULEINH
      , BEV1_RPFAESS
      , BEV1_RPKIST
      , BEV1_RPCONT
      , BEV1_RPSONST
      , BEV1_RPFLGNR
      , BORGR_GRP
      , FSH_TRANSACTION
      , FSH_VAS_LAST_ITEM
      , FSH_VAS_CG
      , ZZORC
      , ZZCUSTTL
      , ZZTMS
      , ZZCONSOLIDATE
      , ZZNETPRICE
      , ZZAPNTMNT
      , ZZTMSEXE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        DELIVERY_HK
      , MANDT
      , VBELN
      , GLREQUEST
      , ERNAM
      , ERZET
      , ERDAT
      , BZIRK
      , VSTEL
      , VKORG
      , LFART
      , AUTLF
      , KZAZU
      , WADAT
      , LDDAT
      , TDDAT
      , LFDAT
      , KODAT
      , ABLAD
      , INCO1
      , INCO2
      , EXPKZ
      , ROUTE
      , FAKSK
      , LIFSK
      , VBTYP
      , KNFAK
      , TPQUA
      , TPGRP
      , LPRIO
      , VSBED
      , KUNNR
      , KUNAG
      , KDGRP
      , STZKL
      , STZZU
      , BTGEW
      , NTGEW
      , GEWEI
      , VOLUM
      , VOLEH
      , ANZPK
      , BEROT
      , LFUHR
      , GRULG
      , LSTEL
      , TRAGR
      , FKARV
      , FKDAT
      , PERFK
      , ROUTA
      , STAFO
      , KALSM
      , KNUMV
      , WAERK
      , VKBUR
      , VBEAK
      , ZUKRL
      , VERUR
      , COMMN
      , STWAE
      , STCUR
      , EXNUM
      , AENAM
      , AEDAT
      , LGNUM
      , LISPL
      , VKOIV
      , VTWIV
      , SPAIV
      , FKAIV
      , PIOIV
      , FKDIV
      , KUNIV
      , KKBER
      , KNKLI
      , GRUPP
      , SBGRP
      , CTLPC
      , CMWAE
      , AMTBL
      , BOLNR
      , LIFNR
      , TRATY
      , TRAID
      , CMFRE
      , CMNGV
      , XABLN
      , BLDAT
      , WADAT_IST
      , TRSPG
      , TPSID
      , LIFEX
      , TERNR
      , KALSM_CH
      , KLIEF
      , KALSP
      , KNUMP
      , NETWR
      , AULWE
      , WERKS
      , LCNUM
      , ABSSC
      , KOUHR
      , TDUHR
      , LDUHR
      , WAUHR
      , LGTOR
      , LGBZO
      , AKWAE
      , AKKUR
      , AKPRZ
      , PROLI
      , XBLNR
      , HANDLE
      , TSEGFL
      , TSEGTP
      , TZONIS
      , TZONRC
      , CONT_DG
      , VERURSYS
      , KZWAB
      , VLSTK
      , TCODE
      , VSART
      , TRMTYP
      , SDABW
      , VBUND
      , XWOFF
      , DIRTA
      , PRVBE
      , FOLAR
      , PODAT
      , POTIM
      , VGANZ
      , IMWRK
      , SPE_LOEKZ
      , SPE_LOC_SEQ
      , SPE_ACC_APP_STS
      , SPE_SHP_INF_STS
      , SPE_RET_CANC
      , SPE_WAUHR_IST
      , SPE_WAZONE_IST
      , SPE_REV_VLSTK
      , SPE_LE_SCENARIO
      , SPE_ORIG_SYS
      , SPE_CHNG_SYS
      , SPE_GEOROUTE
      , SPE_GEOROUTEIND
      , SPE_CARRIER_IND
      , SPE_GTS_REL
      , SPE_GTS_RT_CDE
      , SPE_REL_TMSTMP
      , SPE_UNIT_SYSTEM
      , SPE_INV_BFR_GI
      , SPE_QI_STATUS
      , SPE_RED_IND
      , SAKES
      , SPE_LIFEX_TYPE
      , SPE_TTYPE
      , SPE_PRO_NUMBER
      , LOC_GUID
      , SPE_BILLING_IND
      , PRINTER_PROFILE
      , MSR_ACTIVE
      , PRTNR
      , STGE_LOC_CHANGE
      , TM_CTRL_KEY
      , DLV_SPLIT_INITIA
      , DLV_VERSION
      , HANDOVERLOC
      , HANDOVERDATE
      , HANDOVERTIME
      , HANDOVERTZONE
      , INCOV
      , INCO2_L
      , INCO3_L
      , BEV1_LULEINH
      , BEV1_RPFAESS
      , BEV1_RPKIST
      , BEV1_RPCONT
      , BEV1_RPSONST
      , BEV1_RPFLGNR
      , BORGR_GRP
      , FSH_TRANSACTION
      , FSH_VAS_LAST_ITEM
      , FSH_VAS_CG
      , ZZORC
      , ZZCUSTTL
      , ZZTMS
      , ZZCONSOLIDATE
      , ZZNETPRICE
      , ZZAPNTMNT
      , ZZTMSEXE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_b
)
---- FILTER LAYER ----

, FILTER_b as (
    SELECT *
    FROM RENAME_b
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_b
)

---- FINAL LAYER ----
SELECT
          DELIVERY_HK
        , MANDT
        , VBELN
        , GLREQUEST
        , ERNAM
        , ERZET
        , ERDAT
        , BZIRK
        , VSTEL
        , VKORG
        , LFART
        , AUTLF
        , KZAZU
        , WADAT
        , LDDAT
        , TDDAT
        , LFDAT
        , KODAT
        , ABLAD
        , INCO1
        , INCO2
        , EXPKZ
        , ROUTE
        , FAKSK
        , LIFSK
        , VBTYP
        , KNFAK
        , TPQUA
        , TPGRP
        , LPRIO
        , VSBED
        , KUNNR
        , KUNAG
        , KDGRP
        , STZKL
        , STZZU
        , BTGEW
        , NTGEW
        , GEWEI
        , VOLUM
        , VOLEH
        , ANZPK
        , BEROT
        , LFUHR
        , GRULG
        , LSTEL
        , TRAGR
        , FKARV
        , FKDAT
        , PERFK
        , ROUTA
        , STAFO
        , KALSM
        , KNUMV
        , WAERK
        , VKBUR
        , VBEAK
        , ZUKRL
        , VERUR
        , COMMN
        , STWAE
        , STCUR
        , EXNUM
        , AENAM
        , AEDAT
        , LGNUM
        , LISPL
        , VKOIV
        , VTWIV
        , SPAIV
        , FKAIV
        , PIOIV
        , FKDIV
        , KUNIV
        , KKBER
        , KNKLI
        , GRUPP
        , SBGRP
        , CTLPC
        , CMWAE
        , AMTBL
        , BOLNR
        , LIFNR
        , TRATY
        , TRAID
        , CMFRE
        , CMNGV
        , XABLN
        , BLDAT
        , WADAT_IST
        , TRSPG
        , TPSID
        , LIFEX
        , TERNR
        , KALSM_CH
        , KLIEF
        , KALSP
        , KNUMP
        , NETWR
        , AULWE
        , WERKS
        , LCNUM
        , ABSSC
        , KOUHR
        , TDUHR
        , LDUHR
        , WAUHR
        , LGTOR
        , LGBZO
        , AKWAE
        , AKKUR
        , AKPRZ
        , PROLI
        , XBLNR
        , HANDLE
        , TSEGFL
        , TSEGTP
        , TZONIS
        , TZONRC
        , CONT_DG
        , VERURSYS
        , KZWAB
        , VLSTK
        , TCODE
        , VSART
        , TRMTYP
        , SDABW
        , VBUND
        , XWOFF
        , DIRTA
        , PRVBE
        , FOLAR
        , PODAT
        , POTIM
        , VGANZ
        , IMWRK
        , SPE_LOEKZ
        , SPE_LOC_SEQ
        , SPE_ACC_APP_STS
        , SPE_SHP_INF_STS
        , SPE_RET_CANC
        , SPE_WAUHR_IST
        , SPE_WAZONE_IST
        , SPE_REV_VLSTK
        , SPE_LE_SCENARIO
        , SPE_ORIG_SYS
        , SPE_CHNG_SYS
        , SPE_GEOROUTE
        , SPE_GEOROUTEIND
        , SPE_CARRIER_IND
        , SPE_GTS_REL
        , SPE_GTS_RT_CDE
        , SPE_REL_TMSTMP
        , SPE_UNIT_SYSTEM
        , SPE_INV_BFR_GI
        , SPE_QI_STATUS
        , SPE_RED_IND
        , SAKES
        , SPE_LIFEX_TYPE
        , SPE_TTYPE
        , SPE_PRO_NUMBER
        , LOC_GUID
        , SPE_BILLING_IND
        , PRINTER_PROFILE
        , MSR_ACTIVE
        , PRTNR
        , STGE_LOC_CHANGE
        , TM_CTRL_KEY
        , DLV_SPLIT_INITIA
        , DLV_VERSION
        , HANDOVERLOC
        , HANDOVERDATE
        , HANDOVERTIME
        , HANDOVERTZONE
        , INCOV
        , INCO2_L
        , INCO3_L
        , BEV1_LULEINH
        , BEV1_RPFAESS
        , BEV1_RPKIST
        , BEV1_RPCONT
        , BEV1_RPSONST
        , BEV1_RPFLGNR
        , BORGR_GRP
        , FSH_TRANSACTION
        , FSH_VAS_LAST_ITEM
        , FSH_VAS_CG
        , ZZORC
        , ZZCUSTTL
        , ZZTMS
        , ZZCONSOLIDATE
        , ZZNETPRICE
        , ZZAPNTMNT
        , ZZTMSEXE
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
    WHERE existing.DELIVERY_HK = JOIN_RESULT.DELIVERY_HK  
   AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by DELIVERY_HK, HASHDIFF order by GLCHANGETIME)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS DELIVERY_HK,
NULL AS MANDT,
GR.VALUE::text AS VBELN,
NULL AS GLREQUEST,
NULL AS ERNAM,
NULL AS ERZET,
NULL AS ERDAT,
NULL AS BZIRK,
NULL AS VSTEL,
NULL AS VKORG,
NULL AS LFART,
NULL AS AUTLF,
NULL AS KZAZU,
NULL AS WADAT,
NULL AS LDDAT,
NULL AS TDDAT,
NULL AS LFDAT,
NULL AS KODAT,
NULL AS ABLAD,
NULL AS INCO1,
NULL AS INCO2,
NULL AS EXPKZ,
NULL AS ROUTE,
NULL AS FAKSK,
NULL AS LIFSK,
NULL AS VBTYP,
NULL AS KNFAK,
NULL AS TPQUA,
NULL AS TPGRP,
NULL AS LPRIO,
NULL AS VSBED,
NULL AS KUNNR,
NULL AS KUNAG,
NULL AS KDGRP,
NULL AS STZKL,
NULL AS STZZU,
NULL AS BTGEW,
NULL AS NTGEW,
NULL AS GEWEI,
NULL AS VOLUM,
NULL AS VOLEH,
NULL AS ANZPK,
NULL AS BEROT,
NULL AS LFUHR,
NULL AS GRULG,
NULL AS LSTEL,
NULL AS TRAGR,
NULL AS FKARV,
NULL AS FKDAT,
NULL AS PERFK,
NULL AS ROUTA,
NULL AS STAFO,
NULL AS KALSM,
NULL AS KNUMV,
NULL AS WAERK,
NULL AS VKBUR,
NULL AS VBEAK,
NULL AS ZUKRL,
NULL AS VERUR,
NULL AS COMMN,
NULL AS STWAE,
NULL AS STCUR,
NULL AS EXNUM,
NULL AS AENAM,
NULL AS AEDAT,
NULL AS LGNUM,
NULL AS LISPL,
NULL AS VKOIV,
NULL AS VTWIV,
NULL AS SPAIV,
NULL AS FKAIV,
NULL AS PIOIV,
NULL AS FKDIV,
NULL AS KUNIV,
NULL AS KKBER,
NULL AS KNKLI,
NULL AS GRUPP,
NULL AS SBGRP,
NULL AS CTLPC,
NULL AS CMWAE,
NULL AS AMTBL,
NULL AS BOLNR,
NULL AS LIFNR,
NULL AS TRATY,
NULL AS TRAID,
NULL AS CMFRE,
NULL AS CMNGV,
NULL AS XABLN,
NULL AS BLDAT,
NULL AS WADAT_IST,
NULL AS TRSPG,
NULL AS TPSID,
NULL AS LIFEX,
NULL AS TERNR,
NULL AS KALSM_CH,
NULL AS KLIEF,
NULL AS KALSP,
NULL AS KNUMP,
NULL AS NETWR,
NULL AS AULWE,
NULL AS WERKS,
NULL AS LCNUM,
NULL AS ABSSC,
NULL AS KOUHR,
NULL AS TDUHR,
NULL AS LDUHR,
NULL AS WAUHR,
NULL AS LGTOR,
NULL AS LGBZO,
NULL AS AKWAE,
NULL AS AKKUR,
NULL AS AKPRZ,
NULL AS PROLI,
NULL AS XBLNR,
NULL AS HANDLE,
NULL AS TSEGFL,
NULL AS TSEGTP,
NULL AS TZONIS,
NULL AS TZONRC,
NULL AS CONT_DG,
NULL AS VERURSYS,
NULL AS KZWAB,
NULL AS VLSTK,
NULL AS TCODE,
NULL AS VSART,
NULL AS TRMTYP,
NULL AS SDABW,
NULL AS VBUND,
NULL AS XWOFF,
NULL AS DIRTA,
NULL AS PRVBE,
NULL AS FOLAR,
NULL AS PODAT,
NULL AS POTIM,
NULL AS VGANZ,
NULL AS IMWRK,
NULL AS SPE_LOEKZ,
NULL AS SPE_LOC_SEQ,
NULL AS SPE_ACC_APP_STS,
NULL AS SPE_SHP_INF_STS,
NULL AS SPE_RET_CANC,
NULL AS SPE_WAUHR_IST,
NULL AS SPE_WAZONE_IST,
NULL AS SPE_REV_VLSTK,
NULL AS SPE_LE_SCENARIO,
NULL AS SPE_ORIG_SYS,
NULL AS SPE_CHNG_SYS,
NULL AS SPE_GEOROUTE,
NULL AS SPE_GEOROUTEIND,
NULL AS SPE_CARRIER_IND,
NULL AS SPE_GTS_REL,
NULL AS SPE_GTS_RT_CDE,
NULL AS SPE_REL_TMSTMP,
NULL AS SPE_UNIT_SYSTEM,
NULL AS SPE_INV_BFR_GI,
NULL AS SPE_QI_STATUS,
NULL AS SPE_RED_IND,
NULL AS SAKES,
NULL AS SPE_LIFEX_TYPE,
NULL AS SPE_TTYPE,
NULL AS SPE_PRO_NUMBER,
NULL AS LOC_GUID,
NULL AS SPE_BILLING_IND,
NULL AS PRINTER_PROFILE,
NULL AS MSR_ACTIVE,
NULL AS PRTNR,
NULL AS STGE_LOC_CHANGE,
NULL AS TM_CTRL_KEY,
NULL AS DLV_SPLIT_INITIA,
NULL AS DLV_VERSION,
NULL AS HANDOVERLOC,
NULL AS HANDOVERDATE,
NULL AS HANDOVERTIME,
NULL AS HANDOVERTZONE,
NULL AS INCOV,
NULL AS INCO2_L,
NULL AS INCO3_L,
NULL AS BEV1_LULEINH,
NULL AS BEV1_RPFAESS,
NULL AS BEV1_RPKIST,
NULL AS BEV1_RPCONT,
NULL AS BEV1_RPSONST,
NULL AS BEV1_RPFLGNR,
NULL AS BORGR_GRP,
NULL AS FSH_TRANSACTION,
NULL AS FSH_VAS_LAST_ITEM,
NULL AS FSH_VAS_CG,
NULL AS ZZORC,
NULL AS ZZCUSTTL,
NULL AS ZZTMS,
NULL AS ZZCONSOLIDATE,
NULL AS ZZNETPRICE,
NULL AS ZZAPNTMNT,
NULL AS ZZTMSEXE,
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