select * from ({{ data_exist('fact_ecommerce_traffic_by_session','US.API.GOOGLE_ANALYTICS_WINN_DTC.PROPERTIES')}}) 
union all
select * from ({{ data_exist('fact_ecommerce_traffic_by_session','US.API.GOOGLE_ANALYTICS_WINN_DTC_HISTORICAL.PROPERTIES')}}) 