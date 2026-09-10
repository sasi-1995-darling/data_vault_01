SELECT *
FROM (
    {{
        validity_check(
            'fact_pos_weekly',
            'TRANSACTION_DATE',
            'BRAND',
            ["'SENTRYSAFE','MASTER LOCK','MOEN','LARSON','THERMA-TRU','FIBERON'"],
            "NOT BETWEEN DATE '1899-01-01' AND DATE '2100-12-31'")
    }}
)
