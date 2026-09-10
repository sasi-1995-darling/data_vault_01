---- SRC LAYER ----
WITH
SRC_eine           as ( SELECT * FROM {{ ref('v_psa_stg_purchasing_record_org__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PURCHASING_RECORD_DETAILS_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_eine           as ( SELECT * FROM STAGING.v_psa_stg_purchase_record_org__winn )
*/
---- LOGIC LAYER ----

, LOGIC_eine as (
    SELECT
        PURCHASING_RECORD_DETAILS_HK
      , PURCHASING_ORG_HK
      , PURCHASING_RECORD_HK
      , PLANT_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_eine
)
---- RENAME LAYER ----

, RENAME_eine as (
    SELECT
        PURCHASING_RECORD_DETAILS_HK
      , PURCHASING_ORG_HK
      , PURCHASING_RECORD_HK
      , PLANT_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_eine
)
---- FILTER LAYER ----

, FILTER_eine as (
    SELECT *
    FROM RENAME_eine
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_eine
)

---- FINAL LAYER ----
SELECT
          PURCHASING_RECORD_DETAILS_HK
        , PURCHASING_ORG_HK
        , PURCHASING_RECORD_HK
        , PLANT_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PURCHASING_RECORD_DETAILS_HK = JOIN_RESULT.PURCHASING_RECORD_DETAILS_HK
)
{% endif %}

{% if not is_incremental() %}

union all
SELECT
         MD5_BINARY(GR.VALUE) AS PURCHASING_RECORD_DETAILS_HK
		,MD5_BINARY(GR.VALUE) AS PURCHASING_ORG_HK
		,MD5_BINARY(GR.VALUE) AS PURCHASING_RECORD_HK
		,MD5_BINARY(GR.VALUE) AS PLANT_HK		
        , CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
        , 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC    
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

    {% endif %}