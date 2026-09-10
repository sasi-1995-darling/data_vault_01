{{ config( alias='fact_product_review') }}
select  *
from {{ ref('fact_product_review') }}