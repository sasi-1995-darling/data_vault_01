{%- set yaml_metadata -%}
source_model: stg_cust_sales_area__moen_sap
src_pk: customer_cust_sales_area_hk
src_fk: 
  - customer_hk
  - cust_sales_area_hk
src_ldts: load_dts
src_source: rec_src
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.link(src_pk=metadata_dict["src_pk"],
                    src_fk=metadata_dict["src_fk"], 
                    src_ldts=metadata_dict["src_ldts"],
                    src_source=metadata_dict["src_source"], 
                    source_model=metadata_dict["source_model"]) }}