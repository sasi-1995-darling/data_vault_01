---- SRC LAYER ----
WITH
SRC_QMUR           as ( SELECT * FROM {{ ref('v_psa_stg_quality_causes') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_QMUR           as ( SELECT * FROM STAGING.V_PSA_STG_QUALITY_CAUSES )
*/
---- LOGIC LAYER ----

, LOGIC_QMUR as (
    SELECT
        QUALITY_CAUSES_HK
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
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , PSA_DELETE_IND 
      , HASHDIFF
    FROM SRC_QMUR
)
---- RENAME LAYER ----

, RENAME_QMUR as (
    SELECT
        QUALITY_CAUSES_HK
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
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , PSA_DELETE_IND
      , HASHDIFF
    FROM LOGIC_QMUR
)
---- FILTER LAYER ----

, FILTER_QMUR as (
    SELECT *
    FROM RENAME_QMUR
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_QMUR
)

---- FINAL LAYER ----
SELECT
          QUALITY_CAUSES_HK
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
    WHERE existing.QUALITY_CAUSES_HK = JOIN_RESULT.QUALITY_CAUSES_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}
qualify 1= row_number()over(partition by QUALITY_CAUSES_HK, HASHDIFF order by LOAD_DTS)
union all

SELECT MD5_BINARY(GR.VALUE)  QUALITY_CAUSES_HK
, null:: STRING as QMNUM
, null:: STRING as FENUM
, null:: STRING as URNUM
, null:: NUMBER as GLREQUEST
, null:: STRING as ERNAM
, null:: STRING as ERDAT
, null:: STRING as AENAM
, null:: STRING as AEDAT
, null:: STRING as URTXT
, null:: STRING as URKAT
, null:: STRING as URGRP
, null:: STRING as URCOD
, null:: STRING as URVER
, null:: STRING as INDTX
, null:: STRING as KZMLA
, null:: STRING as ERZEIT
, null:: STRING as AEZEIT
, null:: STRING as VUKAT
, null:: STRING as VUGRP
, null:: STRING as VUCOD
, null:: STRING as PARVW
, null:: STRING as PARNR
, null:: STRING as BAUTL
, null:: NUMBER as URMENGE
, null:: STRING as URMGEIN
, null:: STRING as KZLOESCH
, null:: STRING as QURNUM
, null:: STRING as AUTKZ
, null:: STRING as INVOLVPERC
, null:: STRING as ZZREVLV
, null:: STRING as ZZREASON_GRP
, null:: STRING as ZZREASON_COD
, null:: STRING as GLDELFLAG
, null:: NUMBER as GLCHANGETIME
, null:: STRING as GLSOURCESYSTEM
, CONVERT_TIMEZONE('UTC','1900-01-01')  as LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, null :: VARCHAR AS PSA_DELETE_IND
, ''::BINARY as HASHDIFF FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}