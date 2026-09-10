---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT * FROM {{ ref('v_psa_stg_gl_header__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.V_PSA_STG_GL_HEADER__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        GENERAL_LEDGER_HK
      , MANDT
      , BUKRS
      , BELNR
      , GJAHR
      , GLREQUEST
      , BLART
      , BLDAT
      , BUDAT
      , MONAT
      , CPUDT
      , CPUTM
      , AEDAT
      , UPDDT
      , WWERT
      , USNAM
      , TCODE
      , BVORG
      , XBLNR
      , DBBLG
      , STBLG
      , STJAH
      , BKTXT
      , WAERS
      , KURSF
      , KZWRS
      , KZKRS
      , BSTAT
      , XNETB
      , FRATH
      , XRUEB
      , GLVOR
      , GRPID
      , DOKID
      , ARCID
      , IBLAR
      , AWTYP
      , AWKEY
      , FIKRS
      , HWAER
      , HWAE2
      , HWAE3
      , KURS2
      , KURS3
      , BASW2
      , BASW3
      , UMRD2
      , UMRD3
      , XSTOV
      , STODT
      , XMWST
      , CURT2
      , CURT3
      , KUTY2
      , KUTY3
      , XSNET
      , AUSBK
      , XUSVR
      , DUEFL
      , AWSYS
      , TXKRS
      , CTXKRS
      , LOTKZ
      , XWVOF
      , STGRD
      , PPNAM
      , PPDAT
      , PPTME
      , BRNCH
      , NUMPG
      , ADISC
      , XREF1_HD
      , XREF2_HD
      , XREVERSAL
      , REINDAT
      , RLDNR
      , LDGRP
      , PROPMANO
      , XBLNR_ALT
      , VATDATE
      , DOCCAT
      , XSPLIT
      , CASH_ALLOC
      , FOLLOW_ON
      , XREORG
      , SUBSET
      , KURST
      , KURSX
      , KUR2X
      , KUR3X
      , XMCA
      , RESUBMISSION
      , SAPF15_STATUS
      , PSOTY
      , PSOAK
      , PSOKS
      , PSOSG
      , PSOFN
      , INTFORM
      , INTDATE
      , PSOBT
      , PSOZL
      , PSODT
      , PSOTM
      , FM_UMART
      , CCINS
      , CCNUM
      , SSBLK
      , BATCH
      , SNAME
      , SAMPLED
      , EXCLUDE_FLAG
      , BLIND
      , OFFSET_STATUS
      , OFFSET_REFER_DAT
      , PENRC
      , KNUMV
      , PYBASTYP
      , PYBASNO
      , PYBASDAT
      , PYIBAN
      , INWARDNO_HD
      , INWARDDT_HD
      , GLDELFLAG
      , GLCHANGETIME
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
        GENERAL_LEDGER_HK
      , MANDT
      , BUKRS
      , BELNR
      , GJAHR
      , GLREQUEST
      , BLART
      , BLDAT
      , BUDAT
      , MONAT
      , CPUDT
      , CPUTM
      , AEDAT
      , UPDDT
      , WWERT
      , USNAM
      , TCODE
      , BVORG
      , XBLNR
      , DBBLG
      , STBLG
      , STJAH
      , BKTXT
      , WAERS
      , KURSF
      , KZWRS
      , KZKRS
      , BSTAT
      , XNETB
      , FRATH
      , XRUEB
      , GLVOR
      , GRPID
      , DOKID
      , ARCID
      , IBLAR
      , AWTYP
      , AWKEY
      , FIKRS
      , HWAER
      , HWAE2
      , HWAE3
      , KURS2
      , KURS3
      , BASW2
      , BASW3
      , UMRD2
      , UMRD3
      , XSTOV
      , STODT
      , XMWST
      , CURT2
      , CURT3
      , KUTY2
      , KUTY3
      , XSNET
      , AUSBK
      , XUSVR
      , DUEFL
      , AWSYS
      , TXKRS
      , CTXKRS
      , LOTKZ
      , XWVOF
      , STGRD
      , PPNAM
      , PPDAT
      , PPTME
      , BRNCH
      , NUMPG
      , ADISC
      , XREF1_HD
      , XREF2_HD
      , XREVERSAL
      , REINDAT
      , RLDNR
      , LDGRP
      , PROPMANO
      , XBLNR_ALT
      , VATDATE
      , DOCCAT
      , XSPLIT
      , CASH_ALLOC
      , FOLLOW_ON
      , XREORG
      , SUBSET
      , KURST
      , KURSX
      , KUR2X
      , KUR3X
      , XMCA
      , RESUBMISSION
      , SAPF15_STATUS
      , PSOTY
      , PSOAK
      , PSOKS
      , PSOSG
      , PSOFN
      , INTFORM
      , INTDATE
      , PSOBT
      , PSOZL
      , PSODT
      , PSOTM
      , FM_UMART
      , CCINS
      , CCNUM
      , SSBLK
      , BATCH
      , SNAME
      , SAMPLED
      , EXCLUDE_FLAG
      , BLIND
      , OFFSET_STATUS
      , OFFSET_REFER_DAT
      , PENRC
      , KNUMV
      , PYBASTYP
      , PYBASNO
      , PYBASDAT
      , PYIBAN
      , INWARDNO_HD
      , INWARDDT_HD
      , GLDELFLAG
      , GLCHANGETIME
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
          GENERAL_LEDGER_HK
        , MANDT
        , BUKRS
        , BELNR
        , GJAHR
        , GLREQUEST
        , BLART
        , BLDAT
        , BUDAT
        , MONAT
        , CPUDT
        , CPUTM
        , AEDAT
        , UPDDT
        , WWERT
        , USNAM
        , TCODE
        , BVORG
        , XBLNR
        , DBBLG
        , STBLG
        , STJAH
        , BKTXT
        , WAERS
        , KURSF
        , KZWRS
        , KZKRS
        , BSTAT
        , XNETB
        , FRATH
        , XRUEB
        , GLVOR
        , GRPID
        , DOKID
        , ARCID
        , IBLAR
        , AWTYP
        , AWKEY
        , FIKRS
        , HWAER
        , HWAE2
        , HWAE3
        , KURS2
        , KURS3
        , BASW2
        , BASW3
        , UMRD2
        , UMRD3
        , XSTOV
        , STODT
        , XMWST
        , CURT2
        , CURT3
        , KUTY2
        , KUTY3
        , XSNET
        , AUSBK
        , XUSVR
        , DUEFL
        , AWSYS
        , TXKRS
        , CTXKRS
        , LOTKZ
        , XWVOF
        , STGRD
        , PPNAM
        , PPDAT
        , PPTME
        , BRNCH
        , NUMPG
        , ADISC
        , XREF1_HD
        , XREF2_HD
        , XREVERSAL
        , REINDAT
        , RLDNR
        , LDGRP
        , PROPMANO
        , XBLNR_ALT
        , VATDATE
        , DOCCAT
        , XSPLIT
        , CASH_ALLOC
        , FOLLOW_ON
        , XREORG
        , SUBSET
        , KURST
        , KURSX
        , KUR2X
        , KUR3X
        , XMCA
        , RESUBMISSION
        , SAPF15_STATUS
        , PSOTY
        , PSOAK
        , PSOKS
        , PSOSG
        , PSOFN
        , INTFORM
        , INTDATE
        , PSOBT
        , PSOZL
        , PSODT
        , PSOTM
        , FM_UMART
        , CCINS
        , CCNUM
        , SSBLK
        , BATCH
        , SNAME
        , SAMPLED
        , EXCLUDE_FLAG
        , BLIND
        , OFFSET_STATUS
        , OFFSET_REFER_DAT
        , PENRC
        , KNUMV
        , PYBASTYP
        , PYBASNO
        , PYBASDAT
        , PYIBAN
        , INWARDNO_HD
        , INWARDDT_HD
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
    WHERE existing.GENERAL_LEDGER_HK= JOIN_RESULT.GENERAL_LEDGER_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by GENERAL_LEDGER_HK, HASHDIFF order by LOAD_DTS)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS GENERAL_LEDGER_HK
     , NULL AS MANDT
, NULL AS BUKRS
, NULL AS BELNR
, NULL AS GJAHR
, NULL AS GLREQUEST
, NULL AS BLART
, NULL AS BLDAT
, NULL AS BUDAT
, NULL AS MONAT
, NULL AS CPUDT
, NULL AS CPUTM
, NULL AS AEDAT
, NULL AS UPDDT
, NULL AS WWERT
, NULL AS USNAM
, NULL AS TCODE
, NULL AS BVORG
, NULL AS XBLNR
, NULL AS DBBLG
, NULL AS STBLG
, NULL AS STJAH
, NULL AS BKTXT
, NULL AS WAERS
, NULL AS KURSF
, NULL AS KZWRS
, NULL AS KZKRS
, NULL AS BSTAT
, NULL AS XNETB
, NULL AS FRATH
, NULL AS XRUEB
, NULL AS GLVOR
, NULL AS GRPID
, NULL AS DOKID
, NULL AS ARCID
, NULL AS IBLAR
, NULL AS AWTYP
, NULL AS AWKEY
, NULL AS FIKRS
, NULL AS HWAER
, NULL AS HWAE2
, NULL AS HWAE3
, NULL AS KURS2
, NULL AS KURS3
, NULL AS BASW2
, NULL AS BASW3
, NULL AS UMRD2
, NULL AS UMRD3
, NULL AS XSTOV
, NULL AS STODT
, NULL AS XMWST
, NULL AS CURT2
, NULL AS CURT3
, NULL AS KUTY2
, NULL AS KUTY3
, NULL AS XSNET
, NULL AS AUSBK
, NULL AS XUSVR
, NULL AS DUEFL
, NULL AS AWSYS
, NULL AS TXKRS
, NULL AS CTXKRS
, NULL AS LOTKZ
, NULL AS XWVOF
, NULL AS STGRD
, NULL AS PPNAM
, NULL AS PPDAT
, NULL AS PPTME
, NULL AS BRNCH
, NULL AS NUMPG
, NULL AS ADISC
, NULL AS XREF1_HD
, NULL AS XREF2_HD
, NULL AS XREVERSAL
, NULL AS REINDAT
, NULL AS RLDNR
, NULL AS LDGRP
, NULL AS PROPMANO
, NULL AS XBLNR_ALT
, NULL AS VATDATE
, NULL AS DOCCAT
, NULL AS XSPLIT
, NULL AS CASH_ALLOC
, NULL AS FOLLOW_ON
, NULL AS XREORG
, NULL AS SUBSET
, NULL AS KURST
, NULL AS KURSX
, NULL AS KUR2X
, NULL AS KUR3X
, NULL AS XMCA
, NULL AS RESUBMISSION
, NULL AS SAPF15_STATUS
, NULL AS PSOTY
, NULL AS PSOAK
, NULL AS PSOKS
, NULL AS PSOSG
, NULL AS PSOFN
, NULL AS INTFORM
, NULL AS INTDATE
, NULL AS PSOBT
, NULL AS PSOZL
, NULL AS PSODT
, NULL AS PSOTM
, NULL AS FM_UMART
, NULL AS CCINS
, NULL AS CCNUM
, NULL AS SSBLK
, NULL AS BATCH
, NULL AS SNAME
, NULL AS SAMPLED
, NULL AS EXCLUDE_FLAG
, NULL AS BLIND
, NULL AS OFFSET_STATUS
, NULL AS OFFSET_REFER_DAT
, NULL AS PENRC
, NULL AS KNUMV
, NULL AS PYBASTYP
, NULL AS PYBASNO
, NULL AS PYBASDAT
, NULL AS PYIBAN
, NULL AS INWARDNO_HD
, NULL AS INWARDDT_HD
, NULL AS GLDELFLAG
, NULL AS GLCHANGETIME
, NULL AS GLSOURCESYSTEM
    , NULL  AS PSA_DELETE_IND
, CONVERT_TIMEZONE('UTC','1900-01-01')  as  LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASH_DIFF FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}