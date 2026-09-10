---- SRC LAYER ----
WITH
SRC_a              as ( SELECT ABLAD, ABLAND1, ABORT01, ABPSTLZ, ADRKNZA, ADRKNZZ, ADRNA, ADRNZ, AEDAT, AENAM, AEZET, ARSTA, BELAD, CONT_DG, DATBG, DATEN, DISTZ, DPTBG, DPTEN, EDLAND1, EDORT01, EDPSTLZ, ELUPD, ERDAT, ERNAM, ERZET, FAHZT, FAHZTD, FAHZTDA, FBSTA, FRKRL, GESZT, GESZTD, GESZTDA, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, INCO1, KNOTA, KNOTZ, KUNABLA, KUNABLZ, KUNNA, KUNNZ, LAUFK, LGNUMA, LGNUMZ, LGORTA, LGORTZ, LIFNA, LIFNZ, LSTEL, LSTEZ, MANDT, MEDST, MEIZT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, ROUTE, SDABW, SKALSM, STAFO, TDLNR, TKNUM, TORA, TORZ, TSNUM, TSRFO, TSTYP, UATBG, UATEN, UPTBG, UPTEN, VSART, VSTEL, VSTEZ, WARZTD, WARZTDA, WERKA, WERKZ FROM {{ source('sap_ecc_prd', 'z_vtts') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_vtts )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        MANDT
      , TKNUM
      , TSNUM
      , GLREQUEST
      , TSTYP
      , TSRFO
      , ELUPD
      , ERNAM
      , ERDAT
      , ERZET
      , AENAM
      , AEDAT
      , AEZET
      , ROUTE
      , VSART
      , INCO1
      , LAUFK
      , ADRNA
      , KNOTA
      , VSTEL
      , LSTEL
      , WERKA
      , LGORTA
      , KUNNA
      , LIFNA
      , BELAD
      , ADRNZ
      , KNOTZ
      , VSTEZ
      , LSTEZ
      , WERKZ
      , LGORTZ
      , KUNNZ
      , LIFNZ
      , ABLAD
      , DPTBG
      , UPTBG
      , DATBG
      , UATBG
      , DPTEN
      , UPTEN
      , DATEN
      , UATEN
      , TDLNR
      , DISTZ
      , MEDST
      , FAHZT
      , GESZT
      , MEIZT
      , LGNUMA
      , TORA
      , ADRKNZA
      , KUNABLA
      , LGNUMZ
      , TORZ
      , ADRKNZZ
      , KUNABLZ
      , GESZTD
      , FAHZTD
      , GESZTDA
      , FAHZTDA
      , SDABW
      , FRKRL
      , SKALSM
      , FBSTA
      , ARSTA
      , STAFO
      , CONT_DG
      , WARZTD
      , WARZTDA
      , ABLAND1
      , ABPSTLZ
      , ABORT01
      , EDLAND1
      , EDPSTLZ
      , EDORT01
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , TKNUM                                                        as                              LOGISTICS_SHIPMENT_BK
      , IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,
            CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
            ))
        )                                                            as                                           LOAD_DTS
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
        MANDT
      , TKNUM
      , TSNUM
      , GLREQUEST
      , TSTYP
      , TSRFO
      , ELUPD
      , ERNAM
      , ERDAT
      , ERZET
      , AENAM
      , AEDAT
      , AEZET
      , ROUTE
      , VSART
      , INCO1
      , LAUFK
      , ADRNA
      , KNOTA
      , VSTEL
      , LSTEL
      , WERKA
      , LGORTA
      , KUNNA
      , LIFNA
      , BELAD
      , ADRNZ
      , KNOTZ
      , VSTEZ
      , LSTEZ
      , WERKZ
      , LGORTZ
      , KUNNZ
      , LIFNZ
      , ABLAD
      , DPTBG
      , UPTBG
      , DATBG
      , UATBG
      , DPTEN
      , UPTEN
      , DATEN
      , UATEN
      , TDLNR
      , DISTZ
      , MEDST
      , FAHZT
      , GESZT
      , MEIZT
      , LGNUMA
      , TORA
      , ADRKNZA
      , KUNABLA
      , LGNUMZ
      , TORZ
      , ADRKNZZ
      , KUNABLZ
      , GESZTD
      , FAHZTD
      , GESZTDA
      , FAHZTDA
      , SDABW
      , FRKRL
      , SKALSM
      , FBSTA
      , ARSTA
      , STAFO
      , CONT_DG
      , WARZTD
      , WARZTDA
      , ABLAND1
      , ABPSTLZ
      , ABORT01
      , EDLAND1
      , EDPSTLZ
      , EDORT01
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOGISTICS_SHIPMENT_BK
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_VTTS'
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
          MANDT
        , TKNUM
        , TSNUM
        , GLREQUEST
        , TSTYP
        , TSRFO
        , ELUPD
        , ERNAM
        , ERDAT
        , ERZET
        , AENAM
        , AEDAT
        , AEZET
        , ROUTE
        , VSART
        , INCO1
        , LAUFK
        , ADRNA
        , KNOTA
        , VSTEL
        , LSTEL
        , WERKA
        , LGORTA
        , KUNNA
        , LIFNA
        , BELAD
        , ADRNZ
        , KNOTZ
        , VSTEZ
        , LSTEZ
        , WERKZ
        , LGORTZ
        , KUNNZ
        , LIFNZ
        , ABLAD
        , DPTBG
        , UPTBG
        , DATBG
        , UATBG
        , DPTEN
        , UPTEN
        , DATEN
        , UATEN
        , TDLNR
        , DISTZ
        , MEDST
        , FAHZT
        , GESZT
        , MEIZT
        , LGNUMA
        , TORA
        , ADRKNZA
        , KUNABLA
        , LGNUMZ
        , TORZ
        , ADRKNZZ
        , KUNABLZ
        , GESZTD
        , FAHZTD
        , GESZTDA
        , FAHZTDA
        , SDABW
        , FRKRL
        , SKALSM
        , FBSTA
        , ARSTA
        , STAFO
        , CONT_DG
        , WARZTD
        , WARZTDA
        , ABLAND1
        , ABPSTLZ
        , ABORT01
        , EDLAND1
        , EDPSTLZ
        , EDORT01
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , LOGISTICS_SHIPMENT_BK
        , LOAD_DTS
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LOGISTICS_SHIPMENT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LOGISTICS_SHIPMENT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(TSNUM::text), '^^') 
            , '||', IFNULL(TRIM(TSTYP::text), '^^') 
            , '||', IFNULL(TRIM(TSRFO::text), '^^') 
            , '||', IFNULL(TRIM(ELUPD::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(ERZET::text), '^^') 
            , '||', IFNULL(TRIM(AENAM::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(AEZET::text), '^^') 
            , '||', IFNULL(TRIM(ROUTE::text), '^^') 
            , '||', IFNULL(TRIM(VSART::text), '^^') 
            , '||', IFNULL(TRIM(INCO1::text), '^^') 
            , '||', IFNULL(TRIM(LAUFK::text), '^^') 
            , '||', IFNULL(TRIM(ADRNA::text), '^^') 
            , '||', IFNULL(TRIM(KNOTA::text), '^^') 
            , '||', IFNULL(TRIM(VSTEL::text), '^^') 
            , '||', IFNULL(TRIM(LSTEL::text), '^^') 
            , '||', IFNULL(TRIM(WERKA::text), '^^') 
            , '||', IFNULL(TRIM(LGORTA::text), '^^') 
            , '||', IFNULL(TRIM(KUNNA::text), '^^') 
            , '||', IFNULL(TRIM(LIFNA::text), '^^') 
            , '||', IFNULL(TRIM(BELAD::text), '^^') 
            , '||', IFNULL(TRIM(ADRNZ::text), '^^') 
            , '||', IFNULL(TRIM(KNOTZ::text), '^^') 
            , '||', IFNULL(TRIM(VSTEZ::text), '^^') 
            , '||', IFNULL(TRIM(LSTEZ::text), '^^') 
            , '||', IFNULL(TRIM(WERKZ::text), '^^') 
            , '||', IFNULL(TRIM(LGORTZ::text), '^^') 
            , '||', IFNULL(TRIM(KUNNZ::text), '^^') 
            , '||', IFNULL(TRIM(LIFNZ::text), '^^') 
            , '||', IFNULL(TRIM(ABLAD::text), '^^') 
            , '||', IFNULL(TRIM(DPTBG::text), '^^') 
            , '||', IFNULL(TRIM(UPTBG::text), '^^') 
            , '||', IFNULL(TRIM(DATBG::text), '^^') 
            , '||', IFNULL(TRIM(UATBG::text), '^^') 
            , '||', IFNULL(TRIM(DPTEN::text), '^^') 
            , '||', IFNULL(TRIM(UPTEN::text), '^^') 
            , '||', IFNULL(TRIM(DATEN::text), '^^') 
            , '||', IFNULL(TRIM(UATEN::text), '^^') 
            , '||', IFNULL(TRIM(TDLNR::text), '^^') 
            , '||', IFNULL(TRIM(DISTZ::text), '^^') 
            , '||', IFNULL(TRIM(MEDST::text), '^^') 
            , '||', IFNULL(TRIM(FAHZT::text), '^^') 
            , '||', IFNULL(TRIM(GESZT::text), '^^') 
            , '||', IFNULL(TRIM(MEIZT::text), '^^') 
            , '||', IFNULL(TRIM(LGNUMA::text), '^^') 
            , '||', IFNULL(TRIM(TORA::text), '^^') 
            , '||', IFNULL(TRIM(ADRKNZA::text), '^^') 
            , '||', IFNULL(TRIM(KUNABLA::text), '^^') 
            , '||', IFNULL(TRIM(LGNUMZ::text), '^^') 
            , '||', IFNULL(TRIM(TORZ::text), '^^') 
            , '||', IFNULL(TRIM(ADRKNZZ::text), '^^') 
            , '||', IFNULL(TRIM(KUNABLZ::text), '^^') 
            , '||', IFNULL(TRIM(GESZTD::text), '^^') 
            , '||', IFNULL(TRIM(FAHZTD::text), '^^') 
            , '||', IFNULL(TRIM(GESZTDA::text), '^^') 
            , '||', IFNULL(TRIM(FAHZTDA::text), '^^') 
            , '||', IFNULL(TRIM(SDABW::text), '^^') 
            , '||', IFNULL(TRIM(FRKRL::text), '^^') 
            , '||', IFNULL(TRIM(SKALSM::text), '^^') 
            , '||', IFNULL(TRIM(FBSTA::text), '^^') 
            , '||', IFNULL(TRIM(ARSTA::text), '^^') 
            , '||', IFNULL(TRIM(STAFO::text), '^^') 
            , '||', IFNULL(TRIM(CONT_DG::text), '^^') 
            , '||', IFNULL(TRIM(WARZTD::text), '^^') 
            , '||', IFNULL(TRIM(WARZTDA::text), '^^') 
            , '||', IFNULL(TRIM(ABLAND1::text), '^^') 
            , '||', IFNULL(TRIM(ABPSTLZ::text), '^^') 
            , '||', IFNULL(TRIM(ABORT01::text), '^^') 
            , '||', IFNULL(TRIM(EDLAND1::text), '^^') 
            , '||', IFNULL(TRIM(EDPSTLZ::text), '^^') 
            , '||', IFNULL(TRIM(EDORT01::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
