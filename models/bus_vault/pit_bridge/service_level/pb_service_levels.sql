---- SRC LAYER ----
WITH
SRC_lnksvls        as ( SELECT CUSTOMER_HK, DISTRIBUTION_CHANNEL_HK, DIVISION_HK, GOODS_STORAGE_LOCATION_HK, ITEM_HK, LNK_SERVICE_LEVELS_HK, 
                        ORDER_HEADER_HK, ORDER_LINE_HK, PLANT_HK, REC_SRC, SALES_ORGANIZATION_HK FROM {{ ref('lnk_service_levels') }} as SRC  ),
SRC_hbodh          as ( SELECT BKCC, ORDER_HEADER_BK, ORDER_HEADER_HK FROM {{ ref('hub_order_header') }} as SRC  ),
SRC_hbodl          as ( SELECT ORDER_LINE_BK, ORDER_LINE_HK FROM {{ ref('hub_order_line') }} as SRC  ),
SRC_hbcust         as ( SELECT CUSTOMER_BK, CUSTOMER_HK FROM {{ ref('hub_customer_v1') }} as SRC  ),
SRC_hbslo          as ( SELECT SALES_ORGANIZATION_BK, SALES_ORGANIZATION_HK FROM {{ ref('hub_sales_organization') }} as SRC  ),
SRC_hbdist         as ( SELECT DISTRIBUTION_CHANNEL_BK, DISTRIBUTION_CHANNEL_HK FROM {{ ref('hub_distribution_channel') }} as SRC  ),
SRC_hbdiv          as ( SELECT DIVISION_BK, DIVISION_HK FROM {{ ref('hub_division') }} as SRC  ),
SRC_hbitm          as ( SELECT ITEM_BK, ITEM_HK FROM {{ ref('hub_item_v1') }} as SRC  ),
SRC_hbplt          as ( SELECT PLANT_BK, PLANT_HK FROM {{ ref('hub_plant_v1') }} as SRC  ),
SRC_hbstrg         as ( SELECT GOODS_STORAGE_LOCATION_BK, GOODS_STORAGE_LOCATION_HK FROM {{ ref('hub_storage_location') }} as SRC  ),
SRC_lnkcsdcd       as ( SELECT CUSTOMER_HK, DISTRIBUTION_CHANNEL_HK, DIVISION_HK, LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK, 
                        SALES_ORGANIZATION_HK FROM {{ ref('lnk_customer_sales_organization_distribution_channel_division') }} as SRC  ),
SRC_lnkpltitm      as ( SELECT ITEM_HK, PLANT_HK, PLANT_ITEM_HK FROM {{ ref('link_plant_item_v1') }} as SRC  ),
SRC_lsatsvls       as ( SELECT ERDAT_DT, KODAT_IST_DT, KUNNR, KWMENG, LFIMG, LGORT, LNK_SERVICE_LEVELS_HK, MATNR, MEINS, NETPR, ORDEVALDT_DT, 
                        PERFECTORDER, POSNR, PSTYV, SPART, VBELN, VKORG, VTWEG, WADAT_DT, WADAT_IST_DT, WERKS, ZLINEFILL, ZONTIME, ZRELEASED, 
                        ZSERVCODE, ZSERVTYPE, ZZGRACE FROM {{ ref('lsat_service_levels__winn_sap') }} as SRC 
                        qualify 1 = row_number() over (partition by lnk_service_levels_hk order by load_dts desc) )

