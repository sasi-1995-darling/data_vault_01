    select * from ({{ data_exist('fact_global_spend_detail','USWIOC.ORCL.EBSPRD.MTL_MATERIAL_TRANSACTIONS')}}) 
    union all
    select * from ({{ data_exist('fact_global_spend_detail','USOHNO.SAP.ECCPRD.Z_EKBE')}}) 
    union all
    select * from ({{ data_exist('fact_global_spend_detail','USSDBR.ORCL.PSFTPRD.PS_RECV_LN_SHIP')}}) 
    union all
    select * from ({{ data_exist('fact_global_spend_detail','USCLOUD.ORCL.OCFPRD.INV_MATERIAL_TXNS')}})
    union all
    select * from ({{ data_exist('fact_global_direct_spend_daily_summary','USWIOC.ORCL.EBSPRD.MTL_MATERIAL_TRANSACTIONS')}}) 
    union all
    select * from ({{ data_exist('fact_global_direct_spend_daily_summary','USOHNO.SAP.ECCPRD.Z_EKBE')}}) 
    union all
    select * from ({{ data_exist('fact_global_direct_spend_daily_summary','USSDBR.ORCL.PSFTPRD.PS_RECV_LN_SHIP')}})
    union all
    select * from ({{ data_exist('fact_global_direct_spend_daily_summary','USOHMA.ORCL.E21PRD.POITEM')}}) 
    union all
    select * from ({{ data_exist('fact_global_direct_spend_daily_summary','USOHMA.MSSQL.GPPRD.DBO_POP10500')}})
    union all
    select * from ({{ data_exist('fact_global_direct_spend_daily_summary','USCLOUD.ORCL.OCFPRD.INV_MATERIAL_TXNS')}})

    