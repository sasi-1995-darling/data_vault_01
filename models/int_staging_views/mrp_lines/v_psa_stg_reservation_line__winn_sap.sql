---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_resb') }} as SRC  ),
SRC_bkcc           as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_RESB )
, SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        RSNUM                                                               as                                     RESERVATION_BK
      , COALESCE(NULLIF(UPPER(TRIM(RSPOS)), ''), '-1')                      as                                RESERVATION_LINE_BK
      , COALESCE(NULLIF(UPPER(TRIM(WERKS)), ''), '-1')                      as                                           PLANT_BK
      , coalesce(nullif(UPPER(trim(PLNUM)), ''), '-1')                      as                                   PLANNED_ORDER_BK
      , coalesce(nullif(UPPER(trim(BANFN)), ''), '-1')                      as                            PURCHASE_REQUISITION_BK
      , IFF(NULLIF(TRIM(BANFN), '') IS NOT NULL OR NULLIF(TRIM(BNFPO), '') IS NOT NULL, UPPER(CONCAT(BANFN, '||', BNFPO)), '-1')  as  PURCHASE_REQUISITION_ITEM_BK
      , coalesce(nullif(UPPER(trim(EBELN)), ''), '-1')                      as                                       PO_HEADER_BK
      , IFF(NULLIF(TRIM(EBELN), '') IS NOT NULL OR NULLIF(TRIM(EBELP), '') IS NOT NULL, UPPER(CONCAT(EBELN,'||',EBELP)), '-1')     as     PO_ITEM_BK
      , IFF(NULLIF(TRIM(PO_ITEM_BK), '') IS NOT NULL OR NULLIF(TRIM(EBELE), '') IS NOT NULL, UPPER(CONCAT(PO_ITEM_BK,'||',EBELE)), '-1')  as     PO_LINE_BK
      , coalesce(nullif(UPPER(trim(AUFPL)), ''), '-1')                      as                                         ROUTING_BK
      , coalesce(nullif(UPPER(trim(AENNR)), ''), '-1')                      as                                   CHANGE_MASTER_BK
      , coalesce(nullif(UPPER(trim(LGORT)), ''), '-1')                      as                          GOODS_STORAGE_LOCATION_BK
      , coalesce(nullif(UPPER(trim(LGNUM)), ''), '-1')                      as                                       WAREHOUSE_BK
      , coalesce(nullif(UPPER(trim(LGTYP)), ''), '-1')                      as                                    STORAGE_TYPE_BK
      , coalesce(nullif(UPPER(trim(LGPLA)), ''), '-1')                      as                                     STORAGE_BIN_BK
      , coalesce(nullif(UPPER(trim(STLNR)), ''), '-1')                      as                                             BOM_BK
      , coalesce(nullif(UPPER(trim(MEINS)), ''), '-1')                      as                                             UOM_BK
      , coalesce(nullif(UPPER(trim(KDAUF)), ''), '-1')                      as                                    ORDER_HEADER_BK
      , IFF(NULLIF(TRIM(KDAUF), '') IS NOT NULL OR NULLIF(TRIM(KDPOS), '') IS NOT NULL, UPPER(CONCAT(KDAUF, '||', KDPOS)), '-1')    as     ORDER_LINE_BK
      , coalesce(nullif(UPPER(trim(SAKNR)), ''), '-1')                      as                               GL_ACCOUNT_NUMBER_BK
      , coalesce(nullif(UPPER(trim(MATNR)), ''), '-1')                      as                                            ITEM_BK
      , coalesce(nullif(UPPER(trim(BAUGR)), ''), '-1')                      as                                    ITEM_ASSEMBLY_BK
      , coalesce(nullif(UPPER(trim(AUFNR)), ''), '-1')                      as                                    PRODUCTION_ORDER_BK
      , RSART                                                               as                         RESERVATION_RECORD_TYPE_DC
      , MANDT
      , RSNUM
      , RSPOS
      , RSART
      , GLREQUEST
      , BDART
      , RSSTA
      , XLOEK
      , XWAOK
      , KZEAR
      , XFEHL
      , MATNR
      , WERKS
      , LGORT
      , PRVBE
      , CHARG
      , PLPLA
      , SOBKZ
      , BDTER
      , BDMNG
      , MEINS
      , SHKZG
      , FMENG
      , ENMNG
      , ENWRT
      , WAERS
      , ERFMG
      , ERFME
      , PLNUM
      , BANFN
      , BNFPO
      , AUFNR
      , BAUGR
      , SERNR
      , KDAUF
      , KDPOS
      , KDEIN
      , PROJN
      , BWART
      , SAKNR
      , GSBER
      , UMWRK
      , UMLGO
      , NAFKZ
      , NOMAT
      , NOMNG
      , POSTP
      , POSNR
      , ROMS1
      , ROMS2
      , ROMS3
      , ROMEI
      , ROMEN
      , SGTXT
      , LMENG
      , ROHPS
      , RFORM
      , ROANZ
      , FLMNG
      , STLTY
      , STLNR
      , STLKN
      , STPOZ
      , LTXSP
      , POTX1
      , POTX2
      , SANKA
      , ALPOS
      , EWAHR
      , AUSCH
      , AVOAU
      , NETAU
      , NLFZT
      , AENNR
      , UMREZ
      , UMREN
      , SORTF
      , SBTER
      , VERTI
      , SCHGT
      , UPSKZ
      , DBSKZ
      , TXTPS
      , DUMPS
      , BEIKZ
      , ERSKZ
      , AUFST
      , AUFWG
      , BAUST
      , BAUWG
      , AUFPS
      , EBELN
      , EBELP
      , EBELE
      , KNTTP
      , KZVBR
      , PSPEL
      , AUFPL
      , PLNFL
      , VORNR
      , APLZL
      , OBJNR
      , FLGAT
      , GPREIS
      , FPREIS
      , PEINH
      , RGEKZ
      , EKGRP
      , ROKME
      , ZUMEI
      , ZUMS1
      , ZUMS2
      , ZUMS3
      , ZUDIV
      , VMENG
      , PRREG
      , LIFZT
      , CUOBJ
      , KFPOS
      , REVLV
      , BERKZ
      , LGNUM
      , LGTYP
      , LGPLA
      , TBMNG
      , NPTXTKY
      , KBNKZ
      , KZKUP
      , AFPOS
      , NO_DISP
      , BDZTP
      , ESMNG
      , ALPGR
      , ALPRF
      , ALPST
      , KZAUS
      , NFEAG
      , NFPKZ
      , NFGRP
      , NFUML
      , ADRNR
      , CHOBJ
      , SPLKZ
      , SPLRV
      , KNUMH
      , WEMPF
      , ABLAD
      , HKMAT
      , HRKFT
      , VORAB
      , MATKL
      , FRUNV
      , CLAKZ
      , INPOS
      , WEBAZ
      , LIFNR
      , FLGEX
      , FUNCT
      , GPREIS_2
      , FPREIS_2
      , PEINH_2
      , INFNR
      , KZECH
      , KZMPF
      , STLAL
      , PBDNR
      , STVKN
      , KTOMA
      , VRPLA
      , KZBWS
      , NLFZV
      , NLFMV
      , TECHS
      , OBJTYPE
      , CH_PROC
      , FXPRU
      , UMSOK
      , VORAB_SM
      , FIPOS
      , FIPEX
      , FISTL
      , GEBER
      , GRANT_NBR
      , FKBER
      , PRIO_URG
      , PRIO_REQ
      , KBLNR
      , KBLPOS
      , BUDGET_PD
      , SC_OBJECT_ID
      , SC_ITM_NO
      , SGT_SCAT
      , SGT_RCAT
      , FMFGUS_KEY
      , ADVCODE
      , FSH_RALLOC_QTY
      , FSH_CRITICAL_COMP
      , FSH_CRITICAL_LEVEL
      , WTY_IND
      , R_PART_INDICATOR
      , WTYSC_CLMITEM
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,
            TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
            )
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
        RESERVATION_BK
      , RESERVATION_LINE_BK
      , PLANT_BK
      , PLANNED_ORDER_BK
      , PURCHASE_REQUISITION_BK
      , PURCHASE_REQUISITION_ITEM_BK
      , PO_HEADER_BK
      , PO_ITEM_BK
      , PO_LINE_BK
      , ROUTING_BK
      , CHANGE_MASTER_BK
      , GOODS_STORAGE_LOCATION_BK
      , WAREHOUSE_BK
      , STORAGE_TYPE_BK
      , STORAGE_BIN_BK
      , BOM_BK
      , UOM_BK
      , ORDER_HEADER_BK
      , ORDER_LINE_BK
      , GL_ACCOUNT_NUMBER_BK
      , ITEM_BK
      , ITEM_ASSEMBLY_BK
      , PRODUCTION_ORDER_BK
      , RESERVATION_RECORD_TYPE_DC
      , MANDT
      , RSNUM
      , RSPOS
      , RSART
      , GLREQUEST
      , BDART
      , RSSTA
      , XLOEK
      , XWAOK
      , KZEAR
      , XFEHL
      , MATNR
      , WERKS
      , LGORT
      , PRVBE
      , CHARG
      , PLPLA
      , SOBKZ
      , BDTER
      , BDMNG
      , MEINS
      , SHKZG
      , FMENG
      , ENMNG
      , ENWRT
      , WAERS
      , ERFMG
      , ERFME
      , PLNUM
      , BANFN
      , BNFPO
      , AUFNR
      , BAUGR
      , SERNR
      , KDAUF
      , KDPOS
      , KDEIN
      , PROJN
      , BWART
      , SAKNR
      , GSBER
      , UMWRK
      , UMLGO
      , NAFKZ
      , NOMAT
      , NOMNG
      , POSTP
      , POSNR
      , ROMS1
      , ROMS2
      , ROMS3
      , ROMEI
      , ROMEN
      , SGTXT
      , LMENG
      , ROHPS
      , RFORM
      , ROANZ
      , FLMNG
      , STLTY
      , STLNR
      , STLKN
      , STPOZ
      , LTXSP
      , POTX1
      , POTX2
      , SANKA
      , ALPOS
      , EWAHR
      , AUSCH
      , AVOAU
      , NETAU
      , NLFZT
      , AENNR
      , UMREZ
      , UMREN
      , SORTF
      , SBTER
      , VERTI
      , SCHGT
      , UPSKZ
      , DBSKZ
      , TXTPS
      , DUMPS
      , BEIKZ
      , ERSKZ
      , AUFST
      , AUFWG
      , BAUST
      , BAUWG
      , AUFPS
      , EBELN
      , EBELP
      , EBELE
      , KNTTP
      , KZVBR
      , PSPEL
      , AUFPL
      , PLNFL
      , VORNR
      , APLZL
      , OBJNR
      , FLGAT
      , GPREIS
      , FPREIS
      , PEINH
      , RGEKZ
      , EKGRP
      , ROKME
      , ZUMEI
      , ZUMS1
      , ZUMS2
      , ZUMS3
      , ZUDIV
      , VMENG
      , PRREG
      , LIFZT
      , CUOBJ
      , KFPOS
      , REVLV
      , BERKZ
      , LGNUM
      , LGTYP
      , LGPLA
      , TBMNG
      , NPTXTKY
      , KBNKZ
      , KZKUP
      , AFPOS
      , NO_DISP
      , BDZTP
      , ESMNG
      , ALPGR
      , ALPRF
      , ALPST
      , KZAUS
      , NFEAG
      , NFPKZ
      , NFGRP
      , NFUML
      , ADRNR
      , CHOBJ
      , SPLKZ
      , SPLRV
      , KNUMH
      , WEMPF
      , ABLAD
      , HKMAT
      , HRKFT
      , VORAB
      , MATKL
      , FRUNV
      , CLAKZ
      , INPOS
      , WEBAZ
      , LIFNR
      , FLGEX
      , FUNCT
      , GPREIS_2
      , FPREIS_2
      , PEINH_2
      , INFNR
      , KZECH
      , KZMPF
      , STLAL
      , PBDNR
      , STVKN
      , KTOMA
      , VRPLA
      , KZBWS
      , NLFZV
      , NLFMV
      , TECHS
      , OBJTYPE
      , CH_PROC
      , FXPRU
      , UMSOK
      , VORAB_SM
      , FIPOS
      , FIPEX
      , FISTL
      , GEBER
      , GRANT_NBR
      , FKBER
      , PRIO_URG
      , PRIO_REQ
      , KBLNR
      , KBLPOS
      , BUDGET_PD
      , SC_OBJECT_ID
      , SC_ITM_NO
      , SGT_SCAT
      , SGT_RCAT
      , FMFGUS_KEY
      , ADVCODE
      , FSH_RALLOC_QTY
      , FSH_CRITICAL_COMP
      , FSH_CRITICAL_LEVEL
      , WTY_IND
      , R_PART_INDICATOR
      , WTYSC_CLMITEM
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_RESB' 
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
          RESERVATION_BK
        , RESERVATION_LINE_BK
        , PLANT_BK
        , PLANNED_ORDER_BK
        , PURCHASE_REQUISITION_BK
        , PURCHASE_REQUISITION_ITEM_BK
        , PO_HEADER_BK
        , PO_ITEM_BK
        , PO_LINE_BK
        , ROUTING_BK
        , CHANGE_MASTER_BK
        , GOODS_STORAGE_LOCATION_BK
        , WAREHOUSE_BK
        , STORAGE_TYPE_BK
        , STORAGE_BIN_BK
        , BOM_BK
        , UOM_BK
        , ORDER_HEADER_BK
        , ORDER_LINE_BK
        , GL_ACCOUNT_NUMBER_BK
        , ITEM_BK
        , ITEM_ASSEMBLY_BK
        , PRODUCTION_ORDER_BK
        , RESERVATION_RECORD_TYPE_DC
        , MANDT
        , RSNUM
        , RSPOS
        , RSART
        , GLREQUEST
        , BDART
        , RSSTA
        , XLOEK
        , XWAOK
        , KZEAR
        , XFEHL
        , MATNR
        , WERKS
        , LGORT
        , PRVBE
        , CHARG
        , PLPLA
        , SOBKZ
        , BDTER
        , BDMNG
        , MEINS
        , SHKZG
        , FMENG
        , ENMNG
        , ENWRT
        , WAERS
        , ERFMG
        , ERFME
        , PLNUM
        , BANFN
        , BNFPO
        , AUFNR
        , BAUGR
        , SERNR
        , KDAUF
        , KDPOS
        , KDEIN
        , PROJN
        , BWART
        , SAKNR
        , GSBER
        , UMWRK
        , UMLGO
        , NAFKZ
        , NOMAT
        , NOMNG
        , POSTP
        , POSNR
        , ROMS1
        , ROMS2
        , ROMS3
        , ROMEI
        , ROMEN
        , SGTXT
        , LMENG
        , ROHPS
        , RFORM
        , ROANZ
        , FLMNG
        , STLTY
        , STLNR
        , STLKN
        , STPOZ
        , LTXSP
        , POTX1
        , POTX2
        , SANKA
        , ALPOS
        , EWAHR
        , AUSCH
        , AVOAU
        , NETAU
        , NLFZT
        , AENNR
        , UMREZ
        , UMREN
        , SORTF
        , SBTER
        , VERTI
        , SCHGT
        , UPSKZ
        , DBSKZ
        , TXTPS
        , DUMPS
        , BEIKZ
        , ERSKZ
        , AUFST
        , AUFWG
        , BAUST
        , BAUWG
        , AUFPS
        , EBELN
        , EBELP
        , EBELE
        , KNTTP
        , KZVBR
        , PSPEL
        , AUFPL
        , PLNFL
        , VORNR
        , APLZL
        , OBJNR
        , FLGAT
        , GPREIS
        , FPREIS
        , PEINH
        , RGEKZ
        , EKGRP
        , ROKME
        , ZUMEI
        , ZUMS1
        , ZUMS2
        , ZUMS3
        , ZUDIV
        , VMENG
        , PRREG
        , LIFZT
        , CUOBJ
        , KFPOS
        , REVLV
        , BERKZ
        , LGNUM
        , LGTYP
        , LGPLA
        , TBMNG
        , NPTXTKY
        , KBNKZ
        , KZKUP
        , AFPOS
        , NO_DISP
        , BDZTP
        , ESMNG
        , ALPGR
        , ALPRF
        , ALPST
        , KZAUS
        , NFEAG
        , NFPKZ
        , NFGRP
        , NFUML
        , ADRNR
        , CHOBJ
        , SPLKZ
        , SPLRV
        , KNUMH
        , WEMPF
        , ABLAD
        , HKMAT
        , HRKFT
        , VORAB
        , MATKL
        , FRUNV
        , CLAKZ
        , INPOS
        , WEBAZ
        , LIFNR
        , FLGEX
        , FUNCT
        , GPREIS_2
        , FPREIS_2
        , PEINH_2
        , INFNR
        , KZECH
        , KZMPF
        , STLAL
        , PBDNR
        , STVKN
        , KTOMA
        , VRPLA
        , KZBWS
        , NLFZV
        , NLFMV
        , TECHS
        , OBJTYPE
        , CH_PROC
        , FXPRU
        , UMSOK
        , VORAB_SM
        , FIPOS
        , FIPEX
        , FISTL
        , GEBER
        , GRANT_NBR
        , FKBER
        , PRIO_URG
        , PRIO_REQ
        , KBLNR
        , KBLPOS
        , BUDGET_PD
        , SC_OBJECT_ID
        , SC_ITM_NO
        , SGT_SCAT
        , SGT_RCAT
        , FMFGUS_KEY
        , ADVCODE
        , FSH_RALLOC_QTY
        , FSH_CRITICAL_COMP
        , FSH_CRITICAL_LEVEL
        , WTY_IND
        , R_PART_INDICATOR
        , WTYSC_CLMITEM
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
            COALESCE(NULLIF(TRIM(CAST(RESERVATION_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS RESERVATION_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(RESERVATION_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(RESERVATION_LINE_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS RESERVATION_LINE_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(PLANT_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS PLANT_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(PLANNED_ORDER_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS PLANNED_ORDER_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(PURCHASE_REQUISITION_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS PURCHASE_REQUISITION_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(PURCHASE_REQUISITION_ITEM_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS PURCHASE_REQUISITION_ITEM_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(PO_HEADER_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS PO_HEADER_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(PO_ITEM_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS PO_ITEM_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(PO_LINE_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS PO_LINE_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(ROUTING_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS ROUTING_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(CHANGE_MASTER_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS CHANGE_MASTER_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(GOODS_STORAGE_LOCATION_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS GOODS_STORAGE_LOCATION_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(WAREHOUSE_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS WAREHOUSE_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(STORAGE_TYPE_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS STORAGE_TYPE_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(STORAGE_BIN_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS STORAGE_BIN_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(BOM_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS BOM_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(UOM_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS UOM_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS ORDER_HEADER_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(ORDER_LINE_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS ORDER_LINE_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(GL_ACCOUNT_NUMBER_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS GL_ACCOUNT_NUMBER_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(ITEM_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS ITEM_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(ITEM_ASSEMBLY_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS ITEM_ASSEMBLY_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(PRODUCTION_ORDER_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS PRODUCTION_ORDER_HK,
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(PLANT_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(ITEM_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(ITEM_ASSEMBLY_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(PURCHASE_REQUISITION_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(PURCHASE_REQUISITION_ITEM_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(PO_HEADER_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(PO_ITEM_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(PO_LINE_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(CHANGE_MASTER_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(GOODS_STORAGE_LOCATION_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(WAREHOUSE_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(STORAGE_TYPE_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(STORAGE_BIN_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BOM_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(UOM_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(ROUTING_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(PLANNED_ORDER_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(ORDER_LINE_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(RESERVATION_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(RESERVATION_LINE_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(GL_ACCOUNT_NUMBER_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(PRODUCTION_ORDER_BK AS VARCHAR)), ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS LNK_DEPENDENCY_RESERVATION_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(RSNUM::text), '^^') 
            , '||', IFNULL(TRIM(RSPOS::text), '^^') 
            , '||', IFNULL(TRIM(RSART::text), '^^') 
            , '||', IFNULL(TRIM(BDART::text), '^^') 
            , '||', IFNULL(TRIM(RSSTA::text), '^^') 
            , '||', IFNULL(TRIM(XLOEK::text), '^^') 
            , '||', IFNULL(TRIM(XWAOK::text), '^^') 
            , '||', IFNULL(TRIM(KZEAR::text), '^^') 
            , '||', IFNULL(TRIM(XFEHL::text), '^^') 
            , '||', IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(LGORT::text), '^^') 
            , '||', IFNULL(TRIM(PRVBE::text), '^^') 
            , '||', IFNULL(TRIM(CHARG::text), '^^') 
            , '||', IFNULL(TRIM(PLPLA::text), '^^') 
            , '||', IFNULL(TRIM(SOBKZ::text), '^^') 
            , '||', IFNULL(TRIM(BDTER::text), '^^') 
            , '||', IFNULL(TRIM(BDMNG::text), '^^') 
            , '||', IFNULL(TRIM(MEINS::text), '^^') 
            , '||', IFNULL(TRIM(SHKZG::text), '^^') 
            , '||', IFNULL(TRIM(FMENG::text), '^^') 
            , '||', IFNULL(TRIM(ENMNG::text), '^^') 
            , '||', IFNULL(TRIM(ENWRT::text), '^^') 
            , '||', IFNULL(TRIM(WAERS::text), '^^') 
            , '||', IFNULL(TRIM(ERFMG::text), '^^') 
            , '||', IFNULL(TRIM(ERFME::text), '^^') 
            , '||', IFNULL(TRIM(PLNUM::text), '^^') 
            , '||', IFNULL(TRIM(BANFN::text), '^^') 
            , '||', IFNULL(TRIM(BNFPO::text), '^^') 
            , '||', IFNULL(TRIM(AUFNR::text), '^^') 
            , '||', IFNULL(TRIM(BAUGR::text), '^^') 
            , '||', IFNULL(TRIM(SERNR::text), '^^') 
            , '||', IFNULL(TRIM(KDAUF::text), '^^') 
            , '||', IFNULL(TRIM(KDPOS::text), '^^') 
            , '||', IFNULL(TRIM(KDEIN::text), '^^') 
            , '||', IFNULL(TRIM(PROJN::text), '^^') 
            , '||', IFNULL(TRIM(BWART::text), '^^') 
            , '||', IFNULL(TRIM(SAKNR::text), '^^') 
            , '||', IFNULL(TRIM(GSBER::text), '^^') 
            , '||', IFNULL(TRIM(UMWRK::text), '^^') 
            , '||', IFNULL(TRIM(UMLGO::text), '^^') 
            , '||', IFNULL(TRIM(NAFKZ::text), '^^') 
            , '||', IFNULL(TRIM(NOMAT::text), '^^') 
            , '||', IFNULL(TRIM(NOMNG::text), '^^') 
            , '||', IFNULL(TRIM(POSTP::text), '^^') 
            , '||', IFNULL(TRIM(POSNR::text), '^^') 
            , '||', IFNULL(TRIM(ROMS1::text), '^^') 
            , '||', IFNULL(TRIM(ROMS2::text), '^^') 
            , '||', IFNULL(TRIM(ROMS3::text), '^^') 
            , '||', IFNULL(TRIM(ROMEI::text), '^^') 
            , '||', IFNULL(TRIM(ROMEN::text), '^^') 
            , '||', IFNULL(TRIM(SGTXT::text), '^^') 
            , '||', IFNULL(TRIM(LMENG::text), '^^') 
            , '||', IFNULL(TRIM(ROHPS::text), '^^') 
            , '||', IFNULL(TRIM(RFORM::text), '^^') 
            , '||', IFNULL(TRIM(ROANZ::text), '^^') 
            , '||', IFNULL(TRIM(FLMNG::text), '^^') 
            , '||', IFNULL(TRIM(STLTY::text), '^^') 
            , '||', IFNULL(TRIM(STLNR::text), '^^') 
            , '||', IFNULL(TRIM(STLKN::text), '^^') 
            , '||', IFNULL(TRIM(STPOZ::text), '^^') 
            , '||', IFNULL(TRIM(LTXSP::text), '^^') 
            , '||', IFNULL(TRIM(POTX1::text), '^^') 
            , '||', IFNULL(TRIM(POTX2::text), '^^') 
            , '||', IFNULL(TRIM(SANKA::text), '^^') 
            , '||', IFNULL(TRIM(ALPOS::text), '^^') 
            , '||', IFNULL(TRIM(EWAHR::text), '^^') 
            , '||', IFNULL(TRIM(AUSCH::text), '^^') 
            , '||', IFNULL(TRIM(AVOAU::text), '^^') 
            , '||', IFNULL(TRIM(NETAU::text), '^^') 
            , '||', IFNULL(TRIM(NLFZT::text), '^^') 
            , '||', IFNULL(TRIM(AENNR::text), '^^') 
            , '||', IFNULL(TRIM(UMREZ::text), '^^') 
            , '||', IFNULL(TRIM(UMREN::text), '^^') 
            , '||', IFNULL(TRIM(SORTF::text), '^^') 
            , '||', IFNULL(TRIM(SBTER::text), '^^') 
            , '||', IFNULL(TRIM(VERTI::text), '^^') 
            , '||', IFNULL(TRIM(SCHGT::text), '^^') 
            , '||', IFNULL(TRIM(UPSKZ::text), '^^') 
            , '||', IFNULL(TRIM(DBSKZ::text), '^^') 
            , '||', IFNULL(TRIM(TXTPS::text), '^^') 
            , '||', IFNULL(TRIM(DUMPS::text), '^^') 
            , '||', IFNULL(TRIM(BEIKZ::text), '^^') 
            , '||', IFNULL(TRIM(ERSKZ::text), '^^') 
            , '||', IFNULL(TRIM(AUFST::text), '^^') 
            , '||', IFNULL(TRIM(AUFWG::text), '^^') 
            , '||', IFNULL(TRIM(BAUST::text), '^^') 
            , '||', IFNULL(TRIM(BAUWG::text), '^^') 
            , '||', IFNULL(TRIM(AUFPS::text), '^^') 
            , '||', IFNULL(TRIM(EBELN::text), '^^') 
            , '||', IFNULL(TRIM(EBELP::text), '^^') 
            , '||', IFNULL(TRIM(EBELE::text), '^^') 
            , '||', IFNULL(TRIM(KNTTP::text), '^^') 
            , '||', IFNULL(TRIM(KZVBR::text), '^^') 
            , '||', IFNULL(TRIM(PSPEL::text), '^^') 
            , '||', IFNULL(TRIM(AUFPL::text), '^^') 
            , '||', IFNULL(TRIM(PLNFL::text), '^^') 
            , '||', IFNULL(TRIM(VORNR::text), '^^') 
            , '||', IFNULL(TRIM(APLZL::text), '^^') 
            , '||', IFNULL(TRIM(OBJNR::text), '^^') 
            , '||', IFNULL(TRIM(FLGAT::text), '^^') 
            , '||', IFNULL(TRIM(GPREIS::text), '^^') 
            , '||', IFNULL(TRIM(FPREIS::text), '^^') 
            , '||', IFNULL(TRIM(PEINH::text), '^^') 
            , '||', IFNULL(TRIM(RGEKZ::text), '^^') 
            , '||', IFNULL(TRIM(EKGRP::text), '^^') 
            , '||', IFNULL(TRIM(ROKME::text), '^^') 
            , '||', IFNULL(TRIM(ZUMEI::text), '^^') 
            , '||', IFNULL(TRIM(ZUMS1::text), '^^') 
            , '||', IFNULL(TRIM(ZUMS2::text), '^^') 
            , '||', IFNULL(TRIM(ZUMS3::text), '^^') 
            , '||', IFNULL(TRIM(ZUDIV::text), '^^') 
            , '||', IFNULL(TRIM(VMENG::text), '^^') 
            , '||', IFNULL(TRIM(PRREG::text), '^^') 
            , '||', IFNULL(TRIM(LIFZT::text), '^^') 
            , '||', IFNULL(TRIM(CUOBJ::text), '^^') 
            , '||', IFNULL(TRIM(KFPOS::text), '^^') 
            , '||', IFNULL(TRIM(REVLV::text), '^^') 
            , '||', IFNULL(TRIM(BERKZ::text), '^^') 
            , '||', IFNULL(TRIM(LGNUM::text), '^^') 
            , '||', IFNULL(TRIM(LGTYP::text), '^^') 
            , '||', IFNULL(TRIM(LGPLA::text), '^^') 
            , '||', IFNULL(TRIM(TBMNG::text), '^^') 
            , '||', IFNULL(TRIM(NPTXTKY::text), '^^') 
            , '||', IFNULL(TRIM(KBNKZ::text), '^^') 
            , '||', IFNULL(TRIM(KZKUP::text), '^^') 
            , '||', IFNULL(TRIM(AFPOS::text), '^^') 
            , '||', IFNULL(TRIM(NO_DISP::text), '^^') 
            , '||', IFNULL(TRIM(BDZTP::text), '^^') 
            , '||', IFNULL(TRIM(ESMNG::text), '^^') 
            , '||', IFNULL(TRIM(ALPGR::text), '^^') 
            , '||', IFNULL(TRIM(ALPRF::text), '^^') 
            , '||', IFNULL(TRIM(ALPST::text), '^^') 
            , '||', IFNULL(TRIM(KZAUS::text), '^^') 
            , '||', IFNULL(TRIM(NFEAG::text), '^^') 
            , '||', IFNULL(TRIM(NFPKZ::text), '^^') 
            , '||', IFNULL(TRIM(NFGRP::text), '^^') 
            , '||', IFNULL(TRIM(NFUML::text), '^^') 
            , '||', IFNULL(TRIM(ADRNR::text), '^^') 
            , '||', IFNULL(TRIM(CHOBJ::text), '^^') 
            , '||', IFNULL(TRIM(SPLKZ::text), '^^') 
            , '||', IFNULL(TRIM(SPLRV::text), '^^') 
            , '||', IFNULL(TRIM(KNUMH::text), '^^') 
            , '||', IFNULL(TRIM(WEMPF::text), '^^') 
            , '||', IFNULL(TRIM(ABLAD::text), '^^') 
            , '||', IFNULL(TRIM(HKMAT::text), '^^') 
            , '||', IFNULL(TRIM(HRKFT::text), '^^') 
            , '||', IFNULL(TRIM(VORAB::text), '^^') 
            , '||', IFNULL(TRIM(MATKL::text), '^^') 
            , '||', IFNULL(TRIM(FRUNV::text), '^^') 
            , '||', IFNULL(TRIM(CLAKZ::text), '^^') 
            , '||', IFNULL(TRIM(INPOS::text), '^^') 
            , '||', IFNULL(TRIM(WEBAZ::text), '^^') 
            , '||', IFNULL(TRIM(LIFNR::text), '^^') 
            , '||', IFNULL(TRIM(FLGEX::text), '^^') 
            , '||', IFNULL(TRIM(FUNCT::text), '^^') 
            , '||', IFNULL(TRIM(GPREIS_2::text), '^^') 
            , '||', IFNULL(TRIM(FPREIS_2::text), '^^') 
            , '||', IFNULL(TRIM(PEINH_2::text), '^^') 
            , '||', IFNULL(TRIM(INFNR::text), '^^') 
            , '||', IFNULL(TRIM(KZECH::text), '^^') 
            , '||', IFNULL(TRIM(KZMPF::text), '^^') 
            , '||', IFNULL(TRIM(STLAL::text), '^^') 
            , '||', IFNULL(TRIM(PBDNR::text), '^^') 
            , '||', IFNULL(TRIM(STVKN::text), '^^') 
            , '||', IFNULL(TRIM(KTOMA::text), '^^') 
            , '||', IFNULL(TRIM(VRPLA::text), '^^') 
            , '||', IFNULL(TRIM(KZBWS::text), '^^') 
            , '||', IFNULL(TRIM(NLFZV::text), '^^') 
            , '||', IFNULL(TRIM(NLFMV::text), '^^') 
            , '||', IFNULL(TRIM(TECHS::text), '^^') 
            , '||', IFNULL(TRIM(OBJTYPE::text), '^^') 
            , '||', IFNULL(TRIM(CH_PROC::text), '^^') 
            , '||', IFNULL(TRIM(FXPRU::text), '^^') 
            , '||', IFNULL(TRIM(UMSOK::text), '^^') 
            , '||', IFNULL(TRIM(VORAB_SM::text), '^^') 
            , '||', IFNULL(TRIM(FIPOS::text), '^^') 
            , '||', IFNULL(TRIM(FIPEX::text), '^^') 
            , '||', IFNULL(TRIM(FISTL::text), '^^') 
            , '||', IFNULL(TRIM(GEBER::text), '^^') 
            , '||', IFNULL(TRIM(GRANT_NBR::text), '^^') 
            , '||', IFNULL(TRIM(FKBER::text), '^^') 
            , '||', IFNULL(TRIM(PRIO_URG::text), '^^') 
            , '||', IFNULL(TRIM(PRIO_REQ::text), '^^') 
            , '||', IFNULL(TRIM(KBLNR::text), '^^') 
            , '||', IFNULL(TRIM(KBLPOS::text), '^^') 
            , '||', IFNULL(TRIM(BUDGET_PD::text), '^^') 
            , '||', IFNULL(TRIM(SC_OBJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(SC_ITM_NO::text), '^^') 
            , '||', IFNULL(TRIM(SGT_SCAT::text), '^^') 
            , '||', IFNULL(TRIM(SGT_RCAT::text), '^^') 
            , '||', IFNULL(TRIM(FMFGUS_KEY::text), '^^') 
            , '||', IFNULL(TRIM(ADVCODE::text), '^^') 
            , '||', IFNULL(TRIM(FSH_RALLOC_QTY::text), '^^') 
            , '||', IFNULL(TRIM(FSH_CRITICAL_COMP::text), '^^') 
            , '||', IFNULL(TRIM(FSH_CRITICAL_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(WTY_IND::text), '^^') 
            , '||', IFNULL(TRIM(R_PART_INDICATOR::text), '^^') 
            , '||', IFNULL(TRIM(WTYSC_CLMITEM::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT