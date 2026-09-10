select * exclude (product_name)
from {{ ref('base_product_and_consumer__delighted_edp') }}