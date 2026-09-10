---- SRC LAYER ----
WITH
SRC_lnk_inv        as ( SELECT CUSTOMER_HK, DISTRIBUTION_CHANNEL_HK, DIVISION_HK, INVOICE_HK, INVOICE_LINE_HK, INVOICE_LINE_PACING_LHK, ITEM_HK, PLANT_HK, REC_SRC, SALES_ORGANIZATION_HK FROM {{ ref('lnk_invoice_line_pacing') }} as SRC  ),
SRC_sat_inv        as ( SELECT FKIMG, INVOICE_LINE_HK, MWSBP, NETWR FROM {{ ref('sat_invoice_line__winn_sap') }} as SRC 
                    qualify 1= row_number() over(partition by INVOICE_LINE_HK order by LOAD_DTS DESC)),
SRC_sat_inh        as ( SELECT FKDAT, INVOICE_HK FROM {{ ref('sat_invoice_header__winn_sap') }} as SRC 
                    qualify 1= row_number() over(partition by INVOICE_HK order by LOAD_DTS DESC)),
SRC_hub_item       as ( SELECT ITEM_BK, ITEM_HK, BKCC FROM {{ ref('hub_item_v1') }} as SRC  ),
SRC_hub_cust       as ( SELECT CUSTOMER_BK, CUSTOMER_HK FROM {{ ref('hub_customer_v1') }} as SRC  ),
SRC_hub_pl         as ( SELECT PLANT_BK, PLANT_HK FROM {{ ref('hub_plant_v1') }} as SRC  ),
SRC_hub_d          as ( SELECT DIVISION_BK, DIVISION_HK FROM {{ ref('hub_division') }} as SRC  ),
SRC_hub_so         as ( SELECT SALES_ORGANIZATION_BK, SALES_ORGANIZATION_HK FROM {{ ref('hub_sales_organization') }} as SRC  ),
SRC_hub_dc         as ( SELECT DISTRIBUTION_CHANNEL_BK, DISTRIBUTION_CHANNEL_HK FROM {{ ref('hub_distribution_channel') }} as SRC  ),
SRC_hub_ih         as ( SELECT INVOICE_BK, INVOICE_HK FROM {{ ref('hub_invoice_header') }} as SRC  ),
SRC_hub_il         as ( SELECT INVOICE_LINE_BK, INVOICE_LINE_HK FROM {{ ref('hub_invoice_line_v1') }} as SRC  )

/*
SRC_lnk_inv        as ( SELECT * FROM RAW_VAULT.lnk_invoice_line_pacing )
SRC_sat_inv        as ( SELECT * FROM RAW_VAULT.sat_invoice_line__winn_sap )
SRC_sat_inh        as ( SELECT * FROM RAW_VAULT.sat_invoice_header__winn_sap )
SRC_hub_item       as ( SELECT * FROM RAW_VAULT.hub_item_v1 )
SRC_hub_cust       as ( SELECT * FROM RAW_VAULT.hub_customer_v1 )
SRC_hub_pl         as ( SELECT * FROM RAW_VAULT.hub_plant_v1 )
SRC_hub_d          as ( SELECT * FROM RAW_VAULT.hub_division )
SRC_hub_so         as ( SELECT * FROM RAW_VAULT.hub_sales_organization )
SRC_hub_dc         as ( SELECT * FROM RAW_VAULT.hub_distribution_channel )
SRC_hub_ih         as ( SELECT * FROM RAW_VAULT.hub_invoice_header )
SRC_hub_il         as ( SELECT * FROM RAW_VAULT.hub_invoice_line_v1 )
*/
---- LOGIC LAYER ----

, LOGIC_lnk_inv as (
    SELECT
        CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP ) as PB_LOAD_DTS
      , 'PB_INVOICE_LINE_PACING' as PB_REC_SRC
      , CURRENT_DATE as SNAPSHOTDATE
      , REC_SRC
      , ITEM_HK
      , PLANT_HK
      , CUSTOMER_HK
      , DIVISION_HK
      , SALES_ORGANIZATION_HK
      , DISTRIBUTION_CHANNEL_HK
      , INVOICE_HK
      , INVOICE_LINE_HK
      , INVOICE_LINE_PACING_LHK
    FROM SRC_lnk_inv
)

