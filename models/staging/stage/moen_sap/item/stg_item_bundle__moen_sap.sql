{%- set yaml_metadata -%}

source_model: 'base_item_bundle__moen_sap'
derived_columns:
    rec_src: "!FILE"
    load_dts: current_timestamp()
    item_bundle_id: parent_material_number
    item_id: child_material_number
hashed_columns:
    item_bundle_hk: 
        - customer
        - item_bundle_id
        - item_id
    hdiff:
        is_hashdiff: true
        columns:
            - customer
            - item_bundle_id
            - item_id
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{% set source_model = metadata_dict["source_model"] %}
{% set derived_columns = metadata_dict["derived_columns"] %}
{% set hashed_columns = metadata_dict["hashed_columns"] %}

{{
    automate_dv.stage(
        include_source_columns=true,
        source_model=source_model,
        derived_columns=derived_columns,
        hashed_columns=hashed_columns,
        ranked_columns=none,
    )
}}