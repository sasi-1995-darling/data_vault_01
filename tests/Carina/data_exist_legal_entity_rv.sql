    select * from ({{ data_exist('hub_legal_entity','USWIOC.ORCL.EBSPRD.HR_ALL_ORGANIZATION_UNITS')}}) 
    union all
    select * from ({{ data_exist('hub_legal_entity','USOHNO.SAP.ECCPRD.Z_T001')}}) 
    union all
    select * from ({{ data_exist('hub_legal_entity','USWIOC.ORCL.EBSEMTK.HR_ALL_ORGANIZATION_UNITS')}}) 
    union all
    select * from ({{ data_exist('sat_legal_entity__lrsn_psft','USSDBR.ORCL.PSFTPRD.PS_BUS_UNIT_TBL_FS')}})
    union all
    select * from ({{ data_exist('sat_legal_entity__ml_ebs','USWIOC.ORCL.EBSPRD.HR_ALL_ORGANIZATION_UNITS')}}) 
    union all
    select * from ({{ data_exist('sat_legal_entity__winn_sap','USOHNO.SAP.ECCPRD.Z_T001')}})
    union all
    select * from ({{ data_exist('sat_legal_entity__lrsn_psft','USSDBR.ORCL.PSFTPRD.PS_BUS_UNIT_TBL_FS')}})
    union all
    select * from ({{ data_exist('sat_legal_entity__emtk_ebs','USWIOC.ORCL.EBSEMTK.HR_ALL_ORGANIZATION_UNITS')}}) 