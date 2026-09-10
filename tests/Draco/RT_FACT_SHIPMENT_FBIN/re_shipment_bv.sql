WITH check_results AS (
{{check_relation_exists('fact_shipment_fbin','item_id','dim_item_fbin','item_id'
,'brand',["'MOEN'"],'rec_src',["'USOHNO.SAP.ECCPRD.Z_MARA'", "'USOHNO.SAP.ECCPRD.CE1NEW4'", "'USOHNO.SAP.ECCPRD.Z_STPO'", "'USOHNO.SAP.ECCPRD.Z_MKAL'", "'USOHNO.SAP.ECCPRD.Z_MAST'"])}}
union all
{{check_relation_exists('fact_shipment_fbin','item_id','dim_item_fbin','item_id'
,'brand',["'MASTER LOCK'"],'rec_src',["'USWIOC.ORCL.EBSPRD.SYSTEM_ITEM'", "'USWIOC.ORCL.EBSPRD.BOM_STRUCTURES_B'", "'USWIOC.ORCL.EBSPRD.BOM_COMPONENTS_B'"])}}
union all
{{check_relation_exists('fact_shipment_fbin','item_id','dim_item_fbin','item_id'
,'brand',["'FIBERON'"],'rec_src',["'USCLOUD.ORCL.OCFPRD.SYSTEM_ITEM'", "'USCLOUD.ORCL.OCFPRD.CUSTOMER_TRX_LINES_ALL'"])}}
union all
{{check_relation_exists('fact_shipment_fbin','item_id','dim_item_fbin','item_id'
,'brand',["'LARSON'"],'rec_src',["'USSDBR.ORCL.PSFTPRD.PS_BU_ITEMS_INV'", "'USSDBR.ORCL.PSFTPRD.PS_PROD_ITEM'", "'USSDBR.ORCL.PSFTPRD.PS_INV_ITEMS'", "'USSDBR.ORCL.PSFTPRD.BI_LINE'", "'USSDBR.ORCL.PSFTPRD.PS_MASTER_ITEM_TBL'"])}}
),
--Excluding 12 items had a valid explanation from BU
flag_failed AS (
    SELECT * FROM check_results
    QUALIFY ROW_NUMBER() OVER (ORDER BY 1) > 12
)
SELECT *
FROM flag_failed