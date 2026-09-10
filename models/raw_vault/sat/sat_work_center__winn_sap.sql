---- SRC LAYER ----
WITH
SRC_s              as ( SELECT * FROM {{ ref('v_psa_stg_work_center_capacity__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_s              as ( SELECT * FROM STAGING.V_PSA_STG_WORK_CENTER_CAPACITY__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        WORK_CENTER_HK
      , MANDT
      , OBJTY
      , OBJID
      , GLREQUEST
      , BEGDA
      , ENDDA
      , AEDAT_GRND
      , AENAM_GRND
      , AEDAT_VORA
      , AENAM_VORA
      , AEDAT_TERM
      , AENAM_TERM
      , AEDAT_TECH
      , AENAM_TECH
      , ARBPL
      , WERKS
      , VERWE
      , LVORM
      , PAR01
      , PAR02
      , PAR03
      , PAR04
      , PAR05
      , PAR06
      , PARU1
      , PARU2
      , PARU3
      , PARU4
      , PARU5
      , PARU6
      , PARV1
      , PARV2
      , PARV3
      , PARV4
      , PARV5
      , PARV6
      , PLANV
      , STAND
      , VERAN
      , VGWTS
      , VGM01
      , VGM02
      , VGM03
      , VGM04
      , VGM05
      , VGM06
      , XDEFA
      , XKOST
      , XSPRR
      , XTERM
      , ZGR01
      , ZGR02
      , ZGR03
      , ZGR04
      , ZGR05
      , ZGR06
      , KTSCH
      , LOANZ
      , LOART
      , LOGRP
      , QUALF
      , RASCH
      , STEUS
      , VGE01
      , VGE02
      , VGE03
      , VGE04
      , VGE05
      , VGE06
      , KTSCH_REF
      , LOART_REF
      , LOANZ_REF
      , LOGRP_REF
      , QUALF_REF
      , RASCH_REF
      , STEUS_REF
      , FORT1
      , FORT2
      , FORT3
      , KAPID
      , ORTGR
      , ZEIWN
      , ZWNOR
      , ZEIWM
      , ZWMIN
      , FORMR
      , MATYP
      , CPLGR
      , SORTB
      , MTRVP
      , MTMVP
      , MTPVP
      , RSANZ
      , PDEST
      , HROID
      , FORTN
      , ZGR01_REF
      , ZGR02_REF
      , ZGR03_REF
      , ZGR04_REF
      , ZGR05_REF
      , ZGR06_REF
      , STEUS_C
      , STEUS_I
      , STEUS_N
      , STEUS_Q
      , RUZUS
      , RSANZ_REF
      , HR
      , PRVBE
      , SUBSYS
      , BDEGR
      , RGEKZ
      , HRTYP
      , SLWID
      , LIFNR
      , SLWID_REF
      , LIFNR_REF
      , VGARB
      , VGDIM
      , HRPLVAR
      , VGDAU
      , STOBJ
      , RESGR
      , LGORT_RES
      , MIXMAT
      , ISTBED_KZ
      , PPSKZ
      , SRTYPE
      , SNTYPE
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM SRC_s
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        WORK_CENTER_HK
      , MANDT
      , OBJTY
      , OBJID
      , GLREQUEST
      , BEGDA
      , ENDDA
      , AEDAT_GRND
      , AENAM_GRND
      , AEDAT_VORA
      , AENAM_VORA
      , AEDAT_TERM
      , AENAM_TERM
      , AEDAT_TECH
      , AENAM_TECH
      , ARBPL
      , WERKS
      , VERWE
      , LVORM
      , PAR01
      , PAR02
      , PAR03
      , PAR04
      , PAR05
      , PAR06
      , PARU1
      , PARU2
      , PARU3
      , PARU4
      , PARU5
      , PARU6
      , PARV1
      , PARV2
      , PARV3
      , PARV4
      , PARV5
      , PARV6
      , PLANV
      , STAND
      , VERAN
      , VGWTS
      , VGM01
      , VGM02
      , VGM03
      , VGM04
      , VGM05
      , VGM06
      , XDEFA
      , XKOST
      , XSPRR
      , XTERM
      , ZGR01
      , ZGR02
      , ZGR03
      , ZGR04
      , ZGR05
      , ZGR06
      , KTSCH
      , LOANZ
      , LOART
      , LOGRP
      , QUALF
      , RASCH
      , STEUS
      , VGE01
      , VGE02
      , VGE03
      , VGE04
      , VGE05
      , VGE06
      , KTSCH_REF
      , LOART_REF
      , LOANZ_REF
      , LOGRP_REF
      , QUALF_REF
      , RASCH_REF
      , STEUS_REF
      , FORT1
      , FORT2
      , FORT3
      , KAPID
      , ORTGR
      , ZEIWN
      , ZWNOR
      , ZEIWM
      , ZWMIN
      , FORMR
      , MATYP
      , CPLGR
      , SORTB
      , MTRVP
      , MTMVP
      , MTPVP
      , RSANZ
      , PDEST
      , HROID
      , FORTN
      , ZGR01_REF
      , ZGR02_REF
      , ZGR03_REF
      , ZGR04_REF
      , ZGR05_REF
      , ZGR06_REF
      , STEUS_C
      , STEUS_I
      , STEUS_N
      , STEUS_Q
      , RUZUS
      , RSANZ_REF
      , HR
      , PRVBE
      , SUBSYS
      , BDEGR
      , RGEKZ
      , HRTYP
      , SLWID
      , LIFNR
      , SLWID_REF
      , LIFNR_REF
      , VGARB
      , VGDIM
      , HRPLVAR
      , VGDAU
      , STOBJ
      , RESGR
      , LGORT_RES
      , MIXMAT
      , ISTBED_KZ
      , PPSKZ
      , SRTYPE
      , SNTYPE
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM LOGIC_s
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
)

---- FINAL LAYER ----
SELECT
          WORK_CENTER_HK
        , MANDT
        , OBJTY
        , OBJID
        , GLREQUEST
        , BEGDA
        , ENDDA
        , AEDAT_GRND
        , AENAM_GRND
        , AEDAT_VORA
        , AENAM_VORA
        , AEDAT_TERM
        , AENAM_TERM
        , AEDAT_TECH
        , AENAM_TECH
        , ARBPL
        , WERKS
        , VERWE
        , LVORM
        , PAR01
        , PAR02
        , PAR03
        , PAR04
        , PAR05
        , PAR06
        , PARU1
        , PARU2
        , PARU3
        , PARU4
        , PARU5
        , PARU6
        , PARV1
        , PARV2
        , PARV3
        , PARV4
        , PARV5
        , PARV6
        , PLANV
        , STAND
        , VERAN
        , VGWTS
        , VGM01
        , VGM02
        , VGM03
        , VGM04
        , VGM05
        , VGM06
        , XDEFA
        , XKOST
        , XSPRR
        , XTERM
        , ZGR01
        , ZGR02
        , ZGR03
        , ZGR04
        , ZGR05
        , ZGR06
        , KTSCH
        , LOANZ
        , LOART
        , LOGRP
        , QUALF
        , RASCH
        , STEUS
        , VGE01
        , VGE02
        , VGE03
        , VGE04
        , VGE05
        , VGE06
        , KTSCH_REF
        , LOART_REF
        , LOANZ_REF
        , LOGRP_REF
        , QUALF_REF
        , RASCH_REF
        , STEUS_REF
        , FORT1
        , FORT2
        , FORT3
        , KAPID
        , ORTGR
        , ZEIWN
        , ZWNOR
        , ZEIWM
        , ZWMIN
        , FORMR
        , MATYP
        , CPLGR
        , SORTB
        , MTRVP
        , MTMVP
        , MTPVP
        , RSANZ
        , PDEST
        , HROID
        , FORTN
        , ZGR01_REF
        , ZGR02_REF
        , ZGR03_REF
        , ZGR04_REF
        , ZGR05_REF
        , ZGR06_REF
        , STEUS_C
        , STEUS_I
        , STEUS_N
        , STEUS_Q
        , RUZUS
        , RSANZ_REF
        , HR
        , PRVBE
        , SUBSYS
        , BDEGR
        , RGEKZ
        , HRTYP
        , SLWID
        , LIFNR
        , SLWID_REF
        , LIFNR_REF
        , VGARB
        , VGDIM
        , HRPLVAR
        , VGDAU
        , STOBJ
        , RESGR
        , LGORT_RES
        , MIXMAT
        , ISTBED_KZ
        , PPSKZ
        , SRTYPE
        , SNTYPE
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
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
    WHERE existing.WORK_CENTER_HK = JOIN_RESULT.WORK_CENTER_HK  AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by WORK_CENTER_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS WORK_CENTER_HK,
NULL AS MANDT,
NULL AS OBJTY,
NULL AS OBJID,
NULL AS GLREQUEST,
NULL AS BEGDA,
NULL AS ENDDA,
NULL AS AEDAT_GRND,
NULL AS AENAM_GRND,
NULL AS AEDAT_VORA,
NULL AS AENAM_VORA,
NULL AS AEDAT_TERM,
NULL AS AENAM_TERM,
NULL AS AEDAT_TECH,
NULL AS AENAM_TECH,
GR.VALUE::text AS ARBPL,
GR.VALUE::text AS WERKS,
NULL AS VERWE,
NULL AS LVORM,
NULL AS PAR01,
NULL AS PAR02,
NULL AS PAR03,
NULL AS PAR04,
NULL AS PAR05,
NULL AS PAR06,
NULL AS PARU1,
NULL AS PARU2,
NULL AS PARU3,
NULL AS PARU4,
NULL AS PARU5,
NULL AS PARU6,
NULL AS PARV1,
NULL AS PARV2,
NULL AS PARV3,
NULL AS PARV4,
NULL AS PARV5,
NULL AS PARV6,
NULL AS PLANV,
GR.VALUE::text AS STAND,
NULL AS VERAN,
NULL AS VGWTS,
NULL AS VGM01,
NULL AS VGM02,
NULL AS VGM03,
NULL AS VGM04,
NULL AS VGM05,
NULL AS VGM06,
NULL AS XDEFA,
NULL AS XKOST,
NULL AS XSPRR,
NULL AS XTERM,
NULL AS ZGR01,
NULL AS ZGR02,
NULL AS ZGR03,
NULL AS ZGR04,
NULL AS ZGR05,
NULL AS ZGR06,
NULL AS KTSCH,
NULL AS LOANZ,
NULL AS LOART,
NULL AS LOGRP,
NULL AS QUALF,
NULL AS RASCH,
NULL AS STEUS,
NULL AS VGE01,
NULL AS VGE02,
NULL AS VGE03,
NULL AS VGE04,
NULL AS VGE05,
NULL AS VGE06,
NULL AS KTSCH_REF,
NULL AS LOART_REF,
NULL AS LOANZ_REF,
NULL AS LOGRP_REF,
NULL AS QUALF_REF,
NULL AS RASCH_REF,
NULL AS STEUS_REF,
NULL AS FORT1,
NULL AS FORT2,
NULL AS FORT3,
NULL AS KAPID,
NULL AS ORTGR,
GR.VALUE::text AS ZEIWN,
NULL AS ZWNOR,
NULL AS ZEIWM,
NULL AS ZWMIN,
NULL AS FORMR,
NULL AS MATYP,
NULL AS CPLGR,
NULL AS SORTB,
NULL AS MTRVP,
NULL AS MTMVP,
NULL AS MTPVP,
NULL AS RSANZ,
NULL AS PDEST,
NULL AS HROID,
NULL AS FORTN,
NULL AS ZGR01_REF,
NULL AS ZGR02_REF,
NULL AS ZGR03_REF,
NULL AS ZGR04_REF,
NULL AS ZGR05_REF,
NULL AS ZGR06_REF,
NULL AS STEUS_C,
NULL AS STEUS_I,
NULL AS STEUS_N,
NULL AS STEUS_Q,
NULL AS RUZUS,
NULL AS RSANZ_REF,
NULL AS HR,
NULL AS PRVBE,
NULL AS SUBSYS,
NULL AS BDEGR,
NULL AS RGEKZ,
NULL AS HRTYP,
NULL AS SLWID,
NULL AS LIFNR,
NULL AS SLWID_REF,
NULL AS LIFNR_REF,
NULL AS VGARB,
NULL AS VGDIM,
NULL AS HRPLVAR,
NULL AS VGDAU,
NULL AS STOBJ,
NULL AS RESGR,
NULL AS LGORT_RES,
NULL AS MIXMAT,
NULL AS ISTBED_KZ,
NULL AS PPSKZ,
NULL AS SRTYPE,
NULL AS SNTYPE,
NULL AS GLDELFLAG,
NULL AS GLSOURCESYSTEM,
NULL AS GLCHANGETIME,
NULL AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
NULL AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
''::BINARY AS HASHDIFF,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}