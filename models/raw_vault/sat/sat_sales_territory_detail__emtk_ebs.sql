{%- set source_model = "stg_sales_territory__emtk_ebs_sales" -%}
{%- set src_pk = "sales_territory_hk" -%}
{%- set src_hashdiff = "sales_territory_hdiff" -%}
{%- set src_payload = [ 
     'segment1',
     'territory_id',
     'last_update_date',
     'creation_date',
     'last_update_login',
     'name',
     'description'  ] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.sat(src_pk=src_pk, src_hashdiff=src_hashdiff,
                   src_payload=src_payload, src_eff=none,
                   src_ldts=src_ldts, src_source=src_source,
                   source_model=source_model) }}
