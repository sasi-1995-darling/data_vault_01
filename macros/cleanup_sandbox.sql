{% macro cleanup_sandbox(schema_name=none) %}

  {%- if schema_name is none -%}
    {{ exceptions.raise_compiler_error("Schema name must be provided to cleanup_sandbox macro") }}
  {%- endif -%}

  {%- if target.name in ['dev', 'qa', 'prod'] -%}
    {{ exceptions.raise_compiler_error("cleanup_sandbox macro cannot be run in " ~ target.name ~ " environment") }}
  {%- endif -%}

  {%- if not schema_name.startswith('dbt_') -%}
    {{ exceptions.raise_compiler_error("cleanup_sandbox macro can only be run against sandbox schemas (starting with 'dbt_')") }}
  {%- endif -%}

  {%- set recreate_schema_query -%}
    CREATE OR REPLACE SCHEMA {{ target.database }}.{{ schema_name }}
  {%- endset -%}

  {% do run_query(recreate_schema_query) %}
  {{ log("Recreated schema " ~ schema_name, info=True) }}

  {% endmacro %}

-- call macro command example
-- dbt run-operation cleanup_sandbox --args '{schema_name: dbt_sganapathi}'