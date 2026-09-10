---- SRC LAYER ----
WITH
SRC_PrPrdWinn      as ( SELECT * FROM {{ ref('v_psa_stg_competitive_products__profitero_winn') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   ),
SRC_PrPrdSec       as ( SELECT * FROM {{ ref('v_psa_stg_competitive_products__profitero_security') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   ),
SRC_PrPrdFib       as ( SELECT * FROM {{ ref('v_psa_stg_competitive_products__profitero_fiberon') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   ),
SRC_PrPrdFyp       as ( SELECT * FROM {{ ref('v_psa_stg_competitive_products__profitero_fypon') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   ),
SRC_PrPrdLrsn      as ( SELECT * FROM {{ ref('v_psa_stg_competitive_products__profitero_larson') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   ),
SRC_PrPrdTt        as ( SELECT * FROM {{ ref('v_psa_stg_competitive_products__profitero_thermatru') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_PrPrdWinn      as ( SELECT * FROM STAGING.v_psa_stg_competitive_products__profitero_winn )
, SRC_PrPrdSec       as ( SELECT * FROM STAGING.v_psa_stg_competitive_products__profitero_security )
, SRC_PrPrdFib       as ( SELECT * FROM STAGING.v_psa_stg_competitive_products__profitero_fiberon )
, SRC_PrPrdFyp       as ( SELECT * FROM STAGING.v_psa_stg_competitive_products__profitero_fypon )
, SRC_PrPrdLrsn      as ( SELECT * FROM STAGING.v_psa_stg_competitive_products__profitero_larson )
, SRC_PrPrdTt        as ( SELECT * FROM STAGING.v_psa_stg_competitive_products__profitero_thermatru )
*/
---- LOGIC LAYER ----

, LOGIC_PrPrdWinn as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , LOAD_DTS
      , COMPETITIVE_PRODUCT_ID
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , RETAILER_ID
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_ID
      , RETAILER_HK
      , PRODUCT_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PrPrdWinn
)

, LOGIC_PrPrdSec as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , LOAD_DTS
      , COMPETITIVE_PRODUCT_ID
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , RETAILER_ID
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_ID
      , RETAILER_HK
      , PRODUCT_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PrPrdSec
)

, LOGIC_PrPrdFib as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , LOAD_DTS
      , COMPETITIVE_PRODUCT_ID
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , RETAILER_ID
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_ID
      , RETAILER_HK
      , PRODUCT_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PrPrdFib
)

, LOGIC_PrPrdFyp as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , LOAD_DTS
      , COMPETITIVE_PRODUCT_ID
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , RETAILER_ID
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_ID
      , RETAILER_HK
      , PRODUCT_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PrPrdFyp
)

, LOGIC_PrPrdLrsn as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , LOAD_DTS
      , COMPETITIVE_PRODUCT_ID
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , RETAILER_ID
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_ID
      , RETAILER_HK
      , PRODUCT_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PrPrdLrsn
)

, LOGIC_PrPrdTt as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , LOAD_DTS
      , COMPETITIVE_PRODUCT_ID
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , RETAILER_ID
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_ID
      , RETAILER_HK
      , PRODUCT_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PrPrdTt
)

---- RENAME LAYER ----

, RENAME_PrPrdWinn as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , LOAD_DTS
      , COMPETITIVE_PRODUCT_ID
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , RETAILER_ID
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_ID
      , RETAILER_HK
      , PRODUCT_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PrPrdWinn
)

, RENAME_PrPrdSec as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , LOAD_DTS
      , COMPETITIVE_PRODUCT_ID
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , RETAILER_ID
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_ID
      , RETAILER_HK
      , PRODUCT_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PrPrdSec
)

, RENAME_PrPrdFib as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , LOAD_DTS
      , COMPETITIVE_PRODUCT_ID
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , RETAILER_ID
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_ID
      , RETAILER_HK
      , PRODUCT_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PrPrdFib
)

, RENAME_PrPrdFyp as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , LOAD_DTS
      , COMPETITIVE_PRODUCT_ID
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , RETAILER_ID
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_ID
      , RETAILER_HK
      , PRODUCT_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PrPrdFyp
)

, RENAME_PrPrdLrsn as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , LOAD_DTS
      , COMPETITIVE_PRODUCT_ID
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , RETAILER_ID
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_ID
      , RETAILER_HK
      , PRODUCT_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PrPrdLrsn
)

, RENAME_PrPrdTt as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , LOAD_DTS
      , COMPETITIVE_PRODUCT_ID
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , RETAILER_ID
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_ID
      , RETAILER_HK
      , PRODUCT_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PrPrdTt
)

---- FILTER LAYER ----

, FILTER_PrPrdWinn as (
    SELECT *
    FROM RENAME_PrPrdWinn
)

, FILTER_PrPrdSec as (
    SELECT *
    FROM RENAME_PrPrdSec
)

, FILTER_PrPrdFib as (
    SELECT *
    FROM RENAME_PrPrdFib
)

, FILTER_PrPrdFyp as (
    SELECT *
    FROM RENAME_PrPrdFyp
)

, FILTER_PrPrdLrsn as (
    SELECT *
    FROM RENAME_PrPrdLrsn
)

, FILTER_PrPrdTt as (
    SELECT *
    FROM RENAME_PrPrdTt
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PrPrdWinn
    UNION
    SELECT * FROM FILTER_PrPrdSec
    UNION
    SELECT * FROM FILTER_PrPrdFib
    UNION
    SELECT * FROM FILTER_PrPrdFyp
    UNION
    SELECT * FROM FILTER_PrPrdLrsn
    UNION
    SELECT * FROM FILTER_PrPrdTt
)

---- FINAL LAYER ----
SELECT
          COMPETITIVE_PRODUCT_HK
        , LOAD_DTS
        , COMPETITIVE_PRODUCT_ID
        , RANKING_PRODUCT_ID
        , RPC
        , EAN
        , UPC
        , MODEL
        , URL
        , RETAILER_ID
        , UPDATED_AT
        , IS_DELETED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , PRODUCT_ID
        , RETAILER_HK
        , PRODUCT_HK
        , BKCC
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.COMPETITIVE_PRODUCT_ID = JOIN_RESULT.COMPETITIVE_PRODUCT_ID
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}

 
{% if not is_incremental() %}
qualify 1 = row_number() over (partition by COMPETITIVE_PRODUCT_ID, HASHDIFF order by LOAD_DTS desc) 
union all
SELECT MD5_BINARY(GR.VALUE::varchar) COMPETITIVE_PRODUCT_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
, null as COMPETITIVE_PRODUCT_ID
, null as RANKING_PRODUCT_ID
, null as RPC
, null as EAN
, null as UPC
, null as MODEL
, null as URL
, null as RETAILER_ID
, null as UPDATED_AT
, null as IS_DELETED
, null as PSA_LOAD_DTS
, null as PSA_RECORD_SOURCE
, null as PSA_DELETE_IND
, null as PRODUCT_ID
, MD5_BINARY(GR.VALUE::varchar) RETAILER_HK
, MD5_BINARY(GR.VALUE::varchar) PRODUCT_HK
        , DECODE(GR.VALUE::varchar, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        , ''::BINARY as HASH_DIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}