---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_qmfe') }} as SRC  ),
SRC_b              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM SAP_ECC_PRD.Z_QMFE )
, SRC_b              as ( SELECT * FROM RAW_VAULT.REF_BUSINESS_KEY_COLLISION )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        CONCAT_WS('||',COALESCE(QMNUM,''), COALESCE(FENUM,'')) as  QUALITY_ISSUE_BK
      , to_char(coalesce(QMNUM,'-1')) as QUALITY_NOTIFICATION_BK
      , MANDT
      , QMNUM
      , FENUM
      , GLREQUEST
      , ERNAM
      , ERDAT
      , AENAM
      , AEDAT
      , FETXT
      , FEKAT
      , FEGRP
      , FECOD
      , FEVER
      , OTKAT
      , OTGRP
      , OTEIL
      , OTVER
      , BAUTL
      , EBORT
      , INDTX
      , KZMLA
      , ERZEIT
      , AEZEIT
      , KZORG
      , WDFEH
      , FEQKLAS
      , FCOAUFNR
      , FMGFRD
      , FMGEIG
      , FMGEIN
      , ANZFEHLER
      , FEHLBEW
      , UNITFLBEW
      , FEART
      , PNLKN
      , MERKNR
      , PROBENR
      , PHYNR
      , PRUEFLINR
      , CROBJTY
      , ARBPL
      , ARBPLWERK
      , FENUMORG
      , KZSYSFE
      , KZLOESCH
      , POSNR
      , HERPOS
      , AUTKZ
      , MATNR
      , WERKS
      , EKORG
      , INFNR
      , KOSTL
      , LSTAR
      , PRZNR
      , MENGE
      , EQUNR
      , TPLNR
      , ZZFAILURE_MODE
      , ZZINSTALLDATE
      , ZZMANUFDATE
      , ZZPAFNO
      , ZZITEMKAT1
      , ZZITEMGRP1
      , ZZITEMCOD1
      , ZZITEMKAT2
      , ZZITEMGRP2
      , ZZITEMCOD2
      , ZZITEMDATE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
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
))   as                                    LOAD_DTS
    FROM SRC_a
)

, LOGIC_b as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        QUALITY_ISSUE_BK
      , QUALITY_NOTIFICATION_BK
      , MANDT
      , QMNUM
      , FENUM
      , GLREQUEST
      , ERNAM
      , ERDAT
      , AENAM
      , AEDAT
      , FETXT
      , FEKAT
      , FEGRP
      , FECOD
      , FEVER
      , OTKAT
      , OTGRP
      , OTEIL
      , OTVER
      , BAUTL
      , EBORT
      , INDTX
      , KZMLA
      , ERZEIT
      , AEZEIT
      , KZORG
      , WDFEH
      , FEQKLAS
      , FCOAUFNR
      , FMGFRD
      , FMGEIG
      , FMGEIN
      , ANZFEHLER
      , FEHLBEW
      , UNITFLBEW
      , FEART
      , PNLKN
      , MERKNR
      , PROBENR
      , PHYNR
      , PRUEFLINR
      , CROBJTY
      , ARBPL
      , ARBPLWERK
      , FENUMORG
      , KZSYSFE
      , KZLOESCH
      , POSNR
      , HERPOS
      , AUTKZ
      , MATNR
      , WERKS
      , EKORG
      , INFNR
      , KOSTL
      , LSTAR
      , PRZNR
      , MENGE
      , EQUNR
      , TPLNR
      , ZZFAILURE_MODE
      , ZZINSTALLDATE
      , ZZMANUFDATE
      , ZZPAFNO
      , ZZITEMKAT1
      , ZZITEMGRP1
      , ZZITEMCOD1
      , ZZITEMKAT2
      , ZZITEMGRP2
      , ZZITEMCOD2
      , ZZITEMDATE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_a
)

