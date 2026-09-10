{%- set yaml_metadata -%}

source_model: 'stg_legacy_hofr_us_sales__hofr_ecl_v1'
src_pk: 
    - copa_sales_hk
src_hashdiff: 
  source_column: hdiff
  alias: hdiff
src_payload:
    - fiscaldate_key
    - datasource
    - datatype
    - customer_number
    - customer
    - item
    - item_number1
    - qty
    - sales
    - cogs
    - shpstate
    - state
    - company
    - date
    - year
    - month
    - ferg_or_non_ferg
    - product_group
    - brand_forecast
    - customer_forecast
    - universal_customer_name
    - agency
    - agency_temp
    - region
    - territory
    - buying_group1
    - original_zip
    - program_level1
    - channel
    - msa
    - sapcode
    - month_week
    - branch
    - week_number
    - buying_group2
    - program_level2
    - invoice_no
    - required_date
    - order_date
    - customer_key
    - customer_description
    - customersaleskey
    - item_desc
    - base_material_description
    - item_number_temp
    - item_number2
    - material_key
    - shipped_qty
    - gross_sales_before_freight
    - fp_fiscal_year
    - unique_key
    - bkcc
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
