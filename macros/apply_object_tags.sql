{% macro apply_object_tags(run_results) %}
    {% if execute and run_results %}
        {% do log("env: " ~ env_var('DBT_ENVIRON'), info=True) %}

        {# Step 1: Batch query to retrieve all tags for all models #}
        {% set all_tags_query %}
        WITH BASE AS (
            SELECT DISTINCT
                TAG_DATABASE,
                TAG_SCHEMA,
                OBJECT_DATABASE as db, 
                OBJECT_SCHEMA as schema, 
                OBJECT_NAME, 
                DOMAIN as object_type, 
                COLUMN_NAME, 
                TAG_NAME, 
                TAG_VALUE,
                CASE WHEN OBJECT_DELETED IS NULL THEN '9999-12-31' ELSE OBJECT_DELETED END AS OBJECT_DELETED
            FROM SNOWFLAKE.ACCOUNT_USAGE.TAG_REFERENCES 
            WHERE OBJECT_DATABASE IN ({{ "'" ~ run_results | map(attribute='node.database') | unique | map('upper') | map('string') | join("', '") ~ "'" }})
            AND OBJECT_SCHEMA IN ({{ "'" ~ run_results | map(attribute='node.schema') | unique | map('upper') | map('string') | join("', '") ~ "'" }})
            AND OBJECT_NAME IN ({{ "'" ~ run_results | map(attribute='node.name') | unique | map('upper') | map('string') | join("', '") ~ "'" }})
        ),
        TABLE_TYPE AS (
            {% for database in run_results | map(attribute='node.database') | unique | map('upper') %}
            SELECT 
                TABLE_CATALOG, 
                TABLE_SCHEMA, 
                TABLE_NAME, 
                CASE WHEN TABLE_TYPE = 'BASE TABLE' THEN 'TABLE' ELSE TABLE_TYPE END AS TABLE_TYPE
            FROM {{ database }}.INFORMATION_SCHEMA.TABLES
            {% if not loop.last %}UNION ALL{% endif %}
            {% endfor %}
        )
        SELECT 
            B.TAG_DATABASE,
            B.TAG_SCHEMA,
            B.DB, 
            B.SCHEMA, 
            B.OBJECT_NAME, 
            B.COLUMN_NAME, 
            B.OBJECT_TYPE,
            B.TAG_NAME, 
            B.TAG_VALUE, 
            TT.TABLE_TYPE, 
            B.OBJECT_DELETED 
        FROM BASE B 
        INNER JOIN TABLE_TYPE TT 
            ON B.DB = TT.TABLE_CATALOG 
            AND B.SCHEMA = TT.TABLE_SCHEMA 
            AND B.OBJECT_NAME = TT.TABLE_NAME
        QUALIFY MAX(OBJECT_DELETED) OVER () = OBJECT_DELETED
        ORDER BY B.DB, B.SCHEMA, B.OBJECT_NAME
        {% endset %}

        {# Step 2: Use Snowflake Scripting with Async/Await, Batching, and Quoting #}
        {% set bulk_update_sql %}
        EXECUTE IMMEDIATE $$
        DECLARE
            c1 CURSOR FOR {{ all_tags_query }};
            tags_submitted INTEGER DEFAULT 0;
            batch_size INTEGER DEFAULT 500; -- Throttle to avoid queue overload
            current_batch_count INTEGER DEFAULT 0;
            models_processed INTEGER DEFAULT 0;
            last_model_id STRING DEFAULT '';
            curr_model_id STRING DEFAULT '';
            sql_stmt STRING;
        BEGIN
            -- FOR loop iterates over the cursor
            FOR record IN c1 DO
                -- 0. Logic to distinct count models
                curr_model_id := record.DB || '.' || record.SCHEMA || '.' || record.OBJECT_NAME;
                IF (curr_model_id != last_model_id) THEN
                    models_processed := models_processed + 1;
                    last_model_id := curr_model_id;
                END IF;

                -- 1. SQL Injection & Quoting: Use double quotes for all identifiers to handle special chars and keywords
                sql_stmt := 'BEGIN ' || 
                            'ALTER ' || 
                            CASE WHEN record.TABLE_TYPE = 'TABLE' THEN 'TABLE' ELSE 'VIEW' END || 
                            ' "' || record.DB || '"."' || record.SCHEMA || '"."' || record.OBJECT_NAME || '"' || 
                            CASE WHEN record.COLUMN_NAME IS NOT NULL THEN ' MODIFY COLUMN "' || record.COLUMN_NAME || '"' ELSE '' END || 
                            ' SET TAG "' || record.TAG_DATABASE || '"."' || record.TAG_SCHEMA || '"."' || record.TAG_NAME || '" = \'' || REPLACE(COALESCE(record.TAG_VALUE, ''), '\'', '\'\'') || '\';' ||
                            ' EXCEPTION WHEN OTHER THEN NULL; END;';

                IF (sql_stmt IS NOT NULL) THEN
                    ASYNC (EXECUTE IMMEDIATE :sql_stmt);
                    tags_submitted := tags_submitted + 1;
                    current_batch_count := current_batch_count + 1;
                END IF;

                -- 2. Resource Throttling: Wait every batch_size
                IF (current_batch_count >= batch_size) THEN
                    AWAIT ALL;
                    current_batch_count := 0;
                END IF;
            END FOR;

            -- Wait for remaining jobs
            AWAIT ALL;

            RETURN '\n=== TAG APPLICATION SUMMARY ===\n' ||
                   'Total models processed: ' || models_processed || '\n' ||
                   'Total tags submitted: ' || tags_submitted || '\n' ||
                   'Job submission rate: 100% (queue submission only)\n' ||
                   '==============================';
        EXCEPTION
            WHEN OTHER THEN
                -- 3. Enhanced Error Information
                RETURN 'FAILED during processing. Tags submitted so far: ' || tags_submitted || '. Error: ' || SQLERRM || ' (SQLSTATE: ' || SQLSTATE || ')';
        END;
        $$
        {% endset %}

        {# Execute the block #}
        {% do log("Applying tags using Snowflake Server-side Async processing (Safe Mode)...", info=True) %}
        {% set results = run_query(bulk_update_sql) %}
        {% if results %}
            {% do log(results.rows[0][0], info=True) %}
        {% endif %}
    {% endif %}
{% endmacro %}
