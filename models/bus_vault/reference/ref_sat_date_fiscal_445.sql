{{ config(materialized='table') }}

{%- set yaml_metadata -%}
source_model: 'stg_date__fiscal_445'
src_pk: 'date_bk'
src_extra_columns: 
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