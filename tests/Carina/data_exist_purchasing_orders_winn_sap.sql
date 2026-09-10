 select * from ({{ data_exist('hub_purchasing_org','USOHNO.SAP.ECCPRD.Z_T024')}}) 
    union all
    select * from ({{ data_exist('hub_purchasing_record','USOHNO.SAP.ECCPRD.Z_EINA')}}) 
    union all
    select * from ({{ data_exist('sat_purchasing_org__winn_sap','USOHNO.SAP.ECCPRD.Z_T024')}}) 
    union all
    select * from ({{ data_exist('sat_purchasing_record__winn_sap','USOHNO.SAP.ECCPRD.Z_EINA')}}) 
    union all
    select * from ({{ data_exist('lsat_purchasing_record_details__winn_sap','USOHNO.SAP.ECCPRD.Z_EINE')}}) 