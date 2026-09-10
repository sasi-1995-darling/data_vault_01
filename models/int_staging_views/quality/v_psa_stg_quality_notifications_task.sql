---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_qmsm') }} as SRC  ),
SRC_b              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM SAP_ECC_PRD.Z_QMSM )
, SRC_b              as ( SELECT * FROM RAW_VAULT.REF_BUSINESS_KEY_COLLISION )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        CONCAT_WS('||', COALESCE(QMNUM, ''), COALESCE(MANUM, ''))    as QUALITY_TASKS_BK
      , to_char(coalesce(QMNUM,'-1'))                                as QUALITY_NOTIFICATION_BK
      , CONCAT_WS('||', COALESCE(QMNUM, ''), COALESCE(FENUM, ''), COALESCE(URNUM, '')) as QUALITY_CAUSES_BK
      , CONCAT_WS('||', COALESCE(QMNUM, ''), COALESCE(MANUM, ''))    as QUALITY_ACTIVITY_BK
      , CONCAT_WS('||', COALESCE(QMNUM, ''), COALESCE(FENUM, ''))    as QUALITY_ITEMS_BK
      , MANDT
      , QMNUM
      , MANUM
      , GLREQUEST
      , MNKAT
      , MNGRP
      , MNCOD
      , MNVER
      , FOLGEACT
      , FOLACTPROT
      , MATXT
      , ERNAM
      , ERDAT
      , AENAM
      , AEDAT
      , PSTER
      , PETER
      , OBJNR
      , INDTX
      , KZMLA
      , PSTUR
      , PETUR
      , ERLNAM
      , ERLDAT
      , ERLZEIT
      , WDVDAT
      , FENUM
      , URNUM
      , ERZEIT
      , AEZEIT
      , PARVW
      , PARNR
      , MMENGE
      , MMGEIN
      , BAUTL
      , KZLOESCH
      , QSMNUM
      , AUTKZ
      , HANDLE
      , TSEGFL
      , TSEGTP
      , TZONSO
      , TZONSM
      , TZONID
      , KZACTIONBOX
      , FUNKTION
      , "/SAPSMOSS/NOTE" as SAPSMOSS_NOTE
      , "/SAPSMOSS/REPORT" as SAPSMOSS_REPORT
      , "/SAPSMOSS/MTSTMP" as SAPSMOSS_MTSTMP
      , ABC_TEMPL
      , EFFECTPERC
      , EFFECTTEXT
      , ZZTASK_DATE
      , ZZOPTION
      , ZZLIFNR
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
        ))   as LOAD_DTS
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
        QUALITY_TASKS_BK
      , QUALITY_NOTIFICATION_BK
      , QUALITY_CAUSES_BK
      , QUALITY_ACTIVITY_BK
      , QUALITY_ITEMS_BK
      , MANDT
      , QMNUM
      , MANUM
      , GLREQUEST
      , MNKAT
      , MNGRP
      , MNCOD
      , MNVER
      , FOLGEACT
      , FOLACTPROT
      , MATXT
      , ERNAM
      , ERDAT
      , AENAM
      , AEDAT
      , PSTER
      , PETER
      , OBJNR
      , INDTX
      , KZMLA
      , PSTUR
      , PETUR
      , ERLNAM
      , ERLDAT
      , ERLZEIT
      , WDVDAT
      , FENUM
      , URNUM
      , ERZEIT
      , AEZEIT
      , PARVW
      , PARNR
      , MMENGE
      , MMGEIN
      , BAUTL
      , KZLOESCH
      , QSMNUM
      , AUTKZ
      , HANDLE
      , TSEGFL
      , TSEGTP
      , TZONSO
      , TZONSM
      , TZONID
      , KZACTIONBOX
      , FUNKTION
      , SAPSMOSS_NOTE
      , SAPSMOSS_REPORT
      , SAPSMOSS_MTSTMP
      , ABC_TEMPL
      , EFFECTPERC
      , EFFECTTEXT
      , ZZTASK_DATE
      , ZZOPTION
      , ZZLIFNR
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_QMSM'
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
          QUALITY_TASKS_BK
        , QUALITY_NOTIFICATION_BK
        , QUALITY_CAUSES_BK
        , QUALITY_ACTIVITY_BK
        , QUALITY_ITEMS_BK
        , MANDT
        , QMNUM
        , MANUM
        , GLREQUEST
        , MNKAT
        , MNGRP
        , MNCOD
        , MNVER
        , FOLGEACT
        , FOLACTPROT
        , MATXT
        , ERNAM
        , ERDAT
        , AENAM
        , AEDAT
        , PSTER
        , PETER
        , OBJNR
        , INDTX
        , KZMLA
        , PSTUR
        , PETUR
        , ERLNAM
        , ERLDAT
        , ERLZEIT
        , WDVDAT
        , FENUM
        , URNUM
        , ERZEIT
        , AEZEIT
        , PARVW
        , PARNR
        , MMENGE
        , MMGEIN
        , BAUTL
        , KZLOESCH
        , QSMNUM
        , AUTKZ
        , HANDLE
        , TSEGFL
        , TSEGTP
        , TZONSO
        , TZONSM
        , TZONID
        , KZACTIONBOX
        , FUNKTION
        , SAPSMOSS_NOTE
        , SAPSMOSS_REPORT
        , SAPSMOSS_MTSTMP
        , ABC_TEMPL
        , EFFECTPERC
        , EFFECTTEXT
        , ZZTASK_DATE
        , ZZOPTION
        , ZZLIFNR
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , IFF(QMNUM IS NULL, '-1', CONCAT_WS('||', QMNUM, BKCC)) as drvd_notification_bkcc
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(QMNUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(MANUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as QUALITY_TASKS_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(drvd_notification_bkcc as VARCHAR)),''), '^^')
        ))) as QUALITY_NOTIFICATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(QMNUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(FENUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(URNUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as QUALITY_CAUSES_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(QMNUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(MANUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as QUALITY_ACTIVITY_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(QMNUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(FENUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as QUALITY_ITEMS_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(QUALITY_TASKS_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(QUALITY_NOTIFICATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as QUALITY_NOTIFICATION_TASK_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(QMNUM::text), '^^') 
            , '||', IFNULL(TRIM(MANUM::text), '^^')  
            , '||', IFNULL(TRIM(MNKAT::text), '^^') 
            , '||', IFNULL(TRIM(MNGRP::text), '^^') 
            , '||', IFNULL(TRIM(MNCOD::text), '^^') 
            , '||', IFNULL(TRIM(MNVER::text), '^^') 
            , '||', IFNULL(TRIM(FOLGEACT::text), '^^') 
            , '||', IFNULL(TRIM(FOLACTPROT::text), '^^') 
            , '||', IFNULL(TRIM(MATXT::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(AENAM::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(PSTER::text), '^^') 
            , '||', IFNULL(TRIM(PETER::text), '^^') 
            , '||', IFNULL(TRIM(OBJNR::text), '^^') 
            , '||', IFNULL(TRIM(INDTX::text), '^^') 
            , '||', IFNULL(TRIM(KZMLA::text), '^^') 
            , '||', IFNULL(TRIM(PSTUR::text), '^^') 
            , '||', IFNULL(TRIM(PETUR::text), '^^') 
            , '||', IFNULL(TRIM(ERLNAM::text), '^^') 
            , '||', IFNULL(TRIM(ERLDAT::text), '^^') 
            , '||', IFNULL(TRIM(ERLZEIT::text), '^^') 
            , '||', IFNULL(TRIM(WDVDAT::text), '^^') 
            , '||', IFNULL(TRIM(FENUM::text), '^^') 
            , '||', IFNULL(TRIM(URNUM::text), '^^') 
            , '||', IFNULL(TRIM(ERZEIT::text), '^^') 
            , '||', IFNULL(TRIM(AEZEIT::text), '^^') 
            , '||', IFNULL(TRIM(PARVW::text), '^^') 
            , '||', IFNULL(TRIM(PARNR::text), '^^') 
            , '||', IFNULL(TRIM(MMENGE::text), '^^') 
            , '||', IFNULL(TRIM(MMGEIN::text), '^^') 
            , '||', IFNULL(TRIM(BAUTL::text), '^^') 
            , '||', IFNULL(TRIM(KZLOESCH::text), '^^') 
            , '||', IFNULL(TRIM(QSMNUM::text), '^^') 
            , '||', IFNULL(TRIM(AUTKZ::text), '^^') 
            , '||', IFNULL(TRIM(HANDLE::text), '^^') 
            , '||', IFNULL(TRIM(TSEGFL::text), '^^') 
            , '||', IFNULL(TRIM(TSEGTP::text), '^^') 
            , '||', IFNULL(TRIM(TZONSO::text), '^^') 
            , '||', IFNULL(TRIM(TZONSM::text), '^^') 
            , '||', IFNULL(TRIM(TZONID::text), '^^') 
            , '||', IFNULL(TRIM(KZACTIONBOX::text), '^^') 
            , '||', IFNULL(TRIM(FUNKTION::text), '^^') 
            , '||', IFNULL(TRIM(SAPSMOSS_NOTE::text), '^^') 
            , '||', IFNULL(TRIM(SAPSMOSS_REPORT::text), '^^') 
            , '||', IFNULL(TRIM(SAPSMOSS_MTSTMP::text), '^^') 
            , '||', IFNULL(TRIM(ABC_TEMPL::text), '^^') 
            , '||', IFNULL(TRIM(EFFECTPERC::text), '^^') 
            , '||', IFNULL(TRIM(EFFECTTEXT::text), '^^') 
            , '||', IFNULL(TRIM(ZZTASK_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ZZOPTION::text), '^^') 
            , '||', IFNULL(TRIM(ZZLIFNR::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^')  
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT