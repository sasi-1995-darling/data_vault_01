select distinct
    base_material_key as base_material_id
    , system_base_material as base_material
    , item_type_cd_base_material as item_type_code
    , active_item_ind_base_material as item_status
    , registered_brand_pref_base_material as brand 
    , item_category_base_material as item_category
    , item_sub_category_base_material as item_sub_category
    , item_class_base_material as item_class
    , item_sub_class_base_material as item_sub_class
    , bkcc
    , rec_src
from {{ ref('pb_items_by_plant') }}
where coalesce(moen_base_material_flag, 'Y') = 'Y'
and system_base_material is not null
and base_material_rn = 1
