---- SRC LAYER ----
WITH
SRC_besap          as ( SELECT AREWB, AREWR, AREWR_POP, AREWW, BAMNG, BEKKN, BELNR, BEWTP, BLDAT, BPMNG, BPMNG_POP, BPWEB, BPWES, BUDAT, BUZEI, BWART, BWTAR, CHARG, CPUDT, CPUTM, DMBTR, DMBTR_POP, EBELN, EBELP, ELIKZ, EMATN, ERNAM, ETENS, ET_UPD, EVERE, FSH_COLLECTION, FSH_SEASON, FSH_SEASON_YEAR, FSH_THEME, GJAHR, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, GRUND, HSWAE, INTROW, INV_ITEM_ORIGIN, J_SC_DIE_COMP_F, KNUMV, KUDIF, LEMIN, LFBNR, LFGJA, LFPOS, LSMEH, LSMNG, MANDT, MATNR, MENGE, MENGE_POP, MWSKZ, PACKNO, PSA_DELETE_IND, PSA_LOAD_DTS, REEWR, REFWR, RETAMTP_FC, RETAMTP_LC, RETAMT_FC, RETAMT_LC, REWRB, SAPRL, SGT_SCAT, SHKZG, SRVPOS, VBELN_ST, VBELP_ST, VGABE, WAERS, WEORA, WERKS, WESBB, WESBS, WKURS, WRBTR, WRBTR_POP, WRF_CHARSTC1, WRF_CHARSTC2, WRF_CHARSTC3, XBLNR, XMACC, XUNPL, XWOFF, XWSBR, ZEKKN FROM {{ source('sap_ecc_prd', 'z_ekbe') }} as SRC  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_kosap          as ( SELECT BUKRS, EBELN, LIFNR FROM {{ source('sap_ecc_prd', 'z_ekko') }} as SRC 
                        qualify 1 = (row_number() over(partition by ebeln order by psa_load_dts desc)) )

/*
SRC_besap          as ( SELECT * FROM sap_ecc_prd.z_ekbe )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_kosap          as ( SELECT * FROM sap_ecc_prd.z_ekko )
*/
---- LOGIC LAYER ----

, LOGIC_besap as (
    SELECT
        EBELN                                                        as                                       PO_HEADER_BK
      , MATNR                                                        as                                            ITEM_BK
      , WERKS                                                        as                                           PLANT_BK
      , EBELN
      , EBELP
      , BELNR
      , BUZEI
      , MATNR
      , WERKS
      , MANDT
      , ZEKKN
      , VGABE
      , GJAHR
      , GLREQUEST
      , GLSOURCESYSTEM
      , BEWTP
      , BWART
      , BUDAT
      , MENGE
      , BPMNG
      , DMBTR
      , WRBTR
      , WAERS
      , AREWR
      , WESBS
      , BPWES
      , SHKZG
      , BWTAR
      , ELIKZ
      , XBLNR
      , LFGJA
      , LFBNR
      , LFPOS
      , GRUND
      , CPUDT
      , CPUTM
      , REEWR
      , EVERE
      , REFWR
      , XWSBR
      , ETENS
      , KNUMV
      , MWSKZ
      , LSMNG
      , LSMEH
      , EMATN
      , AREWW
      , HSWAE
      , BAMNG
      , CHARG
      , BLDAT
      , XWOFF
      , XUNPL
      , ERNAM
      , SRVPOS
      , PACKNO
      , INTROW
      , BEKKN
      , LEMIN
      , AREWB
      , REWRB
      , SAPRL
      , MENGE_POP
      , BPMNG_POP
      , DMBTR_POP
      , WRBTR_POP
      , WESBB
      , BPWEB
      , WEORA
      , AREWR_POP
      , KUDIF
      , RETAMT_FC
      , RETAMT_LC
      , RETAMTP_FC
      , RETAMTP_LC
      , XMACC
      , WKURS
      , INV_ITEM_ORIGIN
      , VBELN_ST
      , VBELP_ST
      , SGT_SCAT
      , ET_UPD
      , J_SC_DIE_COMP_F
      , FSH_SEASON_YEAR
      , FSH_SEASON
      , FSH_COLLECTION
      , FSH_THEME
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
    FROM SRC_besap
)

, LOGIC_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_a
)

, LOGIC_kosap as (
    SELECT
        LIFNR                                                        as                                        SUPPLIER_BK
      , BUKRS                                                        as                                    LEGAL_ENTITY_BK
      , LIFNR
      , BUKRS
      , EBELN                                                        as                                        KOSAP_EBELN
    FROM SRC_kosap
)
---- RENAME LAYER ----

