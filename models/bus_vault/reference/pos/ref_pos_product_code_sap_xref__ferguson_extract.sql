{%- set yaml_metadata -%}

source_model: stg_pos_product_code_sap_xref__ferguson_extract
src_pk: xref_id
src_extra_columns: 
    - _modified
    - fei_product_code
    - sap_material_number
    - sap_account_number
src_ldts: load_dts
src_source: rec_src
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.ref_table(src_pk=metadata_dict["src_pk"],
                   src_extra_columns=metadata_dict["src_extra_columns"], 
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}