/*
SRC_lnksvls        as ( SELECT * FROM raw_vault.lnk_service_levels )
SRC_hbodh          as ( SELECT * FROM raw_vault.hub_order_header )
SRC_hbodl          as ( SELECT * FROM raw_vault.hub_order_line )
SRC_hbcust         as ( SELECT * FROM raw_vault.hub_customer_v1 )
SRC_hbslo          as ( SELECT * FROM raw_vault.hub_sales_organization )
SRC_hbdist         as ( SELECT * FROM raw_vault.hub_distribution_channel )
SRC_hbdiv          as ( SELECT * FROM raw_vault.hub_division )
SRC_hbitm          as ( SELECT * FROM raw_vault.hub_item_v1 )
SRC_hbplt          as ( SELECT * FROM raw_vault.hub_plant_v1 )
SRC_hbstrg         as ( SELECT * FROM raw_vault.hub_storage_location )
SRC_lnkcsdcd       as ( SELECT * FROM raw_vault.lnk_customer_sales_organization_distribution_channel_division )
SRC_lnkpltitm      as ( SELECT * FROM raw_vault.link_plant_item_v1 )
SRC_lsatsvls       as ( SELECT * FROM raw_vault.lsat_service_levels__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_lnksvls as (
    SELECT
        LNK_SERVICE_LEVELS_HK                                        as                                 SERVICE_LEVELS_KEY
      , ORDER_HEADER_HK
      , ORDER_LINE_HK
      , CUSTOMER_HK
      , SALES_ORGANIZATION_HK
      , DISTRIBUTION_CHANNEL_HK
      , DIVISION_HK
      , ITEM_HK
      , PLANT_HK
      , GOODS_STORAGE_LOCATION_HK
      , REC_SRC
      , LNK_SERVICE_LEVELS_HK
    FROM SRC_lnksvls
)

, LOGIC_hbodh as (
    SELECT
        ORDER_HEADER_BK
      , BKCC
      , ORDER_HEADER_HK                                              as                              HBODH_ORDER_HEADER_HK
    FROM SRC_hbodh
)

, LOGIC_hbodl as (
    SELECT
        ORDER_LINE_BK
      , ORDER_LINE_HK                                                as                                HBODL_ORDER_LINE_HK
    FROM SRC_hbodl
)

, LOGIC_hbcust as (
    SELECT
        CUSTOMER_BK
      , CUSTOMER_HK                                                  as                                 HBCUST_CUSTOMER_HK
    FROM SRC_hbcust
)

, LOGIC_hbslo as (
    SELECT
        SALES_ORGANIZATION_BK
      , SALES_ORGANIZATION_HK                                        as                        HBSLO_SALES_ORGANIZATION_HK
    FROM SRC_hbslo
)

, LOGIC_hbdist as (
    SELECT
        DISTRIBUTION_CHANNEL_BK
      , DISTRIBUTION_CHANNEL_HK                                      as                     HBDIST_DISTRIBUTION_CHANNEL_HK
    FROM SRC_hbdist
)

, LOGIC_hbdiv as (
    SELECT
        DIVISION_BK
      , DIVISION_HK                                                  as                                  HBDIV_DIVISION_HK
    FROM SRC_hbdiv
)

, LOGIC_hbitm as (
    SELECT
        ITEM_BK
      , ITEM_HK                                                      as                                      HBITM_ITEM_HK
    FROM SRC_hbitm
)

, LOGIC_hbplt as (
    SELECT
        PLANT_BK
      , PLANT_HK                                                     as                                     HBPLT_PLANT_HK
    FROM SRC_hbplt
)

, LOGIC_hbstrg as (
    SELECT
        GOODS_STORAGE_LOCATION_BK
      , GOODS_STORAGE_LOCATION_HK                                    as                   HBSTRG_GOODS_STORAGE_LOCATION_HK
    FROM SRC_hbstrg
)

, LOGIC_lnkcsdcd as (
    SELECT
        LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK as                      CUSTOMER_SALES_ATTRIBUTES_KEY
      , CUSTOMER_HK                                                  as                               LNKCSDCD_CUSTOMER_HK
      , SALES_ORGANIZATION_HK                                        as                     LNKCSDCD_SALES_ORGANIZATION_HK
      , DISTRIBUTION_CHANNEL_HK                                      as                   LNKCSDCD_DISTRIBUTION_CHANNEL_HK
      , DIVISION_HK                                                  as                               LNKCSDCD_DIVISION_HK
    FROM SRC_lnkcsdcd
)

, LOGIC_lnkpltitm as (
    SELECT
        PLANT_ITEM_HK                                                as                                 ITEMS_BY_PLANT_KEY
      , ITEM_HK                                                      as                                  LNKPLTITM_ITEM_HK
      , PLANT_HK                                                     as                                 LNKPLTITM_PLANT_HK
    FROM SRC_lnkpltitm
)

, LOGIC_lsatsvls as (
    SELECT
        ZSERVCODE                                                    as                                 SERVICE_LEVEL_CODE
      , ZSERVTYPE                                                    as                              SERVICE_LEVEL_TYPE_ID
      , VBELN                                                        as                                     SALES_DOCUMENT
      , POSNR                                                        as                         SALES_DOCUMENT_LINE_NUMBER
      , KUNNR                                                        as                                SOLD_TO_CUSTOMER_ID
      , MATNR                                                        as                                        ITEM_NUMBER
      , WERKS                                                        as                                              PLANT
      , LGORT                                                        as                             GOODS_STORAGE_LOCATION
      , VKORG                                                        as                                 SALES_ORGANIZATION
      , VTWEG                                                        as                               DISTRIBUTION_CHANNEL
      , SPART                                                        as                                           DIVISION
      , NETPR                                                        as                                          NET_PRICE
      , PSTYV                                                        as                       SALES_DOCUMENT_LINE_CATEGORY
      , KWMENG                                                       as                               CUMULATIVE_ORDER_QTY
      , LFIMG                                                        as                                      DELIVERED_QTY
      , ZZGRACE                                                      as                             NUMBER_OF_WORKING_DAYS
      , ZONTIME                                                      as                             LINE_ON_TIME_INDICATOR
      , ZLINEFILL                                                    as                              LINE_FILLED_INDICATOR
      , ZRELEASED                                                    as                    SERVICE_LINE_RELEASED_INDICATOR
      , MEINS                                                        as                                     SALES_BASE_UOM
      , PERFECTORDER                                                 as                            PERFECT_ORDER_INDICATOR
      , ERDAT_DT                                                     as                                  LSATSVLS_ERDAT_DT
      , WADAT_DT                                                     as                                  LSATSVLS_WADAT_DT
      , WADAT_IST_DT                                                 as                              LSATSVLS_WADAT_IST_DT
      , ORDEVALDT_DT                                                 as                              LSATSVLS_ORDEVALDT_DT
      , KODAT_IST_DT                                                 as                              LSATSVLS_KODAT_IST_DT
      , LNK_SERVICE_LEVELS_HK                                        as                     LSATSVLS_LNK_SERVICE_LEVELS_HK
    FROM SRC_lsatsvls
)
---- RENAME LAYER ----

, RENAME_lnksvls as (
    SELECT
        SERVICE_LEVELS_KEY
      , ORDER_HEADER_HK
      , ORDER_LINE_HK
      , CUSTOMER_HK
      , SALES_ORGANIZATION_HK
      , DISTRIBUTION_CHANNEL_HK
      , DIVISION_HK
      , ITEM_HK
      , PLANT_HK
      , GOODS_STORAGE_LOCATION_HK
      , REC_SRC
      , LNK_SERVICE_LEVELS_HK
    FROM LOGIC_lnksvls
)

, RENAME_hbodh as (
    SELECT
        ORDER_HEADER_BK
      , BKCC
      , HBODH_ORDER_HEADER_HK
    FROM LOGIC_hbodh
)

, RENAME_hbodl as (
    SELECT
        ORDER_LINE_BK
      , HBODL_ORDER_LINE_HK
    FROM LOGIC_hbodl
)

, RENAME_lnkcsdcd as (
    SELECT
        CUSTOMER_SALES_ATTRIBUTES_KEY
      , LNKCSDCD_CUSTOMER_HK
      , LNKCSDCD_SALES_ORGANIZATION_HK
      , LNKCSDCD_DISTRIBUTION_CHANNEL_HK
      , LNKCSDCD_DIVISION_HK
    FROM LOGIC_lnkcsdcd
)

, RENAME_hbcust as (
    SELECT
        CUSTOMER_BK
      , HBCUST_CUSTOMER_HK
    FROM LOGIC_hbcust
)

, RENAME_hbslo as (
    SELECT
        SALES_ORGANIZATION_BK
      , HBSLO_SALES_ORGANIZATION_HK
    FROM LOGIC_hbslo
)

, RENAME_hbdist as (
    SELECT
        DISTRIBUTION_CHANNEL_BK
      , HBDIST_DISTRIBUTION_CHANNEL_HK
    FROM LOGIC_hbdist
)

, RENAME_hbdiv as (
    SELECT
        DIVISION_BK
      , HBDIV_DIVISION_HK
    FROM LOGIC_hbdiv
)

, RENAME_lnkpltitm as (
    SELECT
        ITEMS_BY_PLANT_KEY
      , LNKPLTITM_ITEM_HK
      , LNKPLTITM_PLANT_HK
    FROM LOGIC_lnkpltitm
)

, RENAME_hbitm as (
    SELECT
        ITEM_BK
      , HBITM_ITEM_HK
    FROM LOGIC_hbitm
)

, RENAME_hbplt as (
    SELECT
        PLANT_BK
      , HBPLT_PLANT_HK
    FROM LOGIC_hbplt
)

, RENAME_hbstrg as (
    SELECT
        GOODS_STORAGE_LOCATION_BK
      , HBSTRG_GOODS_STORAGE_LOCATION_HK
    FROM LOGIC_hbstrg
)

, RENAME_lsatsvls as (
    SELECT
        SERVICE_LEVEL_CODE
      , SERVICE_LEVEL_TYPE_ID
      , SALES_DOCUMENT
      , SALES_DOCUMENT_LINE_NUMBER
      , SOLD_TO_CUSTOMER_ID
      , ITEM_NUMBER
      , PLANT
      , GOODS_STORAGE_LOCATION
      , SALES_ORGANIZATION
      , DISTRIBUTION_CHANNEL
      , DIVISION
      , NET_PRICE
      , SALES_DOCUMENT_LINE_CATEGORY
      , CUMULATIVE_ORDER_QTY
      , DELIVERED_QTY
      , NUMBER_OF_WORKING_DAYS
      , LINE_ON_TIME_INDICATOR
      , LINE_FILLED_INDICATOR
      , SERVICE_LINE_RELEASED_INDICATOR
      , SALES_BASE_UOM
      , PERFECT_ORDER_INDICATOR
      , LSATSVLS_ERDAT_DT
      , LSATSVLS_WADAT_DT
      , LSATSVLS_WADAT_IST_DT
      , LSATSVLS_ORDEVALDT_DT
      , LSATSVLS_KODAT_IST_DT
      , LSATSVLS_LNK_SERVICE_LEVELS_HK
    FROM LOGIC_lsatsvls
)
---- FILTER LAYER ----

, FILTER_lnksvls as (
    SELECT *
    FROM RENAME_lnksvls
)

, FILTER_hbodh as (
    SELECT *
    FROM RENAME_hbodh
)

, FILTER_hbodl as (
    SELECT *
    FROM RENAME_hbodl
)

, FILTER_hbcust as (
    SELECT *
    FROM RENAME_hbcust
)

, FILTER_hbslo as (
    SELECT *
    FROM RENAME_hbslo
)

, FILTER_hbdist as (
    SELECT *
    FROM RENAME_hbdist
)

, FILTER_hbdiv as (
    SELECT *
    FROM RENAME_hbdiv
)

, FILTER_hbitm as (
    SELECT *
    FROM RENAME_hbitm
)

, FILTER_hbplt as (
    SELECT *
    FROM RENAME_hbplt
)

, FILTER_hbstrg as (
    SELECT *
    FROM RENAME_hbstrg
)

, FILTER_lnkcsdcd as (
    SELECT *
    FROM RENAME_lnkcsdcd
)

, FILTER_lnkpltitm as (
    SELECT *
    FROM RENAME_lnkpltitm
)

, FILTER_lsatsvls as (
    SELECT *
    FROM RENAME_lsatsvls
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_lnksvls
    INNER JOIN FILTER_hbodh
        ON ORDER_HEADER_HK = HBODH_ORDER_HEADER_HK
    INNER JOIN FILTER_hbodl
        ON ORDER_LINE_HK = HBODL_ORDER_LINE_HK
    INNER JOIN FILTER_hbcust
        ON CUSTOMER_HK = HBCUST_CUSTOMER_HK
    INNER JOIN FILTER_hbslo
        ON SALES_ORGANIZATION_HK = HBSLO_SALES_ORGANIZATION_HK
    INNER JOIN FILTER_hbdist
        ON DISTRIBUTION_CHANNEL_HK = HBDIST_DISTRIBUTION_CHANNEL_HK
    INNER JOIN FILTER_hbdiv
        ON DIVISION_HK = HBDIV_DIVISION_HK
    INNER JOIN FILTER_hbitm
        ON ITEM_HK = HBITM_ITEM_HK
    INNER JOIN FILTER_hbplt
        ON PLANT_HK = HBPLT_PLANT_HK
    INNER JOIN FILTER_hbstrg
        ON GOODS_STORAGE_LOCATION_HK = HBSTRG_GOODS_STORAGE_LOCATION_HK
    LEFT JOIN FILTER_lnkcsdcd
        ON HBCUST_CUSTOMER_HK = LNKCSDCD_CUSTOMER_HK
AND HBSLO_SALES_ORGANIZATION_HK = LNKCSDCD_SALES_ORGANIZATION_HK
AND HBDIST_DISTRIBUTION_CHANNEL_HK = LNKCSDCD_DISTRIBUTION_CHANNEL_HK
AND HBDIV_DIVISION_HK = LNKCSDCD_DIVISION_HK
    LEFT JOIN FILTER_lnkpltitm
        ON HBITM_ITEM_HK = LNKPLTITM_ITEM_HK
AND HBPLT_PLANT_HK = LNKPLTITM_PLANT_HK
    LEFT JOIN FILTER_lsatsvls
        ON LNK_SERVICE_LEVELS_HK = LSATSVLS_LNK_SERVICE_LEVELS_HK
)

---- FINAL LAYER ----
SELECT
          RANDOM()                                                     as SEQ_ID
        ,  'PB_SERVICE_LEVELS'                                         as PB_REC_SRC
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PB_LOAD_DTS
        , SERVICE_LEVELS_KEY
        , ORDER_HEADER_HK
        , ORDER_HEADER_BK
        , ORDER_LINE_HK
        , ORDER_LINE_BK
        , CUSTOMER_SALES_ATTRIBUTES_KEY
        , CUSTOMER_HK
        , CUSTOMER_BK
        , SALES_ORGANIZATION_HK
        , SALES_ORGANIZATION_BK
        , DISTRIBUTION_CHANNEL_HK
        , DISTRIBUTION_CHANNEL_BK
        , DIVISION_HK
        , DIVISION_BK
        , ITEMS_BY_PLANT_KEY
        , ITEM_HK
        , ITEM_BK
        , PLANT_HK
        , PLANT_BK
        , GOODS_STORAGE_LOCATION_HK
        , GOODS_STORAGE_LOCATION_BK
        , TO_VARCHAR(LSATSVLS_ERDAT_DT, 'YYYYMMDD')::INTEGER           as FISCAL_DATEKEY
        , SERVICE_LEVEL_CODE
        , CASE
        WHEN SERVICE_LEVEL_CODE = 'O' THEN 'ON TIME'
        WHEN SERVICE_LEVEL_CODE = 'S' THEN 'SHIPPED'
        WHEN SERVICE_LEVEL_CODE = 'P' THEN 'PROMISED'
 END as SERVICE_LEVEL_DESCRIPTION
        , SERVICE_LEVEL_TYPE_ID
        , SALES_DOCUMENT
        , SALES_DOCUMENT_LINE_NUMBER
        , TO_VARCHAR(LSATSVLS_ERDAT_DT, 'YYYYMMDD')::INTEGER           as RECORD_CREATION_DATE__YYYYMMDD
        , TO_VARCHAR(LSATSVLS_WADAT_DT, 'YYYYMMDD')::INTEGER           as GOODS_ISSUE_DATE__YYYYMMDD
        , TO_VARCHAR(LSATSVLS_WADAT_IST_DT, 'YYYYMMDD')::INTEGER       as ACTUAL_GOODS_MOVEMENT_DATE__YYYYMMDD
        , TO_VARCHAR(LSATSVLS_ORDEVALDT_DT, 'YYYYMMDD')::INTEGER       as ORDER_EVALUATION_DATE__YYYYMMDD
        , TO_VARCHAR(LSATSVLS_KODAT_IST_DT, 'YYYYMMDD')::INTEGER       as ACTUAL_PICK_COMPLETION_DATE__YYYYMMDD
        , SOLD_TO_CUSTOMER_ID
        , ITEM_NUMBER
        , PLANT
        , GOODS_STORAGE_LOCATION
        , SALES_ORGANIZATION
        , DISTRIBUTION_CHANNEL
        , DIVISION
        , NET_PRICE
        , SALES_DOCUMENT_LINE_CATEGORY
        , CUMULATIVE_ORDER_QTY
        , DELIVERED_QTY
        , NUMBER_OF_WORKING_DAYS
        , LINE_ON_TIME_INDICATOR
        , CASE
        WHEN LINE_ON_TIME_INDICATOR = 1 THEN 'Y'
        ELSE 'N'
 END as LINE_ON_TIME_FLAG
        , LINE_FILLED_INDICATOR
        , CASE
        WHEN LINE_FILLED_INDICATOR = 1 THEN 'Y'
        ELSE 'N'
 END as LINE_FILLED_FLAG
        , SERVICE_LINE_RELEASED_INDICATOR
        , CASE
        WHEN SERVICE_LINE_RELEASED_INDICATOR = '1' THEN 'Y'
        ELSE 'N'
 END as SERVICE_LINE_RELEASED_FLAG
        , CASE
        WHEN (CUMULATIVE_ORDER_QTY - DELIVERED_QTY) > 0 then 'N'
        else 'Y'
 end as LINE_QUANTITY_WAS_COMPLETELY_FILLED_FLAG
        , SALES_BASE_UOM
        , PERFECT_ORDER_INDICATOR
        , CASE
        WHEN PERFECT_ORDER_INDICATOR = '1' THEN 'Y'
        ELSE 'N'
 END as PERFECT_ORDER_FLAG
        , CASE
        WHEN DISTRIBUTION_CHANNEL = 'WH' THEN 0.94
        WHEN DISTRIBUTION_CHANNEL = 'RT' THEN 0.98
        WHEN DISTRIBUTION_CHANNEL = 'EC' THEN 0.94
        WHEN DISTRIBUTION_CHANNEL = 'DR' THEN 0.94
 END as DISTRIBUTION_CHANNEL_SERVICE_TARGET
        , CASE
    WHEN SERVICE_LEVEL_CODE = 'O' THEN CUMULATIVE_ORDER_QTY
    ELSE 0
END as ORDERED_ON_TIME_QTY
        , CASE 
    WHEN SERVICE_LEVEL_CODE = 'O' THEN DELIVERED_QTY
    ELSE 0
END as FILLED_ON_TIME_QTY
        , CASE
    WHEN SERVICE_LEVEL_CODE = 'O' THEN CUMULATIVE_ORDER_QTY - DELIVERED_QTY
    ELSE 0
END as MISSED_ON_TIME_QTY
        , CASE
    WHEN SERVICE_LEVEL_CODE = 'S' THEN CUMULATIVE_ORDER_QTY
    ELSE 0
END as ORDERED_QTY
        , CASE
    WHEN SERVICE_LEVEL_CODE = 'S' THEN DELIVERED_QTY
    ELSE 0
END as SHIPPED_QTY
        , CASE
    WHEN SERVICE_LEVEL_CODE = 'S' THEN CUMULATIVE_ORDER_QTY - DELIVERED_QTY
    ELSE 0
END as MISSED_QTY
        , CASE
    WHEN SERVICE_LEVEL_CODE = 'P' THEN CUMULATIVE_ORDER_QTY
    ELSE 0
END as PROMISED_ORDER_ON_TIME_QTY
        , CASE 
    WHEN SERVICE_LEVEL_CODE = 'P' THEN DELIVERED_QTY
    ELSE 0
END as PROMISED_DELIVERY_ON_TIME_QTY
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
/*Filter condition logic from legacy service levels Qlik reporting load script*/
where item_bk <> 'IST900'