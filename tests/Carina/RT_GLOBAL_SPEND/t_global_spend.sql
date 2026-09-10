with max_date as (select MAX(SNAPSHOT_DTS) as last_date from {{ ref('pb_global_spend_detail') }} )
select * from max_date 
where datediff(day,last_date , current_timestamp) > 2