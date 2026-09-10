{{ config(
    materialized='incremental',
    unique_key='test_unique_id',
    incremental_strategy='merge',
    tmp_relation_type='table'
    
   
    

) }}

{% if execute %}

{% set rows = [] %}
{% set relation_cache = {} %}

{% for node_id, node in graph.nodes.items() %}

    {% if node.resource_type == 'test' %}

        {% set parent = graph.nodes.get(node.attached_node) if node.attached_node else none %}

        {% if parent
            and parent.resource_type in ['model', 'source']
            and (
                parent.resource_type == 'source'
                
                or parent.original_file_path.startswith('models/bus_vault/pit_bridge/')
                or parent.original_file_path.startswith('models/bus_vault/pit/')
                or parent.original_file_path.startswith('models/raw_vault/')
                or parent.original_file_path.startswith('models/bus_vault/dim/')
                or parent.original_file_path.startswith('models/bus_vault/fact/')
            )
        %}

            {% if parent.resource_type == 'model' %}

                {% set model_database = parent.database %}
                {% set model_schema = parent.schema %}
                {% set model_table = parent.alias or parent.name %}
                {% set model_type = parent.config.materialized or 'table' %}
                {% set model_file_path = parent.original_file_path %}

            {% else %}

                {% set model_database = parent.database %}
                {% set model_schema = parent.schema %}
                {% set model_table = parent.name %}
                {% set model_type = 'source' %}
                {% set model_file_path = parent.original_file_path %}

            {% endif %}

            {% set test_name = node.test_metadata.name | lower if node.test_metadata else '' %}
            {% set tested_column = '' %}
            {% set accepted_values = '' %}
            {% set count_of_columns_in_pk = none %}
            {% set pk_data_types = {} %}
            {% set fk_pk_table_name = '' %}
            {% set fk_pk_column_name = '' %}

            {% if node.column_name is defined and node.column_name %}
                {% set tested_column = node.column_name %}
            {% endif %}

            {% if node.test_metadata
                and test_name == 'accepted_values'
                and node.test_metadata.kwargs.get('values') %}

                {% set accepted_values =
                    '[' ~ (node.test_metadata.kwargs.get('values') | join(', ')) ~ ']'
                %}

            {% endif %}

            {% if node.test_metadata
                and (
                    'primary_key' in test_name
                    or 'unique_combination' in test_name
                )
            %}

                {% set cols =
                    node.test_metadata.kwargs.get('column_names')
                    or node.test_metadata.kwargs.get('combination_of_columns')
                %}

                {% if cols %}

                    {% set tested_column = cols | join(',') %}
                    {% set count_of_columns_in_pk = cols | length %}

                    {% set relation_key =
                        model_database ~ '.' ~ model_schema ~ '.' ~ model_table
                    %}

                    {% if relation_key not in relation_cache %}

                        {% set relation = adapter.get_relation(
                            database=model_database,
                            schema=model_schema,
                            identifier=model_table
                        ) %}

                        {% if relation %}

                            {% do relation_cache.update({
                                relation_key:
                                adapter.get_columns_in_relation(relation)
                            }) %}

                        {% else %}

                            {% do relation_cache.update({
                                relation_key: []
                            }) %}

                        {% endif %}

                    {% endif %}

                    {% set columns_metadata = relation_cache[relation_key] %}

                    {% for col_name in cols %}

                        {% for c in columns_metadata %}

                            {% if c.name | lower == col_name | lower %}

                                {% do pk_data_types.update({
                                    col_name: c.data_type
                                }) %}

                            {% endif %}

                        {% endfor %}

                    {% endfor %}

                {% endif %}

            {% endif %}

{% if node.column_name is defined and node.column_name %}
    {% set tested_column = node.column_name %}
{% endif %}


{% if test_name == 'foreign_key' and not tested_column %}

    {% set tested_column =
        node.test_metadata.kwargs.get('column_name')
    %}

    {% if not tested_column
        and node.test_metadata.kwargs.get('fk_column_names')
    %}
        {% set tested_column =
            node.test_metadata.kwargs.get('fk_column_names')[0]
        %}
    {% endif %}

