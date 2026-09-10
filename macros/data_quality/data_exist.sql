{% macro data_exist(table_name, rec_src) %}
    -- Efficient data existence check using EXISTS
    select
        case when exists (
            select 1 from {{ ref(table_name) }} where rec_src = '{{ rec_src }}' limit 1
        ) then 1 else 0 end as data_exists
        where data_exists <> 1
{% endmacro %}