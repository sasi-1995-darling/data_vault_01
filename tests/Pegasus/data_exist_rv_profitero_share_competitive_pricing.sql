select * from ({{ data_exist('lmsat_price_availability__fiberon_profitero_share','US.PROFITERO_FIBERON.PRICING_AVAILABILITY_HISTORY') }})
union all
select * from ({{ data_exist('lmsat_price_availability__fypon_profitero_share','US.PROFITERO_FYPON.PRICING_AVAILABILITY_HISTORY') }})
union all
select * from ({{ data_exist('lmsat_price_availability__larson_profitero_share','US.PROFITERO_LARSON.PRICING_AVAILABILITY_HISTORY') }})
union all
select * from ({{ data_exist('lmsat_price_availability__security_profitero_share','US.PROFITERO_SECURITY.PRICING_AVAILABILITY_HISTORY') }})
union all
select * from ({{ data_exist('lmsat_price_availability__thermatru_profitero_share','US.PROFITERO_THERMATRU.PRICING_AVAILABILITY_HISTORY') }})
union all
select * from ({{ data_exist('lmsat_price_availability__winn_profitero_share','US.PROFITERO_WINN.PRICING_AVAILABILITY_HISTORY') }})
union all
select * from ({{ data_exist('sat_competitive_products__security_profitero_share','US.PROFITERO_SECURITY.PRODUCTS') }})
union all
select * from ({{ data_exist('sat_competitive_products__larson_profitero_share','US.PROFITERO_LARSON.PRODUCTS') }})
union all
select * from ({{ data_exist('sat_competitive_products__fiberon_profitero_share','US.PROFITERO_FIBERON.PRODUCTS') }})
union all
select * from ({{ data_exist('sat_competitive_products__fypon_profitero_share','US.PROFITERO_FYPON.PRODUCTS') }})
union all
select * from ({{ data_exist('sat_competitive_products__thermatru_profitero_share','US.PROFITERO_THERMATRU.PRODUCTS') }})
union all
select * from ({{ data_exist('sat_competitive_products__winn_profitero_share','US.PROFITERO_WINN.PRODUCTS') }})
union all
select * from ({{ data_exist('sat_competitive_products__profitero','US.PROFITERO_SECURITY.PRODUCTS') }})
union all
select * from ({{ data_exist('sat_competitive_products__profitero','US.PROFITERO_LARSON.PRODUCTS') }})
union all
select * from ({{ data_exist('sat_competitive_products__profitero','US.PROFITERO_FIBERON.PRODUCTS') }})
union all
select * from ({{ data_exist('sat_competitive_products__profitero','US.PROFITERO_FYPON.PRODUCTS') }})
union all
select * from ({{ data_exist('sat_competitive_products__profitero','US.PROFITERO_THERMATRU.PRODUCTS') }})
union all
select * from ({{ data_exist('sat_competitive_products__profitero','US.PROFITERO_WINN.PRODUCTS') }})
union all
select * from ({{ data_exist('hub_competitive_product','US.DATAVATIONS.ITEMS') }})
union all
select * from ({{ data_exist('hub_competitive_product','US.DATAVATIONS.MAIN_WEEKLY') }})
union all
select * from ({{ data_exist('hub_competitive_product','US.PROFITERO_FIBERON.PRODUCTS') }})
union all
select * from ({{ data_exist('hub_competitive_product','US.PROFITERO_FYPON.PRODUCTS') }})
union all
select * from ({{ data_exist('hub_competitive_product','US.PROFITERO_LARSON.PRODUCTS') }})
union all
select * from ({{ data_exist('hub_competitive_product','US.PROFITERO_SECURITY.PRODUCTS') }})
union all
select * from ({{ data_exist('hub_competitive_product','US.PROFITERO_THERMATRU.PRODUCTS') }})
union all
select * from ({{ data_exist('hub_competitive_product','US.PROFITERO_WINN.PRODUCTS') }})
union all
select * from ({{ data_exist('lnk_competitive_product_retailer','US.DATAVATIONS.MAIN_WEEKLY') }})
union all
select * from ({{ data_exist('lnk_competitive_product_retailer','US.PROFITERO_LARSON.PRODUCTS') }})
union all
select * from ({{ data_exist('lnk_competitive_product_retailer','US.PROFITERO_FYPON.PRODUCTS') }})
union all
select * from ({{ data_exist('lnk_competitive_product_retailer','US.PROFITERO_WINN.PRODUCTS') }})
union all
select * from ({{ data_exist('lnk_competitive_product_retailer','US.PROFITERO_FIBERON.PRODUCTS') }})
union all
select * from ({{ data_exist('lnk_competitive_product_retailer','US.PROFITERO_SECURITY.PRODUCTS') }})
union all
select * from ({{ data_exist('lnk_competitive_product_retailer','US.PROFITERO_THERMATRU.PRODUCTS') }})