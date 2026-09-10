    select * from ({{ data_exist('dim_supplier_v2','USOHNO.SAP.ECCPRD.Z_LFA1')}}) 
    union all
    select * from ({{ data_exist('dim_supplier_v2','USWIOC.ORCL.EBSPRD.AP_SUPPLIER')}}) 
    union all
    select * from ({{ data_exist('dim_supplier_v2','USOHMA.ORCL.E21PRD.APVNDMSTR')}}) 
    union all
    select * from ({{ data_exist('dim_supplier_v2','USOHMA.MSSQL.GPPRD.DBO_PM00200')}})
    union all
    select * from ({{ data_exist('dim_supplier_v2','USSDBR.ORCL.PSFTPRD.PS_VENDOR')}})
    union all
    select * from ({{ data_exist('dim_supplier_v2','USWIOC.ORCL.EBSEMTK.AP_SUPPLIER')}})