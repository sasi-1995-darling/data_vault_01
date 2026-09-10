{%- set yaml_metadata -%}

source_model: 'stg_invoice_header__tt_e21'
src_pk: 
    - invoice_hk
src_hashdiff: 
  source_column: hdiff
  alias: hdiff
src_payload:
    - mstr_inv_numb
    - invoice_numb
    - order_date
    - ship_date
    - post_date
    - schfld5
    - multiplier
    - cost_ctr
    - invc_type
    - cust_code
    - billto_code
    - order_numb
    - carr_code
    - met_of_ship
    - terms_code
    - billname
    - billadd1
    - billadd2
    - billadd3
    - billcity
    - billst
    - billzip   
    - billcountry
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
