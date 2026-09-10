---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_qmur') }} as SRC  ),
SRC_b              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM SAP_ECC_PRD.Z_QMUR )
, SRC_b              as ( SELECT * FROM RAW_VAULT.REF_BUSINESS_KEY_COLLISION )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        CONCAT_WS('||', COALESCE(QMNUM, ''), COALESCE(FENUM, ''), COALESCE(URNUM, '')) as QUALITY_CAUSES_BK
      , CONCAT_WS('||', COALESCE(QMNUM, ''), COALESCE(FENUM, '')) as QUALITY_ITEMS_BK
      , to_char(coalesce(QMNUM,'-1')) as QUALITY_NOTIFICATION_BK
      , CONCAT_WS('||',COALESCE(QMNUM,''), COALESCE(FENUM,'')) as  QUALITY_ISSUE_BK
      , MANDT
      , QMNUM
      , FENUM
      , URNUM
      , GLREQUEST
      , ERNAM
      , ERDAT
      , AENAM
      , AEDAT
      , URTXT
      , URKAT
      , URGRP
      , URCOD
      , URVER
      , INDTX
      , KZMLA
      , ERZEIT
      , AEZEIT
      , VUKAT
      , VUGRP
      , VUCOD
      , PARVW
      , PARNR
      , BAUTL
      , URMENGE
      , URMGEIN
      , KZLOESCH
      , QURNUM
      , AUTKZ
      , INVOLVPERC
      , ZZREVLV
      , ZZREASON_GRP
      , ZZREASON_COD
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
        QUALITY_CAUSES_BK
      , QUALITY_ITEMS_BK
      , QUALITY_NOTIFICATION_BK
      , QUALITY_ISSUE_BK
      , MANDT
      , QMNUM
      , FENUM
      , URNUM
      , GLREQUEST
      , ERNAM
      , ERDAT
      , AENAM
      , AEDAT
      , URTXT
      , URKAT
      , URGRP
      , URCOD
      , URVER
      , INDTX
      , KZMLA
      , ERZEIT
      , AEZEIT
      , VUKAT
      , VUGRP
      , VUCOD
      , PARVW
      , PARNR
      , BAUTL
      , URMENGE
      , URMGEIN
      , KZLOESCH
      , QURNUM
      , AUTKZ
      , INVOLVPERC
      , ZZREVLV
      , ZZREASON_GRP
      , ZZREASON_COD
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_QMUR'
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
          QUALITY_CAUSES_BK
        , QUALITY_ITEMS_BK
        , QUALITY_NOTIFICATION_BK
        , QUALITY_ISSUE_BK
        , MANDT
        , QMNUM
        , FENUM
        , URNUM
        , GLREQUEST
        , ERNAM
        , ERDAT
        , AENAM
        , AEDAT
        , URTXT
        , URKAT
        , URGRP
        , URCOD
        , URVER
        , INDTX
        , KZMLA
        , ERZEIT
        , AEZEIT
        , VUKAT
        , VUGRP
        , VUCOD
        , PARVW
        , PARNR
        , BAUTL
        , URMENGE
        , URMGEIN
        , KZLOESCH
        , QURNUM
        , AUTKZ
        , INVOLVPERC
        , ZZREVLV
        , ZZREASON_GRP
        , ZZREASON_COD
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , IFF(QMNUM IS NULL, '-1', CONCAT_WS('||', QMNUM, BKCC)) as drvd_notification_bkcc
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(QUALITY_CAUSES_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as QUALITY_CAUSES_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(QUALITY_ITEMS_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as QUALITY_ITEMS_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(drvd_notification_bkcc as VARCHAR)),''), '^^')
        ))) as QUALITY_NOTIFICATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||'
        , COALESCE(NULLIF(TRIM(CAST(QMNUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(FENUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as QUALITY_ISSUE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(QUALITY_CAUSES_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(QUALITY_ISSUE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as QUALITY_ISSUE_CAUSES_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
             '||', IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(QMNUM::text), '^^') 
            , '||', IFNULL(TRIM(FENUM::text), '^^') 
            , '||', IFNULL(TRIM(URNUM::text), '^^')  
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(AENAM::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(URTXT::text), '^^') 
            , '||', IFNULL(TRIM(URKAT::text), '^^') 
            , '||', IFNULL(TRIM(URGRP::text), '^^') 
            , '||', IFNULL(TRIM(URCOD::text), '^^') 
            , '||', IFNULL(TRIM(URVER::text), '^^') 
            , '||', IFNULL(TRIM(INDTX::text), '^^') 
            , '||', IFNULL(TRIM(KZMLA::text), '^^') 
            , '||', IFNULL(TRIM(ERZEIT::text), '^^') 
            , '||', IFNULL(TRIM(AEZEIT::text), '^^') 
            , '||', IFNULL(TRIM(VUKAT::text), '^^') 
            , '||', IFNULL(TRIM(VUGRP::text), '^^') 
            , '||', IFNULL(TRIM(VUCOD::text), '^^') 
            , '||', IFNULL(TRIM(PARVW::text), '^^') 
            , '||', IFNULL(TRIM(PARNR::text), '^^') 
            , '||', IFNULL(TRIM(BAUTL::text), '^^') 
            , '||', IFNULL(TRIM(URMENGE::text), '^^') 
            , '||', IFNULL(TRIM(URMGEIN::text), '^^') 
            , '||', IFNULL(TRIM(KZLOESCH::text), '^^') 
            , '||', IFNULL(TRIM(QURNUM::text), '^^') 
            , '||', IFNULL(TRIM(AUTKZ::text), '^^') 
            , '||', IFNULL(TRIM(INVOLVPERC::text), '^^') 
            , '||', IFNULL(TRIM(ZZREVLV::text), '^^') 
            , '||', IFNULL(TRIM(ZZREASON_GRP::text), '^^') 
            , '||', IFNULL(TRIM(ZZREASON_COD::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^')
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
