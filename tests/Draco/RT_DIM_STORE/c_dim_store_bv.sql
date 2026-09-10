SELECT *
FROM (
    {{
        check_not_null_v2(
            'dim_store',
            [
                'store_key',
                'store_id',
                'store_name',
                'address1',
                'city',
                'state',
                'postal_code',
                'reporting_customer'
            ],
            'reporting_customer',
            'HOME DEPOT'
        )
    }}
)