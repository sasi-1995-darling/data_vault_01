---- SRC LAYER ----
WITH
SRC_hub_inv        as ( SELECT BKCC,GOODS_STORAGE_LOCATION_BK, GOODS_STORAGE_LOCATION_HK, REC_SRC FROM {{ ref('hub_storage_location') }} as SRC  ),
SRC_sat_inv        as ( SELECT GOODS_STORAGE_LOCATION_HK, DISKZ, LGOBE,  PSA_DELETE_IND FROM {{ ref('sat_storage_location__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by GOODS_STORAGE_LOCATION_HK order by load_dts DESC) )

/*
SRC_hub_inv        as ( SELECT * FROM RAW_VAULT.hub_storage_location ),
SRC_sat_inv        as ( SELECT * FROM RAW_VAULT.sat_storage_location__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_hub_inv as (
    SELECT
      'PIT_STORAGE_LOCATION'                                   as                                  PIT_REC_SRC
      , CURRENT_DATE                                                 as                           SNAPSHOT_DTS
      , GOODS_STORAGE_LOCATION_HK
      , GOODS_STORAGE_LOCATION_BK
      , BKCC
      , REC_SRC
    FROM SRC_hub_inv
)

, LOGIC_sat_inv as (
    SELECT
        GOODS_STORAGE_LOCATION_HK                                 as                sat_inv_GOODS_STORAGE_LOCATION_HK
      , LGOBE                                                        as                  STORAGE_LOCATION_DESCRIPTION_TEXT
      , DISKZ                                                        as                STORAGE_LOCATION_MRP_INDICATOR_CODE
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
    FROM SRC_sat_inv
)
---- RENAME LAYER ----

, RENAME_hub_inv as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOT_DTS
      , GOODS_STORAGE_LOCATION_HK
      , GOODS_STORAGE_LOCATION_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_hub_inv
)

, RENAME_sat_inv as (
    SELECT
       sat_inv_GOODS_STORAGE_LOCATION_HK
      ,STORAGE_LOCATION_DESCRIPTION_TEXT
      ,STORAGE_LOCATION_MRP_INDICATOR_CODE
      ,SAT_WINN_PSA_DELETE_IND
    FROM LOGIC_sat_inv
)
---- FILTER LAYER ----

, FILTER_hub_inv as (
    SELECT *
    FROM RENAME_hub_inv
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED' /* This filter is to exclude the ghost records */
)

, FILTER_sat_inv as (
    SELECT *
    FROM RENAME_sat_inv
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_hub_inv
    INNER JOIN FILTER_sat_inv
        ON FILTER_hub_inv.GOODS_STORAGE_LOCATION_HK = sat_inv_GOODS_STORAGE_LOCATION_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOT_DTS
        , GOODS_STORAGE_LOCATION_HK
        , GOODS_STORAGE_LOCATION_BK
        , BKCC
        , REC_SRC
        , STORAGE_LOCATION_DESCRIPTION_TEXT
        , STORAGE_LOCATION_MRP_INDICATOR_CODE
        , CASE  WHEN BKCC = 'Hiding_Tiger' THEN SAT_WINN_PSA_DELETE_IND
           END as IS_DELETED
FROM JOIN_RESULT