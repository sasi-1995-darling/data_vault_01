---- SRC LAYER ----
WITH
SRC_SO             as ( SELECT * FROM {{ ref('v_psa_stg_serial_number_assignment__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', -1, MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SO             as ( SELECT * FROM staging.v_psa_stg_serial_number_assignment__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SO as (
    SELECT
        LNK_SERIAL_NUMBER_HU_ASSIGNMENT_HK
      , LOAD_DTS
      , MANDT
      , OBKNR
      , GLREQUEST
      , GLSOURCESYSTEM
      , VENUM
      , VEPOS
      , EXIDV
      , DATUM
      , UZEIT
      , ANZSN
      , VORGANG
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SO
)
---- RENAME LAYER ----

, RENAME_SO as (
    SELECT
        LNK_SERIAL_NUMBER_HU_ASSIGNMENT_HK
      , LOAD_DTS
      , MANDT
      , OBKNR
      , GLREQUEST
      , GLSOURCESYSTEM
      , VENUM
      , VEPOS
      , EXIDV
      , DATUM
      , UZEIT
      , ANZSN
      , VORGANG
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_SO
)
---- FILTER LAYER ----

, FILTER_SO as (
    SELECT *
    FROM RENAME_SO
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SO
)

---- FINAL LAYER ----
SELECT
          LNK_SERIAL_NUMBER_HU_ASSIGNMENT_HK
        , LOAD_DTS
        , MANDT
        , OBKNR
        , GLREQUEST
        , GLSOURCESYSTEM
        , VENUM
        , VEPOS
        , EXIDV
        , DATUM
        , UZEIT
        , ANZSN
        , VORGANG
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
    WHERE existing.LNK_SERIAL_NUMBER_HU_ASSIGNMENT_HK = JOIN_RESULT.LNK_SERIAL_NUMBER_HU_ASSIGNMENT_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
qualify 1= row_number()over(partition by LNK_SERIAL_NUMBER_HU_ASSIGNMENT_HK, HASHDIFF order by LOAD_DTS)
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS LNK_SERIAL_NUMBER_HU_ASSIGNMENT_HK
,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
,null as MANDT
,null as OBKNR
,null as GLREQUEST
,null as GLSOURCESYSTEM
,null as VENUM
,null as VEPOS
,null as EXIDV
,null as DATUM
,null as UZEIT
,null as ANZSN
,null as VORGANG
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