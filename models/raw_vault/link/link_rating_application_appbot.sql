{%- set source_model = "stg_linkratingapp__appbot_api" -%}
{%- set src_pk = "link_rating_applist_details_hk" -%}
{%- set src_fk = ["rating_hk", "application_hk"] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
--