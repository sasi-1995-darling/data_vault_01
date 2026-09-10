---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT * FROM {{ ref('v_psa_stg_sales_invoice__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.v_psa_stg_sales_invoice__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        SALES_INVOICE_HK
      , MANDT
      , VBELN
      , GLREQUEST
      , FKART
      , FKTYP
      , VBTYP
      , WAERK
      , VKORG
      , VTWEG
      , KALSM
      , KNUMV
      , VSBED
      , FKDAT
      , BELNR
      , GJAHR
      , POPER
      , KONDA
      , KDGRP
      , BZIRK
      , PLTYP
      , INCO1
      , INCO2
      , EXPKZ
      , RFBSK
      , MRNKZ
      , KURRF
      , CPKUR
      , VALTG
      , VALDT
      , ZTERM
      , ZLSCH
      , KTGRD
      , LAND1
      , REGIO
      , COUNC
      , CITYC
      , BUKRS
      , TAXK1
      , TAXK2
      , TAXK3
      , TAXK4
      , TAXK5
      , TAXK6
      , TAXK7
      , TAXK8
      , TAXK9
      , NETWR
      , ZUKRI
      , ERNAM
      , ERZET
      , ERDAT
      , STAFO
      , KUNRG
      , KUNAG
      , MABER
      , STWAE
      , EXNUM
      , STCEG
      , AEDAT
      , SFAKN
      , KNUMA
      , FKART_RL
      , FKDAT_RL
      , KURST
      , MSCHL
      , MANSP
      , SPART
      , KKBER
      , KNKLI
      , CMWAE
      , CMKUF
      , HITYP_PR
      , BSTNK_VF
      , VBUND
      , FKART_AB
      , KAPPL
      , LANDTX
      , STCEG_H
      , STCEG_L
      , XBLNR
      , ZUONR
      , MWSBK
      , LOGSYS
      , FKSTO
      , XEGDR
      , RPLNR
      , LCNUM
      , J_1AFITP
      , KURRF_DAT
      , AKWAE
      , AKKUR
      , KIDNO
      , BVTYP
      , NUMPG
      , BUPLA
      , VKONT
      , FKK_DOCSTAT
      , NRZAS
      , SPE_BILLING_IND
      , VTREF
      , FK_SOURCE_SYS
      , FKTYP_CRM
      , STGRD
      , VBTYP_EXT
      , J_1TPBUPL
      , INCOV
      , INCO2_L
      , INCO3_L
      , DPC_REL
      , MNDID
      , PAY_TYPE
      , SEPON
      , MNDVG
      , SPPAYM
      , SPPORD
      , GLDELFLAG
      , GLCHANGETIME
      , GLCHANGETIME_DTTM
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SWINN
)
---- RENAME LAYER ----

, RENAME_SWINN as (
    SELECT
        SALES_INVOICE_HK
      , MANDT
      , VBELN
      , GLREQUEST
      , FKART
      , FKTYP
      , VBTYP
      , WAERK
      , VKORG
      , VTWEG
      , KALSM
      , KNUMV
      , VSBED
      , FKDAT
      , BELNR
      , GJAHR
      , POPER
      , KONDA
      , KDGRP
      , BZIRK
      , PLTYP
      , INCO1
      , INCO2
      , EXPKZ
      , RFBSK
      , MRNKZ
      , KURRF
      , CPKUR
      , VALTG
      , VALDT
      , ZTERM
      , ZLSCH
      , KTGRD
      , LAND1
      , REGIO
      , COUNC
      , CITYC
      , BUKRS
      , TAXK1
      , TAXK2
      , TAXK3
      , TAXK4
      , TAXK5
      , TAXK6
      , TAXK7
      , TAXK8
      , TAXK9
      , NETWR
      , ZUKRI
      , ERNAM
      , ERZET
      , ERDAT
      , STAFO
      , KUNRG
      , KUNAG
      , MABER
      , STWAE
      , EXNUM
      , STCEG
      , AEDAT
      , SFAKN
      , KNUMA
      , FKART_RL
      , FKDAT_RL
      , KURST
      , MSCHL
      , MANSP
      , SPART
      , KKBER
      , KNKLI
      , CMWAE
      , CMKUF
      , HITYP_PR
      , BSTNK_VF
      , VBUND
      , FKART_AB
      , KAPPL
      , LANDTX
      , STCEG_H
      , STCEG_L
      , XBLNR
      , ZUONR
      , MWSBK
      , LOGSYS
      , FKSTO
      , XEGDR
      , RPLNR
      , LCNUM
      , J_1AFITP
      , KURRF_DAT
      , AKWAE
      , AKKUR
      , KIDNO
      , BVTYP
      , NUMPG
      , BUPLA
      , VKONT
      , FKK_DOCSTAT
      , NRZAS
      , SPE_BILLING_IND
      , VTREF
      , FK_SOURCE_SYS
      , FKTYP_CRM
      , STGRD
      , VBTYP_EXT
      , J_1TPBUPL
      , INCOV
      , INCO2_L
      , INCO3_L
      , DPC_REL
      , MNDID
      , PAY_TYPE
      , SEPON
      , MNDVG
      , SPPAYM
      , SPPORD
      , GLDELFLAG
      , GLCHANGETIME
      , GLCHANGETIME_DTTM
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
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
          SALES_INVOICE_HK
        , MANDT
        , VBELN
        , GLREQUEST
        , FKART
        , FKTYP
        , VBTYP
        , WAERK
        , VKORG
        , VTWEG
        , KALSM
        , KNUMV
        , VSBED
        , FKDAT
        , BELNR
        , GJAHR
        , POPER
        , KONDA
        , KDGRP
        , BZIRK
        , PLTYP
        , INCO1
        , INCO2
        , EXPKZ
        , RFBSK
        , MRNKZ
        , KURRF
        , CPKUR
        , VALTG
        , VALDT
        , ZTERM
        , ZLSCH
        , KTGRD
        , LAND1
        , REGIO
        , COUNC
        , CITYC
        , BUKRS
        , TAXK1
        , TAXK2
        , TAXK3
        , TAXK4
        , TAXK5
        , TAXK6
        , TAXK7
        , TAXK8
        , TAXK9
        , NETWR
        , ZUKRI
        , ERNAM
        , ERZET
        , ERDAT
        , STAFO
        , KUNRG
        , KUNAG
        , MABER
        , STWAE
        , EXNUM
        , STCEG
        , AEDAT
        , SFAKN
        , KNUMA
        , FKART_RL
        , FKDAT_RL
        , KURST
        , MSCHL
        , MANSP
        , SPART
        , KKBER
        , KNKLI
        , CMWAE
        , CMKUF
        , HITYP_PR
        , BSTNK_VF
        , VBUND
        , FKART_AB
        , KAPPL
        , LANDTX
        , STCEG_H
        , STCEG_L
        , XBLNR
        , ZUONR
        , MWSBK
        , LOGSYS
        , FKSTO
        , XEGDR
        , RPLNR
        , LCNUM
        , J_1AFITP
        , KURRF_DAT
        , AKWAE
        , AKKUR
        , KIDNO
        , BVTYP
        , NUMPG
        , BUPLA
        , VKONT
        , FKK_DOCSTAT
        , NRZAS
        , SPE_BILLING_IND
        , VTREF
        , FK_SOURCE_SYS
        , FKTYP_CRM
        , STGRD
        , VBTYP_EXT
        , J_1TPBUPL
        , INCOV
        , INCO2_L
        , INCO3_L
        , DPC_REL
        , MNDID
        , PAY_TYPE
        , SEPON
        , MNDVG
        , SPPAYM
        , SPPORD
        , GLDELFLAG
        , GLCHANGETIME
        , GLCHANGETIME_DTTM
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
    WHERE existing.SALES_INVOICE_HK= JOIN_RESULT.SALES_INVOICE_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by SALES_INVOICE_HK, HASHDIFF order by LOAD_DTS)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS SALES_INVOICE_HK
    , CAST(NULL AS STRING) AS MANDT
    , CAST(NULL AS STRING) AS VBELN
    , CAST(NULL AS NUMBER) AS GLREQUEST
    , CAST(NULL AS STRING) AS FKART
    , CAST(NULL AS STRING) AS FKTYP
    , CAST(NULL AS STRING) AS VBTYP
    , CAST(NULL AS STRING) AS WAERK
    , CAST(NULL AS STRING) AS VKORG
    , CAST(NULL AS STRING) AS VTWEG
    , CAST(NULL AS STRING) AS KALSM
    , CAST(NULL AS STRING) AS KNUMV
    , CAST(NULL AS STRING) AS VSBED
    , CAST(NULL AS STRING) AS FKDAT
    , CAST(NULL AS STRING) AS BELNR
    , CAST(NULL AS STRING) AS GJAHR
    , CAST(NULL AS STRING) AS POPER
    , CAST(NULL AS STRING) AS KONDA
    , CAST(NULL AS STRING) AS KDGRP
    , CAST(NULL AS STRING) AS BZIRK
    , CAST(NULL AS STRING) AS PLTYP
    , CAST(NULL AS STRING) AS INCO1
    , CAST(NULL AS STRING) AS INCO2
    , CAST(NULL AS STRING) AS EXPKZ
    , CAST(NULL AS STRING) AS RFBSK
    , CAST(NULL AS STRING) AS MRNKZ
    , CAST(NULL AS STRING) AS KURRF
    , CAST(NULL AS STRING) AS CPKUR
    , CAST(NULL AS STRING) AS VALTG
    , CAST(NULL AS STRING) AS VALDT
    , CAST(NULL AS STRING) AS ZTERM
    , CAST(NULL AS STRING) AS ZLSCH
    , CAST(NULL AS STRING) AS KTGRD
    , CAST(NULL AS STRING) AS LAND1
    , CAST(NULL AS STRING) AS REGIO
    , CAST(NULL AS STRING) AS COUNC
    , CAST(NULL AS STRING) AS CITYC
    , CAST(NULL AS STRING) AS BUKRS
    , CAST(NULL AS STRING) AS TAXK1
    , CAST(NULL AS STRING) AS TAXK2
    , CAST(NULL AS STRING) AS TAXK3
    , CAST(NULL AS STRING) AS TAXK4
    , CAST(NULL AS STRING) AS TAXK5
    , CAST(NULL AS STRING) AS TAXK6
    , CAST(NULL AS STRING) AS TAXK7
    , CAST(NULL AS STRING) AS TAXK8
    , CAST(NULL AS STRING) AS TAXK9
    , CAST(NULL AS STRING) AS NETWR
    , CAST(NULL AS STRING) AS ZUKRI
    , CAST(NULL AS STRING) AS ERNAM
    , CAST(NULL AS STRING) AS ERZET
    , CAST(NULL AS STRING) AS ERDAT
    , CAST(NULL AS STRING) AS STAFO
    , CAST(NULL AS STRING) AS KUNRG
    , CAST(NULL AS STRING) AS KUNAG
    , CAST(NULL AS STRING) AS MABER
    , CAST(NULL AS STRING) AS STWAE
    , CAST(NULL AS STRING) AS EXNUM
    , CAST(NULL AS STRING) AS STCEG
    , CAST(NULL AS STRING) AS AEDAT
    , CAST(NULL AS STRING) AS SFAKN
    , CAST(NULL AS STRING) AS KNUMA
    , CAST(NULL AS STRING) AS FKART_RL
    , CAST(NULL AS STRING) AS FKDAT_RL
    , CAST(NULL AS STRING) AS KURST
    , CAST(NULL AS STRING) AS MSCHL
    , CAST(NULL AS STRING) AS MANSP
    , CAST(NULL AS STRING) AS SPART
    , CAST(NULL AS STRING) AS KKBER
    , CAST(NULL AS STRING) AS KNKLI
    , CAST(NULL AS STRING) AS CMWAE
    , CAST(NULL AS STRING) AS CMKUF
    , CAST(NULL AS STRING) AS HITYP_PR
    , CAST(NULL AS STRING) AS BSTNK_VF
    , CAST(NULL AS STRING) AS VBUND
    , CAST(NULL AS STRING) AS FKART_AB
    , CAST(NULL AS STRING) AS KAPPL
    , CAST(NULL AS STRING) AS LANDTX
    , CAST(NULL AS STRING) AS STCEG_H
    , CAST(NULL AS STRING) AS STCEG_L
    , CAST(NULL AS STRING) AS XBLNR
    , CAST(NULL AS STRING) AS ZUONR
    , CAST(NULL AS STRING) AS MWSBK
    , CAST(NULL AS STRING) AS LOGSYS
    , CAST(NULL AS STRING) AS FKSTO
    , CAST(NULL AS STRING) AS XEGDR
    , CAST(NULL AS STRING) AS RPLNR
    , CAST(NULL AS STRING) AS LCNUM
    , CAST(NULL AS STRING) AS J_1AFITP
    , CAST(NULL AS STRING) AS KURRF_DAT
    , CAST(NULL AS STRING) AS AKWAE
    , CAST(NULL AS STRING) AS AKKUR
    , CAST(NULL AS STRING) AS KIDNO
    , CAST(NULL AS STRING) AS BVTYP
    , CAST(NULL AS STRING) AS NUMPG
    , CAST(NULL AS STRING) AS BUPLA
    , CAST(NULL AS STRING) AS VKONT
    , CAST(NULL AS STRING) AS FKK_DOCSTAT
    , CAST(NULL AS STRING) AS NRZAS
    , CAST(NULL AS STRING) AS SPE_BILLING_IND
    , CAST(NULL AS STRING) AS VTREF
    , CAST(NULL AS STRING) AS FK_SOURCE_SYS
    , CAST(NULL AS STRING) AS FKTYP_CRM
    , CAST(NULL AS STRING) AS STGRD
    , CAST(NULL AS STRING) AS VBTYP_EXT
    , CAST(NULL AS STRING) AS J_1TPBUPL
    , CAST(NULL AS STRING) AS INCOV
    , CAST(NULL AS STRING) AS INCO2_L
    , CAST(NULL AS STRING) AS INCO3_L
    , CAST(NULL AS STRING) AS DPC_REL
    , CAST(NULL AS STRING) AS MNDID
    , CAST(NULL AS STRING) AS PAY_TYPE
    , CAST(NULL AS STRING) AS SEPON
    , CAST(NULL AS STRING) AS MNDVG
    , CAST(NULL AS STRING) AS SPPAYM
    , CAST(NULL AS STRING) AS SPPORD
    , CAST(NULL AS STRING) AS GLDELFLAG
    , CAST(NULL AS NUMBER) AS GLCHANGETIME
    , CAST(NULL AS TIMESTAMP) AS GLCHANGETIME_DTTM
    , CAST(NULL AS STRING) AS GLSOURCESYSTEM
    , CAST(NULL AS STRING) AS PSA_DELETE_IND
    , CONVERT_TIMEZONE('UTC','1900-01-01')  as  LOAD_DTS
    ,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
    , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
    , ''::BINARY as HASHDIFF FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}