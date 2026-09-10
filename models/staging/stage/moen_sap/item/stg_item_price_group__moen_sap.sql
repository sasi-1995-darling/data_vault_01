{%- set yaml_metadata -%}

source_model: 'base_item_price_group__moen_sap'
derived_columns:
    rec_src: "!MOEN SAP"
    load_dts: current_timestamp()
    item_price_type_group_id: zzptg
    price_type_group: UPPER(txt30)
    language: spras
hashed_columns:
    item_price_type_group_id_hk: item_price_type_group_id
    hdiff:
        is_hashdiff: true
        columns:
           - 'item_price_type_group_id'
           - 'price_type_group'
           - 'language'
           
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{% set source_model = metadata_dict["source_model"] %}
{% set derived_columns = metadata_dict["derived_columns"] %}
{% set hashed_columns = metadata_dict["hashed_columns"] %}

{{
    automate_dv.stage(
        include_source_columns=false,
        source_model=source_model,
        derived_columns=derived_columns,
        hashed_columns=hashed_columns,
        ranked_columns=none,
    )
}}