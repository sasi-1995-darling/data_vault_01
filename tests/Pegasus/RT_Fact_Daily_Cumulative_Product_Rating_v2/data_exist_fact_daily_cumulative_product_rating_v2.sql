SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.APPBOT.RATINGS') }})
UNION ALL
SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.BAZAARVOICE.REVIEW') }})
UNION ALL
SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.BAZAARVOICE_YALE.REVIEW') }})
UNION ALL
SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.DELIGHTED_HYDRA.RESPONSE') }})
UNION ALL
SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.DELIGHTED_NABOO.RESPONSE') }})
UNION ALL
SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.DELIGHTED_SWS.RESPONSE') }})
UNION ALL
SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.DELIGHTED_VAK.RESPONSE') }})
UNION ALL
SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.DELIGHTED_YALE.RESPONSE') }})
UNION ALL
SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.PROFITERO_FIBERON.PRODUCT_RATINGS') }})
UNION ALL
SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.PROFITERO_FIBERON.REVIEWS') }})
UNION ALL
SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.PROFITERO_FYPON.PRODUCT_RATINGS') }})
UNION ALL
SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.PROFITERO_FYPON.REVIEWS') }})
UNION ALL
SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.PROFITERO_LARSON.PRODUCT_RATINGS') }})
UNION ALL
SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.PROFITERO_LARSON.REVIEWS') }})
UNION ALL
SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.PROFITERO_SECURITY.PRODUCT_RATINGS') }})
UNION ALL
SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.PROFITERO_SECURITY.REVIEWS') }})
UNION ALL
SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.PROFITERO_THERMATRU.PRODUCT_RATINGS') }})
UNION ALL
SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.PROFITERO_THERMATRU.REVIEWS') }})
UNION ALL
SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.PROFITERO_WINN.PRODUCT_RATINGS') }})
UNION ALL
SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.PROFITERO_WINN.REVIEWS') }})
UNION ALL
SELECT * FROM ({{ data_exist('fact_daily_cumulative_product_rating_v2','US.SIMPLESAT.SURVEY') }})
