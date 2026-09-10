select * from (
    select * from ({{ data_exist('sat_sales_inventory__thermatru_lowes','USAZET.SNOWFLAKE.FBIN.DERIVED')}}) 
    union all
    select * from ({{ data_exist('sat_sales_inventory__thermatru_lowes','US.API.LOWES_VPP.SALES_INVENTORY_THERMATRU')}}) 
    
    
) 
except
select 1 as data_exists where 1=0