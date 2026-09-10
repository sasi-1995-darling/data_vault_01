{% macro validity_check(table_name, column_name, filter_column , filter_value, exp) %}
{% set space = ' ' %}

-- Optimization: Use EXISTS with LIMIT 1 for early termination
select
    CASE WHEN EXISTS (
        SELECT 1
        FROM {{ ref(table_name) }}
        WHERE
            {{ filter_column }} IN (
                {%- if filter_value is iterable and filter_value is not string -%}
                    {{ filter_value | join(", ") }}
                {%- else -%}
                    {{ filter_value }}
                {%- endif -%}
            )
            AND {{ column_name }} {{space}} {{exp}}
        LIMIT 1
    ) THEN 1 END AS NOT_VALID WHERE NOT_VALID > 0
{% endmacro %}