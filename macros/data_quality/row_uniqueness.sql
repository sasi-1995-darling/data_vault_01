--Created and developed by jashan sadioura
{% macro row_uniqueness(table_name) %}
    -- Ensure table name is passed
    {% if not table_name %}
        {{ exceptions.raise_compiler_error("Table name must be provided as a parameter.") }}
    {% endif %}

    -- Efficient row uniqueness check using hash of all columns
    select
        count(distinct hash(*)) = count(*) as is_distinct
    from {{ ref(table_name) }} having is_distinct = FALSE
{% endmacro %}