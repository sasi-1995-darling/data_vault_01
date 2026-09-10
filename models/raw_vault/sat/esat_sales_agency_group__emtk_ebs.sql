{{ 
    load_esat(
        linkpk = 'sales_agency_groups_hk'
        , hkdk = 'sales_agency_hk'
        , hkfk = ["sales_region_hk", "sales_territory_hk"]
        , stg_tbl = ref('stg_sales_agency_groups__emtk_ebs_sales')
    )
}}