{%- set yaml_metadata -%}

source_model: 'base_shipment__moen_sap_azcopa_history'
derived_columns:
    doc_number: 'kaufn'
    line_number: 'kdpos'
    gi_date: 'wadat'
    invoice_date: 'fadat'
    date_posted: 'budat'
    customer_id: 'kndnr'
    item: 'artnr'
    invoice_qty: 'vvqty'
    list_price: 'vvcrl'
    gross_sales_before_incentives: 'vvgbp'
    gross_sales_before_freight_and_handling: 'vvgrs'
    cja_adjustment: 'vvcjp'
    industry_gross_sales: 'vvsip'
    acquisition_oid: 'vvacq'
    freight_on_cash_sale: 'vvfrc'
    restocking_charge: 'vvrst'
    customer_chargebacks: 'vvhdl'
    volume_purchase_penalty: 'vvvpp'
    currency_exchange_surcharge: 'vvces'
    freight: 'vvfrm'
    freight_allowance: 'vvfra'
    handling_charge: 'vvmin'
    discount: 'vvdip'
    itm_override_ind_price: 'vvoip'
    sales_deal: 'wwknu'
    type_of_sale: 'wwstp'
    combined_reason_code: 'wwrsn'
    volume_rebate: 'vvvlr'
    fixed_rebate: 'vvcop'
    cogs: 'vvcst'
    cash_discount: 'vvotc'
    net_sales: 'vvnsa'
    sales_commission: 'vvcmg'
    uom: 'vvqty_me'
    sales_rep_id: 'wwpsr'
    sales_org: 'vkorg'
    channel: 'vtweg'
    division: 'spart'
    sales_region: 'vkbur'
    sales_district: 'bzirk'
    werks: 'werks'
    rec_waers: 'rec_waers'
    mandt: 'mandt'
    paledger: 'paledger'
    vrgar: 'vrgar'
    versi: 'versi'
    perio: 'perio'
    paobjnr: 'paobjnr'
    pasubnr: 'pasubnr'
    belnr: 'belnr'
    posnr: 'posnr'
    rec_src: 'rec_src'
    bkcc: 'bkcc'
    load_dts: current_timestamp()
    item_bk: item
    customer_bk: customer_id
    plant_bk: werks
    copa_sales_bk:
        - mandt
        - paledger
        - vrgar
        - versi
        - perio
        - paobjnr
        - pasubnr
        - belnr
        - posnr
    cust_sales_area_bk:
        - customer_id
        - sales_org
        - channel
        - division
    item_cust_shipment_bk:
        - item
        - customer_id
        - mandt
        - paledger
        - vrgar
        - versi
        - perio
        - paobjnr
        - pasubnr
        - belnr
        - posnr
        - customer_id
        - sales_org
        - channel
        - division
    plant_shipment_bk:
        - mandt
        - paledger
        - vrgar
        - versi
        - perio
        - paobjnr
        - pasubnr
        - belnr
        - posnr
        - werks
hashed_columns:
    item_hk: 
        - item_bk
        - bkcc
    customer_hk:
        - customer_bk
        - bkcc
    plant_hk:
        - plant_bk
        - bkcc
    copa_sales_hk: 
        - copa_sales_bk
        - bkcc
    cust_sales_area_hk: 
        - cust_sales_area_bk
        - bkcc
    item_cust_shipment_hk:
        - item_cust_shipment_bk
        - bkcc
    plant_shipment_hk:
        - plant_shipment_bk
        - bkcc
    hdiff:
        is_hashdiff: true
        columns:
            - 'doc_number'
            - 'line_number'
            - 'gi_date'
            - 'invoice_date'
            - 'date_posted'
            - 'customer_id'
            - 'item'
            - 'invoice_qty'
            - 'list_price'
            - 'gross_sales_before_incentives'
            - 'gross_sales_before_freight_and_handling'
            - 'cja_adjustment'
            - 'industry_gross_sales'
            - 'acquisition_oid'
            - 'freight_on_cash_sale'
            - 'restocking_charge'
            - 'customer_chargebacks'
            - 'volume_purchase_penalty'
            - 'currency_exchange_surcharge'
            - 'freight'
            - 'freight_allowance'
            - 'handling_charge'
            - 'discount'
            - 'itm_override_ind_price'
            - 'sales_deal'
            - 'type_of_sale'
            - 'combined_reason_code'
            - 'volume_rebate'
            - 'fixed_rebate'
            - 'cogs'
            - 'cash_discount'
            - 'net_sales'
            - 'sales_commission'
            - 'uom'
            - 'sales_rep_id'
            - 'sales_org'
            - 'channel'
            - 'division'
            - 'sales_region'
            - 'sales_district'
            - 'werks'
            - 'rec_waers'
            - 'mandt'
            - 'paledger'
            - 'vrgar'
            - 'versi'
            - 'perio'
            - 'paobjnr'
            - 'pasubnr'
            - 'belnr'
            - 'posnr'
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
