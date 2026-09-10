{{ config(materialized='table') }}

{%- set yaml_metadata -%}
source_model: 'stg_date__fbin'
src_pk: 'date_bk'
src_extra_columns: 
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