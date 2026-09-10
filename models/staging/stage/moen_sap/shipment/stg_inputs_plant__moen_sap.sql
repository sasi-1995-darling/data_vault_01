{%- set yaml_metadata -%}

source_model: 'base_inputs_plant__moen_sap'
derived_columns:
    rec_src: "!MOEN SAP"
    load_dts: current_timestamp()
    plant_id: werks
    plant_name: name1
    language: spras
    delete_flag: gldelflag
hashed_columns:
    hdiff:
        is_hashdiff: true
        columns:
           - 'plant_id'
           - 'plant_name'
           - 'language'
           - 'delete_flag'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.stage(include_source_columns=false,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns']) }}
