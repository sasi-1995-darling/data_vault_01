{%- set yaml_metadata -%}

source_model: 
    - stg_shipment__moen_sap_v1
    - stg_shipment__moen_sap_azcopa_history
    - stg_legacy_hofr_us_sales__hofr_ecl_v1
src_pk: copa_sales_hk
src_nk: 
    - copa_sales_bk
    - bkcc
src_ldts: load_dts
src_source: rec_src
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.hub(src_pk=metadata_dict["src_pk"],
                   src_nk=metadata_dict["src_nk"], 
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}