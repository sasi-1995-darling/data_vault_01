    select * from ({{ primary_key_check('dim_item_fbin',['item_id']) }}) 
    union all
    select * from ({{ primary_key_check('dim_base_material_fbin',['base_material_id']) }}) 
