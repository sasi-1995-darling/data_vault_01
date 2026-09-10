{%- set yaml_metadata -%}

source_model: 'stg_customer__tt_e21'
src_pk: 
    - customer_hk
src_hashdiff: 
  source_column: customer_hdiff
  alias: hashdiff
src_payload:
    - cp_name
    - status_ind
    - add_date
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
