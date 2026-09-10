{%- set source_model = "stg_linkreview_sentiment__delighted_edp" -%}
{%- set src_pk = "link_review_sentiment_hk" -%}
{%- set src_fk = ["review_hk", "sentiment_hk"] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