, RENAME_besap as (
    SELECT
        PO_HEADER_BK
      , ITEM_BK
      , PLANT_BK
      , EBELN
      , EBELP
      , BELNR
      , BUZEI
      , MATNR
      , WERKS
      , MANDT
      , ZEKKN
      , VGABE
      , GJAHR
      , GLREQUEST
      , GLSOURCESYSTEM
      , BEWTP
      , BWART
      , BUDAT
      , MENGE
      , BPMNG
      , DMBTR
      , WRBTR
      , WAERS
      , AREWR
      , WESBS
      , BPWES
      , SHKZG
      , BWTAR
      , ELIKZ
      , XBLNR
      , LFGJA
      , LFBNR
      , LFPOS
      , GRUND
      , CPUDT
      , CPUTM
      , REEWR
      , EVERE
      , REFWR
      , XWSBR
      , ETENS
      , KNUMV
      , MWSKZ
      , LSMNG
      , LSMEH
      , EMATN
      , AREWW
      , HSWAE
      , BAMNG
      , CHARG
      , BLDAT
      , XWOFF
      , XUNPL
      , ERNAM
      , SRVPOS
      , PACKNO
      , INTROW
      , BEKKN
      , LEMIN
      , AREWB
      , REWRB
      , SAPRL
      , MENGE_POP
      , BPMNG_POP
      , DMBTR_POP
      , WRBTR_POP
      , WESBB
      , BPWEB
      , WEORA
      , AREWR_POP
      , KUDIF
      , RETAMT_FC
      , RETAMT_LC
      , RETAMTP_FC
      , RETAMTP_LC
      , XMACC
      , WKURS
      , INV_ITEM_ORIGIN
      , VBELN_ST
      , VBELP_ST
      , SGT_SCAT
      , ET_UPD
      , J_SC_DIE_COMP_F
      , FSH_SEASON_YEAR
      , FSH_SEASON
      , FSH_COLLECTION
      , FSH_THEME
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_besap
)

, RENAME_kosap as (
    SELECT
        SUPPLIER_BK
      , LEGAL_ENTITY_BK
      , LIFNR
      , BUKRS
      , KOSAP_EBELN
    FROM LOGIC_kosap
)

, RENAME_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_besap as (
    SELECT *
    FROM RENAME_besap
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_EKBE'
)

, FILTER_kosap as (
    SELECT *
    FROM RENAME_kosap
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_besap
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_kosap
        ON FILTER_besap.ebeln = kosap_ebeln
)

