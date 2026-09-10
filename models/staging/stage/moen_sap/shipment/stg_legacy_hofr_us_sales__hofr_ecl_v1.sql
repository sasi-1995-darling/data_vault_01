{%- set yaml_metadata -%}

source_model: 'base_legacy_hofr_us_sales__hofr_ecl_v1'
derived_columns:
    load_dts: current_timestamp()
    item_bk: item_number1
    customer_bk: customer_number
    copa_sales_bk:
        - invoice_no
        - unique_key
    cust_sales_area_bk:
        - customer_number
        - '!ROHS'
        - '!WH'
        - '!FS'
    item_cust_shipment_bk:
        - item_number1
        - customer_number
        - invoice_no
        - unique_key
        - customer_number
        - bkcc
hashed_columns:
    item_hk: 
        - item_bk
        - bkcc
    customer_hk:
        - customer_bk
        - bkcc
    copa_sales_hk: 
        - copa_sales_bk
        - bkcc
    cust_sales_area_hk: 
        - cust_sales_area_bk
        - bkcc
    item_cust_shipment_hk:
        - item_cust_shipment_bk
        - bkcc
    hdiff:
        is_hashdiff: true
        columns:
            - 'fiscaldate_key'
            - 'datasource'
            - 'datatype'
            - 'customer_number'
            - 'customer'
            - 'item'
            - 'qty'
            - 'sales'
            - 'cogs'
            - 'shpstate'
            - 'state'
            - 'company'
            - 'date'
            - 'year'
            - 'month'
            - 'ferg_or_non_ferg'
            - 'product_group'
            - 'brand_forecast'
            - 'customer_forecast'
            - 'universal_customer_name'
            - 'agency'
            - 'agency_temp'
            - 'region'
            - 'territory'
            - 'buying_group1'
            - 'original_zip'
            - 'program_level1'
            - 'channel'
            - 'msa'
            - 'sapcode'
            - 'month_week'
            - 'branch'
            - 'week_number'
            - 'buying_group2'
            - 'program_level2'
            - 'invoice_no'
            - 'required_date'
            - 'order_date'
            - 'customer_key'
            - 'customer_description'
            - 'customersaleskey'
            - 'item_desc'
            - 'base_material_description'
            - 'item_number_temp'
            - 'item_number2'
            - 'material_key'
            - 'shipped_qty'
            - 'gross_sales_before_freight'
            - 'fp_fiscal_year'
            - 'unique_key'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{% set source_model = metadata_dict["source_model"] %}
{% set derived_columns = metadata_dict["derived_columns"] %}
{% set hashed_columns = metadata_dict["hashed_columns"] %}

{{
    automate_dv.stage(
        include_source_columns=true,
        source_model=source_model,
        derived_columns=derived_columns,
        hashed_columns=hashed_columns,
        ranked_columns=none,
    )
}}
