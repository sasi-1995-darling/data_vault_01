---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT * FROM {{ ref('v_psa_stg_gl_company_code__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                        {% endif %} )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.V_PSA_STG_GL_COMPANY_CODE__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        GL_ACCOUNT_DETAILS_HK
      , MANDT
      , BUKRS
      , SAKNR
      , GLREQUEST
      , BEGRU
      , BUSAB
      , DATLZ
      , ERDAT
      , ERNAM
      , FDGRV
      , FDLEV
      , FIPLS
      , FSTAG
      , HBKID
      , HKTID
      , KDFSL
      , MITKZ
      , MWSKZ
      , STEXT
      , VZSKZ
      , WAERS
      , WMETH
      , XGKON
      , XINTB
      , XKRES
      , XLOEB
      , XNKON
      , XOPVW
      , XSPEB
      , ZINDT
      , ZINRT
      , ZUAWA
      , ALTKT
      , XMITK
      , RECID
      , FIPOS
      , XMWNO
      , XSALH
      , BEWGP
      , INFKY
      , TOGRU
      , XLGCLR
      , MCAKEY
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
        GL_ACCOUNT_DETAILS_HK
      , MANDT
      , BUKRS
      , SAKNR
      , GLREQUEST
      , BEGRU
      , BUSAB
      , DATLZ
      , ERDAT
      , ERNAM
      , FDGRV
      , FDLEV
      , FIPLS
      , FSTAG
      , HBKID
      , HKTID
      , KDFSL
      , MITKZ
      , MWSKZ
      , STEXT
      , VZSKZ
      , WAERS
      , WMETH
      , XGKON
      , XINTB
      , XKRES
      , XLOEB
      , XNKON
      , XOPVW
      , XSPEB
      , ZINDT
      , ZINRT
      , ZUAWA
      , ALTKT
      , XMITK
      , RECID
      , FIPOS
      , XMWNO
      , XSALH
      , BEWGP
      , INFKY
      , TOGRU
      , XLGCLR
      , MCAKEY
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
          GL_ACCOUNT_DETAILS_HK
        , MANDT
        , BUKRS
        , SAKNR
        , GLREQUEST
        , BEGRU
        , BUSAB
        , DATLZ
        , ERDAT
        , ERNAM
        , FDGRV
        , FDLEV
        , FIPLS
        , FSTAG
        , HBKID
        , HKTID
        , KDFSL
        , MITKZ
        , MWSKZ
        , STEXT
        , VZSKZ
        , WAERS
        , WMETH
        , XGKON
        , XINTB
        , XKRES
        , XLOEB
        , XNKON
        , XOPVW
        , XSPEB
        , ZINDT
        , ZINRT
        , ZUAWA
        , ALTKT
        , XMITK
        , RECID
        , FIPOS
        , XMWNO
        , XSALH
        , BEWGP
        , INFKY
        , TOGRU
        , XLGCLR
        , MCAKEY
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
WHERE existing.GL_ACCOUNT_DETAILS_HK= JOIN_RESULT.GL_ACCOUNT_DETAILS_HK
AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by GL_ACCOUNT_DETAILS_HK, HASHDIFF order by LOAD_DTS)
union all
SELECT 
MD5_BINARY(GR.VALUE) AS GL_ACCOUNT_DETAILS_HK
, NULL AS MANDT
, NULL AS BUKRS
, NULL AS SAKNR
, NULL AS GLREQUEST
, NULL AS BEGRU
, NULL AS BUSAB
, NULL AS DATLZ
, NULL AS ERDAT
, NULL AS ERNAM
, NULL AS FDGRV
, NULL AS FDLEV
, NULL AS FIPLS
, NULL AS FSTAG
, NULL AS HBKID
, NULL AS HKTID
, NULL AS KDFSL
, NULL AS MITKZ
, NULL AS MWSKZ
, NULL AS STEXT
, NULL AS VZSKZ
, NULL AS WAERS
, NULL AS WMETH
, NULL AS XGKON
, NULL AS XINTB
, NULL AS XKRES
, NULL AS XLOEB
, NULL AS XNKON
, NULL AS XOPVW
, NULL AS XSPEB
, NULL AS ZINDT
, NULL AS ZINRT
, NULL AS ZUAWA
, NULL AS ALTKT
, NULL AS XMITK
, NULL AS RECID
, NULL AS FIPOS
, NULL AS XMWNO
, NULL AS XSALH
, NULL AS BEWGP
, NULL AS INFKY
, NULL AS TOGRU
, NULL AS XLGCLR
, NULL AS MCAKEY
, NULL AS GLDELFLAG
, NULL AS GLCHANGETIME
, NULL AS GLSOURCESYSTEM
, NULL AS PSA_DELETE_IND
, CONVERT_TIMEZONE('UTC','1900-01-01') as LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
, ''::BINARY as HASH_DIFF FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}