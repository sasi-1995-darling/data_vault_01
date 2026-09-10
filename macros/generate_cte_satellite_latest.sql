{%- macro generate_cte_satellite_latest(cte_name,hk_field) -%}
    select
        *
        , ROW_NUMBER() over (
            partition by {{ hk_field }}
            order by load_dts desc
        ) as row_num
    from {{ cte_name }}
    qualify row_num = 1
{%- endmacro -%}    