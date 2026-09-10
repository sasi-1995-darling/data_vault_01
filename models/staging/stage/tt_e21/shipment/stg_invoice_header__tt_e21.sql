{%- set yaml_metadata -%}

source_model: 'base_invoice_header__tt_e21'
derived_columns:
    rec_src: "!TT E21TRUBIS"
    brand: '!THTRU'
    load_dts: current_timestamp()
    invoice_bk: invoice_numb
hashed_columns:
    invoice_hk: 
        - invoice_bk
        - brand
    hdiff:
        is_hashdiff: true
        columns:
            - 'mstr_inv_numb'
            - 'invoice_numb'
            - 'order_date'
            - 'ship_date'
            - 'post_date'
            - 'schfld5'
            - 'cost_ctr'
            - 'invc_type'
            - 'cust_code'
            - 'billto_code'
            - 'order_numb'
            - 'carr_code'
            - 'met_of_ship'
            - 'terms_code'
            - 'billname'
            - 'billadd1'
            - 'billadd2'
            - 'billadd3'
            - 'billcity'
            - 'billst'
            - 'billzip'
            - 'billcountry'
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
