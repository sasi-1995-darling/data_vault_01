---- SRC LAYER ----
WITH
SRC_SITMLR         as ( SELECT * FROM {{ ref('v_psa_stg_item_inv__lrsn_psft') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SITMLR         as ( SELECT * FROM STAGING.v_psa_stg_item_inv__lrsn_psft )
*/
---- LOGIC LAYER ----

, LOGIC_SITMLR as (
    SELECT
        ITEM_HK
      , INV_ITEM_ID
      , SETID
      , EFFDT
      , UPC_ID
      , POTENCY_RATING
      , INV_ITEM_TEMPLATE
      , INV_ITEM_TYPE
      , RECYCLE_FLAG
      , REUSABLE_FLAG
      , DISPOSABLE_FLAG
      , INV_STOCK_TYPE
      , PACKING_CD
      , STOR_RULES_ID
      , SHIP_TYPE_ID
      , RECOM_STOR_TEMP
      , RECOM_HUMIDITY_PCT
      , INV_PROD_GRADE
      , MAX_CAPACITY
      , HAZ_CLASS_CD
      , INTL_HAZARD_ID
      , CHARGE_CODE
      , SHELF_LIFE
      , AVAIL_STATUS
      , INV_ITEM_HEIGHT
      , INV_ITEM_LENGTH
      , INV_ITEM_WIDTH
      , INV_ITEM_WEIGHT
      , INV_ITEM_VOLUME
      , INV_ITEM_SIZE
      , INV_ITEM_COLOR
      , UNIT_MEASURE_DIM
      , UNIT_MEASURE_WT
      , UNIT_MEASURE_TEMP
      , UNIT_MEASURE_VOL
      , COMMODITY_CD
      , HARMONIZED_CD
      , MSDS_ID
      , LAST_MAINT_OPRID
      , LAST_DTTM_UPDATE
      , DESCR254
      , COMMODITY_CD_EU
      , AVAIL_LEAD_TIME
      , RETEST_LEAD_TIME
      , CHARGE_MARKUP_PCNT
      , CHARGE_MARKUP_AMT
      , CONSUMABLE_FLG
      , RETURNABLE_FLG
      , SERVICEABLE_FLG
      , SERVICE_PRICE
      , SERVICE_EXCH_AMT
      , CURRENCY_CD
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SITMLR
)
---- RENAME LAYER ----

, RENAME_SITMLR as (
    SELECT
        ITEM_HK
      , INV_ITEM_ID
      , SETID
      , EFFDT
      , UPC_ID
      , POTENCY_RATING
      , INV_ITEM_TEMPLATE
      , INV_ITEM_TYPE
      , RECYCLE_FLAG
      , REUSABLE_FLAG
      , DISPOSABLE_FLAG
      , INV_STOCK_TYPE
      , PACKING_CD
      , STOR_RULES_ID
      , SHIP_TYPE_ID
      , RECOM_STOR_TEMP
      , RECOM_HUMIDITY_PCT
      , INV_PROD_GRADE
      , MAX_CAPACITY
      , HAZ_CLASS_CD
      , INTL_HAZARD_ID
      , CHARGE_CODE
      , SHELF_LIFE
      , AVAIL_STATUS
      , INV_ITEM_HEIGHT
      , INV_ITEM_LENGTH
      , INV_ITEM_WIDTH
      , INV_ITEM_WEIGHT
      , INV_ITEM_VOLUME
      , INV_ITEM_SIZE
      , INV_ITEM_COLOR
      , UNIT_MEASURE_DIM
      , UNIT_MEASURE_WT
      , UNIT_MEASURE_TEMP
      , UNIT_MEASURE_VOL
      , COMMODITY_CD
      , HARMONIZED_CD
      , MSDS_ID
      , LAST_MAINT_OPRID
      , LAST_DTTM_UPDATE
      , DESCR254
      , COMMODITY_CD_EU
      , AVAIL_LEAD_TIME
      , RETEST_LEAD_TIME
      , CHARGE_MARKUP_PCNT
      , CHARGE_MARKUP_AMT
      , CONSUMABLE_FLG
      , RETURNABLE_FLG
      , SERVICEABLE_FLG
      , SERVICE_PRICE
      , SERVICE_EXCH_AMT
      , CURRENCY_CD
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SITMLR
)
---- FILTER LAYER ----

, FILTER_SITMLR as (
    SELECT *
    FROM RENAME_SITMLR
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SITMLR
)

---- FINAL LAYER ----
SELECT
          ITEM_HK
        , INV_ITEM_ID
        , SETID
        , EFFDT
        , UPC_ID
        , POTENCY_RATING
        , INV_ITEM_TEMPLATE
        , INV_ITEM_TYPE
        , RECYCLE_FLAG
        , REUSABLE_FLAG
        , DISPOSABLE_FLAG
        , INV_STOCK_TYPE
        , PACKING_CD
        , STOR_RULES_ID
        , SHIP_TYPE_ID
        , RECOM_STOR_TEMP
        , RECOM_HUMIDITY_PCT
        , INV_PROD_GRADE
        , MAX_CAPACITY
        , HAZ_CLASS_CD
        , INTL_HAZARD_ID
        , CHARGE_CODE
        , SHELF_LIFE
        , AVAIL_STATUS
        , INV_ITEM_HEIGHT
        , INV_ITEM_LENGTH
        , INV_ITEM_WIDTH
        , INV_ITEM_WEIGHT
        , INV_ITEM_VOLUME
        , INV_ITEM_SIZE
        , INV_ITEM_COLOR
        , UNIT_MEASURE_DIM
        , UNIT_MEASURE_WT
        , UNIT_MEASURE_TEMP
        , UNIT_MEASURE_VOL
        , COMMODITY_CD
        , HARMONIZED_CD
        , MSDS_ID
        , LAST_MAINT_OPRID
        , LAST_DTTM_UPDATE
        , DESCR254
        , COMMODITY_CD_EU
        , AVAIL_LEAD_TIME
        , RETEST_LEAD_TIME
        , CHARGE_MARKUP_PCNT
        , CHARGE_MARKUP_AMT
        , CONSUMABLE_FLG
        , RETURNABLE_FLG
        , SERVICEABLE_FLG
        , SERVICE_PRICE
        , SERVICE_EXCH_AMT
        , CURRENCY_CD
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
    WHERE existing.ITEM_HK= JOIN_RESULT.ITEM_HK
  AND existing.SETID = JOIN_RESULT.SETID
  AND existing.EFFDT = JOIN_RESULT.EFFDT
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by ITEM_HK,SETID,EFFDT, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        MD5_BINARY(GR.VALUE) AS ITEM_HK
    , GR.VALUE as INV_ITEM_ID
    , GR.VALUE as SETID
    , DATE('1900-01-01') as EFFDT
    , null as UPC_ID
    , null as POTENCY_RATING
    , null as INV_ITEM_TEMPLATE
    , null as INV_ITEM_TYPE
    , null as RECYCLE_FLAG
    , null as REUSABLE_FLAG
    , null as DISPOSABLE_FLAG
    , null as INV_STOCK_TYPE
    , null as PACKING_CD
    , null as STOR_RULES_ID
    , null as SHIP_TYPE_ID
    , null as RECOM_STOR_TEMP
    , null as RECOM_HUMIDITY_PCT
    , null as INV_PROD_GRADE
    , null as MAX_CAPACITY
    , null as HAZ_CLASS_CD
    , null as INTL_HAZARD_ID
    , null as CHARGE_CODE
    , null as SHELF_LIFE
    , null as AVAIL_STATUS
    , null as INV_ITEM_HEIGHT
    , null as INV_ITEM_LENGTH
    , null as INV_ITEM_WIDTH
    , null as INV_ITEM_WEIGHT
    , null as INV_ITEM_VOLUME
    , null as INV_ITEM_SIZE
    , null as INV_ITEM_COLOR
    , null as UNIT_MEASURE_DIM
    , null as UNIT_MEASURE_WT
    , null as UNIT_MEASURE_TEMP
    , null as UNIT_MEASURE_VOL
    , null as COMMODITY_CD
    , null as HARMONIZED_CD
    , null as MSDS_ID
    , null as LAST_MAINT_OPRID
    , null as LAST_DTTM_UPDATE
    , null as DESCR254
    , null as COMMODITY_CD_EU
    , null as AVAIL_LEAD_TIME
    , null as RETEST_LEAD_TIME
    , null as CHARGE_MARKUP_PCNT
    , null as CHARGE_MARKUP_AMT
    , null as CONSUMABLE_FLG
    , null as RETURNABLE_FLG
    , null as SERVICEABLE_FLG
    , null as SERVICE_PRICE
    , null as SERVICE_EXCH_AMT
    , null as CURRENCY_CD  
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