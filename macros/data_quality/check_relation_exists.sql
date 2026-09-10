-- Created and developed by Umesh Kesarla
{% macro check_relation_exists(
    parent_table,
    parent_column,
    child_table,
    child_column,
    parent_src_column,
    parent_src,
    child_src_column,
    child_src
) %}
    (
        select  {{ parent_column }} as missing_key
        from {{ ref(parent_table) }}
        where {{ parent_src_column }} in (
            {%- if parent_src is iterable and parent_src is not string -%}
                {{ parent_src | join(", ") }}
            {%- else -%}
                {{ parent_src }}
            {%- endif -%}
        )
        and not exists (
            select 1
            from {{ ref(child_table) }}
            where {{ child_column }} = {{ ref(parent_table) }}.{{ parent_column }}
            and {{ child_src_column }} in (
                {%- if child_src is iterable and child_src is not string -%}
                    {{ child_src | join(", ") }}
                {%- else -%}
                    {{ child_src }}
                {%- endif -%}
            )
        )
    limit 1
    )
{% endmacro %}