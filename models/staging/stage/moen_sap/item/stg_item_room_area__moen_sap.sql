{%- set yaml_metadata -%}

source_model: 'base_item_room_area__moen_sap'
derived_columns:
    rec_src: "!MOEN SAP"
    load_dts: current_timestamp()
    room_area_id: zzrmarea
    room_area: UPPER(zzrmarea_desc)
hashed_columns:
    room_area_id_hk: room_area_id
    hdiff:
        is_hashdiff: true
        columns:
           - 'room_area_id'
           - 'room_area'
           
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