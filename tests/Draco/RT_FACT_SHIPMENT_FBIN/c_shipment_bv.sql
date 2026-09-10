SELECT *
FROM (
    {{
        check_not_null_v2(
            'fact_shipment_fbin',
            [
                'shipment_id',
                'posted_datekey',
                'brand',
                'invoiced_qty',
                'return_qty',
                'revenue_dollars',
                'actual_returns_dollars'
            ],
            'brand',
            'MOEN'
        )
    }}
)
UNION ALL
SELECT *
FROM (
    {{
        check_not_null_v2(
            'fact_shipment_fbin',
            [
                'shipment_id',
                'customer_id',
                'customer',
                'posted_datekey',
                'brand',
                'invoiced_qty',
                'return_qty',
                'actual_returns_dollars'
            ],
            'brand',
            'MASTER LOCK'
        )
    }}
)
UNION ALL
SELECT *
FROM (
    {{
        check_not_null_v2(
            'fact_shipment_fbin',
            [
                'shipment_id',
                'item_id',
                'customer_id',
                'customer',
                'customer_account_name',
                'posted_datekey',
                'brand',
                'invoiced_qty',
                'return_qty',
                'actual_returns_dollars',
                'shipment_type'
            ],
            'brand',
            'FIBERON'
        )
    }}
)
UNION ALL
SELECT *
FROM (
    {{
        check_not_null_v2(
            'fact_shipment_fbin',
            [
                'shipment_id',
                'customer_id',
                'item_id',
                'customer',
                'posted_datekey',
                'brand',
                'customer',
                'customer_account_name',
                'key_account_number',
                'invoiced_qty',
                'return_qty',
                'revenue_dollars',
                'actual_returns_dollars'
            ],
            'brand',
            'LARSON'
        )
    }}
)