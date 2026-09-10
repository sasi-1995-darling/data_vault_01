---- SRC LAYER ----
WITH
SRC_LD             as ( SELECT DELIVERY_HK, DELIVERY_LINE_DETAIL_LHK, ITEM_HK, REC_SRC FROM {{ ref('lnk_delivery_line_item_detail') }} as SRC  ),
SRC_SDL            as ( SELECT BRGEW, DELIVERY_LINE_DETAIL_LHK, GEWEI, LFIMG, LGORT, MATNR, NTGEW, POSNR, VBELN, VOLEH, VOLUM, VRKME, WERKS FROM {{ ref('lsat_delivery_line_detail__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by DELIVERY_LINE_DETAIL_LHK order by LOAD_DTS DESC) ),
SRC_HD             as ( SELECT BKCC, DELIVERY_BK, DELIVERY_HK FROM {{ ref('hub_delivery_v1') }} as SRC  ),
SRC_HI             as ( SELECT ITEM_BK, ITEM_HK FROM {{ ref('hub_item_v1') }} as SRC  ),
SRC_SD             as ( SELECT DELIVERY_HK, KUNNR, LFDAT, PSA_DELETE_IND, VSTEL, WADAT_IST FROM {{ ref('sat_delivery__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by DELIVERY_HK order by LOAD_DTS DESC) ),
SRC_SI             as ( SELECT BRGEW, GEWEI, ITEM_HK, MATKL FROM {{ ref('sat_item_master__moen_sap_v1') }} as SRC 
                        qualify 1= row_number() over(partition by ITEM_HK order by LOAD_DTS DESC) )

/*
SRC_LD             as ( SELECT * FROM RAW_VAULT.LNK_DELIVERY_LINE_ITEM_DETAIL )
SRC_SDL            as ( SELECT * FROM RAW_VAULT.LSAT_DELIVERY_LINE_DETAIL__WINN_SAP )
SRC_HD             as ( SELECT * FROM RAW_VAULT.HUB_DELIVERY_V1 )
SRC_HI             as ( SELECT * FROM RAW_VAULT.HUB_ITEM_V1 )
SRC_SD             as ( SELECT * FROM RAW_VAULT.SAT_DELIVERY__WINN_SAP )
SRC_SI             as ( SELECT * FROM RAW_VAULT.SAT_ITEM_MASTER_MOEN_SAP_V1 )
*/
---- LOGIC LAYER ----

, LOGIC_LD as (
    SELECT
        CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , 'PIT_DELIVERY'                                                 as                                        PIT_REC_SRC
      , REC_SRC
      , DELIVERY_HK
      , ITEM_HK
      , DELIVERY_LINE_DETAIL_LHK
    FROM SRC_LD
)

, LOGIC_SDL as (
    SELECT
        DELIVERY_LINE_DETAIL_LHK                                     as                       SDL_DELIVERY_LINE_DETAIL_LHK
      , VBELN                                                        as                                        DELIVERY_ID
      , POSNR                                                        as                                   DELIVERY_ITEM_ID
      , MATNR                                                        as                                        MATERIAL_ID
      , WERKS                                                        as                                           PLANT_ID
      , LGORT                                                        as                                STORAGE_LOCATION_ID
      , LFIMG                                                        as                                 DELIVERED_QUANTITY
      , VRKME                                                        as                                         SALES_UNIT
      , BRGEW                                                        as                                  ITEM_GROSS_WEIGHT
      , NTGEW                                                        as                                    ITEM_NET_WEIGHT
      , GEWEI                                                        as                                   ITEM_WEIGHT_UNIT
      , VOLUM                                                        as                                        ITEM_VOLUME
      , VOLEH                                                        as                                   ITEM_VOLUME_UNIT
    FROM SRC_SDL
)

, LOGIC_HD as (
    SELECT
        BKCC
      , DELIVERY_BK
      , DELIVERY_HK                                                  as                                     HD_DELIVERY_HK
    FROM SRC_HD
)

, LOGIC_HI as (
    SELECT
        ITEM_HK                                                      as                                         HI_ITEM_HK
      , ITEM_BK
    FROM SRC_HI
)

, LOGIC_SD as (
    SELECT
        DELIVERY_HK                                                  as                                     SD_DELIVERY_HK
      , KUNNR                                                        as                                SHIP_TO_CUSTOMER_ID
      , VSTEL                                                        as                                  SHIPPING_POINT_ID
      , LFDAT                                                        as                    PLANNED_DELIVERY_DATE__YYYYMMDD
      , WADAT_IST                                                    as                  ACTUAL_GOODS_ISSUE_DATE__YYYYMMDD
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
    FROM SRC_SD
)

, LOGIC_SI as (
    SELECT
        ITEM_HK                                                      as                                         SI_ITEM_HK
      , MATKL                                                        as                                  MATERIAL_GROUP_ID
      , BRGEW                                                        as                           MASTER_DATA_GROSS_WEIGHT
      , GEWEI                                                        as                            MASTER_DATA_WEIGHT_UNIT
    FROM SRC_SI
)
---- RENAME LAYER ----

, RENAME_LD as (
    SELECT
        PIT_LOAD_DTS
      , PIT_REC_SRC
      , REC_SRC
      , DELIVERY_HK
      , ITEM_HK
      , DELIVERY_LINE_DETAIL_LHK
    FROM LOGIC_LD
)

, RENAME_HD as (
    SELECT
        BKCC
      , DELIVERY_BK
      , HD_DELIVERY_HK
    FROM LOGIC_HD
)

, RENAME_HI as (
    SELECT
        HI_ITEM_HK
      , ITEM_BK
    FROM LOGIC_HI
)

, RENAME_SDL as (
    SELECT
        SDL_DELIVERY_LINE_DETAIL_LHK
      , DELIVERY_ID
      , DELIVERY_ITEM_ID
      , MATERIAL_ID
      , PLANT_ID
      , STORAGE_LOCATION_ID
      , DELIVERED_QUANTITY
      , SALES_UNIT
      , ITEM_GROSS_WEIGHT
      , ITEM_NET_WEIGHT
      , ITEM_WEIGHT_UNIT
      , ITEM_VOLUME
      , ITEM_VOLUME_UNIT
    FROM LOGIC_SDL
)

, RENAME_SD as (
    SELECT
        SD_DELIVERY_HK
      , SHIP_TO_CUSTOMER_ID
      , SHIPPING_POINT_ID
      , PLANNED_DELIVERY_DATE__YYYYMMDD
      , ACTUAL_GOODS_ISSUE_DATE__YYYYMMDD
      , SAT_WINN_PSA_DELETE_IND
    FROM LOGIC_SD
)

, RENAME_SI as (
    SELECT
        SI_ITEM_HK
      , MATERIAL_GROUP_ID
      , MASTER_DATA_GROSS_WEIGHT
      , MASTER_DATA_WEIGHT_UNIT
    FROM LOGIC_SI
)
---- FILTER LAYER ----

, FILTER_LD as (
    SELECT *
    FROM RENAME_LD
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'
)

, FILTER_SDL as (
    SELECT *
    FROM RENAME_SDL
)

, FILTER_HD as (
    SELECT *
    FROM RENAME_HD
)

, FILTER_HI as (
    SELECT *
    FROM RENAME_HI
)

, FILTER_SD as (
    SELECT *
    FROM RENAME_SD
)

, FILTER_SI as (
    SELECT *
    FROM RENAME_SI
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LD
    INNER JOIN FILTER_SDL
        ON FILTER_LD.DELIVERY_LINE_DETAIL_LHK = FILTER_SDL.SDL_DELIVERY_LINE_DETAIL_LHK
    LEFT JOIN FILTER_HD
        ON FILTER_LD.DELIVERY_HK = FILTER_HD.HD_DELIVERY_HK
    LEFT JOIN FILTER_HI
        ON FILTER_LD.ITEM_HK = FILTER_HI.HI_ITEM_HK
    LEFT JOIN FILTER_SD
        ON FILTER_HD.HD_DELIVERY_HK = FILTER_SD.SD_DELIVERY_HK
    LEFT JOIN FILTER_SI
        ON FILTER_HI.HI_ITEM_HK = FILTER_SI.SI_ITEM_HK
)

---- FINAL LAYER ----
SELECT
          row_number() over(order by 1)                                as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , PIT_LOAD_DTS
        , BKCC
        , PIT_REC_SRC
        , REC_SRC
        , DELIVERY_HK
        , ITEM_HK
        , DELIVERY_LINE_DETAIL_LHK
        , DELIVERY_BK
        , ITEM_BK
        , DELIVERY_ID
        , DELIVERY_ITEM_ID
        , SHIP_TO_CUSTOMER_ID
        , SHIPPING_POINT_ID
        , MATERIAL_ID
        , PLANT_ID
        , STORAGE_LOCATION_ID
        , MATERIAL_GROUP_ID
        , PLANNED_DELIVERY_DATE__YYYYMMDD
        , ACTUAL_GOODS_ISSUE_DATE__YYYYMMDD
        , DELIVERED_QUANTITY
        , SALES_UNIT
        , ITEM_GROSS_WEIGHT
        , ITEM_NET_WEIGHT
        , ITEM_WEIGHT_UNIT
        , ITEM_VOLUME
        , ITEM_VOLUME_UNIT
        , MASTER_DATA_GROSS_WEIGHT
        , MASTER_DATA_WEIGHT_UNIT
        , SAT_WINN_PSA_DELETE_IND
FROM JOIN_RESULT
