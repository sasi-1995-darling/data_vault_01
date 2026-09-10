{% macro log_dmfv1(log_table, db, schema, table, test, metric, col, status, message) %}
    {% set sql %}
    INSERT INTO {{ log_table }} VALUES (
        CURRENT_TIMESTAMP,
        '{{ db }}',
        '{{ schema }}',
        '{{ table }}',
        '{{ test }}',
        '{{ metric }}',
        '{{ col }}',
        '{{ status }}',
        '{{ message }}'
    )
    {% endset %}
    
    {% call statement('log_insert_' ~ table ~ '_' ~ metric ~ '_' ~ modules.datetime.datetime.now().strftime('%s%f'), fetch_result=False) %}
        {{ sql }}
    {% endcall %}
{% endmacro %}

{% macro get_table_columns(db, schema, table) %}
    {% set col_query %}
    SELECT 
        COLUMN_NAME,
        DATA_TYPE
    FROM {{ db }}.INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = '{{ schema | upper }}'
      AND TABLE_NAME = '{{ table | upper }}'
    {% endset %}
    
    {% call statement('col_meta_' ~ table, fetch_result=True) %}
        {{ col_query }}
    {% endcall %}
    
    {% set result = load_result('col_meta_' ~ table) %}
    {% set col_rows = result['data'] if result else [] %}
    
   
    {% set column_map = {} %}
    {% for row in col_rows %}
        {% do column_map.update({row[0] | upper: {'name': row[0], 'type': row[1]}}) %}
    {% endfor %}
    
    {% do return(column_map) %}
{% endmacro %}


{% macro get_existing_dmfs(db, schema, table, ref_entity_domain) %}
    {% set model_rel = (db ~ "." ~ schema ~ "." ~ table) | upper %}
    
    {% set dmf_query %}
    SELECT 
        METRIC_NAME,
        REF_ARGUMENTS
    FROM TABLE(
        INFORMATION_SCHEMA.DATA_METRIC_FUNCTION_REFERENCES(
            REF_ENTITY_NAME => '{{ model_rel }}',
            REF_ENTITY_DOMAIN => '{{ ref_entity_domain }}'
        )
    )
    {% endset %}
    
    {% call statement('dmf_meta_' ~ table, fetch_result=True) %}
        {{ dmf_query }}
    {% endcall %}
    
    {% set result = load_result('dmf_meta_' ~ table) %}
    {% set dmf_rows = result['data'] if result else [] %}
    
        {% set existing_dmfs = {} %}
    {% for row in dmf_rows %}
        {% set key = row[0] | upper %}
        {% do existing_dmfs.update({key: {'name': row[0], 'args': row[1]}}) %}
    {% endfor %}
    
    {% do return(existing_dmfs) %}
{% endmacro %}



{% macro apply_schedule_to_table(db, schema, table, schedule, obj_type) %}
    {% set model_rel = (db ~ "." ~ schema ~ "." ~ table) | upper %}
    
    {% if schedule %}
        {{ log("Applying schedule [" ~ schedule ~ "] to " ~ model_rel, info=True) }}
        
        {% set schedule_sql %}
        ALTER {{ obj_type }} {{ model_rel }}
        SET DATA_METRIC_SCHEDULE = '{{ schedule }}'
        {% endset %}
        
        {% call statement('schedule_' ~ table, fetch_result=False) %}
            {{ schedule_sql }}
        {% endcall %}
    {% endif %}
{% endmacro %}



{% macro dmf_exists(existing_dmfs, metric_name, column_name) %}
    {% if metric_name | upper in existing_dmfs %}
        {% set dmf_args = existing_dmfs[metric_name | upper]['args'] %}
        {% if column_name | lower in (dmf_args | lower) %}
            {% do return(True) %}
        {% endif %}
    {% endif %}
    {% do return(False) %}
{% endmacro %}


{% macro attach_simple_dmf(log_table, db, schema, table, col, test, metric, metric_schema, obj_type, column_map, existing_dmfs) %}
    {% set model_rel = (db ~ "." ~ schema ~ "." ~ table) | upper %}
    {% set col_upper = col | upper %}
    
    
    {% if col_upper not in column_map %}
        {{ log_dmfv1
        (log_table, db, schema, table, test, metric, col, 'FAILED', 'column not found') }}
        {% do return('') %}
    {% endif %}
    
    
    {% if dmf_exists(existing_dmfs, metric, col) %}
        {{ log_dmfv1(log_table, db, schema, table, test, metric, col, 'SKIPPED', 'already attached') }}
        {% do return('') %}
    {% endif %}
    
    
    {% set alter_sql %}
    ALTER {{ obj_type }} {{ model_rel }}
    ADD DATA METRIC FUNCTION {{ metric_schema }}.{{ metric }}
    ON ({{ col }})
    {% endset %}
    
    {% call statement('attach_' ~ test ~ '_' ~ table ~ '_' ~ col, fetch_result=False) %}
        {{ alter_sql }}
    {% endcall %}
    
    {{ log_dmfv1(log_table, db, schema, table, test, metric, col, 'SUCCESS', 'attached') }}
{% endmacro %}



