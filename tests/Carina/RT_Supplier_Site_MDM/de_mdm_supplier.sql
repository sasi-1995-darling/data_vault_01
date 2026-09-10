    select * from ({{ data_exist('dim_supplier_site_v2','USOHNO.SAP.ECCPRD.Z_LFA1')}}) 
    union all
    select * from ({{ data_exist('dim_supplier_site_v2','USOHMA.ORCL.E21PRD.APVNDMSTR')}}) 
    union all
    select * from ({{ data_exist('dim_supplier_site_v2','USWIOC.ORCL.EBSPRD.AP_SUPPLIER')}}) 
    union all
    select * from ({{ data_exist('dim_supplier_site_v2','USOHNO.SAP.ECCPRD.Z_T001L')}}) 
    union all
    select * from ({{ data_exist('dim_supplier_site_v2','USOHMA.MSSQL.GPPRD.DBO_PM00200')}}) 
    union all
    select * from ({{ data_exist('dim_supplier_site_legal_entity','USOHNO.SNFL.MDMPRD.OUTBOUND_SUPPLIER_SITE')}})
    union all
    select * from ({{ data_exist('dim_supplier_v3','USOHNO.SAP.ECCPRD.Z_LFA1')}}) 
    union all
    select * from ({{ data_exist('dim_supplier_v3','USOHMA.ORCL.E21PRD.APVNDMSTR')}}) 
    union all
    select * from ({{ data_exist('dim_supplier_v3','USWIOC.ORCL.EBSEMTK.AP_SUPPLIER')}}) 
    union all
    select * from ({{ data_exist('dim_supplier_v3','USWIOC.ORCL.EBSPRD.AP_SUPPLIER')}}) 
    union all
    select * from ({{ data_exist('dim_supplier_v3','USOHNO.SAP.ECCPRD.Z_T001L')}})
    union all
    select * from ({{ data_exist('dim_supplier_v3','USOHMA.MSSQL.GPPRD.DBO_PM00200')}}) 
    union all
    select * from ({{ data_exist('dim_supplier_v3','USSDBR.ORCL.PSFTPRD.PS_VENDOR')}})