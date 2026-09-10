{%- set source_model = ["stg_invoice_adjustment__emtk_ebs_sales"] -%}
{%- set src_pk = "invoice_adjustment_hk" -%}
{%- set src_nk = ["invoice_adjustment_bk","brand"] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                   src_source=src_source, source_model=source_model) }}