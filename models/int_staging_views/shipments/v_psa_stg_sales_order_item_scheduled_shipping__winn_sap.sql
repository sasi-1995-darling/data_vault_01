---- SRC LAYER ----
WITH
SRC_vbep           as ( SELECT ABART, ABGES, ABRUF, AESKD, AUFNR, AULWE, BANFN, BDART, BDDAT, BMENG, BNFPO, BSART, BSTYP, BWART, CMENG, EDATU, ETART, ETENE, ETENR, 
                        ETTYP, EZEIT, FSH_OS_ID, FSH_PQR_RC, FSH_RALLOC_QTY, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, GRSTR, HANDOVERDATE, HANDOVERTIME, 
                        IDNNR, LDDAT, LDUHR, LFREL, LIFSP, LMENG, LRGDT, MANDT, MBDAT, MBDAT_DRS, MBUHR, MEINS, PLART, PLNUM, POSNE, POSNR, PRGRS, PSA_DELETE_IND, 
                        PSA_LOAD_DTS, PSA_RECORD_SOURCE, REPOS, RFORM, ROMEI, ROMS1, ROMS2, ROMS3, RSDAT, SERNR, TDDAT, TDUHR, UMVKN, UMVKZ, VBELE, VBELN, VERFP, 
                        VRKME, WADAT, WAUHR, WEPOS, WMENG, ZZCRSDCODE, ZZKUNWE, ZZMAD, ZZOPDT, ZZORV, ZZPDT, ZZPDTCNT, ZZREC, ZZRSD, ZZRST, _DATAAGING 
                        FROM {{ source('sap_ecc_prd', 'z_vbep') }} as SRC  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_vbap           as ( SELECT MATNR, POSNR, VBELN FROM {{ source('sap_ecc_prd', 'z_vbap') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER()OVER(PARTITION BY VBELN, POSNR ORDER BY PSA_LOAD_DTS DESC, GLCHANGETIME DESC) ),
SRC_billto         as ( SELECT KUNNR, PARVW, POSNR, VBELN FROM {{ source('sap_ecc_prd', 'z_vbpa') }} as SRC 
                        WHERE PARVW = 'RE'
                        QUALIFY 1 = ROW_NUMBER()OVER(PARTITION BY VBELN, POSNR ORDER BY PSA_LOAD_DTS DESC, GLCHANGETIME DESC) ),
SRC_shipto         as ( SELECT KUNNR, PARVW, POSNR, VBELN FROM {{ source('sap_ecc_prd', 'z_vbpa') }} as SRC 
                        WHERE PARVW = 'WE'
                        QUALIFY 1 = ROW_NUMBER()OVER(PARTITION BY VBELN, POSNR ORDER BY PSA_LOAD_DTS DESC, GLCHANGETIME DESC) ),
SRC_soldto         as ( SELECT KUNNR, PARVW, POSNR, VBELN FROM {{ source('sap_ecc_prd', 'z_vbpa') }} as SRC 
                        WHERE PARVW = 'AG'
                        QUALIFY 1 = ROW_NUMBER()OVER(PARTITION BY VBELN, POSNR ORDER BY PSA_LOAD_DTS DESC, GLCHANGETIME DESC) ),
SRC_payer          as ( SELECT KUNNR, PARVW, POSNR, VBELN FROM {{ source('sap_ecc_prd', 'z_vbpa') }} as SRC 
                        WHERE PARVW = 'RG'
                        QUALIFY 1 = ROW_NUMBER()OVER(PARTITION BY VBELN, POSNR ORDER BY PSA_LOAD_DTS DESC, GLCHANGETIME DESC) ),
SRC_insurance      as ( SELECT KUNNR, PARVW, POSNR, VBELN FROM {{ source('sap_ecc_prd', 'z_vbpa') }} as SRC 
                        WHERE PARVW = 'YO'
                        QUALIFY 1 = ROW_NUMBER()OVER(PARTITION BY VBELN, POSNR ORDER BY PSA_LOAD_DTS DESC, GLCHANGETIME DESC) )

/*
SRC_vbep           as ( SELECT * FROM sap_ecc_prd.z_vbep )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_vbap           as ( SELECT * FROM sap_ecc_prd.z_vbap )
SRC_billto         as ( SELECT * FROM sap_ecc_prd.z_vbpa )
SRC_shipto         as ( SELECT * FROM sap_ecc_prd.z_vbpa )
SRC_soldto         as ( SELECT * FROM sap_ecc_prd.z_vbpa )
SRC_payer          as ( SELECT * FROM sap_ecc_prd.z_vbpa )
SRC_insurance      as ( SELECT * FROM sap_ecc_prd.z_vbpa )
*/
---- LOGIC LAYER ----

, LOGIC_vbep as (
    SELECT
        to_char(coalesce(VBELN,'-1'))                                as                                    ORDER_HEADER_BK
      , CONCAT_WS('||', COALESCE(VBELN, ''), COALESCE(POSNR, ''))    as                                      ORDER_LINE_BK
      , MANDT
      , VBELN
      , POSNR
      , ETENR
      , GLREQUEST
      , ETTYP
      , LFREL
      , EDATU
      , EZEIT
      , WMENG
      , BMENG
      , VRKME
      , LMENG
      , MEINS
      , BDDAT
      , TRY_TO_DATE(BDDAT, 'YYYYMMDD')                               as                                           BDDAT_DT
      , BDART
      , PLART
      , VBELE
      , POSNE
      , ETENE
      , RSDAT
      , TRY_TO_DATE(RSDAT, 'YYYYMMDD')                               as                                           RSDAT_DT
      , IDNNR
      , BANFN
      , BSART
      , BSTYP
      , WEPOS
      , REPOS
      , LRGDT
      , PRGRS
      , TDDAT
      , MBDAT
      , TRY_TO_DATE(MBDAT, 'YYYYMMDD')                               as                                           MBDAT_DT
      , LDDAT
      , TRY_TO_DATE(LDDAT, 'YYYYMMDD')                               as                                           LDDAT_DT
      , WADAT
      , TRY_TO_DATE(WADAT, 'YYYYMMDD')                               as                                           WADAT_DT
      , CMENG
      , LIFSP
      , GRSTR
      , ABART
      , ABRUF
      , ROMS1
      , ROMS2
      , ROMS3
      , ROMEI
      , RFORM
      , UMVKZ
      , UMVKN
      , VERFP
      , BWART
      , BNFPO
      , ETART
      , AUFNR
      , PLNUM
      , SERNR
      , AESKD
      , ABGES
      , MBUHR
      , TDUHR
      , LDUHR
      , WAUHR
      , AULWE
      , HANDOVERDATE
      , HANDOVERTIME
      , _DATAAGING
      , FSH_RALLOC_QTY
      , FSH_OS_ID
      , FSH_PQR_RC
      , MBDAT_DRS
      , ZZRSD
      , ZZMAD
      , ZZREC
      , ZZORV
      , ZZRST
      , ZZPDT
      , ZZPDTCNT
      , ZZOPDT
      , ZZCRSDCODE
      , ZZKUNWE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,
            CONVERT_TIMEZONE(
            'UTC',
            TO_TIMESTAMP_NTZ(
            SUBSTR(GLCHANGETIME, 1, 14) || '.' || SUBSTR(GLCHANGETIME, 16),
            'YYYYMMDDHH24MISS.FF9'
            )
            )
        )                                                            as                                           LOAD_DTS
    FROM SRC_vbep
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)

, LOGIC_vbap as (
    SELECT
        MATNR                                                        as                                         VBAP_MATNR
      , VBELN                                                        as                                         VBAP_VBELN
      , POSNR                                                        as                                         VBAP_POSNR
    FROM SRC_vbap
)

, LOGIC_billto as (
    SELECT
        PARVW                                                        as                                       BILLTO_PARVW
      , KUNNR                                                        as                                       BILLTO_KUNNR
      , POSNR                                                        as                                       BILLTO_POSNR
      , VBELN                                                        as                                       BILLTO_VBELN
    FROM SRC_billto
)

, LOGIC_shipto as (
    SELECT
        PARVW                                                        as                                       SHIPTO_PARVW
      , KUNNR                                                        as                                       SHIPTO_KUNNR
      , POSNR                                                        as                                       SHIPTO_POSNR
      , VBELN                                                        as                                       SHIPTO_VBELN
    FROM SRC_shipto
)

, LOGIC_soldto as (
    SELECT
        PARVW                                                        as                                       SOLDTO_PARVW
      , KUNNR                                                        as                                       SOLDTO_KUNNR
      , POSNR                                                        as                                       SOLDTO_POSNR
      , VBELN                                                        as                                       SOLDTO_VBELN
    FROM SRC_soldto
)

, LOGIC_payer as (
    SELECT
        PARVW                                                        as                                        PAYER_PARVW
      , KUNNR                                                        as                                        PAYER_KUNNR
      , POSNR                                                        as                                        PAYER_POSNR
      , VBELN                                                        as                                        PAYER_VBELN
    FROM SRC_payer
)

, LOGIC_insurance as (
    SELECT
        PARVW                                                        as                                    INSURANCE_PARVW
      , KUNNR                                                        as                                    INSURANCE_KUNNR
      , POSNR                                                        as                                    INSURANCE_POSNR
      , VBELN                                                        as                                    INSURANCE_VBELN
    FROM SRC_insurance
)
---- RENAME LAYER ----

, RENAME_vbep as (
    SELECT
        ORDER_HEADER_BK
      , ORDER_LINE_BK
      , MANDT
      , VBELN
      , POSNR
      , ETENR
      , GLREQUEST
      , ETTYP
      , LFREL
      , EDATU
      , EZEIT
      , WMENG
      , BMENG
      , VRKME
      , LMENG
      , MEINS
      , BDDAT
      , BDDAT_DT
      , BDART
      , PLART
      , VBELE
      , POSNE
      , ETENE
      , RSDAT
      , RSDAT_DT
      , IDNNR
      , BANFN
      , BSART
      , BSTYP
      , WEPOS
      , REPOS
      , LRGDT
      , PRGRS
      , TDDAT
      , MBDAT
      , MBDAT_DT
      , LDDAT
      , LDDAT_DT
      , WADAT
      , WADAT_DT
      , CMENG
      , LIFSP
      , GRSTR
      , ABART
      , ABRUF
      , ROMS1
      , ROMS2
      , ROMS3
      , ROMEI
      , RFORM
      , UMVKZ
      , UMVKN
      , VERFP
      , BWART
      , BNFPO
      , ETART
      , AUFNR
      , PLNUM
      , SERNR
      , AESKD
      , ABGES
      , MBUHR
      , TDUHR
      , LDUHR
      , WAUHR
      , AULWE
      , HANDOVERDATE
      , HANDOVERTIME
      , _DATAAGING
      , FSH_RALLOC_QTY
      , FSH_OS_ID
      , FSH_PQR_RC
      , MBDAT_DRS
      , ZZRSD
      , ZZMAD
      , ZZREC
      , ZZORV
      , ZZRST
      , ZZPDT
      , ZZPDTCNT
      , ZZOPDT
      , ZZCRSDCODE
      , ZZKUNWE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_vbep
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)

, RENAME_payer as (
    SELECT
        PAYER_PARVW
      , PAYER_KUNNR
      , PAYER_POSNR
      , PAYER_VBELN
    FROM LOGIC_payer
)

, RENAME_billto as (
    SELECT
        BILLTO_PARVW
      , BILLTO_KUNNR
      , BILLTO_POSNR
      , BILLTO_VBELN
    FROM LOGIC_billto
)

, RENAME_shipto as (
    SELECT
        SHIPTO_PARVW
      , SHIPTO_KUNNR
      , SHIPTO_POSNR
      , SHIPTO_VBELN
    FROM LOGIC_shipto
)

, RENAME_soldto as (
    SELECT
        SOLDTO_PARVW
      , SOLDTO_KUNNR
      , SOLDTO_POSNR
      , SOLDTO_VBELN
    FROM LOGIC_soldto
)

, RENAME_insurance as (
    SELECT
        INSURANCE_PARVW
      , INSURANCE_KUNNR
      , INSURANCE_POSNR
      , INSURANCE_VBELN
    FROM LOGIC_insurance
)

, RENAME_vbap as (
    SELECT
        VBAP_MATNR
      , VBAP_VBELN
      , VBAP_POSNR
    FROM LOGIC_vbap
)
---- FILTER LAYER ----

, FILTER_vbep as (
    SELECT *
    FROM RENAME_vbep
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_VBEP'
)

, FILTER_vbap as (
    SELECT *
    FROM RENAME_vbap
)

, FILTER_billto as (
    SELECT *
    FROM RENAME_billto
)

, FILTER_shipto as (
    SELECT *
    FROM RENAME_shipto
)

, FILTER_soldto as (
    SELECT *
    FROM RENAME_soldto
)

, FILTER_payer as (
    SELECT *
    FROM RENAME_payer
)

, FILTER_insurance as (
    SELECT *
    FROM RENAME_insurance
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_vbep
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_vbap
        ON vbeln = vbap_vbeln
        AND posnr =  vbap_posnr

    LEFT JOIN FILTER_billto
        ON vbeln = billto_vbeln
        AND posnr = billto_posnr
    LEFT JOIN FILTER_shipto
        ON vbeln = shipto_vbeln
        AND posnr = shipto_posnr
    LEFT JOIN FILTER_soldto
        ON vbeln = soldto_vbeln
        AND posnr = soldto_posnr
    LEFT JOIN FILTER_payer
        ON vbeln = payer_vbeln
        AND posnr = payer_posnr
    LEFT JOIN FILTER_insurance
        ON vbeln = insurance_vbeln
        AND posnr = insurance_posnr
)

---- FINAL LAYER ----
SELECT
          ORDER_HEADER_BK
        , ORDER_LINE_BK
        , COALESCE(NULLIF(TRIM(VBAP_MATNR),''),'-1')                   as ITEM_BK
        , COALESCE(NULLIF(TRIM(SOLDTO_KUNNR),''),'-1')                 as CUSTOMER_SOLDTO_BK
        , COALESCE(NULLIF(TRIM(BILLTO_KUNNR),''),'-1')                 as CUSTOMER_BILLTO_BK
        , COALESCE(NULLIF(TRIM(SHIPTO_KUNNR),''),'-1')                 as CUSTOMER_SHIPTO_BK
        , COALESCE(NULLIF(TRIM(PAYER_KUNNR),''),'-1')                  as CUSTOMER_PAYER_BK
        , COALESCE(NULLIF(TRIM(INSURANCE_KUNNR),''),'-1')              as CUSTOMER_INSURANCEPARTNER_BK
        , MANDT
        , VBELN
        , POSNR
        , ETENR
        , GLREQUEST
        , ETTYP
        , LFREL
        , EDATU
        , EZEIT
        , WMENG
        , BMENG
        , VRKME
        , LMENG
        , MEINS
        , BDDAT
        , BDDAT_DT
        , BDART
        , PLART
        , VBELE
        , POSNE
        , ETENE
        , RSDAT
        , RSDAT_DT
        , IDNNR
        , BANFN
        , BSART
        , BSTYP
        , WEPOS
        , REPOS
        , LRGDT
        , PRGRS
        , TDDAT
        , MBDAT
        , MBDAT_DT
        , LDDAT
        , LDDAT_DT
        , WADAT
        , WADAT_DT
        , CMENG
        , LIFSP
        , GRSTR
        , ABART
        , ABRUF
        , ROMS1
        , ROMS2
        , ROMS3
        , ROMEI
        , RFORM
        , UMVKZ
        , UMVKN
        , VERFP
        , BWART
        , BNFPO
        , ETART
        , AUFNR
        , PLNUM
        , SERNR
        , AESKD
        , ABGES
        , MBUHR
        , TDUHR
        , LDUHR
        , WAUHR
        , AULWE
        , HANDOVERDATE
        , HANDOVERTIME
        , _DATAAGING
        , FSH_RALLOC_QTY
        , FSH_OS_ID
        , FSH_PQR_RC
        , MBDAT_DRS
        , ZZRSD
        , ZZMAD
        , ZZREC
        , ZZORV
        , ZZRST
        , ZZPDT
        , ZZPDTCNT
        , ZZOPDT
        , ZZCRSDCODE
        , ZZKUNWE
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , PAYER_PARVW
        , BILLTO_PARVW
        , SHIPTO_PARVW
        , SOLDTO_PARVW
        , INSURANCE_PARVW
        , PAYER_KUNNR
        , BILLTO_KUNNR
        , SHIPTO_KUNNR
        , SOLDTO_KUNNR
        , INSURANCE_KUNNR
        , VBAP_MATNR
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(POSNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_SOLDTO_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_SOLDTO_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BILLTO_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_BILLTO_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_SHIPTO_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_SHIPTO_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_PAYER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_PAYER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_INSURANCEPARTNER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_INSURANCEPARTNER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(POSNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_SOLDTO_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BILLTO_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_SHIPTO_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_PAYER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_INSURANCEPARTNER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SO_ITEM_LHK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(VBELN::text), '^^') 
            , '||', IFNULL(TRIM(POSNR::text), '^^') 
            , '||', IFNULL(TRIM(ETENR::text), '^^') 
            , '||', IFNULL(TRIM(ETTYP::text), '^^') 
            , '||', IFNULL(TRIM(LFREL::text), '^^') 
            , '||', IFNULL(TRIM(EDATU::text), '^^') 
            , '||', IFNULL(TRIM(EZEIT::text), '^^') 
            , '||', IFNULL(TRIM(WMENG::text), '^^') 
            , '||', IFNULL(TRIM(BMENG::text), '^^') 
            , '||', IFNULL(TRIM(VRKME::text), '^^') 
            , '||', IFNULL(TRIM(LMENG::text), '^^') 
            , '||', IFNULL(TRIM(MEINS::text), '^^') 
            , '||', IFNULL(TRIM(BDDAT::text), '^^') 
            , '||', IFNULL(TRIM(BDART::text), '^^') 
            , '||', IFNULL(TRIM(PLART::text), '^^') 
            , '||', IFNULL(TRIM(VBELE::text), '^^') 
            , '||', IFNULL(TRIM(POSNE::text), '^^') 
            , '||', IFNULL(TRIM(ETENE::text), '^^') 
            , '||', IFNULL(TRIM(RSDAT::text), '^^') 
            , '||', IFNULL(TRIM(IDNNR::text), '^^') 
            , '||', IFNULL(TRIM(BANFN::text), '^^') 
            , '||', IFNULL(TRIM(BSART::text), '^^') 
            , '||', IFNULL(TRIM(BSTYP::text), '^^') 
            , '||', IFNULL(TRIM(WEPOS::text), '^^') 
            , '||', IFNULL(TRIM(REPOS::text), '^^') 
            , '||', IFNULL(TRIM(LRGDT::text), '^^') 
            , '||', IFNULL(TRIM(PRGRS::text), '^^') 
            , '||', IFNULL(TRIM(TDDAT::text), '^^') 
            , '||', IFNULL(TRIM(MBDAT::text), '^^') 
            , '||', IFNULL(TRIM(LDDAT::text), '^^') 
            , '||', IFNULL(TRIM(WADAT::text), '^^') 
            , '||', IFNULL(TRIM(CMENG::text), '^^') 
            , '||', IFNULL(TRIM(LIFSP::text), '^^') 
            , '||', IFNULL(TRIM(GRSTR::text), '^^') 
            , '||', IFNULL(TRIM(ABART::text), '^^') 
            , '||', IFNULL(TRIM(ABRUF::text), '^^') 
            , '||', IFNULL(TRIM(ROMS1::text), '^^') 
            , '||', IFNULL(TRIM(ROMS2::text), '^^') 
            , '||', IFNULL(TRIM(ROMS3::text), '^^') 
            , '||', IFNULL(TRIM(ROMEI::text), '^^') 
            , '||', IFNULL(TRIM(RFORM::text), '^^') 
            , '||', IFNULL(TRIM(UMVKZ::text), '^^') 
            , '||', IFNULL(TRIM(UMVKN::text), '^^') 
            , '||', IFNULL(TRIM(VERFP::text), '^^') 
            , '||', IFNULL(TRIM(BWART::text), '^^') 
            , '||', IFNULL(TRIM(BNFPO::text), '^^') 
            , '||', IFNULL(TRIM(ETART::text), '^^') 
            , '||', IFNULL(TRIM(AUFNR::text), '^^') 
            , '||', IFNULL(TRIM(PLNUM::text), '^^') 
            , '||', IFNULL(TRIM(SERNR::text), '^^') 
            , '||', IFNULL(TRIM(AESKD::text), '^^') 
            , '||', IFNULL(TRIM(ABGES::text), '^^') 
            , '||', IFNULL(TRIM(MBUHR::text), '^^') 
            , '||', IFNULL(TRIM(TDUHR::text), '^^') 
            , '||', IFNULL(TRIM(LDUHR::text), '^^') 
            , '||', IFNULL(TRIM(WAUHR::text), '^^') 
            , '||', IFNULL(TRIM(AULWE::text), '^^') 
            , '||', IFNULL(TRIM(HANDOVERDATE::text), '^^') 
            , '||', IFNULL(TRIM(HANDOVERTIME::text), '^^') 
            , '||', IFNULL(TRIM(_DATAAGING::text), '^^') 
            , '||', IFNULL(TRIM(FSH_RALLOC_QTY::text), '^^') 
            , '||', IFNULL(TRIM(FSH_OS_ID::text), '^^') 
            , '||', IFNULL(TRIM(FSH_PQR_RC::text), '^^') 
            , '||', IFNULL(TRIM(MBDAT_DRS::text), '^^') 
            , '||', IFNULL(TRIM(ZZRSD::text), '^^') 
            , '||', IFNULL(TRIM(ZZMAD::text), '^^') 
            , '||', IFNULL(TRIM(ZZREC::text), '^^') 
            , '||', IFNULL(TRIM(ZZORV::text), '^^') 
            , '||', IFNULL(TRIM(ZZRST::text), '^^') 
            , '||', IFNULL(TRIM(ZZPDT::text), '^^') 
            , '||', IFNULL(TRIM(ZZPDTCNT::text), '^^') 
            , '||', IFNULL(TRIM(ZZOPDT::text), '^^') 
            , '||', IFNULL(TRIM(ZZCRSDCODE::text), '^^') 
            , '||', IFNULL(TRIM(ZZKUNWE::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(PAYER_PARVW::text), '^^') 
            , '||', IFNULL(TRIM(BILLTO_PARVW::text), '^^') 
            , '||', IFNULL(TRIM(SHIPTO_PARVW::text), '^^') 
            , '||', IFNULL(TRIM(SOLDTO_PARVW::text), '^^') 
            , '||', IFNULL(TRIM(INSURANCE_PARVW::text), '^^') 
            , '||', IFNULL(TRIM(PAYER_KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(BILLTO_KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(SHIPTO_KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(SOLDTO_KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(INSURANCE_KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(VBAP_MATNR::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
