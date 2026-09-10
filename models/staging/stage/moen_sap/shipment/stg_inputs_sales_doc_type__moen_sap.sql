{%- set yaml_metadata -%}

source_model: 'base_inputs_sales_doc_type__moen_sap'
derived_columns:
    rec_src: "!MOEN SAP"
    load_dts: current_timestamp()
    sales_doc_type_code: auart
    sales_doc_type_desc: bezei
    language: spras
    delete_flag: gldelflag
hashed_columns:
    hdiff:
        is_hashdiff: true
        columns:
           - 'sales_doc_type_code'
           - 'sales_doc_type_desc'
           - 'language'
           - 'delete_flag'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.stage(include_source_columns=false,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns']) }}
