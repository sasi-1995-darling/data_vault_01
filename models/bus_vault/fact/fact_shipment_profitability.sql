---- SRC LAYER ----
WITH
SRC_SHIPMENTS as (
    SELECT
        seq_id,
        snapshot_dts,
        shipment_id,
        item_id,
        customer_id,
        sales_document,
        posted_datekey::NUMBER as POSTED_DATE__YYYYMMDD,
        sales_org,
        channel,
        shipment_type,
        source as brand,
        invoiced_qty,
        return_qty,
        revenue_dollars,
        actual_returns_dollars,
        bkcc,
        rec_src
    FROM {{ref('pb_shipment')}}
),
SRC_COPA as (
    SELECT
        L_LNK_COPA_SALES_HK,
        GROSS_SALES,
        NET_SALES,
        COGS,
        CASH_DISCOUNT,
        MARKDOWNS,
        BUILDER_SINGLE_FAMILY,
        BUILDER_NSF,
        BUILDER_PP,
        PLUMBER_INSTALLER_REBATES,
        CV_SHOWROOM,
        COOP_ADVERTISING,
        OTHER_FIXED_REBATES,
        PROMOTION_EXPENSE,
        CASH_FLOW_REBATES,
        ACCRUED_RETURNS,
        REBATED_CJQ,
        PURCHASE_PRICE_VARIANCE,
        FREIGHT,
        POLICY_INCENTIVE_VPO,
        POLICY_INCENTIVE_DSP,
        POLICY_INCENTIVE_EDI,
        POLICY_INCENTIVE_HCD,
        POLICY_INCENTIVE_OPN,
        POLICY_INCENTIVE_PRP,
        POLICY_INCENTIVE_PRT,
        POLICY_INCENTIVE_RCD,
        POLICY_INCENTIVE_RET,
        POLICY_INCENTIVE_SHW,
        POLICY_INCENTIVE_SPS
    FROM {{ ref('pb_product_sales') }}
)

---- FILTER LAYER ----
, FILTER_SHIPMENTS as (
    SELECT *
    FROM SRC_SHIPMENTS
    WHERE TRUE
        AND bkcc = 'Hiding_Tiger'
        AND sales_org = 'USFS'
        AND SUBSTR(POSTED_DATE__YYYYMMDD::TEXT, 0, 4) >= '2020'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT
        shp.shipment_id,
        shp.bkcc,
        shp.rec_src,
        shp.item_id,
        shp.customer_id,
        shp.sales_document,
        shp.posted_date__YYYYMMDD,
        shp.sales_org,
        shp.channel,
        shp.shipment_type,
        shp.brand,
        shp.invoiced_qty,
        shp.return_qty,
        shp.revenue_dollars,
        shp.actual_returns_dollars,
        COALESCE(cp.GROSS_SALES, 0)                AS gross_sales,
        COALESCE(cp.NET_SALES, 0)                  AS net_sales,
        COALESCE(cp.COGS, 0)                       AS cogs,
        COALESCE(cp.CASH_DISCOUNT, 0)              AS cash_discount,
        COALESCE(cp.MARKDOWNS, 0)                  AS markdowns,
        COALESCE(cp.BUILDER_SINGLE_FAMILY, 0)      AS builder_single_family,
        COALESCE(cp.BUILDER_NSF, 0)                AS builder_nsf,
        COALESCE(cp.BUILDER_PP, 0)                 AS builder_pp,
        COALESCE(cp.PLUMBER_INSTALLER_REBATES, 0)  AS plumber_installer_rebates,
        COALESCE(cp.CV_SHOWROOM, 0)                AS cv_showroom,
        COALESCE(cp.COOP_ADVERTISING, 0)           AS coop_advertising,
        COALESCE(cp.OTHER_FIXED_REBATES, 0)        AS other_fixed_rebates,
        COALESCE(cp.PROMOTION_EXPENSE, 0)          AS promotion_expense,
        COALESCE(cp.CASH_FLOW_REBATES, 0)          AS cash_flow_rebates,
        COALESCE(cp.ACCRUED_RETURNS, 0)            AS accrued_returns,
        COALESCE(cp.REBATED_CJQ, 0)                AS rebated_cjq,
        COALESCE(cp.PURCHASE_PRICE_VARIANCE, 0)    AS purchase_price_variance,
        COALESCE(cp.FREIGHT, 0)                    AS freight,
        COALESCE(cp.POLICY_INCENTIVE_VPO, 0)       AS policy_incentive_vpo,
        COALESCE(cp.POLICY_INCENTIVE_DSP, 0)       AS policy_incentive_dsp,
        COALESCE(cp.POLICY_INCENTIVE_EDI, 0)       AS policy_incentive_edi,
        COALESCE(cp.POLICY_INCENTIVE_HCD, 0)       AS policy_incentive_hcd,
        COALESCE(cp.POLICY_INCENTIVE_OPN, 0)       AS policy_incentive_opn,
        COALESCE(cp.POLICY_INCENTIVE_PRP, 0)       AS policy_incentive_prp,
        COALESCE(cp.POLICY_INCENTIVE_PRT, 0)       AS policy_incentive_prt,
        COALESCE(cp.POLICY_INCENTIVE_RCD, 0)       AS policy_incentive_rcd,
        COALESCE(cp.POLICY_INCENTIVE_RET, 0)       AS policy_incentive_ret,
        COALESCE(cp.POLICY_INCENTIVE_SHW, 0)       AS policy_incentive_shw,
        COALESCE(cp.POLICY_INCENTIVE_SPS, 0)       AS policy_incentive_sps
    FROM FILTER_SHIPMENTS shp
    LEFT JOIN SRC_COPA cp
        ON shp.shipment_id = cp.L_LNK_COPA_SALES_HK
)

---- FINAL LAYER ----
SELECT *
FROM JOIN_RESULT
