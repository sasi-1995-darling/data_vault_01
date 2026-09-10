{{ config( alias='fact_daily_cumulative_product_rating') }}
select  *
from {{ ref('fact_daily_cumulative_product_rating') }}