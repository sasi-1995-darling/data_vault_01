{%- set source_model = ["stg_sales_agency__emtk_ebs_sales"] -%}
{%- set src_pk = "sales_agency_hk" -%}
{%- set src_nk = ["sales_agency_bk","brand"] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                   src_source=src_source, source_model=source_model) }}