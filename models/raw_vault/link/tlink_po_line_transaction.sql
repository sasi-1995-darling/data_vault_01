{%- set source_model = "stg_po_line_transaction__emtk_ebs_po" -%}
{%- set src_pk = "po_line_transaction_link_hk" -%}
{%- set src_fk = ["po_line_transaction_hk", "po_line_hk"] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.t_link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
