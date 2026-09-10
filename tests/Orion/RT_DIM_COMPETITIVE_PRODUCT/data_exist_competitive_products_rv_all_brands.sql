select * from ({{ data_exist('sat_competitive_products__profitero','USAZET.SNOWFLAKE.FBIN.DERIVED')}}) 
union all
select * from ({{ data_exist('sat_competitive_products__profitero','US.PROFITERO_WINN.PRODUCTS')}}) 
union all
select * from ({{ data_exist('sat_competitive_products__profitero','US.PROFITERO_SECURITY.PRODUCTS')}}) 
union all
select * from ({{ data_exist('sat_competitive_products__profitero','US.PROFITERO_FIBERON.PRODUCTS')}}) 
union all
select * from ({{ data_exist('sat_competitive_products__profitero','US.PROFITERO_FYPON.PRODUCTS')}}) 
union all
select * from ({{ data_exist('sat_competitive_products__profitero','US.PROFITERO_THERMATRU.PRODUCTS')}}) 
union all
select * from ({{ data_exist('sat_competitive_products__profitero','US.PROFITERO_LARSON.PRODUCTS')}})
