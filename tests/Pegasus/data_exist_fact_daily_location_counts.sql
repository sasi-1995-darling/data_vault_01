select * from ({{ data_exist('fact_daily_location_counts','US.DATA_PROD_DEVICE_INVENTORY_PUBLIC.DEVICE_INFO')}}) 
union all
select * from ({{ data_exist('fact_daily_location_counts','US.FLO_TELEMETRY.FLO_DEVICE_DAILY')}}) 
union all
select * from ({{ data_exist('fact_daily_location_counts','US.FLO_PG_DEVICE_SERVICE.DEVICES')}}) 