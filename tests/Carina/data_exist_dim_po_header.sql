    select * from ({{ data_exist('dim_po_header','USOHNO.SAP.ECCPRD.Z_EKKO')}}) 
    union all
    select * from ({{ data_exist('dim_po_header','USWIOC.ORCL.EBSPRD.PO_HEADERS_ALL')}}) 
    union all 
    select * from ({{ data_exist('dim_po_header','USSDBR.ORCL.PSFTPRD.PS_PO_HDR')}}) 
    union all
    select * from ({{ data_exist('dim_po_header','USOHMA.MSSQL.GPPRD.DBO_POP10100')}})
    union all
    select * from ({{ data_exist('dim_po_header','USOHMA.ORCL.E21PRD.POHEAD')}})   
    union all
    select * from ({{ data_exist('dim_po_header','USWIOC.ORCL.EBSEMTK.PO_HEADERS_ALL')}})  
    union all
    select * from ({{ data_exist('dim_po_header','USCLOUD.ORCL.OCFPRD.PO_HEADERS_ALL')}})  