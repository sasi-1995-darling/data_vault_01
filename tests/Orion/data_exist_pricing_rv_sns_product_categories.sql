select * from (
    select * from ({{ data_exist('sat_sns_products__profitero_winn','US.PROFITERO_WINN.SNS_PRODUCTS')}}) 
    union all
    select * from ({{ data_exist('sat_sns_products__profitero_security','US.PROFITERO_SECURITY.SNS_PRODUCTS')}}) 
    union all
    select * from ({{ data_exist('sat_sns_categories__profitero_winn','US.PROFITERO_WINN.SNS_CATEGORIES')}}) 
    union all
    select * from ({{ data_exist('sat_sns_categories__profitero_security','US.PROFITERO_SECURITY.SNS_CATEGORIES')}}) 
    union all
    select * from ({{ data_exist('lsat_sns_sales__profitero_security','US.PROFITERO_SECURITY.SALES')}}) 
    union all
    select * from ({{ data_exist('lsat_sns_sales__profitero_winn','US.PROFITERO_WINN.SALES')}})
    
    
) 
except
select * where 1=0