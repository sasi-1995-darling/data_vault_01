    select * from ({{ data_exist('lsat_po_receipt__ml_ebs','USWIOC.ORCL.EBSPRD.MTL_MATERIAL_TRANSACTIONS')}}) 
    union all
    select * from ({{ data_exist('lsat_po_receipt__winn_sap','USOHNO.SAP.ECCPRD.Z_EKBE')}}) 
    union all
    select * from ({{ data_exist('lnk_po_receipt','USOHNO.SAP.ECCPRD.Z_EKBE')}}) 
    union all
    select * from ({{ data_exist('lnk_po_receipt','USWIOC.ORCL.EBSPRD.MTL_MATERIAL_TRANSACTIONS')}})
    union all
    select * from ({{ data_exist('lnk_po_receipt','USSDBR.ORCL.PSFTPRD.PS_RECV_LN_SHIP')}}) 
    union all
    select * from ({{ data_exist('lnk_po_receipt','USWIOC.ORCL.EBSEMTK.MTL_MATERIAL_TRANSACTIONS')}})  
    union all
    select * from ({{ data_exist('lsat_po_receipt__lrsn_psft','USSDBR.ORCL.PSFTPRD.PS_RECV_LN_SHIP')}})
    union all
    select * from ({{ data_exist('lsat_po_receipt__emtk_ebs','USWIOC.ORCL.EBSEMTK.MTL_MATERIAL_TRANSACTIONS')}})  