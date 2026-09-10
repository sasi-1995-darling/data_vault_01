select * from ({{ data_exist('lnk_alert_feedback','US.FLO_DYNAMODB.PROD_ALERT_FEEDBACK')}}) 
union all
select * from ({{ data_exist('lsat_alert_feedback__flo_dynamodb','US.FLO_DYNAMODB.PROD_ALERT_FEEDBACK')}})
union all

select * from ({{ data_exist('hub_product_v2','US.PROFITERO_WINN.CUSTOMER_PRODUCTS') }})
union all
select * from ({{ data_exist('hub_product_v2','US.PROFITERO_WINN.SNS_PRODUCTS') }})
union all
select * from ({{ data_exist('hub_product_v2','US.PROFITERO_WINN.PRICING_AVAILABILITY_HISTORY') }})

union all
select * from ({{ data_exist('hub_product_v2','US.PROFITERO_FYPON.CUSTOMER_PRODUCTS') }})
union all
select * from ({{ data_exist('hub_product_v2','US.PROFITERO_FYPON.PRICING_AVAILABILITY_HISTORY') }})

union all
select * from ({{ data_exist('hub_product_v2','US.PROFITERO_LARSON.CUSTOMER_PRODUCTS') }})
union all
select * from ({{ data_exist('hub_product_v2','US.PROFITERO_LARSON.PRICING_AVAILABILITY_HISTORY') }})

union all
select * from ({{ data_exist('hub_product_v2','US.PROFITERO_SECURITY.CUSTOMER_PRODUCTS') }})
union all
select * from ({{ data_exist('hub_product_v2','US.PROFITERO_SECURITY.SNS_PRODUCTS') }})
union all
select * from ({{ data_exist('hub_product_v2','US.PROFITERO_SECURITY.PRICING_AVAILABILITY_HISTORY') }})

union all
select * from ({{ data_exist('hub_product_v2','US.PROFITERO_FIBERON.CUSTOMER_PRODUCTS') }})

union all
select * from ({{ data_exist('hub_product_v2','US.PROFITERO_THERMATRU.CUSTOMER_PRODUCTS') }})

union all
select * from ({{ data_exist('hub_product_v2','US.DELIGHTED_SWS.RESPONSE') }})
union all
select * from ({{ data_exist('hub_product_v2','US.DELIGHTED_SWS.RESPONSE_ANSWER_SELECTION') }})
union all
select * from ({{ data_exist('hub_product_v2','US.DELIGHTED_YALE.RESPONSE') }})
union all
select * from ({{ data_exist('hub_product_v2','US.DELIGHTED_VAK.RESPONSE') }})
union all
select * from ({{ data_exist('hub_product_v2','US.DELIGHTED_HYDRA.RESPONSE') }})
union all
select * from ({{ data_exist('hub_product_v2','US.DELIGHTED_NABOO.RESPONSE') }})

union all
select * from ({{ data_exist('hub_product_v2','US.BAZAARVOICE.PRODUCT') }})
union all
select * from ({{ data_exist('hub_product_v2','US.BAZAARVOICE_YALE.PRODUCT') }})

union all
select * from ({{ data_exist('hub_product_v2','US.APPBOT.APPLIST') }})