---- SRC LAYER ----
WITH
SRC_SML            as ( SELECT * FROM {{ ref('v_psa_stg_supplier_mdm_xref') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SML            as ( SELECT * FROM STAGING.v_psa_stg_supplier_mdm_xref )
*/
---- LOGIC LAYER ----

, LOGIC_SML as (
    SELECT
        SLNK_SUPPLIER_HK
      , SUPPLIER_HK
      , SAME_AS_SUPPLIER_HK
      , BUSINESS_ID
      , ORIGINAL_BUSINESS_ID
      , SUPPLIER_BK
      , SOURCE_PKEY
      , SOURCE_SYSTEM
      , LAST_RUN_DATE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , BKCC
      , REC_SRC
      , MDM_BKCC
      , HASHDIFF
    FROM SRC_SML
)
---- RENAME LAYER ----

, RENAME_SML as (
    SELECT
        SLNK_SUPPLIER_HK
      , SUPPLIER_HK
      , SAME_AS_SUPPLIER_HK
      , BUSINESS_ID
      , ORIGINAL_BUSINESS_ID
      , SUPPLIER_BK
      , SOURCE_PKEY
      , SOURCE_SYSTEM
      , LAST_RUN_DATE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , BKCC
      , REC_SRC
      , MDM_BKCC
      , HASHDIFF
    FROM LOGIC_SML
)
---- FILTER LAYER ----

, FILTER_SML as (
    SELECT *
    FROM RENAME_SML
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SML
)

---- FINAL LAYER ----
SELECT
          SLNK_SUPPLIER_HK
        , SUPPLIER_HK
        , SAME_AS_SUPPLIER_HK
        , BUSINESS_ID
        , ORIGINAL_BUSINESS_ID
        , SUPPLIER_BK
        , SOURCE_PKEY
        , SOURCE_SYSTEM
        , LAST_RUN_DATE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , BKCC
        , REC_SRC
        , MDM_BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.SLNK_SUPPLIER_HK = JOIN_RESULT.SLNK_SUPPLIER_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 

{% if not is_incremental() %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1= row_number()over(partition by SLNK_SUPPLIER_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT MD5_BINARY(GR.VALUE) as SLNK_SUPPLIER_HK
, MD5_BINARY(GR.VALUE) as SUPPLIER_HK
, MD5_BINARY(GR.VALUE) as SAME_AS_SUPPLIER_HK
, GR.VALUE  as BUSINESS_ID
, null as ORIGINAL_BUSINESS_ID
, GR.VALUE  as SUPPLIER_BK
, null as SOURCE_PKEY
, null as SOURCE_SYSTEM
, null as LAST_RUN_DATE
, '1900-01-01'::TIMESTAMP as PSA_LOAD_DTS
, null as PSA_RECORD_SOURCE
, 'N' as PSA_DELETE_IND
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') as BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' as REC_SRC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' as MDM_BKCC
,  ''::BINARY as HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}