{% endif %}            

{% if node.test_metadata and test_name == 'foreign_key' %}

    {% set fk_pk_table_name =
    node.test_metadata.kwargs.get('pk_table_name', '')
%}

{% if not fk_pk_table_name %}
    {% set fk_pk_table_name =
        node.test_metadata.kwargs.get('to', '')
    %}
{% endif %}

    {% set fk_pk_column_name =
    node.test_metadata.kwargs.get('pk_column_name', '')
%}

{% if not fk_pk_column_name %}
    {% set fk_pk_column_name =
        node.test_metadata.kwargs.get('field', '')
    %}
{% endif %}

    
    {% if not fk_pk_column_name
        and node.test_metadata.kwargs.get('pk_column_names')
    %}
        {% set fk_pk_column_name =
            node.test_metadata.kwargs.get('pk_column_names')[0]
        %}
    {% endif %}

    {% if fk_pk_table_name %}

        {% set fk_pk_table_name = fk_pk_table_name | string %}

        {% set fk_pk_table_name =
            fk_pk_table_name
            | replace("ref('", "")
            | replace("ref( '", "")
            | replace('ref("', "")
            | replace("')", "")
            | replace("' )", "")
            | replace('")', "")
            | trim
        %}

    {% endif %}

{% endif %}

    
            {% do rows.append({

                "test_unique_id": node.unique_id,
                "test_name": node.name,
                "test_type": node.test_metadata.name if node.test_metadata else 'unknown',
                "tested_column": tested_column,
                "count_of_columns_in_pk": count_of_columns_in_pk,
                "pk_data_types_json": pk_data_types,
                "accepted_values": accepted_values,
                "model_database": model_database,
                "model_schema": model_schema,
                "model_table": model_table,
                "model_type": model_type,
                "fk_pk_table_name": fk_pk_table_name,
                "fk_pk_column_name": fk_pk_column_name,
                "model_file_path": model_file_path,
                "loaded_at": run_started_at|string

            }) %}

        {% endif %}

    {% endif %}

{% endfor %}

{% set json_payload = rows | tojson | replace("'", "''") %}

WITH source_data AS (

    SELECT
        value:test_unique_id::string as test_unique_id,
        value:test_name::string as test_name,
        value:test_type::string as test_type,
        value:tested_column::string as tested_column,
        value:count_of_columns_in_pk::number as count_of_columns_in_pk,
        value:pk_data_types_json::variant as pk_data_types_json,
        value:accepted_values::string as accepted_values,
        value:model_database::string as model_database,
        value:model_schema::string as model_schema,
        value:model_table::string as model_table,
        value:model_type::string as model_type,
        value:fk_pk_table_name::string as fk_pk_table_name,
        value:fk_pk_column_name::string as fk_pk_column_name,
        value:model_file_path::string as model_file_path,
        TO_TIMESTAMP(value:loaded_at::string) as loaded_at

    FROM LATERAL FLATTEN(
        input => PARSE_JSON('{{ json_payload }}')
    )

)

SELECT *
FROM source_data

{% if is_incremental() %}

WHERE test_unique_id NOT IN (

    SELECT test_unique_id
    FROM {{ this }}

)

{% endif %}

{% else %}

SELECT
    NULL as test_unique_id,
    NULL as test_name,
    NULL as test_type,
    NULL as tested_column,
    NULL as count_of_columns_in_pk,
    NULL as pk_data_types_json,
    NULL as fk_pk_table_name,
    NULL as fk_pk_column_name,
    NULL as accepted_values,
    NULL as model_database,
    NULL as model_schema,
    NULL as model_table,
    NULL as model_type,
    NULL as fk_pk_table_name,
    NULL as fk_pk_column_name,
     NULL as model_file_path,
     NULL as loaded_at
WHERE 1 = 0

{% endif %}