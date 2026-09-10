select * from ({{ primary_key_check('dim_competitive_product',['COMPETITIVE_PRODUCT_HK','RETAILER_HK','SOURCE']) }}) 
