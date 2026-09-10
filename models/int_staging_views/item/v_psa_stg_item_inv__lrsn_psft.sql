---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_inv_items') }} as SRC 
                        /* The following qualify clause is required to pick the latest change for a day when there are Intra day changes,
                            when Fivetran resync triggered by manual sync multiple times in a day(Resync Happens usually once per week currently). Ex. cust_id ='36196' */
                            qualify 1 = row_number() over(partition by INV_ITEM_ID,SETID,EFFDT, _fivetran_synced order by psa_load_dts desc) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM lrsn_psft_sysadm.ps_inv_items )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        INV_ITEM_ID                                                  as                                            ITEM_BK
      , INV_ITEM_ID
      , SETID
      , CONVERT_TIMEZONE('UTC',EFFDT )                               as                                            EFFDT
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
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        ITEM_BK
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
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.PS_INV_ITEMS'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          ITEM_BK
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
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SETID::text), '^^') 
            , '||', IFNULL(TRIM(EFFDT::text), '^^') 
            , '||', IFNULL(TRIM(UPC_ID::text), '^^') 
            , '||', IFNULL(TRIM(POTENCY_RATING::text), '^^') 
            , '||', IFNULL(TRIM(INV_ITEM_TEMPLATE::text), '^^') 
            , '||', IFNULL(TRIM(INV_ITEM_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(RECYCLE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(REUSABLE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(DISPOSABLE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(INV_STOCK_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PACKING_CD::text), '^^') 
            , '||', IFNULL(TRIM(STOR_RULES_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(RECOM_STOR_TEMP::text), '^^') 
            , '||', IFNULL(TRIM(RECOM_HUMIDITY_PCT::text), '^^') 
            , '||', IFNULL(TRIM(INV_PROD_GRADE::text), '^^') 
            , '||', IFNULL(TRIM(MAX_CAPACITY::text), '^^') 
            , '||', IFNULL(TRIM(HAZ_CLASS_CD::text), '^^') 
            , '||', IFNULL(TRIM(INTL_HAZARD_ID::text), '^^') 
            , '||', IFNULL(TRIM(CHARGE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SHELF_LIFE::text), '^^') 
            , '||', IFNULL(TRIM(AVAIL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(INV_ITEM_HEIGHT::text), '^^') 
            , '||', IFNULL(TRIM(INV_ITEM_LENGTH::text), '^^') 
            , '||', IFNULL(TRIM(INV_ITEM_WIDTH::text), '^^') 
            , '||', IFNULL(TRIM(INV_ITEM_WEIGHT::text), '^^') 
            , '||', IFNULL(TRIM(INV_ITEM_VOLUME::text), '^^') 
            , '||', IFNULL(TRIM(INV_ITEM_SIZE::text), '^^') 
            , '||', IFNULL(TRIM(INV_ITEM_COLOR::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_MEASURE_DIM::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_MEASURE_WT::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_MEASURE_TEMP::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_MEASURE_VOL::text), '^^') 
            , '||', IFNULL(TRIM(COMMODITY_CD::text), '^^') 
            , '||', IFNULL(TRIM(HARMONIZED_CD::text), '^^') 
            , '||', IFNULL(TRIM(MSDS_ID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_MAINT_OPRID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_DTTM_UPDATE::text), '^^') 
            , '||', IFNULL(TRIM(DESCR254::text), '^^') 
            , '||', IFNULL(TRIM(COMMODITY_CD_EU::text), '^^') 
            , '||', IFNULL(TRIM(AVAIL_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(RETEST_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(CHARGE_MARKUP_PCNT::text), '^^') 
            , '||', IFNULL(TRIM(CHARGE_MARKUP_AMT::text), '^^') 
            , '||', IFNULL(TRIM(CONSUMABLE_FLG::text), '^^') 
            , '||', IFNULL(TRIM(RETURNABLE_FLG::text), '^^') 
            , '||', IFNULL(TRIM(SERVICEABLE_FLG::text), '^^') 
            , '||', IFNULL(TRIM(SERVICE_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(SERVICE_EXCH_AMT::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY_CD::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
