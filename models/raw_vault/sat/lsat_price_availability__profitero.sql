---- SRC LAYER ----
WITH
SRC_PrWINN         as ( SELECT * FROM {{ ref('v_psa_stg_price_availability__profitero_winn') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }} where rec_src = 'US.PROFITERO_WINN.PRICING_AVAILABILITY_HISTORY')
                            {% endif %}   ),
SRC_PrSEC          as ( SELECT * FROM {{ ref('v_psa_stg_price_availability__profitero_security') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }} where rec_src = 'US.PROFITERO_SECURITY.PRICING_AVAILABILITY_HISTORY')
                            {% endif %}   ),
SRC_PrTT           as ( SELECT * FROM {{ ref('v_psa_stg_price_availability__profitero_thermatru') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }} where rec_src = 'US.PROFITERO_THERMATRU.PRICING_AVAILABILITY_HISTORY')
                            {% endif %}   ),
SRC_PrFIB          as ( SELECT * FROM {{ ref('v_psa_stg_price_availability__profitero_fiberon') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }} where rec_src = 'US.PROFITERO_FIBERON.PRICING_AVAILABILITY_HISTORY')
                            {% endif %}   ),
SRC_PrFY           as ( SELECT * FROM {{ ref('v_psa_stg_price_availability__profitero_fypon') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }} where rec_src = 'US.PROFITERO_FYPON.PRICING_AVAILABILITY_HISTORY')
                            {% endif %}   ),
SRC_PrLRSN         as ( SELECT * FROM {{ ref('v_psa_stg_price_availability__profitero_larson') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }} where rec_src = 'US.PROFITERO_LARSON.PRICING_AVAILABILITY_HISTORY')
                            {% endif %}   )

/*
SRC_PrWINN         as ( SELECT * FROM STAGING.v_psa_stg_price_availability__profitero_winn )
, SRC_PrSEC          as ( SELECT * FROM STAGING.v_psa_stg_price_availability__profitero_security )
, SRC_PrTT           as ( SELECT * FROM STAGING.v_psa_stg_price_availability__profitero_thermatru )
, SRC_PrFIB          as ( SELECT * FROM STAGING.v_psa_stg_price_availability__profitero_fiberon )
, SRC_PrFY           as ( SELECT * FROM STAGING.v_psa_stg_price_availability__profitero_fypon )
, SRC_PrLRSN         as ( SELECT * FROM STAGING.v_psa_stg_price_availability__profitero_larson )
*/
---- LOGIC LAYER ----

, LOGIC_PrWINN as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , RETAILER_ID
      , PRODUCT_ID
      , UPDATED_AT
      , AVAILABILITY
      , MATCH_TYPE
      , REGULAR_PRICE
      , PROMOTION_TEXT
      , PROMOTION_PRICE
      , FIRST_PARTY_WON_BUY_BOX
      , THIRD_PARTY_SELLER
      , ADD_ON_ITEM
      , PRIME_EXCLUSIVE
      , PROMO_TYPE
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_HK
      , RETAILER_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PrWINN
)

, LOGIC_PrSEC as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , RETAILER_ID
      , PRODUCT_ID
      , UPDATED_AT
      , AVAILABILITY
      , MATCH_TYPE
      , REGULAR_PRICE
      , PROMOTION_TEXT
      , PROMOTION_PRICE
      , FIRST_PARTY_WON_BUY_BOX
      , THIRD_PARTY_SELLER
      , ADD_ON_ITEM
      , PRIME_EXCLUSIVE
      , PROMO_TYPE
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_HK
      , RETAILER_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PrSEC
)

, LOGIC_PrTT as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , RETAILER_ID
      , PRODUCT_ID
      , UPDATED_AT
      , AVAILABILITY
      , MATCH_TYPE
      , REGULAR_PRICE
      , PROMOTION_TEXT
      , PROMOTION_PRICE
      , FIRST_PARTY_WON_BUY_BOX
      , THIRD_PARTY_SELLER
      , ADD_ON_ITEM
      , PRIME_EXCLUSIVE
      , PROMO_TYPE
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_HK
      , RETAILER_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PrTT
)

