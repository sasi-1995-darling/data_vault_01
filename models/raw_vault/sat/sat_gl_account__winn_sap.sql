---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT * FROM {{ ref('v_psa_stg_gl_account__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                        {% endif %} )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.V_PSA_STG_GL_ACCOUNT__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        GL_ACCOUNT_HK
      , MANDT
      , KTOPL
      , SAKNR
      , GLREQUEST
      , XBILK
      , SAKAN
      , BILKT
      , ERDAT
      , ERNAM
      , GVTYP
      , KTOKS
      , MUSTR
      , VBUND
      , XLOEV
      , XSPEA
      , XSPEB
      , XSPEP
      , MCOD1
      , FUNC_AREA
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
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
        GL_ACCOUNT_HK
      , MANDT
      , KTOPL
      , SAKNR
      , GLREQUEST
      , XBILK
      , SAKAN
      , BILKT
      , ERDAT
      , ERNAM
      , GVTYP
      , KTOKS
      , MUSTR
      , VBUND
      , XLOEV
      , XSPEA
      , XSPEB
      , XSPEP
      , MCOD1
      , FUNC_AREA
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
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
          GL_ACCOUNT_HK
        , MANDT
        , KTOPL
        , SAKNR
        , GLREQUEST
        , XBILK
        , SAKAN
        , BILKT
        , ERDAT
        , ERNAM
        , GVTYP
        , KTOKS
        , MUSTR
        , VBUND
        , XLOEV
        , XSPEA
        , XSPEB
        , XSPEP
        , MCOD1
        , FUNC_AREA
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
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
WHERE existing.GL_ACCOUNT_HK= JOIN_RESULT.GL_ACCOUNT_HK
AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by GL_ACCOUNT_HK, HASHDIFF order by LOAD_DTS)
union all
SELECT 
MD5_BINARY(GR.VALUE) AS GL_ACCOUNT_HK
, NULL AS MANDT
, NULL AS KTOPL
, NULL AS SAKNR
, NULL AS GLREQUEST
, NULL AS XBILK
, NULL AS SAKAN
, NULL AS BILKT
, NULL AS ERDAT
, NULL AS ERNAM
, NULL AS GVTYP
, NULL AS KTOKS
, NULL AS MUSTR
, NULL AS VBUND
, NULL AS XLOEV
, NULL AS XSPEA
, NULL AS XSPEB
, NULL AS XSPEP
, NULL AS MCOD1
, NULL AS FUNC_AREA
, NULL AS GLDELFLAG
, NULL AS GLCHANGETIME
, NULL AS GLSOURCESYSTEM
, NULL AS PSA_DELETE_IND
, CONVERT_TIMEZONE('UTC','1900-01-01') as LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
, ''::BINARY as HASHDIFF FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}