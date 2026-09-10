---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ ref('v_psa_stg_equipment_location_assignment__winn_sap') }} as SRC 
{% if is_incremental() %}
      where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
    {% endif %} )

/*
SRC_SRC            as ( SELECT * FROM int_staging_views.v_psa_stg_equipment_location_assignment__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        LNK_EQUIPMENT_LOCATION_ASSIGNMENT_HK
      , ILOAN
      , MANDT
      , EQUNR
      , DATBI
      , EQLFN
      , GLREQUEST
      , EQUZN
      , ERDAT
      , ERNAM
      , AEDAT
      , AENAM
      , TIMBI
      , ESTAI
      , ESTAE
      , STNAM
      , LVORM
      , DATAB
      , IWERK
      , IWERKI
      , SUBMT
      , MAPAR
      , HEQUI
      , HEQNR
      , INGRP
      , INGRPI
      , PM_OBJTY
      , GEWRK
      , GEWRKI
      , TIDNR
      , TIDNRI
      , KUND1
      , KUND2
      , KUND3
      , LIZNR
      , RBNR
      , EZDAT
      , EZBER
      , EZNUM
      , RBNR_I
      , IBLNR
      , BLDAT
      , PVS_FOCUS
      , PPEGUID
      , TECHS
      , FUNCID
      , FRCFIT
      , FRCRMV
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SRC
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
)

---- FINAL LAYER ----
SELECT
          LNK_EQUIPMENT_LOCATION_ASSIGNMENT_HK
        , ILOAN
        , MANDT
        , EQUNR
        , DATBI
        , EQLFN
        , GLREQUEST
        , EQUZN
        , ERDAT
        , ERNAM
        , AEDAT
        , AENAM
        , TIMBI
        , ESTAI
        , ESTAE
        , STNAM
        , LVORM
        , DATAB
        , IWERK
        , IWERKI
        , SUBMT
        , MAPAR
        , HEQUI
        , HEQNR
        , INGRP
        , INGRPI
        , PM_OBJTY
        , GEWRK
        , GEWRKI
        , TIDNR
        , TIDNRI
        , KUND1
        , KUND2
        , KUND3
        , LIZNR
        , RBNR
        , EZDAT
        , EZBER
        , EZNUM
        , RBNR_I
        , IBLNR
        , BLDAT
        , PVS_FOCUS
        , PPEGUID
        , TECHS
        , FUNCID
        , FRCFIT
        , FRCRMV
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} existing
    WHERE existing.LNK_EQUIPMENT_LOCATION_ASSIGNMENT_HK = JOIN_RESULT.LNK_EQUIPMENT_LOCATION_ASSIGNMENT_HK
      AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by LNK_EQUIPMENT_LOCATION_ASSIGNMENT_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_EQUIPMENT_LOCATION_ASSIGNMENT_HK,
NULL AS ILOAN,
NULL AS MANDT,
NULL AS EQUNR,
NULL AS DATBI,
NULL AS EQLFN,
NULL AS GLREQUEST,
NULL AS EQUZN,
NULL AS ERDAT,
NULL AS ERNAM,
NULL AS AEDAT,
NULL AS AENAM,
NULL AS TIMBI,
NULL AS ESTAI,
NULL AS ESTAE,
NULL AS STNAM,
NULL AS LVORM,
NULL AS DATAB,
NULL AS IWERK,
NULL AS IWERKI,
NULL AS SUBMT,
NULL AS MAPAR,
NULL AS HEQUI,
NULL AS HEQNR,
NULL AS INGRP,
NULL AS INGRPI,
NULL AS PM_OBJTY,
NULL AS GEWRK,
NULL AS GEWRKI,
NULL AS TIDNR,
NULL AS TIDNRI,
NULL AS KUND1,
NULL AS KUND2,
NULL AS KUND3,
NULL AS LIZNR,
NULL AS RBNR,
NULL AS EZDAT,
NULL AS EZBER,
NULL AS EZNUM,
NULL AS RBNR_I,
NULL AS IBLNR,
NULL AS BLDAT,
NULL AS PVS_FOCUS,
NULL AS PPEGUID,
NULL AS TECHS,
NULL AS FUNCID,
NULL AS FRCFIT,
NULL AS FRCRMV,
NULL AS GLDELFLAG,
NULL AS GLSOURCESYSTEM,
NULL AS GLCHANGETIME,
'N' AS PSA_DELETE_IND,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'1900-01-01T00:00:00'::TIMESTAMP_NTZ AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
MD5_BINARY('') AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
