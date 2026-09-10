---- SRC LAYER ----
WITH
SRC_SQA            as ( SELECT * FROM {{ ref('v_psa_stg_quality_activities') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SQA            as ( SELECT * FROM STAGING.v_psa_stg_quality_activities )
*/
---- LOGIC LAYER ----

, LOGIC_SQA as (
    SELECT
        QUALITY_ACTIVITY_HK
      , GLREQUEST
      , QMNUM
      , MANUM
      , FENUM
      , URNUM
      , MNKAT
      , MNGRP
      , MNCOD
      , MNVER
      , MATXT
      , ERNAM
      , ERDAT
      , AENAM
      , AEDAT
      , MAKLS
      , KLAKZ
      , PSTER
      , PETER
      , INDTX
      , KZMLA
      , MNGFA
      , PSTUR
      , PETUR
      , ERZEIT
      , AEZEIT
      , KZLOESCH
      , QMANUM
      , AUTKZ
      , KZACTIONBOX
      , FUNKTION
      , ZZAMOUNT1
      , ZZAMOUNT2
      , EBELN
      , EBELP
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , PSA_DELETE_IND
      , HASHDIFF
    FROM SRC_SQA
)
---- RENAME LAYER ----

, RENAME_SQA as (
    SELECT
        QUALITY_ACTIVITY_HK
      , GLREQUEST
      , QMNUM
      , MANUM
      , FENUM
      , URNUM
      , MNKAT
      , MNGRP
      , MNCOD
      , MNVER
      , MATXT
      , ERNAM
      , ERDAT
      , AENAM
      , AEDAT
      , MAKLS
      , KLAKZ
      , PSTER
      , PETER
      , INDTX
      , KZMLA
      , MNGFA
      , PSTUR
      , PETUR
      , ERZEIT
      , AEZEIT
      , KZLOESCH
      , QMANUM
      , AUTKZ
      , KZACTIONBOX
      , FUNKTION
      , ZZAMOUNT1
      , ZZAMOUNT2
      , EBELN
      , EBELP
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , PSA_DELETE_IND
      , HASHDIFF
    FROM LOGIC_SQA
)
---- FILTER LAYER ----

, FILTER_SQA as (
    SELECT *
    FROM RENAME_SQA
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SQA
)

---- FINAL LAYER ----
SELECT
          QUALITY_ACTIVITY_HK 
        , GLREQUEST
        , QMNUM
        , MANUM
        , FENUM
        , URNUM
        , MNKAT
        , MNGRP
        , MNCOD
        , MNVER
        , MATXT
        , ERNAM
        , ERDAT
        , AENAM
        , AEDAT
        , MAKLS
        , KLAKZ
        , PSTER
        , PETER
        , INDTX
        , KZMLA
        , MNGFA
        , PSTUR
        , PETUR
        , ERZEIT
        , AEZEIT
        , KZLOESCH
        , QMANUM
        , AUTKZ
        , KZACTIONBOX
        , FUNKTION
        , ZZAMOUNT1
        , ZZAMOUNT2
        , EBELN
        , EBELP
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , PSA_DELETE_IND
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.QUALITY_ACTIVITY_HK= JOIN_RESULT.QUALITY_ACTIVITY_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by QUALITY_ACTIVITY_HK, HASHDIFF order by LOAD_DTS)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS QUALITY_ACTIVITY_HK
, null:: NUMBER as GLREQUEST
, null:: VARCHAR as QMNUM
, null:: VARCHAR as MANUM
, null:: VARCHAR as FENUM
, null:: VARCHAR as URNUM
, null:: VARCHAR as MNKAT
, null:: VARCHAR as MNGRP
, null:: VARCHAR as MNCOD
, null:: VARCHAR as MNVER
, null:: VARCHAR as MATXT
, null:: VARCHAR as ERNAM
, null:: VARCHAR as ERDAT
, null:: VARCHAR as AENAM
, null:: VARCHAR as AEDAT
, null:: VARCHAR as MAKLS
, null:: VARCHAR as KLAKZ
, null:: VARCHAR as PSTER
, null:: VARCHAR as PETER
, null:: VARCHAR as INDTX
, null:: VARCHAR as KZMLA
, null:: VARCHAR as MNGFA
, null:: VARCHAR as PSTUR
, null:: VARCHAR as PETUR
, null:: VARCHAR as ERZEIT
, null:: VARCHAR as AEZEIT
, null:: VARCHAR as KZLOESCH
, null:: VARCHAR as QMANUM
, null:: VARCHAR as AUTKZ
, null:: VARCHAR as KZACTIONBOX
, null:: VARCHAR as FUNKTION
, null:: NUMBER as ZZAMOUNT1
, null:: NUMBER as ZZAMOUNT2
, null:: VARCHAR as EBELN
, null:: VARCHAR as EBELP
, null:: VARCHAR as GLDELFLAG
, null:: NUMBER AS GLCHANGETIME
, null:: VARCHAR AS GLSOURCESYSTEM 
, CONVERT_TIMEZONE('UTC','1900-01-01') AS LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
, NULL :: VARCHAR AS PSA_DELETE_IND
, ''::BINARY as HASHDIFF FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}