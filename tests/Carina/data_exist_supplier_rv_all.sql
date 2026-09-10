select * from ({{ data_exist('hub_supplier_v2','USOHMA.ORCL.E21PRD.APVNDMSTR')}}) 
    union all
    select * from ({{ data_exist('hub_supplier_v2','USOHMA.MSSQL.GPPRD.DBO_PM00200')}})
    union all
    select * from ({{ data_exist('hub_supplier_v2','USOHNO.SAP.ECCPRD.Z_LFA1')}})
    union all
    select * from ({{ data_exist('hub_supplier_v2','USWIOC.ORCL.EBSPRD.AP_SUPPLIER')}})
    union all
    select * from ({{ data_exist('hub_supplier_v2','USSDBR.ORCL.PSFTPRD.PS_VENDOR')}})    
    union all
    select * from ({{ data_exist('sat_supplier__tt_e21','USOHMA.ORCL.E21PRD.APVNDMSTR')}}) 
    union all
    select * from ({{ data_exist('sat_supplier__tt_gp','USOHMA.MSSQL.GPPRD.DBO_PM00200')}}) 
    union all
    select * from ({{ data_exist('sat_supplier__winn_sap','USOHNO.SAP.ECCPRD.Z_LFA1')}}) 
    union all
    select * from ({{ data_exist('sat_supplier__ml_ebs','USWIOC.ORCL.EBSPRD.AP_SUPPLIER')}}) 
    union all
    select * from ({{ data_exist('sat_supplier__lrsn_psft','USSDBR.ORCL.PSFTPRD.PS_VENDOR')}}) 
    union all
    select * from ({{ data_exist('lmsat_supplier_item_loc__lrsn_psft','USSDBR.ORCL.PSFTPRD.PS_ITM_VENDOR_LOC')}})
    union all
    select * from ({{ data_exist('sat_supplier__emtk_ebs','USWIOC.ORCL.EBSEMTK.AP_SUPPLIER')}})