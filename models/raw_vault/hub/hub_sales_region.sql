{%- set source_model = ["stg_sales_region__emtk_ebs_sales"] -%}
{%- set src_pk = "sales_region_hk" -%}
{%- set src_nk = ["sales_region_bk","brand"] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                   src_source=src_source, source_model=source_model) }}