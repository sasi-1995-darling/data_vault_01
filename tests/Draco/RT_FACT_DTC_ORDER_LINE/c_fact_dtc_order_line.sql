SELECT *
FROM (
    {{
        check_not_null_v2(
            'fact_dtc_order_line',
            [
                'order_header_key',
                'order_header_bk',
                'order_id',
                'order_line_key',
                'order_line_bk',
                'order_line_id',
                'order_line_number',
                'price',
                'line_quantity',
                'created_date_key',
                'store',
                'rec_src',
                'bkcc'
            ],
            'origin',
            'ORDER'
        )
    }}
)
UNION ALL
SELECT *
FROM (
    {{
        check_not_null_v2(
            'fact_dtc_order_line',
            [
                'order_header_key',
                'order_header_bk',
                'order_id',
                'order_line_key',
                'order_line_bk',
                'order_line_id',
                'order_line_number',
                'refund_line_record_id',
                'price',
                'line_dollars',
                'line_quantity',
                'created_date_key',
                'store',
                'rec_src',
                'bkcc'
            ],
            'origin',
            'REFUND'
        )
    }}
)
UNION ALL
SELECT *
FROM (
    {{
        check_not_null_v2(
            'fact_dtc_order_line',
            [
                'order_header_key',
                'order_header_bk',
                'order_id',
                'order_line_key',
                'order_line_bk',
                'order_line_id',
                'order_line_number',
                'adjustment_id',
                'price',
                'line_dollars',
                'line_quantity',
                'created_date_key',
                'store',
                'rec_src',
                'bkcc'
            ],
            'origin',
            'ADJUSTMENT'
        )
    }}
)