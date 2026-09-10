{%- set yaml_metadata -%}
source_model: 'base_supplier_contact__emtk_ebs_po'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: '_fivetran_synced'
  brand: '!EMTEK'
  supplier_bk: 'segment1'
  contact_bk: 'contact_point_id'  
hashed_columns:
  suplier_contact_hk: 
    columns:
    - 'supplier_bk'
    - 'contact_bk'    
    - 'brand'     
  supplier_hk: 
    columns:
    - 'supplier_bk'
    - 'brand'    
  contact_hk: 
    columns:
    - 'contact_bk'
    - 'brand'    
         
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{% set source_model = metadata_dict['source_model'] %}
{% set derived_columns = metadata_dict['derived_columns'] %}
{% set hashed_columns = metadata_dict['hashed_columns'] %}

{{ automate_dv.stage(include_source_columns=true,
                     source_model=source_model,
                     derived_columns=derived_columns,
                     null_columns=none,
                     hashed_columns=hashed_columns,
                     ranked_columns=none) }}
