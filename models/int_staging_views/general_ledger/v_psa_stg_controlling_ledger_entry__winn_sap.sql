---- SRC LAYER ----
WITH
SRC_c              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_coep') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_c              as ( SELECT * FROM sap_ecc_prd.z_coep )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_c as (
    SELECT
            CONVERT_TIMEZONE('UTC', IFF(
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
      , to_char(coalesce(KOKRS,'-1'))                                as                                CONTROLLING_AREA_BK
      , to_char(coalesce(BELNR,'-1'))                                as                       CONTROLLING_LEDGER_HEADER_BK
      , to_char(coalesce(BUZEI,'-1'))                                as                                     POSTING_ROW_BK
      , to_char(coalesce(KSTAR,'-1'))                                as                                    COST_ELEMENT_BK
      , to_char(coalesce(LEDNR,'-1'))                                as                                          LEDGER_BK
      , MANDT
      , KOKRS
      , BELNR
      , BUZEI
      , GLREQUEST
      , PERIO
      , WTGBTR
      , WOGBTR
      , WKGBTR
      , WKFBTR
      , PAGBTR
      , PAFBTR
      , MEGBTR
      , MEFBTR
      , MBGBTR
      , MBFBTR
      , LEDNR
      , OBJNR
      , GJAHR
      , WRTTP
      , VERSN
      , KSTAR
      , HRKFT
      , VRGNG
      , PAROB
      , PAROB1
      , USPOB
      , VBUND
      , PARGB
      , BEKNZ
      , TWAER
      , OWAER
      , MEINH
      , MEINB
      , MVFLG
      , SGTXT
      , REFBZ
      , ZLENR
      , BW_REFBZ
      , GKONT
      , GKOAR
      , WERKS
      , MATNR
      , RBEST
      , EBELN
      , EBELP
      , ZEKKN
      , ERLKZ
      , PERNR
      , BTRKL
      , OBJNR_N1
      , OBJNR_N2
      , OBJNR_N3
      , PAOBJNR
      , BELTP
      , BUKRS
      , GSBER
      , FKBER
      , SCOPE
      , LOGSYSO
      , PKSTAR
      , PBUKRS
      , PFKBER
      , PSCOPE
      , LOGSYSP
      , DABRZ
      , BWSTRAT
      , OBJNR_HK
      , TIMESTMP
      , QMNUM
      , GEBER
      , PGEBER
      , GRANT_NBR
      , PGRANT_NBR
      , REFBZ_FI
      , SEGMENT
      , PSEGMENT
      , BUDGET_PD
      , PBUDGET_PD
      , PRODPER
      , ZZALTKT
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
        ))                                                           as                                  GLCHANGETIME_DTTM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
    FROM SRC_c
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_c as (
    SELECT
        LOAD_DTS
      , CONTROLLING_AREA_BK
      , CONTROLLING_LEDGER_HEADER_BK
      , POSTING_ROW_BK
      , COST_ELEMENT_BK
      , LEDGER_BK
      , MANDT
      , KOKRS
      , BELNR
      , BUZEI
      , GLREQUEST
      , PERIO
      , WTGBTR
      , WOGBTR
      , WKGBTR
      , WKFBTR
      , PAGBTR
      , PAFBTR
      , MEGBTR
      , MEFBTR
      , MBGBTR
      , MBFBTR
      , LEDNR
      , OBJNR
      , GJAHR
      , WRTTP
      , VERSN
      , KSTAR
      , HRKFT
      , VRGNG
      , PAROB
      , PAROB1
      , USPOB
      , VBUND
      , PARGB
      , BEKNZ
      , TWAER
      , OWAER
      , MEINH
      , MEINB
      , MVFLG
      , SGTXT
      , REFBZ
      , ZLENR
      , BW_REFBZ
      , GKONT
      , GKOAR
      , WERKS
      , MATNR
      , RBEST
      , EBELN
      , EBELP
      , ZEKKN
      , ERLKZ
      , PERNR
      , BTRKL
      , OBJNR_N1
      , OBJNR_N2
      , OBJNR_N3
      , PAOBJNR
      , BELTP
      , BUKRS
      , GSBER
      , FKBER
      , SCOPE
      , LOGSYSO
      , PKSTAR
      , PBUKRS
      , PFKBER
      , PSCOPE
      , LOGSYSP
      , DABRZ
      , BWSTRAT
      , OBJNR_HK
      , TIMESTMP
      , QMNUM
      , GEBER
      , PGEBER
      , GRANT_NBR
      , PGRANT_NBR
      , REFBZ_FI
      , SEGMENT
      , PSEGMENT
      , BUDGET_PD
      , PBUDGET_PD
      , PRODPER
      , ZZALTKT
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , GLCHANGETIME_DTTM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
    FROM LOGIC_c
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_c as (
    SELECT *
    FROM RENAME_c
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_COEP'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_c
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(CONTROLLING_AREA_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(CONTROLLING_LEDGER_HEADER_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(POSTING_ROW_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(COST_ELEMENT_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                        CONTROLLING_LEDGER_ENTRY_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(CONTROLLING_AREA_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(CONTROLLING_LEDGER_HEADER_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(POSTING_ROW_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                          COST_OBJECT_LINE_ITEMS_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
              COALESCE(NULLIF(TRIM(CAST(CONTROLLING_AREA_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(CONTROLLING_LEDGER_HEADER_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                         CONTROLLING_HEADER_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
              COALESCE(NULLIF(TRIM(CAST(CONTROLLING_AREA_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                         CONTROLLING_AREA_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(CONTROLLING_LEDGER_HEADER_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                       CONTROLLING_LEDGER_HEADER_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(POSTING_ROW_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                     POSTING_ROW_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(COST_ELEMENT_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                    COST_ELEMENT_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(LEDGER_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                    LEDGER_HK
        , LOAD_DTS
        , CONTROLLING_AREA_BK
        , CONTROLLING_LEDGER_HEADER_BK
        , POSTING_ROW_BK
        , COST_ELEMENT_BK
        , LEDGER_BK
        , MANDT
        , KOKRS
        , BELNR
        , BUZEI
        , GLREQUEST
        , PERIO
        , WTGBTR
        , WOGBTR
        , WKGBTR
        , WKFBTR
        , PAGBTR
        , PAFBTR
        , MEGBTR
        , MEFBTR
        , MBGBTR
        , MBFBTR
        , LEDNR
        , OBJNR
        , GJAHR
        , WRTTP
        , VERSN
        , KSTAR
        , HRKFT
        , VRGNG
        , PAROB
        , PAROB1
        , USPOB
        , VBUND
        , PARGB
        , BEKNZ
        , TWAER
        , OWAER
        , MEINH
        , MEINB
        , MVFLG
        , SGTXT
        , REFBZ
        , ZLENR
        , BW_REFBZ
        , GKONT
        , GKOAR
        , WERKS
        , MATNR
        , RBEST
        , EBELN
        , EBELP
        , ZEKKN
        , ERLKZ
        , PERNR
        , BTRKL
        , OBJNR_N1
        , OBJNR_N2
        , OBJNR_N3
        , PAOBJNR
        , BELTP
        , BUKRS
        , GSBER
        , FKBER
        , SCOPE
        , LOGSYSO
        , PKSTAR
        , PBUKRS
        , PFKBER
        , PSCOPE
        , LOGSYSP
        , DABRZ
        , BWSTRAT
        , OBJNR_HK
        , TIMESTMP
        , QMNUM
        , GEBER
        , PGEBER
        , GRANT_NBR
        , PGRANT_NBR
        , REFBZ_FI
        , SEGMENT
        , PSEGMENT
        , BUDGET_PD
        , PBUDGET_PD
        , PRODPER
        , ZZALTKT
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , GLCHANGETIME_DTTM
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
      '||', IFNULL(TRIM(MANDT::text), '^^')
    , '||', IFNULL(TRIM(KOKRS::text), '^^')
    , '||', IFNULL(TRIM(BELNR::text), '^^')
    , '||', IFNULL(TRIM(BUZEI::text), '^^')
    , '||', IFNULL(TRIM(GLREQUEST::text), '^^')
    , '||', IFNULL(TRIM(PERIO::text), '^^')
    , '||', IFNULL(TRIM(WTGBTR::text), '^^')
    , '||', IFNULL(TRIM(WOGBTR::text), '^^')
    , '||', IFNULL(TRIM(WKGBTR::text), '^^')
    , '||', IFNULL(TRIM(WKFBTR::text), '^^')
    , '||', IFNULL(TRIM(PAGBTR::text), '^^')
    , '||', IFNULL(TRIM(PAFBTR::text), '^^')
    , '||', IFNULL(TRIM(MEGBTR::text), '^^')
    , '||', IFNULL(TRIM(MEFBTR::text), '^^')
    , '||', IFNULL(TRIM(MBGBTR::text), '^^')
    , '||', IFNULL(TRIM(MBFBTR::text), '^^')
    , '||', IFNULL(TRIM(LEDNR::text), '^^')
    , '||', IFNULL(TRIM(OBJNR::text), '^^')
    , '||', IFNULL(TRIM(GJAHR::text), '^^')
    , '||', IFNULL(TRIM(WRTTP::text), '^^')
    , '||', IFNULL(TRIM(VERSN::text), '^^')
    , '||', IFNULL(TRIM(KSTAR::text), '^^')
    , '||', IFNULL(TRIM(HRKFT::text), '^^')
    , '||', IFNULL(TRIM(VRGNG::text), '^^')
    , '||', IFNULL(TRIM(PAROB::text), '^^')
    , '||', IFNULL(TRIM(PAROB1::text), '^^')
    , '||', IFNULL(TRIM(USPOB::text), '^^')
    , '||', IFNULL(TRIM(VBUND::text), '^^')
    , '||', IFNULL(TRIM(PARGB::text), '^^')
    , '||', IFNULL(TRIM(BEKNZ::text), '^^')
    , '||', IFNULL(TRIM(TWAER::text), '^^')
    , '||', IFNULL(TRIM(OWAER::text), '^^')
    , '||', IFNULL(TRIM(MEINH::text), '^^')
    , '||', IFNULL(TRIM(MEINB::text), '^^')
    , '||', IFNULL(TRIM(MVFLG::text), '^^')
    , '||', IFNULL(TRIM(SGTXT::text), '^^')
    , '||', IFNULL(TRIM(REFBZ::text), '^^')
    , '||', IFNULL(TRIM(ZLENR::text), '^^')
    , '||', IFNULL(TRIM(BW_REFBZ::text), '^^')
    , '||', IFNULL(TRIM(GKONT::text), '^^')
    , '||', IFNULL(TRIM(GKOAR::text), '^^')
    , '||', IFNULL(TRIM(WERKS::text), '^^')
    , '||', IFNULL(TRIM(MATNR::text), '^^')
    , '||', IFNULL(TRIM(RBEST::text), '^^')
    , '||', IFNULL(TRIM(EBELN::text), '^^')
    , '||', IFNULL(TRIM(EBELP::text), '^^')
    , '||', IFNULL(TRIM(ZEKKN::text), '^^')
    , '||', IFNULL(TRIM(ERLKZ::text), '^^')
    , '||', IFNULL(TRIM(PERNR::text), '^^')
    , '||', IFNULL(TRIM(BTRKL::text), '^^')
    , '||', IFNULL(TRIM(OBJNR_N1::text), '^^')
    , '||', IFNULL(TRIM(OBJNR_N2::text), '^^')
    , '||', IFNULL(TRIM(OBJNR_N3::text), '^^')
    , '||', IFNULL(TRIM(PAOBJNR::text), '^^')
    , '||', IFNULL(TRIM(BELTP::text), '^^')
    , '||', IFNULL(TRIM(BUKRS::text), '^^')
    , '||', IFNULL(TRIM(GSBER::text), '^^')
    , '||', IFNULL(TRIM(FKBER::text), '^^')
    , '||', IFNULL(TRIM(SCOPE::text), '^^')
    , '||', IFNULL(TRIM(LOGSYSO::text), '^^')
    , '||', IFNULL(TRIM(PKSTAR::text), '^^')
    , '||', IFNULL(TRIM(PBUKRS::text), '^^')
    , '||', IFNULL(TRIM(PFKBER::text), '^^')
    , '||', IFNULL(TRIM(PSCOPE::text), '^^')
    , '||', IFNULL(TRIM(LOGSYSP::text), '^^')
    , '||', IFNULL(TRIM(DABRZ::text), '^^')
    , '||', IFNULL(TRIM(BWSTRAT::text), '^^')
    , '||', IFNULL(TRIM(OBJNR_HK::text), '^^')
    , '||', IFNULL(TRIM(TIMESTMP::text), '^^')
    , '||', IFNULL(TRIM(QMNUM::text), '^^')
    , '||', IFNULL(TRIM(GEBER::text), '^^')
    , '||', IFNULL(TRIM(PGEBER::text), '^^')
    , '||', IFNULL(TRIM(GRANT_NBR::text), '^^')
    , '||', IFNULL(TRIM(PGRANT_NBR::text), '^^')
    , '||', IFNULL(TRIM(REFBZ_FI::text), '^^')
    , '||', IFNULL(TRIM(SEGMENT::text), '^^')
    , '||', IFNULL(TRIM(PSEGMENT::text), '^^')
    , '||', IFNULL(TRIM(BUDGET_PD::text), '^^')
    , '||', IFNULL(TRIM(PBUDGET_PD::text), '^^')
    , '||', IFNULL(TRIM(PRODPER::text), '^^')
    , '||', IFNULL(TRIM(ZZALTKT::text), '^^')
    , '||', IFNULL(TRIM(GLDELFLAG::text), '^^')
    , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^')
), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