, LOGIC_PrFIB as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , RETAILER_ID
      , PRODUCT_ID
      , UPDATED_AT
      , AVAILABILITY
      , MATCH_TYPE
      , REGULAR_PRICE
      , PROMOTION_TEXT
      , PROMOTION_PRICE
      , FIRST_PARTY_WON_BUY_BOX
      , THIRD_PARTY_SELLER
      , ADD_ON_ITEM
      , PRIME_EXCLUSIVE
      , PROMO_TYPE
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_HK
      , RETAILER_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PrFIB
)

, LOGIC_PrFY as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , RETAILER_ID
      , PRODUCT_ID
      , UPDATED_AT
      , AVAILABILITY
      , MATCH_TYPE
      , REGULAR_PRICE
      , PROMOTION_TEXT
      , PROMOTION_PRICE
      , FIRST_PARTY_WON_BUY_BOX
      , THIRD_PARTY_SELLER
      , ADD_ON_ITEM
      , PRIME_EXCLUSIVE
      , PROMO_TYPE
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_HK
      , RETAILER_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PrFY
)

, LOGIC_PrLRSN as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , RETAILER_ID
      , PRODUCT_ID
      , UPDATED_AT
      , AVAILABILITY
      , MATCH_TYPE
      , REGULAR_PRICE
      , PROMOTION_TEXT
      , PROMOTION_PRICE
      , FIRST_PARTY_WON_BUY_BOX
      , THIRD_PARTY_SELLER
      , ADD_ON_ITEM
      , PRIME_EXCLUSIVE
      , PROMO_TYPE
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_HK
      , RETAILER_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_PrLRSN
)
---- RENAME LAYER ----

, RENAME_PrWINN as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , RETAILER_ID
      , PRODUCT_ID
      , UPDATED_AT
      , AVAILABILITY
      , MATCH_TYPE
      , REGULAR_PRICE
      , PROMOTION_TEXT
      , PROMOTION_PRICE
      , FIRST_PARTY_WON_BUY_BOX
      , THIRD_PARTY_SELLER
      , ADD_ON_ITEM
      , PRIME_EXCLUSIVE
      , PROMO_TYPE
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_HK
      , RETAILER_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PrWINN
)

, RENAME_PrSEC as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , RETAILER_ID
      , PRODUCT_ID
      , UPDATED_AT
      , AVAILABILITY
      , MATCH_TYPE
      , REGULAR_PRICE
      , PROMOTION_TEXT
      , PROMOTION_PRICE
      , FIRST_PARTY_WON_BUY_BOX
      , THIRD_PARTY_SELLER
      , ADD_ON_ITEM
      , PRIME_EXCLUSIVE
      , PROMO_TYPE
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_HK
      , RETAILER_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PrSEC
)

, RENAME_PrTT as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , RETAILER_ID
      , PRODUCT_ID
      , UPDATED_AT
      , AVAILABILITY
      , MATCH_TYPE
      , REGULAR_PRICE
      , PROMOTION_TEXT
      , PROMOTION_PRICE
      , FIRST_PARTY_WON_BUY_BOX
      , THIRD_PARTY_SELLER
      , ADD_ON_ITEM
      , PRIME_EXCLUSIVE
      , PROMO_TYPE
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_HK
      , RETAILER_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PrTT
)

, RENAME_PrFIB as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , RETAILER_ID
      , PRODUCT_ID
      , UPDATED_AT
      , AVAILABILITY
      , MATCH_TYPE
      , REGULAR_PRICE
      , PROMOTION_TEXT
      , PROMOTION_PRICE
      , FIRST_PARTY_WON_BUY_BOX
      , THIRD_PARTY_SELLER
      , ADD_ON_ITEM
      , PRIME_EXCLUSIVE
      , PROMO_TYPE
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_HK
      , RETAILER_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PrFIB
)

, RENAME_PrFY as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , RETAILER_ID
      , PRODUCT_ID
      , UPDATED_AT
      , AVAILABILITY
      , MATCH_TYPE
      , REGULAR_PRICE
      , PROMOTION_TEXT
      , PROMOTION_PRICE
      , FIRST_PARTY_WON_BUY_BOX
      , THIRD_PARTY_SELLER
      , ADD_ON_ITEM
      , PRIME_EXCLUSIVE
      , PROMO_TYPE
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_HK
      , RETAILER_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PrFY
)

