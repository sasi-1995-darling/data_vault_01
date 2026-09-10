---- SRC LAYER ----
WITH
SRC_OB             as ( SELECT * FROM {{ ref('v_psa_stg_object_list_detail__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', -1, MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_OB             as ( SELECT * FROM staging.v_psa_stg_object_list_detail__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_OB as (
    SELECT
        LNK_OBJECT_LIST_DETAIL_HK
      , LOAD_DTS
      , MANDT
      , OBKNR
      , OBZAE
      , GLREQUEST
      , GLSOURCESYSTEM
      , EQUNR
      , IHNUM
      , BAUTL
      , ILOAN
      , SORTF
      , BEARB
      , OBJVW
      , SERNR
      , MATNR
      , DATUM
      , EQSNR
      , TASER
      , UII
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_OB
)
---- RENAME LAYER ----

, RENAME_OB as (
    SELECT
        LNK_OBJECT_LIST_DETAIL_HK
      , LOAD_DTS
      , MANDT
      , OBKNR
      , OBZAE
      , GLREQUEST
      , GLSOURCESYSTEM
      , EQUNR
      , IHNUM
      , BAUTL
      , ILOAN
      , SORTF
      , BEARB
      , OBJVW
      , SERNR
      , MATNR
      , DATUM
      , EQSNR
      , TASER
      , UII
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_OB
)
---- FILTER LAYER ----

, FILTER_OB as (
    SELECT *
    FROM RENAME_OB
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_OB
)

---- FINAL LAYER ----
SELECT
          LNK_OBJECT_LIST_DETAIL_HK
        , LOAD_DTS
        , MANDT
        , OBKNR
        , OBZAE
        , GLREQUEST
        , GLSOURCESYSTEM
        , EQUNR
        , IHNUM
        , BAUTL
        , ILOAN
        , SORTF
        , BEARB
        , OBJVW
        , SERNR
        , MATNR
        , DATUM
        , EQSNR
        , TASER
        , UII
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
    WHERE existing.LNK_OBJECT_LIST_DETAIL_HK = JOIN_RESULT.LNK_OBJECT_LIST_DETAIL_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
qualify 1= row_number()over(partition by LNK_OBJECT_LIST_DETAIL_HK, HASHDIFF order by LOAD_DTS)
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS LNK_OBJECT_LIST_DETAIL_HK
,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
,null as MANDT
,null as OBKNR
,null as OBZAE
,null as GLREQUEST
,null as GLSOURCESYSTEM
,null as EQUNR
,null as IHNUM
,null as BAUTL
,null as ILOAN
,null as SORTF
,null as BEARB
,null as OBJVW
,null as SERNR
,null as MATNR
,null as DATUM
,null as EQSNR
,null as TASER
,null as UII
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