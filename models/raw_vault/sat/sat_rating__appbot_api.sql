{%- set yaml_metadata -%}

source_model: stg_rating__appbot_api
src_pk: 
    - rating_hk
src_hashdiff: 
  source_column: hdiff
  alias: hdiff
src_payload:
    - country_id
    - country_code
    - cumulative_1_star
    - cumulative_2_star
    - cumulative_3_star
    - cumulative_4_star
    - cumulative_5_star
    - cumulative_reviews
    - cumulative_star_rating
src_ldts: load_dts
src_source: rec_src
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}
--

{{ automate_dv.sat(src_pk=metadata_dict["src_pk"],
                   src_hashdiff=metadata_dict["src_hashdiff"],
                   src_payload=metadata_dict["src_payload"],
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}
