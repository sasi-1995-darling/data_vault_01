{% macro cleanup_pr_schemas(job_id, pr_number, dry_run=true) %}
  {% if execute %}
    {% do run_query("USE WAREHOUSE DATA_ENGINEER_WH") %}
    
    {% set schema_pattern = 'DBT_CLOUD_PR_' ~ job_id ~ '_' ~ pr_number %}
    
    {% set cleanup_sql %}
      select schema_name 
      from DATAVAULT_QA.information_schema.schemata 
      where schema_name like '{{ schema_pattern }}%'
    {% endset %}
    
    {% set schemas_to_drop = run_query(cleanup_sql) %}
    
    {% for schema_row in schemas_to_drop %}
      {% set schema_name = schema_row[0] %}
      {% if dry_run %}
        {{ log("DRY RUN: Would drop schema " ~ schema_name, info=true) }}
      {% else %}
        {% set drop_sql = "drop schema if exists DATAVAULT_QA." ~ schema_name ~ " cascade" %}
        {% do run_query(drop_sql) %}
        {{ log("Dropped schema: " ~ schema_name, info=true) }}
      {% endif %}
    {% endfor %}
  {% endif %}
{% endmacro %}