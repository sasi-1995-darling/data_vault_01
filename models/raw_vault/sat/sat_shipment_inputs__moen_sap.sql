{%- set yaml_metadata -%}

source_model: 'stg_shipment_inputs__moen_sap'
src_pk: 
    - shipment_inputs_hk
src_hashdiff: 
  source_column: hdiff
  alias: hdiff
src_payload:
    - plant_id
    - order_date
    - issue_date
    - doc_number
    - line_number
    - sales_document_type
    - rejection_id
    - uom
    - currency
    - ordered_units
    - outted_units
    - sales_dollars
    - gross_input_dollars
    - outted_dollars
    - sales_org
    - channel
    - division
    - sales_doc_item_cat
    - po_number
    - order_cat
    - combined_reason_code
    - type_of_sale
    - mandt
    - ssour
    - vrsio
    - spmon
    - sap_load_date
    - spwoc
    - spbup
    - stwae_01
src_ldts: load_dts
src_source: rec_src

{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.sat(src_pk=metadata_dict["src_pk"],
                   src_hashdiff=metadata_dict["src_hashdiff"],
                   src_payload=metadata_dict["src_payload"],
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}
