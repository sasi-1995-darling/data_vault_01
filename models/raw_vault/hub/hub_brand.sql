{%- set yaml_metadata -%}

source_model: 
    - stg_brand__ml_ebs
    - stg_brand__moen_sap
    - stg_brand__ref_appbot
    - stg_brand__ref_file

src_pk: brand_hk
src_nk: 
    - brand_bk
src_ldts: load_dts
src_source: rec_src
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.hub(src_pk=metadata_dict["src_pk"],
                   src_nk=metadata_dict["src_nk"], 
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}

