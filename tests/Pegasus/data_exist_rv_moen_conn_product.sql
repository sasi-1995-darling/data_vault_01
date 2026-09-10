    select * from ({{ data_exist('hub_smart_device','US.DATABRICKS_INTEGRATION.DT_CLEANED_HYD_SHADOW')}}) 
    union all
    select * from ({{ data_exist('hub_smart_device','US.DATABRICKS_INTEGRATION.DT_CLEANED_NAB_SHADOW')}}) 
    union all
    select * from ({{ data_exist('hub_smart_device','US.DATABRICKS_INTEGRATION.DT_CLEANED_VAK_SHADOW')}}) 
    union all
    select * from ({{ data_exist('sat_smart_device__hyd_shadow','US.DATABRICKS_INTEGRATION.DT_CLEANED_HYD_SHADOW')}}) 
    union all
    select * from ({{ data_exist('sat_smart_device__nab_shadow','US.DATABRICKS_INTEGRATION.DT_CLEANED_NAB_SHADOW')}}) 
    union all
    select * from ({{ data_exist('sat_smart_device__vak_shadow','US.DATABRICKS_INTEGRATION.DT_CLEANED_VAK_SHADOW')}})