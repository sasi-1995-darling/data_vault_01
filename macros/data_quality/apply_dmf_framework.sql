{% macro log_dmf(log_table, db, schema, table, test, metric, col, status, message) %}

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

    {% call statement('log_insert_' ~ table ~ '_' ~ metric, fetch_result=False) %}
        {{ sql }}
    {% endcall %}

{% endmacro %}


{% macro apply_dmf_framework() %}

{{ log("Starting DMF Framework ...", info=True) }}

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






{% if target.name in ['default' ,'dev', 'qa'] %}
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

          AND LOWER(test_type) IN ('primary_key','not_null','unique','foreign_key') and model_table !='ref_business_key_collision'
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

{% set processed_tables = [] %}
{% set supported_tests = ['not_null', 'unique', 'primary_key','foreign_key'] %}

{% for row in metadata_rows %}

{% set db = row[7] %}
{% set schema = row[8] %}
{% set table = row[9] %}
{% set test = (row[2] or '') | lower %}
{% set col = (row[3] or '') %}
{% set model_type = (row[10] or 'table') | lower %}
{% set fk_table = (row[11] or '') | upper %}
{% set fk_column = (row[12] or '') | upper %}

{% set obj_type = 'VIEW' if model_type == 'view' else 'TABLE' %}
{% set ref_entity_domain = 'view' if model_type == 'view' else 'table' %}
{% set model_rel = (db ~ "." ~ schema ~ "." ~ table) | upper %}


{% if model_rel not in processed_tables %}

    {% do processed_tables.append(model_rel) %}

    {% if schedule %}
        {{ log("Applying schedule [" ~ schedule ~ "] to " ~ model_rel, info=True) }}

        {% set schedule_sql %}
            ALTER {{ obj_type }} {{ model_rel }}
            SET DATA_METRIC_SCHEDULE = '{{ schedule }}'
        {% endset %}

        {% call statement('schedule_stmt_' ~ loop.index, fetch_result=False) %}
            {{ schedule_sql }}
        {% endcall %}

    {% endif %}

{% endif %}

{% if test not in supported_tests %}

    {{ log_dmf(log_table, db, schema, table, test, 'NA', col, 'SKIPPED', 'unsupported test') }}
    {% continue %}

{% endif %}

{% set col_check %}
    SELECT 1
    FROM {{ db }}.INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = '{{ schema | upper }}'
      AND TABLE_NAME = '{{ table | upper }}'
      AND COLUMN_NAME = '{{ col | upper }}'
    LIMIT 1
{% endset %}

{% call statement('col_check_stmt_' ~ loop.index, fetch_result=True) %}
    {{ col_check }}
{% endcall %}

{% set col_check_result = load_result('col_check_stmt_' ~ loop.index) %}
{% set col_exists = col_check_result and (col_check_result['data'] | length) > 0 %}

{% if test in ['not_null', 'unique'] %}

{% set col_lower = col | lower %}

