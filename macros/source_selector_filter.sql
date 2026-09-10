{% macro source_selector_filter(source_name, table_name) %}
{%- set source_relation = source(source_name, table_name) -%}
{%- if target.name != 'prod' -%}
    {%- set columns = adapter.get_columns_in_relation(source_relation) -%}
    {%- set column_names = columns | map(attribute='name') | list -%}
    {%- if '_FIVETRAN_SYNCED' in column_names -%}
        (
        select *
        from {{ source_relation }}
        where {{ '_FIVETRAN_SYNCED' }} >= dateadd(month, -6, current_date())
        )
    {%- else -%}
        (
        select *
        from {{ source_relation }}
         limit 10000
        )
    {%- endif -%}
{%- else -%}
    {{- source_relation -}}
{%-endif -%}
{%- endmacro -%}