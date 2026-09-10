{%- set yaml_metadata -%}

source_model: 'base_item_reporting_category__moen_sap'
derived_columns:
    rec_src: "!MOEN SAP"
    load_dts: current_timestamp()
    reporting_category_id: zzrepcatg
    reporting_category: zzrepcatgd
    language: spras
hashed_columns:
    reporting_category_id_hk: reporting_category_id
    hdiff:
        is_hashdiff: true
        columns:
           - 'reporting_category_id'
           - 'reporting_category'
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