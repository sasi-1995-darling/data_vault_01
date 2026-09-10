select * from (
    select * from ({{ check_dayofweek('fact_pricing_competitive_weekly', 'date','6') }}) 
) 
except
select * where 1=0