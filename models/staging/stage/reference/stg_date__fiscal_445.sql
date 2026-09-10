{%- set yaml_metadata -%}

source_model: 'base_date__fiscal_445'
derived_columns:
    load_dts: LOAD_DTS
    rec_src: PSA_RECORD_SOURCE
    date_bk:
        - datekey
hashed_columns:
    hdiff:
        is_hashdiff: true
        columns:
            - DATE
            - FISCAL_445_CAL_DAY
            - FISCAL_445_CAL_WEEK
            - FISCAL_445_CAL_MONTH
            - FISCAL_445_CAL_QUARTER
            - FISCAL_445_CAL_YEAR
            - FISCAL_445_CAL_QUARTER_YYYYQQ
            - FISCAL_445_CAL_MONTH_YYYYMM
            - FISCAL_445_CAL_WEEK_YYYYWW
            - FISCAL_445_WORKING_DAY_FLAG
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{
    automate_dv.stage(
        include_source_columns=true,
        source_model=metadata_dict["source_model"],
        derived_columns=metadata_dict["derived_columns"],
        hashed_columns=metadata_dict["hashed_columns"],
    )
}}