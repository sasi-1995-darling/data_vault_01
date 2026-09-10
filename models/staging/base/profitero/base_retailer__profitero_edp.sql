select * 
from {{ source('profitero__rr', 'retailers') }}
/*where id in (
                select id 
                from {{ source('target_retailer__rr', 'target_retailer') }}
                where source = 'Profitero'
)
*/