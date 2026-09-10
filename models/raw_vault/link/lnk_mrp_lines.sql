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
SRC_b              as ( SELECT    MRP_LINES_LHK
                                , ELEMNT_DATA_HK
                                , ITEM_HK
                                , PLANT_HK
                                , UOM_HK
                                , CUSTOMER_HK
                                , SUPPLIER_HK      
                                , LOAD_DTS
                                , REC_SRC FROM {{ ref('v_psa_stg_mrp_lines__winn_sap') }} as SRC)

/*
SRC_b              as ( SELECT * FROM STAGING.V_PSA_STG_MRP_LINES__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        MRP_LINES_LHK
      , ELEMNT_DATA_HK
      , ITEM_HK
      , PLANT_HK
      , UOM_HK
      , CUSTOMER_HK
      , SUPPLIER_HK      
      , LOAD_DTS
      , REC_SRC
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        MRP_LINES_LHK
      , ELEMNT_DATA_HK
      , ITEM_HK
      , PLANT_HK
      , UOM_HK
      , CUSTOMER_HK
      , SUPPLIER_HK             
      , LOAD_DTS
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
        , ELEMNT_DATA_HK
        , ITEM_HK
        , PLANT_HK
        , UOM_HK
        , CUSTOMER_HK
        , SUPPLIER_HK                 
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT

union all
SELECT 
MD5_BINARY(GR.VALUE) AS MRP_LINES_LHK,
MD5_BINARY(GR.VALUE) AS ELEMNT_DATA_HK,
MD5_BINARY(GR.VALUE) AS ITEM_HK,
MD5_BINARY(GR.VALUE) AS PLANT_HK,
MD5_BINARY(GR.VALUE) AS UOM_HK,
MD5_BINARY(GR.VALUE) AS CUSTOMER_HK,
MD5_BINARY(GR.VALUE) AS SUPPLIER_HK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
