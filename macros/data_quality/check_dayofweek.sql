--Developed by Sai Varun
-- Macro to calculate if dates in data are all aligned to day of week
-- Created to test POS/Pricing use cases where data needs to be rolled up to a Saturday
-- Parameters: Model/Table Name to be checked , Date to be checked , Dayofweek that should be test against 1:- Monday ..... 0:- Sunday
{% macro check_dayofweek(table_name, date_column,dayofweek) %}
with day_check as (
    select
        count(*) as total_rows,        
        count_if(extract(dow from {{date_column}}) = {{dayofweek}}) as saturday_rows
    from {{ ref(table_name) }}
),
validation as (
    select saturday_rows has_non_compliant_dayofweek from day_check
    except
    select total_rows from day_check
)
select has_non_compliant_dayofweek from validation
{% endmacro %}
