---- SRC LAYER ----
WITH
SRC_c              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_csks') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_c              as ( SELECT * FROM sap_ecc_prd.z_csks )
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
      , to_char(coalesce(KOSTL,'-1'))                                as                                     COST_CENTER_BK
      , to_char(coalesce(DATBI,'-1'))                                as                                   VALID_DATE_TO_BK
      , MANDT
      , KOKRS
      , KOSTL
      , DATBI
      , GLREQUEST
      , DATAB
      , BKZKP
      , PKZKP
      , BUKRS
      , GSBER
      , KOSAR
      , VERAK
      , VERAK_USER
      , WAERS
      , KALSM
      , TXJCD
      , PRCTR
      , WERKS
      , LOGSYSTEM
      , ERSDA
      , USNAM
      , BKZKS
      , BKZER
      , BKZOB
      , PKZKS
      , PKZER
      , VMETH
      , MGEFL
      , ABTEI
      , NKOST
      , KVEWE
      , KAPPL
      , KOSZSCHL
      , LAND1
      , ANRED
      , NAME1
      , NAME2
      , NAME3
      , NAME4
      , ORT01
      , ORT02
      , STRAS
      , PFACH
      , PSTLZ
      , PSTL2
      , REGIO
      , SPRAS
      , TELBX
      , TELF1
      , TELF2
      , TELFX
      , TELTX
      , TELX1
      , DATLT
      , DRNAM
      , KHINR
      , CCKEY
      , KOMPL
      , STAKZ
      , OBJNR
      , FUNKT
      , AFUNK
      , CPI_TEMPL
      , CPD_TEMPL
      , FUNC_AREA
      , SCI_TEMPL
      , SCD_TEMPL
      , SKI_TEMPL
      , SKD_TEMPL
      , ZVKBUR
      , VNAME
      , RECID
      , ETYPE
      , JV_OTYPE
      , JV_JIBCL
      , JV_JIBSA
      , FERC_IND
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
      , COST_CENTER_BK
      , VALID_DATE_TO_BK
      , MANDT
      , KOKRS
      , KOSTL
      , DATBI
      , GLREQUEST
      , DATAB
      , BKZKP
      , PKZKP
      , BUKRS
      , GSBER
      , KOSAR
      , VERAK
      , VERAK_USER
      , WAERS
      , KALSM
      , TXJCD
      , PRCTR
      , WERKS
      , LOGSYSTEM
      , ERSDA
      , USNAM
      , BKZKS
      , BKZER
      , BKZOB
      , PKZKS
      , PKZER
      , VMETH
      , MGEFL
      , ABTEI
      , NKOST
      , KVEWE
      , KAPPL
      , KOSZSCHL
      , LAND1
      , ANRED
      , NAME1
      , NAME2
      , NAME3
      , NAME4
      , ORT01
      , ORT02
      , STRAS
      , PFACH
      , PSTLZ
      , PSTL2
      , REGIO
      , SPRAS
      , TELBX
      , TELF1
      , TELF2
      , TELFX
      , TELTX
      , TELX1
      , DATLT
      , DRNAM
      , KHINR
      , CCKEY
      , KOMPL
      , STAKZ
      , OBJNR
      , FUNKT
      , AFUNK
      , CPI_TEMPL
      , CPD_TEMPL
      , FUNC_AREA
      , SCI_TEMPL
      , SCD_TEMPL
      , SKI_TEMPL
      , SKD_TEMPL
      , ZVKBUR
      , VNAME
      , RECID
      , ETYPE
      , JV_OTYPE
      , JV_JIBCL
      , JV_JIBSA
      , FERC_IND
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_CSKS'
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
            , COALESCE(NULLIF(TRIM(CAST(COST_CENTER_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(VALID_DATE_TO_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                         COST_CENTER_MASTER_DATA_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(CONTROLLING_AREA_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                CONTROLLING_AREA_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(COST_CENTER_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                     COST_CENTER_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(VALID_DATE_TO_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                   VALID_DATE_TO_HK
        , LOAD_DTS
        , CONTROLLING_AREA_BK
        , COST_CENTER_BK
        , VALID_DATE_TO_BK
        , MANDT
        , KOKRS
        , KOSTL
        , DATBI
        , GLREQUEST
        , DATAB
        , BKZKP
        , PKZKP
        , BUKRS
        , GSBER
        , KOSAR
        , VERAK
        , VERAK_USER
        , WAERS
        , KALSM
        , TXJCD
        , PRCTR
        , WERKS
        , LOGSYSTEM
        , ERSDA
        , USNAM
        , BKZKS
        , BKZER
        , BKZOB
        , PKZKS
        , PKZER
        , VMETH
        , MGEFL
        , ABTEI
        , NKOST
        , KVEWE
        , KAPPL
        , KOSZSCHL
        , LAND1
        , ANRED
        , NAME1
        , NAME2
        , NAME3
        , NAME4
        , ORT01
        , ORT02
        , STRAS
        , PFACH
        , PSTLZ
        , PSTL2
        , REGIO
        , SPRAS
        , TELBX
        , TELF1
        , TELF2
        , TELFX
        , TELTX
        , TELX1
        , DATLT
        , DRNAM
        , KHINR
        , CCKEY
        , KOMPL
        , STAKZ
        , OBJNR
        , FUNKT
        , AFUNK
        , CPI_TEMPL
        , CPD_TEMPL
        , FUNC_AREA
        , SCI_TEMPL
        , SCD_TEMPL
        , SKI_TEMPL
        , SKD_TEMPL
        , ZVKBUR
        , VNAME
        , RECID
        , ETYPE
        , JV_OTYPE
        , JV_JIBCL
        , JV_JIBSA
        , FERC_IND
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , GLCHANGETIME_DTTM
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(KOSTL::text), '^^') 
            , '||', IFNULL(TRIM(DATBI::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(DATAB::text), '^^') 
            , '||', IFNULL(TRIM(BKZKP::text), '^^') 
            , '||', IFNULL(TRIM(PKZKP::text), '^^') 
            , '||', IFNULL(TRIM(BUKRS::text), '^^') 
            , '||', IFNULL(TRIM(GSBER::text), '^^') 
            , '||', IFNULL(TRIM(KOSAR::text), '^^') 
            , '||', IFNULL(TRIM(VERAK::text), '^^') 
            , '||', IFNULL(TRIM(VERAK_USER::text), '^^') 
            , '||', IFNULL(TRIM(WAERS::text), '^^') 
            , '||', IFNULL(TRIM(KALSM::text), '^^') 
            , '||', IFNULL(TRIM(TXJCD::text), '^^') 
            , '||', IFNULL(TRIM(PRCTR::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(LOGSYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(ERSDA::text), '^^') 
            , '||', IFNULL(TRIM(USNAM::text), '^^') 
            , '||', IFNULL(TRIM(BKZKS::text), '^^') 
            , '||', IFNULL(TRIM(BKZER::text), '^^') 
            , '||', IFNULL(TRIM(BKZOB::text), '^^') 
            , '||', IFNULL(TRIM(PKZKS::text), '^^') 
            , '||', IFNULL(TRIM(PKZER::text), '^^') 
            , '||', IFNULL(TRIM(VMETH::text), '^^') 
            , '||', IFNULL(TRIM(MGEFL::text), '^^') 
            , '||', IFNULL(TRIM(ABTEI::text), '^^') 
            , '||', IFNULL(TRIM(NKOST::text), '^^') 
            , '||', IFNULL(TRIM(KVEWE::text), '^^') 
            , '||', IFNULL(TRIM(KAPPL::text), '^^') 
            , '||', IFNULL(TRIM(KOSZSCHL::text), '^^') 
            , '||', IFNULL(TRIM(LAND1::text), '^^') 
            , '||', IFNULL(TRIM(ANRED::text), '^^') 
            , '||', IFNULL(TRIM(NAME1::text), '^^') 
            , '||', IFNULL(TRIM(NAME2::text), '^^') 
            , '||', IFNULL(TRIM(NAME3::text), '^^') 
            , '||', IFNULL(TRIM(NAME4::text), '^^') 
            , '||', IFNULL(TRIM(ORT01::text), '^^') 
            , '||', IFNULL(TRIM(ORT02::text), '^^') 
            , '||', IFNULL(TRIM(STRAS::text), '^^') 
            , '||', IFNULL(TRIM(PFACH::text), '^^') 
            , '||', IFNULL(TRIM(PSTLZ::text), '^^') 
            , '||', IFNULL(TRIM(PSTL2::text), '^^') 
            , '||', IFNULL(TRIM(REGIO::text), '^^') 
            , '||', IFNULL(TRIM(SPRAS::text), '^^') 
            , '||', IFNULL(TRIM(TELBX::text), '^^') 
            , '||', IFNULL(TRIM(TELF1::text), '^^') 
            , '||', IFNULL(TRIM(TELF2::text), '^^') 
            , '||', IFNULL(TRIM(TELFX::text), '^^') 
            , '||', IFNULL(TRIM(TELTX::text), '^^') 
            , '||', IFNULL(TRIM(TELX1::text), '^^') 
            , '||', IFNULL(TRIM(DATLT::text), '^^') 
            , '||', IFNULL(TRIM(DRNAM::text), '^^') 
            , '||', IFNULL(TRIM(KHINR::text), '^^') 
            , '||', IFNULL(TRIM(CCKEY::text), '^^') 
            , '||', IFNULL(TRIM(KOMPL::text), '^^') 
            , '||', IFNULL(TRIM(STAKZ::text), '^^') 
            , '||', IFNULL(TRIM(OBJNR::text), '^^') 
            , '||', IFNULL(TRIM(FUNKT::text), '^^') 
            , '||', IFNULL(TRIM(AFUNK::text), '^^') 
            , '||', IFNULL(TRIM(CPI_TEMPL::text), '^^') 
            , '||', IFNULL(TRIM(CPD_TEMPL::text), '^^') 
            , '||', IFNULL(TRIM(FUNC_AREA::text), '^^') 
            , '||', IFNULL(TRIM(SCI_TEMPL::text), '^^') 
            , '||', IFNULL(TRIM(SCD_TEMPL::text), '^^') 
            , '||', IFNULL(TRIM(SKI_TEMPL::text), '^^') 
            , '||', IFNULL(TRIM(SKD_TEMPL::text), '^^') 
            , '||', IFNULL(TRIM(ZVKBUR::text), '^^') 
            , '||', IFNULL(TRIM(VNAME::text), '^^') 
            , '||', IFNULL(TRIM(RECID::text), '^^') 
            , '||', IFNULL(TRIM(ETYPE::text), '^^') 
            , '||', IFNULL(TRIM(JV_OTYPE::text), '^^') 
            , '||', IFNULL(TRIM(JV_JIBCL::text), '^^') 
            , '||', IFNULL(TRIM(JV_JIBSA::text), '^^') 
            , '||', IFNULL(TRIM(FERC_IND::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^')  
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
