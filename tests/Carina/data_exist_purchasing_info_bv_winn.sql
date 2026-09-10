   select * from ({{ data_exist('dim_purchase_record','USOHNO.SAP.ECCPRD.Z_EINA')}}) 
    union all
    select * from ({{ data_exist('pit_purchasing_record_details_current','USOHNO.SAP.ECCPRD.Z_EINE')}}) 