, RENAME_b as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_b
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_b as (
    SELECT *
    FROM RENAME_b
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_QMFE'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_b
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          QUALITY_ISSUE_BK
        , QUALITY_NOTIFICATION_BK
        , MANDT
        , QMNUM
        , FENUM
        , GLREQUEST
        , ERNAM
        , ERDAT
        , AENAM
        , AEDAT
        , FETXT
        , FEKAT
        , FEGRP
        , FECOD
        , FEVER
        , OTKAT
        , OTGRP
        , OTEIL
        , OTVER
        , BAUTL
        , EBORT
        , INDTX
        , KZMLA
        , ERZEIT
        , AEZEIT
        , KZORG
        , WDFEH
        , FEQKLAS
        , FCOAUFNR
        , FMGFRD
        , FMGEIG
        , FMGEIN
        , ANZFEHLER
        , FEHLBEW
        , UNITFLBEW
        , FEART
        , PNLKN
        , MERKNR
        , PROBENR
        , PHYNR
        , PRUEFLINR
        , CROBJTY
        , ARBPL
        , ARBPLWERK
        , FENUMORG
        , KZSYSFE
        , KZLOESCH
        , POSNR
        , HERPOS
        , AUTKZ
        , MATNR
        , WERKS
        , EKORG
        , INFNR
        , KOSTL
        , LSTAR
        , PRZNR
        , MENGE
        , EQUNR
        , TPLNR
        , ZZFAILURE_MODE
        , ZZINSTALLDATE
        , ZZMANUFDATE
        , ZZPAFNO
        , ZZITEMKAT1
        , ZZITEMGRP1
        , ZZITEMCOD1
        , ZZITEMKAT2
        , ZZITEMGRP2
        , ZZITEMCOD2
        , ZZITEMDATE
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , IFF(QMNUM IS NULL, '-1', CONCAT_WS('||', QMNUM, BKCC)) as drvd_notification_bkcc
        , MD5_BINARY(UPPER(CONCAT_WS('||'
        , COALESCE(NULLIF(TRIM(CAST(QMNUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(FENUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as QUALITY_ISSUE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(drvd_notification_bkcc as VARCHAR)),''), '^^')
        ))) as QUALITY_NOTIFICATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(QUALITY_ISSUE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(QUALITY_NOTIFICATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as QUALITY_NOTIFICATION_ISSUE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(QMNUM::text), '^^') 
            , '||', IFNULL(TRIM(FENUM::text), '^^')  
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(AENAM::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(FETXT::text), '^^') 
            , '||', IFNULL(TRIM(FEKAT::text), '^^') 
            , '||', IFNULL(TRIM(FEGRP::text), '^^') 
            , '||', IFNULL(TRIM(FECOD::text), '^^') 
            , '||', IFNULL(TRIM(FEVER::text), '^^') 
            , '||', IFNULL(TRIM(OTKAT::text), '^^') 
            , '||', IFNULL(TRIM(OTGRP::text), '^^') 
            , '||', IFNULL(TRIM(OTEIL::text), '^^') 
            , '||', IFNULL(TRIM(OTVER::text), '^^') 
            , '||', IFNULL(TRIM(BAUTL::text), '^^') 
            , '||', IFNULL(TRIM(EBORT::text), '^^') 
            , '||', IFNULL(TRIM(INDTX::text), '^^') 
            , '||', IFNULL(TRIM(KZMLA::text), '^^') 
            , '||', IFNULL(TRIM(ERZEIT::text), '^^') 
            , '||', IFNULL(TRIM(AEZEIT::text), '^^') 
            , '||', IFNULL(TRIM(KZORG::text), '^^') 
            , '||', IFNULL(TRIM(WDFEH::text), '^^') 
            , '||', IFNULL(TRIM(FEQKLAS::text), '^^') 
            , '||', IFNULL(TRIM(FCOAUFNR::text), '^^') 
            , '||', IFNULL(TRIM(FMGFRD::text), '^^') 
            , '||', IFNULL(TRIM(FMGEIG::text), '^^') 
            , '||', IFNULL(TRIM(FMGEIN::text), '^^') 
            , '||', IFNULL(TRIM(ANZFEHLER::text), '^^') 
            , '||', IFNULL(TRIM(FEHLBEW::text), '^^') 
            , '||', IFNULL(TRIM(UNITFLBEW::text), '^^') 
            , '||', IFNULL(TRIM(FEART::text), '^^') 
            , '||', IFNULL(TRIM(PNLKN::text), '^^') 
            , '||', IFNULL(TRIM(MERKNR::text), '^^') 
            , '||', IFNULL(TRIM(PROBENR::text), '^^') 
            , '||', IFNULL(TRIM(PHYNR::text), '^^') 
            , '||', IFNULL(TRIM(PRUEFLINR::text), '^^') 
            , '||', IFNULL(TRIM(CROBJTY::text), '^^') 
            , '||', IFNULL(TRIM(ARBPL::text), '^^') 
            , '||', IFNULL(TRIM(ARBPLWERK::text), '^^') 
            , '||', IFNULL(TRIM(FENUMORG::text), '^^') 
            , '||', IFNULL(TRIM(KZSYSFE::text), '^^') 
            , '||', IFNULL(TRIM(KZLOESCH::text), '^^') 
            , '||', IFNULL(TRIM(POSNR::text), '^^') 
            , '||', IFNULL(TRIM(HERPOS::text), '^^') 
            , '||', IFNULL(TRIM(AUTKZ::text), '^^') 
            , '||', IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(EKORG::text), '^^') 
            , '||', IFNULL(TRIM(INFNR::text), '^^') 
            , '||', IFNULL(TRIM(KOSTL::text), '^^') 
            , '||', IFNULL(TRIM(LSTAR::text), '^^') 
            , '||', IFNULL(TRIM(PRZNR::text), '^^') 
            , '||', IFNULL(TRIM(MENGE::text), '^^') 
            , '||', IFNULL(TRIM(EQUNR::text), '^^') 
            , '||', IFNULL(TRIM(TPLNR::text), '^^') 
            , '||', IFNULL(TRIM(ZZFAILURE_MODE::text), '^^') 
            , '||', IFNULL(TRIM(ZZINSTALLDATE::text), '^^') 
            , '||', IFNULL(TRIM(ZZMANUFDATE::text), '^^') 
            , '||', IFNULL(TRIM(ZZPAFNO::text), '^^') 
            , '||', IFNULL(TRIM(ZZITEMKAT1::text), '^^') 
            , '||', IFNULL(TRIM(ZZITEMGRP1::text), '^^') 
            , '||', IFNULL(TRIM(ZZITEMCOD1::text), '^^') 
            , '||', IFNULL(TRIM(ZZITEMKAT2::text), '^^') 
            , '||', IFNULL(TRIM(ZZITEMGRP2::text), '^^') 
            , '||', IFNULL(TRIM(ZZITEMCOD2::text), '^^') 
            , '||', IFNULL(TRIM(ZZITEMDATE::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^')
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^')  
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
