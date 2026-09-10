{#
  Data Vault production environment comparison analysis
  
  Purpose: Comprehensive analysis macro to compare dbt models against Snowflake production objects
           Maps development and QA models to their production deployment locations using dbt_project.yml configuration
           Correctly translates databases: DATAVAULT_DEV/QA → DATAVAULT_PROD, INFOMART_DEV/QA → INFOMART_PROD
           Scans all schemas within dbt-managed databases to identify orphaned schemas and objects
           Excludes Snowflake native schemas (INFORMATION_SCHEMA, PUBLIC, etc.) from analysis
           Stores comprehensive comparison results in metrics schema for ongoing analysis
           Excludes ephemeral models from comparison as they are not materialized in Snowflake
  Author: System analysis macro for Data Vault production validation
#}

{% macro gc_diff_store_results(table_name, expected, actual, missing, orphaned, orphaned_schema_map) %}
    {# Create comparison results table and insert all analysis data #}
    {% set create_sql %}
        CREATE OR REPLACE TABLE {{ table_name }} (
            COMPARISON_TYPE STRING,
            DATABASE_NAME STRING,
            SCHEMA_NAME STRING,
            NAME STRING,
            MATERIALIZATION STRING,
            ORPHANED_SCHEMA_FLAG STRING,
            ANALYSIS_RUN_DTS TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
        )
    {% endset %}
    {% do run_query(create_sql) %}

    {% set all_values = [] %}
    
    {% for row in expected %}
        {% set schema_key = row.DATABASE ~ "." ~ row.SCHEMA %}
        {% set orphaned_flag = orphaned_schema_map.get(schema_key, 'N') %}
        {% set value_row = "('EXPECTED','" ~ row.DATABASE ~ "','" ~ row.SCHEMA ~ "','" ~ row.TABLE_NAME ~ "','" ~ (row.MATERIALIZATION or '') ~ "','" ~ orphaned_flag ~ "', CURRENT_TIMESTAMP())" %}
        {% do all_values.append(value_row) %}
    {% endfor %}
    
    {% for row in actual %}
        {% set schema_key = row.DATABASE ~ "." ~ row.SCHEMA %}
        {% set orphaned_flag = orphaned_schema_map.get(schema_key, 'N') %}
        {% set value_row = "('ACTUAL','" ~ row.DATABASE ~ "','" ~ row.SCHEMA ~ "','" ~ row.TABLE_NAME ~ "','" ~ (row.MATERIALIZATION or '') ~ "','" ~ orphaned_flag ~ "', CURRENT_TIMESTAMP())" %}
        {% do all_values.append(value_row) %}
    {% endfor %}
    
    {% for row in missing %}
        {% set schema_key = row.DATABASE ~ "." ~ row.SCHEMA %}
        {% set orphaned_flag = orphaned_schema_map.get(schema_key, 'N') %}
        {% set value_row = "('MISSING','" ~ row.DATABASE ~ "','" ~ row.SCHEMA ~ "','" ~ row.TABLE_NAME ~ "','" ~ (row.MATERIALIZATION or '') ~ "','" ~ orphaned_flag ~ "', CURRENT_TIMESTAMP())" %}
        {% do all_values.append(value_row) %}
    {% endfor %}
    
    {% for row in orphaned %}
        {% set schema_key = row.DATABASE ~ "." ~ row.SCHEMA %}
        {% set orphaned_flag = orphaned_schema_map.get(schema_key, 'N') %}
        {% set value_row = "('ORPHANED','" ~ row.DATABASE ~ "','" ~ row.SCHEMA ~ "','" ~ row.TABLE_NAME ~ "','" ~ (row.MATERIALIZATION or '') ~ "','" ~ orphaned_flag ~ "', CURRENT_TIMESTAMP())" %}
        {% do all_values.append(value_row) %}
    {% endfor %}

    {% if all_values|length > 0 %}
        {% set bulk_insert_sql = "INSERT INTO " ~ table_name ~ " (COMPARISON_TYPE, DATABASE_NAME, SCHEMA_NAME, NAME, MATERIALIZATION, ORPHANED_SCHEMA_FLAG, ANALYSIS_RUN_DTS) VALUES " ~ all_values|join(', ') %}
        {% do run_query(bulk_insert_sql) %}
    {% endif %}
{% endmacro %}

{% macro gc_diff_analysis(store_results=true) %}
  {% do log("=== GC_DIFF PRODUCTION ANALYSIS ===", info=True) %}
  {% do log("Analyzing all dbt-managed databases and schemas", info=True) %}
  {% do log("Current dbt target: " ~ target.database ~ "." ~ target.schema, info=True) %}
  
  {% set snowflake_native_schemas = [
    'INFORMATION_SCHEMA', 'PUBLIC', 'ACCOUNT_USAGE', 'READER_ACCOUNT_USAGE',
    'DATA_SHARING_USAGE', 'ORGANIZATION_USAGE', 'SNOWFLAKE', 'SNOWFLAKE_SAMPLE_DATA'
  ] %}
  
  {% if graph is defined and graph.nodes is defined %}
    {% do log("In-memory graph is available with " ~ graph.nodes|length ~ " nodes", info=True) %}
    
    {% set dev_schema_counts = {} %}
    {% set prod_schema_counts = {} %}
    {% set prod_database_counts = {} %}
    {% set all_expected_objects = [] %}
    {% set all_models_by_layer = {} %}
    {% set ephemeral_count = 0 %}
    {% set materialized_count = 0 %}
    {% set dbt_managed_databases = [] %}
    {% set dbt_expected_locations = {} %}
    {% set alias_resolution_count = 0 %}
    
    {% for node_id, node in graph.nodes.items() %}
      {% if node.resource_type == 'model' %}
        {% set current_database = (node.database or target.database) | upper %}
        {% set current_schema = (node.schema or target.schema) | upper %}
        {% set dev_schema_key = current_database ~ "." ~ current_schema %}
        
        {% set materialization = 'table' %}
        {% if node.config and node.config.get('materialized') %}
          {% set materialization = node.config.get('materialized') | lower %}
        {% endif %}
        
        {% if materialization == 'ephemeral' %}
          {% set ephemeral_count = ephemeral_count + 1 %}
          {% continue %}
        {% endif %}
        
        {% set materialized_count = materialized_count + 1 %}
        
        {% set production_database = current_database %}
        {% set production_schema = 'UNKNOWN' %}
        
        {% set config_database = current_database %}
        {% if node.config and node.config.get('database') %}
          {% set config_database = node.config.get('database') | upper %}
        {% endif %}
        
        {# Map development/QA databases to production equivalents #}
        {% if config_database == 'DATAVAULT_DEV' or config_database == 'DATAVAULT_QA' %}
          {% set production_database = 'DATAVAULT_PROD' %}
        {% elif config_database == 'INFOMART_DEV' or config_database == 'INFOMART_QA' %}
          {% set production_database = 'INFOMART_PROD' %}
        {% elif config_database.endswith('_DEV') or config_database.endswith('_QA') %}
          {% if config_database.endswith('_DEV') %}
            {% set production_database = config_database.replace('_DEV', '_PROD') %}
          {% elif config_database.endswith('_QA') %}
            {% set production_database = config_database.replace('_QA', '_PROD') %}
          {% endif %}
        {% elif config_database.endswith('_PROD') %}
          {% set production_database = config_database %}
        {% else %}
          {% if current_database == 'DATAVAULT_DEV' or current_database == 'DATAVAULT_QA' %}
            {% set production_database = 'DATAVAULT_PROD' %}
          {% elif current_database == 'INFOMART_DEV' or current_database == 'INFOMART_QA' %}
            {% set production_database = 'INFOMART_PROD' %}
          {% elif current_database.endswith('_DEV') %}
            {% set production_database = current_database.replace('_DEV', '_PROD') %}
          {% elif current_database.endswith('_QA') %}
            {% set production_database = current_database.replace('_QA', '_PROD') %}
          {% else %}
            {% set production_database = current_database %}
          {% endif %}
        {% endif %}
        
        {% if production_database not in dbt_managed_databases %}
          {% do dbt_managed_databases.append(production_database) %}
        {% endif %}
        
        {# Determine production schema from node configuration #}
        {% if node.config and node.config.get('schema') %}
          {% set production_schema = node.config.get('schema') | upper %}
        {% endif %}
        
        {# Infer schema from model path structure if not explicitly configured #}
        {% if production_schema == 'UNKNOWN' and node.fqn %}
          {% set model_path = node.fqn %}
          {% if model_path|length > 2 %}
            {% for path_part in model_path %}
              {% set path_part_upper = path_part | upper %}
              {% if path_part_upper in ['BUSINESS_VAULT', 'BUS_VAULT'] %}
                {% set production_schema = 'BUS_VAULT' %}
                {% break %}
              {% elif path_part_upper in ['RAW_VAULT', 'VAULT'] %}
                {% set production_schema = 'RAW_VAULT' %}
                {% break %}
              {% elif path_part_upper in ['STAGING', 'STG'] %}
                {% set production_schema = 'STAGING' %}
                {% break %}
              {% elif path_part_upper in ['MARTS', 'INFO_MART'] %}
                {% set production_schema = 'INFO_MART' %}
                {% break %}
              {% else %}
                {% set production_schema = path_part_upper %}
              {% endif %}
            {% endfor %}
          {% endif %}
        {% endif %}
        
        {# Fallback to tags for schema inference #}
        {% if production_schema == 'UNKNOWN' and node.tags %}
          {% for tag in node.tags %}
            {% set tag_upper = tag | upper %}
            {% if tag_upper in ['BUSINESS_VAULT', 'BUS_VAULT'] %}
              {% set production_schema = 'BUS_VAULT' %}
              {% break %}
            {% elif tag_upper in ['RAW_VAULT', 'VAULT'] %}
              {% set production_schema = 'RAW_VAULT' %}
              {% break %}
            {% elif tag_upper in ['STAGING', 'STG'] %}
              {% set production_schema = 'STAGING' %}
              {% break %}
            {% elif tag_upper in ['MARTS', 'INFO_MART'] %}
              {% set production_schema = 'INFO_MART' %}
              {% break %}
            {% else %}
              {% set production_schema = tag_upper %}
            {% endif %}
          {% endfor %}
        {% endif %}
        
        {# Final fallback to group for schema inference #}
        {% if production_schema == 'UNKNOWN' and node.group %}
          {% set group_upper = node.group | upper %}
          {% if group_upper in ['BUSINESS_VAULT', 'BUS_VAULT'] %}
            {% set production_schema = 'BUS_VAULT' %}
          {% elif group_upper in ['RAW_VAULT', 'VAULT'] %}
            {% set production_schema = 'RAW_VAULT' %}
          {% elif group_upper in ['STAGING', 'STG'] %}
            {% set production_schema = 'STAGING' %}
          {% elif group_upper in ['MARTS', 'INFO_MART'] %}
            {% set production_schema = 'INFO_MART' %}
          {% else %}
            {% set production_schema = group_upper %}
          {% endif %}
        {% endif %}
        
        {% set prod_location_key = production_database ~ "." ~ production_schema %}
        
        {% if prod_location_key not in dbt_expected_locations %}
          {% do dbt_expected_locations.update({prod_location_key: []}) %}
        {% endif %}
        
        {% set data_vault_layer = production_schema %}
        {% if production_database == 'INFOMART_PROD' %}
          {% set data_vault_layer = 'INFOMART' %}
        {% endif %}
        
        {# Update schema distribution counters #}
        {% if dev_schema_key not in dev_schema_counts %}
          {% do dev_schema_counts.update({dev_schema_key: 0}) %}
        {% endif %}
        {% do dev_schema_counts.update({dev_schema_key: dev_schema_counts[dev_schema_key] + 1}) %}
        
        {% if prod_location_key not in prod_schema_counts %}
          {% do prod_schema_counts.update({prod_location_key: 0}) %}
        {% endif %}
        {% do prod_schema_counts.update({prod_location_key: prod_schema_counts[prod_location_key] + 1}) %}
        
        {% if production_database not in prod_database_counts %}
          {% do prod_database_counts.update({production_database: 0}) %}
        {% endif %}
        {% do prod_database_counts.update({production_database: prod_database_counts[production_database] + 1}) %}
        
        {# Track models by data vault layer #}
        {% if data_vault_layer not in all_models_by_layer %}
          {% do all_models_by_layer.update({data_vault_layer: []}) %}
        {% endif %}
        {% do all_models_by_layer[data_vault_layer].append({
          'NODE_ID': node_id,
          'NAME': node.name,
          'ALIAS': node.alias or node.name,
          'MATERIALIZATION': materialization,
          'CURRENT_LOCATION': dev_schema_key,
          'PRODUCTION_LOCATION': prod_location_key,
          'PRODUCTION_DATABASE': production_database,
          'PRODUCTION_SCHEMA': production_schema
        }) %}
        
        {# Use configured alias or default to node name #}
        {% set production_table_name = node.alias or node.name %}
        
        {% if node.config and node.config.get('alias') %}
          {% set alias_resolution_count = alias_resolution_count + 1 %}
        {% endif %}
        
        {% do all_expected_objects.append({
          'DATABASE': production_database,
          'SCHEMA': production_schema,
          'TABLE_NAME': production_table_name | upper,
          'MATERIALIZATION': materialization
        }) %}
        
        {% do dbt_expected_locations[prod_location_key].append(production_table_name | upper) %}
        
      {% endif %}
    {% endfor %}
    
    {% do log("=== MATERIALIZATION STRATEGY ANALYSIS ===", info=True) %}
    {% do log("Total models analyzed: " ~ (ephemeral_count + materialized_count), info=True) %}
    {% do log("Ephemeral models (excluded from Snowflake comparison): " ~ ephemeral_count, info=True) %}
    {% do log("Materialized models (included in Snowflake comparison): " ~ materialized_count, info=True) %}
    {% if alias_resolution_count > 0 %}
      {% do log("Models with alias configurations: " ~ alias_resolution_count, info=True) %}
    {% endif %}
    
    {% do log("=== DBT-MANAGED DATABASES ===", info=True) %}
    {% for database in dbt_managed_databases %}
      {% do log("  - " ~ database, info=True) %}
    {% endfor %}
    
    {% do log("=== CURRENT DEVELOPMENT MODEL DISTRIBUTION ===", info=True) %}
    {% for schema_key, count in dev_schema_counts.items() %}
      {% do log(schema_key ~ ": " ~ count ~ " models", info=True) %}
    {% endfor %}
    
    {% do log("=== PROJECTED PRODUCTION DATABASE DISTRIBUTION ===", info=True) %}
    {% for database_key, count in prod_database_counts.items() %}
      {% do log(database_key ~ ": " ~ count ~ " models", info=True) %}
    {% endfor %}
    
    {% do log("=== PROJECTED PRODUCTION LOCATION DISTRIBUTION ===", info=True) %}
    {% for location_key, count in prod_schema_counts.items() %}
      {% do log(location_key ~ ": " ~ count ~ " models", info=True) %}
    {% endfor %}
    
    {% do log("=== MODELS BY DATA VAULT LAYER ===", info=True) %}
    {% for layer, models in all_models_by_layer.items() %}
      {% do log(layer ~ ": " ~ models|length ~ " models", info=True) %}
    {% endfor %}

    {% if execute and dbt_managed_databases|length > 0 %}
      {% do log("=== COMPREHENSIVE SNOWFLAKE ANALYSIS ===", info=True) %}
      
      {% set all_actual_objects = [] %}
      {% set all_missing_objects = [] %}
      {% set all_orphaned_objects = [] %}
      {% set orphaned_schemas = [] %}
      {% set orphaned_schema_map = {} %}
      
      {% for database in dbt_managed_databases %}
        {% do log("Analyzing database: " ~ database, info=True) %}
        
        {% set schemas_query = "SELECT SCHEMA_NAME FROM " ~ database ~ ".INFORMATION_SCHEMA.SCHEMATA ORDER BY SCHEMA_NAME" %}
        {% set schemas_results = run_query(schemas_query) %}
        
        {% set actual_schemas = [] %}
        {% if schemas_results %}
          {% for row in schemas_results.rows %}
            {% set schema_name = row[0] | upper %}
            {% if schema_name not in snowflake_native_schemas %}
              {% do actual_schemas.append(schema_name) %}
            {% endif %}
          {% endfor %}
        {% endif %}
        
        {% do log("Found " ~ actual_schemas|length ~ " non-native schemas in " ~ database, info=True) %}
        
        {% set expected_schemas_for_db = [] %}
        {% for location_key in dbt_expected_locations.keys() %}
          {% if location_key.startswith(database ~ '.') %}
            {% set schema_name = location_key.split('.')[1] %}
            {% if schema_name not in expected_schemas_for_db %}
              {% do expected_schemas_for_db.append(schema_name) %}
            {% endif %}
          {% endif %}
        {% endfor %}
        
        {# Identify orphaned schemas #}
        {% for actual_schema in actual_schemas %}
          {% set schema_key = database ~ "." ~ actual_schema %}
          {% if actual_schema not in expected_schemas_for_db %}
            {% do orphaned_schemas.append({'DATABASE': database, 'SCHEMA': actual_schema}) %}
            {% do orphaned_schema_map.update({schema_key: 'Y'}) %}
            {% do log("Orphaned schema found: " ~ database ~ "." ~ actual_schema, info=True) %}
          {% else %}
            {% do orphaned_schema_map.update({schema_key: 'N'}) %}
          {% endif %}
        {% endfor %}
        
        {# Catalog all actual tables in each schema #}
        {% for schema_name in actual_schemas %}
          {% set location_key = database ~ "." ~ schema_name %}
          
          {% set tables_query = "SELECT TABLE_NAME, TABLE_TYPE FROM " ~ database ~ ".INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '" ~ schema_name ~ "' ORDER BY TABLE_NAME" %}
          {% set tables_results = run_query(tables_query) %}
          
          {% if tables_results %}
            {% for row in tables_results.rows %}
              {% set table_name = row[0] | upper %}
              {% set table_type = 'table' if row[1] == 'BASE TABLE' else 'view' %}
              {% do all_actual_objects.append({
                'DATABASE': database,
                'SCHEMA': schema_name,
                'TABLE_NAME': table_name,
                'MATERIALIZATION': table_type
              }) %}
            {% endfor %}
          {% endif %}
        {% endfor %}
      {% endfor %}
      
      {# Create comparison keys for analysis #}
      {% set expected_table_keys = [] %}
      {% for expected_obj in all_expected_objects %}
        {% set key = expected_obj.DATABASE ~ "." ~ expected_obj.SCHEMA ~ "." ~ expected_obj.TABLE_NAME %}
        {% do expected_table_keys.append(key) %}
      {% endfor %}
      
      {% set actual_table_keys = [] %}
      {% for actual_obj in all_actual_objects %}
        {% set key = actual_obj.DATABASE ~ "." ~ actual_obj.SCHEMA ~ "." ~ actual_obj.TABLE_NAME %}
        {% do actual_table_keys.append(key) %}
      {% endfor %}
      
      {# Identify missing tables (expected but not found) #}
      {% for expected_obj in all_expected_objects %}
        {% set key = expected_obj.DATABASE ~ "." ~ expected_obj.SCHEMA ~ "." ~ expected_obj.TABLE_NAME %}
        {% if key not in actual_table_keys %}
          {% do all_missing_objects.append(expected_obj) %}
        {% endif %}
      {% endfor %}
      
      {# Identify orphaned tables (found but not expected) #}
      {% for actual_obj in all_actual_objects %}
        {% set key = actual_obj.DATABASE ~ "." ~ actual_obj.SCHEMA ~ "." ~ actual_obj.TABLE_NAME %}
        {% if key not in expected_table_keys %}
          {% do all_orphaned_objects.append(actual_obj) %}
        {% endif %}
      {% endfor %}
      
      {% do log("=== COMPREHENSIVE COMPARISON SUMMARY ===", info=True) %}
      {% do log("DBT-managed databases analyzed: " ~ dbt_managed_databases|length, info=True) %}
      {% do log("Expected materialized models (from dbt): " ~ all_expected_objects|length, info=True) %}
      {% do log("Actual tables (in Snowflake): " ~ all_actual_objects|length, info=True) %}
      {% do log("Missing tables: " ~ all_missing_objects|length, info=True) %}
      {% do log("Orphaned tables: " ~ all_orphaned_objects|length, info=True) %}
      {% do log("Orphaned schemas: " ~ orphaned_schemas|length, info=True) %}
      
      {% if store_results %}
        {% do log("=== STORING COMPREHENSIVE COMPARISON RESULTS ===", info=True) %}
        
        {% set metrics_schema = target.database ~ ".METRICS" %}
        {% set create_schema_sql = "CREATE SCHEMA IF NOT EXISTS " ~ metrics_schema %}
        {% do run_query(create_schema_sql) %}
        
        {% set comparison_table = metrics_schema ~ ".gc_diff_comparison" %}
        {% do log("Creating comparison table: " ~ comparison_table, info=True) %}
        
        {{ gc_diff_store_results(comparison_table, all_expected_objects, all_actual_objects, all_missing_objects, all_orphaned_objects, orphaned_schema_map) }}
        
        {% set total_records = all_expected_objects|length + all_actual_objects|length + all_missing_objects|length + all_orphaned_objects|length %}
        {% do log("Stored " ~ total_records ~ " comparison records in " ~ comparison_table, info=True) %}
        
        {% do log("=== ANALYSIS QUERIES ===", info=True) %}
        {% do log("Summary by type: SELECT COMPARISON_TYPE, COUNT(*) FROM " ~ comparison_table ~ " WHERE ANALYSIS_RUN_DTS >= CURRENT_DATE GROUP BY COMPARISON_TYPE ORDER BY COMPARISON_TYPE", info=True) %}
        {% do log("By database: SELECT DATABASE_NAME, COMPARISON_TYPE, COUNT(*) FROM " ~ comparison_table ~ " WHERE ANALYSIS_RUN_DTS >= CURRENT_DATE GROUP BY DATABASE_NAME, COMPARISON_TYPE ORDER BY DATABASE_NAME, COMPARISON_TYPE", info=True) %}
        {% do log("Orphaned schemas: SELECT DATABASE_NAME, SCHEMA_NAME FROM " ~ comparison_table ~ " WHERE ORPHANED_SCHEMA_FLAG = 'Y' AND ANALYSIS_RUN_DTS >= CURRENT_DATE GROUP BY DATABASE_NAME, SCHEMA_NAME ORDER BY DATABASE_NAME, SCHEMA_NAME", info=True) %}
        
        {% do log("Metrics stored in dedicated schema: " ~ metrics_schema, info=True) %}
      {% endif %}
      
    {% endif %}
    
  {% else %}
    {% do log("In-memory graph is NOT available", info=True) %}
    {{ return("Analysis failed - dbt graph not available") }}
  {% endif %}

  {{ return("Comprehensive analysis complete - check logs for validation results") }}
{% endmacro %}