, RENAME_PrLRSN as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , RETAILER_ID
      , PRODUCT_ID
      , UPDATED_AT
      , AVAILABILITY
      , MATCH_TYPE
      , REGULAR_PRICE
      , PROMOTION_TEXT
      , PROMOTION_PRICE
      , FIRST_PARTY_WON_BUY_BOX
      , THIRD_PARTY_SELLER
      , ADD_ON_ITEM
      , PRIME_EXCLUSIVE
      , PROMO_TYPE
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_HK
      , RETAILER_HK
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PrLRSN
)
---- FILTER LAYER ----

, FILTER_PrWINN as (
    SELECT *
    FROM RENAME_PrWINN
)

, FILTER_PrSEC as (
    SELECT *
    FROM RENAME_PrSEC
)

, FILTER_PrTT as (
    SELECT *
    FROM RENAME_PrTT
)

, FILTER_PrFIB as (
    SELECT *
    FROM RENAME_PrFIB
)

, FILTER_PrFY as (
    SELECT *
    FROM RENAME_PrFY
)

, FILTER_PrLRSN as (
    SELECT *
    FROM RENAME_PrLRSN
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PrWINN
    UNION
    SELECT * FROM FILTER_PrSEC
    UNION
    SELECT * FROM FILTER_PrTT
    UNION
    SELECT * FROM FILTER_PrFIB
    UNION
    SELECT * FROM FILTER_PrFY
    UNION
    SELECT * FROM FILTER_PrLRSN
)

---- FINAL LAYER ----
SELECT
          PRODUCT_RETAILER_HK
        , LOAD_DTS
        , DATE
        , CUSTOMER_PRODUCT_ID
        , RETAILER_ID
        , PRODUCT_ID
        , UPDATED_AT
        , AVAILABILITY
        , MATCH_TYPE
        , REGULAR_PRICE
        , PROMOTION_TEXT
        , PROMOTION_PRICE
        , FIRST_PARTY_WON_BUY_BOX
        , THIRD_PARTY_SELLER
        , ADD_ON_ITEM
        , PRIME_EXCLUSIVE
        , PROMO_TYPE
        , IS_DELETED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , PRODUCT_HK
        , RETAILER_HK
        , BKCC
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PRODUCT_ID = JOIN_RESULT.PRODUCT_ID
    AND existing.CUSTOMER_PRODUCT_ID = JOIN_RESULT.CUSTOMER_PRODUCT_ID
    AND existing.RETAILER_ID = JOIN_RESULT.RETAILER_ID
    AND existing.DATE = JOIN_RESULT.DATE
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}

 
{% if not is_incremental() %}
qualify 1 = row_number() over (partition by PRODUCT_ID, CUSTOMER_PRODUCT_ID, RETAILER_ID, DATE, HASHDIFF order by LOAD_DTS desc) 
union all
SELECT MD5_BINARY(GR.VALUE::varchar) AS PRODUCT_RETAILER_HK
	, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
	, GR.VALUE::varchar as DATE
	, GR.VALUE::varchar as CUSTOMER_PRODUCT_ID
	, GR.VALUE::varchar as RETAILER_ID
	, GR.VALUE::varchar as PRODUCT_ID
	, null as UPDATED_AT
	, null as AVAILABILITY
	, null as MATCH_TYPE
	, null as REGULAR_PRICE
	, null as PROMOTION_TEXT
	, null as PROMOTION_PRICE
	, null as FIRST_PARTY_WON_BUY_BOX
	, null as THIRD_PARTY_SELLER
	, null as ADD_ON_ITEM
	, null as PRIME_EXCLUSIVE
	, null as PROMO_TYPE
	, null as IS_DELETED
	, null as PSA_LOAD_DTS
	, null as PSA_RECORD_SOURCE
	, null as PSA_DELETE_IND
	, MD5_BINARY(GR.VALUE::varchar) AS PRODUCT_HK
	, MD5_BINARY(GR.VALUE::varchar) AS RETAILER_HK
	, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        , DECODE(GR.VALUE::varchar, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
        , ''::BINARY as HASH_DIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}