---- SRC LAYER ----
WITH
SRC_KEPH           as ( SELECT BWVAR, BZOBJ, DIPA, KADKY, KALKA, KALNR, KEART, KKZMA, KKZMM, KKZST, KST001, KST002, KST003, KST004, KST005, KST006, KST007, KST008, KST009, KST010, KST011, KST012, KST013, KST014, KST015, KST016, KST017, KST018, KST019, KST020, KST021, KST022, KST023, KST024, KST025, KST026, KST027, KST028, KST029, KST030, KST031, KST032, KST033, KST034, KST035, KST036, KST037, KST038, KST039, KST040, LOSFX, PATNR, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, TVERS FROM {{ source('sap_ecc_prd', 'z_keph') }} as SRC  ),
SRC_KEKO           as ( SELECT BDATJ, BWVAR, BZOBJ, KADKY, KALNR, KKZMA, KLVAR, MANDT, MATNR, POPER, PSA_DELETE_IND, PSA_LOAD_DTS, WERKS FROM {{ source('sap_ecc_prd', 'z_keko') }} as SRC  ),
SRC_BKCC           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_KEPH           as ( SELECT * FROM sap_ecc_prd.z_keph )
SRC_KEKO           as ( SELECT * FROM sap_ecc_prd.z_keko )
SRC_BKCC           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_KEPH as (
    SELECT
        BZOBJ                                                        as                                           KP_BZOBJ
      , KALNR                                                        as                                           KP_KALNR
      , KALKA
      , KADKY                                                        as                                           KP_KADKY
      , TVERS
      , BWVAR                                                        as                                           KP_BWVAR
      , KKZMA                                                        as                                           KP_KKZMA
      , PATNR
      , KEART
      , LOSFX
      , KKZST
      , KKZMM
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
      , DIPA
      , KST001
      , KST002
      , KST003
      , KST004
      , KST005
      , KST006
      , KST007
      , KST008
      , KST009
      , KST010
      , KST011
      , KST012
      , KST013
      , KST014
      , KST015
      , KST016
      , KST017
      , KST018
      , KST019
      , KST020
      , KST021
      , KST022
      , KST023
      , KST024
      , KST025
      , KST026
      , KST027
      , KST028
      , KST029
      , KST030
      , KST031
      , KST032
      , KST033
      , KST034
      , KST035
      , KST036
      , KST037
      , KST038
      , KST039
      , KST040
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
    FROM SRC_KEPH
)

, LOGIC_KEKO as (
    SELECT
        MANDT
      , BZOBJ
      , KALNR
      , KADKY
      , BWVAR
      , KKZMA
      , MATNR
      , WERKS
      , POPER
      , BDATJ
      , KLVAR
      , PSA_DELETE_IND                                               as                                  KE_PSA_DELETE_IND
      , PSA_LOAD_DTS                                                 as                                    KE_PSA_LOAD_DTS
    FROM SRC_KEKO
)

, LOGIC_BKCC as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_BKCC
)
---- RENAME LAYER ----

, RENAME_KEKO as (
    SELECT
        MANDT
      , BZOBJ
      , KALNR
      , KADKY
      , BWVAR
      , KKZMA
      , MATNR
      , WERKS
      , POPER
      , BDATJ
      , KLVAR
      , KE_PSA_DELETE_IND
      , KE_PSA_LOAD_DTS
    FROM LOGIC_KEKO
)

, RENAME_KEPH as (
    SELECT
        KP_BZOBJ
      , KP_KALNR
      , KALKA
      , KP_KADKY
      , TVERS
      , KP_BWVAR
      , KP_KKZMA
      , PATNR
      , KEART
      , LOSFX
      , KKZST
      , KKZMM
      , LOAD_DTS
      , DIPA
      , KST001
      , KST002
      , KST003
      , KST004
      , KST005
      , KST006
      , KST007
      , KST008
      , KST009
      , KST010
      , KST011
      , KST012
      , KST013
      , KST014
      , KST015
      , KST016
      , KST017
      , KST018
      , KST019
      , KST020
      , KST021
      , KST022
      , KST023
      , KST024
      , KST025
      , KST026
      , KST027
      , KST028
      , KST029
      , KST030
      , KST031
      , KST032
      , KST033
      , KST034
      , KST035
      , KST036
      , KST037
      , KST038
      , KST039
      , KST040
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
    FROM LOGIC_KEPH
)

, RENAME_BKCC as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_BKCC
)
---- FILTER LAYER ----

, FILTER_KEPH as (
    SELECT *
    FROM RENAME_KEPH
    WHERE PSA_DELETE_IND='N'

)

, FILTER_KEKO as (
    SELECT *
    FROM RENAME_KEKO
    WHERE KE_PSA_DELETE_IND='N'
QUALIFY ROW_NUMBER() OVER (PARTITION BY MATNR,BZOBJ,KALNR,BWVAR,KKZMA,KADKY ORDER BY KE_PSA_LOAD_DTS DESC)=1
)

