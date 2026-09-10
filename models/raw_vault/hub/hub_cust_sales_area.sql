{%- set yaml_metadata -%}

source_model: 
    - stg_cust_sales_area__moen_sap
    - stg_shipment__moen_sap
    - stg_shipment_inputs__moen_sap
    - stg_legacy_hofr_us_sales__hofr_ecl
src_pk: cust_sales_area_hk
src_nk: 
    - cust_sales_area_bk
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