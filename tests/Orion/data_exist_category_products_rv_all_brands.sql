select * from (
    select * from ({{ data_exist('sat_category_products__profitero','USAZET.SNOWFLAKE.FBIN.DERIVED')}}) 
    union all
    select * from ({{ data_exist('sat_category_products__profitero','US.PROFITERO_WINN.CATEGORIES')}}) 
    union all
    select * from ({{ data_exist('sat_category_products__profitero','US.PROFITERO_SECURITY.CATEGORIES')}}) 
    union all
    select * from ({{ data_exist('sat_category_products__profitero','US.PROFITERO_FIBERON.CATEGORIES')}}) 
    union all
    select * from ({{ data_exist('sat_category_products__profitero','US.PROFITERO_FYPON.CATEGORIES')}}) 
    union all
    select * from ({{ data_exist('sat_category_products__profitero','US.PROFITERO_THERMATRU.CATEGORIES')}}) 
    union all
    select * from ({{ data_exist('sat_category_products__profitero','US.PROFITERO_LARSON.CATEGORIES')}})
    
) 
except
select * where 1=0