{%- set yaml_metadata -%}

source_model: stg_pos_ref_itemattributes__hd_askuity
src_pk: customer_sku_hk
src_extra_columns:
    - item_hk
    - sku_nbr
    - category
    - svp1
    - merch_dept1
    - class1_3
    - sub_class1_1
    - sku1_2
    - manuf_part_number
    - run_date
    - brand
src_ldts: load_dts
src_source: rec_src
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.ref_table(src_pk=metadata_dict["src_pk"],
                   src_extra_columns=metadata_dict["src_extra_columns"], 
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}