{% macro attach_foreign_key_dmf(log_table, db, schema, table, col, fk_table, fk_column, metric_schema, obj_type, column_map, existing_dmfs, dv_db) %}
    {% set model_rel = (db ~ "." ~ schema ~ "." ~ table) | upper %}
    {% set col_upper = col | upper %}
    {% set metric = 'DMF_FOREIGN_KEY' %}
    {% set parent_table = dv_db ~ '.' ~ schema ~ '.' ~ fk_table %}
    
    
    {% if col_upper not in column_map %}
        {{ log_dmfv1(log_table, db, schema, table, 'foreign_key', metric, col, 'FAILED', 'column not found') }}
        {% do return('') %}
    {% endif %}
    
   
    {% if dmf_exists(existing_dmfs, metric, col) %}
        {{ log_dmfv1(log_table, db, schema, table, 'foreign_key', metric, col, 'SKIPPED', 'already attached') }}
        {% do return('') %}
    {% endif %}
    
  
    {% set alter_sql %}
    ALTER {{ obj_type }} {{ model_rel }}
    ADD DATA METRIC FUNCTION {{ metric_schema }}.{{ metric }}
    ON (
        {{ col }},
        TABLE({{ parent_table }}({{ fk_column }}))
    )
    {% endset %}
    
    {% call statement('attach_fk_' ~ table ~ '_' ~ col, fetch_result=False) %}
        {{ alter_sql }}
    {% endcall %}
    
    {{ log_dmfv1(log_table, db, schema, table, 'foreign_key', metric, col, 'SUCCESS', 'attached') }}
{% endmacro %}


{% macro process_primary_key_dmf(log_table, db, schema, table, col, obj_type, column_map, existing_dmfs) %}
    {% set model_rel = (db ~ "." ~ schema ~ "." ~ table) | upper %}
    
   
    {% set cols = col.split(',') | map('trim') | map('upper') | reject('equalto', '') | list | sort %}
    {% set pk_expr = cols | join(', ') %}
    {% set pk_hash = local_md5(cols | join('_'))[:8] %}
    {% set dmf_name = 'DMF_PK_' ~ table | upper ~ '_' ~ pk_hash %}
    
    
    {% set col_defs = [] %}
    {% set all_cols_exist = True %}
    
    {% for c in cols %}
        {% if c in column_map %}
            {% do col_defs.append(c ~ ' ' ~ column_map[c]['type']) %}
        {% else %}
            {% set all_cols_exist = False %}
        {% endif %}
    {% endfor %}
    
    {% if not all_cols_exist %}
        {{ log_dmfv1(log_table, db, schema, table, 'primary_key', dmf_name, col, 'FAILED', 'one or more columns not found') }}
        {% do return('') %}
    {% endif %}
    
    {{ log("Generated PK DMF = " ~ dmf_name, info=True) }}

{% for dmf_name_key in existing_dmfs.keys() %}
    {{ log("Existing PK DMF = " ~ dmf_name_key, info=True) }}
{% endfor %}

{% set ns = namespace(pk_exists=False) %}

{% for dmf_name_key in existing_dmfs.keys() %}
    {% if dmf_name | upper == dmf_name_key | upper %}
        {% set ns.pk_exists = True %}
        {% do log_dmfv1(
            log_table,
            db,
            schema,
            table,
            'primary_key',
            dmf_name_key,
            col,
            'SKIPPED',
            'already attached'
        ) %}
    {% endif %}
{% endfor %}

