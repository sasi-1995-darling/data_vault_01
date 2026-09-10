---- SRC LAYER ----
WITH
SRC_eine           as ( SELECT * FROM {{ ref('v_psa_stg_purchasing_record_org__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_eine           as ( SELECT * FROM staging.v_psa_stg_purchase_record_org__winn )
*/
---- LOGIC LAYER ----

, LOGIC_eine as (
    SELECT
        PURCHASING_RECORD_DETAILS_HK
      , LOAD_DTS
      , MANDT
      , INFNR
      , EKORG
      , ESOKZ
      , WERKS
      , GLREQUEST
      , GLSOURCESYSTEM
      , LOEKZ
      , ERDAT
      , ERNAM
      , EKGRP
      , WAERS
      , BONUS
      , MGBON
      , MINBM
      , NORBM
      , APLFZ
      , UEBTO
      , UEBTK
      , UNTTO
      , ANGNR
      , ANGDT
      , ANFNR
      , ANFPS
      , ABSKZ
      , AMODV
      , AMODB
      , AMOBM
      , AMOBW
      , AMOAM
      , AMOAW
      , AMORS
      , BSTYP
      , EBELN
      , EBELP
      , DATLB
      , NETPR
      , PEINH
      , BPRME
      , PRDAT
      , BPUMZ
      , BPUMN
      , MTXNO
      , WEBRE
      , EFFPR
      , EKKOL
      , SKTOF
      , KZABS
      , MWSKZ
      , BWTAR
      , EBONU
      , EVERS
      , EXPRF
      , BSTAE
      , MEPRF
      , INCO1
      , INCO2
      , XERSN
      , EBON2
      , EBON3
      , EBONF
      , MHDRZ
      , VERID
      , BSTMA
      , RDPRF
      , MEGRU
      , J_1BNBM
      , SPE_CRE_REF_DOC
      , IPRKZ
      , CO_ORDER
      , VENDOR_RMA_REQ
      , DIFF_INVOICE
      , INCOV
      , INCO2_L
      , INCO3_L
      , FSH_DCI_CORR
      , FSH_RLT
      , FSH_MLT
      , FSH_PLT
      , FSH_TLT
      , MRPIND
      , SGT_SSREL
      , TRANSPORT_CHAIN
      , STAGING_TIME
      , ZZMPLFZ
      , ZZTPLFZ
      , ZZOVERRIDE
      , ZZ3TPLFZ
      , ZZ3OVERRIDE
      , ZZEKGRP
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_eine
)
---- RENAME LAYER ----

, RENAME_eine as (
    SELECT
        PURCHASING_RECORD_DETAILS_HK
      , LOAD_DTS
      , MANDT
      , INFNR
      , EKORG
      , ESOKZ
      , WERKS
      , GLREQUEST
      , GLSOURCESYSTEM
      , LOEKZ
      , ERDAT
      , ERNAM
      , EKGRP
      , WAERS
      , BONUS
      , MGBON
      , MINBM
      , NORBM
      , APLFZ
      , UEBTO
      , UEBTK
      , UNTTO
      , ANGNR
      , ANGDT
      , ANFNR
      , ANFPS
      , ABSKZ
      , AMODV
      , AMODB
      , AMOBM
      , AMOBW
      , AMOAM
      , AMOAW
      , AMORS
      , BSTYP
      , EBELN
      , EBELP
      , DATLB
      , NETPR
      , PEINH
      , BPRME
      , PRDAT
      , BPUMZ
      , BPUMN
      , MTXNO
      , WEBRE
      , EFFPR
      , EKKOL
      , SKTOF
      , KZABS
      , MWSKZ
      , BWTAR
      , EBONU
      , EVERS
      , EXPRF
      , BSTAE
      , MEPRF
      , INCO1
      , INCO2
      , XERSN
      , EBON2
      , EBON3
      , EBONF
      , MHDRZ
      , VERID
      , BSTMA
      , RDPRF
      , MEGRU
      , J_1BNBM
      , SPE_CRE_REF_DOC
      , IPRKZ
      , CO_ORDER
      , VENDOR_RMA_REQ
      , DIFF_INVOICE
      , INCOV
      , INCO2_L
      , INCO3_L
      , FSH_DCI_CORR
      , FSH_RLT
      , FSH_MLT
      , FSH_PLT
      , FSH_TLT
      , MRPIND
      , SGT_SSREL
      , TRANSPORT_CHAIN
      , STAGING_TIME
      , ZZMPLFZ
      , ZZTPLFZ
      , ZZOVERRIDE
      , ZZ3TPLFZ
      , ZZ3OVERRIDE
      , ZZEKGRP
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_eine
)
---- FILTER LAYER ----

, FILTER_eine as (
    SELECT *
    FROM RENAME_eine
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_eine
)

---- FINAL LAYER ----
SELECT
          PURCHASING_RECORD_DETAILS_HK
        , LOAD_DTS
        , MANDT
        , INFNR
        , EKORG
        , ESOKZ
        , WERKS
        , GLREQUEST
        , GLSOURCESYSTEM
        , LOEKZ
        , ERDAT
        , ERNAM
        , EKGRP
        , WAERS
        , BONUS
        , MGBON
        , MINBM
        , NORBM
        , APLFZ
        , UEBTO
        , UEBTK
        , UNTTO
        , ANGNR
        , ANGDT
        , ANFNR
        , ANFPS
        , ABSKZ
        , AMODV
        , AMODB
        , AMOBM
        , AMOBW
        , AMOAM
        , AMOAW
        , AMORS
        , BSTYP
        , EBELN
        , EBELP
        , DATLB
        , NETPR
        , PEINH
        , BPRME
        , PRDAT
        , BPUMZ
        , BPUMN
        , MTXNO
        , WEBRE
        , EFFPR
        , EKKOL
        , SKTOF
        , KZABS
        , MWSKZ
        , BWTAR
        , EBONU
        , EVERS
        , EXPRF
        , BSTAE
        , MEPRF
        , INCO1
        , INCO2
        , XERSN
        , EBON2
        , EBON3
        , EBONF
        , MHDRZ
        , VERID
        , BSTMA
        , RDPRF
        , MEGRU
        , J_1BNBM
        , SPE_CRE_REF_DOC
        , IPRKZ
        , CO_ORDER
        , VENDOR_RMA_REQ
        , DIFF_INVOICE
        , INCOV
        , INCO2_L
        , INCO3_L
        , FSH_DCI_CORR
        , FSH_RLT
        , FSH_MLT
        , FSH_PLT
        , FSH_TLT
        , MRPIND
        , SGT_SSREL
        , TRANSPORT_CHAIN
        , STAGING_TIME
        , ZZMPLFZ
        , ZZTPLFZ
        , ZZOVERRIDE
        , ZZ3TPLFZ
        , ZZ3OVERRIDE
        , ZZEKGRP
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
    WHERE existing.PURCHASING_RECORD_DETAILS_HK = JOIN_RESULT.PURCHASING_RECORD_DETAILS_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 

{% if not is_incremental() %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1= row_number()over(partition by PURCHASING_RECORD_DETAILS_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT
MD5_BINARY(GR.VALUE) PURCHASING_RECORD_DETAILS_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, NULL AS MANDT
, GR.VALUE AS INFNR
, GR.VALUE AS EKORG
, NULL AS ESOKZ
, GR.VALUE AS WERKS
, NULL AS GLREQUEST
, NULL AS GLSOURCESYSTEM
, NULL AS LOEKZ
, NULL AS ERDAT
, NULL AS ERNAM
, NULL AS EKGRP
, NULL AS WAERS
, NULL AS BONUS
, NULL AS MGBON
, NULL AS MINBM
, NULL AS NORBM
, NULL AS APLFZ
, NULL AS UEBTO
, NULL AS UEBTK
, NULL AS UNTTO
, NULL AS ANGNR
, NULL AS ANGDT
, NULL AS ANFNR
, NULL AS ANFPS
, NULL AS ABSKZ
, NULL AS AMODV
, NULL AS AMODB
, NULL AS AMOBM
, NULL AS AMOBW
, NULL AS AMOAM
, NULL AS AMOAW
, NULL AS AMORS
, NULL AS BSTYP
, NULL AS EBELN
, NULL AS EBELP
, NULL AS DATLB
, NULL AS NETPR
, NULL AS PEINH
, NULL AS BPRME
, NULL AS PRDAT
, NULL AS BPUMZ
, NULL AS BPUMN
, NULL AS MTXNO
, NULL AS WEBRE
, NULL AS EFFPR
, NULL AS EKKOL
, NULL AS SKTOF
, NULL AS KZABS
, NULL AS MWSKZ
, NULL AS BWTAR
, NULL AS EBONU
, NULL AS EVERS
, NULL AS EXPRF
, NULL AS BSTAE
, NULL AS MEPRF
, NULL AS INCO1
, NULL AS INCO2
, NULL AS XERSN
, NULL AS EBON2
, NULL AS EBON3
, NULL AS EBONF
, NULL AS MHDRZ
, NULL AS VERID
, NULL AS BSTMA
, NULL AS RDPRF
, NULL AS MEGRU
, NULL AS J_1BNBM
, NULL AS SPE_CRE_REF_DOC
, NULL AS IPRKZ
, NULL AS CO_ORDER
, NULL AS VENDOR_RMA_REQ
, NULL AS DIFF_INVOICE
, NULL AS INCOV
, NULL AS INCO2_L
, NULL AS INCO3_L
, NULL AS FSH_DCI_CORR
, NULL AS FSH_RLT
, NULL AS FSH_MLT
, NULL AS FSH_PLT
, NULL AS FSH_TLT
, NULL AS MRPIND
, NULL AS SGT_SSREL
, NULL AS TRANSPORT_CHAIN
, NULL AS STAGING_TIME
, NULL AS ZZMPLFZ
, NULL AS ZZTPLFZ
, NULL AS ZZOVERRIDE
, NULL AS ZZ3TPLFZ
, NULL AS ZZ3OVERRIDE
, NULL AS ZZEKGRP
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