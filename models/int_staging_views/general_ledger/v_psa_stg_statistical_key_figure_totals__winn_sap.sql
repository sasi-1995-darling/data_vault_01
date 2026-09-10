---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_cosr') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_cosr )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        to_char(coalesce(MANDT,'-1'))                                as                                          CLIENT_BK
      , to_char(coalesce(LEDNR,'-1'))                                as                  LEDGER_FOR_CONTROLLING_OBJECTS_BK
      , to_char(coalesce(OBJNR,'-1'))                                as                                   OBJECT_NUMBER_BK
      , to_char(coalesce(GJAHR,'-1'))                                as                                     FISCAL_YEAR_BK
      , to_char(coalesce(WRTTP,'-1'))                                as                                 COST_VALUE_TYPE_BK
      , to_char(coalesce(VERSN,'-1'))                                as                                    COST_VERSION_BK
      , to_char(coalesce(STAGR,'-1'))                                as                                 TRACKING_FACTOR_BK
      , to_char(coalesce(HRKFT,'-1'))                                as                                CO_KEY_SUBNUMBER_BK
      , to_char(coalesce(VRGNG,'-1'))                                as                           COST_TRANSACTION_TYPE_BK
      , to_char(coalesce(PERBL,'-1'))                                as                                    PERIOD_BLOCK_BK
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
      , MANDT
      , LEDNR
      , OBJNR
      , GJAHR
      , WRTTP
      , VERSN
      , STAGR
      , HRKFT
      , VRGNG
      , PERBL
      , GLREQUEST
      , MEINH
      , SME001
      , SME002
      , SME003
      , SME004
      , SME005
      , SME006
      , SME007
      , SME008
      , SME009
      , SME010
      , SME011
      , SME012
      , SME013
      , SME014
      , SME015
      , SME016
      , SMA001
      , SMA002
      , SMA003
      , SMA004
      , SMA005
      , SMA006
      , SMA007
      , SMA008
      , SMA009
      , SMA010
      , SMA011
      , SMA012
      , SMA013
      , SMA014
      , SMA015
      , SMA016
      , FKBER
      , SEGMENT
      , GEBER
      , GRANT_NBR
      , BUDGET_PD
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
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
        CLIENT_BK
      , LEDGER_FOR_CONTROLLING_OBJECTS_BK
      , OBJECT_NUMBER_BK
      , FISCAL_YEAR_BK
      , COST_VALUE_TYPE_BK
      , COST_VERSION_BK
      , TRACKING_FACTOR_BK
      , CO_KEY_SUBNUMBER_BK
      , COST_TRANSACTION_TYPE_BK
      , PERIOD_BLOCK_BK
      , LOAD_DTS
      , MANDT
      , LEDNR
      , OBJNR
      , GJAHR
      , WRTTP
      , VERSN
      , STAGR
      , HRKFT
      , VRGNG
      , PERBL
      , GLREQUEST
      , MEINH
      , SME001
      , SME002
      , SME003
      , SME004
      , SME005
      , SME006
      , SME007
      , SME008
      , SME009
      , SME010
      , SME011
      , SME012
      , SME013
      , SME014
      , SME015
      , SME016
      , SMA001
      , SMA002
      , SMA003
      , SMA004
      , SMA005
      , SMA006
      , SMA007
      , SMA008
      , SMA009
      , SMA010
      , SMA011
      , SMA012
      , SMA013
      , SMA014
      , SMA015
      , SMA016
      , FKBER
      , SEGMENT
      , GEBER
      , GRANT_NBR
      , BUDGET_PD
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_COSR'
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
          CLIENT_BK
        , LEDGER_FOR_CONTROLLING_OBJECTS_BK
        , OBJECT_NUMBER_BK
        , FISCAL_YEAR_BK
        , COST_VALUE_TYPE_BK
        , COST_VERSION_BK
        , TRACKING_FACTOR_BK
        , CO_KEY_SUBNUMBER_BK
        , COST_TRANSACTION_TYPE_BK
        , PERIOD_BLOCK_BK
        , LOAD_DTS
        , MANDT
        , LEDNR
        , OBJNR
        , GJAHR
        , WRTTP
        , VERSN
        , STAGR
        , HRKFT
        , VRGNG
        , PERBL
        , GLREQUEST
        , MEINH
        , SME001
        , SME002
        , SME003
        , SME004
        , SME005
        , SME006
        , SME007
        , SME008
        , SME009
        , SME010
        , SME011
        , SME012
        , SME013
        , SME014
        , SME015
        , SME016
        , SMA001
        , SMA002
        , SMA003
        , SMA004
        , SMA005
        , SMA006
        , SMA007
        , SMA008
        , SMA009
        , SMA010
        , SMA011
        , SMA012
        , SMA013
        , SMA014
        , SMA015
        , SMA016
        , FKBER
        , SEGMENT
        , GEBER
        , GRANT_NBR
        , BUDGET_PD
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(CLIENT_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(LEDGER_FOR_CONTROLLING_OBJECTS_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(OBJECT_NUMBER_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(FISCAL_YEAR_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(COST_VALUE_TYPE_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(COST_VERSION_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(TRACKING_FACTOR_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(CO_KEY_SUBNUMBER_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(COST_TRANSACTION_TYPE_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(PERIOD_BLOCK_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                   STATISTICAL_KEY_FIGURE_TOTALS_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(OBJECT_NUMBER_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                     OBJECT_NUMBER_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(FISCAL_YEAR_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(PERIOD_BLOCK_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                   FISCAL_PERIOD_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(COST_VALUE_TYPE_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                 COST_VALUE_TYPE_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(LEDGER_FOR_CONTROLLING_OBJECTS_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                          LEDGER_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(COST_VERSION_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                    COST_VERSION_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(TRACKING_FACTOR_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                 TRACKING_FACTOR_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(COST_TRANSACTION_TYPE_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                  COST_TRANSACTION_TYPE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(LEDNR::text), '^^') 
            , '||', IFNULL(TRIM(OBJNR::text), '^^') 
            , '||', IFNULL(TRIM(GJAHR::text), '^^') 
            , '||', IFNULL(TRIM(WRTTP::text), '^^') 
            , '||', IFNULL(TRIM(VERSN::text), '^^') 
            , '||', IFNULL(TRIM(STAGR::text), '^^') 
            , '||', IFNULL(TRIM(HRKFT::text), '^^') 
            , '||', IFNULL(TRIM(VRGNG::text), '^^') 
            , '||', IFNULL(TRIM(PERBL::text), '^^') 
            , '||', IFNULL(TRIM(MEINH::text), '^^') 
            , '||', IFNULL(TRIM(SME001::text), '^^') 
            , '||', IFNULL(TRIM(SME002::text), '^^') 
            , '||', IFNULL(TRIM(SME003::text), '^^') 
            , '||', IFNULL(TRIM(SME004::text), '^^') 
            , '||', IFNULL(TRIM(SME005::text), '^^') 
            , '||', IFNULL(TRIM(SME006::text), '^^') 
            , '||', IFNULL(TRIM(SME007::text), '^^') 
            , '||', IFNULL(TRIM(SME008::text), '^^') 
            , '||', IFNULL(TRIM(SME009::text), '^^') 
            , '||', IFNULL(TRIM(SME010::text), '^^') 
            , '||', IFNULL(TRIM(SME011::text), '^^') 
            , '||', IFNULL(TRIM(SME012::text), '^^') 
            , '||', IFNULL(TRIM(SME013::text), '^^') 
            , '||', IFNULL(TRIM(SME014::text), '^^') 
            , '||', IFNULL(TRIM(SME015::text), '^^') 
            , '||', IFNULL(TRIM(SME016::text), '^^') 
            , '||', IFNULL(TRIM(SMA001::text), '^^') 
            , '||', IFNULL(TRIM(SMA002::text), '^^') 
            , '||', IFNULL(TRIM(SMA003::text), '^^') 
            , '||', IFNULL(TRIM(SMA004::text), '^^') 
            , '||', IFNULL(TRIM(SMA005::text), '^^') 
            , '||', IFNULL(TRIM(SMA006::text), '^^') 
            , '||', IFNULL(TRIM(SMA007::text), '^^') 
            , '||', IFNULL(TRIM(SMA008::text), '^^') 
            , '||', IFNULL(TRIM(SMA009::text), '^^') 
            , '||', IFNULL(TRIM(SMA010::text), '^^') 
            , '||', IFNULL(TRIM(SMA011::text), '^^') 
            , '||', IFNULL(TRIM(SMA012::text), '^^') 
            , '||', IFNULL(TRIM(SMA013::text), '^^') 
            , '||', IFNULL(TRIM(SMA014::text), '^^') 
            , '||', IFNULL(TRIM(SMA015::text), '^^') 
            , '||', IFNULL(TRIM(SMA016::text), '^^') 
            , '||', IFNULL(TRIM(FKBER::text), '^^') 
            , '||', IFNULL(TRIM(SEGMENT::text), '^^') 
            , '||', IFNULL(TRIM(GEBER::text), '^^') 
            , '||', IFNULL(TRIM(GRANT_NBR::text), '^^') 
            , '||', IFNULL(TRIM(BUDGET_PD::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