, FILTER_BKCC as (
    SELECT *
    FROM RENAME_BKCC
    WHERE REC_SRC = 'USOHNO.SAP.ECCPRD.KEPH'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_KEPH
    INNER JOIN FILTER_KEKO
        ON BZOBJ = KP_BZOBJ AND KALNR=KP_KALNR AND KADKY=KP_KADKY AND BWVAR=KP_BWVAR AND KKZMA=KP_KKZMA
    INNER JOIN FILTER_BKCC
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          MANDT
        , BZOBJ
        , KALNR
        , KALKA
        , KADKY
        , TVERS
        , BWVAR
        , KKZMA
        , PATNR
        , KEART
        , LOSFX
        , KKZST
        , KKZMM
        , LOAD_DTS
        , MATNR
        , COALESCE(NULLIF(UPPER(TRIM(MATNR)),'-1'),'UNKNOWN')          as ITEM_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , WERKS
        , COALESCE(NULLIF(UPPER(TRIM(WERKS)),''),'-1')                 as PLANT_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , POPER
        , BDATJ
        , KLVAR
        , DIPA
        , KST001
        , KST002
        , KST003
        , KST004
        , KST005
        , KST006
        , KST007
        , KST008
        , KST009
        , KST010
        , KST011
        , KST012
        , KST013
        , KST014
        , KST015
        , KST016
        , KST017
        , KST018
        , KST019
        , KST020
        , KST021
        , KST022
        , KST023
        , KST024
        , KST025
        , KST026
        , KST027
        , KST028
        , KST029
        , KST030
        , KST031
        , KST032
        , KST033
        , KST034
        , KST035
        , KST036
        , KST037
        , KST038
        , KST039
        , KST040
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
		,  COALESCE(NULLIF(TRIM(CAST(WERKS as VARCHAR)),''), '^^')
		,  COALESCE(NULLIF(TRIM(CAST(POPER as VARCHAR)),''), '^^')
		,  COALESCE(NULLIF(TRIM(CAST(BDATJ as VARCHAR)),''), '^^')
		,  COALESCE(NULLIF(TRIM(CAST(KLVAR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_COST_ESTIMATE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(POPER::text), '^^') 
            , '||', IFNULL(TRIM(BDATJ::text), '^^') 
            , '||', IFNULL(TRIM(KLVAR::text), '^^') 
            , '||', IFNULL(TRIM(DIPA::text), '^^') 
            , '||', IFNULL(TRIM(KST001::text), '^^') 
            , '||', IFNULL(TRIM(KST002::text), '^^') 
            , '||', IFNULL(TRIM(KST003::text), '^^') 
            , '||', IFNULL(TRIM(KST004::text), '^^') 
            , '||', IFNULL(TRIM(KST005::text), '^^') 
            , '||', IFNULL(TRIM(KST006::text), '^^') 
            , '||', IFNULL(TRIM(KST007::text), '^^') 
            , '||', IFNULL(TRIM(KST008::text), '^^') 
            , '||', IFNULL(TRIM(KST009::text), '^^') 
            , '||', IFNULL(TRIM(KST010::text), '^^') 
            , '||', IFNULL(TRIM(KST011::text), '^^') 
            , '||', IFNULL(TRIM(KST012::text), '^^') 
            , '||', IFNULL(TRIM(KST013::text), '^^') 
            , '||', IFNULL(TRIM(KST014::text), '^^') 
            , '||', IFNULL(TRIM(KST015::text), '^^') 
            , '||', IFNULL(TRIM(KST016::text), '^^') 
            , '||', IFNULL(TRIM(KST017::text), '^^') 
            , '||', IFNULL(TRIM(KST018::text), '^^') 
            , '||', IFNULL(TRIM(KST019::text), '^^') 
            , '||', IFNULL(TRIM(KST020::text), '^^') 
            , '||', IFNULL(TRIM(KST021::text), '^^') 
            , '||', IFNULL(TRIM(KST022::text), '^^') 
            , '||', IFNULL(TRIM(KST023::text), '^^') 
            , '||', IFNULL(TRIM(KST024::text), '^^') 
            , '||', IFNULL(TRIM(KST025::text), '^^') 
            , '||', IFNULL(TRIM(KST026::text), '^^') 
            , '||', IFNULL(TRIM(KST027::text), '^^') 
            , '||', IFNULL(TRIM(KST028::text), '^^') 
            , '||', IFNULL(TRIM(KST029::text), '^^') 
            , '||', IFNULL(TRIM(KST030::text), '^^') 
            , '||', IFNULL(TRIM(KST031::text), '^^') 
            , '||', IFNULL(TRIM(KST032::text), '^^') 
            , '||', IFNULL(TRIM(KST033::text), '^^') 
            , '||', IFNULL(TRIM(KST034::text), '^^') 
            , '||', IFNULL(TRIM(KST035::text), '^^') 
            , '||', IFNULL(TRIM(KST036::text), '^^') 
            , '||', IFNULL(TRIM(KST037::text), '^^') 
            , '||', IFNULL(TRIM(KST038::text), '^^') 
            , '||', IFNULL(TRIM(KST039::text), '^^') 
            , '||', IFNULL(TRIM(KST040::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
