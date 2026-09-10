   select * from ({{ data_exist('hub_planned_order','USOHNO.SAP.ECCPRD.Z_PLAF')}}) 
    union all
    select * from ({{ data_exist('sat_planned_order__winn_sap','USOHNO.SAP.ECCPRD.Z_PLAF')}}) 
    union all
    select * from ({{ data_exist('sat_planned_order__ml_ascp','USWIOC.ORCL.ASCPPRD.MSC_SUPPLIES')}}) 