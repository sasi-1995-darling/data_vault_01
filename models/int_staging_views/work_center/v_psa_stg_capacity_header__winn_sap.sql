---- SRC LAYER ----
WITH
SRC_a              as ( SELECT ANG_MAX, ANG_MIN, ANG_UNIT, AZMAX, AZNOR, BASNE, BASZL, BEGZT, BRGRU, BR_QUANT, BR_QUNIT, BR_TIME, BR_TUNIT, BUFFERTIME, BUFFERTIME_UNIT, CAMPAIGN_PPDS, CAMPAIGN_SNP, CAPACITY_A, CAPACITY_A_UNIT, DEFINE_BUCKETS, DIM_STORAGE, ENDZT, FINITY_LEVEL, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, IS_BOTTLENECK, KALID, KAPAR, KAPAVO, KAPEH, KAPID, KAPIE, KAPLPL, KAPTER, LC_DAYS_MINUS, LC_DAYS_PLUS, LOSS_FACTOR, MANDT, MAX_STORAGE, MDRMODEL, MEHR, MEINS, MIN_OVERLAP, MIN_OVERLAP_UNIT, MIN_STORAGE, MIX_PLAN_TYPE, MOSID, NAME, NGRAD, NUM_OF_PERIODS, OVERLAP_BUCKETS, PAUSE, PERIOD, PLANR, POOLK, PP_BUCKET_FACT, PP_BUCKET_SCHEMA, PP_DEF_BUCKETS, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REFAN, REFAZ, REFID, RESTYPE, RITT_FLG, SNPLC, SORT, START_ON_GRID, STORAGE_CAPABLE, STORAGE_TO_ZERO, STORAGE_UNIT, SUPPK, SYNC_START, TSTREAM_EXTERNAL, TYPE, UEBERLAST, UNDERLOAD, UTIL_BUCKET, VERSA, WERKS FROM {{ source('sap_ecc_prd', 'z_kako') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_kako )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        KAPID                                                        as                                        CAPACITY_BK
      , MANDT
      , KAPID
      , GLREQUEST
      , AZMAX
      , AZNOR
      , BASNE
      , BASZL
      , BEGZT
      , BRGRU
      , ENDZT
      , KALID
      , KAPAR
      , MEINS
      , MOSID
      , NAME
      , NGRAD
      , PAUSE
      , PLANR
      , POOLK
      , REFAN
      , REFAZ
      , REFID
      , SUPPK
      , VERSA
      , WERKS
      , KAPIE
      , KAPTER
      , KAPAVO
      , UEBERLAST
      , KAPLPL
      , KAPEH
      , MEHR
      , ANG_UNIT
      , ANG_MIN
      , ANG_MAX
      , TYPE
      , RESTYPE
      , CAPACITY_A
      , CAPACITY_A_UNIT
      , NUM_OF_PERIODS
      , PERIOD
      , BUFFERTIME
      , BUFFERTIME_UNIT
      , IS_BOTTLENECK
      , UNDERLOAD
      , OVERLAP_BUCKETS
      , START_ON_GRID
      , MIN_OVERLAP
      , MIN_OVERLAP_UNIT
      , LOSS_FACTOR
      , SORT
      , SYNC_START
      , DEFINE_BUCKETS
      , LC_DAYS_MINUS
      , LC_DAYS_PLUS
      , STORAGE_CAPABLE
      , MIN_STORAGE
      , MAX_STORAGE
      , STORAGE_UNIT
      , DIM_STORAGE
      , STORAGE_TO_ZERO
      , SNPLC
      , UTIL_BUCKET
      , CAMPAIGN_PPDS
      , CAMPAIGN_SNP
      , TSTREAM_EXTERNAL
      , FINITY_LEVEL
      , BR_QUANT
      , BR_QUNIT
      , BR_TIME
      , BR_TUNIT
      , RITT_FLG
      , MDRMODEL
      , PP_DEF_BUCKETS
      , PP_BUCKET_SCHEMA
      , PP_BUCKET_FACT
      , MIX_PLAN_TYPE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,
            CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
            ))
        )                                                            as                                          LOAD_DTS
    FROM SRC_a
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        CAPACITY_BK
      , MANDT
      , KAPID
      , GLREQUEST
      , AZMAX
      , AZNOR
      , BASNE
      , BASZL
      , BEGZT
      , BRGRU
      , ENDZT
      , KALID
      , KAPAR
      , MEINS
      , MOSID
      , NAME
      , NGRAD
      , PAUSE
      , PLANR
      , POOLK
      , REFAN
      , REFAZ
      , REFID
      , SUPPK
      , VERSA
      , WERKS
      , KAPIE
      , KAPTER
      , KAPAVO
      , UEBERLAST
      , KAPLPL
      , KAPEH
      , MEHR
      , ANG_UNIT
      , ANG_MIN
      , ANG_MAX
      , TYPE
      , RESTYPE
      , CAPACITY_A
      , CAPACITY_A_UNIT
      , NUM_OF_PERIODS
      , PERIOD
      , BUFFERTIME
      , BUFFERTIME_UNIT
      , IS_BOTTLENECK
      , UNDERLOAD
      , OVERLAP_BUCKETS
      , START_ON_GRID
      , MIN_OVERLAP
      , MIN_OVERLAP_UNIT
      , LOSS_FACTOR
      , SORT
      , SYNC_START
      , DEFINE_BUCKETS
      , LC_DAYS_MINUS
      , LC_DAYS_PLUS
      , STORAGE_CAPABLE
      , MIN_STORAGE
      , MAX_STORAGE
      , STORAGE_UNIT
      , DIM_STORAGE
      , STORAGE_TO_ZERO
      , SNPLC
      , UTIL_BUCKET
      , CAMPAIGN_PPDS
      , CAMPAIGN_SNP
      , TSTREAM_EXTERNAL
      , FINITY_LEVEL
      , BR_QUANT
      , BR_QUNIT
      , BR_TIME
      , BR_TUNIT
      , RITT_FLG
      , MDRMODEL
      , PP_DEF_BUCKETS
      , PP_BUCKET_SCHEMA
      , PP_BUCKET_FACT
      , MIX_PLAN_TYPE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_a
)

, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_KAKO'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          CAPACITY_BK
        , coalesce(nullif(trim(UPPER(WERKS)), ''), '-1')                                                          as PLANT_BK
        , coalesce(nullif(trim(UPPER(MEINS)), ''), '-1')                                                           as UOM_BK
        , MANDT
        , KAPID
        , GLREQUEST
        , AZMAX
        , AZNOR
        , BASNE
        , BASZL
        , BEGZT
        , BRGRU
        , ENDZT
        , KALID
        , KAPAR
        , MEINS
        , MOSID
        , NAME
        , NGRAD
        , PAUSE
        , PLANR
        , POOLK
        , REFAN
        , REFAZ
        , REFID
        , SUPPK
        , VERSA
        , WERKS
        , KAPIE
        , KAPTER
        , KAPAVO
        , UEBERLAST
        , KAPLPL
        , KAPEH
        , MEHR
        , ANG_UNIT
        , ANG_MIN
        , ANG_MAX
        , TYPE
        , RESTYPE
        , CAPACITY_A
        , CAPACITY_A_UNIT
        , NUM_OF_PERIODS
        , PERIOD
        , BUFFERTIME
        , BUFFERTIME_UNIT
        , IS_BOTTLENECK
        , UNDERLOAD
        , OVERLAP_BUCKETS
        , START_ON_GRID
        , MIN_OVERLAP
        , MIN_OVERLAP_UNIT
        , LOSS_FACTOR
        , SORT
        , SYNC_START
        , DEFINE_BUCKETS
        , LC_DAYS_MINUS
        , LC_DAYS_PLUS
        , STORAGE_CAPABLE
        , MIN_STORAGE
        , MAX_STORAGE
        , STORAGE_UNIT
        , DIM_STORAGE
        , STORAGE_TO_ZERO
        , SNPLC
        , UTIL_BUCKET
        , CAMPAIGN_PPDS
        , CAMPAIGN_SNP
        , TSTREAM_EXTERNAL
        , FINITY_LEVEL
        , BR_QUANT
        , BR_QUNIT
        , BR_TIME
        , BR_TUNIT
        , RITT_FLG
        , MDRMODEL
        , PP_DEF_BUCKETS
        , PP_BUCKET_SCHEMA
        , PP_BUCKET_FACT
        , MIX_PLAN_TYPE
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
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(UOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as UOM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(KAPID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CAPACITY_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(WERKS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(MEINS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(KAPID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_PLANT_CAPACITY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(AZMAX::text), '^^') 
            , '||', IFNULL(TRIM(AZNOR::text), '^^') 
            , '||', IFNULL(TRIM(BASNE::text), '^^') 
            , '||', IFNULL(TRIM(BASZL::text), '^^') 
            , '||', IFNULL(TRIM(BEGZT::text), '^^') 
            , '||', IFNULL(TRIM(BRGRU::text), '^^') 
            , '||', IFNULL(TRIM(ENDZT::text), '^^') 
            , '||', IFNULL(TRIM(KALID::text), '^^') 
            , '||', IFNULL(TRIM(KAPAR::text), '^^') 
            , '||', IFNULL(TRIM(MOSID::text), '^^') 
            , '||', IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(NGRAD::text), '^^') 
            , '||', IFNULL(TRIM(PAUSE::text), '^^') 
            , '||', IFNULL(TRIM(PLANR::text), '^^') 
            , '||', IFNULL(TRIM(POOLK::text), '^^') 
            , '||', IFNULL(TRIM(REFAN::text), '^^') 
            , '||', IFNULL(TRIM(REFAZ::text), '^^') 
            , '||', IFNULL(TRIM(REFID::text), '^^') 
            , '||', IFNULL(TRIM(SUPPK::text), '^^') 
            , '||', IFNULL(TRIM(VERSA::text), '^^') 
            , '||', IFNULL(TRIM(KAPIE::text), '^^') 
            , '||', IFNULL(TRIM(KAPTER::text), '^^') 
            , '||', IFNULL(TRIM(KAPAVO::text), '^^') 
            , '||', IFNULL(TRIM(UEBERLAST::text), '^^') 
            , '||', IFNULL(TRIM(KAPLPL::text), '^^') 
            , '||', IFNULL(TRIM(KAPEH::text), '^^') 
            , '||', IFNULL(TRIM(MEHR::text), '^^') 
            , '||', IFNULL(TRIM(ANG_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(ANG_MIN::text), '^^') 
            , '||', IFNULL(TRIM(ANG_MAX::text), '^^') 
            , '||', IFNULL(TRIM(TYPE::text), '^^') 
            , '||', IFNULL(TRIM(RESTYPE::text), '^^') 
            , '||', IFNULL(TRIM(CAPACITY_A::text), '^^') 
            , '||', IFNULL(TRIM(CAPACITY_A_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(NUM_OF_PERIODS::text), '^^') 
            , '||', IFNULL(TRIM(PERIOD::text), '^^') 
            , '||', IFNULL(TRIM(BUFFERTIME::text), '^^') 
            , '||', IFNULL(TRIM(BUFFERTIME_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(IS_BOTTLENECK::text), '^^') 
            , '||', IFNULL(TRIM(UNDERLOAD::text), '^^') 
            , '||', IFNULL(TRIM(OVERLAP_BUCKETS::text), '^^') 
            , '||', IFNULL(TRIM(START_ON_GRID::text), '^^') 
            , '||', IFNULL(TRIM(MIN_OVERLAP::text), '^^') 
            , '||', IFNULL(TRIM(MIN_OVERLAP_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(LOSS_FACTOR::text), '^^') 
            , '||', IFNULL(TRIM(SORT::text), '^^') 
            , '||', IFNULL(TRIM(SYNC_START::text), '^^') 
            , '||', IFNULL(TRIM(DEFINE_BUCKETS::text), '^^') 
            , '||', IFNULL(TRIM(LC_DAYS_MINUS::text), '^^') 
            , '||', IFNULL(TRIM(LC_DAYS_PLUS::text), '^^') 
            , '||', IFNULL(TRIM(STORAGE_CAPABLE::text), '^^') 
            , '||', IFNULL(TRIM(MIN_STORAGE::text), '^^') 
            , '||', IFNULL(TRIM(MAX_STORAGE::text), '^^') 
            , '||', IFNULL(TRIM(STORAGE_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(DIM_STORAGE::text), '^^') 
            , '||', IFNULL(TRIM(STORAGE_TO_ZERO::text), '^^') 
            , '||', IFNULL(TRIM(SNPLC::text), '^^') 
            , '||', IFNULL(TRIM(UTIL_BUCKET::text), '^^') 
            , '||', IFNULL(TRIM(CAMPAIGN_PPDS::text), '^^') 
            , '||', IFNULL(TRIM(CAMPAIGN_SNP::text), '^^') 
            , '||', IFNULL(TRIM(TSTREAM_EXTERNAL::text), '^^') 
            , '||', IFNULL(TRIM(FINITY_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(BR_QUANT::text), '^^') 
            , '||', IFNULL(TRIM(BR_QUNIT::text), '^^') 
            , '||', IFNULL(TRIM(BR_TIME::text), '^^') 
            , '||', IFNULL(TRIM(BR_TUNIT::text), '^^') 
            , '||', IFNULL(TRIM(RITT_FLG::text), '^^') 
            , '||', IFNULL(TRIM(MDRMODEL::text), '^^') 
            , '||', IFNULL(TRIM(PP_DEF_BUCKETS::text), '^^') 
            , '||', IFNULL(TRIM(PP_BUCKET_SCHEMA::text), '^^') 
            , '||', IFNULL(TRIM(PP_BUCKET_FACT::text), '^^') 
            , '||', IFNULL(TRIM(MIX_PLAN_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT