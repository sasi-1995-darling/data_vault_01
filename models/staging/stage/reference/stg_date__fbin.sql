{%- set yaml_metadata -%}

source_model: 'base_date__fbin'
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
            - FBIN_CAL_DAY
            - FBIN_CAL_WEEK
            - FBIN_CAL_MONTH
            - FBIN_CAL_QUARTER
            - FBIN_CAL_YEAR
            - FBIN_CAL_QUARTER_YYYYQQ
            - FBIN_CAL_MONTH_YYYYMM
            - FBIN_CAL_WEEK_YYYYWW
            - FBIN_WORKING_DAY_FLAG
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