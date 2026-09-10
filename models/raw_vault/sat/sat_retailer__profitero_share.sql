---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT * FROM {{ ref('v_psa_stg_retailers__winn_profitero_share') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  ),
SRC_S2             as ( SELECT * FROM {{ ref('v_psa_stg_retailers__security_profitero_share') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  ),
SRC_S3             as ( SELECT * FROM {{ ref('v_psa_stg_retailers__fypon_profitero_share') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  ),
SRC_S4             as ( SELECT * FROM {{ ref('v_psa_stg_retailers__fiberon_profitero_share') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  ),
SRC_S5             as ( SELECT * FROM {{ ref('v_psa_stg_retailers__thermatru_profitero_share') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  ),
SRC_S6             as ( SELECT * FROM {{ ref('v_psa_stg_retailers__larson_profitero_share') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  ),
SRC_S7             as ( SELECT * FROM {{ ref('v_psa_stg_retailers_location__winn_profitero_share') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  ),
SRC_S8             as ( SELECT * FROM {{ ref('v_psa_stg_retailers_location__security_profitero_share') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  ),
SRC_S9             as ( SELECT * FROM {{ ref('v_psa_stg_retailers_location__fypon_profitero_share') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  ),
SRC_S10            as ( SELECT * FROM {{ ref('v_psa_stg_retailers_location__fiberon_profitero_share') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  ),
SRC_S11            as ( SELECT * FROM {{ ref('v_psa_stg_retailers_location__thermatru_profitero_share') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  ),
SRC_S12            as ( SELECT * FROM {{ ref('v_psa_stg_retailers_location__larson_profitero_share') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_S1             as ( SELECT * FROM staging.v_psa_stg_retailers__winn_profitero_share )
SRC_S2             as ( SELECT * FROM staging.v_psa_stg_retailers__security_profitero_share )
SRC_S3             as ( SELECT * FROM staging.v_psa_stg_retailers__fypon_profitero_share )
SRC_S4             as ( SELECT * FROM staging.v_psa_stg_retailers__fiberon_profitero_share )
SRC_S5             as ( SELECT * FROM staging.v_psa_stg_retailers__thermatru_profitero_share )
SRC_S6             as ( SELECT * FROM staging.v_psa_stg_retailers__larson_profitero_share )
SRC_S7             as ( SELECT * FROM staging.v_psa_stg_retailers_location__winn_profitero_share )
SRC_S8             as ( SELECT * FROM staging.v_psa_stg_retailers_location__security_profitero_share )
SRC_S9             as ( SELECT * FROM staging.v_psa_stg_retailers_location__fypon_profitero_share )
SRC_S10            as ( SELECT * FROM staging.v_psa_stg_retailers_location__fiberon_profitero_share )
SRC_S11            as ( SELECT * FROM staging.v_psa_stg_retailers_location__thermatru_profitero_share )
SRC_S12            as ( SELECT * FROM staging.v_psa_stg_retailers_location__larson_profitero_share )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_S1
)

, LOGIC_S2 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_S2
)

, LOGIC_S3 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_S3
)

, LOGIC_S4 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_S4
)

, LOGIC_S5 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_S5
)

, LOGIC_S6 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_S6
)

, LOGIC_S7 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_S7
)

, LOGIC_S8 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_S8
)

, LOGIC_S9 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_S9
)

, LOGIC_S10 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_S10
)

, LOGIC_S11 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_S11
)

, LOGIC_S12 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_S12
)
---- RENAME LAYER ----

, RENAME_S1 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_S1
)

, RENAME_S2 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_S2
)

, RENAME_S3 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_S3
)

, RENAME_S4 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_S4
)

, RENAME_S5 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_S5
)

, RENAME_S6 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_S6
)

, RENAME_S7 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_S7
)

, RENAME_S8 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_S8
)

, RENAME_S9 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_S9
)

, RENAME_S10 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_S10
)

, RENAME_S11 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_S11
)

, RENAME_S12 as (
    SELECT
        RETAILER_HK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_S12
)
---- FILTER LAYER ----

, FILTER_S1 as (
    SELECT *
    FROM RENAME_S1
)

, FILTER_S2 as (
    SELECT *
    FROM RENAME_S2
)

, FILTER_S3 as (
    SELECT *
    FROM RENAME_S3
)

, FILTER_S4 as (
    SELECT *
    FROM RENAME_S4
)

, FILTER_S5 as (
    SELECT *
    FROM RENAME_S5
)

, FILTER_S6 as (
    SELECT *
    FROM RENAME_S6
)

, FILTER_S7 as (
    SELECT *
    FROM RENAME_S7
)

, FILTER_S8 as (
    SELECT *
    FROM RENAME_S8
)

, FILTER_S9 as (
    SELECT *
    FROM RENAME_S9
)

, FILTER_S10 as (
    SELECT *
    FROM RENAME_S10
)

, FILTER_S11 as (
    SELECT *
    FROM RENAME_S11
)

, FILTER_S12 as (
    SELECT *
    FROM RENAME_S12
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_S1
    UNION ALL
    SELECT * FROM FILTER_S2
    UNION ALL
    SELECT * FROM FILTER_S3
    UNION ALL
    SELECT * FROM FILTER_S4
    UNION ALL
    SELECT * FROM FILTER_S5
    UNION ALL
    SELECT * FROM FILTER_S6
    UNION ALL
    SELECT * FROM FILTER_S7
    UNION ALL
    SELECT * FROM FILTER_S8
    UNION ALL
    SELECT * FROM FILTER_S9
    UNION ALL
    SELECT * FROM FILTER_S10
    UNION ALL
    SELECT * FROM FILTER_S11
    UNION ALL
    SELECT * FROM FILTER_S12
)

---- FINAL LAYER ----
SELECT
          RETAILER_HK
        , LOAD_DTS
        , DIM_RETAILER_KEY
        , COUNTRY
        , UPDATED_AT
        , IS_DELETED
        , RETAILER_ALIAS
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
    WHERE existing.RETAILER_HK = JOIN_RESULT.RETAILER_HK     AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}

qualify 1= row_number()over(partition by RETAILER_HK, HASHDIFF order by UPDATED_AT desc, PSA_LOAD_DTS desc) 

{% if not is_incremental() %}
union all
SELECT 
	MD5_BINARY(GR.VALUE) AS RETAILER_HK	
	, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
	, null as DIM_RETAILER_KEY
	, null as COUNTRY
	, null as UPDATED_AT
	, null as IS_DELETED
                , null as RETAILER_ALIAS
	, null as PSA_LOAD_DTS
	, null as PSA_RECORD_SOURCE
	, null as PSA_DELETE_IND
	, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
	, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
	, ''::BINARY as HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}