{% if ns.pk_exists %}
    {% do return('') %}
{% endif %}
    
    
    {% set create_sql %}
    CREATE OR REPLACE DATA METRIC FUNCTION {{ db }}.{{ schema }}.{{ dmf_name }}
    (t TABLE({{ col_defs | join(', ') }}))
    RETURNS NUMBER AS $$
    SELECT IFF(
    EXISTS (
        SELECT 1
        FROM t
        GROUP BY {{ pk_expr }}
        HAVING COUNT(*) > 1
    ),
    1,
    0
)
    $$
    {% endset %}
    
    {% call statement('create_pk_dmf_' ~ table, fetch_result=False) %}
        {{ create_sql }}
    {% endcall %}
    
    {% set attach_sql %}
    ALTER {{ obj_type }} {{ model_rel }}
    ADD DATA METRIC FUNCTION {{ db }}.{{ schema }}.{{ dmf_name }}
    ON ({{ pk_expr }})
    {% endset %}
    
    {% call statement('attach_pk_dmf_' ~ table, fetch_result=False) %}
        {{ attach_sql }}
    {% endcall %}
    
    {{ log_dmfv1(log_table, db, schema, table, 'primary_key', dmf_name, col, 'SUCCESS', 'created') }}
{% endmacro %}


{% macro apply_dmf_frameworkv1() %}

{{ log("Starting OPTIMIZED DMF Framework ...", info=True) }}

{% if execute %}


{% set env = env_var('DBT_ENVIRON', target.name) %}
{% set dv_db = "datavault_" ~ env %}
{% set schedule = env_var("DBT_DMF_SCHEDULE", "") %}
{{ log("DMF Schedule from env var = [" ~ schedule ~ "]", info=True) }}


{% if target.name == 'default' %}
    {% set log_table = dv_db ~ '.' ~ target.schema ~ '.DMF_RUN_LOG' %}
    {% set inventory_table = dv_db ~ '.' ~ target.schema ~ '.DMF_SKIPPED_TABLE_DETAILS' %}
{% else %}
    {% set log_table = dv_db ~ '.SNOWFLAKE_DMF.DMF_RUN_LOG' %}
    {% set inventory_table = dv_db ~ '.SNOWFLAKE_DMF.DMF_SKIPPED_TABLE_DETAILS' %}
{% endif %}


{% call statement('create_log_table', fetch_result=False) %}
CREATE TABLE IF NOT EXISTS {{ log_table }} (
    run_time TIMESTAMP,
    database_name STRING,
    schema_name STRING,
    table_name STRING,
    test_type STRING,
    metric_name STRING,
    tested_column STRING,
    status STRING,
    message STRING
)
{% endcall %}


{% if target.name in ['default', 'dev', 'qa'] %}
    {{ log("Running in DEV/QA → LIMITED execution", info=True) }}
    
    {% set metadata_query %}
        SELECT *
        FROM {{ inventory_table }}
        WHERE loaded_at >= DATEADD(hour, -1, CURRENT_TIMESTAMP)
          AND LOWER(test_type) IN ('primary_key','not_null','unique','foreign_key')
          AND LOWER(model_type) != 'ephemeral'
          AND LOWER(model_table) IN (
              'dim_item_fbin',
              'dim_legal_entity',
              'dim_supplier_payment_terms',
              'fact_false_positive_rate_period',
              'fact_flow_events_device_period',
              'sat_pog_weekly__homedepot',
              'sat_po_item__ml_ebs',
              'sat_user_engagement_screen__ios_flo',
              'fact_product_cost_estimate',
              'fact_delivery_line_item',
              'hub_transaction',
              'hub_device_account',
              'hub_device_location',
              'sat_sales_rep__tt_e21',
              'dim_sales_invoice',
              'lmsat_channel_forecast_items__amazon_moen_anaheim'
          )
    {% endset %}

{% elif target.name == 'prod' %}
    {{ log("Running in PROD → FULL execution", info=True) }}
    
    {% set metadata_query %}
        SELECT *
        FROM {{ inventory_table }}
        WHERE loaded_at >= DATEADD(hour, -1, CURRENT_TIMESTAMP)
          AND LOWER(test_type) IN ('primary_key','not_null','unique','foreign_key')
          AND model_table != 'ref_business_key_collision'
          AND LOWER(model_type) != 'ephemeral'
    {% endset %}

{% else %}
    {{ log("Unsupported target for DMF framework: " ~ target.name ~ ". Skipping.", info=True) }}
    {% do return('') %}
{% endif %}


{% call statement('metadata_query_stmt', fetch_result=True) %}
    {{ metadata_query }}
{% endcall %}

{% set metadata_result = load_result('metadata_query_stmt') %}
{% set metadata_rows = metadata_result['data'] if metadata_result else [] %}

{% if metadata_rows | length == 0 %}
    {{ log("No eligible inventory rows found. Skipping DMF framework.", info=True) }}
    {% do return('') %}
{% endif %}

{% set tables_dict = {} %}

