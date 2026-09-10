{%- set source_model = ["stg_supplier_site__emtk_ebs_po"] -%}
{%- set src_pk = "supplier_site_hk" -%}
{%- set src_nk = ["supplier_site_bk","brand"] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                   src_source=src_source, source_model=source_model) }}