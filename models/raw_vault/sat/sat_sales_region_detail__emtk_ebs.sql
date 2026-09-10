{%- set source_model = "stg_sales_region__emtk_ebs_sales" -%}
{%- set src_pk = "sales_region_hk" -%}
{%- set src_hashdiff = "sales_region_hdiff" -%}
{%- set src_payload = [ 
     'group_name',
     'group_id',
     'created_by',
     'creation_date',
     'last_updated_by',
     'last_update_date',
     'last_update_login',
     'group_desc'  ] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.sat(src_pk=src_pk, src_hashdiff=src_hashdiff,
                   src_payload=src_payload, src_eff=none,
                   src_ldts=src_ldts, src_source=src_source,
                   source_model=source_model) }}
