---- SRC LAYER ----
WITH
SRC_GLUSR          as ( SELECT * FROM {{ ref('v_psa_stg_gl_user__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_GLUSR          as ( SELECT * FROM STAGING.v_psa_stg_gl_user__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_GLUSR as (
    SELECT
        USER_NAME_HK
      , MANDT
      , BNAME
      , GLREQUEST
      , NAME1
      , NAME2
      , NAME3
      , NAME4
      , SALUT
      , ABTLG
      , KOSTL
      , BUINR
      , ROONR
      , STRAS
      , PFACH
      , PSTLZ
      , ORT01
      , REGIO
      , LAND1
      , SPRAS
      , TELPR
      , TELNR
      , TEL01
      , TEL02
      , TELX1
      , TELFX
      , TELTX
      , ORT02
      , PSTL2
      , TZONE
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
    FROM SRC_GLUSR
)
---- RENAME LAYER ----

, RENAME_GLUSR as (
    SELECT
        USER_NAME_HK
      , MANDT
      , BNAME
      , GLREQUEST
      , NAME1
      , NAME2
      , NAME3
      , NAME4
      , SALUT
      , ABTLG
      , KOSTL
      , BUINR
      , ROONR
      , STRAS
      , PFACH
      , PSTLZ
      , ORT01
      , REGIO
      , LAND1
      , SPRAS
      , TELPR
      , TELNR
      , TEL01
      , TEL02
      , TELX1
      , TELFX
      , TELTX
      , ORT02
      , PSTL2
      , TZONE
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
    FROM LOGIC_GLUSR
)
---- FILTER LAYER ----

, FILTER_GLUSR as (
    SELECT *
    FROM RENAME_GLUSR
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_GLUSR
)

---- FINAL LAYER ----
SELECT
          USER_NAME_HK
        , MANDT
        , BNAME
        , GLREQUEST
        , NAME1
        , NAME2
        , NAME3
        , NAME4
        , SALUT
        , ABTLG
        , KOSTL
        , BUINR
        , ROONR
        , STRAS
        , PFACH
        , PSTLZ
        , ORT01
        , REGIO
        , LAND1
        , SPRAS
        , TELPR
        , TELNR
        , TEL01
        , TEL02
        , TELX1
        , TELFX
        , TELTX
        , ORT02
        , PSTL2
        , TZONE
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
    WHERE existing.USER_NAME_HK = JOIN_RESULT.USER_NAME_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by USER_NAME_HK, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS USER_NAME_HK
    , NULL AS MANDT
, NULL AS BNAME
, NULL AS GLREQUEST
, NULL AS NAME1
, NULL AS NAME2
, NULL AS NAME3
, NULL AS NAME4
, NULL AS SALUT
, NULL AS ABTLG
, NULL AS KOSTL
, NULL AS BUINR
, NULL AS ROONR
, NULL AS STRAS
, NULL AS PFACH
, NULL AS PSTLZ
, NULL AS ORT01
, NULL AS REGIO
, NULL AS LAND1
, NULL AS SPRAS
, NULL AS TELPR
, NULL AS TELNR
, NULL AS TEL01
, NULL AS TEL02
, NULL AS TELX1
, NULL AS TELFX
, NULL AS TELTX
, NULL AS ORT02
, NULL AS PSTL2
, NULL AS TZONE
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