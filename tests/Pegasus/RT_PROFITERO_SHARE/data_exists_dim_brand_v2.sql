SELECT * FROM ({{ data_exist('dim_brand_v2','US.PROFITERO_FIBERON.BRANDS') }})
UNION ALL
SELECT * FROM ({{ data_exist('dim_brand_v2','US.PROFITERO_FYPON.BRANDS') }})
UNION ALL
SELECT * FROM ({{ data_exist('dim_brand_v2','US.PROFITERO_LARSON.BRANDS') }})
UNION ALL
SELECT * FROM ({{ data_exist('dim_brand_v2','US.PROFITERO_SECURITY.BRANDS') }})
UNION ALL
SELECT * FROM ({{ data_exist('dim_brand_v2','US.PROFITERO_THERMATRU.BRANDS') }})
UNION ALL
SELECT * FROM ({{ data_exist('dim_brand_v2','US.PROFITERO_WINN.BRANDS') }})