---- SRC LAYER ----
WITH
SRC_plan           as ( SELECT * FROM {{ ref('v_psa_stg_item_special_procurement_plant__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )
/*
SRC_plan           as ( SELECT * FROM staging.v_psa_stg_item_special_procurement_plant__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_plan as (
    SELECT
        SLNK_LNK_SAME_AS_PLANT_TRANSFER_HK
      , MANDT
      , WERKS
      , SOBSL
      , GLREQUEST
      , BESKZ
      , SOBES
      , WRK02
      , CLCOR
      , DUMPS
      , REWFG
      , REWRK
      , DIRPR
      , UMLDB
      , ADDIN
      , MLSCR
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM SRC_plan
)
---- RENAME LAYER ----

, RENAME_plan as (
    SELECT
        SLNK_LNK_SAME_AS_PLANT_TRANSFER_HK
      , MANDT
      , WERKS
      , SOBSL
      , GLREQUEST
      , BESKZ
      , SOBES
      , WRK02
      , CLCOR
      , DUMPS
      , REWFG
      , REWRK
      , DIRPR
      , UMLDB
      , ADDIN
      , MLSCR
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM LOGIC_plan
)
---- FILTER LAYER ----

, FILTER_plan as (
    SELECT *
    FROM RENAME_plan
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_plan
)

---- FINAL LAYER ----
SELECT
          SLNK_LNK_SAME_AS_PLANT_TRANSFER_HK
        , MANDT
        , WERKS
        , SOBSL
        , GLREQUEST
        , BESKZ
        , SOBES
        , WRK02
        , CLCOR
        , DUMPS
        , REWFG
        , REWRK
        , DIRPR
        , UMLDB
        , ADDIN
        , MLSCR
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , HASHDIFF
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.SLNK_LNK_SAME_AS_PLANT_TRANSFER_HK = JOIN_RESULT.SLNK_LNK_SAME_AS_PLANT_TRANSFER_HK
    AND existing.SOBSL = JOIN_RESULT.SOBSL    
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by SLNK_LNK_SAME_AS_PLANT_TRANSFER_HK, SOBSL, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS SLNK_LNK_SAME_AS_PLANT_TRANSFER_HK,
NULL AS MANDT,
GR.VALUE::text AS WERKS,
GR.VALUE::text AS SOBSL,
NULL AS GLREQUEST,
NULL AS BESKZ,
NULL AS SOBES,
GR.VALUE::text AS WRK02,
NULL AS CLCOR,
NULL AS DUMPS,
NULL AS REWFG,
NULL AS REWRK,
NULL AS DIRPR,
NULL AS UMLDB,
NULL AS ADDIN,
NULL AS MLSCR,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLSOURCESYSTEM,
'N' AS PSA_DELETE_IND,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
''::BINARY AS HASHDIFF,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}