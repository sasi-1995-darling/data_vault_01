{% macro drop_unused_objects(database=None, schema=None, dry_run=True, debug=False) %}
--dbt run-operation drop_unused_objects --args "{database: 'my_database', schema: 'my_schema', dry_run: True, debug: True}"

-- Set the database and schema to target values if not provided
{% set database = database or target.database %}
{% set schema = schema or target.schema %}

-- Initialize debug logging based on the provided argument
{% if debug %}
    {{ log("Target Database: " ~ database, info=True) }}
    {{ log("Target Schema: " ~ schema, info=True) }}
{% endif %}

-- Get the list of all tables and views in Snowflake in the specified schema
{% set query %}
    SELECT TABLE_NAME, TABLE_TYPE
    FROM {{ database }}.INFORMATION_SCHEMA.TABLES
    WHERE TABLE_CATALOG = UPPER('{{ database }}')
      AND TABLE_SCHEMA = UPPER('{{ schema }}')
    ORDER BY TABLE_NAME
{% endset %}

-- Execute the query and store the results
{% set results = run_query(query) %}
{% set existing_objects = {} %}
{% if results %}
    {{ log("\n\n===============================", info=True) }}    
    {% for row in results.rows %}
        {% do existing_objects.update({row[0]: row[1]}) %}
    {% endfor %}
    {% if debug %}
        {{ log(database ~ "." ~ schema ~ " Query Results: " ~ existing_objects, info=True) }}
    {% endif %}
{% else %}
    {{ log("ERROR: No results returned or error in query execution.", info=True) }}
{% endif %}

-- Compile a list of dbt models and seeds
{% set dbt_assets = [] %}
{% for node in graph.nodes.values() %}
    {% if node.resource_type == 'model' or node.resource_type == 'seed' %}
        {% do dbt_assets.append(node.alias | upper) %}
    {% endif %}
{% endfor %}

-- Initialize dictionaries for keep and drop
{% set to_keep = {} %}
{% set to_drop = {} %}

-- Identify unused objects and populate keep and drop dictionaries
{% for name, type in existing_objects.items() %}
    {% if name not in dbt_assets %}
        {% set object_type = 'TABLE' if type == 'BASE TABLE' else 'VIEW' %}
        {% do to_drop.update({name: object_type}) %}
    {% else %}
        {% set object_type = 'TABLE' if type == 'BASE TABLE' else 'VIEW' %}
        {% do to_keep.update({name: object_type}) %}
    {% endif %}
{% endfor %}

-- Log actions based on debug flag
{% if debug %}
    {{ log("\n\n===============================", info=True) }}    
    {% for name, object_type in to_drop.items() %}
        {{ log("DROP " ~ object_type ~ " "  ~ database ~ "." ~ schema ~ "." ~ name ~";", info=True) }}
    {% endfor %}
{% endif %}

-- Execute DROP statements if not a dry run
{% if not dry_run %}
    {% for name, object_type in to_drop.items() %}
        {{ run_query("DROP " ~ object_type ~ " "  ~ database ~ "." ~ schema ~ "." ~ name) }}
        {{ log("Dropped " ~ object_type ~ " "  ~ database ~ "." ~ schema ~ "." ~ name, info=True) }}
    {% endfor %}
{% endif %}

{% endmacro %}
