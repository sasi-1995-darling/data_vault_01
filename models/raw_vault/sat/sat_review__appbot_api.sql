{%- set yaml_metadata -%}

source_model: stg_review__appbot_api
src_pk: 
    - review_hk
src_hashdiff: 
  source_column: hdiff
  alias: hdiff
src_payload:
    - customer_product_id
    - app_store_id
    - author
    - star_rating
    - text
    - summary
    - published_at
    - published_at_datetime
    - version
    - country
    - country_id
    - country_code
    - translated_subject
    - translated_body
    - manufacturer_comment_text
    - manufacturer_comment_datekey
    - topics
    - topic_ids
    - store_id
    - device
    - device_friendly_name
    - os_version
    - os_version_friendly_name
    - sentiment
    - detected_language
    - detected_language_id
    - permalink_url
    - reply_url
    - internal_url
src_ldts: load_dts
src_source: rec_src
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.sat(src_pk=metadata_dict["src_pk"],
                   src_hashdiff=metadata_dict["src_hashdiff"],
                   src_payload=metadata_dict["src_payload"],
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}
