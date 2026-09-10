{%- set source_model = "stg_supplier_contact__emtk_ebs_po" -%}
{%- set src_pk = "suplier_contact_hk" -%}
{%- set src_fk = ["supplier_hk", "contact_hk"] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
