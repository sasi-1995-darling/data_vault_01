select * from (
    select * from ({{ data_exist('sat_sales_inventory_history__moen_menards','USAZET.SNOWFLAKE.FBIN.DERIVED')}}) 
    union all
    select * from ({{ data_exist('sat_sales_inventory_history__moen_menards','US.EXCEL.MENARDS.MOEN_SALES_AND_INVENTORY_HISTORY')}}) 
    union all
    select * from ({{ data_exist('sat_sales_inventory_weekly__moen_menards','USAZET.SNOWFLAKE.FBIN.DERIVED')}}) 
    union all
    select * from ({{ data_exist('sat_sales_inventory_weekly__moen_menards','US.EXCEL.MENARDS.MOEN_SALES_AND_INVENTORY_WEEKLY')}}) 
    
    
) 
except
select 1 as data_exists where 1=0