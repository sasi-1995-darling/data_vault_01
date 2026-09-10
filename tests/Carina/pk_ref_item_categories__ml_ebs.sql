select * from ({{ primary_key_check('ref_item_categories__ml_ebs',['inventory_item_id','category_set_id']) }}) 
    