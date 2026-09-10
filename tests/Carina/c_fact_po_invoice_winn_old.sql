select * from ({{ check_not_null('fact_po_invoice','po_header_hk')}}) 
    union all
    select * from ({{ check_not_null('fact_po_invoice','supplier_hk')}}) 
    union all
    select * from ({{ check_not_null('fact_po_invoice','item_hk')}}) 
    union all
    select * from ({{ check_not_null('fact_po_invoice','plant_hk')}}) 
    union all
    select * from ({{ check_not_null('fact_po_invoice','legal_entity_hk')}}) 
    union all
    select * from ({{ check_not_null('fact_po_invoice','po_line_receipt_ind_hk')}}) 
    union all
    select * from ({{ check_not_null('fact_po_invoice','po_receipt_date__yyyymmdd')}})
    union all
    select * from ({{ check_not_null('fact_po_invoice','po_header_id')}})  
    union all
    select * from ({{ check_not_null('fact_po_invoice','po_line_number')}})  