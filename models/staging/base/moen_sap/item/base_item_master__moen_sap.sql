with cte_item as (select * from {{ source("bronze_moen_sap", "z_mara") }})

select distinct
    cte_item.matnr as item_id
    ,cte_item.zzrmarea as room_area_id
    ,cte_item.zzptgk as item_group_id
    ,cte_item.zzplt as item_platform_id
    ,cte_item.zzptk as item_type_id
    ,cte_item.zzfin as item_finish_id
    ,cte_item.zzrepcatg as reporting_category_id
    ,cte_item.zzarch as item_architecture_id
    ,cte_item.zzdtp as item_line_id
    ,cte_item.zzcpf as item_price_category_id
    ,cte_item.zzptg as item_price_type_group_id
    ,cte_item.zzbusown as business_owner_id
    ,cte_item.zzbusunitown as business_unit_id
    ,cte_item.zzmkg_flag as imap_flag
    ,cte_item.mtart as item_type_code
    -- ,cte_item.zzfcst_base as base_material
    ,cte_item.zzbase_matnr as base_material
    ,cte_item.mstae as item_status
from cte_item