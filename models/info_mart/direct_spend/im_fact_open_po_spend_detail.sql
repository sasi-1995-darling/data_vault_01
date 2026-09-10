{{ config(alias='fact_open_po_spend_detail' + ('_direct_spend' if target.name not in ['dev', 'qa', 'prod'] else '')) }}

select
    open_po_hk
    , po_header_id
    , po_line_number
    , po_schedule_line_number
    , plan_creation_date__yyyymmdd
    , order_number
    , transaction_id
    , po_creation_date__yyyymmdd
    , schedule_line_delivery_date_key
    , po_item_uom
    , order_qty
    , received_qty
    , net_price
    , volume
    , spend
    , cal_year
    , cal_month
    , business_unit
    , drvd_opco
    , opco_item
    , supplier_number_parent
    , supplier_name_parent
    , supplier_number_child
    , supplier_name_child
    , country_of_origin
    , po_header_del_ind
    , payment_terms
    , document_type
    , opco_category
    , category_leader_name
    , director_name
    , fbin_category_i
    , fbin_category_ii
    , fbin_category_iii
    , item_bk
    , plant_bk
    , legal_entity_bk
    , source
    , schedule_line_delivery_date__yyyymmdd
    , po_header_hk
    , po_item_hk
    , item_hk
    , supplier_hk
    , legal_entity_hk
    , purchasing_record_hk
    , purchasing_org_hk
    , rec_src
    , bkcc
from {{ ref('fact_open_po_spend_detail') }}
