{%- set yaml_metadata -%}

source_model: 
    - stg_systems_items__ml_ebs
    - stg_partmstr__tt_e21
    - stg_item_base__emtk_ebs_common
    - stg_item_master__moen_sap
    - stg_shipment__moen_sap
    - stg_shipment_inputs__moen_sap
    - stg_inv_items__lrsn_psft
    - stg_master_item__lrsn_psft
    - stg_prod_grp__lrsn_psft
    - stg_prod_item__lrsn_psft
    - stg_sp_prod__lrsn_psft
    - stg_bi_line__lrsn_psft
src_pk: item_hk
src_nk: 
    - item_bk
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
