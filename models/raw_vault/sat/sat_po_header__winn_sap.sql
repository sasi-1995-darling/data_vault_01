---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ ref('v_psa_stg_po_header__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_a              as ( SELECT * FROM STAGING.v_psa_stg_po_header__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        PO_HEADER_HK
      , LOAD_DTS
      , EBELN
      , MANDT
      , GLREQUEST
      , GLSOURCESYSTEM
      , BUKRS
      , BSTYP
      , BSART
      , BSAKZ
      , LOEKZ
      , STATU
      , AEDAT
      , ERNAM
      , PINCR
      , LPONR
      , LIFNR
      , SPRAS
      , ZTERM
      , ZBD1T
      , ZBD2T
      , ZBD3T
      , ZBD1P
      , ZBD2P
      , EKORG
      , EKGRP
      , WAERS
      , WKURS
      , KUFIX
      , BEDAT
      , KDATB
      , KDATE
      , BWBDT
      , ANGDT
      , BNDDT
      , GWLDT
      , AUSNR
      , ANGNR
      , IHRAN
      , IHREZ
      , VERKF
      , TELF1
      , LLIEF
      , KUNNR
      , KONNR
      , ABGRU
      , AUTLF
      , WEAKT
      , RESWK
      , LBLIF
      , INCO1
      , INCO2
      , KTWRT
      , SUBMI
      , KNUMV
      , KALSM
      , STAFO
      , LIFRE
      , EXNUM
      , UNSEZ
      , LOGSY
      , UPINC
      , STAKO
      , FRGGR
      , FRGSX
      , FRGKE
      , FRGZU
      , FRGRL
      , LANDS
      , LPHIS
      , ADRNR
      , STCEG_L
      , STCEG
      , ABSGR
      , ADDNR
      , KORNR
      , MEMORY
      , PROCSTAT
      , RLWRT
      , REVNO
      , SCMPROC
      , REASON_CODE
      , MEMORYTYPE
      , RETTP
      , RETPC
      , DPTYP
      , DPPCT
      , DPAMT
      , DPDAT
      , MSR_ID
      , HIERARCHY_EXISTS
      , THRESHOLD_EXISTS
      , LEGAL_CONTRACT
      , DESCRIPTION
      , RELEASE_DATE
      , VSART
      , HANDOVERLOC
      , SHIPCOND
      , INCOV
      , INCO2_L
      , INCO3_L
      , FORCE_ID
      , FORCE_CNT
      , RELOC_ID
      , RELOC_SEQ_ID
      , SOURCE_LOGSYS
      , FSH_TRANSACTION
      , FSH_ITEM_GROUP
      , FSH_VAS_LAST_ITEM
      , FSH_OS_STG_CHANGE
      , ZZ3RDPO
      , ZZNO_EMAIL
      , ZZFRZ_SHPDT
      , VZSKZ
      , FSH_SNST_STATUS
      , POHF_TYPE
      , EQ_EINDT
      , EQ_WERKS
      , FIXPO
      , EKGRP_ALLOW
      , WERKS_ALLOW
      , CONTRACT_ALLOW
      , PSTYP_ALLOW
      , FIXPO_ALLOW
      , KEY_ID_ALLOW
      , AUREL_ALLOW
      , DELPER_ALLOW
      , EINDT_ALLOW
      , LTSNR_ALLOW
      , OTB_LEVEL
      , OTB_COND_TYPE
      , KEY_ID
      , OTB_VALUE
      , OTB_CURR
      , OTB_RES_VALUE
      , OTB_SPEC_VALUE
      , SPR_RSN_PROFILE
      , BUDG_TYPE
      , OTB_STATUS
      , OTB_REASON
      , CHECK_TYPE
      , CON_OTB_REQ
      , CON_PREBOOK_LEV
      , CON_DISTR_LEV
      , ZZACKIND_SENT
      , ZZACCIND_SENT
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        PO_HEADER_HK
      , LOAD_DTS
      , EBELN
      , MANDT
      , GLREQUEST
      , GLSOURCESYSTEM
      , BUKRS
      , BSTYP
      , BSART
      , BSAKZ
      , LOEKZ
      , STATU
      , AEDAT
      , ERNAM
      , PINCR
      , LPONR
      , LIFNR
      , SPRAS
      , ZTERM
      , ZBD1T
      , ZBD2T
      , ZBD3T
      , ZBD1P
      , ZBD2P
      , EKORG
      , EKGRP
      , WAERS
      , WKURS
      , KUFIX
      , BEDAT
      , KDATB
      , KDATE
      , BWBDT
      , ANGDT
      , BNDDT
      , GWLDT
      , AUSNR
      , ANGNR
      , IHRAN
      , IHREZ
      , VERKF
      , TELF1
      , LLIEF
      , KUNNR
      , KONNR
      , ABGRU
      , AUTLF
      , WEAKT
      , RESWK
      , LBLIF
      , INCO1
      , INCO2
      , KTWRT
      , SUBMI
      , KNUMV
      , KALSM
      , STAFO
      , LIFRE
      , EXNUM
      , UNSEZ
      , LOGSY
      , UPINC
      , STAKO
      , FRGGR
      , FRGSX
      , FRGKE
      , FRGZU
      , FRGRL
      , LANDS
      , LPHIS
      , ADRNR
      , STCEG_L
      , STCEG
      , ABSGR
      , ADDNR
      , KORNR
      , MEMORY
      , PROCSTAT
      , RLWRT
      , REVNO
      , SCMPROC
      , REASON_CODE
      , MEMORYTYPE
      , RETTP
      , RETPC
      , DPTYP
      , DPPCT
      , DPAMT
      , DPDAT
      , MSR_ID
      , HIERARCHY_EXISTS
      , THRESHOLD_EXISTS
      , LEGAL_CONTRACT
      , DESCRIPTION
      , RELEASE_DATE
      , VSART
      , HANDOVERLOC
      , SHIPCOND
      , INCOV
      , INCO2_L
      , INCO3_L
      , FORCE_ID
      , FORCE_CNT
      , RELOC_ID
      , RELOC_SEQ_ID
      , SOURCE_LOGSYS
      , FSH_TRANSACTION
      , FSH_ITEM_GROUP
      , FSH_VAS_LAST_ITEM
      , FSH_OS_STG_CHANGE
      , ZZ3RDPO
      , ZZNO_EMAIL
      , ZZFRZ_SHPDT
      , VZSKZ
      , FSH_SNST_STATUS
      , POHF_TYPE
      , EQ_EINDT
      , EQ_WERKS
      , FIXPO
      , EKGRP_ALLOW
      , WERKS_ALLOW
      , CONTRACT_ALLOW
      , PSTYP_ALLOW
      , FIXPO_ALLOW
      , KEY_ID_ALLOW
      , AUREL_ALLOW
      , DELPER_ALLOW
      , EINDT_ALLOW
      , LTSNR_ALLOW
      , OTB_LEVEL
      , OTB_COND_TYPE
      , KEY_ID
      , OTB_VALUE
      , OTB_CURR
      , OTB_RES_VALUE
      , OTB_SPEC_VALUE
      , SPR_RSN_PROFILE
      , BUDG_TYPE
      , OTB_STATUS
      , OTB_REASON
      , CHECK_TYPE
      , CON_OTB_REQ
      , CON_PREBOOK_LEV
      , CON_DISTR_LEV
      , ZZACKIND_SENT
      , ZZACCIND_SENT
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
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
          PO_HEADER_HK
        , LOAD_DTS
        , EBELN
        , MANDT
        , GLREQUEST
        , GLSOURCESYSTEM
        , BUKRS
        , BSTYP
        , BSART
        , BSAKZ
        , LOEKZ
        , STATU
        , AEDAT
        , ERNAM
        , PINCR
        , LPONR
        , LIFNR
        , SPRAS
        , ZTERM
        , ZBD1T
        , ZBD2T
        , ZBD3T
        , ZBD1P
        , ZBD2P
        , EKORG
        , EKGRP
        , WAERS
        , WKURS
        , KUFIX
        , BEDAT
        , KDATB
        , KDATE
        , BWBDT
        , ANGDT
        , BNDDT
        , GWLDT
        , AUSNR
        , ANGNR
        , IHRAN
        , IHREZ
        , VERKF
        , TELF1
        , LLIEF
        , KUNNR
        , KONNR
        , ABGRU
        , AUTLF
        , WEAKT
        , RESWK
        , LBLIF
        , INCO1
        , INCO2
        , KTWRT
        , SUBMI
        , KNUMV
        , KALSM
        , STAFO
        , LIFRE
        , EXNUM
        , UNSEZ
        , LOGSY
        , UPINC
        , STAKO
        , FRGGR
        , FRGSX
        , FRGKE
        , FRGZU
        , FRGRL
        , LANDS
        , LPHIS
        , ADRNR
        , STCEG_L
        , STCEG
        , ABSGR
        , ADDNR
        , KORNR
        , MEMORY
        , PROCSTAT
        , RLWRT
        , REVNO
        , SCMPROC
        , REASON_CODE
        , MEMORYTYPE
        , RETTP
        , RETPC
        , DPTYP
        , DPPCT
        , DPAMT
        , DPDAT
        , MSR_ID
        , HIERARCHY_EXISTS
        , THRESHOLD_EXISTS
        , LEGAL_CONTRACT
        , DESCRIPTION
        , RELEASE_DATE
        , VSART
        , HANDOVERLOC
        , SHIPCOND
        , INCOV
        , INCO2_L
        , INCO3_L
        , FORCE_ID
        , FORCE_CNT
        , RELOC_ID
        , RELOC_SEQ_ID
        , SOURCE_LOGSYS
        , FSH_TRANSACTION
        , FSH_ITEM_GROUP
        , FSH_VAS_LAST_ITEM
        , FSH_OS_STG_CHANGE
        , ZZ3RDPO
        , ZZNO_EMAIL
        , ZZFRZ_SHPDT
        , VZSKZ
        , FSH_SNST_STATUS
        , POHF_TYPE
        , EQ_EINDT
        , EQ_WERKS
        , FIXPO
        , EKGRP_ALLOW
        , WERKS_ALLOW
        , CONTRACT_ALLOW
        , PSTYP_ALLOW
        , FIXPO_ALLOW
        , KEY_ID_ALLOW
        , AUREL_ALLOW
        , DELPER_ALLOW
        , EINDT_ALLOW
        , LTSNR_ALLOW
        , OTB_LEVEL
        , OTB_COND_TYPE
        , KEY_ID
        , OTB_VALUE
        , OTB_CURR
        , OTB_RES_VALUE
        , OTB_SPEC_VALUE
        , SPR_RSN_PROFILE
        , BUDG_TYPE
        , OTB_STATUS
        , OTB_REASON
        , CHECK_TYPE
        , CON_OTB_REQ
        , CON_PREBOOK_LEV
        , CON_DISTR_LEV
        , ZZACKIND_SENT
        , ZZACCIND_SENT
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PO_HEADER_HK = JOIN_RESULT.PO_HEADER_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1= row_number()over(partition by PO_HEADER_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT
         MD5_BINARY(GR.VALUE) AS PO_HEADER_HK
        , CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
        , GR.VALUE AS EBELN
        , '' AS MANDT
        , NULL AS GLREQUEST
        , NULL AS GLSOURCESYSTEM
        , NULL AS BUKRS
        , NULL AS BSTYP
        , NULL AS BSART
        , NULL AS BSAKZ
        , NULL AS LOEKZ
        , NULL AS STATU
        , NULL AS AEDAT
        , NULL AS ERNAM
        , NULL AS PINCR
        , NULL AS LPONR
        , NULL AS LIFNR
        , NULL AS SPRAS
        , NULL AS ZTERM
        , NULL AS ZBD1T
        , NULL AS ZBD2T
        , NULL AS ZBD3T
        , NULL AS ZBD1P
        , NULL AS ZBD2P
        , NULL AS EKORG
        , NULL AS EKGRP
        , NULL AS WAERS
        , NULL AS WKURS
        , NULL AS KUFIX
        , NULL AS BEDAT
        , NULL AS KDATB
        , NULL AS KDATE
        , NULL AS BWBDT
        , NULL AS ANGDT
        , NULL AS BNDDT
        , NULL AS GWLDT
        , NULL AS AUSNR
        , NULL AS ANGNR
        , NULL AS IHRAN
        , NULL AS IHREZ
        , NULL AS VERKF
        , NULL AS TELF1
        , NULL AS LLIEF
        , NULL AS KUNNR
        , NULL AS KONNR
        , NULL AS ABGRU
        , NULL AS AUTLF
        , NULL AS WEAKT
        , NULL AS RESWK
        , NULL AS LBLIF
        , NULL AS INCO1
        , NULL AS INCO2
        , NULL AS KTWRT
        , NULL AS SUBMI
        , NULL AS KNUMV
        , NULL AS KALSM
        , NULL AS STAFO
        , NULL AS LIFRE
        , NULL AS EXNUM
        , NULL AS UNSEZ
        , NULL AS LOGSY
        , NULL AS UPINC
        , NULL AS STAKO
        , NULL AS FRGGR
        , NULL AS FRGSX
        , NULL AS FRGKE
        , NULL AS FRGZU
        , NULL AS FRGRL
        , NULL AS LANDS
        , NULL AS LPHIS
        , NULL AS ADRNR
        , NULL AS STCEG_L
        , NULL AS STCEG
        , NULL AS ABSGR
        , NULL AS ADDNR
        , NULL AS KORNR
        , NULL AS MEMORY
        , NULL AS PROCSTAT
        , NULL AS RLWRT
        , NULL AS REVNO
        , NULL AS SCMPROC
        , NULL AS REASON_CODE
        , NULL AS MEMORYTYPE
        , NULL AS RETTP
        , NULL AS RETPC
        , NULL AS DPTYP
        , NULL AS DPPCT
        , NULL AS DPAMT
        , NULL AS DPDAT
        , NULL AS MSR_ID
        , NULL AS HIERARCHY_EXISTS
        , NULL AS THRESHOLD_EXISTS
        , NULL AS LEGAL_CONTRACT
        , NULL AS DESCRIPTION
        , NULL AS RELEASE_DATE
        , NULL AS VSART
        , NULL AS HANDOVERLOC
        , NULL AS SHIPCOND
        , NULL AS INCOV
        , NULL AS INCO2_L
        , NULL AS INCO3_L
        , NULL AS FORCE_ID
        , NULL AS FORCE_CNT
        , NULL AS RELOC_ID
        , NULL AS RELOC_SEQ_ID
        , NULL AS SOURCE_LOGSYS
        , NULL AS FSH_TRANSACTION
        , NULL AS FSH_ITEM_GROUP
        , NULL AS FSH_VAS_LAST_ITEM
        , NULL AS FSH_OS_STG_CHANGE
        , NULL AS ZZ3RDPO
        , NULL AS ZZNO_EMAIL
        , NULL AS ZZFRZ_SHPDT
        , NULL AS VZSKZ
        , NULL AS FSH_SNST_STATUS
        , NULL AS POHF_TYPE
        , NULL AS EQ_EINDT
        , NULL AS EQ_WERKS
        , NULL AS FIXPO
        , NULL AS EKGRP_ALLOW
        , NULL AS WERKS_ALLOW
        , NULL AS CONTRACT_ALLOW
        , NULL AS PSTYP_ALLOW
        , NULL AS FIXPO_ALLOW
        , NULL AS KEY_ID_ALLOW
        , NULL AS AUREL_ALLOW
        , NULL AS DELPER_ALLOW
        , NULL AS EINDT_ALLOW
        , NULL AS LTSNR_ALLOW
        , NULL AS OTB_LEVEL
        , NULL AS OTB_COND_TYPE
        , NULL AS KEY_ID
        , NULL AS OTB_VALUE
        , NULL AS OTB_CURR
        , NULL AS OTB_RES_VALUE
        , NULL AS OTB_SPEC_VALUE
        , NULL AS SPR_RSN_PROFILE
        , NULL AS BUDG_TYPE
        , NULL AS OTB_STATUS
        , NULL AS OTB_REASON
        , NULL AS CHECK_TYPE
        , NULL AS CON_OTB_REQ
        , NULL AS CON_PREBOOK_LEV
        , NULL AS CON_DISTR_LEV
        , NULL AS ZZACKIND_SENT
        , NULL AS ZZACCIND_SENT
        , NULL AS GLDELFLAG
        , NULL AS GLCHANGETIME
        , '1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS
        , 'N' AS PSA_DELETE_IND
        , 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
        , ''::BINARY as HASH_DIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

    {% endif %}