---- SRC LAYER ----
WITH
SRC_PrCatWinn      as ( SELECT * FROM {{ ref('v_psa_stg_category_products__profitero_winn') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   ),
SRC_PrCatSec       as ( SELECT * FROM {{ ref('v_psa_stg_category_products__profitero_security') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   ),
SRC_PrCatFib       as ( SELECT * FROM {{ ref('v_psa_stg_category_products__profitero_fiberon') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   ),
SRC_PrCatFyp       as ( SELECT * FROM {{ ref('v_psa_stg_category_products__profitero_fypon') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   ),
SRC_PrCatLrn       as ( SELECT * FROM {{ ref('v_psa_stg_category_products__profitero_larson') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   ),
SRC_PrCatThm       as ( SELECT * FROM {{ ref('v_psa_stg_category_products__profitero_thermatru') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_PrCatWinn      as ( SELECT * FROM STAGING.v_psa_stg_category_products__profitero_winn )
, SRC_PrCatSec       as ( SELECT * FROM STAGING.v_psa_stg_category_products__profitero_security )
, SRC_PrCatFib       as ( SELECT * FROM STAGING.v_psa_stg_category_products__profitero_fiberon )
, SRC_PrCatFyp       as ( SELECT * FROM STAGING.v_psa_stg_category_products__profitero_fypon )
, SRC_PrCatLrn       as ( SELECT * FROM STAGING.v_psa_stg_category_products__profitero_larson )
, SRC_PrCatThm       as ( SELECT * FROM STAGING.v_psa_stg_category_products__profitero_thermatru )
*/
---- LOGIC LAYER ----

, LOGIC_PrCatWinn as (
    SELECT
        CATEGORY_HK
      , LOAD_DTS
      , CATEGORY_ID
      , FULL_NAME
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PrCatWinn
)

, LOGIC_PrCatSec as (
    SELECT
        CATEGORY_HK
      , LOAD_DTS
      , CATEGORY_ID
      , FULL_NAME
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PrCatSec
)

, LOGIC_PrCatFib as (
    SELECT
        CATEGORY_HK
      , LOAD_DTS
      , CATEGORY_ID
      , FULL_NAME
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PrCatFib
)

, LOGIC_PrCatFyp as (
    SELECT
        CATEGORY_HK
      , LOAD_DTS
      , CATEGORY_ID
      , FULL_NAME
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PrCatFyp
)

, LOGIC_PrCatLrn as (
    SELECT
        CATEGORY_HK
      , LOAD_DTS
      , CATEGORY_ID
      , FULL_NAME
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PrCatLrn
)

, LOGIC_PrCatThm as (
    SELECT
        CATEGORY_HK
      , LOAD_DTS
      , CATEGORY_ID
      , FULL_NAME
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PrCatThm
)
---- RENAME LAYER ----

, RENAME_PrCatWinn as (
    SELECT
        CATEGORY_HK
      , LOAD_DTS
      , CATEGORY_ID
      , FULL_NAME
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PrCatWinn
)

, RENAME_PrCatSec as (
    SELECT
        CATEGORY_HK
      , LOAD_DTS
      , CATEGORY_ID
      , FULL_NAME
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PrCatSec
)

, RENAME_PrCatFib as (
    SELECT
        CATEGORY_HK
      , LOAD_DTS
      , CATEGORY_ID
      , FULL_NAME
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PrCatFib
)

, RENAME_PrCatFyp as (
    SELECT
        CATEGORY_HK
      , LOAD_DTS
      , CATEGORY_ID
      , FULL_NAME
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PrCatFyp
)

, RENAME_PrCatLrn as (
    SELECT
        CATEGORY_HK
      , LOAD_DTS
      , CATEGORY_ID
      , FULL_NAME
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PrCatLrn
)

, RENAME_PrCatThm as (
    SELECT
        CATEGORY_HK
      , LOAD_DTS
      , CATEGORY_ID
      , FULL_NAME
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PrCatThm
)
---- FILTER LAYER ----

, FILTER_PrCatWinn as (
    SELECT *
    FROM RENAME_PrCatWinn
)

, FILTER_PrCatSec as (
    SELECT *
    FROM RENAME_PrCatSec
)

, FILTER_PrCatFib as (
    SELECT *
    FROM RENAME_PrCatFib
)

, FILTER_PrCatFyp as (
    SELECT *
    FROM RENAME_PrCatFyp
)

, FILTER_PrCatLrn as (
    SELECT *
    FROM RENAME_PrCatLrn
)

, FILTER_PrCatThm as (
    SELECT *
    FROM RENAME_PrCatThm
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PrCatWinn
    UNION
    SELECT * FROM FILTER_PrCatSec
    UNION
    SELECT * FROM FILTER_PrCatFib
    UNION
    SELECT * FROM FILTER_PrCatFyp
    UNION
    SELECT * FROM FILTER_PrCatLrn
    UNION
    SELECT * FROM FILTER_PrCatThm
)

---- FINAL LAYER ----
SELECT
          CATEGORY_HK
        , LOAD_DTS
        , CATEGORY_ID
        , FULL_NAME
        , UPDATED_AT
        , IS_DELETED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.CATEGORY_ID = JOIN_RESULT.CATEGORY_ID
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}

 
{% if not is_incremental() %}
qualify 1 = row_number() over (partition by CATEGORY_ID, HASHDIFF order by LOAD_DTS desc) 
union all
SELECT MD5_BINARY(GR.VALUE::varchar) CATEGORY_HK
	, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
	, GR.VALUE::NUMBER(38,5) as CATEGORY_ID
	, null as FULL_NAME
	, null as UPDATED_AT
	, null as IS_DELETED
	, null as PSA_LOAD_DTS
	, null as PSA_RECORD_SOURCE
	, null as PSA_DELETE_IND
        , DECODE(GR.VALUE::varchar, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
	, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        , ''::BINARY as HASH_DIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}