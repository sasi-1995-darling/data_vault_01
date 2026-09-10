{%- set yaml_metadata -%}

source_model: 'stg_shipment__moen_sap_v1'
src_pk: 
    - copa_sales_hk
src_hashdiff: 
  source_column: hdiff
  alias: hdiff
src_payload:
    - doc_number
    - line_number
    - gi_date
    - invoice_date
    - date_posted
    - invoice_qty
    - list_price
    - gross_sales_before_incentives
    - gross_sales_before_freight_and_handling
    - cja_adjustment
    - industry_gross_sales
    - acquisition_oid
    - freight_on_cash_sale
    - restocking_charge
    - customer_chargebacks
    - volume_purchase_penalty
    - currency_exchange_surcharge
    - freight
    - freight_allowance
    - handling_charge
    - discount
    - itm_override_ind_price
    - sales_deal
    - type_of_sale
    - combined_reason_code
    - volume_rebate
    - fixed_rebate
    - cogs
    - cash_discount
    - net_sales
    - sales_commission
    - uom
    - sales_rep_id
    - sales_org
    - channel
    - division
    - sales_region
    - sales_district
    - werks
    - rec_waers
    - mandt
    - paledger
    - vrgar
    - versi
    - perio
    - paobjnr
    - pasubnr
    - belnr
    - posnr
    - bkcc
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