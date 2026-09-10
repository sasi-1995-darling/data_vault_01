{% macro relation_exists(schema, identifier) %}
    {% set relation = adapter.get_relation(
        database=target.database,
        schema=schema,
        identifier=identifier
    ) %}
    {% if relation is not none %}
        {{ return(true) }}
    {% else %}
        {{ return(false) }}
    {% endif %}
{% endmacro %}