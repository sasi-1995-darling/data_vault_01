-- Created and developed by Umesh Kesarla
{% macro check_not_null_v2(table_name, column_names, src_column, src_name, extra_condition='1=1') %}
        -- Efficient null or blank check using ARRAY_CONSTRUCT and ARRAY_CONTAINS
        select 1
        from {{ ref(table_name) }}
        where {{ src_column }} = '{{ src_name }}'
            and {{ extra_condition }}
            and (
                ARRAY_CONTAINS(NULL, ARRAY_CONSTRUCT({{ column_names | join(', ') }}))
                or ARRAY_CONTAINS(''::variant, ARRAY_CONSTRUCT({{ column_names | join(', ') }}))
            )
        limit 1
{% endmacro %}