, LOGIC_sat_inv as (
    SELECT
        INVOICE_LINE_HK                                              as                                INV_INVOICE_LINE_HK
      , FKIMG                                                        as                                  INVOICED_QUANTITY
      , NETWR                                                        as                                          NET_VALUE
      , MWSBP                                                        as                                         TAX_AMOUNT
    FROM SRC_sat_inv
)

, LOGIC_sat_inh as (
    SELECT
        INVOICE_HK                                                   as                                     INH_INVOICE_HK
      , FKDAT                                                        as                                      INVOICED_DATE
    FROM SRC_sat_inh
)

, LOGIC_hub_item as (
    SELECT
        ITEM_HK as HUB_ITEM_HK
      , ITEM_BK
      , BKCC
    FROM SRC_hub_item
)

, LOGIC_hub_cust as (
    SELECT
        CUSTOMER_HK as HUB_CUSTOMER_HK
      , CUSTOMER_BK
    FROM SRC_hub_cust
)

, LOGIC_hub_pl as (
    SELECT
        PLANT_HK as HUB_PLANT_HK
      , PLANT_BK
    FROM SRC_hub_pl
)

, LOGIC_hub_d as (
    SELECT
        DIVISION_HK as HUB_DIVISION_HK
      , DIVISION_BK
    FROM SRC_hub_d
)

, LOGIC_hub_so as (
    SELECT
        SALES_ORGANIZATION_HK as HUB_SALES_ORGANIZATION_HK
      , SALES_ORGANIZATION_BK
    FROM SRC_hub_so
)

, LOGIC_hub_dc as (
    SELECT
        DISTRIBUTION_CHANNEL_HK as HUB_DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
    FROM SRC_hub_dc
)

, LOGIC_hub_ih as (
    SELECT
        INVOICE_HK as HUB_INVOICE_HK
      , INVOICE_BK
    FROM SRC_hub_ih
)

, LOGIC_hub_il as (
    SELECT
        INVOICE_LINE_HK as HUB_INVOICE_LINE_HK
      , INVOICE_LINE_BK
    FROM SRC_hub_il
)
---- RENAME LAYER ----

, RENAME_lnk_inv as (
    SELECT
        PB_LOAD_DTS
      , PB_REC_SRC
      , SNAPSHOTDATE
      , REC_SRC
      , ITEM_HK
      , PLANT_HK
      , CUSTOMER_HK
      , DIVISION_HK
      , SALES_ORGANIZATION_HK
      , DISTRIBUTION_CHANNEL_HK
      , INVOICE_HK
      , INVOICE_LINE_HK
      , INVOICE_LINE_PACING_LHK
    FROM LOGIC_lnk_inv
)

, RENAME_sat_inv as (
    SELECT
        INV_INVOICE_LINE_HK
      , INVOICED_QUANTITY
      , NET_VALUE
      , TAX_AMOUNT
    FROM LOGIC_sat_inv
)

, RENAME_sat_inh as (
    SELECT
        INH_INVOICE_HK
      , INVOICED_DATE
    FROM LOGIC_sat_inh
)

, RENAME_hub_pl as (
    SELECT
        HUB_PLANT_HK
      , PLANT_BK
    FROM LOGIC_hub_pl
)

, RENAME_hub_cust as (
    SELECT
        HUB_CUSTOMER_HK
      , CUSTOMER_BK
    FROM LOGIC_hub_cust
)

, RENAME_hub_d as (
    SELECT
        HUB_DIVISION_HK
      , DIVISION_BK
    FROM LOGIC_hub_d
)

, RENAME_hub_so as (
    SELECT
        HUB_SALES_ORGANIZATION_HK
      , SALES_ORGANIZATION_BK
    FROM LOGIC_hub_so
)

, RENAME_hub_dc as (
    SELECT
        HUB_DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
    FROM LOGIC_hub_dc
)

, RENAME_hub_ih as (
    SELECT
        HUB_INVOICE_HK
      , INVOICE_BK
    FROM LOGIC_hub_ih
)

, RENAME_hub_il as (
    SELECT
        HUB_INVOICE_LINE_HK
      , INVOICE_LINE_BK
    FROM LOGIC_hub_il
)

