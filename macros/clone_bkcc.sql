{% macro clone_bkcc (source_table_fqn='DATAVAULT_DEV.RAW_VAULT.REF_BUSINESS_KEY_COLLISION', target_schema=target_schema) %}
    {#
        Macro to clone the BKCC talbe into the developers schema using Snowflakes ZCC.
        Parameters:
        - source_table:  Fully qualified name of the source table (DATAULT_DEV.RAW_VAULT.REF_BUSINESS_KEY_COLLISION)
        - target_schema: The schema to clone the table into (e.g. users dev schema in datavault_dev)
    #}

    {# Split the FQN into database, schema, table #}
    {% set source_parts = source_table_fqn.split('.') %}
    {% if source_parts | length != 3 %}
        {{ exceptions.raise_compiler_error("Source table FQN muse consist of 3 parts.") }}
    {% endif %}
    {% set source_database = source_parts[0] %}
    {% set source_schema = source_parts[1] %}
    {% set source_table = source_parts[2] %}
    
    {# Construct the FQN target table name #}
    {% set target_table = target_schema ~'.'~ source_table %}

    {# Construct the SQL for ZCC #}
    {% set sql %}
    CREATE OR REPLACE TABLE {{ target_table }}
    CLONE {{ source_database }}.{{ source_schema }}.{{ source_table }}
    {% endset %}

    {# Execute the SQL generated #}
    {{ log("Cloning {{ source_table_fqn }} to {{ target_table }} ", info=True )}}
    {{ return(run_query( sql ) )}}
{% endmacro %}
