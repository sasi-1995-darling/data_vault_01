{%- set yaml_metadata -%}

source_model: 'base_cust_cgrp__lrsn_psft'
derived_columns:
    rec_src: "!LRSN PSFT"
    brand: '!LRSN'
    load_dts: current_timestamp()
    customer_bk: cust_id
hashed_columns:
    customer_hk:
        - customer_bk
        - brand
    hdiff:
        is_hashdiff: true
        columns:
            - 'setid'
            - 'cust_id'
            - 'cust_grp_type'
            - 'customer_group'
            - 'default_tax_grp'
            - 'datetime_added'
            - 'lastupddttm'
            - 'last_maint_oprid'
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
