---- SRC LAYER ----
WITH
SRC_E              as ( SELECT ENTITY_HK, MANDT, RCOMP, GLREQUEST, NAME1, CNTRY, NAME2, LANGU, STRET, POBOX, PSTLC, CITY, CURR, MODCP, GLSIP, RESTA, RFORM, ZWEIG, MCOMP, MCLNT, LCCOMP, STRT2, INDPO, GLDELFLAG, GLCHANGETIME, GLSOURCESYSTEM, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND, LOAD_DTS, REC_SRC, BKCC, HASHDIFF 
                            FROM {{ ref('v_psa_stg_entity__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_E              as ( SELECT * FROM STAGING.v_psa_stg_entity__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_E as (
    SELECT
        ENTITY_HK
      , MANDT
      , RCOMP
      , GLREQUEST
      , NAME1
      , CNTRY
      , NAME2
      , LANGU
      , STRET
      , POBOX
      , PSTLC
      , CITY
      , CURR
      , MODCP
      , GLSIP
      , RESTA
      , RFORM
      , ZWEIG
      , MCOMP
      , MCLNT
      , LCCOMP
      , STRT2
      , INDPO
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_E
)
---- RENAME LAYER ----

, RENAME_E as (
    SELECT
        ENTITY_HK
      , MANDT
      , RCOMP
      , GLREQUEST
      , NAME1
      , CNTRY
      , NAME2
      , LANGU
      , STRET
      , POBOX
      , PSTLC
      , CITY
      , CURR
      , MODCP
      , GLSIP
      , RESTA
      , RFORM
      , ZWEIG
      , MCOMP
      , MCLNT
      , LCCOMP
      , STRT2
      , INDPO
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_E
)
---- FILTER LAYER ----

, FILTER_E as (
    SELECT *
    FROM RENAME_E
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_E
)

---- FINAL LAYER ----
SELECT
          ENTITY_HK
        , MANDT
        , RCOMP
        , GLREQUEST
        , NAME1
        , CNTRY
        , NAME2
        , LANGU
        , STRET
        , POBOX
        , PSTLC
        , CITY
        , CURR
        , MODCP
        , GLSIP
        , RESTA
        , RFORM
        , ZWEIG
        , MCOMP
        , MCLNT
        , LCCOMP
        , STRT2
        , INDPO
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ENTITY_HK= JOIN_RESULT.ENTITY_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by ENTITY_HK, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS ENTITY_HK
    , NULL AS MANDT
, NULL AS RCOMP
, NULL AS GLREQUEST
, NULL AS NAME1
, NULL AS CNTRY
, NULL AS NAME2
, NULL AS LANGU
, NULL AS STRET
, NULL AS POBOX
, NULL AS PSTLC
, NULL AS CITY
, NULL AS CURR
, NULL AS MODCP
, NULL AS GLSIP
, NULL AS RESTA
, NULL AS RFORM
, NULL AS ZWEIG
, NULL AS MCOMP
, NULL AS MCLNT
, NULL AS LCCOMP
, NULL AS STRT2
, NULL AS INDPO
, NULL AS GLDELFLAG
, NULL AS GLSOURCESYSTEM
, NULL AS GLCHANGETIME
, NULL AS PSA_LOAD_DTS
, NULL AS PSA_RECORD_SOURCE
, NULL AS PSA_DELETE_IND
, CONVERT_TIMEZONE('UTC','1900-01-01')  as  LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASH_DIFF FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}