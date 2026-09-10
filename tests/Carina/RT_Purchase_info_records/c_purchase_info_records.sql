select * from (
    {{ check_not_null_v2(
        'fact_purchase_info_record',
        [
            'PURCHASING_INFO_RECORD_ORG_HK',
            'PURCHASING_INFO_RECORD_BK',
            'SUPPLIER_BK',
            'PURCHASING_ORG_BK',
            'PURCHASING_INFO_RECORD_CATEGORY',
            'ORDER_UOM',
            'CONVERSION_ORDER_UOM_TO_BASE_UOM_N',
            'CONVERSION_ORDER_UOM_TO_BASE_UOM_D',
            'PURCHASING_GROUP',
            'PLANNED_DELIVERY_TIME_IN_DAYS',
            'NET_PRICE',
            'PRICE_UNIT',
            'PRICE_VALID_UNTIL__YYYYMMDD',
            'OVER_DELIVERY_TOLORANCE_LIMIT',
            'UNDER_DELIVERY_TOLORANCE_LIMIT',
            'PIR_CREATION_DATE__YYYYMMDD',
            'PIR_PORG_CREATION_DATE__YYYYMMDD',
            'IS_DELETED',
            'REC_SRC',
            'BKCC'
        ],
        'BKCC',
        'Hiding_Tiger'
    ) }})