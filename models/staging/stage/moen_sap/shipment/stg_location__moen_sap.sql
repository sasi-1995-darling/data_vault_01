{%- set yaml_metadata -%}

source_model: 'base_location__moen_sap'
derived_columns:
    address1: 'street'
    city: 'city1'
    state: 'region'
    zipcode: 'post_code1'
    country: 'country'
    language: 'langu'
    nation: 'nation'
    location_id: addrnumber
    location_bk: location_id
    rec_src: "!MOEN SAP"
    brand: '!MOEN'
    load_dts: current_timestamp()
hashed_columns:
    location_hk: 
        - location_bk
        - brand
    address_number_hk: location_id
    hdiff:
        is_hashdiff: true
        columns:
        - 'location_id'
        - 'address1'
        - 'city'
        - 'state'
        - 'zipcode'
        - 'country'
        - 'language'
        - 'nation'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.stage(include_source_columns=false,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns']) }}