---- FINAL LAYER ----
SELECT
          CONCAT_WS('||', COALESCE(EBELN, ''), COALESCE(EBELP, ''), COALESCE(BELNR, ''), COALESCE(BUZEI, '')) as PO_ITEM_RECEIPT_BK
        , PO_HEADER_BK
        , SUPPLIER_BK
        , ITEM_BK
        , PLANT_BK
        , LEGAL_ENTITY_BK
        , EBELN
        , EBELP
        , BELNR
        , BUZEI
        , MATNR
        , WERKS
        , MANDT
        , ZEKKN
        , VGABE
        , GJAHR
        , GLREQUEST
        , GLSOURCESYSTEM
        , BEWTP
        , BWART
        , BUDAT
        , MENGE
        , BPMNG
        , DMBTR
        , WRBTR
        , WAERS
        , AREWR
        , WESBS
        , BPWES
        , SHKZG
        , BWTAR
        , ELIKZ
        , XBLNR
        , LFGJA
        , LFBNR
        , LFPOS
        , GRUND
        , CPUDT
        , CPUTM
        , REEWR
        , EVERE
        , REFWR
        , XWSBR
        , ETENS
        , KNUMV
        , MWSKZ
        , LSMNG
        , LSMEH
        , EMATN
        , AREWW
        , HSWAE
        , BAMNG
        , CHARG
        , BLDAT
        , XWOFF
        , XUNPL
        , ERNAM
        , SRVPOS
        , PACKNO
        , INTROW
        , BEKKN
        , LEMIN
        , AREWB
        , REWRB
        , SAPRL
        , MENGE_POP
        , BPMNG_POP
        , DMBTR_POP
        , WRBTR_POP
        , WESBB
        , BPWEB
        , WEORA
        , AREWR_POP
        , KUDIF
        , RETAMT_FC
        , RETAMT_LC
        , RETAMTP_FC
        , RETAMTP_LC
        , XMACC
        , WKURS
        , INV_ITEM_ORIGIN
        , VBELN_ST
        , VBELP_ST
        , SGT_SCAT
        , ET_UPD
        , J_SC_DIE_COMP_F
        , FSH_SEASON_YEAR
        , FSH_SEASON
        , FSH_COLLECTION
        , FSH_THEME
        , WRF_CHARSTC1
        , WRF_CHARSTC2
        , WRF_CHARSTC3
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , LOAD_DTS
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(EBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(EBELP as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BELNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BUZEI as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LIFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(WERKS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BUKRS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_PO_RECEIPT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(EBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(EBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(EBELP as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(EBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(EBELP as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BELNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BUZEI as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_ITEM_RECEIPT_DK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LIFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(WERKS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BUKRS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(ZEKKN::text), '^^') 
            , '||', IFNULL(TRIM(VGABE::text), '^^') 
            , '||', IFNULL(TRIM(GJAHR::text), '^^') 
            , '||', IFNULL(TRIM(BEWTP::text), '^^') 
            , '||', IFNULL(TRIM(BWART::text), '^^') 
            , '||', IFNULL(TRIM(BUDAT::text), '^^') 
            , '||', IFNULL(TRIM(MENGE::text), '^^') 
            , '||', IFNULL(TRIM(BPMNG::text), '^^') 
            , '||', IFNULL(TRIM(DMBTR::text), '^^') 
            , '||', IFNULL(TRIM(WRBTR::text), '^^') 
            , '||', IFNULL(TRIM(WAERS::text), '^^') 
            , '||', IFNULL(TRIM(AREWR::text), '^^') 
            , '||', IFNULL(TRIM(WESBS::text), '^^') 
            , '||', IFNULL(TRIM(BPWES::text), '^^') 
            , '||', IFNULL(TRIM(SHKZG::text), '^^') 
            , '||', IFNULL(TRIM(BWTAR::text), '^^') 
            , '||', IFNULL(TRIM(ELIKZ::text), '^^') 
            , '||', IFNULL(TRIM(XBLNR::text), '^^') 
            , '||', IFNULL(TRIM(LFGJA::text), '^^') 
            , '||', IFNULL(TRIM(LFBNR::text), '^^') 
            , '||', IFNULL(TRIM(LFPOS::text), '^^') 
            , '||', IFNULL(TRIM(GRUND::text), '^^') 
            , '||', IFNULL(TRIM(CPUDT::text), '^^') 
            , '||', IFNULL(TRIM(CPUTM::text), '^^') 
            , '||', IFNULL(TRIM(REEWR::text), '^^') 
            , '||', IFNULL(TRIM(EVERE::text), '^^') 
            , '||', IFNULL(TRIM(REFWR::text), '^^') 
            , '||', IFNULL(TRIM(XWSBR::text), '^^') 
            , '||', IFNULL(TRIM(ETENS::text), '^^') 
            , '||', IFNULL(TRIM(KNUMV::text), '^^') 
            , '||', IFNULL(TRIM(MWSKZ::text), '^^') 
            , '||', IFNULL(TRIM(LSMNG::text), '^^') 
            , '||', IFNULL(TRIM(LSMEH::text), '^^') 
            , '||', IFNULL(TRIM(EMATN::text), '^^') 
            , '||', IFNULL(TRIM(AREWW::text), '^^') 
            , '||', IFNULL(TRIM(HSWAE::text), '^^') 
            , '||', IFNULL(TRIM(BAMNG::text), '^^') 
            , '||', IFNULL(TRIM(CHARG::text), '^^') 
            , '||', IFNULL(TRIM(BLDAT::text), '^^') 
            , '||', IFNULL(TRIM(XWOFF::text), '^^') 
            , '||', IFNULL(TRIM(XUNPL::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(SRVPOS::text), '^^') 
            , '||', IFNULL(TRIM(PACKNO::text), '^^') 
            , '||', IFNULL(TRIM(INTROW::text), '^^') 
            , '||', IFNULL(TRIM(BEKKN::text), '^^') 
            , '||', IFNULL(TRIM(LEMIN::text), '^^') 
            , '||', IFNULL(TRIM(AREWB::text), '^^') 
            , '||', IFNULL(TRIM(REWRB::text), '^^') 
            , '||', IFNULL(TRIM(SAPRL::text), '^^') 
            , '||', IFNULL(TRIM(MENGE_POP::text), '^^') 
            , '||', IFNULL(TRIM(BPMNG_POP::text), '^^') 
            , '||', IFNULL(TRIM(DMBTR_POP::text), '^^') 
            , '||', IFNULL(TRIM(WRBTR_POP::text), '^^') 
            , '||', IFNULL(TRIM(WESBB::text), '^^') 
            , '||', IFNULL(TRIM(BPWEB::text), '^^') 
            , '||', IFNULL(TRIM(WEORA::text), '^^') 
            , '||', IFNULL(TRIM(AREWR_POP::text), '^^') 
            , '||', IFNULL(TRIM(KUDIF::text), '^^') 
            , '||', IFNULL(TRIM(RETAMT_FC::text), '^^') 
            , '||', IFNULL(TRIM(RETAMT_LC::text), '^^') 
            , '||', IFNULL(TRIM(RETAMTP_FC::text), '^^') 
            , '||', IFNULL(TRIM(RETAMTP_LC::text), '^^') 
            , '||', IFNULL(TRIM(XMACC::text), '^^') 
            , '||', IFNULL(TRIM(WKURS::text), '^^') 
            , '||', IFNULL(TRIM(INV_ITEM_ORIGIN::text), '^^') 
            , '||', IFNULL(TRIM(VBELN_ST::text), '^^') 
            , '||', IFNULL(TRIM(VBELP_ST::text), '^^') 
            , '||', IFNULL(TRIM(SGT_SCAT::text), '^^') 
            , '||', IFNULL(TRIM(ET_UPD::text), '^^') 
            , '||', IFNULL(TRIM(J_SC_DIE_COMP_F::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEASON_YEAR::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEASON::text), '^^') 
            , '||', IFNULL(TRIM(FSH_COLLECTION::text), '^^') 
            , '||', IFNULL(TRIM(FSH_THEME::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC1::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC2::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC3::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
