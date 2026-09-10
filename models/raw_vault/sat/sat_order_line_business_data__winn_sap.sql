---- SRC LAYER ----
WITH
SRC_OL             as ( SELECT * FROM {{ ref('v_psa_stg_business_data__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', -1, MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_OL             as ( SELECT * FROM staging.v_psa_stg_business_data__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_OL as (
    SELECT
        ORDER_LINE_HK
      , LOAD_DTS
      , MANDT
      , VBELN
      , POSNR
      , GLREQUEST
      , KONDA
      , KDGRP
      , BZIRK
      , PLTYP
      , INCO1
      , INCO2
      , KZAZU
      , PERFK
      , PERRL
      , MRNKZ
      , KURRF
      , VALTG
      , VALDT
      , ZTERM
      , ZLSCH
      , KTGRD
      , KURSK
      , PRSDT
      , FKDAT
      , FBUDA
      , GJAHR
      , POPER
      , STCUR
      , MSCHL
      , MANSP
      , FPLNR
      , WAKTION
      , ABSSC
      , LCNUM
      , J_1AFITP
      , J_1ARFZ
      , J_1AREGIO
      , J_1AGICD
      , J_1ADTYP
      , J_1ATXREL
      , ABTNR
      , EMPST
      , BSTKD
      , BSTDK
      , BSARK
      , IHREZ
      , BSTKD_E
      , BSTDK_E
      , BSARK_E
      , IHREZ_E
      , POSEX_E
      , KURSK_DAT
      , KURRF_DAT
      , KDKG1
      , KDKG2
      , KDKG3
      , KDKG4
      , KDKG5
      , WKWAE
      , WKKUR
      , AKWAE
      , AKKUR
      , AKPRZ
      , J_1AINDXP
      , J_1AIDATEP
      , BSTKD_M
      , DELCO
      , FFPRF
      , BEMOT
      , FAKTF
      , RRREL
      , ACDATV
      , VSART
      , TRATY
      , TRMTYP
      , SDABW
      , WMINR
      , FKBER
      , PODKZ
      , CAMPAIGN
      , VKONT
      , DPBP_REF_FPLNR
      , DPBP_REF_FPLTR
      , REVSP
      , REVEVTYP
      , FARR_RELTYPE
      , VTREF
      , _DATAAGING
      , J_1TPBUPL
      , INCOV
      , INCO2_L
      , INCO3_L
      , PEROP_BEG
      , PEROP_END
      , STCODE
      , FORMC1
      , FORMC2
      , STEUC
      , COMPREAS
      , MNDID
      , PAY_TYPE
      , SEPON
      , MNDVG
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_OL
)
---- RENAME LAYER ----

, RENAME_OL as (
    SELECT
        ORDER_LINE_HK
      , LOAD_DTS
      , MANDT
      , VBELN
      , POSNR
      , GLREQUEST
      , KONDA
      , KDGRP
      , BZIRK
      , PLTYP
      , INCO1
      , INCO2
      , KZAZU
      , PERFK
      , PERRL
      , MRNKZ
      , KURRF
      , VALTG
      , VALDT
      , ZTERM
      , ZLSCH
      , KTGRD
      , KURSK
      , PRSDT
      , FKDAT
      , FBUDA
      , GJAHR
      , POPER
      , STCUR
      , MSCHL
      , MANSP
      , FPLNR
      , WAKTION
      , ABSSC
      , LCNUM
      , J_1AFITP
      , J_1ARFZ
      , J_1AREGIO
      , J_1AGICD
      , J_1ADTYP
      , J_1ATXREL
      , ABTNR
      , EMPST
      , BSTKD
      , BSTDK
      , BSARK
      , IHREZ
      , BSTKD_E
      , BSTDK_E
      , BSARK_E
      , IHREZ_E
      , POSEX_E
      , KURSK_DAT
      , KURRF_DAT
      , KDKG1
      , KDKG2
      , KDKG3
      , KDKG4
      , KDKG5
      , WKWAE
      , WKKUR
      , AKWAE
      , AKKUR
      , AKPRZ
      , J_1AINDXP
      , J_1AIDATEP
      , BSTKD_M
      , DELCO
      , FFPRF
      , BEMOT
      , FAKTF
      , RRREL
      , ACDATV
      , VSART
      , TRATY
      , TRMTYP
      , SDABW
      , WMINR
      , FKBER
      , PODKZ
      , CAMPAIGN
      , VKONT
      , DPBP_REF_FPLNR
      , DPBP_REF_FPLTR
      , REVSP
      , REVEVTYP
      , FARR_RELTYPE
      , VTREF
      , _DATAAGING
      , J_1TPBUPL
      , INCOV
      , INCO2_L
      , INCO3_L
      , PEROP_BEG
      , PEROP_END
      , STCODE
      , FORMC1
      , FORMC2
      , STEUC
      , COMPREAS
      , MNDID
      , PAY_TYPE
      , SEPON
      , MNDVG
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_OL
)
---- FILTER LAYER ----

, FILTER_OL as (
    SELECT *
    FROM RENAME_OL
    WHERE POSNR != '000000'
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_OL
)

---- FINAL LAYER ----
SELECT
          ORDER_LINE_HK
        , LOAD_DTS
        , MANDT
        , VBELN
        , POSNR
        , GLREQUEST
        , KONDA
        , KDGRP
        , BZIRK
        , PLTYP
        , INCO1
        , INCO2
        , KZAZU
        , PERFK
        , PERRL
        , MRNKZ
        , KURRF
        , VALTG
        , VALDT
        , ZTERM
        , ZLSCH
        , KTGRD
        , KURSK
        , PRSDT
        , FKDAT
        , FBUDA
        , GJAHR
        , POPER
        , STCUR
        , MSCHL
        , MANSP
        , FPLNR
        , WAKTION
        , ABSSC
        , LCNUM
        , J_1AFITP
        , J_1ARFZ
        , J_1AREGIO
        , J_1AGICD
        , J_1ADTYP
        , J_1ATXREL
        , ABTNR
        , EMPST
        , BSTKD
        , BSTDK
        , BSARK
        , IHREZ
        , BSTKD_E
        , BSTDK_E
        , BSARK_E
        , IHREZ_E
        , POSEX_E
        , KURSK_DAT
        , KURRF_DAT
        , KDKG1
        , KDKG2
        , KDKG3
        , KDKG4
        , KDKG5
        , WKWAE
        , WKKUR
        , AKWAE
        , AKKUR
        , AKPRZ
        , J_1AINDXP
        , J_1AIDATEP
        , BSTKD_M
        , DELCO
        , FFPRF
        , BEMOT
        , FAKTF
        , RRREL
        , ACDATV
        , VSART
        , TRATY
        , TRMTYP
        , SDABW
        , WMINR
        , FKBER
        , PODKZ
        , CAMPAIGN
        , VKONT
        , DPBP_REF_FPLNR
        , DPBP_REF_FPLTR
        , REVSP
        , REVEVTYP
        , FARR_RELTYPE
        , VTREF
        , _DATAAGING
        , J_1TPBUPL
        , INCOV
        , INCO2_L
        , INCO3_L
        , PEROP_BEG
        , PEROP_END
        , STCODE
        , FORMC1
        , FORMC2
        , STEUC
        , COMPREAS
        , MNDID
        , PAY_TYPE
        , SEPON
        , MNDVG
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ORDER_LINE_HK = JOIN_RESULT.ORDER_LINE_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
qualify 1= row_number()over(partition by ORDER_LINE_HK, HASHDIFF order by LOAD_DTS)
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS ORDER_LINE_HK
,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
,null as MANDT
,null as VBELN
,null as POSNR
,null as GLREQUEST
,null as KONDA
,null as KDGRP
,null as BZIRK
,null as PLTYP
,null as INCO1
,null as INCO2
,null as KZAZU
,null as PERFK
,null as PERRL
,null as MRNKZ
,null as KURRF
,null as VALTG
,null as VALDT
,null as ZTERM
,null as ZLSCH
,null as KTGRD
,null as KURSK
,null as PRSDT
,null as FKDAT
,null as FBUDA
,null as GJAHR
,null as POPER
,null as STCUR
,null as MSCHL
,null as MANSP
,null as FPLNR
,null as WAKTION
,null as ABSSC
,null as LCNUM
,null as J_1AFITP
,null as J_1ARFZ
,null as J_1AREGIO
,null as J_1AGICD
,null as J_1ADTYP
,null as J_1ATXREL
,null as ABTNR
,null as EMPST
,null as BSTKD
,null as BSTDK
,null as BSARK
,null as IHREZ
,null as BSTKD_E
,null as BSTDK_E
,null as BSARK_E
,null as IHREZ_E
,null as POSEX_E
,null as KURSK_DAT
,null as KURRF_DAT
,null as KDKG1
,null as KDKG2
,null as KDKG3
,null as KDKG4
,null as KDKG5
,null as WKWAE
,null as WKKUR
,null as AKWAE
,null as AKKUR
,null as AKPRZ
,null as J_1AINDXP
,null as J_1AIDATEP
,null as BSTKD_M
,null as DELCO
,null as FFPRF
,null as BEMOT
,null as FAKTF
,null as RRREL
,null as ACDATV
,null as VSART
,null as TRATY
,null as TRMTYP
,null as SDABW
,null as WMINR
,null as FKBER
,null as PODKZ
,null as CAMPAIGN
,null as VKONT
,null as DPBP_REF_FPLNR
,null as DPBP_REF_FPLTR
,null as REVSP
,null as REVEVTYP
,null as FARR_RELTYPE
,null as VTREF
,null as _DATAAGING
,null as J_1TPBUPL
,null as INCOV
,null as INCO2_L
,null as INCO3_L
,null as PEROP_BEG
,null as PEROP_END
,null as STCODE
,null as FORMC1
,null as FORMC2
,null as STEUC
,null as COMPREAS
,null as MNDID
,null as PAY_TYPE
,null as SEPON
,null as MNDVG
,null as GLDELFLAG
,null as GLCHANGETIME
,null as GLSOURCESYSTEM
,null as PSA_LOAD_DTS
,null as PSA_RECORD_SOURCE
,null as PSA_DELETE_IND
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}