select distinct upper(trim(model)) as model, base_product_id, source
from {{ source('profitero__rr', 'products_master') }}
where concat(model, base_product_id, source) is not null