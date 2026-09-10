{%- set yaml_metadata -%}

source_model: 'base_hr_all_organization_units__ml_ebs'
derived_columns:
    rec_src: "!ML EBS"
    load_dts: current_timestamp()
    brand: '!TMLC'
hashed_columns:
    plant_hk: 
        - plant_id
        - brand
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.stage(include_source_columns=true,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns']) }}
