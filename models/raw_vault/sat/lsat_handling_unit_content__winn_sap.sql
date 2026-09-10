---- SRC LAYER ----
WITH
SRC_ZV             as ( SELECT * FROM {{ ref('v_psa_stg_handling_unit_content__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', -1, MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_ZV             as ( SELECT * FROM staging.v_psa_stg_handling_unit_content__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_ZV as (
    SELECT
        LNK_HANDLING_UNIT_CONTENT_HK
      , LOAD_DTS
      , MANDT
      , VENUM
      , VEPOS
      , GLREQUEST
      , GLSOURCESYSTEM
      , VELIN
      , VBELN
      , POSNR
      , VBTYP
      , UNVEL
      , VEMNG
      , VEMNG_FLO
      , VEMEH
      , ALTME
      , VEANZ
      , KZBEI
      , MATNR
      , CHARG
      , WERKS
      , LGORT
      , CUOBJ
      , BESTQ
      , SOBKZ
      , SONUM
      , QPLOS
      , ANZSN
      , SERAIL
      , PSTYV
      , POSNR_GEN
      , P_MATERIAL
      , WDATU
      , VFDAT
      , HU_LGORT
      , XCHAR
      , SPE_IDPLATE
      , SGT_SCAT
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_ZV
)
---- RENAME LAYER ----

, RENAME_ZV as (
    SELECT
        LNK_HANDLING_UNIT_CONTENT_HK
      , LOAD_DTS
      , MANDT
      , VENUM
      , VEPOS
      , GLREQUEST
      , GLSOURCESYSTEM
      , VELIN
      , VBELN
      , POSNR
      , VBTYP
      , UNVEL
      , VEMNG
      , VEMNG_FLO
      , VEMEH
      , ALTME
      , VEANZ
      , KZBEI
      , MATNR
      , CHARG
      , WERKS
      , LGORT
      , CUOBJ
      , BESTQ
      , SOBKZ
      , SONUM
      , QPLOS
      , ANZSN
      , SERAIL
      , PSTYV
      , POSNR_GEN
      , P_MATERIAL
      , WDATU
      , VFDAT
      , HU_LGORT
      , XCHAR
      , SPE_IDPLATE
      , SGT_SCAT
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_ZV
)
---- FILTER LAYER ----

, FILTER_ZV as (
    SELECT *
    FROM RENAME_ZV
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_ZV
)

---- FINAL LAYER ----
SELECT
          LNK_HANDLING_UNIT_CONTENT_HK
        , LOAD_DTS
        , MANDT
        , VENUM
        , VEPOS
        , GLREQUEST
        , GLSOURCESYSTEM
        , VELIN
        , VBELN
        , POSNR
        , VBTYP
        , UNVEL
        , VEMNG
        , VEMNG_FLO
        , VEMEH
        , ALTME
        , VEANZ
        , KZBEI
        , MATNR
        , CHARG
        , WERKS
        , LGORT
        , CUOBJ
        , BESTQ
        , SOBKZ
        , SONUM
        , QPLOS
        , ANZSN
        , SERAIL
        , PSTYV
        , POSNR_GEN
        , P_MATERIAL
        , WDATU
        , VFDAT
        , HU_LGORT
        , XCHAR
        , SPE_IDPLATE
        , SGT_SCAT
        , WRF_CHARSTC1
        , WRF_CHARSTC2
        , WRF_CHARSTC3
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_HANDLING_UNIT_CONTENT_HK = JOIN_RESULT.LNK_HANDLING_UNIT_CONTENT_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
qualify 1= row_number()over(partition by LNK_HANDLING_UNIT_CONTENT_HK, HASHDIFF order by LOAD_DTS)
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS LNK_HANDLING_UNIT_CONTENT_HK
,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
,null as MANDT
,null as VENUM
,null as VEPOS
,null as GLREQUEST
,null as GLSOURCESYSTEM
,null as VELIN
,null as VBELN
,null as POSNR
,null as VBTYP
,null as UNVEL
,null as VEMNG
,null as VEMNG_FLO
,null as VEMEH
,null as ALTME
,null as VEANZ
,null as KZBEI
,null as MATNR
,null as CHARG
,null as WERKS
,null as LGORT
,null as CUOBJ
,null as BESTQ
,null as SOBKZ
,null as SONUM
,null as QPLOS
,null as ANZSN
,null as SERAIL
,null as PSTYV
,null as POSNR_GEN
,null as P_MATERIAL
,null as WDATU
,null as VFDAT
,null as HU_LGORT
,null as XCHAR
,null as SPE_IDPLATE
,null as SGT_SCAT
,null as WRF_CHARSTC1
,null as WRF_CHARSTC2
,null as WRF_CHARSTC3
,null as GLDELFLAG
,null as GLCHANGETIME
,null as PSA_LOAD_DTS
,null as PSA_RECORD_SOURCE
,null as PSA_DELETE_IND
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}