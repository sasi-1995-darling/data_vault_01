{%- set source_model = "stg_invoice_line_transaction__emtk_ebs_sales" -%}
{%- set src_pk = "invoice_line_transaction_hk" -%}
{%- set src_fk = ["invoice_line_hk"] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
