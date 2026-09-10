    select * from ({{ data_exist('hub_supplier_site_v2','USOHNO.SNFL.MDMPRD.OUTBOUND_SUPPLIER_SITE')}}) 
    union all
    select * from ({{ data_exist('lnk_supplier_site','USOHNO.SNFL.MDMPRD.OUTBOUND_SUPPLIER_SITE')}})
    union all
    select * from ({{ data_exist('lnk_supplier_site_legal_entity','USOHNO.SNFL.MDMPRD.OUTBOUND_SUPPLIER_ORG_ID')}})
    union all
    select * from ({{ data_exist('sat_supplier_site__mdm','USOHNO.SNFL.MDMPRD.OUTBOUND_SUPPLIER_SITE')}})
    union all
    select * from ({{ data_exist('msat_supplier_site_email__mdm','USOHNO.SNFL.MDMPRD.OUTBOUND_SUPPLIER_SITE_EMAIL')}})    
    union all
    select * from ({{ data_exist('msat_supplier_site_phone__mdm','USOHNO.SNFL.MDMPRD.OUTBOUND_SUPPLIER_SITE_PHONE')}}) 
    union all
    select * from ({{ data_exist('lsat_supplier_site_legal_entity__mdm','USOHNO.SNFL.MDMPRD.OUTBOUND_SUPPLIER_ORG_ID')}}) 