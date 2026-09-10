    select * from ({{ data_exist('dim_legal_entity','USWIOC.ORCL.EBSPRD.HR_ALL_ORGANIZATION_UNITS')}}) 
    union all
    select * from ({{ data_exist('dim_legal_entity','USOHNO.SAP.ECCPRD.Z_T001')}}) 
    union all
    select * from ({{ data_exist('dim_legal_entity','USSDBR.ORCL.PSFTPRD.PS_BUS_UNIT_TBL_FS')}})   
    union all
    select * from ({{ data_exist('dim_legal_entity','USWIOC.ORCL.EBSEMTK.HR_ALL_ORGANIZATION_UNITS')}}) 
    union all
    select * from ({{ data_exist('dim_legal_entity','USOHMA.ORCL.E21PRD.CCMSTR')}}) 
    union all
    select * from ({{ data_exist('dim_legal_entity','USOHMA.MSSQL.GPPRD.DBO_POP10100')}}) 
    union all
    select * from ({{ data_exist('dim_legal_entity','USCLOUD.ORCL.OCFPRD.XLE_ENTITY_PROFILES')}}) 
    