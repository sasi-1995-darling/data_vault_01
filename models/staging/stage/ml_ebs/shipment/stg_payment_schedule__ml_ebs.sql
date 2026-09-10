{%- set yaml_metadata -%}

source_model: 'base_payment_schedule__ml_ebs'
derived_columns:
    rec_src: "!ML EBS"
    brand: '!TMLC'
    load_dts: current_timestamp()
    payment_schedule_bk: to_char(customer_trx_id)
hashed_columns:
    payment_schedule_hk: payment_schedule_bk
    hash_diff:
        is_hashdiff: true
        columns:
        - payment_schedule_id
        - gl_date
        - class
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.stage(include_source_columns=true,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns']) }}
