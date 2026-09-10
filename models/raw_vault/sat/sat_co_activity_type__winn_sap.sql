---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT * FROM {{ ref('v_psa_stg_co_activity_type__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.v_psa_stg_co_activity_type__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        CO_ACTIVITY_TYPE_HK
      , MANDT
      , KOKRS
      , LSTAR
      , DATBI
      , GLREQUEST
      , DATAB
      , LEINH
      , LATYP
      , LATYPI
      , ERSDA
      , USNAM
      , KSTTY
      , AUSEH
      , AUSFK
      , VKSTA
      , LARK1
      , LARK2
      , SPRKZ
      , HRKFT
      , FIXVO
      , TARKZ
      , YRATE
      , TARKZ_I
      , MANIST
      , MANPLAN
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SWINN
)
---- RENAME LAYER ----

, RENAME_SWINN as (
    SELECT
        CO_ACTIVITY_TYPE_HK
      , MANDT
      , KOKRS
      , LSTAR
      , DATBI
      , GLREQUEST
      , DATAB
      , LEINH
      , LATYP
      , LATYPI
      , ERSDA
      , USNAM
      , KSTTY
      , AUSEH
      , AUSFK
      , VKSTA
      , LARK1
      , LARK2
      , SPRKZ
      , HRKFT
      , FIXVO
      , TARKZ
      , YRATE
      , TARKZ_I
      , MANIST
      , MANPLAN
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_SWINN
)
---- FILTER LAYER ----

, FILTER_SWINN as (
    SELECT *
    FROM RENAME_SWINN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SWINN
)

---- FINAL LAYER ----
SELECT
          CO_ACTIVITY_TYPE_HK
        , MANDT
        , KOKRS
        , LSTAR
        , DATBI
        , GLREQUEST
        , DATAB
        , LEINH
        , LATYP
        , LATYPI
        , ERSDA
        , USNAM
        , KSTTY
        , AUSEH
        , AUSFK
        , VKSTA
        , LARK1
        , LARK2
        , SPRKZ
        , HRKFT
        , FIXVO
        , TARKZ
        , YRATE
        , TARKZ_I
        , MANIST
        , MANPLAN
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
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
    WHERE existing.CO_ACTIVITY_TYPE_HK= JOIN_RESULT.CO_ACTIVITY_TYPE_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by CO_ACTIVITY_TYPE_HK, HASHDIFF order by LOAD_DTS)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS CO_ACTIVITY_TYPE_HK
, NULL AS MANDT
, NULL AS KOKRS
, NULL AS LSTAR
, NULL AS DATBI
, NULL AS GLREQUEST
, NULL AS DATAB
, NULL AS LEINH
, NULL AS LATYP
, NULL AS LATYPI
, NULL AS ERSDA
, NULL AS USNAM
, NULL AS KSTTY
, NULL AS AUSEH
, NULL AS AUSFK
, NULL AS VKSTA
, NULL AS LARK1
, NULL AS LARK2
, NULL AS SPRKZ
, NULL AS HRKFT
, NULL AS FIXVO
, NULL AS TARKZ
, NULL AS YRATE
, NULL AS TARKZ_I
, NULL AS MANIST
, NULL AS MANPLAN
, NULL AS GLDELFLAG
, NULL AS GLCHANGETIME
, NULL AS GLSOURCESYSTEM
, NULL AS PSA_LOAD_DTS
, NULL AS PSA_RECORD_SOURCE
, NULL AS PSA_DELETE_IND
, CONVERT_TIMEZONE('UTC','1900-01-01')  as  LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASH_DIFF FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}