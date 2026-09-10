{% macro check_not_null(table_name, column_name) %}
with not_null_check as (

    select 
        count(*) as total_null_records 
    from {{ ref(table_name) }}
    where {{ column_name }} is null
            
)
select
    case
        when total_null_records > 3 then 1
    end as is_null
from not_null_check
where total_null_records > 3
{% endmacro %}