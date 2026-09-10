{%- set yaml_metadata -%}

source_model: 'stg_location__moen_sap_v1'
src_pk: 
    - location_hk
src_hashdiff: 
  source_column: hdiff
  alias: hdiff
src_payload:
    - location_id
    - address1
    - city
    - state
    - zipcode
    - country
    - language
    - nation
    - address_number_hk
    - bkcc
src_ldts: load_dts
src_source: rec_src
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.sat(src_pk=metadata_dict["src_pk"],
                   src_hashdiff=metadata_dict["src_hashdiff"],
                   src_payload=metadata_dict["src_payload"],
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}
