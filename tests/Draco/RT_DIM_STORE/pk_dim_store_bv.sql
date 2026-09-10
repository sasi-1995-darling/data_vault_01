select * from ({{ primary_key_check('dim_store',['store_key']) }})
