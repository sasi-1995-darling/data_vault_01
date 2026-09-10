{%- set source_model = "stg_linkreviewbrand__appbot_api" -%}
{%- set src_pk = "link_review_brand_hk" -%}
{%- set src_fk = ["review_hk", "brand_hk"] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}
{{ automate_dv.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
