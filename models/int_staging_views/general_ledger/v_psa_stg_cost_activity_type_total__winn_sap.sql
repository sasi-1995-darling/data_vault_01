---- SRC LAYER ----
WITH
SRC_cosl           as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_cosl') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_cosl           as ( SELECT * FROM sap_ecc_prd.z_cosl )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_cosl as (
    SELECT
        MANDT
      , LEDNR 
      , OBJNR 
      , GJAHR 
      , WRTTP 
      , VERSN 
      , VRGNG 
      , PERBL 
      , to_char(coalesce(nullif(trim(LEDNR), ''), '-1'))                                as                                          LEDGER_BK
      , to_char(coalesce(nullif(trim(OBJNR), ''), '-1'))                                as                                   OBJECT_NUMBER_BK
      , to_char(coalesce(nullif(trim(GJAHR), ''), '-1'))                                as                                     FISCAL_YEAR_BK
      , to_char(coalesce(nullif(trim(WRTTP), ''), '-1'))                                as                                 COST_VALUE_TYPE_BK
      , to_char(coalesce(nullif(trim(VERSN), ''), '-1'))                                as                                    COST_VERSION_BK
      , to_char(coalesce(nullif(trim(VRGNG), ''), '-1'))                                as                           COST_TRANSACTION_TYPE_BK
      , to_char(coalesce(nullif(trim(PERBL), ''), '-1'))                                as                                    PERIOD_BLOCK_BK
      , GLREQUEST
      , MEINH
      , LST001
      , LST002
      , LST003
      , LST004
      , LST005
      , LST006
      , LST007
      , LST008
      , LST009
      , LST010
      , LST011
      , LST012
      , LST013
      , LST014
      , LST015
      , LST016
      , KAP001
      , KAP002
      , KAP003
      , KAP004
      , KAP005
      , KAP006
      , KAP007
      , KAP008
      , KAP009
      , KAP010
      , KAP011
      , KAP012
      , KAP013
      , KAP014
      , KAP015
      , KAP016
      , AUSEH
      , AUS001
      , AUS002
      , AUS003
      , AUS004
      , AUS005
      , AUS006
      , AUS007
      , AUS008
      , AUS009
      , AUS010
      , AUS011
      , AUS012
      , AUS013
      , AUS014
      , AUS015
      , AUS016
      , DIS001
      , DIS002
      , DIS003
      , DIS004
      , DIS005
      , DIS006
      , DIS007
      , DIS008
      , DIS009
      , DIS010
      , DIS011
      , DIS012
      , DIS013
      , DIS014
      , DIS015
      , DIS016
      , AEQ001
      , AEQ002
      , AEQ003
      , AEQ004
      , AEQ005
      , AEQ006
      , AEQ007
      , AEQ008
      , AEQ009
      , AEQ010
      , AEQ011
      , AEQ012
      , AEQ013
      , AEQ014
      , AEQ015
      , AEQ016
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
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
        ))                                                           as                                       LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_cosl
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_cosl as (
    SELECT
       MANDT
      , LEDNR 
      , OBJNR 
      , GJAHR 
      , WRTTP 
      , VERSN 
      , VRGNG 
      , PERBL 
      , LEDGER_BK
      , OBJECT_NUMBER_BK
      , FISCAL_YEAR_BK
      , COST_VALUE_TYPE_BK
      , COST_VERSION_BK
      , COST_TRANSACTION_TYPE_BK
      , PERIOD_BLOCK_BK
      , GLREQUEST
      , MEINH
      , LST001
      , LST002
      , LST003
      , LST004
      , LST005
      , LST006
      , LST007
      , LST008
      , LST009
      , LST010
      , LST011
      , LST012
      , LST013
      , LST014
      , LST015
      , LST016
      , KAP001
      , KAP002
      , KAP003
      , KAP004
      , KAP005
      , KAP006
      , KAP007
      , KAP008
      , KAP009
      , KAP010
      , KAP011
      , KAP012
      , KAP013
      , KAP014
      , KAP015
      , KAP016
      , AUSEH
      , AUS001
      , AUS002
      , AUS003
      , AUS004
      , AUS005
      , AUS006
      , AUS007
      , AUS008
      , AUS009
      , AUS010
      , AUS011
      , AUS012
      , AUS013
      , AUS014
      , AUS015
      , AUS016
      , DIS001
      , DIS002
      , DIS003
      , DIS004
      , DIS005
      , DIS006
      , DIS007
      , DIS008
      , DIS009
      , DIS010
      , DIS011
      , DIS012
      , DIS013
      , DIS014
      , DIS015
      , DIS016
      , AEQ001
      , AEQ002
      , AEQ003
      , AEQ004
      , AEQ005
      , AEQ006
      , AEQ007
      , AEQ008
      , AEQ009
      , AEQ010
      , AEQ011
      , AEQ012
      , AEQ013
      , AEQ014
      , AEQ015
      , AEQ016
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_cosl
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_cosl as (
    SELECT *
    FROM RENAME_cosl
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_COSL'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_cosl
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
         MANDT
        , LEDNR 
        , OBJNR 
        , GJAHR 
        , WRTTP 
        , VERSN 
        , VRGNG 
        , PERBL
        , LEDGER_BK
        , OBJECT_NUMBER_BK
        , FISCAL_YEAR_BK
        , COST_VALUE_TYPE_BK
        , COST_VERSION_BK
        , COST_TRANSACTION_TYPE_BK
        , PERIOD_BLOCK_BK
        , GLREQUEST
        , MEINH
        , LST001
        , LST002
        , LST003
        , LST004
        , LST005
        , LST006
        , LST007
        , LST008
        , LST009
        , LST010
        , LST011
        , LST012
        , LST013
        , LST014
        , LST015
        , LST016
        , KAP001
        , KAP002
        , KAP003
        , KAP004
        , KAP005
        , KAP006
        , KAP007
        , KAP008
        , KAP009
        , KAP010
        , KAP011
        , KAP012
        , KAP013
        , KAP014
        , KAP015
        , KAP016
        , AUSEH
        , AUS001
        , AUS002
        , AUS003
        , AUS004
        , AUS005
        , AUS006
        , AUS007
        , AUS008
        , AUS009
        , AUS010
        , AUS011
        , AUS012
        , AUS013
        , AUS014
        , AUS015
        , AUS016
        , DIS001
        , DIS002
        , DIS003
        , DIS004
        , DIS005
        , DIS006
        , DIS007
        , DIS008
        , DIS009
        , DIS010
        , DIS011
        , DIS012
        , DIS013
        , DIS014
        , DIS015
        , DIS016
        , AEQ001
        , AEQ002
        , AEQ003
        , AEQ004
        , AEQ005
        , AEQ006
        , AEQ007
        , AEQ008
        , AEQ009
        , AEQ010
        , AEQ011
        , AEQ012
        , AEQ013
        , AEQ014
        , AEQ015
        , AEQ016
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(LEDGER_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(OBJECT_NUMBER_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(FISCAL_YEAR_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(COST_VALUE_TYPE_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(COST_VERSION_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(COST_TRANSACTION_TYPE_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(PERIOD_BLOCK_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                            COST_ACTIVITY_TYPE_TOTALS_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LEDGER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEDGER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(OBJECT_NUMBER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as OBJECT_NUMBER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(FISCAL_YEAR_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PERIOD_BLOCK_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as FISCAL_PERIOD_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COST_VALUE_TYPE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as COST_VALUE_TYPE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COST_VERSION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as COST_VERSION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COST_TRANSACTION_TYPE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as COST_TRANSACTION_TYPE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PERIOD_BLOCK_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PERIOD_BLOCK_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(LEDNR::text), '^^') 
            , '||', IFNULL(TRIM(OBJNR::text), '^^') 
            , '||', IFNULL(TRIM(GJAHR::text), '^^') 
            , '||', IFNULL(TRIM(WRTTP::text), '^^') 
            , '||', IFNULL(TRIM(VERSN::text), '^^') 
            , '||', IFNULL(TRIM(VRGNG::text), '^^') 
            , '||', IFNULL(TRIM(PERBL::text), '^^') 
            , '||', IFNULL(TRIM(LEDGER_BK::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_NUMBER_BK::text), '^^') 
            , '||', IFNULL(TRIM(FISCAL_YEAR_BK::text), '^^') 
            , '||', IFNULL(TRIM(COST_VALUE_TYPE_BK::text), '^^') 
            , '||', IFNULL(TRIM(COST_VERSION_BK::text), '^^') 
            , '||', IFNULL(TRIM(COST_TRANSACTION_TYPE_BK::text), '^^') 
            , '||', IFNULL(TRIM(PERIOD_BLOCK_BK::text), '^^') 
            , '||', IFNULL(TRIM(MEINH::text), '^^') 
            , '||', IFNULL(TRIM(LST001::text), '^^') 
            , '||', IFNULL(TRIM(LST002::text), '^^') 
            , '||', IFNULL(TRIM(LST003::text), '^^') 
            , '||', IFNULL(TRIM(LST004::text), '^^') 
            , '||', IFNULL(TRIM(LST005::text), '^^') 
            , '||', IFNULL(TRIM(LST006::text), '^^') 
            , '||', IFNULL(TRIM(LST007::text), '^^') 
            , '||', IFNULL(TRIM(LST008::text), '^^') 
            , '||', IFNULL(TRIM(LST009::text), '^^') 
            , '||', IFNULL(TRIM(LST010::text), '^^') 
            , '||', IFNULL(TRIM(LST011::text), '^^') 
            , '||', IFNULL(TRIM(LST012::text), '^^') 
            , '||', IFNULL(TRIM(LST013::text), '^^') 
            , '||', IFNULL(TRIM(LST014::text), '^^') 
            , '||', IFNULL(TRIM(LST015::text), '^^') 
            , '||', IFNULL(TRIM(LST016::text), '^^') 
            , '||', IFNULL(TRIM(KAP001::text), '^^') 
            , '||', IFNULL(TRIM(KAP002::text), '^^') 
            , '||', IFNULL(TRIM(KAP003::text), '^^') 
            , '||', IFNULL(TRIM(KAP004::text), '^^') 
            , '||', IFNULL(TRIM(KAP005::text), '^^') 
            , '||', IFNULL(TRIM(KAP006::text), '^^') 
            , '||', IFNULL(TRIM(KAP007::text), '^^') 
            , '||', IFNULL(TRIM(KAP008::text), '^^') 
            , '||', IFNULL(TRIM(KAP009::text), '^^') 
            , '||', IFNULL(TRIM(KAP010::text), '^^') 
            , '||', IFNULL(TRIM(KAP011::text), '^^') 
            , '||', IFNULL(TRIM(KAP012::text), '^^') 
            , '||', IFNULL(TRIM(KAP013::text), '^^') 
            , '||', IFNULL(TRIM(KAP014::text), '^^') 
            , '||', IFNULL(TRIM(KAP015::text), '^^') 
            , '||', IFNULL(TRIM(KAP016::text), '^^') 
            , '||', IFNULL(TRIM(AUSEH::text), '^^') 
            , '||', IFNULL(TRIM(AUS001::text), '^^') 
            , '||', IFNULL(TRIM(AUS002::text), '^^') 
            , '||', IFNULL(TRIM(AUS003::text), '^^') 
            , '||', IFNULL(TRIM(AUS004::text), '^^') 
            , '||', IFNULL(TRIM(AUS005::text), '^^') 
            , '||', IFNULL(TRIM(AUS006::text), '^^') 
            , '||', IFNULL(TRIM(AUS007::text), '^^') 
            , '||', IFNULL(TRIM(AUS008::text), '^^') 
            , '||', IFNULL(TRIM(AUS009::text), '^^') 
            , '||', IFNULL(TRIM(AUS010::text), '^^') 
            , '||', IFNULL(TRIM(AUS011::text), '^^') 
            , '||', IFNULL(TRIM(AUS012::text), '^^') 
            , '||', IFNULL(TRIM(AUS013::text), '^^') 
            , '||', IFNULL(TRIM(AUS014::text), '^^') 
            , '||', IFNULL(TRIM(AUS015::text), '^^') 
            , '||', IFNULL(TRIM(AUS016::text), '^^') 
            , '||', IFNULL(TRIM(DIS001::text), '^^') 
            , '||', IFNULL(TRIM(DIS002::text), '^^') 
            , '||', IFNULL(TRIM(DIS003::text), '^^') 
            , '||', IFNULL(TRIM(DIS004::text), '^^') 
            , '||', IFNULL(TRIM(DIS005::text), '^^') 
            , '||', IFNULL(TRIM(DIS006::text), '^^') 
            , '||', IFNULL(TRIM(DIS007::text), '^^') 
            , '||', IFNULL(TRIM(DIS008::text), '^^') 
            , '||', IFNULL(TRIM(DIS009::text), '^^') 
            , '||', IFNULL(TRIM(DIS010::text), '^^') 
            , '||', IFNULL(TRIM(DIS011::text), '^^') 
            , '||', IFNULL(TRIM(DIS012::text), '^^') 
            , '||', IFNULL(TRIM(DIS013::text), '^^') 
            , '||', IFNULL(TRIM(DIS014::text), '^^') 
            , '||', IFNULL(TRIM(DIS015::text), '^^') 
            , '||', IFNULL(TRIM(DIS016::text), '^^') 
            , '||', IFNULL(TRIM(AEQ001::text), '^^') 
            , '||', IFNULL(TRIM(AEQ002::text), '^^') 
            , '||', IFNULL(TRIM(AEQ003::text), '^^') 
            , '||', IFNULL(TRIM(AEQ004::text), '^^') 
            , '||', IFNULL(TRIM(AEQ005::text), '^^') 
            , '||', IFNULL(TRIM(AEQ006::text), '^^') 
            , '||', IFNULL(TRIM(AEQ007::text), '^^') 
            , '||', IFNULL(TRIM(AEQ008::text), '^^') 
            , '||', IFNULL(TRIM(AEQ009::text), '^^') 
            , '||', IFNULL(TRIM(AEQ010::text), '^^') 
            , '||', IFNULL(TRIM(AEQ011::text), '^^') 
            , '||', IFNULL(TRIM(AEQ012::text), '^^') 
            , '||', IFNULL(TRIM(AEQ013::text), '^^') 
            , '||', IFNULL(TRIM(AEQ014::text), '^^') 
            , '||', IFNULL(TRIM(AEQ015::text), '^^') 
            , '||', IFNULL(TRIM(AEQ016::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
