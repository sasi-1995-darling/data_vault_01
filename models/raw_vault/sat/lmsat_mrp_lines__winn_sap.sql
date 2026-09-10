
{{ 
    config(
        materialized='table'
    ) 
}}
/* The MRP table is a daily snapshot containing a very large volume of data, which causes the initial load into the raw vault to be extremely time-consuming and result in performance issues. 
   To address this, we are changing the materialization strategy for this model to a full table refresh.
   This approach is justified because the downstream business vault for MRP lines only requires the most recent data (based on the max glchangetime), 
   eliminating the need to store and process historical data.
*/
---- SRC LAYER ----
WITH
SRC_b              as ( SELECT MRP_LINES_LHK
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
                                , LOAD_DTS
                                , HASHDIFF
                                , REC_SRC FROM {{ ref('v_psa_stg_mrp_lines__winn_sap') }} as SRC                        
                         )

/*
SRC_b              as ( SELECT * FROM STAGING.V_PSA_STG_MRP_LINES__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        MRP_LINES_LHK
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
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        MRP_LINES_LHK
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
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM LOGIC_b
)
---- FILTER LAYER ----

, FILTER_b as (
    SELECT *
    FROM RENAME_b
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_b
)

---- FINAL LAYER ----
SELECT
          MRP_LINES_LHK
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
        , LOAD_DTS
        , HASHDIFF
        , REC_SRC
FROM JOIN_RESULT

union all
SELECT 
MD5_BINARY(GR.VALUE) AS MRP_LINES_LHK,
NULL AS MANDT,
NULL AS PLAN_SCENARIO,
GR.VALUE::text AS MATNR,
GR.VALUE::text AS WERKS,
NULL AS AVAIL_DATE,
GR.VALUE::number AS MRP_ITEM,
NULL AS GLREQUEST,
GR.VALUE::text AS MRP_ELEMENT_IND,
NULL AS PLUS_MINUS,
NULL AS AVAILABLE,
NULL AS FINISH_DATE,
NULL AS MRP_ELEMNT,
NULL AS ELEMNT_DATA,
NULL AS EXCMSGKEY,
NULL AS EXCMESSAGE,
NULL AS RESCHED_DATE,
NULL AS REC_REQD_QTY,
NULL AS AVAIL_QTY1,
NULL AS AVAIL_QTY2,
NULL AS ATP_QTY,
NULL AS PROD_VERSION,
NULL AS PLAN_PLANT2,
NULL AS STORAGE_LOC,
GR.VALUE::text AS VENDOR_NO,
GR.VALUE::text AS CUSTOMER,
GR.VALUE::text AS BASE_UOM,
NULL AS MRP_DATE,
NULL AS MRP_TIME,
NULL AS JOB_DATE,
NULL AS JOB_TIME,
NULL AS STOCK_IN_TRANSIT,
NULL AS PLNGSEGNO,
NULL AS EXCLUDE,
NULL AS EXT_SPPROCTYPE,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLSOURCESYSTEM,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
''::BINARY AS HASHDIFF,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