, RENAME_hub_item as (
    SELECT
        HUB_ITEM_HK
      , ITEM_BK
      , BKCC
    FROM LOGIC_hub_item
)
---- FILTER LAYER ----

, FILTER_lnk_inv as (
    SELECT *
    FROM RENAME_lnk_inv
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED' /* This filter is to exclude the ghost records */
)

, FILTER_sat_inv as (
    SELECT *
    FROM RENAME_sat_inv
)

, FILTER_sat_inh as (
    SELECT *
    FROM RENAME_sat_inh
)

, FILTER_hub_item as (
    SELECT *
    FROM RENAME_hub_item
)

, FILTER_hub_cust as (
    SELECT *
    FROM RENAME_hub_cust
)

, FILTER_hub_pl as (
    SELECT *
    FROM RENAME_hub_pl
)

, FILTER_hub_d as (
    SELECT *
    FROM RENAME_hub_d
)

, FILTER_hub_so as (
    SELECT *
    FROM RENAME_hub_so
)

, FILTER_hub_dc as (
    SELECT *
    FROM RENAME_hub_dc
)

, FILTER_hub_ih as (
    SELECT *
    FROM RENAME_hub_ih
)

, FILTER_hub_il as (
    SELECT *
    FROM RENAME_hub_il
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_lnk_inv
    INNER JOIN FILTER_sat_inv
        ON FILTER_lnk_inv.INVOICE_LINE_HK = FILTER_sat_inv.INV_INVOICE_LINE_HK
    INNER JOIN FILTER_sat_inh
        ON FILTER_lnk_inv.INVOICE_HK = FILTER_sat_inh.INH_INVOICE_HK
    INNER JOIN FILTER_hub_item
        ON FILTER_lnk_inv.ITEM_HK = FILTER_hub_item.HUB_ITEM_HK
    INNER JOIN FILTER_hub_cust
        ON FILTER_lnk_inv.CUSTOMER_HK = FILTER_hub_cust.HUB_CUSTOMER_HK
    INNER JOIN FILTER_hub_pl
        ON FILTER_lnk_inv.PLANT_HK = FILTER_hub_pl.HUB_PLANT_HK
    INNER JOIN FILTER_hub_d
        ON FILTER_lnk_inv.DIVISION_HK = FILTER_hub_d.HUB_DIVISION_HK
    INNER JOIN FILTER_hub_so
        ON FILTER_lnk_inv.SALES_ORGANIZATION_HK = FILTER_hub_so.HUB_SALES_ORGANIZATION_HK
    INNER JOIN FILTER_hub_dc
        ON FILTER_lnk_inv.DISTRIBUTION_CHANNEL_HK = FILTER_hub_dc.HUB_DISTRIBUTION_CHANNEL_HK
    INNER JOIN FILTER_hub_ih
        ON FILTER_lnk_inv.INVOICE_HK = FILTER_hub_ih.HUB_INVOICE_HK
    INNER JOIN FILTER_hub_il
        ON FILTER_lnk_inv.INVOICE_LINE_HK = FILTER_hub_il.HUB_INVOICE_LINE_HK
)

---- FINAL LAYER ----
SELECT
          SEQ8()                                                AS SEQ_ID
        , PB_LOAD_DTS
        , PB_REC_SRC
        , SNAPSHOTDATE
        , BKCC
        , REC_SRC
        , ITEM_HK
        , PLANT_HK
        , CUSTOMER_HK
        , DIVISION_HK
        , SALES_ORGANIZATION_HK
        , DISTRIBUTION_CHANNEL_HK
        , INVOICE_HK
        , INVOICE_LINE_HK
        , INVOICE_LINE_PACING_LHK
        , INVOICED_QUANTITY
        , NET_VALUE
        , TAX_AMOUNT
        , INVOICED_DATE::INTEGER             as     INVOICED_DATE__YYYYMMDD
        , PLANT_BK
        , CUSTOMER_BK
        , DIVISION_BK
        , SALES_ORGANIZATION_BK
        , DISTRIBUTION_CHANNEL_BK
        , INVOICE_BK
        , INVOICE_LINE_BK
        , ITEM_BK
FROM JOIN_RESULT
