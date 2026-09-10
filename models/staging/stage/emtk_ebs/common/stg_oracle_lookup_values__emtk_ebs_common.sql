{%- set yaml_metadata -%}
source_model: 'base_oracle_lookup_values__emtk_ebs_common'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: '_fivetran_synced'
  brand: '!EMTEK'
  oracle_lookup_bk: ['lookup_type', 'lookup_code', 'view_application_id', 'meaning']
hashed_columns:
  oracle_lookup_hk: 
  - oracle_lookup_bk
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{% set source_model = metadata_dict['source_model'] %}
{% set derived_columns = metadata_dict['derived_columns'] %}
{% set hashed_columns = metadata_dict['hashed_columns'] %}

{{ automate_dv.stage(include_source_columns=true,
                     source_model=source_model,
                     derived_columns=derived_columns,
                     null_columns=none,
                     hashed_columns=hashed_columns,
                     ranked_columns=none) }}