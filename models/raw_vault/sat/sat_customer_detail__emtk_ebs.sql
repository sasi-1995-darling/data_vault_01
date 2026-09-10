{%- set source_model = "stg_customer__emtk_ebs_sales" -%}
{%- set src_pk = "customer_hk" -%}
{%- set src_hashdiff = "customer_hdiff" -%}
{%- set src_payload = [ 
     'account_number',
     'cust_account_id',
     'party_id',
     'last_update_date',
     'last_updated_by',
     'creation_date',
     'created_by',
     'last_update_login',
     'request_id',
     'program_application_id',
     'program_id',
     'program_update_date',
     'attribute1',
     'attribute2',
     'attribute3',
     'attribute4',
     'attribute10',
     'attribute11',
     'attribute13',
     'attribute15',
     'attribute16',
     'attribute17',
     'attribute19',
     'attribute20',
     'orig_system_reference',
     'status',
     'customer_class_code',
     'freight_term',
     'ship_via',
     'payment_term_id',
     'tax_header_level_flag',
     'account_name',
     'account_replication_key',
     'object_version_number',
     'created_by_module',
     'application_id' ] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.sat(src_pk=src_pk, src_hashdiff=src_hashdiff,
                   src_payload=src_payload, src_eff=none,
                   src_ldts=src_ldts, src_source=src_source,
                   source_model=source_model) }}
