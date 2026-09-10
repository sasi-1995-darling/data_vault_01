    select * from ({{ primary_key_check('dim_supplier_v2',['supplier_hk']) }}) 
    union all
    select * from ({{ primary_key_check('dim_supplier_v2',['supplier_bk','bkcc']) }})