{%- set source_model = "stg_purchase_order__emtk_ebs_po" -%}
{%- set src_pk = "po_supplier_link_hk" -%}
{%- set src_fk = ["purchase_order_hk", "supplier_hk", "supplier_site_hk"] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
