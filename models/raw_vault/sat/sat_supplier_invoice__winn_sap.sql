---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ ref('v_psa_stg_supplier_invoice__winn_sap') }} as SRC 
{% if is_incremental() %}
      where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
    {% endif %} )

/*
SRC_SRC            as ( SELECT * FROM int_staging_views.v_psa_stg_supplier_invoice__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        SUPPLIER_INVOICE_HK
      , BELNR
      , MANDT
      , GJAHR
      , GLREQUEST
      , BLART
      , BLDAT
      , BUDAT
      , USNAM
      , TCODE
      , CPUDT
      , CPUTM
      , VGART
      , XBLNR
      , BUKRS
      , LIFNR
      , WAERS
      , KURSF
      , RMWWR
      , BEZNK
      , WMWST1
      , MWSKZ1
      , WMWST2
      , MWSKZ2
      , ZTERM
      , ZBD1T
      , ZBD1P
      , ZBD2T
      , ZBD2P
      , ZBD3T
      , WSKTO
      , XRECH
      , BKTXT
      , SAPRL
      , LOGSYS
      , XMWST
      , STBLG
      , STJAH
      , MWSKZ_BNK
      , TXJCD_BNK
      , IVTYP
      , XRBTX
      , REPART
      , RBSTAT
      , KNUMVE
      , KNUMVL
      , ARKUEN
      , ARKUEMW
      , MAKZN
      , MAKZMW
      , LIEFFN
      , LIEFFMW
      , XAUTAKZ
      , ESRNR
      , ESRPZ
      , ESRRE
      , QSSHB
      , QSFBT
      , QSSKZ
      , DIEKZ
      , LANDL
      , LZBKZ
      , TXKRS
      , CTXKRS
      , EMPFB
      , BVTYP
      , HBKID
      , ZUONR
      , ZLSPR
      , ZLSCH
      , ZFBDT
      , KIDNO
      , REBZG
      , REBZJ
      , XINVE
      , EGMLD
      , XEGDR
      , VATDATE
      , HKONT
      , J_1BNFTYPE
      , BRNCH
      , ERFPR
      , SECCO
      , NAME1
      , NAME2
      , NAME3
      , NAME4
      , PSTLZ
      , ORT01
      , LAND1
      , STRAS
      , PFACH
      , PSTL2
      , PSKTO
      , BANKN
      , BANKL
      , BANKS
      , STCD1
      , STCD2
      , STKZU
      , STKZA
      , REGIO
      , BKONT
      , DTAWS
      , DTAMS
      , SPRAS
      , XCPDK
      , EMPFG
      , FITYP
      , STCDT
      , STKZN
      , STCD3
      , STCD4
      , BKREF
      , J_1KFREPRE
      , J_1KFTBUS
      , J_1KFTIND
      , ANRED
      , STCEG
      , ERNAME
      , REINDAT
      , UZAWE
      , FDLEV
      , FDTAG
      , ZBFIX
      , FRGKZ
      , ERFNAM
      , BUPLA
      , FILKD
      , GSBER
      , LOTKZ
      , SGTXT
      , INV_TRAN
      , PREPAY_STATUS
      , PREPAY_AWKEY
      , ASSIGN_STATUS
      , ASSIGN_NEXT_DATE
      , ASSIGN_END_DATE
      , COPY_BY_BELNR
      , COPY_BY_YEAR
      , COPY_TO_BELNR
      , COPY_TO_YEAR
      , COPY_USER
      , KURSX
      , WWERT
      , XREF3
      , J_1TPBUPL
      , PYBASTYP
      , PYBASNO
      , PYBASDAT
      , PYIBAN
      , INWARDNO_HD
      , INWARDDT_HD
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SRC
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
)

---- FINAL LAYER ----
SELECT
          SUPPLIER_INVOICE_HK
        , BELNR
        , MANDT
        , GJAHR
        , GLREQUEST
        , BLART
        , BLDAT
        , BUDAT
        , USNAM
        , TCODE
        , CPUDT
        , CPUTM
        , VGART
        , XBLNR
        , BUKRS
        , LIFNR
        , WAERS
        , KURSF
        , RMWWR
        , BEZNK
        , WMWST1
        , MWSKZ1
        , WMWST2
        , MWSKZ2
        , ZTERM
        , ZBD1T
        , ZBD1P
        , ZBD2T
        , ZBD2P
        , ZBD3T
        , WSKTO
        , XRECH
        , BKTXT
        , SAPRL
        , LOGSYS
        , XMWST
        , STBLG
        , STJAH
        , MWSKZ_BNK
        , TXJCD_BNK
        , IVTYP
        , XRBTX
        , REPART
        , RBSTAT
        , KNUMVE
        , KNUMVL
        , ARKUEN
        , ARKUEMW
        , MAKZN
        , MAKZMW
        , LIEFFN
        , LIEFFMW
        , XAUTAKZ
        , ESRNR
        , ESRPZ
        , ESRRE
        , QSSHB
        , QSFBT
        , QSSKZ
        , DIEKZ
        , LANDL
        , LZBKZ
        , TXKRS
        , CTXKRS
        , EMPFB
        , BVTYP
        , HBKID
        , ZUONR
        , ZLSPR
        , ZLSCH
        , ZFBDT
        , KIDNO
        , REBZG
        , REBZJ
        , XINVE
        , EGMLD
        , XEGDR
        , VATDATE
        , HKONT
        , J_1BNFTYPE
        , BRNCH
        , ERFPR
        , SECCO
        , NAME1
        , NAME2
        , NAME3
        , NAME4
        , PSTLZ
        , ORT01
        , LAND1
        , STRAS
        , PFACH
        , PSTL2
        , PSKTO
        , BANKN
        , BANKL
        , BANKS
        , STCD1
        , STCD2
        , STKZU
        , STKZA
        , REGIO
        , BKONT
        , DTAWS
        , DTAMS
        , SPRAS
        , XCPDK
        , EMPFG
        , FITYP
        , STCDT
        , STKZN
        , STCD3
        , STCD4
        , BKREF
        , J_1KFREPRE
        , J_1KFTBUS
        , J_1KFTIND
        , ANRED
        , STCEG
        , ERNAME
        , REINDAT
        , UZAWE
        , FDLEV
        , FDTAG
        , ZBFIX
        , FRGKZ
        , ERFNAM
        , BUPLA
        , FILKD
        , GSBER
        , LOTKZ
        , SGTXT
        , INV_TRAN
        , PREPAY_STATUS
        , PREPAY_AWKEY
        , ASSIGN_STATUS
        , ASSIGN_NEXT_DATE
        , ASSIGN_END_DATE
        , COPY_BY_BELNR
        , COPY_BY_YEAR
        , COPY_TO_BELNR
        , COPY_TO_YEAR
        , COPY_USER
        , KURSX
        , WWERT
        , XREF3
        , J_1TPBUPL
        , PYBASTYP
        , PYBASNO
        , PYBASDAT
        , PYIBAN
        , INWARDNO_HD
        , INWARDDT_HD
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} existing
    WHERE existing.SUPPLIER_INVOICE_HK = JOIN_RESULT.SUPPLIER_INVOICE_HK
      AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by SUPPLIER_INVOICE_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS SUPPLIER_INVOICE_HK,
NULL AS BELNR,
NULL AS MANDT,
NULL AS GJAHR,
NULL AS GLREQUEST,
NULL AS BLART,
NULL AS BLDAT,
NULL AS BUDAT,
NULL AS USNAM,
NULL AS TCODE,
NULL AS CPUDT,
NULL AS CPUTM,
NULL AS VGART,
NULL AS XBLNR,
NULL AS BUKRS,
NULL AS LIFNR,
NULL AS WAERS,
NULL AS KURSF,
NULL AS RMWWR,
NULL AS BEZNK,
NULL AS WMWST1,
NULL AS MWSKZ1,
NULL AS WMWST2,
NULL AS MWSKZ2,
NULL AS ZTERM,
NULL AS ZBD1T,
NULL AS ZBD1P,
NULL AS ZBD2T,
NULL AS ZBD2P,
NULL AS ZBD3T,
NULL AS WSKTO,
NULL AS XRECH,
NULL AS BKTXT,
NULL AS SAPRL,
NULL AS LOGSYS,
NULL AS XMWST,
NULL AS STBLG,
NULL AS STJAH,
NULL AS MWSKZ_BNK,
NULL AS TXJCD_BNK,
NULL AS IVTYP,
NULL AS XRBTX,
NULL AS REPART,
NULL AS RBSTAT,
NULL AS KNUMVE,
NULL AS KNUMVL,
NULL AS ARKUEN,
NULL AS ARKUEMW,
NULL AS MAKZN,
NULL AS MAKZMW,
NULL AS LIEFFN,
NULL AS LIEFFMW,
NULL AS XAUTAKZ,
NULL AS ESRNR,
NULL AS ESRPZ,
NULL AS ESRRE,
NULL AS QSSHB,
NULL AS QSFBT,
NULL AS QSSKZ,
NULL AS DIEKZ,
NULL AS LANDL,
NULL AS LZBKZ,
NULL AS TXKRS,
NULL AS CTXKRS,
NULL AS EMPFB,
NULL AS BVTYP,
NULL AS HBKID,
NULL AS ZUONR,
NULL AS ZLSPR,
NULL AS ZLSCH,
NULL AS ZFBDT,
NULL AS KIDNO,
NULL AS REBZG,
NULL AS REBZJ,
NULL AS XINVE,
NULL AS EGMLD,
NULL AS XEGDR,
NULL AS VATDATE,
NULL AS HKONT,
NULL AS J_1BNFTYPE,
NULL AS BRNCH,
NULL AS ERFPR,
NULL AS SECCO,
NULL AS NAME1,
NULL AS NAME2,
NULL AS NAME3,
NULL AS NAME4,
NULL AS PSTLZ,
NULL AS ORT01,
NULL AS LAND1,
NULL AS STRAS,
NULL AS PFACH,
NULL AS PSTL2,
NULL AS PSKTO,
NULL AS BANKN,
NULL AS BANKL,
NULL AS BANKS,
NULL AS STCD1,
NULL AS STCD2,
NULL AS STKZU,
NULL AS STKZA,
NULL AS REGIO,
NULL AS BKONT,
NULL AS DTAWS,
NULL AS DTAMS,
NULL AS SPRAS,
NULL AS XCPDK,
NULL AS EMPFG,
NULL AS FITYP,
NULL AS STCDT,
NULL AS STKZN,
NULL AS STCD3,
NULL AS STCD4,
NULL AS BKREF,
NULL AS J_1KFREPRE,
NULL AS J_1KFTBUS,
NULL AS J_1KFTIND,
NULL AS ANRED,
NULL AS STCEG,
NULL AS ERNAME,
NULL AS REINDAT,
NULL AS UZAWE,
NULL AS FDLEV,
NULL AS FDTAG,
NULL AS ZBFIX,
NULL AS FRGKZ,
NULL AS ERFNAM,
NULL AS BUPLA,
NULL AS FILKD,
NULL AS GSBER,
NULL AS LOTKZ,
NULL AS SGTXT,
NULL AS INV_TRAN,
NULL AS PREPAY_STATUS,
NULL AS PREPAY_AWKEY,
NULL AS ASSIGN_STATUS,
NULL AS ASSIGN_NEXT_DATE,
NULL AS ASSIGN_END_DATE,
NULL AS COPY_BY_BELNR,
NULL AS COPY_BY_YEAR,
NULL AS COPY_TO_BELNR,
NULL AS COPY_TO_YEAR,
NULL AS COPY_USER,
NULL AS KURSX,
NULL AS WWERT,
NULL AS XREF3,
NULL AS J_1TPBUPL,
NULL AS PYBASTYP,
NULL AS PYBASNO,
NULL AS PYBASDAT,
NULL AS PYIBAN,
NULL AS INWARDNO_HD,
NULL AS INWARDDT_HD,
NULL AS GLDELFLAG,
NULL AS GLSOURCESYSTEM,
NULL AS GLCHANGETIME,
'N' AS PSA_DELETE_IND,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'1900-01-01T00:00:00'::TIMESTAMP_NTZ AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
MD5_BINARY('') AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
