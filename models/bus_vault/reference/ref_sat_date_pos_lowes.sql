{{ config(materialized='table') }}

{%- set yaml_metadata -%}
source_model: 'stg_date__pos_lowes'
src_pk: 'date_bk'
src_extra_columns: 
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
    - hdiff
src_ldts: 'load_dts'
src_source: 'rec_src'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.ref_table(src_pk=metadata_dict["src_pk"],
                   src_extra_columns=metadata_dict["src_extra_columns"], 
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}