{% if col_lower in ['hash_diff','hashdiff']
   or col_lower[-3:] == '_hk'
   or col_lower[-4:] == '_lhk' %}
    {% if test == 'not_null' %}
        {% set metric = 'DMF_HASHKEY_NULL_COUNT' %}
    {% else %}
        {% set metric = 'DMF_HASHKEY_UNIQUE_COUNT' %}
    {% endif %}
    {% set metric_schema = target.database ~ '.SNOWFLAKE_DMF' %}
{% else %}
    {% if test == 'not_null' %}
        {% set metric = 'NULL_COUNT' %}
    {% else %}
        {% set metric = 'DUPLICATE_COUNT' %}
    {% endif %}
    {% set metric_schema = 'SNOWFLAKE.CORE' %}
{% endif %}


    {% set check_sql %}
    SELECT 1
    FROM TABLE(
        INFORMATION_SCHEMA.DATA_METRIC_FUNCTION_REFERENCES(
            REF_ENTITY_NAME => '{{ model_rel }}',
            REF_ENTITY_DOMAIN => '{{ ref_entity_domain }}'
        )
    )
    WHERE METRIC_NAME = '{{ metric }}'
      AND LOWER(REF_ARGUMENTS)::STRING LIKE '%{{ col | lower }}%'
    LIMIT 1
    {% endset %}

    {% call statement('exists_stmt_' ~ loop.index, fetch_result=True) %}
        {{ check_sql }}
    {% endcall %}

    {% set exists_check = load_result('exists_stmt_' ~ loop.index) %}
    {% set exists_rows = exists_check['data'] if exists_check else [] %}

    {% if not col_exists %}

        {{ log_dmf(log_table, db, schema, table, test, metric, col, 'FAILED', 'column not found') }}

    {% elif exists_rows | length == 0 %}

        {% set alter_sql %}
        ALTER {{ obj_type }} {{ model_rel }}
        ADD DATA METRIC FUNCTION {{ metric_schema }}.{{ metric }}
        ON ({{ col }})
        {% endset %}

        {% call statement('alter_stmt_' ~ loop.index, fetch_result=False) %}
            {{ alter_sql }}
        {% endcall %}

        {{ log_dmf(log_table, db, schema, table, test, metric, col, 'SUCCESS', 'attached') }}

    {% else %}

        {{ log_dmf(log_table, db, schema, table, test, metric, col, 'SKIPPED', 'already attached') }}

    {% endif %}

{% endif %}
{% if test == 'foreign_key' %}

    {% set metric = 'DMF_FOREIGN_KEY' %}
    {% set metric_schema = target.database ~ '.SNOWFLAKE_DMF' %}
    {% set parent_table = dv_db ~ '.' ~ schema ~ '.' ~ fk_table %}

    {% set check_sql %}
    SELECT 1
    FROM TABLE(
        INFORMATION_SCHEMA.DATA_METRIC_FUNCTION_REFERENCES(
            REF_ENTITY_NAME => '{{ model_rel }}',
            REF_ENTITY_DOMAIN => '{{ ref_entity_domain }}'
        )
    )
    WHERE METRIC_NAME = '{{ metric }}'
      AND LOWER(REF_ARGUMENTS)::STRING LIKE '%{{ col | lower }}%'
    LIMIT 1
    {% endset %}

    {% call statement('fk_exists_stmt_' ~ loop.index, fetch_result=True) %}
        {{ check_sql }}
    {% endcall %}

    {% set exists_result = load_result('fk_exists_stmt_' ~ loop.index) %}
    {% set exists_rows = exists_result['data'] if exists_result else [] %}

    {% if not col_exists %}

       {{ log_dmf(log_table, db, schema, table, test, metric, col, 'FAILED', 'column not found') }}

    {% elif exists_rows | length == 0 %}

        {% set alter_sql %}
           ALTER {{ obj_type }} {{ model_rel }}
           ADD DATA METRIC FUNCTION {{ metric_schema }}.{{ metric }}
          ON (
         {{ col }},
         TABLE({{ parent_table }}({{ fk_column }})))
{% endset %}

        {% call statement('attach_fk_stmt_' ~ loop.index, fetch_result=False) %}
            {{ alter_sql }}
        {% endcall %}

        {{ log_dmf(log_table,db,schema,table,test,metric,col,'SUCCESS','attached') }}

    {% else %}

        {{ log_dmf(log_table,db,schema,table,test,metric,col,'SKIPPED','already attached') }}

    {% endif %}

