select * from ({{ data_exist('hub_po_item','USWIOC.ORCL.EBSPRD.PO_LINES_ALL')}}) 
    union all
    select * from ({{ data_exist('hub_po_item','USOHNO.SAP.ECCPRD.Z_EKPO')}})
    union all
    select * from ({{ data_exist('hub_po_item','USSDBR.ORCL.PSFTPRD.PS_PO_LINE')}})
    union all
    select * from ({{ data_exist('hub_po_item','USOHMA.MSSQL.GPPRD.DBO_POP10110')}})
    union all
    select * from ({{ data_exist('hub_po_item','USOHMA.ORCL.E21PRD.POITEM')}})
    union all
    select * from ({{ data_exist('hub_po_item','USWIOC.ORCL.EBSEMTK.PO_LINES_ALL')}})
    union all
    select * from ({{ data_exist('sat_po_item__ml_ebs','USWIOC.ORCL.EBSPRD.PO_LINES_ALL')}}) 
    union all
    select * from ({{ data_exist('sat_po_item__winn_sap','USOHNO.SAP.ECCPRD.Z_EKPO')}})
    union all
    select * from ({{ data_exist('sat_po_item__lrsn_psft','USSDBR.ORCL.PSFTPRD.PS_PO_LINE')}})
    union all
    select * from ({{ data_exist('sat_po_item__tt_gp','USOHMA.MSSQL.GPPRD.DBO_POP10110')}})
    union all
    select * from ({{ data_exist('msat_po_item__tt_e21','USOHMA.ORCL.E21PRD.POITEM')}})
    union all
    select * from ({{ data_exist('sat_po_item__emtk_ebs','USWIOC.ORCL.EBSEMTK.PO_LINES_ALL')}})