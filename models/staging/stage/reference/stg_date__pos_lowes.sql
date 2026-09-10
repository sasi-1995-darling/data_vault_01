{%- set yaml_metadata -%}

source_model: 'base_date__pos_lowes'
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
            - LOWES_CAL_DAY
            - LOWES_CAL_WEEK
            - LOWES_CAL_MONTH
            - LOWES_CAL_YEAR
            - LOWES_CAL_QUARTER
            - LOWES_445_CAL_QUARTER_YYYYQQ
            - LOWES_445_CAL_MONTH_YYYYMM
            - LOWES_445_CAL_WEEK_YYYYWW
            - LOWES_WORKING_DAY_FLAG
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