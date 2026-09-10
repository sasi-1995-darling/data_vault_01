{%- set yaml_metadata -%}

source_model: 'base_shipment_inputs__moen_sap'
derived_columns:
    customer_id: 'kunnr'
    item: 'matnr'
    plant_id: 'werks'
    order_date: 'erdat'
    issue_date: 'wadat'
    doc_number: 'vbeln '
    line_number: 'posnr'
    sales_document_type: 'auart'
    rejection_id: 'abgru'
    uom: 'vrkme'
    currency: 'waerk'
    ordered_units: 'kwmeng'
    outted_units: 'zout_qty'
    sales_dollars: 'netwr'
    gross_input_dollars: 'z532_kwert'
    outted_dollars: 'zout_dol'
    sales_org: 'vkorg'
    channel: 'vtweg'
    division: 'spart'
    sales_doc_item_cat: 'pstyv'
    po_number: 'bstnk'
    order_cat: 'zzorc'
    combined_reason_code: 'wwrsn'
    type_of_sale: 'wwstp'
    mandt: 'mandt'
    ssour: 'ssour'
    vrsio: 'vrsio'
    spmon: 'spmon'
    sap_load_date: 'sptag'
    spwoc: 'spwoc'
    spbup: 'spbup'
    stwae_01: 'stwae_01'
    rec_src: "!MOEN SAP"
    brand: '!MOEN'
    load_dts: current_timestamp()
    item_bk: item
    customer_bk: customer_id
    shipment_inputs_bk:
        - mandt
        - ssour
        - vrsio
        - spmon
        - sap_load_date
        - spwoc
        - spbup
        - customer_id
        - item
        - plant_id
        - issue_date
        - doc_number
        - line_number
        - sales_document_type
        - stwae_01
        - rejection_id
    cust_sales_area_bk:
        - customer_id
        - sales_org
        - channel
        - division
    item_cust_shipment_inputs_bk:
        - item
        - customer_id
        - mandt
        - ssour
        - vrsio
        - spmon
        - sap_load_date
        - spwoc
        - spbup
        - customer_id
        - item
        - plant_id
        - issue_date
        - doc_number
        - line_number
        - sales_document_type
        - stwae_01
        - rejection_id
        - customer_id
        - sales_org
        - channel
        - division
hashed_columns:
    item_hk: 
        - item_bk
        - brand
    customer_hk:
        - customer_bk
        - brand
    shipment_inputs_hk:
        - shipment_inputs_bk
        - brand
    cust_sales_area_hk: 
        - cust_sales_area_bk
        - brand
    item_cust_shipment_inputs_hk:
        - item_cust_shipment_inputs_bk
        - brand
    hdiff:
        is_hashdiff: true
        columns:
            - 'customer_id'
            - 'item'
            - 'plant_id'
            - 'order_date'
            - 'issue_date'
            - 'doc_number'
            - 'line_number'
            - 'sales_document_type'
            - 'rejection_id'
            - 'uom'
            - 'currency'
            - 'ordered_units'
            - 'outted_units'
            - 'sales_dollars'
            - 'gross_input_dollars'
            - 'outted_dollars'
            - 'sales_org'
            - 'channel'
            - 'division'
            - 'sales_doc_item_cat'
            - 'po_number'
            - 'order_cat'
            - 'combined_reason_code'
            - 'type_of_sale'
            - 'mandt'
            - 'ssour'
            - 'vrsio'
            - 'spmon'
            - 'sap_load_date'
            - 'spwoc'
            - 'spbup'
            - 'stwae_01'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{% set source_model = metadata_dict["source_model"] %}
{% set derived_columns = metadata_dict["derived_columns"] %}
{% set hashed_columns = metadata_dict["hashed_columns"] %}

{{
    automate_dv.stage(
        include_source_columns=false,
        source_model=source_model,
        derived_columns=derived_columns,
        hashed_columns=hashed_columns,
        ranked_columns=none,
    )
}}
