---- SRC LAYER ----
WITH
SRC_MDM            as ( SELECT * FROM {{ ref('v_psa_stg_supplier_mdm') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_MDM            as ( SELECT * FROM STAGING.v_psa_stg_supplier_mdm )
*/
---- LOGIC LAYER ----

, LOGIC_MDM as (
    SELECT
        SUPPLIER_HK
      , BUSINESS_ID
      , SUPPLIER_ID
      , CREATE_DATE
      , LAST_UPDATE_DATE
      , LAST_RUN_DATE
      , NAME
      , ALTERNATE_NAME
      , INDUSTRY_TYPE
      , SUPPLIER_STATUS
      , OWNERSHIP_TYPE
      , INACTIVATION_DATE
      , REPORTING_COUNTRY
      , REPORTING_CONTINENT
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_MDM
)
---- RENAME LAYER ----

, RENAME_MDM as (
    SELECT
        SUPPLIER_HK
      , BUSINESS_ID
      , SUPPLIER_ID
      , CREATE_DATE
      , LAST_UPDATE_DATE
      , LAST_RUN_DATE
      , NAME
      , ALTERNATE_NAME
      , INDUSTRY_TYPE
      , SUPPLIER_STATUS
      , OWNERSHIP_TYPE
      , INACTIVATION_DATE
      , REPORTING_COUNTRY
      , REPORTING_CONTINENT
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_MDM
)
---- FILTER LAYER ----

, FILTER_MDM as (
    SELECT *
    FROM RENAME_MDM
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_MDM
)

---- FINAL LAYER ----
SELECT
          SUPPLIER_HK
        , BUSINESS_ID
        , SUPPLIER_ID
        , CREATE_DATE
        , LAST_UPDATE_DATE
        , LAST_RUN_DATE
        , NAME
        , ALTERNATE_NAME
        , INDUSTRY_TYPE
        , SUPPLIER_STATUS
        , OWNERSHIP_TYPE
        , INACTIVATION_DATE
        , REPORTING_COUNTRY
        , REPORTING_CONTINENT
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , LOAD_DTS
        , BKCC
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.SUPPLIER_HK = JOIN_RESULT.SUPPLIER_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 

{% if not is_incremental() %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1= row_number()over(partition by SUPPLIER_HK, HASHDIFF order by PSA_LOAD_DTS)

union all

SELECT MD5_BINARY(GR.VALUE) AS SUPPLIER_HK
        , GR.VALUE AS BUSINESS_ID
        , GR.VALUE AS SUPPLIER_ID
        , NULL AS CREATE_DATE
        , NULL AS LAST_UPDATE_DATE
        , NULL AS LAST_RUN_DATE
        , NULL AS NAME
        , NULL AS ALTERNATE_NAME
        , NULL AS INDUSTRY_TYPE
        , NULL AS SUPPLIER_STATUS
        , NULL AS OWNERSHIP_TYPE
        , NULL AS INACTIVATION_DATE
        , NULL AS REPORTING_COUNTRY
        , NULL AS REPORTING_CONTINENT
        , '1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS
        , 'N' AS PSA_DELETE_IND
        , CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
        , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
        , 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        , ''::BINARY as HASH_DIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}