---- SRC LAYER ----
WITH
SRC_CAP            as ( SELECT CAPACITY_HK,KAPID, MANDT, VERSN, DATUB, GLREQUEST, ANZHL, ANZSH, ANZTG, FABTG, NGRAD, SPROG, WOTAG, KKOPF, FIRST, GLDELFLAG, GLSOURCESYSTEM, GLCHANGETIME, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND, LOAD_DTS, REC_SRC, HASHDIFF FROM {{ ref('v_psa_stg_capacity_availability_interval__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_uom            as ( SELECT * FROM STAGING.V_PSA_STG_UOM__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_cap as (
    SELECT
            CAPACITY_HK,
            KAPID,
            MANDT,
            VERSN,
            DATUB,
            GLREQUEST,
            ANZHL,
            ANZSH,
            ANZTG,
            FABTG,
            NGRAD,
            SPROG,
            WOTAG,
            KKOPF,
            FIRST,
            GLDELFLAG,
            GLSOURCESYSTEM,
            GLCHANGETIME,
            PSA_LOAD_DTS,
            PSA_RECORD_SOURCE,
            PSA_DELETE_IND,
            LOAD_DTS,
            REC_SRC,
            HASHDIFF
    FROM SRC_CAP
)

---- RENAME LAYER ----

, RENAME_cap as (
    SELECT
            CAPACITY_HK,
            KAPID,
            MANDT,
            VERSN,
            DATUB,
            GLREQUEST,
            ANZHL,
            ANZSH,
            ANZTG,
            FABTG,
            NGRAD,
            SPROG,
            WOTAG,
            KKOPF,
            FIRST,
            GLDELFLAG,
            GLSOURCESYSTEM,
            GLCHANGETIME,
            PSA_LOAD_DTS,
            PSA_RECORD_SOURCE,
            PSA_DELETE_IND,
            LOAD_DTS,
            REC_SRC,
            HASHDIFF
    FROM LOGIC_cap
)
---- FILTER LAYER ----

, FILTER_cap as (
    SELECT *
    FROM RENAME_cap
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_cap
)

---- FINAL LAYER ----
SELECT
            CAPACITY_HK,
            KAPID,
            MANDT,
            VERSN,
            DATUB,
            GLREQUEST,
            ANZHL,
            ANZSH,
            ANZTG,
            FABTG,
            NGRAD,
            SPROG,
            WOTAG,
            KKOPF,
            FIRST,
            GLDELFLAG,
            GLSOURCESYSTEM,
            GLCHANGETIME,
            PSA_LOAD_DTS,
            PSA_RECORD_SOURCE,
            PSA_DELETE_IND,
            LOAD_DTS,
            REC_SRC,
            HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.CAPACITY_HK = JOIN_RESULT.CAPACITY_HK
    AND   existing.VERSN = JOIN_RESULT.VERSN
    AND   existing.DATUB = JOIN_RESULT.DATUB  
    AND   existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by CAPACITY_HK, VERSN, DATUB, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS CAPACITY_HK,
GR.VALUE::text AS  KAPID,
NULL AS  MANDT,
GR.VALUE::text AS  VERSN,
GR.VALUE::text AS  DATUB,
NULL AS  GLREQUEST,
NULL AS  ANZHL,
NULL AS  ANZSH,
NULL AS  ANZTG,
NULL AS  FABTG,
NULL AS  NGRAD,
NULL AS  SPROG,
NULL AS  WOTAG,
NULL AS  KKOPF,
NULL AS  FIRST,
NULL AS  GLDELFLAG,
NULL AS  GLSOURCESYSTEM,
NULL AS  GLCHANGETIME,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}