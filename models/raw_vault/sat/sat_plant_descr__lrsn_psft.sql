---- SRC LAYER ----
WITH
SRC_SBPLLR         as ( SELECT * FROM {{ ref('v_psa_stg_plant_descr__lrsn_psft') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SBPLLR         as ( SELECT * FROM STAGING.v_psa_stg_plant_descr__LRSN_PSFT )
*/
---- LOGIC LAYER ----

, LOGIC_SBPLLR as (
    SELECT
        PLANT_HK
      , BUSINESS_UNIT
      , DESCR
      , DESCRSHORT
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SBPLLR
)
---- RENAME LAYER ----

, RENAME_SBPLLR as (
    SELECT
        PLANT_HK
      , BUSINESS_UNIT
      , DESCR
      , DESCRSHORT
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SBPLLR
)
---- FILTER LAYER ----

, FILTER_SBPLLR as (
    SELECT *
    FROM RENAME_SBPLLR
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SBPLLR
)

---- FINAL LAYER ----
SELECT
          PLANT_HK
        , BUSINESS_UNIT
        , DESCR
        , DESCRSHORT
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PLANT_HK = JOIN_RESULT.PLANT_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by PLANT_HK , HASHDIFF order by PSA_LOAD_DTS)
union all
SELECT        MD5_BINARY(GR.VALUE) AS PLANT_HK
, GR.VALUE as BUSINESS_UNIT
, null as DESCR
, null as DESCRSHORT
, null as _FIVETRAN_DELETED
, null as _FIVETRAN_ID
, null as _FIVETRAN_SYNCED
, null as PSA_DELETE_IND
, null as PSA_LOAD_DTS
, null as PSA_RECORD_SOURCE
    , CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP as LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASHDIFF
  FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}