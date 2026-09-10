{% macro set_alation_active_tags() %}
    {#
    The Alation - Snowflake metadata extraction will pull tag data from Snowflake.  When a tag is created/edited/deleted it will not show up in the
    SNOWFLAKE.ACCOUNT_USAGE.TAG_REFERENCES table right away.  The problem with this is when the nightly DBT job runs it takes more than 1 hour.  By
    the time the code runs that reactivates the tags some tables could already be marked as deleted (based on how DBT recreates tables).  In order to 
    handle this situation we need to take a snapshot of the tags before process runs.  This ALATION_INTEGRATION.METADATA.ACTIVE_TAGS will be that snapshot.
    Before every DBT run we will truncate this table and reload it based on the SNOWFLAKE.ACCOUNT_USAGE.TAG_REFERENCES table.
    #}
        {% set active_tags_query %}
            INSERT OVERWRITE INTO ALATION_INTEGRATION.METADATA_CATALOG.ACTIVE_TAGS
                SELECT 
                    TAG_DATABASE, 
                    TAG_SCHEMA, 
                    TAG_ID, 
                    TAG_NAME, 
                    TAG_VALUE, 
                    OBJECT_DATABASE, 
                    OBJECT_SCHEMA, 
                    OBJECT_ID, 
                    OBJECT_NAME, 
                    OBJECT_DELETED, 
                    DOMAIN, 
                    COLUMN_ID, 
                    COLUMN_NAME, 
                    APPLY_METHOD, 
                    OBJECT_DATABASE || '.' || OBJECT_SCHEMA || '.' || OBJECT_NAME AS db_schema_object,
                    CURRENT_TIMESTAMP() AS CREATED_AT
                FROM SNOWFLAKE.ACCOUNT_USAGE.TAG_REFERENCES 
                WHERE OBJECT_DATABASE IS NOT NULL 
                    AND OBJECT_SCHEMA IS NOT NULL 
                    AND OBJECT_NAME IS NOT NULL 
                    AND OBJECT_DELETED IS NULL
                    AND OBJECT_DATABASE IN ('INFOMART_PROD', 'DATAVAULT_PROD'); 
        {% endset %}
        {% set results = run_query(active_tags_query) %}
        {% do log("ALATION_INTEGRATION.METADATA_CATALOG.ACTIVE_TAGS was repopulated", info=True)%}
{% endmacro %}