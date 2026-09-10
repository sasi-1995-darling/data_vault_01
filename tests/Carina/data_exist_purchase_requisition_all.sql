    select * from ({{ data_exist('hub_purchase_requisition','USOHNO.SAP.ECCPRD.Z_EBAN')}}) 
    union all
    select * from ({{ data_exist('sat_purchase_requisition__winn_sap','USOHNO.SAP.ECCPRD.Z_EBAN')}})
    union all
    select * from ({{ data_exist('sat_purchase_requisition__ml_ascp','USWIOC.ORCL.ASCPPRD.MSC_SUPPLIES')}})  