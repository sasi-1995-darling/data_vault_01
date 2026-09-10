select * from ({{ data_exist('fact_shipment_fbin','USWIOC.ORCL.EBSPRD.PAYMENT_SCHEDULES_ALL')}}) 
union all
select * from ({{ data_exist('fact_shipment_fbin','USWIOC.ORCL.EBSPRD.CUSTOMER_TRX_LINES_ALL')}}) 
union all

select * from ({{ data_exist('fact_shipment_fbin','USOHNO.SAP.ECCPRD.HOFR_US_SALES')}}) 
union all
select * from ({{ data_exist('fact_shipment_fbin','USOHNO.SAP.ECCPRD.CE1NEW4')}}) 
union all
select * from ({{ data_exist('fact_shipment_fbin','USOHNO.SAP_BW.AZ_COPA')}}) 
union all

select * from ({{ data_exist('fact_shipment_fbin','USCLOUD.ORCL.OCFPRD.CUSTOMER_TRX_LINES_ALL')}}) 
union all

select * from ({{ data_exist('fact_shipment_fbin','USSDBR.ORCL.PSFTPRD.BI_LINE')}}) 
