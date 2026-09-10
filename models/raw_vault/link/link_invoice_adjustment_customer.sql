{%- set source_model = "stg_invoice_adjustment_customer__emtk_ebs_sales" -%}
{%- set src_pk = "invoice_adjustment_customer_hk" -%}
{%- set src_fk = ["invoice_adjustment_hk", "customer_hk", "customer_bill_location_hk"] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
