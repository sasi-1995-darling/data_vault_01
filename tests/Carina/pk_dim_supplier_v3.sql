    select * from ({{ primary_key_check('dim_supplier_v3',['supplier_hk']) }}) 
    union all
    select * from ({{ primary_key_check('dim_supplier_v3',['supplier_bk','bkcc']) }})