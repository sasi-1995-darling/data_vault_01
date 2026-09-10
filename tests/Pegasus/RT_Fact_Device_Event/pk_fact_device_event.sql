select * from ({{ primary_key_check('fact_device_event',['PAIRED_DEVICE_BK','DEVICE_LOCATION_BK','BKCC','REC_SRC','EVENT']) }}) 