{% endif %}
{% if test == 'primary_key' %}

    {% set cols = col.split(',') | map('trim') | map('upper') | reject('equalto', '') | list %}
    {% set cols = cols | sort %}
    {% set pk_expr = cols | join(', ') %}
    {% set pk_hash = local_md5(cols | join('_'))[:8] %}
    {% set dmf_name = 'DMF_PK_' ~ table | upper ~ '_' ~ pk_hash %}

    {% set col_query %}
    SELECT COLUMN_NAME, DATA_TYPE
    FROM {{ db }}.INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = '{{ schema | upper }}'
      AND TABLE_NAME = '{{ table | upper }}'
    {% endset %}

    {% call statement('col_meta_stmt_' ~ loop.index, fetch_result=True) %}
        {{ col_query }}
    {% endcall %}

    {% set col_results = load_result('col_meta_stmt_' ~ loop.index) %}
    {% set col_rows = col_results['data'] if col_results else [] %}

    {% set column_map = {} %}

    {% for r in col_rows %}
        {% do column_map.update({r[0]: r[1]}) %}
    {% endfor %}

    {% set col_defs = [] %}

    {% for c in cols %}
        {% if c in column_map %}
            {% do col_defs.append(c ~ ' ' ~ column_map[c]) %}
        {% endif %}
    {% endfor %}

    {% set dmf_query %}
    SELECT METRIC_NAME, REF_ARGUMENTS
    FROM TABLE(
        INFORMATION_SCHEMA.DATA_METRIC_FUNCTION_REFERENCES(
            REF_ENTITY_NAME => '{{ model_rel }}',
            REF_ENTITY_DOMAIN => '{{ ref_entity_domain }}'
        )
    )
    {% endset %}

    {% call statement('dmf_stmt_' ~ loop.index, fetch_result=True) %}
        {{ dmf_query }}
    {% endcall %}

    {% set dmf_results = load_result('dmf_stmt_' ~ loop.index) %}
    {% set dmf_rows = dmf_results['data'] if dmf_results else [] %}

    {% set pk_dmfs = [] %}

    {% for r in dmf_rows %}

        {% if 'DMF_PK_' in r[0] and table | upper in r[0] %}

            {% set parsed = fromjson(r[1]) %}
            {% set col_names = [] %}

            {% for obj in parsed %}
                {% do col_names.append(obj['name']) %}
            {% endfor %}

            {% do pk_dmfs.append(r[0] | upper) %}

        {% endif %}

    {% endfor %}
    {{ log('Generated DMF Name: ' ~ dmf_name, info=True) }}
    {{ log('Existing PK DMFs: ' ~ (pk_dmfs | join(', ')), info=True) }}

    {% if dmf_name | upper in pk_dmfs %}

        {{ log_dmf(log_table, db, schema, table, 'primary_key', dmf_name, col, 'SKIPPED', 'already attached') }}

    {% else %}

        {% set create_sql %}
        CREATE OR REPLACE DATA METRIC FUNCTION {{ db }}.{{ schema }}.{{ dmf_name }}
        (t TABLE({{ col_defs | join(', ') }}))
        RETURNS NUMBER AS $$
        SELECT COUNT(*) FROM (
            SELECT {{ pk_expr }}
            FROM t
            GROUP BY {{ pk_expr }}
            HAVING COUNT(*) > 1
        )
        $$
        {% endset %}

        {% call statement('create_dmf_stmt_' ~ loop.index, fetch_result=False) %}
            {{ create_sql }}
        {% endcall %}

        {% set attach_sql %}
        ALTER {{ obj_type }} {{ model_rel }}
        ADD DATA METRIC FUNCTION {{ db }}.{{ schema }}.{{ dmf_name }}
        ON ({{ pk_expr }})
        {% endset %}

        {% call statement('attach_dmf_stmt_' ~ loop.index, fetch_result=False) %}
            {{ attach_sql }}
        {% endcall %}

        {{ log_dmf(log_table, db, schema, table, 'primary_key', dmf_name, col, 'SUCCESS', 'created') }}

    {% endif %}

{% endif %}

{% endfor %}

{% endif %}

{{ log("Completed DMF Framework FINAL", info=True) }}

{% endmacro %}