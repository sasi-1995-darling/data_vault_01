{%- set source_model = ["stg_contact__emtk_ebs_common"] -%}
{%- set src_pk = "contact_hk" -%}
{%- set src_nk = ["contact_bk","brand"] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                   src_source=src_source, source_model=source_model) }}