select * from ({{ data_exist('hub_delivery_v1','US.SAP_ECC_PRD.Z_ZFLO_SERIALNOS') }})
union all
select * from ({{ data_exist('hub_delivery_v1','USOHNO.SAP.ECCPRD.Z_LIKP') }})
union all
select * from ({{ data_exist('hub_delivery_v1','USOHNO.SAP.ECCPRD.Z_LIPS') }})
union all
select * from ({{ data_exist('hub_delivery_v1','USOHNO.SAP.ECCPRD.Z_VTTP') }})
union all
select * from ({{ data_exist('hub_order_header','USOHNO.SAP.ECCPRD.Z_LIPS') }})
union all
select * from ({{ data_exist('hub_order_header','US.SHOPIFY_MOEN.DISCOUNT_APPLICATION') }})
union all
select * from ({{ data_exist('hub_order_header','US.SHOPIFY_MOEN.ORDER_TAG') }})
union all
select * from ({{ data_exist('hub_order_header','USWIOC.ORCL.E21PRD.ORDHEAD') }})
union all
select * from ({{ data_exist('hub_order_header','USOHNO.SAP.ECCPRD.Z_VBUK') }})
union all
select * from ({{ data_exist('hub_order_header','US.SAP_ECC_PRD.Z_VBKD') }})
union all
select * from ({{ data_exist('hub_order_header','USOHNO.SAP.ECCPRD.Z_VBAP') }})
union all
select * from ({{ data_exist('hub_order_header','USOHNO.SAP.ECCPRD.Z_VBEP') }})
union all
select * from ({{ data_exist('hub_order_line','USOHNO.SAP_BW.AZ_COPA') }})
union all
select * from ({{ data_exist('hub_order_line','USWIOC.ORCL.EBSPRD.OE_ORDER_LINES_ALL') }})
union all
select * from ({{ data_exist('hub_order_line','USOHNO.SAP.ECCPRD.Z_VBUP') }})
union all
select * from ({{ data_exist('hub_order_line','USOHNO.SAP.ECCPRD.Z_ZSERVLEVEL') }})
union all
select * from ({{ data_exist('hub_order_line','US.SAP_ECC_PRD.Z_VBKD') }})
union all
select * from ({{ data_exist('hub_order_line','USOHNO.SAP.ECCPRD.Z_MARA') }})
union all
select * from ({{ data_exist('hub_order_line','USWIOC.ORCL.E21PRD.ORDITEM') }})
union all
select * from ({{ data_exist('hub_order_line','US.API.SHOPIFY_MOEN.ORDER_LINE') }})
union all
select * from ({{ data_exist('hub_order_line','USOHNO.SAP.ECCPRD.Z_LIPS') }})
union all
select * from ({{ data_exist('hub_order_line','USOHNO.SAP.ECCPRD.CE1NEW4') }})
union all
select * from ({{ data_exist('hub_order_line','USOHNO.SAP.ECCPRD.Z_VBAP') }})
union all
select * from ({{ data_exist('hub_order_line','USWIOC.ORCL.EBSPRD.CUSTOMER_TRX_LINES_ALL') }})
union all
select * from ({{ data_exist('hub_order_line','USOHNO.SAP.ECCPRD.Z_VBEP') }})
union all
select * from ({{ data_exist('hub_order_line','USOHNO.SAP.ECCPRD.Z_MSEG') }})
union all
select * from ({{ data_exist('lnk_subscriber_subscription','US.PRIVE_MOEN.SUBSCRIPTION') }})
union all
select * from ({{ data_exist('lnk_subscription_order','US.PRIVE_MOEN.ORDERS') }})
union all
select * from ({{ data_exist('lsat_subscription_order__winn_prive','US.PRIVE_MOEN.ORDERS') }})
union all
select * from ({{ data_exist('msat_delivery_flo_serial__winn_sap','US.SAP_ECC_PRD.Z_ZFLO_SERIALNOS') }})
union all
select * from ({{ data_exist('sat_subscriber__winn_prive','US.PRIVE_MOEN.SUBSCRIBER') }})
union all
select * from ({{ data_exist('sat_subscription__winn_prive','US.PRIVE_MOEN.SUBSCRIPTION') }})