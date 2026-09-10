{%- set yaml_metadata -%}

source_model: 
    - 'stg_plant__moen_sap' 
    - 'stg_shipment__moen_sap'
src_pk: plant_hk
src_nk: 
    - plant_bk
    - brand
src_ldts: load_dts
src_source: rec_src
{%- endset -%}


{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.hub(src_pk=metadata_dict["src_pk"],
                   src_nk=metadata_dict["src_nk"], 
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}