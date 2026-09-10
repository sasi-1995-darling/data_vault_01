{%- set source_model = ["stg_plant_location__emtk_ebs_po"] -%}
{%- set src_pk = "plant_location_hk" -%}
{%- set src_nk = ["plant_location_bk","brand"] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                   src_source=src_source, source_model=source_model) }}
