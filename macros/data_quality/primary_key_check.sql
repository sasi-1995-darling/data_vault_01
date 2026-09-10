{% macro primary_key_check(table_name, columns) %}
{% set space = ' ' %}
WITH metrics AS (
    SELECT
        COUNT(*) AS total_records,

        COUNT(DISTINCT 
            {% for value in columns -%}
            {{ value }}
            {%- if not loop.last -%},{%- endif %}
            {%- endfor %}) AS unique_records,

        COUNT(CASE WHEN 
            {% for value in columns -%}
            {{ value }} {{space}}is null{{space}}
            {%- if not loop.last -%}  
            {{space}}OR{{space}} {%- endif %}
            {%- endfor %}  THEN 1 ELSE NULL END) AS null_records

    FROM {{ ref(table_name) }}
)

SELECT
    CASE
        WHEN null_records != 0 OR unique_records != total_records THEN 1
        ELSE NULL
    END AS primary_key_check
FROM metrics
WHERE null_records != 0 OR unique_records != total_records

{% endmacro %}