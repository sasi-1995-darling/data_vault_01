{% macro promote_bkcc(source_db, target_db) %}
    {% set source_table = source_db ~ ".RAW_VAULT.REF_BUSINESS_KEY_COLLISION" %}
    {% set target_table = target_db ~ ".RAW_VAULT.REF_BUSINESS_KEY_COLLISION" %}
    
    {{ log("Starting BKCC promotion from " ~ source_db ~ " to " ~ target_db, info=True) }}
    
    -- Step 1: Delete records in target that don't exist in source
    {% set delete_sql %}
        DELETE FROM {{ target_table }}
        WHERE REC_SRC NOT IN (SELECT REC_SRC FROM {{ source_table }})
    {% endset %}
    
    {% set delete_result = run_query(delete_sql) %}
    {% set deleted_count = delete_result.rows[0][0] if delete_result.rows else 0 %}
    {{ log("Deleted records: " ~ deleted_count, info=True) }}
    
    -- Step 2: Insert new records from source that don't exist in target
    {% set insert_sql %}
        INSERT INTO {{ target_table }}
        SELECT * FROM {{ source_table }}
        WHERE REC_SRC NOT IN (SELECT REC_SRC FROM {{ target_table }})
    {% endset %}
    
    {% set insert_result = run_query(insert_sql) %}
    {% set inserted_count = insert_result.rows[0][0] if insert_result.rows else 0 %}
    {{ log("Inserted records: " ~ inserted_count, info=True) }}
    
    -- Step 3: Update existing records that have been modified in source
    {% set update_sql %}
        UPDATE {{ target_table }} target
        SET 
            REC_SRC_DESC = source.REC_SRC_DESC,
            BKCC = source.BKCC,
            DEACTIVATED_IND = source.DEACTIVATED_IND,
            DEACTIVATED_DATE = source.DEACTIVATED_DATE,
            LOAD_DATE = source.LOAD_DATE
        FROM {{ source_table }} source
        WHERE target.REC_SRC = source.REC_SRC
        AND (
            target.REC_SRC_DESC != source.REC_SRC_DESC OR
            target.BKCC != source.BKCC OR
            target.DEACTIVATED_IND != source.DEACTIVATED_IND OR
            COALESCE(target.DEACTIVATED_DATE, '1900-01-01'::DATE) != COALESCE(source.DEACTIVATED_DATE, '1900-01-01'::DATE) OR
            target.LOAD_DATE != source.LOAD_DATE
        )
    {% endset %}
    
    {% set update_result = run_query(update_sql) %}
    {% set updated_count = update_result.rows[0][0] if update_result.rows else 0 %}
    {{ log("Updated records: " ~ updated_count, info=True) }}
    
    {{ log("✅ BKCC Promotion completed - Deleted: " ~ deleted_count ~ ", Inserted: " ~ inserted_count ~ ", Updated: " ~ updated_count, info=True) }}
    
    {% do return({"deleted": deleted_count, "inserted": inserted_count, "updated": updated_count}) %}
{% endmacro %}