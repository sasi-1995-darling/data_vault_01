{%- set source_model = "stg_sales_agency_groups__emtk_ebs_sales" -%}
{%- set src_pk = "sales_agency_groups_hk" -%}
{%- set src_fk = ["sales_agency_hk", "sales_region_hk", "sales_territory_hk"] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
