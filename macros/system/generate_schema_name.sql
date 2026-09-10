{%- macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    
    {# Check for API-passed variables #}
    {%- set force_pr = var('force_pr_schema', false) -%}
    {%- set pr_prefix = var('pr_schema_prefix', '') -%}
    
    {%- if target.name in ['dev','qa','prod'] -%}
        {%- if force_pr and pr_prefix != '' -%}
            {# Force PR schema when variables are set via API #}
            {{ log("Using forced PR schema: " ~ pr_prefix, info=true) }}
            {%- if custom_schema_name -%}
                {{ pr_prefix }}_{{ custom_schema_name | trim }}
            {%- else -%}
                {{ pr_prefix }}
            {%- endif -%}
        {%- elif default_schema.startswith('dbt_cloud_pr_') -%}
            {# Normal PR schema logic #}
            {%- if custom_schema_name -%}
                {{ default_schema }}_{{ custom_schema_name | trim }}
            {%- else -%}
                {{ default_schema }}
            {%- endif -%}
        {%- else -%}
            {# Normal schema logic #}
            {%- if custom_schema_name -%}
                {{ custom_schema_name | trim }}
            {%- else -%}
                {{ default_schema }}
            {%- endif -%}
        {%- endif -%}
    {%- else -%}
        {{ default_schema }}
    {%- endif -%}
{%- endmacro %}