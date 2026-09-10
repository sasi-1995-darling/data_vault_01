SELECT *
FROM (
    {{
        check_not_null_v2(
            'dim_promotion',
            [
                'DIM_PROMOTION_KEY',
                'LNK_ACCOUNT_BASE_MATERIAL_PROMOTION_HK',
                'KEY_ACCOUNT_GROUP_HK',
                'BASE_MATERIAL_HK',
                'PROMOTION_HK',
                'BASE_MATERIAL_BK',
                'KEY_ACCOUNT_GROUP_BK',
                'PROMOTION_BK',
                'PROMOTION_ID',
                'PROMOTION_START_DATE_KEY',
                'PROMOTION_END_DATE_KEY',
                'PROMOTION_NAME',
                'BASE_MATERIAL',
                'BUSINESS_UNIT',
                'PROMOTION_STATUS',
                'PROMOTION_TYPE',
                'PAYMENT_TYPE',
                'PROMOTION_ACCOUNT',
                'PROMOTION_START_DATE__YYYYMMDD',
                'PROMOTION_END_DATE__YYYYMMDD',
                'PROMOTION_REPORTING_CUSTOMER',
                'PROMOTION_REPORTING_CHANNEL',
                'PROMOTION_START_FISCAL_WEEK__YYYYWW',
                'PROMOTION_END_FISCAL_WEEK__YYYYWW',
                'PROMOTION_STORE_COUNT',
                'BASE_RETAIL_PRICE',
                'PROMO_RETAIL_PRICE',
                'PLANNED_BASE_UPSPW',
                'BASE_INVOICE_PRICE',
                'PLANNED_BASE_UNITS',
                'PLANNED_INCR_UNITS',
                'PROMO_DOLLARS_PER_UNIT_EXC_FIXED',
                'BILLBACK_AMOUNT',
                'PLANNED_PROMO_SPEND_DOLLARS',
                'G2N_BEFORE_TRADE_RATE',
                'COGS_PER_UNIT',
                'VARIABLE_COSTS_RATE',
                'PLANNED_CM_DOLLARS_BEFORE_TRADE',
                'PLANNED_INCR_CM_DOLLARS',
                'REC_SRC'
            ],
            'bkcc',
            'Whistling_Walrus',
            "
            PROMOTION_END_DATE_KEY >= '2026-01-01'
            and BASE_MATERIAL_BK <> '900-006-1LD'
            --and PROMOTION_END_DATE_KEY <= CURRENT_DATE
            "
        )
    }}
)