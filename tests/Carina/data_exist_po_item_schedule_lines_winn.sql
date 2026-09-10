    select * from ({{ data_exist('sat_po_item_schedule_lines__winn_sap','USOHNO.SAP.ECCPRD.Z_EKET')}})
    union all 
   select * from ({{ data_exist('sat_po_item_schedule_lines__lrsn_psft','USSDBR.ORCL.PSFTPRD.PS_PO_LINE_SHIP')}})