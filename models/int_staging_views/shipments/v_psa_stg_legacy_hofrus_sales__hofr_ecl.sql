---- SRC LAYER ----
WITH
SRC_s              as ( SELECT AGENCY, AGENCY_TEMP, BASE_MATERIAL_DESCRIPTION, BRANCH, BRAND_FORECAST, BUYING_GROUP1, BUYING_GROUP2, CHANNEL, COGS, COMPANY, CUSTOMER, 
                               CUSTOMERSALESKEY, CUSTOMER_DESCRIPTION, CUSTOMER_FORECAST, CUSTOMER_KEY, CUSTOMER_NUMBER, DATASOURCE, DATATYPE, DATE, FERG_OR_NON_FERG, 
                               FISCALDATE_KEY, FP_FISCAL_YEAR, GROSS_SALES_BEFORE_FREIGHT, INVOICE_NO, ITEM, ITEM_DESC, ITEM_NUMBER1, ITEM_NUMBER2, ITEM_NUMBER_TEMP, 
                               MATERIAL_KEY, MONTH, MONTH_WEEK, MSA, ORDER_DATE, ORIGINAL_ZIP, PRODUCT_GROUP, PROGRAM_LEVEL1, PROGRAM_LEVEL2, PSA_DELETE_IND, PSA_LOAD_DTS, 
                               PSA_RECORD_SOURCE, QTY, REGION, REQUIRED_DATE, SALES, SAPCODE, SHIPPED_QTY, SHPSTATE, STATE, TERRITORY, UNIQUE_KEY, UNIVERSAL_CUSTOMER_NAME, 
                               WEEK_NUMBER, YEAR FROM {{ source('hofr_eclipse', 'hofr_us_sales') }} as SRC  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_x              as ( SELECT CUSTOMER_AS_SAP, ECLIPSE_ID FROM {{ source('hofr_eclipse', 'eclipse_sap_cust_xref') }} as SRC  )

/*
SRC_s              as ( SELECT * FROM hofr_eclipse.hofr_us_sales )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_x              as ( SELECT * FROM hofr_eclipse.eclipse_sap_cust_xref )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        COALESCE(NULLIF(TRIM(ITEM_NUMBER1),''),'-1')                 as                                            ITEM_BK
      , COALESCE(NULLIF(TRIM(INVOICE_NO),''),'-1')                   as                                         INVOICE_BK
      , FISCALDATE_KEY
      , DATASOURCE
      , DATATYPE
      , CUSTOMER_NUMBER
      , CUSTOMER
      , ITEM
      , ITEM_NUMBER1
      , QTY
      , SALES
      , COGS
      , SHPSTATE
      , STATE
      , COMPANY
      , DATE
      , YEAR
      , MONTH
      , FERG_OR_NON_FERG
      , PRODUCT_GROUP
      , BRAND_FORECAST
      , CUSTOMER_FORECAST
      , UNIVERSAL_CUSTOMER_NAME
      , AGENCY
      , AGENCY_TEMP
      , REGION
      , TERRITORY
      , BUYING_GROUP1
      , ORIGINAL_ZIP
      , PROGRAM_LEVEL1
      , CHANNEL
      , MSA
      , SAPCODE
      , MONTH_WEEK
      , BRANCH
      , WEEK_NUMBER
      , BUYING_GROUP2
      , PROGRAM_LEVEL2
      , INVOICE_NO
      , REQUIRED_DATE
      , ORDER_DATE
      , CUSTOMER_KEY
      , CUSTOMER_DESCRIPTION
      , CUSTOMERSALESKEY
      , ITEM_DESC
      , BASE_MATERIAL_DESCRIPTION
      , ITEM_NUMBER_TEMP
      , ITEM_NUMBER2
      , MATERIAL_KEY
      , SHIPPED_QTY
      , GROSS_SALES_BEFORE_FREIGHT
      , FP_FISCAL_YEAR
      , UNIQUE_KEY
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP)                   as                                           LOAD_DTS
      , LPAD(CUSTOMER_NUMBER, 10, '0')                               as                                  S_CUSTOMER_NUMBER
    FROM SRC_s
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)

, LOGIC_x as (
    SELECT
        CUSTOMER_AS_SAP
      , ECLIPSE_ID
    FROM SRC_x
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        ITEM_BK
      , INVOICE_BK
      , FISCALDATE_KEY
      , DATASOURCE
      , DATATYPE
      , CUSTOMER_NUMBER
      , CUSTOMER
      , ITEM
      , ITEM_NUMBER1
      , QTY
      , SALES
      , COGS
      , SHPSTATE
      , STATE
      , COMPANY
      , DATE
      , YEAR
      , MONTH
      , FERG_OR_NON_FERG
      , PRODUCT_GROUP
      , BRAND_FORECAST
      , CUSTOMER_FORECAST
      , UNIVERSAL_CUSTOMER_NAME
      , AGENCY
      , AGENCY_TEMP
      , REGION
      , TERRITORY
      , BUYING_GROUP1
      , ORIGINAL_ZIP
      , PROGRAM_LEVEL1
      , CHANNEL
      , MSA
      , SAPCODE
      , MONTH_WEEK
      , BRANCH
      , WEEK_NUMBER
      , BUYING_GROUP2
      , PROGRAM_LEVEL2
      , INVOICE_NO
      , REQUIRED_DATE
      , ORDER_DATE
      , CUSTOMER_KEY
      , CUSTOMER_DESCRIPTION
      , CUSTOMERSALESKEY
      , ITEM_DESC
      , BASE_MATERIAL_DESCRIPTION
      , ITEM_NUMBER_TEMP
      , ITEM_NUMBER2
      , MATERIAL_KEY
      , SHIPPED_QTY
      , GROSS_SALES_BEFORE_FREIGHT
      , FP_FISCAL_YEAR
      , UNIQUE_KEY
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , S_CUSTOMER_NUMBER
    FROM LOGIC_s
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)

, RENAME_x as (
    SELECT
        CUSTOMER_AS_SAP
      , ECLIPSE_ID
    FROM LOGIC_x
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.HOFR_US_SALES'
)

, FILTER_x as (
    SELECT *
    FROM RENAME_x
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_x
        ON s_customer_number = eclipse_id
)

---- FINAL LAYER ----
SELECT
          ITEM_BK
        , INVOICE_BK
        , FISCALDATE_KEY
        , DATASOURCE
        , DATATYPE
        , CUSTOMER_NUMBER
        , CUSTOMER
        , ITEM
        , ITEM_NUMBER1
        , QTY
        , SALES
        , COGS
        , SHPSTATE
        , STATE
        , COMPANY
        , DATE
        , YEAR
        , MONTH
        , FERG_OR_NON_FERG
        , PRODUCT_GROUP
        , BRAND_FORECAST
        , CUSTOMER_FORECAST
        , UNIVERSAL_CUSTOMER_NAME
        , AGENCY
        , AGENCY_TEMP
        , REGION
        , TERRITORY
        , BUYING_GROUP1
        , ORIGINAL_ZIP
        , PROGRAM_LEVEL1
        , CHANNEL
        , MSA
        , SAPCODE
        , MONTH_WEEK
        , BRANCH
        , WEEK_NUMBER
        , BUYING_GROUP2
        , PROGRAM_LEVEL2
        , INVOICE_NO
        , REQUIRED_DATE
        , ORDER_DATE
        , CUSTOMER_KEY
        , CUSTOMER_DESCRIPTION
        , CUSTOMERSALESKEY
        , ITEM_DESC
        , BASE_MATERIAL_DESCRIPTION
        , ITEM_NUMBER_TEMP
        , ITEM_NUMBER2
        , MATERIAL_KEY
        , SHIPPED_QTY
        , GROSS_SALES_BEFORE_FREIGHT
        , FP_FISCAL_YEAR
        , UNIQUE_KEY
        , SPLIT_PART(CUSTOMERSALESKEY, '|', 2)                         as SALES_ORGANIZATION
        , SPLIT_PART(CUSTOMERSALESKEY, '|', 3)                         as DISTRIBUTION_CHANNEL
        , SPLIT_PART(CUSTOMERSALESKEY, '|', 4)                         as DIVISION
        , COALESCE(CUSTOMER_AS_SAP, S_CUSTOMER_NUMBER)                 as SAP_CUSTOMER
        , COALESCE(NULLIF(TRIM(SAP_CUSTOMER),''),'-1')                 as CUSTOMER_BK
        , COALESCE(NULLIF(TRIM(SALES_ORGANIZATION),''),'-1')           as SALES_ORGANIZATION_BK
        , COALESCE(NULLIF(TRIM(DISTRIBUTION_CHANNEL),''),'-1')         as DISTRIBUTION_CHANNEL_BK
        , COALESCE(NULLIF(TRIM(DIVISION),''),'-1')                     as DIVISION_BK
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SALES_ORGANIZATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SALES_ORGANIZATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DISTRIBUTION_CHANNEL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DISTRIBUTION_CHANNEL_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DIVISION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INVOICE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(UNIQUE_KEY as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SALES_ORGANIZATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DISTRIBUTION_CHANNEL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_INVOICE_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SALES_ORGANIZATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DISTRIBUTION_CHANNEL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(FISCALDATE_KEY::text), '^^') 
            , '||', IFNULL(TRIM(DATASOURCE::text), '^^') 
            , '||', IFNULL(TRIM(DATATYPE::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER::text), '^^') 
            , '||', IFNULL(TRIM(ITEM::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_NUMBER1::text), '^^') 
            , '||', IFNULL(TRIM(QTY::text), '^^') 
            , '||', IFNULL(TRIM(SALES::text), '^^') 
            , '||', IFNULL(TRIM(COGS::text), '^^') 
            , '||', IFNULL(TRIM(SHPSTATE::text), '^^') 
            , '||', IFNULL(TRIM(STATE::text), '^^') 
            , '||', IFNULL(TRIM(COMPANY::text), '^^') 
            , '||', IFNULL(TRIM(DATE::text), '^^') 
            , '||', IFNULL(TRIM(YEAR::text), '^^') 
            , '||', IFNULL(TRIM(MONTH::text), '^^') 
            , '||', IFNULL(TRIM(FERG_OR_NON_FERG::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(BRAND_FORECAST::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_FORECAST::text), '^^') 
            , '||', IFNULL(TRIM(UNIVERSAL_CUSTOMER_NAME::text), '^^') 
            , '||', IFNULL(TRIM(AGENCY::text), '^^') 
            , '||', IFNULL(TRIM(AGENCY_TEMP::text), '^^') 
            , '||', IFNULL(TRIM(REGION::text), '^^') 
            , '||', IFNULL(TRIM(TERRITORY::text), '^^') 
            , '||', IFNULL(TRIM(BUYING_GROUP1::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_ZIP::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_LEVEL1::text), '^^') 
            , '||', IFNULL(TRIM(CHANNEL::text), '^^') 
            , '||', IFNULL(TRIM(MSA::text), '^^') 
            , '||', IFNULL(TRIM(SAPCODE::text), '^^') 
            , '||', IFNULL(TRIM(MONTH_WEEK::text), '^^') 
            , '||', IFNULL(TRIM(BRANCH::text), '^^') 
            , '||', IFNULL(TRIM(WEEK_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(BUYING_GROUP2::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_LEVEL2::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_NO::text), '^^') 
            , '||', IFNULL(TRIM(REQUIRED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_KEY::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMERSALESKEY::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_DESC::text), '^^') 
            , '||', IFNULL(TRIM(BASE_MATERIAL_DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_NUMBER_TEMP::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_NUMBER2::text), '^^') 
            , '||', IFNULL(TRIM(MATERIAL_KEY::text), '^^') 
            , '||', IFNULL(TRIM(SHIPPED_QTY::text), '^^') 
            , '||', IFNULL(TRIM(GROSS_SALES_BEFORE_FREIGHT::text), '^^') 
            , '||', IFNULL(TRIM(FP_FISCAL_YEAR::text), '^^') 
            , '||', IFNULL(TRIM(UNIQUE_KEY::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
