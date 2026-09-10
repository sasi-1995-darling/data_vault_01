select * from ({{ data_exist('dim_item_fbin','USWIOC.ORCL.EBSPRD.MLC_SYSTEM_ITEMS')}}) 
union all
select * from ({{ data_exist('dim_item_fbin','USWIOC.ORCL.EBSPRD.BOM_STRUCTURES_B')}}) 
union all
select * from ({{ data_exist('dim_item_fbin','USWIOC.ORCL.EBSPRD.SYSTEM_ITEM')}}) 
union all
select * from ({{ data_exist('dim_item_fbin','USWIOC.ORCL.EBSPRD.BOM_COMPONENTS_B')}}) 
union all

select * from ({{ data_exist('dim_item_fbin','USOHNO.SAP.ECCPRD.Z_MAST')}}) 
union all
select * from ({{ data_exist('dim_item_fbin','USOHNO.SAP.ECCPRD.CE1NEW4')}})
union all
select * from ({{ data_exist('dim_item_fbin','USOHNO.SAP.ECCPRD.Z_MARC')}}) 
union all
select * from ({{ data_exist('dim_item_fbin','USOHNO.SAP.ECCPRD.Z_MARA')}}) 
union all
select * from ({{ data_exist('dim_item_fbin','USOHNO.SAP.ECCPRD.Z_MKAL')}}) 
union all
select * from ({{ data_exist('dim_item_fbin','USOHNO.SAP.ECCPRD.Z_STPO')}}) 
union all

select * from ({{ data_exist('dim_item_fbin','USCLOUD.ORCL.OCFPRD.SYSTEM_ITEM')}})
union all
select * from ({{ data_exist('dim_item_fbin','USCLOUD.ORCL.OCFPRD.CUSTOMER_TRX_LINES_ALL')}}) 
union all

select * from ({{ data_exist('dim_item_fbin','USOHMA.ORCL.E21PRD.PARTMSTR')}}) 
union all
select * from ({{ data_exist('dim_item_fbin','USOHMA.MSSQL.GPPRD.DBO_IV00101')}}) 
union all
select * from ({{ data_exist('dim_item_fbin','USOHMA.ORCL.E21PRD.WHSPRMSTR')}}) 
union all
select * from ({{ data_exist('dim_item_fbin','USOHMA.MSSQL.GPPRD.DBO_IV00102')}})
union all

select * from ({{ data_exist('dim_item_fbin','USSDBR.ORCL.PSFTPRD.BI_LINE')}}) 
union all
select * from ({{ data_exist('dim_item_fbin','USSDBR.ORCL.PSFTPRD.PS_PROD_ITEM')}}) 
union all
select * from ({{ data_exist('dim_item_fbin','USSDBR.ORCL.PSFTPRD.PS_INV_ITEMS')}}) 
union all
select * from ({{ data_exist('dim_item_fbin','USSDBR.ORCL.PSFTPRD.PS_BU_ITEMS_INV')}}) 
union all
select * from ({{ data_exist('dim_item_fbin','USSDBR.ORCL.PSFTPRD.PS_MASTER_ITEM_TBL')}})

union all
select * from ({{ data_exist('dim_item_fbin','USWIOC.ORCL.EBSEMTK.SYSTEM_ITEM')}})

union all
select * from ({{ data_exist('dim_base_material_fbin','USWIOC.ORCL.EBSPRD.MLC_SYSTEM_ITEMS')}}) 
union all
select * from ({{ data_exist('dim_base_material_fbin','USWIOC.ORCL.EBSPRD.BOM_STRUCTURES_B')}}) 
union all
select * from ({{ data_exist('dim_base_material_fbin','USWIOC.ORCL.EBSPRD.SYSTEM_ITEM')}}) 
union all
select * from ({{ data_exist('dim_base_material_fbin','USWIOC.ORCL.EBSPRD.BOM_COMPONENTS_B')}}) 
union all

select * from ({{ data_exist('dim_base_material_fbin','USOHNO.SAP.ECCPRD.Z_MAST')}}) 
union all
select * from ({{ data_exist('dim_base_material_fbin','USOHNO.SAP.ECCPRD.CE1NEW4')}})
union all
select * from ({{ data_exist('dim_base_material_fbin','USOHNO.SAP.ECCPRD.Z_MARC')}}) 
union all
select * from ({{ data_exist('dim_base_material_fbin','USOHNO.SAP.ECCPRD.Z_MARA')}}) 
union all
select * from ({{ data_exist('dim_base_material_fbin','USOHNO.SAP.ECCPRD.Z_STPO')}}) 
union all
select * from ({{ data_exist('dim_base_material_fbin','USOHNO.SAP.ECCPRD.Z_MKAL')}}) 
union all

select * from ({{ data_exist('dim_base_material_fbin','USCLOUD.ORCL.OCFPRD.SYSTEM_ITEM')}})
union all

select * from ({{ data_exist('dim_base_material_fbin','USOHMA.ORCL.E21PRD.PARTMSTR')}}) 
union all
select * from ({{ data_exist('dim_base_material_fbin','USOHMA.MSSQL.GPPRD.DBO_IV00101')}}) 
union all
select * from ({{ data_exist('dim_base_material_fbin','USOHMA.ORCL.E21PRD.WHSPRMSTR')}}) 
union all
select * from ({{ data_exist('dim_base_material_fbin','USOHMA.MSSQL.GPPRD.DBO_IV00102')}})
union all

select * from ({{ data_exist('dim_base_material_fbin','USSDBR.ORCL.PSFTPRD.BI_LINE')}}) 
union all
select * from ({{ data_exist('dim_base_material_fbin','USSDBR.ORCL.PSFTPRD.PS_INV_ITEMS')}}) 
union all
select * from ({{ data_exist('dim_base_material_fbin','USSDBR.ORCL.PSFTPRD.PS_PROD_ITEM')}}) 
union all
select * from ({{ data_exist('dim_base_material_fbin','USSDBR.ORCL.PSFTPRD.PS_BU_ITEMS_INV')}}) 
union all
select * from ({{ data_exist('dim_base_material_fbin','USSDBR.ORCL.PSFTPRD.PS_MASTER_ITEM_TBL')}})