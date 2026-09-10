---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ ref('v_psa_stg_order_confirmation__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_a              as ( SELECT * FROM STAGING.V_PSA_STG_ORDER_CONFIRMATION__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        ORDER_CONFIRMATION_HK
      , MANDT
      , RUECK
      , RMZHL
      , GLREQUEST
      , ERSDA
      , ERNAM
      , LAEDA
      , AENAM
      , BUDAT
      , ARBID
      , WERKS
      , LTXA1
      , TXTSP
      , ISERH
      , ZEIER
      , ILE01
      , ISM01
      , ILE02
      , ISM02
      , ILE03
      , ISM03
      , ILE04
      , ISM04
      , ILE05
      , ISM05
      , ILE06
      , ISM06
      , ABARB
      , ISMNW
      , ISMNE
      , LEARR
      , IDAUR
      , IDAUE
      , ZCODE
      , LOART
      , QUALF
      , ANZMA
      , LOGRP
      , GMNGA
      , LMNGA
      , XMNGA
      , GMEIN
      , MEINH
      , GRUND
      , PERNR
      , ISDD
      , ISDZ
      , IERD
      , IERZ
      , ISBD
      , ISBZ
      , IEBD
      , IEBZ
      , ISAD
      , ISAZ
      , IEDD
      , IEDZ
      , PEDD
      , PEDZ
      , WABLNR
      , WEBLNR
      , AUERU
      , AUSOR
      , STNDR
      , MANUR
      , MEILR
      , AUFPL
      , APLZL
      , AUFNR
      , APLFL
      , VORNR
      , SUMNR
      , OFM01
      , OFE01
      , LEK01
      , OFM02
      , OFE02
      , LEK02
      , OFM03
      , OFE03
      , LEK03
      , OFM04
      , OFE04
      , LEK04
      , OFM05
      , OFE05
      , LEK05
      , OFM06
      , OFE06
      , LEK06
      , OFMNW
      , OFMNE
      , LEKNW
      , ODAUR
      , ODAUE
      , STOKZ
      , STZHL
      , SMENG
      , RUECK_MST
      , RMZHL_MST
      , PDSNR
      , KAPID
      , SPLIT
      , ZAUSW
      , ORIND
      , ORIGF
      , CANUM
      , BELNR_IST
      , BELNR_UMB
      , RMNGA
      , CATSBELNR
      , SATZA
      , ERZET
      , CATSPRICE
      , CATSTCURR
      , CATSPEINH
      , BEMOT
      , IPRZ1
      , IPRE1
      , IPRK1
      , EXNAM
      , EXERD
      , EXERZ
      , PRZ01
      , OPRZ1
      , OPRE1
      , SKOKRS
      , SKOSTL
      , NODAT
      , ISMNU
      , OFMNU
      , PACKNO
      , EXTID
      , SCHGRUP
      , KAPTPROG
      , OBMAT
      , OBCHA
      , LICHA
      , MYEAR
      , ME_SFCID
      , ME_2ND_CONF_QTY
      , ROLE_ID
      , UCMAT
      , UCCHA
      , WTY_IND
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , HASHDIFF
      , REC_SRC
      , LOAD_DTS
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        ORDER_CONFIRMATION_HK
      , MANDT
      , RUECK
      , RMZHL
      , GLREQUEST
      , ERSDA
      , ERNAM
      , LAEDA
      , AENAM
      , BUDAT
      , ARBID
      , WERKS
      , LTXA1
      , TXTSP
      , ISERH
      , ZEIER
      , ILE01
      , ISM01
      , ILE02
      , ISM02
      , ILE03
      , ISM03
      , ILE04
      , ISM04
      , ILE05
      , ISM05
      , ILE06
      , ISM06
      , ABARB
      , ISMNW
      , ISMNE
      , LEARR
      , IDAUR
      , IDAUE
      , ZCODE
      , LOART
      , QUALF
      , ANZMA
      , LOGRP
      , GMNGA
      , LMNGA
      , XMNGA
      , GMEIN
      , MEINH
      , GRUND
      , PERNR
      , ISDD
      , ISDZ
      , IERD
      , IERZ
      , ISBD
      , ISBZ
      , IEBD
      , IEBZ
      , ISAD
      , ISAZ
      , IEDD
      , IEDZ
      , PEDD
      , PEDZ
      , WABLNR
      , WEBLNR
      , AUERU
      , AUSOR
      , STNDR
      , MANUR
      , MEILR
      , AUFPL
      , APLZL
      , AUFNR
      , APLFL
      , VORNR
      , SUMNR
      , OFM01
      , OFE01
      , LEK01
      , OFM02
      , OFE02
      , LEK02
      , OFM03
      , OFE03
      , LEK03
      , OFM04
      , OFE04
      , LEK04
      , OFM05
      , OFE05
      , LEK05
      , OFM06
      , OFE06
      , LEK06
      , OFMNW
      , OFMNE
      , LEKNW
      , ODAUR
      , ODAUE
      , STOKZ
      , STZHL
      , SMENG
      , RUECK_MST
      , RMZHL_MST
      , PDSNR
      , KAPID
      , SPLIT
      , ZAUSW
      , ORIND
      , ORIGF
      , CANUM
      , BELNR_IST
      , BELNR_UMB
      , RMNGA
      , CATSBELNR
      , SATZA
      , ERZET
      , CATSPRICE
      , CATSTCURR
      , CATSPEINH
      , BEMOT
      , IPRZ1
      , IPRE1
      , IPRK1
      , EXNAM
      , EXERD
      , EXERZ
      , PRZ01
      , OPRZ1
      , OPRE1
      , SKOKRS
      , SKOSTL
      , NODAT
      , ISMNU
      , OFMNU
      , PACKNO
      , EXTID
      , SCHGRUP
      , KAPTPROG
      , OBMAT
      , OBCHA
      , LICHA
      , MYEAR
      , ME_SFCID
      , ME_2ND_CONF_QTY
      , ROLE_ID
      , UCMAT
      , UCCHA
      , WTY_IND
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , HASHDIFF
      , REC_SRC
      , LOAD_DTS
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
          ORDER_CONFIRMATION_HK
        , MANDT
        , RUECK
        , RMZHL
        , GLREQUEST
        , ERSDA
        , ERNAM
        , LAEDA
        , AENAM
        , BUDAT
        , ARBID
        , WERKS
        , LTXA1
        , TXTSP
        , ISERH
        , ZEIER
        , ILE01
        , ISM01
        , ILE02
        , ISM02
        , ILE03
        , ISM03
        , ILE04
        , ISM04
        , ILE05
        , ISM05
        , ILE06
        , ISM06
        , ABARB
        , ISMNW
        , ISMNE
        , LEARR
        , IDAUR
        , IDAUE
        , ZCODE
        , LOART
        , QUALF
        , ANZMA
        , LOGRP
        , GMNGA
        , LMNGA
        , XMNGA
        , GMEIN
        , MEINH
        , GRUND
        , PERNR
        , ISDD
        , ISDZ
        , IERD
        , IERZ
        , ISBD
        , ISBZ
        , IEBD
        , IEBZ
        , ISAD
        , ISAZ
        , IEDD
        , IEDZ
        , PEDD
        , PEDZ
        , WABLNR
        , WEBLNR
        , AUERU
        , AUSOR
        , STNDR
        , MANUR
        , MEILR
        , AUFPL
        , APLZL
        , AUFNR
        , APLFL
        , VORNR
        , SUMNR
        , OFM01
        , OFE01
        , LEK01
        , OFM02
        , OFE02
        , LEK02
        , OFM03
        , OFE03
        , LEK03
        , OFM04
        , OFE04
        , LEK04
        , OFM05
        , OFE05
        , LEK05
        , OFM06
        , OFE06
        , LEK06
        , OFMNW
        , OFMNE
        , LEKNW
        , ODAUR
        , ODAUE
        , STOKZ
        , STZHL
        , SMENG
        , RUECK_MST
        , RMZHL_MST
        , PDSNR
        , KAPID
        , SPLIT
        , ZAUSW
        , ORIND
        , ORIGF
        , CANUM
        , BELNR_IST
        , BELNR_UMB
        , RMNGA
        , CATSBELNR
        , SATZA
        , ERZET
        , CATSPRICE
        , CATSTCURR
        , CATSPEINH
        , BEMOT
        , IPRZ1
        , IPRE1
        , IPRK1
        , EXNAM
        , EXERD
        , EXERZ
        , PRZ01
        , OPRZ1
        , OPRE1
        , SKOKRS
        , SKOSTL
        , NODAT
        , ISMNU
        , OFMNU
        , PACKNO
        , EXTID
        , SCHGRUP
        , KAPTPROG
        , OBMAT
        , OBCHA
        , LICHA
        , MYEAR
        , ME_SFCID
        , ME_2ND_CONF_QTY
        , ROLE_ID
        , UCMAT
        , UCCHA
        , WTY_IND
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , HASHDIFF
        , REC_SRC
        , LOAD_DTS
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ORDER_CONFIRMATION_HK = JOIN_RESULT.ORDER_CONFIRMATION_HK AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by ORDER_CONFIRMATION_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS ORDER_CONFIRMATION_HK,
NULL AS MANDT,
NULL AS RUECK,
NULL AS RMZHL,
NULL AS GLREQUEST,
NULL AS ERSDA,
NULL AS ERNAM,
NULL AS LAEDA,
NULL AS AENAM,
NULL AS BUDAT,
NULL AS ARBID,
NULL AS WERKS,
NULL AS LTXA1,
NULL AS TXTSP,
NULL AS ISERH,
NULL AS ZEIER,
NULL AS ILE01,
NULL AS ISM01,
NULL AS ILE02,
NULL AS ISM02,
NULL AS ILE03,
NULL AS ISM03,
NULL AS ILE04,
NULL AS ISM04,
NULL AS ILE05,
NULL AS ISM05,
NULL AS ILE06,
NULL AS ISM06,
NULL AS ABARB,
NULL AS ISMNW,
NULL AS ISMNE,
NULL AS LEARR,
NULL AS IDAUR,
NULL AS IDAUE,
NULL AS ZCODE,
NULL AS LOART,
NULL AS QUALF,
NULL AS ANZMA,
NULL AS LOGRP,
NULL AS GMNGA,
NULL AS LMNGA,
NULL AS XMNGA,
NULL AS GMEIN,
NULL AS MEINH,
NULL AS GRUND,
NULL AS PERNR,
NULL AS ISDD,
NULL AS ISDZ,
NULL AS IERD,
NULL AS IERZ,
NULL AS ISBD,
NULL AS ISBZ,
NULL AS IEBD,
NULL AS IEBZ,
NULL AS ISAD,
NULL AS ISAZ,
NULL AS IEDD,
NULL AS IEDZ,
NULL AS PEDD,
NULL AS PEDZ,
NULL AS WABLNR,
NULL AS WEBLNR,
NULL AS AUERU,
NULL AS AUSOR,
NULL AS STNDR,
NULL AS MANUR,
NULL AS MEILR,
NULL AS AUFPL,
NULL AS APLZL,
NULL AS AUFNR,
NULL AS APLFL,
NULL AS VORNR,
NULL AS SUMNR,
NULL AS OFM01,
NULL AS OFE01,
NULL AS LEK01,
NULL AS OFM02,
NULL AS OFE02,
NULL AS LEK02,
NULL AS OFM03,
NULL AS OFE03,
NULL AS LEK03,
NULL AS OFM04,
NULL AS OFE04,
NULL AS LEK04,
NULL AS OFM05,
NULL AS OFE05,
NULL AS LEK05,
NULL AS OFM06,
NULL AS OFE06,
NULL AS LEK06,
NULL AS OFMNW,
NULL AS OFMNE,
NULL AS LEKNW,
NULL AS ODAUR,
NULL AS ODAUE,
NULL AS STOKZ,
NULL AS STZHL,
NULL AS SMENG,
NULL AS RUECK_MST,
NULL AS RMZHL_MST,
NULL AS PDSNR,
NULL AS KAPID,
NULL AS SPLIT,
NULL AS ZAUSW,
NULL AS ORIND,
NULL AS ORIGF,
NULL AS CANUM,
NULL AS BELNR_IST,
NULL AS BELNR_UMB,
NULL AS RMNGA,
NULL AS CATSBELNR,
NULL AS SATZA,
NULL AS ERZET,
NULL AS CATSPRICE,
NULL AS CATSTCURR,
NULL AS CATSPEINH,
NULL AS BEMOT,
NULL AS IPRZ1,
NULL AS IPRE1,
NULL AS IPRK1,
NULL AS EXNAM,
NULL AS EXERD,
NULL AS EXERZ,
NULL AS PRZ01,
NULL AS OPRZ1,
NULL AS OPRE1,
NULL AS SKOKRS,
NULL AS SKOSTL,
NULL AS NODAT,
NULL AS ISMNU,
NULL AS OFMNU,
NULL AS PACKNO,
NULL AS EXTID,
NULL AS SCHGRUP,
NULL AS KAPTPROG,
NULL AS OBMAT,
NULL AS OBCHA,
NULL AS LICHA,
NULL AS MYEAR,
NULL AS ME_SFCID,
NULL AS ME_2ND_CONF_QTY,
NULL AS ROLE_ID,
NULL AS UCMAT,
NULL AS UCCHA,
NULL AS WTY_IND,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLSOURCESYSTEM,
NULL AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
NULL AS PSA_DELETE_IND,
''::BINARY AS HASHDIFF,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
