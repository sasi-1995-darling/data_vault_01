---- SRC LAYER ----
WITH
SRC_s              as ( SELECT "/BEV1/EMLGFORTS", "/BEV1/EMLGPFAND", AGREL, ANTLF, AUFSD, AUTLF, AWAHR, BEGRU, BLIND, BOIDT, BOKRE, BZIRK, CARRIER_NOTIF, CASSD, 
                        CHSPL, CVP_XBLCK_V, EIKTO, ERDAT, ERNAM, FAKSD, FSH_GRREG, FSH_GRSGY, FSH_KVGR10, FSH_KVGR6, FSH_KVGR7, FSH_KVGR8, FSH_KVGR9, FSH_MSOCDC, 
                        FSH_MSOPID, FSH_RESGY, FSH_SC_CID, FSH_SS, FSH_VAS_CG, FSH_VAS_DETC, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, INCO1, INCO2, 
                        INCO2_L, INCO3_L, INCOV, KABSS, KALKS, KDGRP, KKBER, KLABC, KONDA, KTGRD, KUNNR, KURST, KVAKZ, KVAWT, KVGR1, KVGR2, KVGR3, KVGR4, KVGR5, 
                        KZAZU, KZTLF, LIFSD, LOEVM, LPRIO, MANDT, MEGRU, MRNKZ, PERFK, PERRL, PLTYP, PODKZ, PODTG, PRAT1, PRAT2, PRAT3, PRAT4, PRAT5, PRAT6, PRAT7, 
                        PRAT8, PRAT9, PRATA, PRFRE, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PVKSM, RDOFF, SPART, UEBTK, UEBTO, UNTTO, VERSG, VKBUR, VKGRP, 
                        VKORG, VSBED, VSORT, VTWEG, VWERK, WAERS, ZOLD_CUSTOMER, ZTERM, ZZACCT, ZZACCTNAME, ZZAPO_PRICE_ACCT, ZZBPEXC, ZZBRSCH, ZZCID, ZZCMBDELVINV, 
                        ZZCONSOLIDATE, ZZGROUP_APO, ZZKATR1, ZZKATR2, ZZKATR3, ZZSHWOR, ZZSNGOR, ZZSOD, ZZTAXABLE, ZZTEA, ZZTMS, ZZTMSEXE, ZZW2B 
                        FROM {{ source('sap_ecc_prd', 'z_knvv') }} as SRC  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_s              as ( SELECT * FROM sap_ecc_prd.z_knvv )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        COALESCE(NULLIF(TRIM(KUNNR),''),'-1')                        as                                        CUSTOMER_BK
      , COALESCE(NULLIF(TRIM(VKORG),''),'-1')                        as                              SALES_ORGANIZATION_BK
      , COALESCE(NULLIF(TRIM(VTWEG),''),'-1')                        as                            DISTRIBUTION_CHANNEL_BK
      , COALESCE(NULLIF(TRIM(SPART),''),'-1')                        as                                        DIVISION_BK
      , COALESCE(NULLIF(TRIM(KVGR1),''),'-2')                        as                                     KEY_ACCOUNT_BK
      , COALESCE(NULLIF(TRIM(KVGR2),''),'-2')                        as                               KEY_ACCOUNT_GROUP_BK
      , MANDT
      , KUNNR
      , VKORG
      , VTWEG
      , SPART
      , GLREQUEST
      , ERNAM
      , ERDAT
      , BEGRU
      , LOEVM
      , VERSG
      , AUFSD
      , KALKS
      , KDGRP
      , BZIRK
      , KONDA
      , PLTYP
      , AWAHR
      , INCO1
      , INCO2
      , LIFSD
      , AUTLF
      , ANTLF
      , KZTLF
      , KZAZU
      , CHSPL
      , LPRIO
      , EIKTO
      , VSBED
      , FAKSD
      , MRNKZ
      , PERFK
      , PERRL
      , KVAKZ
      , KVAWT
      , WAERS
      , KLABC
      , KTGRD
      , ZTERM
      , VWERK
      , VKGRP
      , VKBUR
      , VSORT
      , KVGR1
      , KVGR2
      , KVGR3
      , KVGR4
      , KVGR5
      , BOKRE
      , BOIDT
      , KURST
      , PRFRE
      , PRAT1
      , PRAT2
      , PRAT3
      , PRAT4
      , PRAT5
      , PRAT6
      , PRAT7
      , PRAT8
      , PRAT9
      , PRATA
      , KABSS
      , KKBER
      , CASSD
      , RDOFF
      , AGREL
      , MEGRU
      , UEBTO
      , UNTTO
      , UEBTK
      , PVKSM
      , PODKZ
      , PODTG
      , BLIND
      , CARRIER_NOTIF
      , CVP_XBLCK_V
      , INCOV
      , INCO2_L
      , INCO3_L
      , "/BEV1/EMLGPFAND"                                            as                                     BEV1_EMLGPFAND
      , "/BEV1/EMLGFORTS"                                            as                                     BEV1_EMLGFORTS
      , FSH_KVGR6
      , FSH_KVGR7
      , FSH_KVGR8
      , FSH_KVGR9
      , FSH_KVGR10
      , FSH_GRREG
      , FSH_RESGY
      , FSH_SC_CID
      , FSH_VAS_DETC
      , FSH_VAS_CG
      , FSH_GRSGY
      , FSH_SS
      , FSH_MSOCDC
      , FSH_MSOPID
      , ZOLD_CUSTOMER
      , ZZTEA
      , ZZBRSCH
      , ZZKATR1
      , ZZKATR2
      , ZZKATR3
      , ZZGROUP_APO
      , ZZAPO_PRICE_ACCT
      , ZZSNGOR
      , ZZSHWOR
      , ZZW2B
      , ZZSOD
      , ZZACCT
      , ZZACCTNAME
      , ZZCMBDELVINV
      , ZZTAXABLE
      , ZZCID
      , ZZTMS
      , ZZCONSOLIDATE
      , ZZTMSEXE
      , ZZBPEXC
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
        ))                                                            as                                           LOAD_DTS
    FROM SRC_s
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        CUSTOMER_BK
      , SALES_ORGANIZATION_BK
      , DISTRIBUTION_CHANNEL_BK
      , DIVISION_BK
      , KEY_ACCOUNT_BK
      , KEY_ACCOUNT_GROUP_BK
      , MANDT
      , KUNNR
      , VKORG
      , VTWEG
      , SPART
      , GLREQUEST
      , ERNAM
      , ERDAT
      , BEGRU
      , LOEVM
      , VERSG
      , AUFSD
      , KALKS
      , KDGRP
      , BZIRK
      , KONDA
      , PLTYP
      , AWAHR
      , INCO1
      , INCO2
      , LIFSD
      , AUTLF
      , ANTLF
      , KZTLF
      , KZAZU
      , CHSPL
      , LPRIO
      , EIKTO
      , VSBED
      , FAKSD
      , MRNKZ
      , PERFK
      , PERRL
      , KVAKZ
      , KVAWT
      , WAERS
      , KLABC
      , KTGRD
      , ZTERM
      , VWERK
      , VKGRP
      , VKBUR
      , VSORT
      , KVGR1
      , KVGR2
      , KVGR3
      , KVGR4
      , KVGR5
      , BOKRE
      , BOIDT
      , KURST
      , PRFRE
      , PRAT1
      , PRAT2
      , PRAT3
      , PRAT4
      , PRAT5
      , PRAT6
      , PRAT7
      , PRAT8
      , PRAT9
      , PRATA
      , KABSS
      , KKBER
      , CASSD
      , RDOFF
      , AGREL
      , MEGRU
      , UEBTO
      , UNTTO
      , UEBTK
      , PVKSM
      , PODKZ
      , PODTG
      , BLIND
      , CARRIER_NOTIF
      , CVP_XBLCK_V
      , INCOV
      , INCO2_L
      , INCO3_L
      , BEV1_EMLGPFAND
      , BEV1_EMLGFORTS
      , FSH_KVGR6
      , FSH_KVGR7
      , FSH_KVGR8
      , FSH_KVGR9
      , FSH_KVGR10
      , FSH_GRREG
      , FSH_RESGY
      , FSH_SC_CID
      , FSH_VAS_DETC
      , FSH_VAS_CG
      , FSH_GRSGY
      , FSH_SS
      , FSH_MSOCDC
      , FSH_MSOPID
      , ZOLD_CUSTOMER
      , ZZTEA
      , ZZBRSCH
      , ZZKATR1
      , ZZKATR2
      , ZZKATR3
      , ZZGROUP_APO
      , ZZAPO_PRICE_ACCT
      , ZZSNGOR
      , ZZSHWOR
      , ZZW2B
      , ZZSOD
      , ZZACCT
      , ZZACCTNAME
      , ZZCMBDELVINV
      , ZZTAXABLE
      , ZZCID
      , ZZTMS
      , ZZCONSOLIDATE
      , ZZTMSEXE
      , ZZBPEXC
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_s
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_KNVV'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          CUSTOMER_BK
        , SALES_ORGANIZATION_BK
        , DISTRIBUTION_CHANNEL_BK
        , DIVISION_BK
        , KEY_ACCOUNT_BK
        , KEY_ACCOUNT_GROUP_BK
        , MANDT
        , KUNNR
        , VKORG
        , VTWEG
        , SPART
        , GLREQUEST
        , ERNAM
        , ERDAT
        , BEGRU
        , LOEVM
        , VERSG
        , AUFSD
        , KALKS
        , KDGRP
        , BZIRK
        , KONDA
        , PLTYP
        , AWAHR
        , INCO1
        , INCO2
        , LIFSD
        , AUTLF
        , ANTLF
        , KZTLF
        , KZAZU
        , CHSPL
        , LPRIO
        , EIKTO
        , VSBED
        , FAKSD
        , MRNKZ
        , PERFK
        , PERRL
        , KVAKZ
        , KVAWT
        , WAERS
        , KLABC
        , KTGRD
        , ZTERM
        , VWERK
        , VKGRP
        , VKBUR
        , VSORT
        , KVGR1
        , KVGR2
        , KVGR3
        , KVGR4
        , KVGR5
        , BOKRE
        , BOIDT
        , KURST
        , PRFRE
        , PRAT1
        , PRAT2
        , PRAT3
        , PRAT4
        , PRAT5
        , PRAT6
        , PRAT7
        , PRAT8
        , PRAT9
        , PRATA
        , KABSS
        , KKBER
        , CASSD
        , RDOFF
        , AGREL
        , MEGRU
        , UEBTO
        , UNTTO
        , UEBTK
        , PVKSM
        , PODKZ
        , PODTG
        , BLIND
        , CARRIER_NOTIF
        , CVP_XBLCK_V
        , INCOV
        , INCO2_L
        , INCO3_L
        , BEV1_EMLGPFAND
        , BEV1_EMLGFORTS
        , FSH_KVGR6
        , FSH_KVGR7
        , FSH_KVGR8
        , FSH_KVGR9
        , FSH_KVGR10
        , FSH_GRREG
        , FSH_RESGY
        , FSH_SC_CID
        , FSH_VAS_DETC
        , FSH_VAS_CG
        , FSH_GRSGY
        , FSH_SS
        , FSH_MSOCDC
        , FSH_MSOPID
        , ZOLD_CUSTOMER
        , ZZTEA
        , ZZBRSCH
        , ZZKATR1
        , ZZKATR2
        , ZZKATR3
        , ZZGROUP_APO
        , ZZAPO_PRICE_ACCT
        , ZZSNGOR
        , ZZSHWOR
        , ZZW2B
        , ZZSOD
        , ZZACCT
        , ZZACCTNAME
        , ZZCMBDELVINV
        , ZZTAXABLE
        , ZZCID
        , ZZTMS
        , ZZCONSOLIDATE
        , ZZTMSEXE
        , ZZBPEXC
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
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SALES_ORGANIZATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SALES_ORGANIZATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DISTRIBUTION_CHANNEL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DISTRIBUTION_CHANNEL_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DIVISION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(KEY_ACCOUNT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as KEY_ACCOUNT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(KEY_ACCOUNT_GROUP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as KEY_ACCOUNT_GROUP_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SALES_ORGANIZATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DISTRIBUTION_CHANNEL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SALES_ORGANIZATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DISTRIBUTION_CHANNEL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(KEY_ACCOUNT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(KEY_ACCOUNT_GROUP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_KEY_ACCOUNT_KEY_ACCOUNT_GROUP_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(VKORG::text), '^^') 
            , '||', IFNULL(TRIM(VTWEG::text), '^^') 
            , '||', IFNULL(TRIM(SPART::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(BEGRU::text), '^^') 
            , '||', IFNULL(TRIM(LOEVM::text), '^^') 
            , '||', IFNULL(TRIM(VERSG::text), '^^') 
            , '||', IFNULL(TRIM(AUFSD::text), '^^') 
            , '||', IFNULL(TRIM(KALKS::text), '^^') 
            , '||', IFNULL(TRIM(KDGRP::text), '^^') 
            , '||', IFNULL(TRIM(BZIRK::text), '^^') 
            , '||', IFNULL(TRIM(KONDA::text), '^^') 
            , '||', IFNULL(TRIM(PLTYP::text), '^^') 
            , '||', IFNULL(TRIM(AWAHR::text), '^^') 
            , '||', IFNULL(TRIM(INCO1::text), '^^') 
            , '||', IFNULL(TRIM(INCO2::text), '^^') 
            , '||', IFNULL(TRIM(LIFSD::text), '^^') 
            , '||', IFNULL(TRIM(AUTLF::text), '^^') 
            , '||', IFNULL(TRIM(ANTLF::text), '^^') 
            , '||', IFNULL(TRIM(KZTLF::text), '^^') 
            , '||', IFNULL(TRIM(KZAZU::text), '^^') 
            , '||', IFNULL(TRIM(CHSPL::text), '^^') 
            , '||', IFNULL(TRIM(LPRIO::text), '^^') 
            , '||', IFNULL(TRIM(EIKTO::text), '^^') 
            , '||', IFNULL(TRIM(VSBED::text), '^^') 
            , '||', IFNULL(TRIM(FAKSD::text), '^^') 
            , '||', IFNULL(TRIM(MRNKZ::text), '^^') 
            , '||', IFNULL(TRIM(PERFK::text), '^^') 
            , '||', IFNULL(TRIM(PERRL::text), '^^') 
            , '||', IFNULL(TRIM(KVAKZ::text), '^^') 
            , '||', IFNULL(TRIM(KVAWT::text), '^^') 
            , '||', IFNULL(TRIM(WAERS::text), '^^') 
            , '||', IFNULL(TRIM(KLABC::text), '^^') 
            , '||', IFNULL(TRIM(KTGRD::text), '^^') 
            , '||', IFNULL(TRIM(ZTERM::text), '^^') 
            , '||', IFNULL(TRIM(VWERK::text), '^^') 
            , '||', IFNULL(TRIM(VKGRP::text), '^^') 
            , '||', IFNULL(TRIM(VKBUR::text), '^^') 
            , '||', IFNULL(TRIM(VSORT::text), '^^') 
            , '||', IFNULL(TRIM(KVGR1::text), '^^') 
            , '||', IFNULL(TRIM(KVGR2::text), '^^') 
            , '||', IFNULL(TRIM(KVGR3::text), '^^') 
            , '||', IFNULL(TRIM(KVGR4::text), '^^') 
            , '||', IFNULL(TRIM(KVGR5::text), '^^') 
            , '||', IFNULL(TRIM(BOKRE::text), '^^') 
            , '||', IFNULL(TRIM(BOIDT::text), '^^') 
            , '||', IFNULL(TRIM(KURST::text), '^^') 
            , '||', IFNULL(TRIM(PRFRE::text), '^^') 
            , '||', IFNULL(TRIM(PRAT1::text), '^^') 
            , '||', IFNULL(TRIM(PRAT2::text), '^^') 
            , '||', IFNULL(TRIM(PRAT3::text), '^^') 
            , '||', IFNULL(TRIM(PRAT4::text), '^^') 
            , '||', IFNULL(TRIM(PRAT5::text), '^^') 
            , '||', IFNULL(TRIM(PRAT6::text), '^^') 
            , '||', IFNULL(TRIM(PRAT7::text), '^^') 
            , '||', IFNULL(TRIM(PRAT8::text), '^^') 
            , '||', IFNULL(TRIM(PRAT9::text), '^^') 
            , '||', IFNULL(TRIM(PRATA::text), '^^') 
            , '||', IFNULL(TRIM(KABSS::text), '^^') 
            , '||', IFNULL(TRIM(KKBER::text), '^^') 
            , '||', IFNULL(TRIM(CASSD::text), '^^') 
            , '||', IFNULL(TRIM(RDOFF::text), '^^') 
            , '||', IFNULL(TRIM(AGREL::text), '^^') 
            , '||', IFNULL(TRIM(MEGRU::text), '^^') 
            , '||', IFNULL(TRIM(UEBTO::text), '^^') 
            , '||', IFNULL(TRIM(UNTTO::text), '^^') 
            , '||', IFNULL(TRIM(UEBTK::text), '^^') 
            , '||', IFNULL(TRIM(PVKSM::text), '^^') 
            , '||', IFNULL(TRIM(PODKZ::text), '^^') 
            , '||', IFNULL(TRIM(PODTG::text), '^^') 
            , '||', IFNULL(TRIM(BLIND::text), '^^') 
            , '||', IFNULL(TRIM(CARRIER_NOTIF::text), '^^') 
            , '||', IFNULL(TRIM(CVP_XBLCK_V::text), '^^') 
            , '||', IFNULL(TRIM(INCOV::text), '^^') 
            , '||', IFNULL(TRIM(INCO2_L::text), '^^') 
            , '||', IFNULL(TRIM(INCO3_L::text), '^^') 
            , '||', IFNULL(TRIM(BEV1_EMLGPFAND::text), '^^') 
            , '||', IFNULL(TRIM(BEV1_EMLGFORTS::text), '^^') 
            , '||', IFNULL(TRIM(FSH_KVGR6::text), '^^') 
            , '||', IFNULL(TRIM(FSH_KVGR7::text), '^^') 
            , '||', IFNULL(TRIM(FSH_KVGR8::text), '^^') 
            , '||', IFNULL(TRIM(FSH_KVGR9::text), '^^') 
            , '||', IFNULL(TRIM(FSH_KVGR10::text), '^^') 
            , '||', IFNULL(TRIM(FSH_GRREG::text), '^^') 
            , '||', IFNULL(TRIM(FSH_RESGY::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SC_CID::text), '^^') 
            , '||', IFNULL(TRIM(FSH_VAS_DETC::text), '^^') 
            , '||', IFNULL(TRIM(FSH_VAS_CG::text), '^^') 
            , '||', IFNULL(TRIM(FSH_GRSGY::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SS::text), '^^') 
            , '||', IFNULL(TRIM(FSH_MSOCDC::text), '^^') 
            , '||', IFNULL(TRIM(FSH_MSOPID::text), '^^') 
            , '||', IFNULL(TRIM(ZOLD_CUSTOMER::text), '^^') 
            , '||', IFNULL(TRIM(ZZTEA::text), '^^') 
            , '||', IFNULL(TRIM(ZZBRSCH::text), '^^') 
            , '||', IFNULL(TRIM(ZZKATR1::text), '^^') 
            , '||', IFNULL(TRIM(ZZKATR2::text), '^^') 
            , '||', IFNULL(TRIM(ZZKATR3::text), '^^') 
            , '||', IFNULL(TRIM(ZZGROUP_APO::text), '^^') 
            , '||', IFNULL(TRIM(ZZAPO_PRICE_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(ZZSNGOR::text), '^^') 
            , '||', IFNULL(TRIM(ZZSHWOR::text), '^^') 
            , '||', IFNULL(TRIM(ZZW2B::text), '^^') 
            , '||', IFNULL(TRIM(ZZSOD::text), '^^') 
            , '||', IFNULL(TRIM(ZZACCT::text), '^^') 
            , '||', IFNULL(TRIM(ZZACCTNAME::text), '^^') 
            , '||', IFNULL(TRIM(ZZCMBDELVINV::text), '^^') 
            , '||', IFNULL(TRIM(ZZTAXABLE::text), '^^') 
            , '||', IFNULL(TRIM(ZZCID::text), '^^') 
            , '||', IFNULL(TRIM(ZZTMS::text), '^^') 
            , '||', IFNULL(TRIM(ZZCONSOLIDATE::text), '^^') 
            , '||', IFNULL(TRIM(ZZTMSEXE::text), '^^') 
            , '||', IFNULL(TRIM(ZZBPEXC::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
