---- SRC LAYER ----
WITH
SRC_a as (
    SELECT *, LEFT(GLCHANGETIME, 8) AS gl_change_date 
    FROM {{ source('sap_ecc_prd', 'z_zmrplines_000') }} as SRC 
    WHERE psa_load_dts > CURRENT_DATE() - 4 
    QUALIFY gl_change_date = MAX(gl_change_date) OVER ()
        AND ROW_NUMBER() OVER (
            PARTITION BY MATNR, WERKS, BASE_UOM, CUSTOMER, VENDOR_NO, MRP_ELEMENT_IND, MRP_ITEM, AVAIL_DATE
            ORDER BY GLCHANGETIME DESC, PSA_LOAD_DTS DESC
        ) = 1
),
                        
SRC_bkcc           as ( SELECT distinct * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_zmrplines_000 )
, SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        MATNR                                                        as                                            ITEM_BK
      , WERKS                                                        as                                            PLANT_BK
      , BASE_UOM                                                     as                                            UOM_BK
      , CUSTOMER                                                     as                                            CUSTOMER_BK
      , VENDOR_NO                                                    as                                            SUPPLIER_BK
      , MANDT
      , PLAN_SCENARIO
      , MATNR
      , WERKS
      , AVAIL_DATE
      , MRP_ITEM
      , GLREQUEST
      , MRP_ELEMENT_IND
      , PLUS_MINUS
      , AVAILABLE
      , FINISH_DATE
      , MRP_ELEMNT
      , ELEMNT_DATA
      , EXCMSGKEY
      , EXCMESSAGE
      , RESCHED_DATE
      , REC_REQD_QTY
      , AVAIL_QTY1
      , AVAIL_QTY2
      , ATP_QTY
      , PROD_VERSION
      , PLAN_PLANT2
      , STORAGE_LOC
      , VENDOR_NO
      , CUSTOMER
      , BASE_UOM
      , MRP_DATE
      , MRP_TIME
      , JOB_DATE
      , JOB_TIME
      , STOCK_IN_TRANSIT
      , PLNGSEGNO
      , EXCLUDE
      , EXT_SPPROCTYPE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_a
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        ITEM_BK
      , PLANT_BK
      , UOM_BK
      , CUSTOMER_BK
      , SUPPLIER_BK
      , MANDT
      , PLAN_SCENARIO
      , MATNR
      , WERKS
      , AVAIL_DATE
      , MRP_ITEM
      , GLREQUEST
      , MRP_ELEMENT_IND
      , PLUS_MINUS
      , AVAILABLE
      , FINISH_DATE
      , MRP_ELEMNT
      , ELEMNT_DATA
      , EXCMSGKEY
      , EXCMESSAGE
      , RESCHED_DATE
      , REC_REQD_QTY
      , AVAIL_QTY1
      , AVAIL_QTY2
      , ATP_QTY
      , PROD_VERSION
      , PLAN_PLANT2
      , STORAGE_LOC
      , VENDOR_NO
      , CUSTOMER
      , BASE_UOM
      , MRP_DATE
      , MRP_TIME
      , JOB_DATE
      , JOB_TIME
      , STOCK_IN_TRANSIT
      , PLNGSEGNO
      , EXCLUDE
      , EXT_SPPROCTYPE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_a
)

, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a    
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_ZMRPLINES_000'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          ITEM_BK
        , PLANT_BK
        , UOM_BK
        , CUSTOMER_BK
        , SUPPLIER_BK
        , MANDT
        , PLAN_SCENARIO
        , MATNR
        , WERKS
        , AVAIL_DATE
        , MRP_ITEM
        , GLREQUEST
        , MRP_ELEMENT_IND
        , PLUS_MINUS
        , AVAILABLE
        , FINISH_DATE
        , MRP_ELEMNT
        , ELEMNT_DATA
        , EXCMSGKEY
        , EXCMESSAGE
        , RESCHED_DATE
        , REC_REQD_QTY
        , AVAIL_QTY1
        , AVAIL_QTY2
        , ATP_QTY
        , PROD_VERSION
        , PLAN_PLANT2
        , STORAGE_LOC
        , VENDOR_NO
        , CUSTOMER
        , BASE_UOM
        , MRP_DATE
        , MRP_TIME
        , JOB_DATE
        , JOB_TIME
        , STOCK_IN_TRANSIT
        , PLNGSEGNO
        , EXCLUDE
        , EXT_SPPROCTYPE
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , CONVERT_TIMEZONE('UTC', IFF(
        PSA_DELETE_IND = 'Y', 
        PSA_LOAD_DTS,  
        TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
          )
      )) as LOAD_DTS
        , REC_SRC
        , BKCC
        , TRIM(REGEXP_REPLACE(ELEMNT_DATA, '\\*', '')) AS ELEMNT_DATA_TRIM 
        , CASE
            WHEN MRP_ELEMENT_IND IN ('VC', 'BA', 'BE', 'U2', 'VI') THEN
                REGEXP_SUBSTR(ELEMNT_DATA_TRIM, '([^/]+)', 1, 1) || '||' || REGEXP_SUBSTR(ELEMNT_DATA_TRIM, '[^/]+', 1, 2)
            WHEN MRP_ELEMENT_IND IN ('PA', 'U3', 'FE', 'VJ', 'LA') THEN
                REGEXP_SUBSTR(ELEMNT_DATA_TRIM, '([^/]+)', 1, 1)
            ELSE
                REGEXP_SUBSTR(ELEMNT_DATA_TRIM, '([^/]+)', 1, 1)
          END AS DRVD_ELEMNT_DATA
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(WERKS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BASE_UOM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VENDOR_NO as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(MRP_ELEMENT_IND as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(MRP_ITEM as VARCHAR)),''), '^^')        
        , COALESCE(NULLIF(TRIM(CAST(AVAIL_DATE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as MRP_LINES_LHK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_ELEMNT_DATA as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ELEMNT_DATA_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(WERKS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BASE_UOM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as UOM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_HK                
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VENDOR_NO as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK                             
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(PLAN_SCENARIO::text), '^^') 
            , '||', IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(PLUS_MINUS::text), '^^') 
            , '||', IFNULL(TRIM(AVAILABLE::text), '^^') 
            , '||', IFNULL(TRIM(FINISH_DATE::text), '^^') 
            , '||', IFNULL(TRIM(MRP_ELEMNT::text), '^^') 
            , '||', IFNULL(TRIM(EXCMSGKEY::text), '^^') 
            , '||', IFNULL(TRIM(EXCMESSAGE::text), '^^') 
            , '||', IFNULL(TRIM(RESCHED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REC_REQD_QTY::text), '^^') 
            , '||', IFNULL(TRIM(AVAIL_QTY1::text), '^^') 
            , '||', IFNULL(TRIM(AVAIL_QTY2::text), '^^') 
            , '||', IFNULL(TRIM(ATP_QTY::text), '^^') 
            , '||', IFNULL(TRIM(PROD_VERSION::text), '^^') 
            , '||', IFNULL(TRIM(PLAN_PLANT2::text), '^^') 
            , '||', IFNULL(TRIM(STORAGE_LOC::text), '^^')             
            , '||', IFNULL(TRIM(MRP_DATE::text), '^^') 
            , '||', IFNULL(TRIM(MRP_TIME::text), '^^') 
            , '||', IFNULL(TRIM(JOB_DATE::text), '^^') 
            , '||', IFNULL(TRIM(JOB_TIME::text), '^^') 
            , '||', IFNULL(TRIM(STOCK_IN_TRANSIT::text), '^^') 
            , '||', IFNULL(TRIM(PLNGSEGNO::text), '^^') 
            , '||', IFNULL(TRIM(EXCLUDE::text), '^^') 
            , '||', IFNULL(TRIM(EXT_SPPROCTYPE::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
