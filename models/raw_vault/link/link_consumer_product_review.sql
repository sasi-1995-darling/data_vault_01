{%- set source_model = "stg_linkconsumer_product_review__delighted_edp" -%}

{%- set src_pk = "link_consumer_product_review_hk" -%}
{%- set src_fk = ["consumer_hk", "product_hk", "review_hk"] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}
{{ automate_dv.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}