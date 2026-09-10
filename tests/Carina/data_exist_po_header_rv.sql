    select * from ({{ data_exist('hub_po_header','USOHNO.SAP.ECCPRD.Z_EKKO')}}) 
    union all
    select * from ({{ data_exist('hub_po_header','USWIOC.ORCL.EBSPRD.PO_HEADERS_ALL')}})
    union all
    select * from ({{ data_exist('hub_po_header','USSDBR.ORCL.PSFTPRD.PS_PO_HDR')}})
    union all
    select * from ({{ data_exist('hub_po_header','USOHMA.MSSQL.GPPRD.DBO_POP10100')}})
    union all
    select * from ({{ data_exist('hub_po_header','USOHMA.ORCL.E21PRD.POHEAD')}})  
    union all
    select * from ({{ data_exist('sat_po_header__ml_ebs','USWIOC.ORCL.EBSPRD.PO_HEADERS_ALL')}}) 
    union all
    select * from ({{ data_exist('sat_po_header__winn_sap','USOHNO.SAP.ECCPRD.Z_EKKO')}})
    union all
    select * from ({{ data_exist('sat_po_header__lrsn_psft','USSDBR.ORCL.PSFTPRD.PS_PO_HDR')}})
    union all
    select * from ({{ data_exist('sat_po_header__tt_gp','USOHMA.MSSQL.GPPRD.DBO_POP10100')}})
    union all
    select * from ({{ data_exist('msat_po_header__tt_e21','USOHMA.ORCL.E21PRD.POHEAD')}})
    union all
    select * from ({{ data_exist('sat_po_header__emtk_ebs','USWIOC.ORCL.EBSEMTK.PO_HEADERS_ALL')}})     