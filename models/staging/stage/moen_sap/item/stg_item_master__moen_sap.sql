{%- set yaml_metadata -%}

source_model: 'base_item_master__moen_sap'
derived_columns:
    rec_src: "!MOEN SAP"
    brand: '!MOEN'
    load_dts: current_timestamp()
    item_bk: item_id
hashed_columns:
    item_hk: 
        - item_bk
        - brand
    room_area_id_hk: room_area_id
    item_group_id_hk: item_group_id
    item_platform_id_hk: item_platform_id
    item_type_id_hk: item_type_id
    item_finish_id_hk: item_finish_id
    reporting_category_id_hk: reporting_category_id
    item_architecture_id_hk: item_architecture_id
    item_line_id_hk: item_line_id
    item_price_category_id_hk: item_price_category_id
    item_price_type_group_id_hk: item_price_type_group_id
    business_owner_id_hk: business_owner_id
    business_unit_id_hk: business_unit_id
    hdiff:
        is_hashdiff: true
        columns:
           - 'item_id'
           - 'room_area_id'
           - 'item_group_id'
           - 'item_platform_id'
           - 'item_type_id'
           - 'item_finish_id'
           - 'reporting_category_id'
           - 'item_architecture_id'
           - 'item_line_id'
           - 'item_price_category_id'
           - 'item_price_type_group_id'
           - 'business_owner_id'
           - 'business_unit_id'
           - 'imap_flag'
           - 'item_type_code'
           - 'base_material'
           - 'item_status'
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