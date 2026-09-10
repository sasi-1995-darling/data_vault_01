{% macro table_exists(src, table) %}
  
  {%- set source_relation = adapter.get_relation(
      database=source(src, table).database,
      schema=source(src, table).schema,
      identifier=source(src, table).name) -%}

  {% set var_table_exists=source_relation is not none %}

  {{ return(var_table_exists) }}
  
{% endmacro %}

