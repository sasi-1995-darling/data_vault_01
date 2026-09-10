select * from ({{ row_uniqueness('fact_global_direct_spend_daily_summary') }}) 
union all
select * from ({{ row_uniqueness('fact_global_spend_detail') }}) 