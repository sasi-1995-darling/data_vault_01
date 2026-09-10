{%- set yaml_metadata -%}

source_model: 'stg_cust_sales_area__moen_sap'
src_pk: 
    - cust_sales_area_hk
src_hashdiff: 
  source_column: hdiff
  alias: hdiff
src_payload:
    - customer_number
    - customer_desc
    - address_number
    - language
    - customer_account_name
    - customer_account_number
    - sales_org
    - dist_channel
    - division
    - sales_region
    - sales_district
    - address_number_hk
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
