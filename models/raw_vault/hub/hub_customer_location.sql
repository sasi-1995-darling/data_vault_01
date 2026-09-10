{%- set yaml_metadata -%}

source_model: 
    - stg_pos_customer_location__ferguson_extract
    - stg_pos_customer_location__hd_askuity
    - stg_pos_customer_location__lowes
src_pk: customer_location_hk
src_nk: 
    - location_bk
    - customer
src_ldts: load_dts
src_source: rec_src
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.hub(src_pk=metadata_dict["src_pk"],
                   src_nk=metadata_dict["src_nk"], 
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}
                   