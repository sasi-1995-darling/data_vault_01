---- SRC LAYER ----
WITH
SRC_CAP            as ( SELECT MANDT, KAPID, GLREQUEST, AZMAX, AZNOR, BASNE, BASZL, BEGZT, BRGRU, ENDZT, KALID, KAPAR, MEINS, MOSID, NAME, NGRAD, PAUSE, PLANR, POOLK, REFAN, REFAZ, REFID, SUPPK, VERSA, WERKS, KAPIE, KAPTER, KAPAVO, UEBERLAST, KAPLPL, KAPEH, MEHR, ANG_UNIT, ANG_MIN, ANG_MAX, TYPE, RESTYPE, CAPACITY_A, CAPACITY_A_UNIT, NUM_OF_PERIODS, PERIOD, BUFFERTIME, BUFFERTIME_UNIT, IS_BOTTLENECK, UNDERLOAD, OVERLAP_BUCKETS, START_ON_GRID, MIN_OVERLAP, MIN_OVERLAP_UNIT, LOSS_FACTOR, SORT, SYNC_START, DEFINE_BUCKETS, LC_DAYS_MINUS, LC_DAYS_PLUS, STORAGE_CAPABLE, MIN_STORAGE, MAX_STORAGE, STORAGE_UNIT, DIM_STORAGE, STORAGE_TO_ZERO, SNPLC, UTIL_BUCKET, CAMPAIGN_PPDS, CAMPAIGN_SNP, TSTREAM_EXTERNAL, FINITY_LEVEL, BR_QUANT, BR_QUNIT, BR_TIME, BR_TUNIT, RITT_FLG, MDRMODEL, PP_DEF_BUCKETS, PP_BUCKET_SCHEMA, PP_BUCKET_FACT, MIX_PLAN_TYPE, GLDELFLAG, GLCHANGETIME, GLSOURCESYSTEM, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND, LOAD_DTS, REC_SRC, CAPACITY_HK, HASHDIFF FROM {{ ref('v_psa_stg_capacity_header__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_uom            as ( SELECT * FROM STAGING.V_PSA_STG_UOM__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_cap as (
    SELECT
          CAPACITY_HK
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
        , HASHDIFF
        , REC_SRC
    FROM SRC_CAP
)

---- RENAME LAYER ----

, RENAME_cap as (
    SELECT
        CAPACITY_HK
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
        , HASHDIFF
    FROM LOGIC_cap
)
---- FILTER LAYER ----

, FILTER_cap as (
    SELECT *
    FROM RENAME_cap
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_cap
)

---- FINAL LAYER ----
SELECT
          CAPACITY_HK
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
        , HASHDIFF
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.CAPACITY_HK = JOIN_RESULT.CAPACITY_HK  
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by CAPACITY_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS CAPACITY_HK
, NULL as MANDT
, GR.VALUE::text AS KAPID
, NULL as GLREQUEST
, NULL as AZMAX
, NULL as AZNOR
, NULL as BASNE
, NULL as BASZL
, NULL as BEGZT
, NULL as BRGRU
, NULL as ENDZT
, NULL as KALID
, NULL as KAPAR
, NULL as MEINS
, NULL as MOSID
, NULL as NAME
, NULL as NGRAD
, NULL as PAUSE
, NULL as PLANR
, NULL as POOLK
, NULL as REFAN
, NULL as REFAZ
, NULL as REFID
, NULL as SUPPK
, NULL as VERSA
, NULL as WERKS
, NULL as KAPIE
, NULL as KAPTER
, NULL as KAPAVO
, NULL as UEBERLAST
, NULL as KAPLPL
, NULL as KAPEH
, NULL as MEHR
, NULL as ANG_UNIT
, NULL as ANG_MIN
, NULL as ANG_MAX
, NULL as TYPE
, NULL as RESTYPE
, NULL as CAPACITY_A
, NULL as CAPACITY_A_UNIT
, NULL as NUM_OF_PERIODS
, NULL as PERIOD
, NULL as BUFFERTIME
, NULL as BUFFERTIME_UNIT
, NULL as IS_BOTTLENECK
, NULL as UNDERLOAD
, NULL as OVERLAP_BUCKETS
, NULL as START_ON_GRID
, NULL as MIN_OVERLAP
, NULL as MIN_OVERLAP_UNIT
, NULL as LOSS_FACTOR
, NULL as SORT
, NULL as SYNC_START
, NULL as DEFINE_BUCKETS
, NULL as LC_DAYS_MINUS
, NULL as LC_DAYS_PLUS
, NULL as STORAGE_CAPABLE
, NULL as MIN_STORAGE
, NULL as MAX_STORAGE
, NULL as STORAGE_UNIT
, NULL as DIM_STORAGE
, NULL as STORAGE_TO_ZERO
, NULL as SNPLC
, NULL as UTIL_BUCKET
, NULL as CAMPAIGN_PPDS
, NULL as CAMPAIGN_SNP
, NULL as TSTREAM_EXTERNAL
, NULL as FINITY_LEVEL
, NULL as BR_QUANT
, NULL as BR_QUNIT
, NULL as BR_TIME
, NULL as BR_TUNIT
, NULL as RITT_FLG
, NULL as MDRMODEL
, NULL as PP_DEF_BUCKETS
, NULL as PP_BUCKET_SCHEMA
, NULL as PP_BUCKET_FACT
, NULL as MIX_PLAN_TYPE
, NULL as GLDELFLAG
, NULL as GLCHANGETIME
, NULL as GLSOURCESYSTEM
,'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS
,NULL AS PSA_RECORD_SOURCE
,'N' AS PSA_DELETE_IND
,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS
,''::BINARY AS HASHDIFF
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}