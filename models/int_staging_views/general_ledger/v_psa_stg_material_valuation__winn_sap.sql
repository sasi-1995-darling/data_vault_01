---- SRC LAYER ----
WITH
SRC_S              as ( SELECT ABCIW, ABWKZ, BKLAS, BWKEY, BWPEI, BWPH1, BWPRH, BWPRS, BWPS1, BWSPA, BWTAR, BWTTY, BWVA1, BWVA2, BWVA3, EKALR, EKLAS, FBWST, FPLPX, GLCHANGETIME, GLDELFLAG, GLSOURCESYSTEM, HKMAT, HRKFT, KALKL, KALKV, KALKZ, KALN1, KALNR, KALSC, KOSGR, KZIWL, LAEPR, LBKUM, LBWST, LFGJA, LFMON, LPLPR, LPLPX, LVORM, MANDT, MATNR, MBRUE, MLAST, MLMAA, MTORG, MTUSE, MYPOL, OIPPINV, OKLAS, OWNPR, PDATL, PDATV, PDATZ, PEINH, PPERL, PPERV, PPERZ, PPRDL, PPRDV, PPRDZ, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSTAT, QKLAS, SALK3, SALKV, SPERW, STPRS, STPRV, TIMESTAMP, VBWST, VERPR, VERS1, VERS2, VERS3, VJBKL, VJBWH, VJBWS, VJKUM, VJPEI, VJSAL, VJSAV, VJSTP, VJVER, VJVPR, VKSAL, VMBKL, VMKUM, VMPEI, VMSAL, VMSAV, VMSTP, VMVER, VMVPR, VPLPR, VPLPX, VPRSV, VVJLB, VVJSL, VVMLB, VVSAL, WLINL, XBEWM, XLIFO, ZKDAT, ZKPRS, ZPLD1, ZPLD2, ZPLD3, ZPLP1, ZPLP2, ZPLP3, ZPLPR FROM {{ source('sap_ecc_prd', 'z_mbew') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_mbew )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        MANDT 
      , MATNR
      , BWKEY
      , BWTAR
      , LVORM
      , LBKUM
      , SALK3
      , VPRSV
      , VERPR
      , STPRS
      , PEINH
      , BKLAS
      , SALKV
      , VMKUM
      , VMSAL
      , VMVPR
      , VMVER
      , VMSTP
      , VMPEI
      , VMBKL
      , VMSAV
      , VJKUM
      , VJSAL
      , VJVPR
      , VJVER
      , VJSTP
      , VJPEI
      , VJBKL
      , VJSAV
      , LFGJA
      , LFMON
      , BWTTY
      , STPRV
      , LAEPR
      , ZKPRS
      , ZKDAT
      , TIMESTAMP
      , BWPRS
      , BWPRH
      , VJBWS
      , VJBWH
      , VVJSL
      , VVJLB
      , VVMLB
      , VVSAL
      , ZPLPR
      , ZPLP1
      , ZPLP2
      , ZPLP3
      , ZPLD1
      , ZPLD2
      , ZPLD3
      , PPERZ
      , PPERL
      , PPERV
      , KALKZ
      , KALKL
      , KALKV
      , KALSC
      , XLIFO
      , MYPOL
      , BWPH1
      , BWPS1
      , ABWKZ
      , PSTAT
      , KALN1
      , KALNR
      , BWVA1
      , BWVA2
      , BWVA3
      , VERS1
      , VERS2
      , VERS3
      , HRKFT
      , KOSGR
      , PPRDZ
      , PPRDL
      , PPRDV
      , PDATZ
      , PDATL
      , PDATV
      , EKALR
      , VPLPR
      , MLMAA
      , MLAST
      , LPLPR
      , VKSAL
      , HKMAT
      , SPERW
      , KZIWL
      , WLINL
      , ABCIW
      , BWSPA
      , LPLPX
      , VPLPX
      , FPLPX
      , LBWST
      , VBWST
      , FBWST
      , EKLAS
      , QKLAS
      , MTUSE
      , MTORG
      , OWNPR
      , XBEWM
      , BWPEI
      , MBRUE
      , OKLAS
      , OIPPINV
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        MANDT
      , MATNR
      , BWKEY
      , BWTAR
      , LVORM
      , LBKUM
      , SALK3
      , VPRSV
      , VERPR
      , STPRS
      , PEINH
      , BKLAS
      , SALKV
      , VMKUM
      , VMSAL
      , VMVPR
      , VMVER
      , VMSTP
      , VMPEI
      , VMBKL
      , VMSAV
      , VJKUM
      , VJSAL
      , VJVPR
      , VJVER
      , VJSTP
      , VJPEI
      , VJBKL
      , VJSAV
      , LFGJA
      , LFMON
      , BWTTY
      , STPRV
      , LAEPR
      , ZKPRS
      , ZKDAT
      , TIMESTAMP
      , BWPRS
      , BWPRH
      , VJBWS
      , VJBWH
      , VVJSL
      , VVJLB
      , VVMLB
      , VVSAL
      , ZPLPR
      , ZPLP1
      , ZPLP2
      , ZPLP3
      , ZPLD1
      , ZPLD2
      , ZPLD3
      , PPERZ
      , PPERL
      , PPERV
      , KALKZ
      , KALKL
      , KALKV
      , KALSC
      , XLIFO
      , MYPOL
      , BWPH1
      , BWPS1
      , ABWKZ
      , PSTAT
      , KALN1
      , KALNR
      , BWVA1
      , BWVA2
      , BWVA3
      , VERS1
      , VERS2
      , VERS3
      , HRKFT
      , KOSGR
      , PPRDZ
      , PPRDL
      , PPRDV
      , PDATZ
      , PDATL
      , PDATV
      , EKALR
      , VPLPR
      , MLMAA
      , MLAST
      , LPLPR
      , VKSAL
      , HKMAT
      , SPERW
      , KZIWL
      , WLINL
      , ABCIW
      , BWSPA
      , LPLPX
      , VPLPX
      , FPLPX
      , LBWST
      , VBWST
      , FBWST
      , EKLAS
      , QKLAS
      , MTUSE
      , MTORG
      , OWNPR
      , XBEWM
      , BWPEI
      , MBRUE
      , OKLAS
      , OIPPINV
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_MBEW'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          to_char(coalesce(nullif(trim(MATNR), ''), '-1'))                      as         ITEM_BK
        , to_char(coalesce(nullif(trim(BWKEY), ''), '-1'))                      as         PLANT_BK
        , MANDT
        , MATNR
        , BWKEY
        , BWTAR
        , LVORM
        , LBKUM
        , SALK3
        , VPRSV
        , VERPR
        , STPRS
        , PEINH
        , BKLAS
        , SALKV
        , VMKUM
        , VMSAL
        , VMVPR
        , VMVER
        , VMSTP
        , VMPEI
        , VMBKL
        , VMSAV
        , VJKUM
        , VJSAL
        , VJVPR
        , VJVER
        , VJSTP
        , VJPEI
        , VJBKL
        , VJSAV
        , LFGJA
        , LFMON
        , BWTTY
        , STPRV
        , LAEPR
        , ZKPRS
        , ZKDAT
        , TIMESTAMP
        , BWPRS
        , BWPRH
        , VJBWS
        , VJBWH
        , VVJSL
        , VVJLB
        , VVMLB
        , VVSAL
        , ZPLPR
        , ZPLP1
        , ZPLP2
        , ZPLP3
        , ZPLD1
        , ZPLD2
        , ZPLD3
        , PPERZ
        , PPERL
        , PPERV
        , KALKZ
        , KALKL
        , KALKV
        , KALSC
        , XLIFO
        , MYPOL
        , BWPH1
        , BWPS1
        , ABWKZ
        , PSTAT
        , KALN1
        , KALNR
        , BWVA1
        , BWVA2
        , BWVA3
        , VERS1
        , VERS2
        , VERS3
        , HRKFT
        , KOSGR
        , PPRDZ
        , PPRDL
        , PPRDV
        , PDATZ
        , PDATL
        , PDATV
        , EKALR
        , VPLPR
        , MLMAA
        , MLAST
        , LPLPR
        , VKSAL
        , HKMAT
        , SPERW
        , KZIWL
        , WLINL
        , ABCIW
        , BWSPA
        , LPLPX
        , VPLPX
        , FPLPX
        , LBWST
        , VBWST
        , FBWST
        , EKLAS
        , QKLAS
        , MTUSE
        , MTORG
        , OWNPR
        , XBEWM
        , BWPEI
        , MBRUE
        , OKLAS
        , OIPPINV
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
        ))  as LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(COALESCE(NULLIF(BWTAR, ''), '-1') as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_MATERIAL_VALUATION_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(BWKEY::text), '^^') 
            , '||', IFNULL(TRIM(BWTAR::text), '^^') 
            , '||', IFNULL(TRIM(LVORM::text), '^^') 
            , '||', IFNULL(TRIM(LBKUM::text), '^^') 
            , '||', IFNULL(TRIM(SALK3::text), '^^') 
            , '||', IFNULL(TRIM(VPRSV::text), '^^') 
            , '||', IFNULL(TRIM(VERPR::text), '^^') 
            , '||', IFNULL(TRIM(STPRS::text), '^^') 
            , '||', IFNULL(TRIM(PEINH::text), '^^') 
            , '||', IFNULL(TRIM(BKLAS::text), '^^') 
            , '||', IFNULL(TRIM(SALKV::text), '^^') 
            , '||', IFNULL(TRIM(VMKUM::text), '^^') 
            , '||', IFNULL(TRIM(VMSAL::text), '^^') 
            , '||', IFNULL(TRIM(VMVPR::text), '^^') 
            , '||', IFNULL(TRIM(VMVER::text), '^^') 
            , '||', IFNULL(TRIM(VMSTP::text), '^^') 
            , '||', IFNULL(TRIM(VMPEI::text), '^^') 
            , '||', IFNULL(TRIM(VMBKL::text), '^^') 
            , '||', IFNULL(TRIM(VMSAV::text), '^^') 
            , '||', IFNULL(TRIM(VJKUM::text), '^^') 
            , '||', IFNULL(TRIM(VJSAL::text), '^^') 
            , '||', IFNULL(TRIM(VJVPR::text), '^^') 
            , '||', IFNULL(TRIM(VJVER::text), '^^') 
            , '||', IFNULL(TRIM(VJSTP::text), '^^') 
            , '||', IFNULL(TRIM(VJPEI::text), '^^') 
            , '||', IFNULL(TRIM(VJBKL::text), '^^') 
            , '||', IFNULL(TRIM(VJSAV::text), '^^') 
            , '||', IFNULL(TRIM(LFGJA::text), '^^') 
            , '||', IFNULL(TRIM(LFMON::text), '^^') 
            , '||', IFNULL(TRIM(BWTTY::text), '^^') 
            , '||', IFNULL(TRIM(STPRV::text), '^^') 
            , '||', IFNULL(TRIM(LAEPR::text), '^^') 
            , '||', IFNULL(TRIM(ZKPRS::text), '^^') 
            , '||', IFNULL(TRIM(ZKDAT::text), '^^') 
            , '||', IFNULL(TRIM(TIMESTAMP::text), '^^') 
            , '||', IFNULL(TRIM(BWPRS::text), '^^') 
            , '||', IFNULL(TRIM(BWPRH::text), '^^') 
            , '||', IFNULL(TRIM(VJBWS::text), '^^') 
            , '||', IFNULL(TRIM(VJBWH::text), '^^') 
            , '||', IFNULL(TRIM(VVJSL::text), '^^') 
            , '||', IFNULL(TRIM(VVJLB::text), '^^') 
            , '||', IFNULL(TRIM(VVMLB::text), '^^') 
            , '||', IFNULL(TRIM(VVSAL::text), '^^') 
            , '||', IFNULL(TRIM(ZPLPR::text), '^^') 
            , '||', IFNULL(TRIM(ZPLP1::text), '^^') 
            , '||', IFNULL(TRIM(ZPLP2::text), '^^') 
            , '||', IFNULL(TRIM(ZPLP3::text), '^^') 
            , '||', IFNULL(TRIM(ZPLD1::text), '^^') 
            , '||', IFNULL(TRIM(ZPLD2::text), '^^') 
            , '||', IFNULL(TRIM(ZPLD3::text), '^^') 
            , '||', IFNULL(TRIM(PPERZ::text), '^^') 
            , '||', IFNULL(TRIM(PPERL::text), '^^') 
            , '||', IFNULL(TRIM(PPERV::text), '^^') 
            , '||', IFNULL(TRIM(KALKZ::text), '^^') 
            , '||', IFNULL(TRIM(KALKL::text), '^^') 
            , '||', IFNULL(TRIM(KALKV::text), '^^') 
            , '||', IFNULL(TRIM(KALSC::text), '^^') 
            , '||', IFNULL(TRIM(XLIFO::text), '^^') 
            , '||', IFNULL(TRIM(MYPOL::text), '^^') 
            , '||', IFNULL(TRIM(BWPH1::text), '^^') 
            , '||', IFNULL(TRIM(BWPS1::text), '^^') 
            , '||', IFNULL(TRIM(ABWKZ::text), '^^') 
            , '||', IFNULL(TRIM(PSTAT::text), '^^') 
            , '||', IFNULL(TRIM(KALN1::text), '^^') 
            , '||', IFNULL(TRIM(KALNR::text), '^^') 
            , '||', IFNULL(TRIM(BWVA1::text), '^^') 
            , '||', IFNULL(TRIM(BWVA2::text), '^^') 
            , '||', IFNULL(TRIM(BWVA3::text), '^^') 
            , '||', IFNULL(TRIM(VERS1::text), '^^') 
            , '||', IFNULL(TRIM(VERS2::text), '^^') 
            , '||', IFNULL(TRIM(VERS3::text), '^^') 
            , '||', IFNULL(TRIM(HRKFT::text), '^^') 
            , '||', IFNULL(TRIM(KOSGR::text), '^^') 
            , '||', IFNULL(TRIM(PPRDZ::text), '^^') 
            , '||', IFNULL(TRIM(PPRDL::text), '^^') 
            , '||', IFNULL(TRIM(PPRDV::text), '^^') 
            , '||', IFNULL(TRIM(PDATZ::text), '^^') 
            , '||', IFNULL(TRIM(PDATL::text), '^^') 
            , '||', IFNULL(TRIM(PDATV::text), '^^') 
            , '||', IFNULL(TRIM(EKALR::text), '^^') 
            , '||', IFNULL(TRIM(VPLPR::text), '^^') 
            , '||', IFNULL(TRIM(MLMAA::text), '^^') 
            , '||', IFNULL(TRIM(MLAST::text), '^^') 
            , '||', IFNULL(TRIM(LPLPR::text), '^^') 
            , '||', IFNULL(TRIM(VKSAL::text), '^^') 
            , '||', IFNULL(TRIM(HKMAT::text), '^^') 
            , '||', IFNULL(TRIM(SPERW::text), '^^') 
            , '||', IFNULL(TRIM(KZIWL::text), '^^') 
            , '||', IFNULL(TRIM(WLINL::text), '^^') 
            , '||', IFNULL(TRIM(ABCIW::text), '^^') 
            , '||', IFNULL(TRIM(BWSPA::text), '^^') 
            , '||', IFNULL(TRIM(LPLPX::text), '^^') 
            , '||', IFNULL(TRIM(VPLPX::text), '^^') 
            , '||', IFNULL(TRIM(FPLPX::text), '^^') 
            , '||', IFNULL(TRIM(LBWST::text), '^^') 
            , '||', IFNULL(TRIM(VBWST::text), '^^') 
            , '||', IFNULL(TRIM(FBWST::text), '^^') 
            , '||', IFNULL(TRIM(EKLAS::text), '^^') 
            , '||', IFNULL(TRIM(QKLAS::text), '^^') 
            , '||', IFNULL(TRIM(MTUSE::text), '^^') 
            , '||', IFNULL(TRIM(MTORG::text), '^^') 
            , '||', IFNULL(TRIM(OWNPR::text), '^^') 
            , '||', IFNULL(TRIM(XBEWM::text), '^^') 
            , '||', IFNULL(TRIM(BWPEI::text), '^^') 
            , '||', IFNULL(TRIM(MBRUE::text), '^^') 
            , '||', IFNULL(TRIM(OKLAS::text), '^^') 
            , '||', IFNULL(TRIM(OIPPINV::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