{% for row in metadata_rows %}
    {% set db = row[7] %}
    {% set schema = row[8] %}
    {% set table = row[9] %}
    {% set test = (row[2] or '') | lower %}
    {% set col = (row[3] or '') %}
    {% set model_type = (row[10] or 'table') | lower %}
    {% set fk_table = (row[11] or '') | upper %}
    {% set fk_column = (row[12] or '') | upper %}
    
    {% set table_key = (db ~ "." ~ schema ~ "." ~ table) | upper %}
    
   
    {% if table_key not in tables_dict %}
        {% do tables_dict.update({
            table_key: {
                'db': db,
                'schema': schema,
                'table': table,
                'model_type': model_type,
                'tests': []
            }
        }) %}
    {% endif %}
    
   
    {% do tables_dict[table_key]['tests'].append({
        'type': test,
        'column': col,
        'fk_table': fk_table,
        'fk_column': fk_column
    }) %}
{% endfor %}

{{ log("Processing " ~ (tables_dict | length) ~ " unique tables with " ~ (metadata_rows | length) ~ " total tests", info=True) }}

{% for table_key, table_info in tables_dict.items() %}
    
    {% set db = table_info['db'] %}
    {% set schema = table_info['schema'] %}
    {% set table = table_info['table'] %}
    {% set model_type = table_info['model_type'] %}
    {% set tests = table_info['tests'] %}
    
    {% set obj_type = 'VIEW' if model_type == 'view' else 'TABLE' %}
    {% set ref_entity_domain = 'view' if model_type == 'view' else 'table' %}
    
    {{ log("Processing table " ~ table_key ~ " (" ~ (tests | length) ~ " tests)", info=True) }}
    

    {% do apply_schedule_to_table(db, schema, table, schedule, obj_type) %}
    
   
    {% set column_map = get_table_columns(db, schema, table) %}
    
   
    {% set existing_dmfs = get_existing_dmfs(db, schema, table, ref_entity_domain) %}
    
   
    {% for test in tests %}
        
        {% set test_type = test['type'] %}
        {% set col = test['column'] %}
        {% set fk_table = test['fk_table'] %}
        {% set fk_column = test['fk_column'] %}
        
       
        {% if test_type == 'not_null' %}
            {% set col_lower = col | lower %}
            
           
            {% if col_lower in ['hash_diff','hashdiff'] or col_lower[-3:] == '_hk' or col_lower[-4:] == '_lhk' %}
                {% set metric = 'DMF_HASHKEY_NULL_COUNT' %}
                {% set metric_schema = target.database ~ '.SNOWFLAKE_DMF' %}
            {% else %}
                {% set metric = 'NULL_COUNT' %}
                {% set metric_schema = 'SNOWFLAKE.CORE' %}
            {% endif %}
            
            {% do attach_simple_dmf(log_table, db, schema, table, col, 'not_null', metric, metric_schema, obj_type, column_map, existing_dmfs) %}
        
       
        {% elif test_type == 'unique' %}
            {% set col_lower = col | lower %}
            
          
            {% if col_lower in ['hash_diff','hashdiff'] or col_lower[-3:] == '_hk' or col_lower[-4:] == '_lhk' %}
                {% set metric = 'DMF_HASHKEY_UNIQUE_COUNT' %}
                {% set metric_schema = target.database ~ '.SNOWFLAKE_DMF' %}
            {% else %}
                {% set metric = 'DUPLICATE_COUNT' %}
                {% set metric_schema = 'SNOWFLAKE.CORE' %}
            {% endif %}
            
            {% do attach_simple_dmf(log_table, db, schema, table, col, 'not_null', metric, metric_schema, obj_type, column_map, existing_dmfs) %}
        
        
        {% elif test_type == 'foreign_key' %}
            {% set metric_schema = target.database ~ '.SNOWFLAKE_DMF' %}
            {% do attach_foreign_key_dmf(log_table, db, schema, table, col, fk_table, fk_column, metric_schema, obj_type, column_map, existing_dmfs, dv_db) %}
        
        
        {% elif test_type == 'primary_key' %}
            {% do process_primary_key_dmf(log_table, db, schema, table, col, obj_type, column_map, existing_dmfs) %}
        
     
        {% else %}
            {{ log_dmfv1(log_table, db, schema, table, test_type, 'NA', col, 'SKIPPED', 'unsupported test') }}
        
        {% endif %}
        
    {% endfor %}
    
{% endfor %}

{% endif %}

{{ log("Completed  DMF Framework", info=True) }}

{% endmacro %}
