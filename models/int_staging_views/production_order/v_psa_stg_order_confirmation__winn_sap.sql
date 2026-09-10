---- SRC LAYER ----
WITH
SRC_a              as ( SELECT ABARB, AENAM, ANZMA, APLFL, APLZL, ARBID, AUERU, AUFNR, AUFPL, AUSOR, BELNR_IST, BELNR_UMB, BEMOT, BUDAT, CANUM, CATSBELNR, CATSPEINH, CATSPRICE, CATSTCURR, ERNAM, ERSDA, ERZET, EXERD, EXERZ, EXNAM, EXTID, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, GMEIN, GMNGA, GRUND, IDAUE, IDAUR, IEBD, IEBZ, IEDD, IEDZ, IERD, IERZ, ILE01, ILE02, ILE03, ILE04, ILE05, ILE06, IPRE1, IPRK1, IPRZ1, ISAD, ISAZ, ISBD, ISBZ, ISDD, ISDZ, ISERH, ISM01, ISM02, ISM03, ISM04, ISM05, ISM06, ISMNE, ISMNU, ISMNW, KAPID, KAPTPROG, LAEDA, LEARR, LEK01, LEK02, LEK03, LEK04, LEK05, LEK06, LEKNW, LICHA, LMNGA, LOART, LOGRP, LTXA1, MANDT, MANUR, MEILR, MEINH, ME_2ND_CONF_QTY, ME_SFCID, MYEAR, NODAT, OBCHA, OBMAT, ODAUE, ODAUR, OFE01, OFE02, OFE03, OFE04, OFE05, OFE06, OFM01, OFM02, OFM03, OFM04, OFM05, OFM06, OFMNE, OFMNU, OFMNW, OPRE1, OPRZ1, ORIGF, ORIND, PACKNO, PDSNR, PEDD, PEDZ, PERNR, PRZ01, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, QUALF, RMNGA, RMZHL, RMZHL_MST, ROLE_ID, RUECK, RUECK_MST, SATZA, SCHGRUP, SKOKRS, SKOSTL, SMENG, SPLIT, STNDR, STOKZ, STZHL, SUMNR, TXTSP, UCCHA, UCMAT, VORNR, WABLNR, WEBLNR, WERKS, WTY_IND, XMNGA, ZAUSW, ZCODE, ZEIER FROM {{ source('sap_ecc_prd', 'z_afru') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_afru )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        coalesce(nullif(trim(UPPER(AUFNR)), ''), '-1')               as                                PRODUCTION_ORDER_BK
      , coalesce(nullif(trim(UPPER(APLFL)), ''), '-1') as                           PRODUCTION_ORDER_LINE_ITEM_BK
      , coalesce(nullif(trim(UPPER(SKOSTL)), ''), '-1')              as                                     COST_CENTER_BK
      , coalesce(nullif(trim(UPPER(KAPID)), ''), '-1')               as                                        CAPACITY_BK
      , coalesce(nullif(trim(UPPER(GMEIN)), ''), '-1')               as                               MATERIAL_BASE_UOM_BK
      , coalesce(nullif(trim(UPPER(MEINH)), ''), '-1')               as                                CONFIRMATION_UOM_BK
      , coalesce(nullif(trim(UPPER(AUFPL)), ''), '-1')               as                                         ROUTING_BK
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
      , CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
        ))                                                           as                                           LOAD_DTS
    FROM SRC_a
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        PRODUCTION_ORDER_BK
      , PRODUCTION_ORDER_LINE_ITEM_BK
      , COST_CENTER_BK
      , CAPACITY_BK
      , MATERIAL_BASE_UOM_BK
      , CONFIRMATION_UOM_BK
      , ROUTING_BK
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
      , LOAD_DTS
    FROM LOGIC_a
)

, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_AFRU'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PRODUCTION_ORDER_BK
        , PRODUCTION_ORDER_LINE_ITEM_BK
        , COST_CENTER_BK
        , CAPACITY_BK
        , MATERIAL_BASE_UOM_BK
        , CONFIRMATION_UOM_BK
        , ROUTING_BK
        , RUECK                                                        as CONFIRMATION_NUMBER_BK
        , RMZHL                                                        as CONFIRMATION_COUNTER_BK
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
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCTION_ORDER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PRODUCTION_ORDER_LINE_ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(COST_CENTER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CAPACITY_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(MATERIAL_BASE_UOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CONFIRMATION_UOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CONFIRMATION_NUMBER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CONFIRMATION_COUNTER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ROUTING_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCTION_ORDER_CONFIRMATION_LHK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCTION_ORDER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCTION_ORDER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCTION_ORDER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PRODUCTION_ORDER_LINE_ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCTION_ORDER_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COST_CENTER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as COST_CENTER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CAPACITY_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CAPACITY_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(MATERIAL_BASE_UOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as MATERIAL_BASE_UOM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CONFIRMATION_UOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CONFIRMATION_UOM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CONFIRMATION_NUMBER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CONFIRMATION_COUNTER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_CONFIRMATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ROUTING_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ROUTING_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ERSDA::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(LAEDA::text), '^^') 
            , '||', IFNULL(TRIM(AENAM::text), '^^') 
            , '||', IFNULL(TRIM(BUDAT::text), '^^') 
            , '||', IFNULL(TRIM(ARBID::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(LTXA1::text), '^^') 
            , '||', IFNULL(TRIM(TXTSP::text), '^^') 
            , '||', IFNULL(TRIM(ISERH::text), '^^') 
            , '||', IFNULL(TRIM(ZEIER::text), '^^') 
            , '||', IFNULL(TRIM(ILE01::text), '^^') 
            , '||', IFNULL(TRIM(ISM01::text), '^^') 
            , '||', IFNULL(TRIM(ILE02::text), '^^') 
            , '||', IFNULL(TRIM(ISM02::text), '^^') 
            , '||', IFNULL(TRIM(ILE03::text), '^^') 
            , '||', IFNULL(TRIM(ISM03::text), '^^') 
            , '||', IFNULL(TRIM(ILE04::text), '^^') 
            , '||', IFNULL(TRIM(ISM04::text), '^^') 
            , '||', IFNULL(TRIM(ILE05::text), '^^') 
            , '||', IFNULL(TRIM(ISM05::text), '^^') 
            , '||', IFNULL(TRIM(ILE06::text), '^^') 
            , '||', IFNULL(TRIM(ISM06::text), '^^') 
            , '||', IFNULL(TRIM(ABARB::text), '^^') 
            , '||', IFNULL(TRIM(ISMNW::text), '^^') 
            , '||', IFNULL(TRIM(ISMNE::text), '^^') 
            , '||', IFNULL(TRIM(LEARR::text), '^^') 
            , '||', IFNULL(TRIM(IDAUR::text), '^^') 
            , '||', IFNULL(TRIM(IDAUE::text), '^^') 
            , '||', IFNULL(TRIM(ZCODE::text), '^^') 
            , '||', IFNULL(TRIM(LOART::text), '^^') 
            , '||', IFNULL(TRIM(QUALF::text), '^^') 
            , '||', IFNULL(TRIM(ANZMA::text), '^^') 
            , '||', IFNULL(TRIM(LOGRP::text), '^^') 
            , '||', IFNULL(TRIM(GMNGA::text), '^^') 
            , '||', IFNULL(TRIM(LMNGA::text), '^^') 
            , '||', IFNULL(TRIM(XMNGA::text), '^^') 
            , '||', IFNULL(TRIM(GRUND::text), '^^') 
            , '||', IFNULL(TRIM(PERNR::text), '^^') 
            , '||', IFNULL(TRIM(ISDD::text), '^^') 
            , '||', IFNULL(TRIM(ISDZ::text), '^^') 
            , '||', IFNULL(TRIM(IERD::text), '^^') 
            , '||', IFNULL(TRIM(IERZ::text), '^^') 
            , '||', IFNULL(TRIM(ISBD::text), '^^') 
            , '||', IFNULL(TRIM(ISBZ::text), '^^') 
            , '||', IFNULL(TRIM(IEBD::text), '^^') 
            , '||', IFNULL(TRIM(IEBZ::text), '^^') 
            , '||', IFNULL(TRIM(ISAD::text), '^^') 
            , '||', IFNULL(TRIM(ISAZ::text), '^^') 
            , '||', IFNULL(TRIM(IEDD::text), '^^') 
            , '||', IFNULL(TRIM(IEDZ::text), '^^') 
            , '||', IFNULL(TRIM(PEDD::text), '^^') 
            , '||', IFNULL(TRIM(PEDZ::text), '^^') 
            , '||', IFNULL(TRIM(WABLNR::text), '^^') 
            , '||', IFNULL(TRIM(WEBLNR::text), '^^') 
            , '||', IFNULL(TRIM(AUERU::text), '^^') 
            , '||', IFNULL(TRIM(AUSOR::text), '^^') 
            , '||', IFNULL(TRIM(STNDR::text), '^^') 
            , '||', IFNULL(TRIM(MANUR::text), '^^') 
            , '||', IFNULL(TRIM(MEILR::text), '^^') 
            , '||', IFNULL(TRIM(APLZL::text), '^^') 
            , '||', IFNULL(TRIM(VORNR::text), '^^') 
            , '||', IFNULL(TRIM(SUMNR::text), '^^') 
            , '||', IFNULL(TRIM(OFM01::text), '^^') 
            , '||', IFNULL(TRIM(OFE01::text), '^^') 
            , '||', IFNULL(TRIM(LEK01::text), '^^') 
            , '||', IFNULL(TRIM(OFM02::text), '^^') 
            , '||', IFNULL(TRIM(OFE02::text), '^^') 
            , '||', IFNULL(TRIM(LEK02::text), '^^') 
            , '||', IFNULL(TRIM(OFM03::text), '^^') 
            , '||', IFNULL(TRIM(OFE03::text), '^^') 
            , '||', IFNULL(TRIM(LEK03::text), '^^') 
            , '||', IFNULL(TRIM(OFM04::text), '^^') 
            , '||', IFNULL(TRIM(OFE04::text), '^^') 
            , '||', IFNULL(TRIM(LEK04::text), '^^') 
            , '||', IFNULL(TRIM(OFM05::text), '^^') 
            , '||', IFNULL(TRIM(OFE05::text), '^^') 
            , '||', IFNULL(TRIM(LEK05::text), '^^') 
            , '||', IFNULL(TRIM(OFM06::text), '^^') 
            , '||', IFNULL(TRIM(OFE06::text), '^^') 
            , '||', IFNULL(TRIM(LEK06::text), '^^') 
            , '||', IFNULL(TRIM(OFMNW::text), '^^') 
            , '||', IFNULL(TRIM(OFMNE::text), '^^') 
            , '||', IFNULL(TRIM(LEKNW::text), '^^') 
            , '||', IFNULL(TRIM(ODAUR::text), '^^') 
            , '||', IFNULL(TRIM(ODAUE::text), '^^') 
            , '||', IFNULL(TRIM(STOKZ::text), '^^') 
            , '||', IFNULL(TRIM(STZHL::text), '^^') 
            , '||', IFNULL(TRIM(SMENG::text), '^^') 
            , '||', IFNULL(TRIM(RUECK_MST::text), '^^') 
            , '||', IFNULL(TRIM(RMZHL_MST::text), '^^') 
            , '||', IFNULL(TRIM(PDSNR::text), '^^') 
            , '||', IFNULL(TRIM(SPLIT::text), '^^') 
            , '||', IFNULL(TRIM(ZAUSW::text), '^^') 
            , '||', IFNULL(TRIM(ORIND::text), '^^') 
            , '||', IFNULL(TRIM(ORIGF::text), '^^') 
            , '||', IFNULL(TRIM(CANUM::text), '^^') 
            , '||', IFNULL(TRIM(BELNR_IST::text), '^^') 
            , '||', IFNULL(TRIM(BELNR_UMB::text), '^^') 
            , '||', IFNULL(TRIM(RMNGA::text), '^^') 
            , '||', IFNULL(TRIM(CATSBELNR::text), '^^') 
            , '||', IFNULL(TRIM(SATZA::text), '^^') 
            , '||', IFNULL(TRIM(ERZET::text), '^^') 
            , '||', IFNULL(TRIM(CATSPRICE::text), '^^') 
            , '||', IFNULL(TRIM(CATSTCURR::text), '^^') 
            , '||', IFNULL(TRIM(CATSPEINH::text), '^^') 
            , '||', IFNULL(TRIM(BEMOT::text), '^^') 
            , '||', IFNULL(TRIM(IPRZ1::text), '^^') 
            , '||', IFNULL(TRIM(IPRE1::text), '^^') 
            , '||', IFNULL(TRIM(IPRK1::text), '^^') 
            , '||', IFNULL(TRIM(EXNAM::text), '^^') 
            , '||', IFNULL(TRIM(EXERD::text), '^^') 
            , '||', IFNULL(TRIM(EXERZ::text), '^^') 
            , '||', IFNULL(TRIM(PRZ01::text), '^^') 
            , '||', IFNULL(TRIM(OPRZ1::text), '^^') 
            , '||', IFNULL(TRIM(OPRE1::text), '^^') 
            , '||', IFNULL(TRIM(SKOKRS::text), '^^') 
            , '||', IFNULL(TRIM(NODAT::text), '^^') 
            , '||', IFNULL(TRIM(ISMNU::text), '^^') 
            , '||', IFNULL(TRIM(OFMNU::text), '^^') 
            , '||', IFNULL(TRIM(PACKNO::text), '^^') 
            , '||', IFNULL(TRIM(EXTID::text), '^^') 
            , '||', IFNULL(TRIM(SCHGRUP::text), '^^') 
            , '||', IFNULL(TRIM(KAPTPROG::text), '^^') 
            , '||', IFNULL(TRIM(OBMAT::text), '^^') 
            , '||', IFNULL(TRIM(OBCHA::text), '^^') 
            , '||', IFNULL(TRIM(LICHA::text), '^^') 
            , '||', IFNULL(TRIM(MYEAR::text), '^^') 
            , '||', IFNULL(TRIM(ME_SFCID::text), '^^') 
            , '||', IFNULL(TRIM(ME_2ND_CONF_QTY::text), '^^') 
            , '||', IFNULL(TRIM(ROLE_ID::text), '^^') 
            , '||', IFNULL(TRIM(UCMAT::text), '^^') 
            , '||', IFNULL(TRIM(UCCHA::text), '^^') 
            , '||', IFNULL(TRIM(WTY_IND::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT