---Created and developed by Vikas Mahato

{% macro check_column_data_type(table_name, columns_types, type) %}
{%- set relation = ref(table_name) -%}
{%- set database = relation.database -%}
{%- set schema = relation.schema -%}
{%- set identifier = relation.identifier -%}

-- columns_types: list of tuples [(column_name, expected_data_type)]
-- Returns one row per expected column when missing or mismatched

(
    with col_meta as (
    select upper(column_name) as column_name, upper(data_type) as data_type
    from {{ database }}.information_schema.columns
    where table_name = '{{ identifier | upper }}'
      and table_schema = '{{ schema | upper }}'
),
expected_columns as (
    select upper(t.column_name) as column_name, upper(t.expected_data_type) as expected_data_type
    from (
        values
        {% for col_type in columns_types %}
            ('{{ col_type[0] }}', '{{ col_type[1] }}'){% if not loop.last %},{% endif %}
        {% endfor %}
    ) as t(column_name, expected_data_type)
)
select * from (
    select
        e.column_name,
        e.expected_data_type,
        m.data_type as actual_data_type,
        case
            when m.column_name is null then 'MISSING'
            when m.data_type <> e.expected_data_type then 'TYPE_MISMATCH'
            else null
        end as test_failure
    from expected_columns e
    left join col_meta m
      on m.column_name = e.column_name
)
where test_failure is not null
)
{% endmacro %}