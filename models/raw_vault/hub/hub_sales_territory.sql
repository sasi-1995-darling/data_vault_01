{%- set source_model = ["stg_sales_territory__emtk_ebs_sales"] -%}
{%- set src_pk = "sales_territory_hk" -%}
{%- set src_nk = ["sales_territory_bk","brand"] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                   src_source=src_source, source_model=source_model) }}