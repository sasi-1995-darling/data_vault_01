    select * from ({{ primary_key_check('dim_purchase_record',['PURCHASING_RECORD_HK']) }}) 
    union all
    select * from ({{ primary_key_check('fact_purchase_record_details',['PURCHASING_RECORD_DETAILS_HK',
    'PURCHASING_REC_DETAIL_HK','PURCHASING_ORG_HK','PLANT_HK']) }}) 
