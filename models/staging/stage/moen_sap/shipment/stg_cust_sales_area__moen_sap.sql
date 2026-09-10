{%- set yaml_metadata -%}

source_model: 'base_cust_sales_area__moen_sap'
derived_columns:
    customer_number: 'kunnr'
    customer_desc: 'name1'
    address_number: 'adrnr'
    language: 'spras'
    customer_account_name: 'zzacctname'
    customer_account_number: 'zzacct'
    sales_org: 'vkorg'
    dist_channel: 'vtweg'
    division: 'spart'
    sales_region: 'vkbur'
    sales_district: 'bzirk'
    rec_src: "!MOEN SAP"
    brand: '!MOEN'
    load_dts: current_timestamp()
    customer_bk: customer_number
    cust_sales_area_bk:
        - customer_number
        - sales_org
        - dist_channel
        - division
    customer_cust_sales_area_bk:
        - customer_number
        - customer_number
        - sales_org
        - dist_channel
        - division
hashed_columns:
    customer_hk:
        - customer_bk
        - brand
    cust_sales_area_hk: 
        - cust_sales_area_bk
        - brand
    customer_cust_sales_area_hk:
        - customer_cust_sales_area_bk
        - brand
    address_number_hk: address_number
    hdiff:
        is_hashdiff: true
        columns:
            - 'customer_number'
            - 'customer_desc'
            - 'address_number'
            - 'language'
            - 'customer_account_name'
            - 'customer_account_number'
            - 'sales_org'
            - 'dist_channel'
            - 'division'
            - 'sales_region'
            - 'sales_district'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{% set source_model = metadata_dict["source_model"] %}
{% set derived_columns = metadata_dict["derived_columns"] %}
{% set hashed_columns = metadata_dict["hashed_columns"] %}

{{
    automate_dv.stage(
        include_source_columns=false,
        source_model=source_model,
        derived_columns=derived_columns,
        hashed_columns=hashed_columns,
        ranked_columns=none,
    )
}}
