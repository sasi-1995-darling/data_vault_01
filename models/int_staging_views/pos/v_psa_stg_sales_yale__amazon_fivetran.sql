---- SRC LAYER ----
WITH
SRC_S              as ( SELECT ASIN, CUSTOMER_RETURNS, END_DATE, ORDERED_REVENUE_AMOUNT, ORDERED_REVENUE_CURRENCY_CODE, ORDERED_UNITS, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SHIPPED_COGS_AMOUNT, SHIPPED_COGS_CURRENCY_CODE, SHIPPED_REVENUE_AMOUNT, SHIPPED_REVENUE_CURRENCY_CODE, SHIPPED_UNITS, START_DATE, _FIVETRAN_SYNCED FROM {{ source('amazon_sp_ft_yale', 'vendor_sales_manufacturing_retail_asin_report_daily') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_C              as ( SELECT cutoff_dt FROM {{ ref('v_psa_stg_ref_avc_talend_migration_cutoff_date') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM amazon_sp_ft_yale.vendor_sales_manufacturing_retail_asin_report_daily )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_C              as ( SELECT * FROM raw_vault.v_psa_stg_ref_avc_talend_migration_cutoff_date )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        'AMAZON'                                                     as                                           STORE_BK
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , END_DATE                                                     as                                    REPORT_END_DATE
      , 'Yale'                                                       as                              VENDORCENTRAL_ACCOUNT
      , ASIN
      , CUSTOMER_RETURNS
      , START_DATE                                                   as                                  REPORT_START_DATE
      , ORDERED_REVENUE_AMOUNT                                       as                               ORDERDED_REVENUE_AMT
      , ORDERED_REVENUE_CURRENCY_CODE                                as                              ORDERDED_REV_CURRCODE
      , ORDERED_UNITS                                                as                                     ORDERDED_UNITS
      , SHIPPED_COGS_AMOUNT                                          as                                   SHIPPED_COGS_AMT
      , SHIPPED_COGS_CURRENCY_CODE                                   as                              SHIPPED_COGS_CURRCODE
      , SHIPPED_REVENUE_AMOUNT                                       as                                SHIPPED_REVENUE_AMT
      , SHIPPED_REVENUE_CURRENCY_CODE                                as                               SHIPPED_REV_CURRCODE
      , SHIPPED_UNITS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , _FIVETRAN_SYNCED
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)

, LOGIC_C as (
    SELECT
        cutoff_dt
    FROM SRC_C
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        STORE_BK
      , LOAD_DTS
      , REPORT_END_DATE
      , VENDORCENTRAL_ACCOUNT
      , ASIN
      , CUSTOMER_RETURNS
      , REPORT_START_DATE
      , ORDERDED_REVENUE_AMT
      , ORDERDED_REV_CURRCODE
      , ORDERDED_UNITS
      , SHIPPED_COGS_AMT
      , SHIPPED_COGS_CURRCODE
      , SHIPPED_REVENUE_AMT
      , SHIPPED_REV_CURRCODE
      , SHIPPED_UNITS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , _FIVETRAN_SYNCED
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)

, RENAME_C as (
    SELECT
        cutoff_dt
    FROM LOGIC_C
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'US.API_FT.AMAZON_VC.SALES'
)

, FILTER_C as (
    SELECT *
    FROM RENAME_C
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
    INNER JOIN FILTER_C
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          STORE_BK
        , LOAD_DTS
        , REPORT_END_DATE
        , VENDORCENTRAL_ACCOUNT
        , ASIN
        , CUSTOMER_RETURNS
        , REPORT_START_DATE
        , ORDERDED_REVENUE_AMT
        , ORDERDED_REV_CURRCODE
        , ORDERDED_UNITS
        , SHIPPED_COGS_AMT
        , SHIPPED_COGS_CURRCODE
        , SHIPPED_REVENUE_AMT
        , SHIPPED_REV_CURRCODE
        , SHIPPED_UNITS
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(STORE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(REPORT_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ORDERDED_REVENUE_AMT::text), '^^') 
            , '||', IFNULL(TRIM(ORDERDED_REV_CURRCODE::text), '^^') 
            , '||', IFNULL(TRIM(ORDERDED_UNITS::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPED_COGS_AMT::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPED_COGS_CURRCODE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPED_REVENUE_AMT::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPED_REV_CURRCODE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPED_UNITS::text), '^^')             
            , '||', IFNULL(TRIM(PSA_RECORD_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
where to_date(report_end_date) > cutoff_dt