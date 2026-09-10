---- SRC LAYER ----
WITH
SRC_B              as ( SELECT
                            L_LNK_COPA_SALES_HK, L_COPA_HK, ITEM_HK, CUSTOMER_HK,
                            COPA_HEADER_BK, COPA_LINE_BK, BKCC,
                            ITEM_ID, CUSTOMER_ID, DOCUMENT_NUMBER, LINE_NUMBER, PRODUCT_SEGMENT_ID,
                            GI_DATE__YYYYMMDD, INVOICE_DATE__YYYYMMDD, POSTED_DATE__YYYYMMDD,
                            PERIO,
                            FISCAL_YEAR, FISCAL_MONTH, FISCAL_QUARTER, FISCAL_YEAR_PERIOD,
                            INVOICE_QTY, UOM,
                            GROSS_BILLING_PRICE, GROSS_SALES, NET_SALES, COGS,
                            CASH_DISCOUNT, BONUS, MARKDOWNS,
                            BUILDER_SINGLE_FAMILY, BUILDER_NSF, BUILDER_PP,
                            PLUMBER_INSTALLER_REBATES,
                            DIRECT_VOLUME_REBATE_DFR, DIRECT_VOLUME_REBATE_DSA,
                            DIRECT_VOLUME_REBATE_HFR, DIRECT_VOLUME_REBATE_VLR,
                            DIRECT_VOLUME_REBATE_DEV, CV_SHOWROOM,
                            COOP_ADVERTISING, OTHER_FIXED_REBATES,
                            PROMOTION_EXPENSE, CASH_FLOW_REBATES,
                            ACCRUED_RETURNS, REBATED_CJQ,
                            POLICY_INCENTIVE_DSP, POLICY_INCENTIVE_EDI, POLICY_INCENTIVE_HCD,
                            POLICY_INCENTIVE_OPN, POLICY_INCENTIVE_PRP, POLICY_INCENTIVE_PRT,
                            POLICY_INCENTIVE_RCD, POLICY_INCENTIVE_RET, POLICY_INCENTIVE_SHW,
                            POLICY_INCENTIVE_SPS, POLICY_INCENTIVE_VPO,
                            PURCHASE_PRICE_VARIANCE, ACQUISITION, HANDLING, FREIGHT,
                            SALES_ORG, CHANNEL, DIVISION,
                            PER_UNIT_GROSS_SALES, PER_UNIT_NET_SALES,
                            PER_UNIT_COGS, PER_UNIT_PRODUCT_MARGIN,
                            LSAT_LOAD_DTS, LSAT_REC_SRC
                        FROM {{ ref('pb_product_sales') }} as SRC  )
/*
SRC_B              as ( SELECT * FROM BUS_VAULT.PB_PRODUCT_SALES )
*/
---- LOGIC LAYER ----
, LOGIC_B as (
    SELECT *
    FROM SRC_B
)
---- RENAME LAYER ----
, RENAME_B as (
    SELECT *
    FROM LOGIC_B
)
---- FILTER LAYER ----
, FILTER_B as (
    SELECT *
    FROM RENAME_B
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_B
)
---- FINAL LAYER ----
SELECT
         L_LNK_COPA_SALES_HK
        , L_COPA_HK
        , ITEM_HK
        , CUSTOMER_HK
        , COPA_HEADER_BK
        , COPA_LINE_BK
        , BKCC
        , ITEM_ID
        , CUSTOMER_ID
        , DOCUMENT_NUMBER
        , LINE_NUMBER
        , PRODUCT_SEGMENT_ID
        , GI_DATE__YYYYMMDD
        , INVOICE_DATE__YYYYMMDD
        , POSTED_DATE__YYYYMMDD
        , PERIO
        , FISCAL_YEAR
        , FISCAL_MONTH
        , FISCAL_QUARTER
        , FISCAL_YEAR_PERIOD
        , SALES_ORG
        , CHANNEL
        , DIVISION
        , INVOICE_QTY
        , UOM
        , GROSS_BILLING_PRICE
        , GROSS_SALES
        , NET_SALES
        , COGS
        , CASH_DISCOUNT
        , BONUS
        , MARKDOWNS
        , BUILDER_SINGLE_FAMILY
        , BUILDER_NSF
        , BUILDER_PP
        , PLUMBER_INSTALLER_REBATES
        , DIRECT_VOLUME_REBATE_DFR
        , DIRECT_VOLUME_REBATE_DSA
        , DIRECT_VOLUME_REBATE_HFR
        , DIRECT_VOLUME_REBATE_VLR
        , DIRECT_VOLUME_REBATE_DEV
        , CV_SHOWROOM
        , COOP_ADVERTISING
        , OTHER_FIXED_REBATES
        , PROMOTION_EXPENSE
        , CASH_FLOW_REBATES
        , ACCRUED_RETURNS
        , REBATED_CJQ
        , POLICY_INCENTIVE_DSP
        , POLICY_INCENTIVE_EDI
        , POLICY_INCENTIVE_HCD
        , POLICY_INCENTIVE_OPN
        , POLICY_INCENTIVE_PRP
        , POLICY_INCENTIVE_PRT
        , POLICY_INCENTIVE_RCD
        , POLICY_INCENTIVE_RET
        , POLICY_INCENTIVE_SHW
        , POLICY_INCENTIVE_SPS
        , POLICY_INCENTIVE_VPO
        , PURCHASE_PRICE_VARIANCE
        , ACQUISITION
        , HANDLING
        , FREIGHT
        , PER_UNIT_GROSS_SALES
        , PER_UNIT_NET_SALES
        , PER_UNIT_COGS
        , PER_UNIT_PRODUCT_MARGIN
        , LSAT_LOAD_DTS                                                      AS SOURCE_LOAD_DTS
        , LSAT_REC_SRC
FROM JOIN_RESULT