{%- set source_model = "stg_po_line_item_plant_location__emtk_ebs_po" -%}
{%- set src_pk = "po_line_item_plant_location_hk" -%}
{%- set src_fk = ["po_line_hk", "plant_location_hk", "item_hk"] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
