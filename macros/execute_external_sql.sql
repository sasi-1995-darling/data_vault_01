{% macro execute_external_sql() %}

{%- if target.name.lower() in ('qa','prod') -%}

    {% set query %}
        SELECT id, sql_statement
        FROM metadata.external_sql
        WHERE processed_on IS NULL
    {% endset %}
    {% set results = run_query(query) %}

    {% if execute %}
        {% if results.rows %}
            {% for row in results.rows %}
                {% set sql_statement = row[1] %}
                {% if sql_statement %}
                    {{ log("Executing SQL statement: " ~ sql_statement) }}
                    {% set execution_response = run_query(sql_statement) %}
                    {{ log("Execution response: " ~ execution_response) }}
                    {% if execution_response.rows %}
                        {% set response_message = execution_response.rows | map(attribute=0) | join(', ') %}
                        {% set update_query %}
                            UPDATE metadata.external_sql
                            SET processed_on = CURRENT_TIMESTAMP(),
                                sql_status = '{{ response_message }}'
                            WHERE id = {{ row[0] }}
                        {% endset %}
                        {{ log("Executing update query: " ~ update_query) }}
                        {% set update_response = run_query(update_query) %}
                        {{ log("Update response: " ~ update_response) }}
                        {% if not update_response %}
                            {{ log("Failed to update external_sql table for id " ~ row[0]) }}
                        {% endif %}
                    {% else %}
                        {{ log("Failed to execute SQL statement for id " ~ row[0]) }}
                    {% endif %}
                {% endif %}
            {% endfor %}
        {% endif %}
    {% endif %}
{% endif %}

{% endmacro %}
